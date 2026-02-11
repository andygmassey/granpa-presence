# Grandpa Presence - Elderly Monitoring System

A Home Assistant-based system for remotely monitoring an elderly relative's daily activity, with automated alerts, sleep pattern tracking, and self-healing infrastructure. Built on a Raspberry Pi with Xiaomi presence sensors and Reolink cameras.

> This project was built to monitor my elderly father living alone, but it can be adapted for any family member or care situation. See [CUSTOMISING.md](CUSTOMISING.md) for how to adapt it to your setup.

<!-- TODO: Add screenshot of HA dashboard here -->
<!-- ![Dashboard Screenshot](docs/images/dashboard.png) -->

## Why This Exists

When an elderly parent lives alone, you worry. Are they up at their usual time? Have they moved around today? Did they get up in the night? This system provides peace of mind by:

- Sending a **daily summary** email each morning with sleep patterns and activity
- Alerting the family if **no activity is detected** for an unusual period
- Detecting **late wake-ups** compared to their normal routine
- Tracking **sleep patterns** over time (bed time, wake time, trends)
- **Self-healing** when sensors go offline (automatic restart, two-tier recovery)
- Working **passively** - no wearables, no buttons to press, no behaviour change required

## Hardware Shopping List

| Item | Purpose | Approx. Cost |
|------|---------|-------------|
| [Raspberry Pi 5](https://www.raspberrypi.com/products/raspberry-pi-5/) (4GB+) | Runs Home Assistant, InfluxDB, Grafana | ~£60 |
| microSD card (32GB+) or NVMe SSD | Pi storage | ~£10-30 |
| USB-C power supply for Pi 5 | Power | ~£12 |
| [Xiaomi Smart Home Hub 2](https://www.mi.com/global/product/xiaomi-smart-home-hub-2) | Gateway for presence sensors | ~£30 |
| [Xiaomi Human Presence Sensor](https://www.mi.com/global/product/xiaomi-human-presence-sensor) x1-3 | Detects presence in rooms (mmWave, not PIR) | ~£25 each |
| [Reolink E1 Pro](https://reolink.com/product/e1-pro/) x1-2 (optional) | Motion detection + snapshots | ~£35 each |

**Total: ~£170-250** depending on number of sensors and cameras.

The Xiaomi Human Presence Sensors use mmWave radar, not PIR - they detect **stationary presence** (sitting, sleeping), not just movement. This is critical for elderly monitoring where someone may be still for long periods.

## Features

### Activity Monitoring
- **Presence detection** via Xiaomi mmWave sensors (detects sitting/sleeping, not just movement)
- **Motion detection** via Reolink cameras (optional, covers additional rooms)
- **Last activity tracking** with timestamp
- **Sleep pattern tracking** - bed time, wake time, rolling average
- **Bathroom visit counting**

### Automated Alerts

All time windows and thresholds are configurable via the HA dashboard.

| Alert | Trigger | Default Active Hours |
|-------|---------|---------------------|
| No Activity (Day) | Configurable hours, no detection | 7am - 11pm |
| No Activity (Night) | Configurable hours, no detection | 11pm - 7am |
| Morning Check | No activity since midnight | 8am |
| Late Wake | 45 mins past average wake time | 5am - 10am |
| Daily Summary | Email status report | 8am |
| Extended Bathroom | 30+ mins in bathroom | Always |
| Low Battery | Sensor < 25% | Always |
| System Health | Disk > 80%, CPU > 75C | Always |

### Dashboards

**Home Assistant Dashboard:**
- Room-by-room status with live sensor readings
- Sleep pattern tracking (bed time, wake time, averages)
- Live camera feeds
- Sensor batteries and staleness indicators
- Configurable monitoring settings
- System health metrics
- Embedded Grafana charts

**Grafana Dashboard:**
- Today vs historical average activity
- 7-day activity trend
- Room-by-room activity timelines
- Activity heatmap

### Self-Healing Infrastructure

Xiaomi cloud sensors can go offline. This system handles it automatically:

| Tier | Trigger | Action | Notification |
|------|---------|--------|-------------|
| Quick Reload | 10 mins stale | Silent integration reload | None |
| Auto-Restart | 30 mins stale | Reload + email alert | Yes |
| Auth Failure | 2+ hours offline | Email with fix instructions | Yes |
| Daily Reminder | Still offline at 8am | Urgent email | Yes |

Plus: Docker container watchdog, auto-restart on boot, hardware watchdog, SD card health monitoring.

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
          |                   |                   |
   +-----------+       +-----------+       +-----------+
   |  Xiaomi   |       |  Reolink  |       |  Reolink  |
   |  Gateway  |       |  E1 Pro   |       |  E1 Pro   |
   +-----------+       +-----------+       +-----------+
          |
   +-----------+
   | Presence  |
   | Sensors   |
   +-----------+
```

## Setup

### Prerequisites
- Raspberry Pi 5 (4GB+) with Raspberry Pi OS
- Docker and Docker Compose installed
- Xiaomi sensors paired in Mi Home app
- [Tailscale](https://tailscale.com/) for remote access (recommended)

### Installation

1. **Clone this repo** to your Pi:
   ```bash
   git clone https://github.com/andygmassey/grandpa-presence.git
   cd grandpa-presence
   ```

2. **Create your secrets files:**
   ```bash
   cp .env.example .env
   cp homeassistant/secrets.yaml.example homeassistant/secrets.yaml
   ```
   Edit both files with your actual credentials.

3. **Start the stack:**
   ```bash
   docker compose up -d
   ```

4. **Configure integrations** in the HA web UI (http://your-pi:8123):
   - Install [HACS](https://hacs.xyz/) and [Xiaomi Miot Auto](https://github.com/al-one/hacs-xiaomi-miot) via HACS
   - Add your Reolink cameras via the Reolink integration
   - Set up a Gmail App Password for email notifications

5. **Customise** the automations for your relative's schedule - see [CUSTOMISING.md](CUSTOMISING.md).

### File Structure

```
grandpa-presence/
├── docker-compose.yml              # HA + InfluxDB + Grafana stack
├── .env.example                    # Docker credentials template
├── homeassistant/
│   ├── configuration.yaml          # Main HA config
│   ├── automations.yaml            # All monitoring automations
│   ├── secrets.yaml.example        # HA secrets template
│   └── dashboards/
│       └── status.yaml             # Status dashboard
├── grafana/
│   └── dashboards/
│       └── presence.json           # Grafana dashboard export
├── scripts/
│   └── watchdog.sh                 # Container health check
├── CUSTOMISING.md                  # How to adapt for your setup
├── STATUS.md                       # Detailed system status
└── CLAUDE.md                       # AI assistant instructions
```

## Quick Reference

```bash
# SSH to Pi
ssh user@<TAILSCALE_IP>

# Check containers
docker ps

# Restart all containers
docker compose restart

# View HA logs
docker logs homeassistant --tail 50

# Check HA config is valid
docker exec homeassistant python -m homeassistant --script check_config -c /config
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.6.2 | 2026-02-08 | Xiaomi auth failure alert |
| v1.6.1 | 2026-02-06 | Fix auto-restart to check hourly |
| v1.6 | 2026-02-04 | Fix bed time detection (trigger-based template sensors) |
| v1.5 | 2026-02-01 | Two-tier Xiaomi recovery system |
| v1.4 | 2026-01 | Sensor staleness tracking & auto-recovery |
| v1.3 | 2026-01-17 | Bed time detection fix, cloud recovery email fix |
| v1.2 | 2026-01-01 | Hardware watchdog, SD card monitoring, configurable thresholds |
| v1.1 | 2026-01-01 | Reolink cameras, Grafana dashboards |
| v1.0 | 2024-12-29 | Initial setup |

## Contributing

Contributions welcome! If you've adapted this for your own family member, I'd love to hear about it. Open an issue or PR.

## License

[MIT](LICENSE)
