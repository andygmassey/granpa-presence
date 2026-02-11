# CLAUDE.md

Instructions for Claude Code when working on this project.

## MANDATORY: Config File Edit Rules

**These rules are NON-NEGOTIABLE. Violating them wastes hours of user time.**

### Before ANY edit to YAML/config files:
1. **READ THE ENTIRE FILE FIRST** - Not just the section you're changing
2. **BACKUP FIRST** - `cp file.yaml file.yaml.bak` before any modification
3. **ONE CHANGE AT A TIME** - Make one change, verify it works, then proceed
4. **NEVER USE SED ON YAML** - Use the Edit tool with exact string matching only

### When editing dashboards (status.yaml):
1. **LIST ALL EXISTING CARDS** before making changes - count them
2. **VERIFY CAMERAS STILL EXIST** after any edit
3. **VERIFY ROOM STATUSES STILL EXIST** after any edit
4. **VERIFY CONFIG OPTIONS STILL EXIST** after any edit
5. **If you remove something by accident, STOP and restore from backup immediately**

### When editing automations:
1. **READ the full automation** before changing any part of it
2. **TEST the logic mentally** - trace through what will happen
3. **CHECK trigger.to_state vs now()** - know which time you're capturing

### After ANY config change:
1. **Restart HA** and verify it comes up without errors
2. **CHECK THE DASHBOARD** in a browser - don't assume it worked
3. **If something broke, restore backup FIRST before trying another fix**

### NEVER:
- Claim something is fixed without testing it
- Make multiple changes at once hoping they all work
- Use sed/awk for structured file edits
- Delete sections to "simplify" - you'll remove working features

---

## CRITICAL: Shared Pi - Two Projects

This Pi runs **TWO separate projects**:

| Project | Local Folder | Purpose | Pi Location |
|---------|--------------|---------|-------------|
| **Gramps Transcriber (BK001)** | `BK001 - Gramps Transcriber/01 - Code/` | Real-time phone caption display | `/home/massey/gramps-transcriber/` |
| **Dad Presence (BK004)** | `BK004 - Dad Presence/` | Home Assistant elderly monitoring | `/home/massey/ha-config/` + Docker |

**Both projects share the same Raspberry Pi 5.**

**Sister project:** Gran Presence (BK0003) - same HA architecture for MiL

---

## Project Overview

This is the "Dad Presence" project (BK004) - a Raspberry Pi 5-based elderly monitoring system using Home Assistant, InfluxDB, and Grafana. It monitors Dad's activity via Xiaomi presence sensors and Reolink cameras, sending alerts when unusual patterns are detected.

## Current Status: OPERATIONAL

The system is fully operational with:
- Bedroom presence sensor (Xiaomi)
- Shower Room presence sensor (Xiaomi)
- Living Room and Conservatory cameras (Reolink E1 Pro)
- Grafana dashboards configured
- All automations tuned for Dad's schedule

---

## Reolink E1 Pro Cameras (WORKING)

| Camera | Motion Entity |
|--------|---------------|
| Living Room | binary_sensor.gramps_living_room_motion |
| Conservatory | binary_sensor.gramps_conservatory_motion |

Credentials: see `secrets.yaml`

---

## Working Xiaomi Entities

| Entity | Purpose |
|--------|---------|
| sensor.xiaomi_03_85df_occupancy_sensor | Bedroom presence |
| sensor.xiaomi_03_85df_battery_level | Bedroom battery % |
| binary_sensor.bedroom_occupied | Bedroom template sensor |
| sensor.xiaomi_03_b987_occupancy_sensor | Shower room presence |
| sensor.xiaomi_03_b987_battery_level | Shower room battery % |
| binary_sensor.shower_room_occupied | Shower room template sensor |

---

## Key Input Helpers

| Entity | Purpose |
|--------|---------|
| input_boolean.dad_monitoring_enabled | MUST BE ON for alerts to work |
| input_datetime.dad_last_activity | Updated on presence detection |
| input_datetime.dad_bed_time | Detected bed time |
| input_datetime.dad_wake_time | Detected wake time |
| input_datetime.dad_avg_wake_time | Rolling average wake time |

---

## Automations (Tuned for Dad's Schedule)

Dad typically goes to bed 11pm-midnight and wakes 6-7am.

| Automation | Trigger | Notes |
|------------|---------|-------|
| Track Last Activity | Any presence/motion | Updates dad_last_activity |
| Daytime No Activity | 1 hour no activity | 7am-11pm |
| Nighttime No Activity | 8 hours no activity | 11pm-7am |
| Morning Check | 8am if no activity today | URGENT alert |
| Daily Summary | 7am email | Sleep pattern + status |
| Late Wake Alert | 45 mins past avg wake | If still in bedroom |
| Bed Time Detection | Bedroom occupied after 10pm | Records bed time |
| Wake Time Detection | Bedroom vacated 5am-10am | Records wake time + updates avg |
| Low Battery | Sensor < 25% | Email alert |
| System Health | Disk > 80%, CPU > 75C | Email alerts |
| Motion Snapshots | Camera motion | Captures RTSP snapshot |

