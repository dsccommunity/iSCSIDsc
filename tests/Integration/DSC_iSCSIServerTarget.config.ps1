Configuration DSC_iSCSIServerTarget_Config {
    Import-DscResource -ModuleName iSCSIDsc

    Node localhost {
        iSCSIServerTarget Integration_Test {
            TargetName   = $Node.TargetName
            Ensure       = $Node.Ensure
            InitiatorIds = $Node.InitiatorIds
            Paths        = $Node.Paths
            iSNSServer   = $Node.iSNSServer
        }
    }
}
