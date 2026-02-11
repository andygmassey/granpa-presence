# Dad Presence - Project Status

**Last Updated:** 2026-02-08

## Overall Status: OPERATIONAL

The monitoring system is fully operational with presence sensors, cameras, dashboards, and all automations configured and tuned for Dad's schedule.

---

## Completed Tasks

### Infrastructure
- [x] Docker Compose stack deployed (HA + InfluxDB + Grafana)
- [x] Home Assistant running on port 8123
- [x] InfluxDB running on port 8086
- [x] Grafana running on port 3000
- [x] All containers set to auto-restart
- [x] Watchdog script installed (runs every 5 mins via cron)
- [x] Auto-start on boot configured (@reboot cron job)
- [x] D-Bus mount added for Bluetooth support
- [x] Hardware watchdog enabled (30s kernel freeze detection)
- [x] SD card health monitoring (I/O error detection)

### Home Assistant Configuration
- [x] HACS installed and activated
- [x] Xiaomi Miot Auto integration installed via HACS
- [x] Xiaomi Mi account connected (filtered to "Grandpa" home only)
- [x] Bedroom presence sensor discovered and working
- [x] Shower room presence sensor working
- [x] Reolink E1 Pro cameras integrated (Living Room + Conservatory)
- [x] Email notifications configured (Gmail SMTP with HTML)
- [x] Input helpers created (dad_last_activity, dad_bed_time, etc.)
- [x] input_boolean.dad_monitoring_enabled created
- [x] Template sensor binary_sensor.bedroom_occupied created
- [x] System health sensors configured (CPU temp, disk usage, uptime)
- [x] Status dashboard configured (YAML mode)
- [x] Lovelace dashboard with live camera feeds

### Grafana
- [x] InfluxDB datasource configured
- [x] Dad Presence Patterns dashboard imported
- [x] Today vs Historical Average panel
- [x] 7-Day Activity Trend panel
- [x] First/Last Activity stat panels
- [x] Room activity timelines
- [x] Activity Heatmap panel

### Automations Deployed (Tuned for Dad's Schedule)

Dad typically goes to bed 11pm-midnight and wakes 6-7am.

- [x] Dad - Track Last Activity (presence + camera motion)
- [x] Dad - Daytime No Activity Alert (configurable, 7am-11pm)
- [x] Dad - Nighttime No Activity Alert (configurable, 11pm-7am)
- [x] Dad - Morning Activity Check (8am)
- [x] Dad - Daily Activity Summary (8am)
- [x] Dad - Detect Bed Time (after 10pm)
- [x] Dad - Detect Wake Time (5am-10am)
- [x] Dad - Late Wake Alert (45 mins past avg)
- [x] Dad - Low Battery Alert (< 25%)
- [x] Dad - Disk Space Alert (> 80%)
- [x] Dad - Overheating Alert (> 75C)
- [x] Dad - Motion Snapshot Living Room
- [x] Dad - Motion Snapshot Conservatory
- [x] Dad - Xiaomi Cloud Offline Detection
- [x] Dad - Xiaomi Cloud Online Detection
- [x] Dad - Xiaomi Quick Reload (Tier 1 - silent)
- [x] Dad - Xiaomi Auto-Restart (Tier 2 - with notification)
- [x] Dad - Xiaomi Auth Failure Alert
- [x] Dad - Xiaomi Cloud Extended Outage Alert
- [x] Dad - Xiaomi Cloud Recovered
- [x] Dad - SD Card Errors Alert
- [x] Dad - Shower Room Extended Presence
- [x] Dad - Bathroom Visit Counter
- [x] Deepgram Low Balance / Critical Balance Alerts

---

## Current System State

### Docker Containers
```
NAMES           STATUS          PORTS
homeassistant   Up              (host network)
influxdb        Up              0.0.0.0:8086->8086/tcp
grafana         Up              0.0.0.0:3000->3000/tcp
```

### Working Entities

