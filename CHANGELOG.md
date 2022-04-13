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
- Update build badges in `README.md` with correct build IDs.
- Removed unused test helper function `New-VDisk`.
- Added test helper function `Assert-CanRunIntegrationTest` to validate if
  integration tests can be successfully run on a machine.
- Fixed build failures caused by changes in `ModuleBuilder` module v1.7.0
  by changing `CopyDirectories` to `CopyPaths` - Fixes [Issue #58](https://github.com/dsccommunity/iSCSIDsc/issues/58).
- Updated to use the common module _DscResource.Common_ - Fixes [Issue #53](https://github.com/dsccommunity/iSCSIDsc/issues/53).
- Pin `Pester` module to 4.10.1 because Pester 5.0 is missing code
  coverage - Fixes [Issue #60](https://github.com/dsccommunity/iSCSIDsc/issues/60).
- Automatically publish documentation to GitHub Wiki - Fixes [Issue #61](https://github.com/dsccommunity/iSCSIDsc/issues/61).
- Renamed `master` branch to `main` - Fixes [Issue #63](https://github.com/dsccommunity/iSCSIDsc/issues/63).
- Updated build to use `Sampler.GitHubTasks` - Fixes [Issue #65](https://github.com/dsccommunity/iSCSIDsc/issues/65).
- Added support for publishing code coverage to `CodeCov.io` and
  Azure Pipelines - Fixes [Issue #66](https://github.com/dsccommunity/iSCSIDsc/issues/66).
- Updated .github issue templates to standard - Fixes [Issue #69](https://github.com/dsccommunity/iSCSIDsc/issues/69).
- Added Create_ChangeLog_GitHub_PR task to publish stage of build pipeline.
- Added SECURITY.md.
- Updated pipeline Deploy_Module anb Code_Coverage jobs to use ubuntu-latest
  images - Fixes [Issue #68](https://github.com/dsccommunity/iSCSIDsc/issues/68).
- Updated pipeline unit tests and integration tests to use Windows Server
  2019 only - Fixes [Issue #68](https://github.com/dsccommunity/iSCSIDsc/issues/68).

### Fixed

- Fixed pipeline by replacing the GitVersion task in the `azure-pipelines.yml`
  with a script.

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
