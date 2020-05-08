# Change log for ComputerManagementDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Transferred ownership to DSCCommunity.org - Fixes [Issue #50](https://github.com/dsccommunity/iSCSIDsc/issues/50).
- Fix hash table style guideline violations.
- Added .gitattributes file to fix bug publishing examples - Fixes [Issue #40](https://github.com/PlagueHO/iSCSIDsc/issues/40).
- Opted into Common Tests 'Common Tests - Validate Localization' - Fixes [Issue #44](https://github.com/PlagueHO/iSCSIDsc/issues/44).
- Renamed `iSCSIDsc.ResourceHelpers` module to `iSCSIDsc.Common`
  to align to other modules.
- Renamed all localization strings so that they are detected by
  'Common Tests - Validate Localization'.
- Fixed issues with mismatched localization strings.
- Replaced `iSCSIDsc.Common` module with the latest version from
  [DSCResource.Template](https://github.com/PowerShell/DSCResource.Template).
- Fix minor style issues in statement case.
- Fix minor style issues in hashtable layout.
- Correct other minor style issues.
- Enabled PSSA rule violations to fail build - Fixes [Issue #27](https://github.com/PlagueHO/iSCSIDsc/issues/27).
- Updated tests to meet Pester v4 standard.
- Added Open Code of Conduct.
- Refactored module folder structure to move resource
  to root folder of repository and remove test harness - Fixes [Issue #36](https://github.com/PlagueHO/iSCSIDsc/issues/36).
- Converted Examples to support format for publishing to PowerShell
  Gallery.
- Opted into common tests:
  - Common Tests - Validate Example Files To Be Published
  - Common Tests - Validate Markdown Links
  - Common Tests - Relative Path Length
  - Common Tests - Relative Path Length
- Update to new format LICENSE.
- Added .VSCode settings for applying DSC PSSA rules - fixes [Issue #37](https://github.com/PlagueHO/iSCSIDsc/issues/37).
- BREAKING CHANGE: Changed resource prefix from MSFT to DSC.
- Updated to use continuous delivery pattern using Azure DevOps - fixes
  [Issue #52](https://github.com/dsccommunity/iSCSIDsc/issues/52).

## [1.5.0.41] - 2017-09-02

### Changed

- Converted resource module to be compliant with HQRM.
- Changed AppVeyor.yml to use AppVeyor module.
- Converted to Autodocumentation module.

## [1.2.1.95] - 2016-05-04

### Changed

- iSCSIInitiator: Fix bug when converting connected target to IsPersistent.

## [1.2.0.0] - 2016-01-01

### Changed

- iSCSIInitiator:
  - Fix bug when TargetPortalAddress is set to a Hostname instead of an IP address.
  - InitiatorPortalAddress property made optional.
- Unit and Integration test headers updated to v1.1.0

## [1.1.0.0] - 2016-01-01

### Changed

- Added iSNS Server support.

## [1.0.0.0] - 2016-01-01

### Changed

- Initial release.
