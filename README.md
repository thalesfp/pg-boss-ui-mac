# BossDesk

<p align="center">
  <img src="BossDesk/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png" width="128" alt="BossDesk icon">
</p>

Native macOS desktop application for managing and monitoring [pg-boss](https://github.com/timgit/pg-boss) job queues.

## Features

- **Real-time Queue Monitoring** - Live dashboard with job counts, throughput charts, and health metrics
- **Estimated Completion** - Dynamic estimates based on recent activity (last 15 minutes)
- **Job Management** - View, filter, retry, cancel, and delete jobs
- **Multi-Version Support** - Works with pg-boss v9, v10, and v11+
- **Connection Management** - Secure credential storage using macOS Keychain
- **Schedule Viewing** - View cron schedules (pg-boss v10+)

## Requirements

- macOS 15.0+
- PostgreSQL database with pg-boss schema

## Build & Run

```bash
make        # Build debug configuration
make run    # Build and run the app
make clean  # Clean build artifacts
```

Or open `BossDesk.xcodeproj` in Xcode and press Cmd+R.

## License

MIT
