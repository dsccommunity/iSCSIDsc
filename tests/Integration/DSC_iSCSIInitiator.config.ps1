Configuration DSC_iSCSIInitiator_Config {
    Import-DscResource -ModuleName iSCSIDsc

    Node localhost {
        iSCSIInitiator Integration_Test {
            NodeAddress            = $Node.NodeAddress
            TargetPortalAddress    = $Node.TargetPortalAddress
            InitiatorPortalAddress = $Node.InitiatorPortalAddress
            Ensure                 = $Node.Ensure
            TargetPortalPortNumber = $Node.TargetPortalPortNumber
            InitiatorInstanceName  = $Node.InitiatorInstanceName
            AuthenticationType     = $Node.AuthenticationType
            ChapUsername           = $Node.ChapUsername
            ChapSecret             = $Node.ChapSecret
            IsDataDigest           = $Node.IsDataDigest
            IsHeaderDigest         = $Node.IsHeaderDigest
            IsMultipathEnabled     = $Node.IsMultipathEnabled
            IsPersistent           = $Node.IsPersistent
            ReportToPnP            = $Node.ReportToPnP
            iSNSServer             = $Node.iSNSServer
        }
    }
}