---

## v1.4.1 Features: Email Notification Rate Limiting (Jan 2026)

### Problem Solved
Xiaomi sensors flapping online/offline caused notification spam:
- 5 "Integration Restarted" emails in 24 hours
- 8 "Sensors Back Online" emails in 24 hours

The auto-restart automation had a 1-hour rate limit, but the recovery notification had NO rate limiting and no hysteresis.

### Changes

**New Input Helper:**
- `input_datetime.xiaomi_recovery_notification_sent` - Tracks last recovery notification timestamp

**Auto-Restart Rate Limit:** Increased from 1 hour to **4 hours**
- Reduces maximum restart notifications from 24/day to 6/day

**Recovery Notification - Hysteresis:**
- Now requires sensors to be stable online for **5 minutes** before sending notification
- Prevents spam from brief recovery periods before re-failing

**Recovery Notification - Rate Limiting:**
- Only sends once per **24 hours** (even if sensors flap multiple times)
- Records timestamp in `xiaomi_recovery_notification_sent` helper

### Expected Results
- Auto-restart: Max 1 email per 4 hours (if sensors keep failing)
- Recovery: Max 1 email per 24 hours (even if sensors flap multiple times)
- **Total worst case: ~7 emails/day vs. 13+ previously**

---

## v1.4 Features: Sensor Staleness Tracking & Auto-Recovery (Jan 2026)

### Problem Solved
Xiaomi cloud API can fail silently, causing sensors to report stale data. This led to false "no activity" alerts because the system couldn't distinguish between "no presence detected" and "sensor not updating".

### New Input Helpers

| Entity | Purpose |
|--------|---------|
| input_datetime.bedroom_sensor_last_update | Tracks last update from bedroom sensor |
| input_datetime.shower_room_sensor_last_update | Tracks last update from shower room sensor |
| input_datetime.xiaomi_last_restart | Rate-limits auto-restart attempts |

### New Template Sensors

| Entity | Purpose |
|--------|---------|
| sensor.bedroom_sensor_age | Human-readable age ("5 min ago", "2 hr ago") |
| sensor.shower_room_sensor_age | Human-readable age for shower room sensor |
| sensor.bedroom_sensor_stale | True if bedroom sensor >15 min old |
| sensor.shower_room_sensor_stale | True if shower room sensor >15 min old |

### New Automations

| Automation | Trigger | Action |
|------------|---------|--------|
| Dad - Initialize Sensor Timestamps | HA start | Sets timestamps to now() after 30s delay |
| Dad - Track Bedroom Sensor Update | Illumination or occupancy change | Updates bedroom_sensor_last_update |
| Dad - Track Shower Room Sensor Update | Illumination or occupancy change | Updates shower_room_sensor_last_update |
| Dad - Cloud Offline Detection | Both sensors stale >15 min | Sets xiaomi_cloud_available OFF |
| Dad - Cloud Online Detection | Both sensors fresh | Sets xiaomi_cloud_available ON |
| Dad - Xiaomi Auto-Restart | Cloud offline for 30 min | Reloads Xiaomi config entry (rate-limited, see v1.4.1) |

### Dashboard Changes
- Room Status table now shows sensor ages with staleness warnings
- Warning banner appears when Xiaomi Cloud is offline

### Xiaomi Miot Config Entry ID
Config entry ID used by auto-restart automation is stored in the automations file. Update it if you re-add the integration.

---

## Troubleshooting

### Xiaomi Cloud Authentication Failure (Most Common Issue)

**Symptoms:**
- Email alert: "Presence Sensors Still Offline"
- HA logs show: `MiCloudException: Too many failures when login to Xiaomi`
- HA logs show: `MiCloudNeedVerify: need_verify`
- Dashboard shows sensors as stale/unavailable
- `input_boolean.xiaomi_cloud_available` is OFF

**Cause:**
Xiaomi's cloud API periodically expires authentication tokens and requires manual re-verification (2FA). This typically happens every few weeks. The auto-restart automation cannot fix this because it's an authentication issue, not a temporary network glitch.

**Solution:**
1. Go to HA: **Settings -> Devices & Services**
2. Find **Xiaomi Miot Auto** integration
3. Click **three dots -> Configure**
4. Re-enter Xiaomi account credentials
5. Complete verification (SMS code or Mi Home app approval)
6. Click **three dots -> Reload**
7. Verify sensors come back online (check logs for errors)

