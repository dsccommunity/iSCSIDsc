# iSCSIDsc

[![Build Status](https://dev.azure.com/dsccommunity/iSCSIDsc/_apis/build/status/dsccommunity.iSCSIDsc?branchName=main)](https://dev.azure.com/dsccommunity/iSCSIDsc/_build/latest?definitionId=36&branchName=main)
![Code Coverage](https://img.shields.io/azure-devops/coverage/dsccommunity/iSCSIDsc/36/main)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/iSCSIDsc/36/main)](https://dsccommunity.visualstudio.com/iSCSIDsc/_test/analytics?definitionId=36&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/iSCSIDsc?label=iSCSIDsc%20Preview)](https://www.powershellgallery.com/packages/iSCSIDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/iSCSIDsc?label=iSCSIDsc)](https://www.powershellgallery.com/packages/iSCSIDsc/)
[![codecov](https://codecov.io/gh/dsccommunity/iSCSIDsc/branch/main/graph/badge.svg)](https://codecov.io/gh/dsccommunity/iSCSIDsc)

## Code of Conduct

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

The **iSCSIDsc** module contains DSC resources for configuring Windows iSCSI
Targets and Initiators.

- **iSCSIInitiator**: This resource is used to add or remove an iSCSI Target
  Portal and connect it to an iSCSI Target.
- **iSCSIServerTarget**: This resource is used to create or remove Virtual Disks
  for use by iSCSI Targets.
- **iSCSIVirtualDisk**: This resource is used to create or remove Virtual Disks
  for use by iSCSI Targets.

This project has adopted this [Open Source Code of Conduct](CODE_OF_CONDUCT.md).

## Documentation and Examples

For a full list of resources in iSCSIDsc and examples on their use, check out
the [iSCSIDsc wiki](https://github.com/dsccommunity/iSCSIDsc/wiki).

## Requirements

- The iSCSI Target resources can only be used on Windows Server 2012 and above but
  does not currently work with Windows Server 2022 due to the ISNS feature being
  deprecated. See [this post](https://docs.microsoft.com/windows-server/get-started/removed-features-1709)
  for more information.
  These resources can not be used on Windows Desktop operating systems.
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

- ISNS support is deprecated on Windows Server 2022, this resource will not currently
  work on that OS.
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
