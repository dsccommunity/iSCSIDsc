Configuration DSC_iSCSIVirtualDisk_Config {
    Import-DscResource -ModuleName iSCSIDsc

    Node localhost {
        iSCSIVirtualDisk Integration_Test {
            Path            = $Node.Path
            Ensure          = $Node.Ensure
            DiskType        = $Node.DiskType
            SizeBytes       = $Node.SizeBytes
            Description     = $Node.Description
        }
    }
}
