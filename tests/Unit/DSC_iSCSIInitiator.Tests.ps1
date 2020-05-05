$script:dscModuleName = 'iSCSIDsc'
$script:dscResourceName = 'DSC_iSCSIInitiator'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        # Create the Mock Objects that will be used for running tests
        $TestInitiator = [PSObject]@{
            NodeAddress = 'iqn.1991-05.com.microsoft:fileserver-cluster-target-target'
            TargetPortalAddress = '192.168.129.24'
            InitiatorPortalAddress = '192.168.129.28'
            Ensure = 'Present'
            TargetPortalPortNumber = 3260
            InitiatorInstanceName = 'ROOT\ISCSIPRT\0000_0'
            AuthenticationType = 'MutualCHAP'
            ChapUsername = 'MyUsername'
            ChapSecret = 'MySecret'
            IsDataDigest = $false
            IsHeaderDigest = $false
            IsMultipathEnabled = $false
            IsPersistent = $true
            ReportToPnP = $true
        }

        $TestInitiatorWithoutInitiatorAddress = [PSObject]@{
            NodeAddress = 'iqn.1991-05.com.microsoft:fileserver-cluster-target-target'
            TargetPortalAddress = '192.168.129.24'
            Ensure = 'Present'
            TargetPortalPortNumber = 3260
            InitiatorInstanceName = 'ROOT\ISCSIPRT\0000_0'
            AuthenticationType = 'MutualCHAP'
            ChapUsername = 'MyUsername'
            ChapSecret = 'MySecret'
            IsDataDigest = $false
            IsHeaderDigest = $false
            IsMultipathEnabled = $false
            IsPersistent = $true
            ReportToPnP = $true
        }

        $TestInitiatorWithHostname = [PSObject]@{
            NodeAddress = 'iqn.1991-05.com.microsoft:fileserver-cluster-target-target'
            TargetPortalAddress = 'targetportal.example.com'
            InitiatorPortalAddress = '192.168.129.28'
            Ensure = 'Present'
            TargetPortalPortNumber = 3260
            InitiatorInstanceName = 'ROOT\ISCSIPRT\0000_0'
            AuthenticationType = 'MutualCHAP'
            ChapUsername = 'MyUsername'
            ChapSecret = 'MySecret'
            IsDataDigest = $false
            IsHeaderDigest = $false
            IsMultipathEnabled = $false
            IsPersistent = $true
            ReportToPnP = $true
        }

        $TestInitiatorWithiSNS = [PSObject]@{
            NodeAddress = 'iqn.1991-05.com.microsoft:fileserver-cluster-target-target'
            TargetPortalAddress = '192.168.129.24'
            InitiatorPortalAddress = '192.168.129.28'
            Ensure = 'Present'
            TargetPortalPortNumber = 3260
            InitiatorInstanceName = 'ROOT\ISCSIPRT\0000_0'
            AuthenticationType = 'MutualCHAP'
            ChapUsername = 'MyUsername'
            ChapSecret = 'MySecret'
            IsDataDigest = $false
            IsHeaderDigest = $false
            IsMultipathEnabled = $false
            IsPersistent = $true
            ReportToPnP = $true
            iSNSServer = 'isns.contoso.com'
        }

        $MockTargetPortal = [PSObject]@{
            TargetPortalAddress = $TestInitiator.TargetPortalAddress
            InitiatorPortalAddress = $TestInitiator.InitiatorPortalAddress
            TargetPortalPortNumber = $TestInitiator.TargetPortalPortNumber
            InitiatorInstanceName = $TestInitiator.InitiatorInstanceName
            IsDataDigest = $TestInitiator.IsDataDigest
            IsHeaderDigest = $TestInitiator.IsHeaderDigest
        }

        $MockTargetPortalWithoutInitiatorAddress = [PSObject]@{
            TargetPortalAddress = $TestInitiator.TargetPortalAddress
            InitiatorPortalAddress = $null
            TargetPortalPortNumber = $TestInitiator.TargetPortalPortNumber
            InitiatorInstanceName = $TestInitiator.InitiatorInstanceName
            IsDataDigest = $TestInitiator.IsDataDigest
            IsHeaderDigest = $TestInitiator.IsHeaderDigest
        }

        $MockTargetPortalWithHostName = [PSObject]@{
            TargetPortalAddress = $TestInitiatorWithHostname.TargetPortalAddress
            InitiatorPortalAddress = $TestInitiatorWithHostname.InitiatorPortalAddress
            TargetPortalPortNumber = $TestInitiatorWithHostname.TargetPortalPortNumber
            InitiatorInstanceName = $TestInitiatorWithHostname.InitiatorInstanceName
            IsDataDigest = $TestInitiatorWithHostname.IsDataDigest
            IsHeaderDigest = $TestInitiatorWithHostname.IsHeaderDigest
        }

        $MockTarget = [PSObject]@{
            NodeAddress = $TestInitiator.NodeAddress
            IsConnected = $True
        }

        $MockTargetNotConnected = [PSObject]@{
            NodeAddress = $TestInitiator.NodeAddress
            IsConnected = $False
        }

        $MockConnection = [PSObject]@{
            ConnectionIdentifier = 'ffffe00112ed9020-b'
            InitiatorAddress     = $TestInitiator.InitiatorPortalAddress
            InitiatorPortNumber  = 52723
            TargetAddress        = $TestInitiator.TargetPortalAddress
            TargetPortNumber     = $TestInitiator.TargetPortalPortNumber
        }

        $MockSession = [PSObject]@{
            AuthenticationType      = $TestInitiator.AuthenticationType
            InitiatorInstanceName   = $TestInitiator.InitiatorInstanceName
            InitiatorNodeAddress    = 'iqn.1991-05.com.microsoft:cluster1.contoso.com'
            InitiatorPortalAddress  = $TestInitiator.InitiatorPortalAddress
            InitiatorSideIdentifier = '400001370000'
            IsConnected             = $True
            IsDataDigest            = $TestInitiator.IsDataDigest
            IsDiscovered            = $True
            IsHeaderDigest          = $TestInitiator.IsHeaderDigest
            IsPersistent            = $False
            NumberOfConnections     = 1
            SessionIdentifier       = 'ffffe0013d37c020-4000013700000001'
            TargetNodeAddress       = $TestInitiator.NodeAddress
            TargetSideIdentifier    = '0100'
        }

        $MockSessionPersistent = $MockSession.Clone()
        $MockSessionPersistent.IsPersistent = $True

        $MockiSNSSrver = @{
             Path               = "\\Localhost\root\wmi:MSiSCSIInitiator_iSNSServerClass.iSNSServerAddress=`"$($TestInitiatorWithiSNS.iSNSServer)`""
            iSNSServerAddress   = $TestInitiatorWithiSNS.iSNSServer
        }

        # Dummy functions to allow passing values from pipeline
        Function Register-IscsiSession {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
                ${InputObject},
                [Boolean] ${IsMultipathEnabled}
            )
        }

        Function Unregister-IscsiSession {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
                ${InputObject}
            )
        }

        Describe "DSC_iSCSIInitiator\Get-TargetResource" {
            Context 'Target Portal and Target do not exist' {
                Mock Get-TargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return absent' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure | Should -Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal exists but Target does not' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return absent but with Target Portal data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure                 | Should -Be 'Absent'
                    $Result.TargetPortalAddress    | Should -Be $TestInitiator.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should -Be $TestInitiator.InitiatorPortalAddress
                    $Result.TargetPortalPortNumber | Should -Be $TestInitiator.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiator.InitiatorInstanceName
                    $Result.IsDataDigest           | Should -Be $TestInitiator.IsDataDigest
                    $Result.IsHeaderDigest         | Should -Be $TestInitiator.IsHeaderDigest
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal and Target exists but not connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return absent but with Target Portal data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure                 | Should -Be 'Absent'
                    $Result.TargetPortalAddress    | Should -Be $TestInitiator.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should -Be $TestInitiator.InitiatorPortalAddress
                    $Result.TargetPortalPortNumber | Should -Be $TestInitiator.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiator.InitiatorInstanceName
                    $Result.IsDataDigest           | Should -Be $TestInitiator.IsDataDigest
                    $Result.IsHeaderDigest         | Should -Be $TestInitiator.IsHeaderDigest
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal and Target exists but not connected, Initiator Portal Address not set' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortalWithoutInitiatorAddress) }
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return absent but with Target Portal data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiatorWithoutInitiatorAddress.NodeAddress `
                        -TargetPortalAddress $TestInitiatorWithoutInitiatorAddress.TargetPortalAddress
                    $Result.Ensure                 | Should -Be 'Absent'
                    $Result.TargetPortalAddress    | Should -Be $TestInitiatorWithoutInitiatorAddress.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should -BeNullOrEmpty
                    $Result.TargetPortalPortNumber | Should -Be $TestInitiatorWithoutInitiatorAddress.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiatorWithoutInitiatorAddress.InitiatorInstanceName
                    $Result.IsDataDigest           | Should -Be $TestInitiatorWithoutInitiatorAddress.IsDataDigest
                    $Result.IsHeaderDigest         | Should -Be $TestInitiatorWithoutInitiatorAddress.IsHeaderDigest
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal and Target exists and is Connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                Mock Get-WMIObject
                It 'should return correct data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure                 | Should -Be 'Present'
                    $Result.TargetPortalAddress    | Should -Be $TestInitiator.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should -Be $TestInitiator.InitiatorPortalAddress
                    $Result.TargetPortalPortNumber | Should -Be $TestInitiator.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiator.InitiatorInstanceName
                    $Result.IsDataDigest           | Should -Be $TestInitiator.IsDataDigest
                    $Result.IsHeaderDigest         | Should -Be $TestInitiator.IsHeaderDigest
                    $Result.AuthenticationType     | Should -Be $TestInitiator.AuthenticationType
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiator.InitiatorInstanceName
                    $Result.ConnectionIdentifier   | Should -Be $MockConnection.ConnectionIdentifier
                    $Result.SessionIdentifier      | Should -Be $MockSession.SessionIdentifier
                    $Result.IsConnected            | Should -Be $MockSession.IsConnected
                    $Result.IsDiscovered           | Should -Be $MockSession.IsDiscovered
                    $Result.IsPersistent           | Should -Be $MockSession.IsPersistent
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal and Target exists and is Connected, Initiator Portal Address not set' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortalWithoutInitiatorAddress) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                Mock Get-WMIObject
                It 'should return correct data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiatorWithoutInitiatorAddress.NodeAddress `
                        -TargetPortalAddress $TestInitiatorWithoutInitiatorAddress.TargetPortalAddress
                    $Result.Ensure                 | Should -Be 'Present'
                    $Result.TargetPortalAddress    | Should -Be $TestInitiatorWithoutInitiatorAddress.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should -Be $MockConnection.InitiatorAddress
                    $Result.TargetPortalPortNumber | Should -Be $TestInitiatorWithoutInitiatorAddress.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiatorWithoutInitiatorAddress.InitiatorInstanceName
                    $Result.IsDataDigest           | Should -Be $TestInitiatorWithoutInitiatorAddress.IsDataDigest
                    $Result.IsHeaderDigest         | Should -Be $TestInitiatorWithoutInitiatorAddress.IsHeaderDigest
                    $Result.AuthenticationType     | Should -Be $TestInitiatorWithoutInitiatorAddress.AuthenticationType
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiatorWithoutInitiatorAddress.InitiatorInstanceName
                    $Result.ConnectionIdentifier   | Should -Be $MockConnection.ConnectionIdentifier
                    $Result.SessionIdentifier      | Should -Be $MockSession.SessionIdentifier
                    $Result.IsConnected            | Should -Be $MockSession.IsConnected
                    $Result.IsDiscovered           | Should -Be $MockSession.IsDiscovered
                    $Result.IsPersistent           | Should -Be $MockSession.IsPersistent
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal and Target exists and is Connected, iSNS Server set' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                Mock Get-WMIObject -MockWith { return @($MockiSNSSrver) }
                It 'should return correct data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure                 | Should -Be 'Present'
                    $Result.TargetPortalAddress    | Should -Be $TestInitiator.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should -Be $TestInitiator.InitiatorPortalAddress
                    $Result.TargetPortalPortNumber | Should -Be $TestInitiator.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiator.InitiatorInstanceName
                    $Result.IsDataDigest           | Should -Be $TestInitiator.IsDataDigest
                    $Result.IsHeaderDigest         | Should -Be $TestInitiator.IsHeaderDigest
                    $Result.AuthenticationType     | Should -Be $TestInitiator.AuthenticationType
                    $Result.InitiatorInstanceName  | Should -Be $TestInitiator.InitiatorInstanceName
                    $Result.ConnectionIdentifier   | Should -Be $MockConnection.ConnectionIdentifier
                    $Result.SessionIdentifier      | Should -Be $MockSession.SessionIdentifier
                    $Result.IsConnected            | Should -Be $MockSession.IsConnected
                    $Result.IsDiscovered           | Should -Be $MockSession.IsDiscovered
                    $Result.IsPersistent           | Should -Be $MockSession.IsPersistent
                    $Result.iSNSServer             | Should -Be $MockiSNSSrver.iSNSServerAddress
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }
        }

        Describe "DSC_iSCSIInitiator\Set-TargetResource" {
            Context 'Target Portal does not exist but should' {
                Mock Get-TargetPortal
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget -MockWith { return @($MockSession) }
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does not exist but should, Initiator Portal Address not set' {
                Mock Get-TargetPortal
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget -MockWith { return @($MockSession) }
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiatorWithoutInitiatorAddress.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist and should but Target is disconnected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget -MockWith { return @($MockSession) }
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist and should but Target is disconnected, Initiator Portal Address not set' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortalWithoutInitiatorAddress) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget -MockWith { return @($MockSession) }
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiatorWithoutInitiatorAddress.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
            Mock New-IscsiTargetPortal
            Mock Remove-IscsiTargetPortal
            Mock Get-Target -MockWith { return @($MockTarget) }
            Mock Get-Connection
            Mock Get-Session
            Mock Connect-IscsiTarget -MockWith { return @($MockSession) }
            Mock Disconnect-IscsiTarget
            Mock Register-IscsiSession
            Mock Unregister-IscsiSession
            Mock Get-WMIObject
            Mock Set-WMIInstance
            Mock Remove-WMIObject

            Context 'Target Portal does exist and should but TargetPortalPortNumber is different' {
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.TargetPortalPortNumber = $Splat.TargetPortalPortNumber + 1
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist and should but InitiatorInstanceName is different' {
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.InitiatorInstanceName = "Different"
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist and should but IsDataDigest is different' {
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.IsDataDigest = ! $Splat.IsDataDigest
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist and should but IsHeaderDigest is different' {
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.IsHeaderDigest = ! $Splat.IsHeaderDigest
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist and Target is connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal with Hostname does exist and Target is connected to expected IP address' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortalWithHostName) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                Mock Resolve-DNSName -MockWith {
                    return @( @{ IPAddress = $MockConnection.TargetAddress } )
                }
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiatorWithHostname.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                    Assert-MockCalled -commandName Resolve-DNSName -Exactly 1
                }
            }

            Context 'Target Portal with Hostname does exist and Target is connected to unexpected IP address' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortalWithHostName) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                Mock Connect-IscsiTarget -MockWith { return @($MockSession) }
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                Mock Resolve-DNSName -MockWith {
                    return @( @{ IPAddress = '1.1.1.1' } )
                }
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiatorWithHostname.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                    Assert-MockCalled -commandName Resolve-DNSName -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected but AuthenticationType is different' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                Mock Connect-IscsiTarget -MockWith { return @($MockSession) }
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.AuthenticationType = 'None'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent but should not be' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.IsPersistent = $False
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal exists but should not and Target is connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal exists but should not and Target is not connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does not exist and should not but Target is connected' {
                Mock Get-TargetPortal
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 1
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does not exist and should not and Target is not connected' {
                Mock Get-TargetPortal
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be, but iSNS Server is different' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject -MockWith { return @($MockiSNSSrver) }
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiatorWithiSNS.Clone()
                        $Splat.iSNSServer = 'different.contoso.com'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be, but iSNS Server is not set' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiatorWithiSNS.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be, but iSNS Server should not be set' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject -MockWith { return @($MockiSNSSrver) }
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiatorWithiSNS.Clone()
                        $Splat.iSNSServer = ''
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does not exist and should not and Target is not connected but iSNS Server is set' {
                Mock Get-TargetPortal
                Mock New-IscsiTargetPortal
                Mock Remove-IscsiTargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Connect-IscsiTarget
                Mock Disconnect-IscsiTarget
                Mock Register-IscsiSession
                Mock Unregister-IscsiSession
                Mock Get-WMIObject -MockWith { return @($MockiSNSSrver) }
                Mock Set-WMIInstance
                Mock Remove-WMIObject
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName New-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSITargetPortal -Exactly 0
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Connect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Disconnect-IscsiTarget -Exactly 0
                    Assert-MockCalled -commandName Register-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Unregister-IscsiSession -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 1
                }
            }
        }

        Describe "DSC_iSCSIInitiator\Test-TargetResource" {
            Context 'Target Portal does not exist but should' {
                Mock Get-TargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 0
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does not exist but should, Initiator Portal Address not set' {
                Mock Get-TargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiatorWithoutInitiatorAddress.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 0
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist and should but Target does not exist' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist and should but Target is disconnected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist and should but Target is disconnected, Initiator Portal Address not set' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortalWithoutInitiatorAddress) }
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiatorWithoutInitiatorAddress.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
            Mock Get-Target -MockWith { return @($MockTarget) }
            Mock Get-Connection
            Mock Get-Session
            Mock Get-WMIObject

            Context 'Target Portal does exist and should but TargetPortalPortNumber is different' {
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.TargetPortalPortNumber = $Splat.TargetPortalPortNumber + 1
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist and should but InitiatorInstanceName is different' {
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.InitiatorInstanceName = "Different"
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist and should but IsDataDigest is different' {
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.IsDataDigest = ! $Splat.IsDataDigest
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist and should but IsHeaderDigest is different' {
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.IsHeaderDigest = ! $Splat.IsHeaderDigest
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal using Hostname does exist, Target is connected using expected IP Address' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortalWithHostName) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Get-WMIObject
                Mock Resolve-DNSName -MockWith {
                    return @( @{ IPAddress = $MockConnection.TargetAddress } )
                }
                It 'should return true' {
                    $Splat = $TestInitiatorWithHostname.Clone()
                    Test-TargetResource @Splat | Should -Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Resolve-DNSName -Exactly 1
                }
            }

            Context 'Target Portal using Hostname does exist, Target is connected using unexpected IP Address' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortalWithHostName) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Get-WMIObject
                Mock Resolve-DNSName -MockWith {
                    return @( @{ IPAddress = '1.1.1.1' } )
                }
                It 'should return false' {
                    $Splat = $TestInitiatorWithHostname.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                    Assert-MockCalled -commandName Resolve-DNSName -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected but AuthenticationType is different' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.AuthenticationType = 'None'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Get-WMIObject
                It 'should return true' {
                    $Splat = $TestInitiator.Clone()
                    Test-TargetResource @Splat | Should -Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent but should not be' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.IsPersistent = $False
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal exists but should not and Target is connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal exists but should not and Target is not connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does not exist and should not but Target is connected' {
                Mock Get-TargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does not exist and should not and Target is not connected' {
                Mock Get-TargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject
                It 'should return true' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should -Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be and iSNS Server is not set' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Get-WMIObject
                It 'should return false' {
                    $Splat = $TestInitiatorWithiSNS.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be and iSNS Server is different' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Get-WMIObject -MockWith { return @($MockiSNSSrver) }
                It 'should return false' {
                    $Splat = $TestInitiatorWithiSNS.Clone()
                    $Splat.iSNSServer = 'different.contoso.com'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be and iSNS Server should be cleared' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }
                Mock Get-WMIObject -MockWith { return @($MockiSNSSrver) }
                It 'should return false' {
                    $Splat = $TestInitiatorWithiSNS.Clone()
                    $Splat.iSNSServer = ''
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }

            Context 'Target Portal does not exist and should not and Target is not connected but iSNS Server is set' {
                Mock Get-TargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                Mock Get-WMIObject -MockWith { return @($MockiSNSSrver) }
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                    Assert-MockCalled -commandName Get-WMIObject -Exactly 1
                }
            }
        }

        Describe "DSC_iSCSIInitiator\Get-TargetPortal" {
            Context 'Target Portal does not exist' {
                Mock Get-iSCSITargetPortal
                It 'should return null' {
                    $Splat = $TestInitiator.Clone()
                    $Result = Get-TargetPortal `
                        -TargetPortalAddress $Splat.TargetPortalAddress `
                        -InitiatorPortalAddress $Splat.InitiatorPortalAddress
                    $Result | Should -Be $null
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSITargetPortal -Exactly 1
                }
            }

            Context 'Target Portal does exist' {
                Mock Get-iSCSITargetPortal -MockWith { return @($MockTargetPortal) }
                It 'should return expected parameters' {
                    $Splat = $TestInitiator.Clone()
                    $Result = Get-TargetPortal `
                        -TargetPortalAddress $Splat.TargetPortalAddress `
                        -InitiatorPortalAddress $Splat.InitiatorPortalAddress
                    $Result.TargetPortalAddress    | Should -Be $MockTargetPortal.TargetPortalAddress
                    $Result.TargetPortalPortNumber | Should -Be $MockTargetPortal.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should -Be $MockTargetPortal.InitiatorInstanceName
                    $Result.InitiatorPortalAddress | Should -Be $MockTargetPortal.InitiatorPortalAddress
                    $Result.IsDataDigest           | Should -Be $MockTargetPortal.IsDataDigest
                    $Result.IsHeaderDigest         | Should -Be $MockTargetPortal.IsHeaderDigest
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSITargetPortal -Exactly 1
                }
            }
        }

        Describe "DSC_iSCSIInitiator\Get-Target" {
            Context 'Target does not exist' {
                Mock Get-iSCSITarget
                It 'should return null' {
                    $Splat = $TestInitiator.Clone()
                    $Result = Get-Target `
                        -NodeAddress $Splat.NodeAddress
                    $Result | Should -Be $null
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSITarget -Exactly 1
                }
            }

            Context 'Target does exist' {
               Mock Get-iSCSITarget -MockWith { return @($MockTarget) }
               It 'should return expected parameters' {
                    $Splat = $TestInitiator.Clone()
                    $Result = Get-Target `
                        -NodeAddress $Splat.NodeAddress
                    $Result.NodeAddress            | Should -Be $MockTarget.NodeAddress
                    $Result.IsConnected            | Should -Be $MockTarget.IsConnected
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSITarget -Exactly 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
