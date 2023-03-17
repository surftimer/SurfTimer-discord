## Release Notes


## [2.5.7]

### Added

- Added more server console prints on failed webhook execution.

### Fixed

- Fixed test command sending Map-Challenge webhook despite the plugin not running on the server.

## [2.5.6]

### Added

- Added better debugging.

## [2.5.5]

### Fixed

- Fixed test command throwing an error when called from the server's console.

## [2.5.4]

### Fixed

- Fixed invalid webhook name checks.

## [2.5.3]

### Added

- Added a check for invalid webhook names.

## [2.5.2]

### Fixed

- Fixed an incorrect `sizeof` statement.

## [2.5.1]

### Fixed

- Fixed an error when running the test commands from console.

## [2.5.0]

### Added

- Added Timezone to Timestamps.

### Fixed

- Missing ArrayList Handle Closing.

## [2.4.1]

### Fixed

- Make MapChallenge not a required plugin.

## [2.4.0]

### Added

- Added ConVar for Mention Role option with MapChallenges.

## [2.3.0]

### Added

- Added Runtime & RuntimeDifference to Final TOP5 Message.
- Changed styled messages to be printed upon using **sm_ck_discordtest**.

### Fixed

- Fixed wrong include file name of MapChallenge plugin.
- Fixed missing return value.

## [2.2.0]

### Added

- Added support for MapChallenge plugin.
- Added MapChallenge announcements (Challenge Started, Challenge Ended).
- Added 2 new ConVar's for MapChallenge webhook's.
- Added 2 more styled messages to be printed upon using **sm_ck_discordtest**

## [2.1.4]

### Added

- Added a new ConVar for styled stages webhook.
- Added all styled messages to be printed upon using **sm_ck_discordtest**

### Fixed

-Fixed a ConVar conflict from **v2.1.3**

## [2.1.3]

### Added

- Added stage record announcements.

## [2.1.2]

### Added

- Added Map Tier to be displayed on Discord embed.

## [2.1.1]

### Fixed

- Fixed incorrect ConVar values.

## [2.0.2]

### Fixed

- Wrong webstat URL.

## [2.0.1]

### Added

- Added separate webhooks for styled records (see #8).
- Added a way to disable the `!calladmin` and `!bug` commands.

### Fixed

- Fixed colors not being parsed properly.

## [2.0.0]

### Fixed

- Switched to RIPext.
