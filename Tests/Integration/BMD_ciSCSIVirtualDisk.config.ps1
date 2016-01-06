$VirtualDisk = @{
    Path            = Join-Path -Path $ENV:Temp -ChildPath 'TestiSCSIVirtualDisk.vhdx'
    Ensure          = 'Present'
    DiskType        = 'Dynamic'
    Size            = 100MB
    Description     = 'Integration Test iSCSI Virtual Disk'
}

Configuration BMD_ciSCSIVirtualDisk_Config {
    Import-DscResource -ModuleName ciSCSI
    node localhost {
        ciSCSIVirtualDisk Integration_Test {
            Path            = $VirtualDisk.Path
            Ensure          = $VirtualDisk.Ensure
            DiskType        = $VirtualDisk.DiskType
            SizeBytes       = $VirtualDisk.Size
            Description     = $VirtualDisk.Description
        }
    }
}