| Entity ID | Purpose |
|-----------|---------|
| sensor.xiaomi_03_85df_occupancy_sensor | Bedroom presence |
| sensor.xiaomi_03_85df_battery_level | Sensor battery % |
| binary_sensor.bedroom_occupied | Template sensor |
| sensor.xiaomi_03_b987_occupancy_sensor | Shower room presence |
| sensor.xiaomi_03_b987_battery_level | Shower room sensor battery % |
| binary_sensor.shower_room_occupied | Template sensor |
| binary_sensor.gramps_living_room_motion | Living Room camera motion |
| binary_sensor.gramps_conservatory_motion | Conservatory camera motion |
| camera.gramps_living_room_fluent | Living Room camera stream |
| camera.gramps_conservatory_fluent | Conservatory camera stream |
| sensor.cpu_temperature | Pi CPU temp |
| sensor.disk_usage_percent | Disk usage |
| sensor.system_uptime | System uptime |
| sensor.sd_card_errors | SD card I/O errors |
| sensor.deepgram_balance | Deepgram API credit balance |

### Input Helpers

| Entity ID | Purpose |
|-----------|---------|
| input_boolean.dad_monitoring_enabled | Master enable for alerts |
| input_boolean.xiaomi_cloud_available | Xiaomi cloud status |
| input_datetime.dad_last_activity | Last detected activity |
| input_datetime.dad_bed_time | Detected bedtime |
| input_datetime.dad_wake_time | Detected wake time |
| input_datetime.dad_avg_wake_time | Rolling average wake time |
| input_datetime.dad_bedroom_entry_time | Bedroom entry timestamp |
| input_datetime.bedroom_sensor_last_update | Bedroom sensor freshness |
| input_datetime.shower_room_sensor_last_update | Shower sensor freshness |
| input_datetime.xiaomi_last_restart | Rate-limits auto-restart |
| input_datetime.xiaomi_last_quick_reload | Rate-limits quick reload |
| input_datetime.xiaomi_recovery_notification_sent | Rate-limits recovery email |
| input_number.daytime_alert_hours | Daytime alert threshold (configurable) |
| input_number.nighttime_alert_hours | Nighttime alert threshold (configurable) |
| counter.dad_bathroom_visits | Daily bathroom visit counter |

---

## Credentials

All credentials are stored in gitignored files:
- **`homeassistant/secrets.yaml`** - HA secrets
- **`.env`** - Docker environment variables

---

## Files on Pi

| File | Purpose | Status |
|------|---------|--------|
| ~/docker-compose.yml | Container orchestration | Deployed |
| ~/.env | Docker credentials | Deployed (not in repo) |
| ~/ha-config/configuration.yaml | HA main config | Deployed |
| ~/ha-config/secrets.yaml | HA secrets | Deployed (not in repo) |
| ~/ha-config/automations.yaml | Monitoring automations | Deployed |
| ~/ha-config/dashboards/status.yaml | Status dashboard | Deployed |
| ~/watchdog.sh | Container health check | Deployed |
| ~/influxdb-data/ | InfluxDB data | Created |
| ~/grafana-data/ | Grafana data | Created |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.6.2 | 2026-02-08 | Add Xiaomi auth failure alert |
| v1.6.1 | 2026-02-06 | Fix auto-restart to check hourly instead of once |
| v1.6 | 2026-02-04 | Fix bed time detection - trigger-based template sensors |
| v1.5.2 | 2026-02-01 | Reduce quick reload rate limit to 10 mins |
| v1.5.1 | 2026-02-01 | Fix quick reload timing, full system audit |
| v1.5 | 2026-02-01 | Two-tier Xiaomi recovery |
| v1.4.3 | 2026-02-01 | Daily summary alignment |
| v1.4.2 | 2026-01-19 | Timezone fix |
| v1.4.1 | 2026-01 | Email notification rate limiting |
| v1.4 | 2026-01 | Sensor staleness tracking & auto-recovery |
| v1.3.1 | 2026-01-17 | Fixed cloud recovery email spam |
| v1.3.0 | 2026-01-17 | Fixed bed time detection - two-step approach |
| v1.2.0 | 2026-01-01 | Reliability improvements |
| v1.1.0 | 2026-01-01 | Reolink cameras, Grafana, tuned automations |
| v1.0.0 | 2024-12-29 | Initial setup |