**Prevention:**
- Keep Xiaomi Miot integration updated (check for updates regularly)
- v1.1.2+ has improved login failure handling

**History:**
- 2026-01-20: Authentication expired, required manual 2FA re-verification. Updated Xiaomi Miot v1.1.1 -> v1.1.2, re-authenticated, sensors restored.

### Storage Corruption (core.config)

**Symptoms:**
- HA alert: "Storage corruption detected for core.config"
- Error: "Input is a zero-length, empty document"

**Cause:**
Disk write issue caused the config file to be zeroed out (empty).

**Solution:**
- HA auto-recovers by creating a default config
- Check the current `/config/.storage/core.config` is valid JSON
- If valid, just dismiss the alert (click Submit)
- If invalid, restore from backup or the `.corrupt.*` file if it has content

---

## Target Pi Details

- **Tailscale IP:** (see secrets / deploy notes)
- **SSH User:** massey
- **SSH Command:** `ssh massey@<TAILSCALE_IP>`

## Key File Locations on Pi

| Path | Purpose |
|------|---------|
| ~/docker-compose.yml | Container orchestration |
| ~/ha-config/ | Home Assistant config directory |
| ~/ha-config/configuration.yaml | Main HA config |
| ~/ha-config/automations.yaml | Monitoring automations |
| ~/ha-config/dashboards/status.yaml | Status dashboard |
| ~/watchdog.sh | Container health check |
| ~/influxdb-data/ | InfluxDB data volume |
| ~/grafana-data/ | Grafana data volume |

## Service Ports

| Service | Port |
|---------|------|
| Home Assistant | 8123 |
| InfluxDB | 8086 |
| Grafana | 3000 |

## Credentials

All credentials are stored in:
- `homeassistant/secrets.yaml` - HA secrets (SMTP, API keys, camera passwords)
- `.env` - Docker environment variables (InfluxDB, Grafana passwords)

**These files are gitignored and must never be committed.**

## Common Commands

```bash
# SSH to Pi
ssh massey@<TAILSCALE_IP>

# Check containers
docker ps

# Restart HA
docker restart homeassistant

# Check HA logs
docker logs homeassistant --tail 50

# Restart all containers
cd ~ && docker compose restart
```

## Reference Project

The Gran Presence project (BK0003) has aligned config and dashboards.

---

## Troubleshooting History

### 2026-01-19: Timezone Fix (v1.4.2)

**Symptoms:**
- Bed times not being detected properly
- `dad_avg_wake_time` showing 04:00 (nonsense value)
- Time-based automations behaving incorrectly

**Root Cause:**
HA timezone was set to `Asia/Hong_Kong` instead of `Europe/London`. All time-based automations were 8 hours off. The bed time condition `after: '22:00:00'` was being evaluated in HK time, meaning it would only trigger at 6am UK time.

**Fix:**
Changed `/config/.storage/core.config` -> `time_zone` from `Asia/Hong_Kong` to `Europe/London`, then restarted HA.

### 2026-02-01: Daily Summary Alignment (v1.4.3)

**Changes:**
- Daily summary time changed from 07:00 -> **08:00** (aligned with Gran)
- Subject line now prefixed with emoji for easy identification

**Both systems now send daily summaries at 08:00 local time.**

### 2026-02-01: Xiaomi Quick Reload - Two-Tier Recovery (v1.5)

**Problem:**
Xiaomi sensors frequently become stale due to transient cloud API issues. The existing 30-minute wait + 4-hour rate limit was too conservative - a simple integration reload usually fixes it within seconds.

**Solution - Two-Tier Approach:**

| Tier | Trigger | Rate Limit | Action | Email |
|------|---------|------------|--------|-------|
| **Quick Reload** | 10 mins stale | 30 mins | Silent reload | No |
| **Persistent Issue** | 30 mins stale | 4 hours | Reload + alert | Yes |

**New Components:**
- `input_datetime.xiaomi_last_quick_reload` - tracks quick reload timestamps
- `dad_xiaomi_quick_reload` automation - silent reload after 10 mins

**Timeline when sensors go stale:**
```
0 min   - Sensor stops updating
15 min  - Cloud marked offline (xiaomi_cloud_available -> OFF)
25 min  - Quick reload triggered (silent)
55 min  - If still stale, another quick reload (30 min rate limit)
30 min+ - If still offline, Tier 2 kicks in with email notification
```

**Key Learning:**
- Integration reload (`homeassistant.reload_config_entry`) is lightweight and fast
- Most Xiaomi cloud issues are transient and resolve with a quick reload
- Silent reloads reduce notification fatigue while maintaining reliability

