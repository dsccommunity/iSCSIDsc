$VirtualDisk = @{
    Path            = Join-Path -Path $ENV:Temp -ChildPath 'TestiSCSIVirtualDisk.vhdx'
    Ensure          = 'Present'
    DiskType        = 'Dynamic'
    Size            = 100MB
    Description     = 'Integration Test iSCSI Virtual Disk'
}

Configuration DSR_iSCSIVirtualDisk_Config {
    Import-DscResource -ModuleName iSCSIDsc
    node localhost {
        iSCSIVirtualDisk Integration_Test {
            Path            = $VirtualDisk.Path
            Ensure          = $VirtualDisk.Ensure
            DiskType        = $VirtualDisk.DiskType
            SizeBytes       = $VirtualDisk.Size
            Description     = $VirtualDisk.Description
        }
    }
}
