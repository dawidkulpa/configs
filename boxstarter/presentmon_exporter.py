# PresentMon frame metrics → Prometheus exporter. See AGENTS.md for documentation.
import csv
import os
import socket
import subprocess
import sys
import threading
import time
import urllib.request

from prometheus_client import CollectorRegistry
from prometheus_client import Counter
from prometheus_client import Gauge
from prometheus_client import Histogram
from prometheus_client import start_http_server

PRESENTMON_PATH = os.environ.get("PRESENTMON_PATH", r"C:\Apps\PresentMonExporter\PresentMon.exe")
METRICS_PORT = int(os.environ.get("PRESENTMON_METRICS_PORT", "4446"))
STALE_TIMEOUT = int(os.environ.get("PRESENTMON_STALE_TIMEOUT", "60"))
PRESENTMON_VERSION = "2.4.1"

FRAME_BUCKETS = [1, 2, 4, 8, 10, 12, 16.6, 20, 25, 33.3, 50, 100]
DISPLAY_BUCKETS = [5, 10, 16.6, 20, 25, 33.3, 50, 75, 100, 150, 200]
LABELS = ["application"]
STALE_KEYS = ["frame", "cpu_busy", "cpu_wait", "gpu_busy", "gpu_wait", "gpu_latency", "display_latency", "click_to_photon", "frames_total"]

