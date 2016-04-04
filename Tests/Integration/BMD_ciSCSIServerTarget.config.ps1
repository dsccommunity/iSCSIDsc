$VirtualDisk = @{
    Path         = Join-Path -Path $ENV:Temp -ChildPath 'TestiSCSIServerTarget.vhdx'
}
$ServerTarget = @{
    TargetName   = 'testtarget'
    Ensure       = 'Present'
    InitiatorIds = @( 'Iqn:iqn.1991-05.com.microsoft:fs1.contoso.com','Iqn:iqn.1991-05.com.microsoft:fs2.contoso.com' )
    Paths        = @( $VirtualDisk.Path )
    iSNSServer   = 'isns.contoso.com'
}

Configuration BMD_ciSCSIServerTarget_Config {
    Import-DscResource -ModuleName ciSCSI
    node localhost {
        ciSCSIServerTarget Integration_Test {
            TargetName   = $ServerTarget.TargetName
            Ensure       = $ServerTarget.Ensure
            InitiatorIds = $ServerTarget.InitiatorIds
            Paths        = $ServerTarget.Paths
            iSNSServer   = $ServerTarget.iSNSServer
        }
    }
}
