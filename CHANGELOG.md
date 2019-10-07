# Versions

## Unreleased

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

## 1.5.1.0

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

## 1.5.0.0

- Converted resource module to be compliant with HQRM.
- Changed AppVeyor.yml to use AppVeyor module.
- Converted to Autodocumentation module.

## 1.2.1.0

- iSCSIInitiator: Fix bug when converting connected target to IsPersistent.

## 1.2.0.0

- iSCSIInitiator:
  - Fix bug when TargetPortalAddress is set to a Hostname instead of an IP address.
  - InitiatorPortalAddress property made optional.
- Unit and Integration test headers updated to v1.1.0

## 1.1.0.0

- Added iSNS Server support.

## 1.0.0.0

- Initial release.
