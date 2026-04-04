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

FRAME_BUCKETS = [1, 2, 4, 8, 10, 12, 16.6, 20, 25, 33.3, 50, 75, 100, 150, 200, 500]
DISPLAY_BUCKETS = [5, 10, 16.6, 20, 25, 33.3, 50, 75, 100, 150, 200, 250, 500]
LABELS = ["application"]
STALE_KEYS = ["frame", "cpu_busy", "cpu_wait", "gpu_busy", "gpu_wait", "gpu_latency", "display_latency", "click_to_photon", "frames_total", "gpu_time", "displayed_time", "animation_error", "all_input_to_photon", "in_present_api", "between_display_change", "until_displayed", "render_present_latency", "between_simulation_start", "between_app_start", "pc_latency", "allows_tearing"]

presentmon_frame_time_milliseconds = Histogram("presentmon_frame_time_milliseconds", "Frame time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_cpu_busy_milliseconds = Histogram("presentmon_cpu_busy_milliseconds", "CPU busy time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_cpu_wait_milliseconds = Histogram("presentmon_cpu_wait_milliseconds", "CPU wait time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_gpu_busy_milliseconds = Histogram("presentmon_gpu_busy_milliseconds", "GPU busy time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_gpu_wait_milliseconds = Histogram("presentmon_gpu_wait_milliseconds", "GPU wait time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_gpu_latency_milliseconds = Histogram("presentmon_gpu_latency_milliseconds", "GPU latency in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_display_latency_milliseconds = Histogram("presentmon_display_latency_milliseconds", "Display latency in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_click_to_photon_milliseconds = Histogram("presentmon_click_to_photon_milliseconds", "Click to photon latency in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_gpu_time_milliseconds = Histogram("presentmon_gpu_time_milliseconds", "GPU time in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_displayed_time_milliseconds = Histogram("presentmon_displayed_time_milliseconds", "Displayed time in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_animation_error_milliseconds = Histogram("presentmon_animation_error_milliseconds", "Animation error absolute value in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_all_input_to_photon_milliseconds = Histogram("presentmon_all_input_to_photon_milliseconds", "All input to photon latency in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_in_present_api_milliseconds = Histogram("presentmon_in_present_api_milliseconds", "Time in Present API in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_between_display_change_milliseconds = Histogram("presentmon_between_display_change_milliseconds", "Time between display changes in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_until_displayed_milliseconds = Histogram("presentmon_until_displayed_milliseconds", "Time until displayed in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_render_present_latency_milliseconds = Histogram("presentmon_render_present_latency_milliseconds", "Render present latency in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_between_simulation_start_milliseconds = Histogram("presentmon_between_simulation_start_milliseconds", "Time between simulation starts in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_between_app_start_milliseconds = Histogram("presentmon_between_app_start_milliseconds", "Time between app frame starts in milliseconds", LABELS, buckets=FRAME_BUCKETS)
presentmon_pc_latency_milliseconds = Histogram("presentmon_pc_latency_milliseconds", "PC latency in milliseconds", LABELS, buckets=DISPLAY_BUCKETS)
presentmon_app_info = Gauge("presentmon_app_info", "Application presentation info", ["application", "present_mode", "present_runtime", "frame_type"])
presentmon_allows_tearing = Gauge("presentmon_allows_tearing", "Whether application allows tearing", LABELS)
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
        "gpu_time": Histogram("presentmon_gpu_time_milliseconds", "gpu_time", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "displayed_time": Histogram("presentmon_displayed_time_milliseconds", "displayed_time", LABELS, buckets=DISPLAY_BUCKETS, registry=registry),
        "animation_error": Histogram("presentmon_animation_error_milliseconds", "animation_error", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "all_input_to_photon": Histogram("presentmon_all_input_to_photon_milliseconds", "all_input_to_photon", LABELS, buckets=DISPLAY_BUCKETS, registry=registry),
        "in_present_api": Histogram("presentmon_in_present_api_milliseconds", "in_present_api", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "between_display_change": Histogram("presentmon_between_display_change_milliseconds", "between_display_change", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "until_displayed": Histogram("presentmon_until_displayed_milliseconds", "until_displayed", LABELS, buckets=DISPLAY_BUCKETS, registry=registry),
        "render_present_latency": Histogram("presentmon_render_present_latency_milliseconds", "render_present_latency", LABELS, buckets=DISPLAY_BUCKETS, registry=registry),
        "between_simulation_start": Histogram("presentmon_between_simulation_start_milliseconds", "between_simulation_start", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "between_app_start": Histogram("presentmon_between_app_start_milliseconds", "between_app_start", LABELS, buckets=FRAME_BUCKETS, registry=registry),
        "pc_latency": Histogram("presentmon_pc_latency_milliseconds", "pc_latency", LABELS, buckets=DISPLAY_BUCKETS, registry=registry),
        "app_info": Gauge("presentmon_app_info", "app_info", ["application", "present_mode", "present_runtime", "frame_type"], registry=registry),
        "allows_tearing": Gauge("presentmon_allows_tearing", "allows_tearing", LABELS, registry=registry),
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
    metrics["gpu_time"] = presentmon_gpu_time_milliseconds
    metrics["displayed_time"] = presentmon_displayed_time_milliseconds
    metrics["animation_error"] = presentmon_animation_error_milliseconds
    metrics["all_input_to_photon"] = presentmon_all_input_to_photon_milliseconds
    metrics["in_present_api"] = presentmon_in_present_api_milliseconds
    metrics["between_display_change"] = presentmon_between_display_change_milliseconds
    metrics["until_displayed"] = presentmon_until_displayed_milliseconds
    metrics["render_present_latency"] = presentmon_render_present_latency_milliseconds
    metrics["between_simulation_start"] = presentmon_between_simulation_start_milliseconds
    metrics["between_app_start"] = presentmon_between_app_start_milliseconds
    metrics["pc_latency"] = presentmon_pc_latency_milliseconds
    metrics["app_info"] = presentmon_app_info
    metrics["allows_tearing"] = presentmon_allows_tearing
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
            ("gpu_time", "MsGPUTime"),
            ("displayed_time", "DisplayedTime"),
            ("animation_error", "MsAnimationError"),
            ("all_input_to_photon", "MsAllInputToPhotonLatency"),
            ("in_present_api", "MsInPresentAPI"),
            ("between_display_change", "MsBetweenDisplayChange"),
            ("until_displayed", "MsUntilDisplayed"),
            ("render_present_latency", "MsRenderPresentLatency"),
            ("between_simulation_start", "MsBetweenSimulationStart"),
            ("between_app_start", "MsBetweenAppStart"),
            ("pc_latency", "MsPCLatency"),
        ]:
            val = row.get(col, "")
            if val and val != "NA":
                v = float(val)
                if key == "animation_error":
                    v = abs(v)
                metrics[key].labels(app).observe(v)
        pm = row.get("PresentMode", "")
        rt = row.get("PresentRuntime", "")
        ft = row.get("FrameType", "")
        if pm or rt or ft:
            metrics["app_info"].labels(application=app, present_mode=pm, present_runtime=rt, frame_type=ft).set(1)
        at = row.get("AllowsTearing", "")
        if at and at != "NA":
            metrics["allows_tearing"].labels(app).set(float(at))
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
        sample = "Application,MsBetweenPresents,MsCPUBusy,MsCPUWait,MsGPULatency,MsGPUBusy,MsGPUWait,DisplayLatency,MsClickToPhotonLatency,MsGPUTime,DisplayedTime,MsAnimationError,MsAllInputToPhotonLatency,MsInPresentAPI,MsBetweenDisplayChange,MsUntilDisplayed,MsRenderPresentLatency,MsBetweenSimulationStart,MsBetweenAppStart,MsPCLatency,PresentMode,PresentRuntime,FrameType,AllowsTearing\nsteam.exe,16.6,5.2,3.1,1.5,4.2,2.1,12.5,8.3,6.3,16.7,0.5,25.0,0.3,16.6,14.2,8.1,16.5,16.6,22.0,Hardware: Independent Flip,DXGI,Application,1"
        head, row = sample.splitlines()
        parsed = parse_csv_line(next(csv.reader([head])), row)
        if not parsed or parsed.get("Application") != "steam.exe" or parsed.get("MsGPUBusy") != "4.2":
            raise Exception("Test 1 failed")
        observe(metrics, "steam.exe", parsed, seen, lock)
        sample2 = "Application,MsBetweenPresents,MsCPUBusy,MsCPUWait,MsGPULatency,MsGPUBusy,MsGPUWait,DisplayLatency,MsClickToPhotonLatency,MsGPUTime,DisplayedTime,MsAnimationError,MsAllInputToPhotonLatency,MsInPresentAPI,MsBetweenDisplayChange,MsUntilDisplayed,MsRenderPresentLatency,MsBetweenSimulationStart,MsBetweenAppStart,MsPCLatency,PresentMode,PresentRuntime,FrameType,AllowsTearing\ncs2.exe,8.3,3.1,1.2,0.8,6.5,0.5,9.2,NA,7.0,NA,-1.2,15.5,0.2,8.3,7.1,4.5,8.2,8.3,12.0,Hardware: Independent Flip,DXGI,Application,0"
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
        new_metric_names = [
            "presentmon_gpu_time_milliseconds_bucket",
            "presentmon_displayed_time_milliseconds_bucket",
            "presentmon_animation_error_milliseconds_bucket",
            "presentmon_all_input_to_photon_milliseconds_bucket",
            "presentmon_in_present_api_milliseconds_bucket",
            "presentmon_between_display_change_milliseconds_bucket",
            "presentmon_until_displayed_milliseconds_bucket",
            "presentmon_render_present_latency_milliseconds_bucket",
            "presentmon_between_simulation_start_milliseconds_bucket",
            "presentmon_between_app_start_milliseconds_bucket",
            "presentmon_pc_latency_milliseconds_bucket",
            "presentmon_app_info",
            "presentmon_allows_tearing",
        ]
        for name in new_metric_names:
            if name not in payload:
                raise Exception("Test 7 failed: " + name + " not in /metrics output")
        animation_count = 0
        for metric in registry.collect():
            if metric.name != "presentmon_animation_error_milliseconds":
                continue
            for sample_metric in metric.samples:
                if sample_metric.name == "presentmon_animation_error_milliseconds_count" and sample_metric.labels.get("application") == "cs2.exe":
                    animation_count = sample_metric.value
        if animation_count < 1:
            raise Exception("Test 8 failed: cs2.exe animation_error not observed (expected abs(-1.2) to be recorded)")
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