presentmon_frame_time_milliseconds = Histogram("presentmon_frame_time_milliseconds", "Frame time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_cpu_busy_milliseconds = Histogram("presentmon_cpu_busy_milliseconds", "CPU busy time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_cpu_wait_milliseconds = Histogram("presentmon_cpu_wait_milliseconds", "CPU wait time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_gpu_busy_milliseconds = Histogram("presentmon_gpu_busy_milliseconds", "GPU busy time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_gpu_wait_milliseconds = Histogram("presentmon_gpu_wait_milliseconds", "GPU wait time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_gpu_latency_milliseconds = Histogram("presentmon_gpu_latency_milliseconds", "GPU latency in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_display_latency_milliseconds = Histogram("presentmon_display_latency_milliseconds", "Display latency in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_click_to_photon_milliseconds = Histogram("presentmon_click_to_photon_milliseconds", "Click to photon latency in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_up = Gauge("presentmon_up", "PresentMon subprocess health")
presentmon_frames_total = Counter("presentmon_frames_total", "Total PresentMon frames", LABELS)


def parse_csv_line(headers, line):
    try:
        row = next(csv.reader([line]))
    except Exception as e:
        return None
    if len(row) < len(headers):
        return None
    return dict(zip(headers, row))


def build_test_metrics(registry):
    return {
        "frame": Histogram("presentmon_frame_time_milliseconds", "frame", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "cpu_busy": Histogram("presentmon_cpu_busy_milliseconds", "cpu_busy", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "cpu_wait": Histogram("presentmon_cpu_wait_milliseconds", "cpu_wait", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "gpu_busy": Histogram("presentmon_gpu_busy_milliseconds", "gpu_busy", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "gpu_wait": Histogram("presentmon_gpu_wait_milliseconds", "gpu_wait", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "gpu_latency": Histogram("presentmon_gpu_latency_milliseconds", "gpu_latency", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "display_latency": Histogram("presentmon_display_latency_milliseconds", "display_latency", LABELS, buckets=DISPLAY_BUCKETS, registry=registry),
        "click_to_photon": Histogram("presentmon_click_to_photon_milliseconds", "click_to_photon", LABELS, buckets=DISPLAY_BUCKETS, registry=registry),
        "up": Gauge("presentmon_up", "up", registry=registry),
        "frames_total": Counter("presentmon_frames_total", "frames_total", LABELS, registry=registry),
    }


def live_metrics():
    metrics = {}
    metrics["frame"] = presentmon_frame_time_milliseconds
    metrics["cpu_busy"] = presentmon_cpu_busy_milliseconds
    metrics["cpu_wait"] = presentmon_cpu_wait_milliseconds
    metrics["gpu_busy"] = presentmon_gpu_busy_milliseconds
    metrics["gpu_wait"] = presentmon_gpu_wait_milliseconds
    metrics["gpu_latency"] = presentmon_gpu_latency_milliseconds
    metrics["display_latency"] = presentmon_display_latency_milliseconds
    metrics["click_to_photon"] = presentmon_click_to_photon_milliseconds
    metrics["up"] = presentmon_up
    metrics["frames_total"] = presentmon_frames_total
    return metrics


def observe(metrics, app, row, seen, lock):
    with lock:
        for key, col in [
            ("frame", "MsBetweenPresents"),
            ("cpu_busy", "MsCPUBusy"),
            ("cpu_wait", "MsCPUWait"),
            ("gpu_busy", "MsGPUBusy"),
            ("gpu_wait", "MsGPUWait"),
            ("gpu_latency", "MsGPULatency"),
            ("display_latency", "DisplayLatency"),
            ("click_to_photon", "MsClickToPhotonLatency"),
        ]:
            val = row.get(col, "")
            if val and val != "NA":
                metrics[key].labels(app).observe(float(val))
        metrics["frames_total"].labels(app).inc()
        seen[app] = time.time()


def cleanup_stale(metrics, seen, lock, timeout_seconds):
    removed = []
    with lock:
        now = time.time()
        for app, last in list(seen.items()):
            if now - last <= timeout_seconds:
                continue
            for key in STALE_KEYS:
                metrics[key].remove(app)
            del seen[app]
            removed.append(app)
    return removed


class CleanupCollector:
    def __init__(self, metrics, seen, lock, timeout_seconds):
        self.metrics = metrics
        self.seen = seen
        self.lock = lock
        self.timeout_seconds = timeout_seconds

    def collect(self):
        cleanup_stale(self.metrics, self.seen, self.lock, self.timeout_seconds)
        return []


def read_presentmon(metrics, seen, lock):
    command = [PRESENTMON_PATH, "--output_stdout", "--stop_existing_session"]
    while True:
        process = None
        headers = None
        try:
            process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)
            metrics["up"].set(1)
            stdout = process.stdout
            if stdout is None:
                raise Exception("PresentMon stdout unavailable")
            for raw in stdout:
                line = raw.strip()
                if not line:
                    continue
                if headers is None:
                    headers = [h.strip("\ufeff ") for h in next(csv.reader([line]))]
                    continue
                parsed = parse_csv_line(headers, line)
                if not parsed:
                    continue
                app = os.path.basename(parsed.get("Application", "").strip())
                if not app:
                    continue
                try:
                    observe(metrics, app, parsed, seen, lock)
                except Exception as e:
                    continue
            metrics["up"].set(0)
            sys.stderr.write("PresentMon subprocess exited")
            err = process.stderr.read().strip() if process.stderr else ""
            if err:
                sys.stderr.write(": " + err)
            sys.stderr.write("\n")
        except Exception as e:
            metrics["up"].set(0)
            sys.stderr.write("PresentMon reader error: " + str(e) + "\n")
        finally:
            if process and process.poll() is None:
                process.kill()
        time.sleep(5)


def run_tests():
    registry = CollectorRegistry()
    metrics = build_test_metrics(registry)
    seen = {}
    lock = threading.Lock()
    registry.register(CleanupCollector(metrics, seen, lock, 60))
    try:
        sample = "Application,MsBetweenPresents,MsCPUBusy,MsCPUWait,MsGPULatency,MsGPUBusy,MsGPUWait,DisplayLatency,MsClickToPhotonLatency\nsteam.exe,16.6,5.2,3.1,1.5,4.2,2.1,12.5,8.3"
        head, row = sample.splitlines()
        parsed = parse_csv_line(next(csv.reader([head])), row)
        if not parsed or parsed.get("Application") != "steam.exe" or parsed.get("MsGPUBusy") != "4.2":
            raise Exception("Test 1 failed")
        observe(metrics, "steam.exe", parsed, seen, lock)
        sample2 = "Application,MsBetweenPresents,MsCPUBusy,MsCPUWait,MsGPULatency,MsGPUBusy,MsGPUWait,DisplayLatency,MsClickToPhotonLatency\ncs2.exe,8.3,3.1,1.2,0.8,6.5,0.5,9.2,NA"
        head2, row2 = sample2.splitlines()
        parsed2 = parse_csv_line(next(csv.reader([head2])), row2)
        if not parsed2 or parsed2.get("Application") != "cs2.exe":
            raise Exception("Test 2 failed")
        observe(metrics, "cs2.exe", parsed2, seen, lock)
        cs2_count = 0
        for metric in registry.collect():
            if metric.name != "presentmon_frame_time_milliseconds":
                continue
            for sample_metric in metric.samples:
                if sample_metric.name == "presentmon_frame_time_milliseconds_count" and sample_metric.labels.get("application") == "cs2.exe":
                    cs2_count = sample_metric.value
        if cs2_count < 1:
            raise Exception("Test 2 failed: cs2.exe frame count not recorded despite NA in MsClickToPhotonLatency")
        with lock:
            seen["old.exe"] = time.time() - 999
        if "old.exe" not in cleanup_stale(metrics, seen, lock, 60):
            raise Exception("Test 4 failed")
        buckets = []
        for metric in registry.collect():
            if metric.name != "presentmon_frame_time_milliseconds":
                continue
            for sample_metric in metric.samples:
                le = sample_metric.labels.get("le")
                if sample_metric.name.endswith("_bucket") and le and le != "+Inf":
                    le_float = float(le)
                    if le_float not in buckets:
                        buckets.append(le_float)
        if buckets != FRAME_BUCKETS:
            raise Exception("Test 5 failed")
        probe = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
        probe.close()
        _ = start_http_server(port, addr="127.0.0.1", registry=registry)
        time.sleep(0.2)
        payload = urllib.request.urlopen("http://127.0.0.1:" + str(port) + "/metrics", timeout=2).read().decode("utf-8")
        if "presentmon_frame_time_milliseconds_bucket" not in payload or "presentmon_up" not in payload:
            raise Exception("Test 6 failed")
        with open(os.path.join(".sisyphus", "evidence", "task-1-metrics-format.txt"), "w", encoding="utf-8") as handle:
            _ = handle.write(payload)
        print("All tests passed")
        sys.exit(0)
    except Exception as e:
        print(str(e))
        sys.exit(1)


def main():
    if "--test" in sys.argv:
        run_tests()
    metrics = live_metrics()
    seen = {}
    lock = threading.Lock()
    from prometheus_client import REGISTRY

    REGISTRY.register(CleanupCollector(metrics, seen, lock, STALE_TIMEOUT))
    _ = start_http_server(METRICS_PORT)
    thread = threading.Thread(target=read_presentmon, args=(metrics, seen, lock), daemon=True)
    thread.start()
    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()
