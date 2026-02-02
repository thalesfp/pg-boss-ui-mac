# Privacy Policy

**Last Updated:** February 2, 2026

## Overview

BossDesk is a privacy-first macOS desktop application for managing PostgreSQL job queues powered by pg-boss. We believe your data is yours, and we've designed BossDesk to keep it that way.

## Data Collection

**BossDesk does not collect, transmit, or share any of your data.**

- No analytics or telemetry
- No crash reporting to external services
- No user accounts or authentication required
- No connection to our servers or third-party services

## Data Storage

All data is stored locally on your Mac:

### Connection Information
- **PostgreSQL connection details** (host, port, database name, username) are stored in your local application preferences
- **Passwords and sensitive credentials** are securely stored in the macOS Keychain, Apple's built-in credential management system
- Connection history and settings remain on your device

### Application Data
- User preferences and UI settings are stored locally using macOS's UserDefaults system
- No data leaves your machine unless you explicitly connect to a PostgreSQL database

## Network Access

BossDesk only makes network connections when:
- You explicitly connect to a PostgreSQL database you've configured
- All database connections are made directly from your Mac to your specified database server
- We never intercept, log, or transmit your database queries or results

## Database Access

When you connect to a PostgreSQL database:
- BossDesk queries the pg-boss tables to display job queue information
- All data retrieved from your database is processed and displayed locally
- Database credentials are used solely to establish your connection
- We do not store or cache sensitive data from your database

## Data Sharing

BossDesk does not share any data with third parties because we don't collect any data to share.

## macOS Permissions

BossDesk may request the following macOS permissions:
- **Network Access**: Required to connect to your PostgreSQL databases
- **Keychain Access**: Used to securely store and retrieve database passwords

These permissions are used solely for the application's core functionality.

## Security

We take security seriously:
- Database credentials are stored in macOS Keychain with encryption
- Application runs in the macOS App Sandbox for enhanced security
- Hardened Runtime protections are enabled
- No plain-text storage of sensitive credentials

## Your Rights

Since all your data is stored locally on your Mac:
- You have complete control over your data
- You can delete all BossDesk data by:
  - Removing the app from your Applications folder
  - Deleting application preferences: `~/Library/Preferences/com.thalesfp.BossDesk.plist`
  - Removing Keychain entries for BossDesk database connections

## Children's Privacy

BossDesk is not directed to children under the age of 13. We do not knowingly collect any information from children.

## Changes to This Policy

If we update this privacy policy, we will update the "Last Updated" date at the top of this document. Continued use of BossDesk after changes constitutes acceptance of the updated policy.

## Open Source

BossDesk is committed to transparency. You can review our source code to verify these privacy practices.

## Contact

If you have questions about this privacy policy or BossDesk's privacy practices, please open an issue on our GitHub repository.

---

**Summary:** BossDesk is a local-first application. Your data never leaves your Mac except when you explicitly connect to your own PostgreSQL databases. We don't collect, track, or share any of your information.
