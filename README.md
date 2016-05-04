[![Build status](https://ci.appveyor.com/api/projects/status/c3ib1g51tly89xoh/branch/master?svg=true)](https://ci.appveyor.com/project/PlagueHO/ciscsi/branch/master)

# ciSCSI

The **ciSCSI** module contains DSC resources for configuring Windows iSCSI Targets and Initiators.

## Requirements
- The iSCSI Target resources can only be used on Windows Server 2012 and above. They can not be used Windows Desktop operating systems.
- The iSCSI Target resources can only be used on Windows Servers that have the iSCSI Target Server (FS-iSCSITarget-Server) feature installed.
- Before the iSCSI Initiator resource is used in a config, the **msiscsi** service must be started. It is recommended that this service is set to startup automatically in any iSCSI Initiator configurations.

## Installation
```powershell
Install-Module -Name ciSCSI -MinimumVersion 1.2.1.0
```

## Important Information
### iSNS Servers
Configuring a _Server Target_ or _Initiator_ to connect to an **iSNS Server** requires that the **iSNS Server** is online and accessible.
If an **iSNS Server** is specified but it can't be contacted, the **iSNS Server** will not be set on the _Server Target_ or _Initiator_, but an error will not be thrown.
This error will be reported in the DSC verbose logs however.
This means that the configuration will continue to be applied until the **iSNS Server** is contactable so that the **iSNS Server** setting will be configured as soon as the **iSNS Server** becomes contactable.

## Known Issues
- Integration Tests on the ciSCSIInitiator resource are currently disabled because it requires **iSCSI Initiator Loopback**, but this isn't documented anywhere so could not be made to work.
  Note: **iSCSI Initiator Loopback** is supported according to [this document](http://blogs.technet.com/b/filecab/archive/2012/05/21/introduction-of-iscsi-target-in-windows-server-2012.aspx).
  This issue won't prevent this resource from working correctly, it simply reduces the effectiveness of automated testing of the resource.
- Integration Tests on **iSNS Server** settings on the _Server Target_ and _Initiator_ resources are currently disabled because they require access to an **iSNS server**.
  However, the "iSNSServer" parameter is still set in the integration test, but the resulting configuration parameter value is not confirmed.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## iSCSI Target Resources
### ciSCSIVirtualDisk
This resource is used to create or remove Virtual Disks for use by iSCSI Targets.

#### Parameters
- **Ensure**: Ensures that Virtual Disk is either Absent or Present. Required.
- **Path**: Specifies the path of the VHDX file that is associated with the iSCSI virtual disk. Required.
- **SizeBytes**: Specifies the size, in bytes, of the iSCSI virtual disk. Required.
- **BlockSizeBytes**: Specifies the block size, in bytes, for the VHDX. For fixed VHDX, if the value of the SizeBytes parameter is less than 32 MB, the default size if 2 MB. Otherwise, the default value is 32 MB. For dynamic VHDX, the default size is 2 MB. For differencing VHDX, the default size is the parent BlockSize. Optional.
- **DiskType**: Specifies the type of the VHDX. { Dynamic | Fixed | Differencing }. Defaults to Dynamics. Optional.
- **LogicalSectorSizeBytes**: Specifies the logical sector size, in bytes, for the VHDX. { 512 | 4096 }. Defaults to 512. Optional.
- **PhysicalSectorSizeBytes**: Specifies the physical sector size, in bytes, for the VHDX. { 512 | 4096 }. Defaults to 512. Optional.
- **Description**: Specifies the description for the iSCSI virtual disk. Optional.
- **ParentPath**: Specifies the parent virtual disk path if the VHDX is a differencing disk. Optional.

### ciSCSIServerTarget
This resource is used to create or remove iSCSI Server Targets.

#### Parameters
- **Ensure**: Ensures that Server Target is either Absent or Present. Required.
- **TargetName**: Specifies the name of the iSCSI target. Required.
- **InitiatorIds**: Specifies the iSCSI initiator identifiers (IDs) to which the iSCSI target is assigned. Required.
- **Paths**: Specifies the path of the virtual hard disk (VHD) files that are associated with the Server Target. Required.
- **iSNSServer**: Specifies an iSNS Server to register this Server Target with. Optional.

## iSCSI Initiator Resources
### ciSCSIInitiator
This resource is used to add or remove an iSCSI Target Portals and connect to an iSCSI Targets on them.

#### Parameters
- **NodeAddress**: Represents the IQN of the discovered target. Required.
- **TargetPortalAddress**: Represents the IP address or DNS name of the target portal. Required.
- **Ensure**: Ensures that Target is Absent or Present. Defaults to Present. Optional.
- **InitiatorPortalAddress**: Specifies the IP address associated with the portal. Optional.
- **TargetPortalPortNumber**: Specifies the TCP/IP port number for the target portal. Defaults to 3260. Optional.
- **InitiatorInstanceName**: The name of the initiator instance that the iSCSI initiator service uses to send SendTargets requests to the target portal. If no instance name is specified, the iSCSI initiator service chooses the initiator instance. Optional.
- **AuthenticationType**: Specifies the type of authentication to use when logging into the target. { None | OneWayCHAP | MutualCHAP } Defaults to None. Optional.
- **ChapUsername**: Specifies the user name to use when establishing a connection authenticated by using Mutual CHAP. Optional.
- **ChapSecret**: Specifies the CHAP secret to use when establishing a connection authenticated by using CHAP. Optional.
- **IsDataDigest**: Enables data digest when the initiator logs into the target portal. Defaults to False. Optional.
- **IsHeaderDigest**: Enables header digest when the initiator logs into the target portal. By not specifying this parameter, the digest setting is determined by the initiator kernel mode driver. Defaults to False. Optional.
- **IsMultipathEnabled**: Indicates that the initiator has enabled Multipath I/O (MPIO) and it will be used when logging into the target portal. Defaults to False. Optional.
- **IsPersistent**: Specifies that the session is to be automatically connected after each restart. Defaults to True. Optional.
- **ReportToPnP**: Specifies that the operation is reported to PNP. Defaults to True. Optional.
- **iSNSServer**: Specifies an iSNS Server to register this Initiator with. Optional.

## Examples
This example installs the iSCSI Target Server, creates two iSCSI Virtal Disks and then a new iSCSI Target called Cluster with the two Virtual Disks assigned. The iSCSI target will accept connections from cluster01.contoso.com, cluster02.contoso.com or cluster03.contoso.com.

```powershell
configuration Sample_ciSCSIServerTarget
{
    Param
    (
        [String] $NodeName = 'LocalHost'
    )

    Import-DscResource -Module ciSCSI

    Node $NodeName
    {
        WindowsFeature iSCSITargetServerInstall
        { 
            Ensure = "Present"
            Name = "FS-iSCSITarget-Server"
        }

        ciSCSIVirtualDisk iSCSIClusterVDisk01
        {
            Ensure = 'Present'
            Path = 'D:\iSCSIVirtualDisks\ClusterVdisk01.vhdx'
            DiskType = 'Dynamic'
            SizeBytes = 20GB
            Description = 'Cluster Virtual Disk 01'
            DependsOn = "[WindowsFeature]ISCSITargetServerInstall"
        } # End of ciSCSIVirtualDisk Resource

        ciSCSIVirtualDisk iSCSIClusterVDisk02
        {
            Ensure = 'Present'
            Path = 'D:\iSCSIVirtualDisks\ClusterVdisk02.vhdx'
            DiskType = 'Dynamic'
            UseFixed = $false
            Description = 'Cluster Virtual Disk 02'
            DependsOn = "[WindowsFeature]ISCSITargetServerInstall"
        } # End of ciSCSIVirtualDisk Resource

        ciSCSIServerTarget iSCSIClusterTarget
        {
            Ensure = 'Present'
            TargetName = 'Cluster'
            InitiatorIds = 'iqn.1991-05.com.microsoft:cluster01.contoso.com','iqn.1991-05.com.microsoft:cluster02.contoso.com','iqn.1991-05.com.microsoft:cluster03.contoso.com'
            Paths = 'D:\iSCSIVirtualDisks\ClusterVdisk01.vhdx','D:\iSCSIVirtualDisks\ClusterVdisk02.vhdx'
            iSNSServer = 'isns.contoso.com'
            DependsOn = "[ciSCSIVirtualDisk]iSCSIClusterVDisk01","[ciSCSIVirtualDisk]iSCSIClusterVDisk01"
        } # End of ciSCSIServerTarget Resource
    } # End of Node
} # End of Configuration
```

This example starts the MSiSCSI service on a cluster node and then configures an iSCSI Target Portal and then connects to the iSCSI Target.
```powershell
configuration Sample_ciSCSIInitiator
{
    Param
    (
         [String] $NodeName = 'LocalHost'
    )

    Import-DscResource -Module ciSCSI

    Node $NodeName
    {
        Service iSCSIService
        {
            Name = 'MSiSCSI'
            StartupType = 'Automatic'
            State = 'Running'
        }

        ciSCSIInitiator iSCSIInitiator
        {
            Ensure = 'Present'
            NodeAddress = 'iqn.1991-05.com.microsoft:fileserver01-cluster-target'
            TargetPortalAddress = '192.168.128.10'
            InitiatorPortalAddress = '192.168.128.20'
            IsPersistent = $true
            iSNSServer = 'isns.contoso.com'
            DependsOn = "[Service]iSCSIService"
        } # End of ciSCSIInitiator Resource
    } # End of Node
} # End of Configuration
```

## Versions

### 1.2.1.0
* iSCSIInitiator: Fix bug when converting connected target to IsPersistent.

### 1.2.0.0
* iSCSIInitiator: Fix bug when TargetPortalAddress is set to a Hostname instead of an IP address.
*                 InitiatorPortalAddress property made optional.
* Unit and Integration test headers updated to v1.1.0

### 1.1.0.0
* Added iSNS Server support.

### 1.0.0.0
* Initial release.

## Links
* **[GitHub Repo](https://github.com/PlagueHO/ciSCSI)**: Raise any issues, requests or PRs here.
* **[My Blog](https://dscottraynsford.wordpress.com)**: See my PowerShell and Programming Blog.
