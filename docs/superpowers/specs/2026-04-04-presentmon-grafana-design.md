# Spec: PresentMon High-Resolution Performance Dashboard

## 1. Overview
A specialized Grafana dashboard for analyzing game performance metrics captured via Intel PresentMon (exported to Prometheus). The dashboard focuses on frame-time consistency, stutter detection (1% / 0.1% lows), and hardware correlation.

## 2. Architecture & Variables
The dashboard uses a **modular JSON model** intended for updates via the Grafana Dashboard Mutation API (JSON Patch).

### Variables
- `$Process`: `label_values(presentmon_frame_time_ms_count, process_name)`
- `$GPU`: `label_values(presentmon_frame_time_ms_count, gpu_name)`
- `$Resolution`: `label_values(presentmon_frame_time_ms_count, resolution)`
- `$Interval`: Default `$__rate_interval`

## 3. Visualization Strategy

### Zone 1: Global Summary (Top Row)
- **Current FPS**: `sum(rate(presentmon_frame_time_ms_count{process_name=~"$Process"}[$__rate_interval]))`
- **Median Frame Time (p50)**: `histogram_quantile(0.50, sum by (le) (rate(presentmon_frame_time_ms_bucket{process_name=~"$Process"}[$__rate_interval])))`
- **1% Lows (p99)**: `histogram_quantile(0.99, ...)`
- **Jank Index**: Ratio of p99 to p50. Threshold > 2.0 indicates perceivable stutter.

### Zone 2: Distribution & Consistency (Middle Row)
- **Heatmap (Frame Time Distribution)**: 
  - Data: `presentmon_frame_time_ms_bucket`
  - Mode: Time series buckets
  - Purpose: Visualizes "clumpiness" of frame delivery.
- **Time Series (p99/p99.9 Overlay)**:
  - Tracks the worst frames over time to identify specific hitching events.

### Zone 3: Hardware Context (Collapsed Row)
- **GPU Busy vs Frame Time**: Identifies if bottlenecks are GPU-bound or CPU-bound.
- **Clock Speeds**: Correlation with thermal throttling or power limits.

## 4. Implementation Details (API)

### Grid Positioning (`gridPos`)
- Standard 24-column grid.
- Stat Panels: `w: 6, h: 4`
- Heatmap: `w: 18, h: 8`
- Side Charts: `w: 6, h: 8`

### Collapsed Row Pitfall Prevention
- Nested panels MUST be in the row's internal `panels` array in the JSON model.
- Expansion logic handled by Grafana; API patches should target `$.panels[?(@.type=='row' && @.title=='Hardware Context')].panels`.

## 5. Success Criteria
- [ ] p99 frame times accurately reflect perceived "stutter".
- [ ] Heatmap correctly visualizes frame time density.
- [ ] Variables correctly filter across all panels.
- [ ] Patch API operations successfully add/update panels without breaking layout.
