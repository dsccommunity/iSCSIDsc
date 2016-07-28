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
            SizeBytes = 10GB
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