### 2026-02-01: Quick Reload Timing Fix (v1.5.1)

**Problem:**
Quick reload was triggering on `xiaomi_cloud_available` being OFF for 10 mins, but that boolean only turns OFF at 15 mins stale. Result: quick reload fired at 25 mins (15+10), AFTER the cloud offline email at 20 mins.

**Fix:**
Changed quick reload to trigger directly on sensor staleness (10 min threshold) using a template trigger, same pattern as cloud offline detection but with 600s instead of 900s threshold.

**Correct Timeline:**
```
0 min   - Sensor stops updating
10 min  - Quick reload (silent)
20 min  - Cloud offline email (15 min stale + 5 min for:)
30 min  - Tier 2 restart + email
```

**Full System Audit Performed:**
- All timing windows verified correct
- Rate limits: Quick reload 10 min (v1.5.2), Auto-restart 4 hr
- Bed time: Gran 19:00-06:00, Dad 22:00-06:00
- Activity alerts: Day 07:00-22:00, Night 22:00-07:00
- Cloud online requires BOTH sensors fresh (prevents flapping)
- No other timing bugs found

### 2026-02-01: Quick Reload Rate Limit Reduction (v1.5.2)

**Problem:**
Cloud offline email still firing despite quick reload feature. Sensors would recover briefly after quick reload, then go stale again within the 30-minute rate limit window.

**Fix:**
Reduced quick reload rate limit from 30 minutes to **10 minutes**.

**New timeline:**
```
0 min   - Sensor goes stale
10 min  - Quick reload #1
20 min  - Quick reload #2 (if still stale)
30 min  - Quick reload #3 + Tier 2 persistent issue email
```

**Benefits:**
- 3 reload attempts before "persistent issue" email (was 1)
- Max 6 reloads/hour (was 2/hour) - still reasonable
- Better recovery for transient Xiaomi cloud issues

### 2026-02-04: Bed Time Detection Fix - Template Binary Sensors (v1.6)

**Symptoms:**
- Bed time showing very late times (4-5am) instead of actual bedtime
- Binary sensors stuck in "unknown" state after HA restart
- Bed time detected only when Xiaomi cloud recovered, not actual bedtime

**Root Cause:**
Template binary sensors with `availability` conditions have a startup race condition:
1. HA starts, binary sensor created at T+0 with state "unknown"
2. Xiaomi integration loads at T+2 seconds, sensor becomes available
3. Binary sensor stays "unknown" because no state CHANGE occurred
4. If cloud was offline during actual bedtime, first detection is when cloud recovers

**Fix:**
Changed template binary sensors from **state-based** to **trigger-based**:

```yaml
# OLD (broken - state-based with availability)
- binary_sensor:
    - name: "Bedroom Occupied"
      state: "{{ 'has' in states('sensor.xiaomi...') }}"
      availability: "{{ states('sensor.xiaomi...') not in ['unknown', 'unavailable'] }}"

# NEW (working - trigger-based)
- trigger:
    - platform: state
      entity_id: sensor.xiaomi_03_85df_occupancy_sensor
    - platform: homeassistant
      event: start  # Re-evaluate after HA startup!
  binary_sensor:
    - name: "Bedroom Occupied"
      state: >
        {% set s = states('sensor.xiaomi_03_85df_occupancy_sensor') | lower %}
        {{ s not in ['unknown', 'unavailable', ''] and ('has' in s or 'someone' in s) }}
```

**Key Learning:**
- `platform: homeassistant event: start` trigger ensures re-evaluation AFTER HA is fully loaded
- Aligned with Gran's system (same fix applied to both)

### 2026-02-06: Auto-Restart Bug Fix (v1.6.1)

**Problem:**
Auto-restart automation only triggered ONCE when cloud went offline. If it stayed offline for extended periods, no re-trigger occurred even after the 4-hour rate limit expired.

**Root Cause:**
State trigger `to: 'off' for: 30 minutes` only fires on state CHANGE. Once cloud is offline, staying offline doesn't re-trigger the automation.

**Fix:**
Changed from **state trigger** to **time-based trigger**:

```yaml
# OLD (broken - only triggers once)
trigger:
  - platform: state
    entity_id: input_boolean.xiaomi_cloud_available
    to: 'off'
    for: minutes: 30

# NEW (working - checks every hour)
trigger:
  - platform: time_pattern
    hours: "/1"
condition:
  - Cloud must be offline
  - Sensors stale for 30+ minutes
  - Last restart was 4+ hours ago
```

Now checks every hour and will retry restart every 4 hours while offline.

**Note:** Cannot auto-fix expired Xiaomi authentication - requires manual 2FA re-authentication via HA UI.
