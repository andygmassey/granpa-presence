# Dad Presence - Elderly Monitoring System

A Home Assistant-based monitoring system for remotely keeping an eye on Dad, with automated alerts, activity pattern tracking, and self-healing infrastructure.

## Overview

This system monitors activity in Dad's home using presence sensors and cameras, sending alerts when unusual patterns are detected (e.g., no movement for extended periods, late wake-up). Designed for reliability with multiple watchdog layers and automatic recovery.

## Current Status: OPERATIONAL

See [STATUS.md](STATUS.md) for detailed current state.

### What's Working
- Home Assistant + InfluxDB + Grafana stack running
- Xiaomi Miot integration with bedroom presence sensor
- Reolink E1 Pro cameras (Living Room + Conservatory)
- Grafana dashboards with activity patterns
- HA Status dashboard with live camera feeds
- All monitoring automations (tuned for Dad's schedule)
- Email notifications with HTML formatting
- System health monitoring
- Watchdog scripts running

## Hardware

### Current
- **Raspberry Pi 5** - Running Home Assistant Core in Docker
- **Xiaomi Smart Home Hub 2** (lumi.gateway.mcn001) - Gateway for presence sensors
- **Xiaomi Human Presence Sensor** x2 - Bedroom and Shower Room
- **Reolink E1 Pro** x2 - Living Room and Conservatory

## Network Configuration

| Device | Notes |
|--------|-------|
| Raspberry Pi 5 | LAN + Tailscale VPN |
| Home Assistant | Port 8123 |
| InfluxDB | Port 8086 |
| Grafana | Port 3000 |
| Xiaomi Hub | Local network |
| Reolink cameras x2 | Local network |

**Note:** IP addresses are deployment-specific. See `secrets.yaml` and `.env` for your configuration.

## Credentials

All credentials are managed through:
- **`homeassistant/secrets.yaml`** - HA secrets (SMTP, API keys, camera passwords, email recipients)
- **`.env`** - Docker environment variables (InfluxDB, Grafana admin passwords)

**These files are gitignored and must never be committed.** See `.env.example` and `homeassistant/secrets.yaml.example` for the required variables.

## Features

### Activity Monitoring
- **Presence detection** in bedroom and shower room (Xiaomi Human Presence Sensors)
- **Motion detection** in Living Room and Conservatory (Reolink cameras)
- **Last activity tracking** with timestamp
- **Sleep pattern tracking** - Bed time, wake time, rolling average

### Automated Alerts (Tuned for Dad)

Dad typically goes to bed 11pm-midnight and wakes 6-7am.

| Alert | Trigger | Active Hours |
|-------|---------|--------------|
| No Activity (Day) | Configurable hours, no detection | 7am - 11pm |
| No Activity (Night) | Configurable hours, no detection | 11pm - 7am |
| Morning Check | No activity since midnight | 8am |
| Late Wake | 45 mins past average wake time | 5am - 10am |
| Daily Summary | Status report | 8am |
| Low Battery | Sensor < 25% | Always |
| System Health | Disk > 80%, CPU > 75C | Always |

### Dashboards

**Home Assistant Dashboard** includes:
- Status header with last activity and weather
- Room status (Bedroom, Shower Room, Living Room, Conservatory)
- Sleep pattern tracking with duration
- Live camera feeds
- Sensor batteries
- Monitoring settings
- System health
- Embedded Grafana charts

**Grafana Dashboard** includes:
- Today vs Historical Average activity
- 7-Day Activity Trend
- First/Last Activity stats
- Room-by-room activity timelines
- Activity Heatmap

### System Health & Reliability
- Docker container watchdog (every 5 mins via cron)
- Auto-restart on boot (via cron @reboot)
- Hardware watchdog (30s kernel freeze detection)
- CPU temperature monitoring
- Disk usage monitoring
- SD card I/O error detection
- Stale sensor detection (alerts if Xiaomi stops updating)
- Two-tier auto-recovery for Xiaomi cloud issues

## Architecture

```
+---------------------------------------------------------------+
|                        Remote Access                           |
|                    (Tailscale VPN)                             |
+---------------------------------------------------------------+
                              |
                              v
+---------------------------------------------------------------+
|                     Raspberry Pi 5                             |
|  +----------------------------------------------------------+ |
|  |              Docker Compose Stack                         | |
|  |  +--------------+  +------------+  +-----------------+    | |
|  |  |    Home      |  |  InfluxDB  |  |    Grafana      |    | |
|  |  |  Assistant   |  | (365 days) |  |  (dashboards)   |    | |
|  |  |    :8123     |  |   :8086    |  |     :3000       |    | |
|  |  +--------------+  +------------+  +-----------------+    | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
                              |
          +-------------------+-------------------+
          v                   v                   v
   +-----------+       +-----------+       +-----------+
   |  Xiaomi   |       |  Reolink  |       |  Reolink  |
   |  Gateway  |       |  E1 Pro   |       |  E1 Pro   |
   +-----------+       +-----------+       +-----------+
          |            Living Room        Conservatory
          v
   +-----------+
   | Presence  |
   | Sensors   |
   | (x2)      |
   +-----------+
```

## File Structure on Pi

```
/home/massey/
├── docker-compose.yml      # HA + InfluxDB + Grafana stack
├── .env                    # Docker credentials (not in repo)
├── ha-config/              # Home Assistant config (mounted to container)
│   ├── configuration.yaml  # Main HA config
│   ├── automations.yaml    # Monitoring automations
│   ├── secrets.yaml        # HA secrets (not in repo)
│   ├── dashboards/
│   │   └── status.yaml     # Status dashboard
│   ├── www/snapshots/      # Camera snapshots
│   └── custom_components/
│       └── hacs/           # HACS integration
├── influxdb-data/          # InfluxDB data volume
├── influxdb-config/        # InfluxDB config volume
├── grafana-data/           # Grafana data volume
├── watchdog.sh             # Container health check script
└── watchdog.log            # Watchdog log file
```

## Quick Reference Commands

### SSH Access
```bash
ssh massey@<TAILSCALE_IP>
```

### Docker Commands
```bash
# Check container status
docker ps

# Restart all containers
cd ~ && docker compose restart

# View HA logs
docker logs homeassistant --tail 50
```

## Setup

1. Clone this repo to your Pi
2. Copy `.env.example` to `.env` and fill in credentials
3. Copy `homeassistant/secrets.yaml.example` to `homeassistant/secrets.yaml` and fill in credentials
4. Run `docker compose up -d`
5. Configure Xiaomi Miot Auto and Reolink integrations in HA UI

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.6.2 | 2026-02-08 | Add Xiaomi auth failure alert |
| v1.6.1 | 2026-02-06 | Fix auto-restart to check hourly instead of once |
| v1.6 | 2026-02-04 | Fix bed time detection - use trigger-based template sensors |
| v1.5.2 | 2026-02-01 | Reduce quick reload rate limit to 10 mins |
| v1.5.1 | 2026-02-01 | Fix quick reload timing and document full system audit |
| v1.5 | 2026-02-01 | Two-tier Xiaomi recovery (quick reload + persistent issue alert) |
| v1.4.3 | 2026-02-01 | Daily summary alignment (08:00, emoji prefixes) |
| v1.4.2 | 2026-01-19 | Timezone fix (Europe/London) |
| v1.4.1 | 2026-01 | Email notification rate limiting |
| v1.4 | 2026-01 | Sensor staleness tracking & auto-recovery |
| v1.3.1 | 2026-01-17 | Fixed cloud recovery email spam |
| v1.3.0 | 2026-01-17 | Fixed bed time detection - two-step approach |
| v1.2.0 | 2026-01-01 | Reliability improvements: hardware watchdog, SD card monitoring |
| v1.1.0 | 2026-01-01 | Reolink cameras, Grafana dashboards, tuned automations |
| v1.0.0 | 2024-12-29 | Initial setup |
