# Customising Grandpa Presence

This guide explains how to adapt the system for your own family member's home and schedule.

## Entity Names

The config files use entity names prefixed with `dad_` and `gramps_` from the original deployment. You don't need to rename these for the system to work - they're just labels. But if you'd prefer cleaner names, here's where they appear:

### Input Helpers (`configuration.yaml`)

All `input_datetime`, `input_boolean`, `input_number`, and `counter` entities are defined in `configuration.yaml`. You can rename them, but you'll also need to update every reference in `automations.yaml` and `dashboards/status.yaml`.

For example, to change `dad_last_activity` to `mum_last_activity`, you'd need to find-and-replace across all three files.

### Camera Entities

The camera entities (`gramps_living_room`, `gramps_conservatory`) are set during Reolink integration setup in the HA UI. These aren't in the config files - they come from what you name the cameras when you add them.

### Xiaomi Sensor Entities

The Xiaomi entity IDs (e.g., `sensor.xiaomi_03_85df_occupancy_sensor`) are auto-generated based on the sensor's hardware ID. Your sensors will have different IDs. You'll need to update these throughout:

- `configuration.yaml` - template sensors
- `automations.yaml` - all triggers and conditions referencing sensors
- `dashboards/status.yaml` - status display

**Tip:** Set up your sensors first, note the entity IDs from the HA UI, then do a find-and-replace.

## Schedule & Time Windows

The default schedule is tuned for someone who goes to bed around 11pm-midnight and wakes at 6-7am. Adjust these in `automations.yaml`:

### Bed Time Detection

```yaml
# In automation: dad_record_bedroom_entry and dad_detect_bed_time
condition:
  - condition: time
    after: '22:00:00'   # Change to when they typically go to bed
    before: '06:00:00'  # Change to their earliest possible wake time
```

### Wake Time Detection

```yaml
# In automation: dad_detect_wake_time
condition:
  - condition: time
    after: '05:00:00'   # Earliest they might wake
    before: '10:00:00'  # Latest they'd reasonably wake
```

### Daytime vs Nighttime Alerts

```yaml
# In automation: dad_daytime_no_activity
condition:
  - condition: time
    after: '07:00:00'   # Start of "daytime" monitoring
    before: '23:00:00'  # End of "daytime" monitoring

# In automation: dad_nighttime_no_activity
condition:
  - condition: time
    after: '23:00:00'   # Start of "nighttime" monitoring
    before: '07:00:00'  # End of "nighttime" monitoring
```

### Alert Thresholds

These are configurable from the HA dashboard without editing files:

- **Daytime no-activity threshold** - `input_number.daytime_alert_hours` (default: 4 hours)
- **Nighttime no-activity threshold** - `input_number.nighttime_alert_hours` (default: 12 hours)

## Number of Rooms & Sensors

### Adding a Sensor

1. Pair the new sensor in Mi Home app
2. It will appear in HA via Xiaomi Miot Auto
3. Add tracking automation (copy an existing `Track Sensor Update` automation)
4. Add staleness tracking (copy existing `bedroom_sensor_last_update` pattern)
5. Add to dashboard in `status.yaml`
6. Add to the activity tracking automation triggers

### Removing Cameras

If you don't want cameras, you can:
1. Remove the `shell_command` section from `configuration.yaml`
2. Remove the motion snapshot automations from `automations.yaml`
3. Remove the camera cards from `dashboards/status.yaml`
4. Remove the Reolink camera triggers from the `Track Last Activity` automation

The presence sensors work independently of the cameras.

### Adding Rooms

For each new room with a presence sensor:
1. Add a trigger-based template binary sensor in `configuration.yaml` (follow the `Bedroom Occupied` pattern)
2. Add sensor update tracking (`input_datetime` + automation)
3. Add staleness tracking (sensor age + stale template)
4. Add to the `Track Last Activity` automation triggers
5. Add to the dashboard
6. Add to the daily summary email template

## Email Configuration

### Recipients

Email recipients are defined in `secrets.yaml`:

```yaml
email_recipient_1: "family-member-1@example.com"
email_recipient_2: "family-member-2@example.com"
email_recipient_3: "family-member-3@example.com"
```

To add or remove recipients, update `secrets.yaml` and the corresponding `!secret` references in the `recipient` list in `configuration.yaml`.

### Gmail Setup

1. Enable 2-Factor Authentication on your Google account
2. Go to Google Account > Security > App Passwords
3. Create an app password for "Mail"
4. Use this as `smtp_password` in `secrets.yaml`

## Xiaomi Miot Config Entry ID

The auto-restart automations reference a config entry ID specific to your HA installation:

```yaml
# In automations.yaml
entry_id: 01KE34E9ADX17BKKWE8SHKQSBA  # YOUR ID WILL BE DIFFERENT
```

To find yours:
1. Go to HA > Settings > Devices & Services > Xiaomi Miot Auto
2. Click the three dots > System Options
3. The URL will contain the entry ID, or check `.storage/core.config_entries` in your HA config

## Daily Summary Email

The daily summary template in `automations.yaml` (automation `dad_daily_summary`) includes room statuses, sleep patterns, and system health. Customise the HTML template to match your rooms and sensors.

## Grafana Dashboard URLs

The embedded Grafana panels in the HA dashboard are defined in `secrets.yaml`. After importing the Grafana dashboard (`grafana/dashboards/presence.json`), update the URLs with your Grafana instance address and dashboard UID.
