(Get-NetIPAddress -InterfaceIndex (Get-NetConnectionProfile -IPv4Connectivity Internet).InterfaceIndex -AddressFamily IPv4).IPAddress
$TargetName = 'TestServerTarget'
$Initiator = @{
    NodeAddress            = "iqn.1991-05.com.microsoft:$($ENV:ComputerName)-$TargetName-target-target"
    TargetPortalAddress    = $ENV:ComputerName
    InitiatorPortalAddress = $ENV:ComputerName
    Ensure                 = 'Present'
    TargePortalPortNumber  = 3260 
    InitiatorInstanceName  = 'ROOT\ISCSIPRT\0000_0'
    AuthenticationType     = 'OneWayCHAP'
    ChapUsername           = 'MyUsername'
    ChapSecret             = 'MySecret'
    IsDataDigest           = $false
    IsHeaderDigest         = $false
    IsMultipathEnabled     = $false
    IsPersistent           = $true
    ReportToPnP            = $true

}

Configuration BMD_ciSCSIInitiator_Config {
    Import-DscResource -ModuleName ciSCSI
    node localhost {
        ciSCSIInitiator Integration_Test {
            NodeAddress            = $Initiator.NodeAddress
            TargetPortalAddress    = $Initiator.TargetPortalAddress
            InitiatorPortalAddress = $Initiator.InitiatorPortalAddress
            Ensure                 = $Initiator.Ensure
            TargetPortalPortNumber = $Initiator.TargetPortalPortNumber
            InitiatorInstanceName  = $Initiator.InitiatorInstanceName
            AuthenticationType     = $Initiator.AuthenticationType
            ChapUsername           = $Initiator.ChapUsername
            ChapSecret             = $Initiator.ChapSecret
            IsDataDigest           = $Initiator.IsDataDigest
            IsHeaderDigest         = $Initiator.IsHeaderDigest
            IsMultipathEnabled     = $Initiator.IsMultipathEnabled
            IsPersistent           = $Initiator.IsPersistent
            ReportToPnP            = $Initiator.ReportToPnP
        }
    }
}
