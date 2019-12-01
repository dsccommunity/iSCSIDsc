# iSCSIDsc

The **iSCSIDsc** module contains DSC resources for configuring Windows iSCSI
Targets and Initiators.

- **iSCSIInitiator**: This resource is used to add or remove an iSCSI Target
  Portal and connect it to an iSCSI Target.
- **iSCSIServerTarget**: This resource is used to create or remove Virtual Disks
  for use by iSCSI Targets.
- **iSCSIVirtualDisk**: This resource is used to create or remove Virtual Disks
  for use by iSCSI Targets.

**This project is not maintained or supported by Microsoft.**

This project has adopted this [Open Source Code of Conduct](CODE_OF_CONDUCT.md).

This module should meet the [PowerShell DSC Resource Kit High Quality Resource
Module Guidelines](https://github.com/PowerShell/DscResources/blob/master/HighQualityModuleGuidelines.md).

## Documentation and Examples

For a full list of resources in iSCSIDsc and examples on their use, check out
the [iSCSIDsc wiki](https://github.com/dsccommunity/iSCSIDsc/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/github/dsccommunity/iSCSIDsc?branch=master&svg=true)](https://ci.appveyor.com/project/dsccommunity/iSCSIDsc/branch/master)
[![codecov](https://codecov.io/gh/dsccommunity/iSCSIDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/dsccommunity/iSCSIDsc/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/github/dsccommunity/iSCSIDsc?branch=dev&svg=true)](https://ci.appveyor.com/project/dsccommunity/iSCSIDsc/branch/dev)
[![codecov](https://codecov.io/gh/dsccommunity/iSCSIDsc/branch/dev/graph/badge.svg)](https://codecov.io/gh/dsccommunity/iSCSIDsc/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Requirements

- The iSCSI Target resources can only be used on Windows Server 2012 and above.
  They can not be used on Windows Desktop operating systems.
- The iSCSI Target resources can only be used on Windows Servers that have the
  iSCSI Target Server (FS-iSCSITarget-Server) feature installed.
- Before the iSCSI Initiator resource is used in a config, the **msiscsi** service
  must be started. It is recommended that this service is set to startup automatically
  in any iSCSI Initiator configurations.

## Important Information

### iSNS Servers

Configuring a _Server Target_ or _Initiator_ to connect to an **iSNS Server**
requires that the **iSNS Server** is online and accessible.
If an **iSNS Server** is specified but it can't be contacted, the **iSNS Server**
will not be set on the _Server Target_ or _Initiator_, but an error will not be thrown.
This error will be reported in the DSC verbose logs however.
This means that the configuration will continue to be applied until the **iSNS Server**
is contactable so that the **iSNS Server** setting will be configured as soon
as the **iSNS Server** becomes contactable.

## Known Issues

- Integration Tests on the iSCSIInitiator resource are currently disabled because
  it requires **iSCSI Initiator Loopback**, but this isn't documented anywhere so
  could not be made to work.

  Note: **iSCSI Initiator Loopback** is supported according to [this document](http://blogs.technet.com/b/filecab/archive/2012/05/21/introduction-of-iscsi-target-in-windows-server-2012.aspx).
  This issue won't prevent this resource from working correctly, it simply reduces
  the effectiveness of automated testing of the resource.
- Integration Tests on **iSNS Server** settings on the _Server Target_ and _Initiator_
  resources are currently disabled because they require access to an **iSNS server**.
  However, the "iSNSServer" parameter is still set in the integration test, but
  the resulting configuration parameter value is not confirmed.
