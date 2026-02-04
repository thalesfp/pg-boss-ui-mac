# BossDesk

<p align="center">
  <img src="BossDesk/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png" width="128" alt="BossDesk icon">
</p>

A privacy-first, native macOS application for managing and monitoring [pg-boss](https://github.com/timgit/pg-boss) job queues with seamless multi-version support.

## Features

- **Real-time Queue Monitoring** - Live dashboard with job counts, throughput charts, and health metrics
- **Estimated Completion** - Dynamic estimates based on recent activity (last 15 minutes)
- **Job Management** - View, filter, retry, cancel, and delete jobs
- **Multi-Version Support** - Works with pg-boss v7, v8, v9, v10, and v11+
- **Connection Management** - Secure credential storage using macOS Keychain
- **Schedule Viewing** - View cron schedules (pg-boss v10+)

## Requirements

- macOS 15.0+
- PostgreSQL database with pg-boss schema (v7-v11+)
- Xcode 16.0+ (for building from source)

BossDesk automatically detects your pg-boss schema version on connection.

## Installation

### Download from App Store

<a href="https://apps.apple.com/us/app/bossdesk/id6758589367">
  <img src="https://tools.applemediaservices.com/api/badges/download-on-the-mac-app-store/black/en-us?size=250x83&releaseDate=1234567890" alt="Download on the Mac App Store" width="200">
</a>

## Build & Run

### Prerequisites
- Xcode 16.0+
- macOS 15.0+

### Quick Start
```bash
make        # Build debug configuration
make run    # Build and run the app
make clean  # Clean build artifacts
```

Or open `BossDesk.xcodeproj` in Xcode and press Cmd+R.

### Additional Commands
```bash
make release # Build release configuration
make kill    # Kill the running app
```

## License

MIT
