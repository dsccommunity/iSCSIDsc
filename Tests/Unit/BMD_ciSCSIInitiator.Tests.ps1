$Global:DSCModuleName = 'ciSCSI'
$Global:DSCResourceName = 'BMD_ciSCSIInitiator'

#region HEADER (V2)
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:DSCResourceName {
        
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
        
        $MockTargetPortal = [PSObject]@{
            TargetPortalAddress = $TestInitiator.TargetPortalAddress
            InitiatorPortalAddress = $TestInitiator.InitiatorPortalAddress
            TargetPortalPortNumber = $TestInitiator.TargetPortalPortNumber
            InitiatorInstanceName = $TestInitiator.InitiatorInstanceName
            IsDataDigest = $TestInitiator.IsDataDigest
            IsHeaderDigest = $TestInitiator.IsHeaderDigest
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

        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            Context 'Target Portal and Target do not exist' {
                Mock Get-TargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session                
                It 'should return absent' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }
            
            Context 'Target Portal exists but Target does not' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                It 'should return absent but with Target Portal data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure                 | Should Be 'Absent'
                    $Result.TargetPortalAddress    | Should Be $TestInitiator.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should Be $TestInitiator.InitiatorPortalAddress
                    $Result.TargetPortalPortNumber | Should Be $TestInitiator.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should Be $TestInitiator.InitiatorInstanceName
                    $Result.IsDataDigest           | Should Be $TestInitiator.IsDataDigest
                    $Result.IsHeaderDigest         | Should Be $TestInitiator.IsHeaderDigest
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Context 'Target Portal and Target exists but not connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                It 'should return absent but with Target Portal data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure                 | Should Be 'Absent'
                    $Result.TargetPortalAddress    | Should Be $TestInitiator.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should Be $TestInitiator.InitiatorPortalAddress
                    $Result.TargetPortalPortNumber | Should Be $TestInitiator.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should Be $TestInitiator.InitiatorInstanceName
                    $Result.IsDataDigest           | Should Be $TestInitiator.IsDataDigest
                    $Result.IsHeaderDigest         | Should Be $TestInitiator.IsHeaderDigest
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Context 'Target Portal and Target exists and is Connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }
                It 'should return correct data' {
                    $Result = Get-TargetResource `
                        -NodeAddress $TestInitiator.NodeAddress `
                        -TargetPortalAddress $TestInitiator.TargetPortalAddress `
                        -InitiatorPortalAddress $TestInitiator.InitiatorPortalAddress
                    $Result.Ensure                 | Should Be 'Present'
                    $Result.TargetPortalAddress    | Should Be $TestInitiator.TargetPortalAddress
                    $Result.InitiatorPortalAddress | Should Be $TestInitiator.InitiatorPortalAddress
                    $Result.TargetPortalPortNumber | Should Be $TestInitiator.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should Be $TestInitiator.InitiatorInstanceName
                    $Result.IsDataDigest           | Should Be $TestInitiator.IsDataDigest
                    $Result.IsHeaderDigest         | Should Be $TestInitiator.IsHeaderDigest
                    $Result.AuthenticationType     | Should Be $TestInitiator.AuthenticationType
                    $Result.InitiatorInstanceName  | Should Be $TestInitiator.InitiatorInstanceName
                    $Result.ConnectionIdentifier   | Should Be $MockConnection.ConnectionIdentifier
                    $Result.SessionIdentifier      | Should Be $MockSession.SessionIdentifier
                    $Result.IsConnected            | Should Be $MockSession.IsConnected
                    $Result.IsDiscovered           | Should Be $MockSession.IsDiscovered
                    $Result.IsPersistent           | Should Be $MockSession.IsPersistent
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                }
            }
        }
        
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
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

            Context 'Target Portal does exist and should but TargetPortalPortNumber is different' {
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.TargetPortalPortNumber = $Splat.TargetPortalPortNumber + 1
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                }
            }
            
            Context 'Target Portal does exist and should but InitiatorInstanceName is different' {
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.InitiatorInstanceName = "Different"
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                }
            }

            Context 'Target Portal does exist and should but IsDataDigest is different' {
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.IsDataDigest = ! $Splat.IsDataDigest
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                }
            }

            Context 'Target Portal does exist and should but IsHeaderDigest is different' {
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.IsHeaderDigest = ! $Splat.IsHeaderDigest
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.AuthenticationType = 'None'
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.IsPersistent = $False
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                It 'should not throw error' {
                    {
                        $Splat = $TestInitiator.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
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
                }
            }
        }
        
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Context 'Target Portal does not exist but should' {
                Mock Get-TargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    Test-TargetResource @Splat | Should Be $False
                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 0
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }
            
            Context 'Target Portal does exist and should but Target does not exist' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session                
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    Test-TargetResource @Splat | Should Be $False
                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Context 'Target Portal does exist and should but Target is disconnected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    Test-TargetResource @Splat | Should Be $False
                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
            Mock Get-Target -MockWith { return @($MockTarget) }
            Mock Get-Connection
            Mock Get-Session

            Context 'Target Portal does exist and should but TargetPortalPortNumber is different' {
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.TargetPortalPortNumber = $Splat.TargetPortalPortNumber + 1
                    Test-TargetResource @Splat | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }
            
            Context 'Target Portal does exist and should but InitiatorInstanceName is different' {
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.InitiatorInstanceName = "Different"
                    Test-TargetResource @Splat | Should Be $False                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Context 'Target Portal does exist and should but IsDataDigest is different' {
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.IsDataDigest = ! $Splat.IsDataDigest
                    Test-TargetResource @Splat | Should Be $False                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Context 'Target Portal does exist and should but IsHeaderDigest is different' {
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.IsHeaderDigest = ! $Splat.IsHeaderDigest
                    Test-TargetResource @Splat | Should Be $False                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Context 'Target Portal does exist, Target is connected but AuthenticationType is different' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSession) }                
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.AuthenticationType = 'None'
                    Test-TargetResource @Splat | Should Be $False                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent and should be' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }                
                It 'should return true' {
                    $Splat = $TestInitiator.Clone()
                    Test-TargetResource @Splat | Should Be $True                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                }
            }

            Context 'Target Portal does exist, Target is connected, is Persistent but should not be' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection -MockWith { return @($MockConnection) }
                Mock Get-Session -MockWith { return @($MockSessionPersistent) }                
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.IsPersistent = $False
                    Test-TargetResource @Splat | Should Be $False                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 1
                    Assert-MockCalled -commandName Get-Session -Exactly 1
                }
            }

            Context 'Target Portal exists but should not and Target is connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection
                Mock Get-Session                
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should Be $False                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }
            
            Context 'Target Portal exists but should not and Target is not connected' {
                Mock Get-TargetPortal -MockWith { return @($MockTargetPortal) }
                Mock Get-Target -MockWith { return @($MockTargetNotConnected) }
                Mock Get-Connection
                Mock Get-Session
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should Be $False                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Context 'Target Portal does not exist and should not but Target is connected' {                
                Mock Get-TargetPortal
                Mock Get-Target -MockWith { return @($MockTarget) }
                Mock Get-Connection
                Mock Get-Session
                It 'should return false' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should Be $False                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }

            Context 'Target Portal does not exist and should not and Target is not connected' {
                Mock Get-TargetPortal
                Mock Get-Target
                Mock Get-Connection
                Mock Get-Session
                It 'should return true' {
                    $Splat = $TestInitiator.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should Be $True       
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-TargetPortal -Exactly 1
                    Assert-MockCalled -commandName Get-Target -Exactly 1
                    Assert-MockCalled -commandName Get-Connection -Exactly 0
                    Assert-MockCalled -commandName Get-Session -Exactly 0
                }
            }
        }
        
        Describe "$($Global:DSCResourceName)\Get-TargetPortal" {
            Context 'Target Portal does not exist' {
                Mock Get-iSCSITargetPortal
                It 'should return null' {
                    $Splat = $TestInitiator.Clone()
                    $Result = Get-TargetPortal `
                        -TargetPortalAddress $Splat.TargetPortalAddress `
                        -InitiatorPortalAddress $Splat.InitiatorPortalAddress
                    $Result | Should Be $null
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
                    $Result.TargetPortalAddress    | Should Be $MockTargetPortal.TargetPortalAddress
                    $Result.TargetPortalPortNumber | Should Be $MockTargetPortal.TargetPortalPortNumber
                    $Result.InitiatorInstanceName  | Should Be $MockTargetPortal.InitiatorInstanceName
                    $Result.InitiatorPortalAddress | Should Be $MockTargetPortal.InitiatorPortalAddress
                    $Result.IsDataDigest           | Should Be $MockTargetPortal.IsDataDigest
                    $Result.IsHeaderDigest         | Should Be $MockTargetPortal.IsHeaderDigest
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSITargetPortal -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Get-Target" {
            Context 'Target does not exist' {
                Mock Get-iSCSITarget
                It 'should return null' {
                    $Splat = $TestInitiator.Clone()
                    $Result = Get-Target `
                        -NodeAddress $Splat.NodeAddress
                    $Result | Should Be $null
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
                    $Result.NodeAddress            | Should Be $MockTarget.NodeAddress
                    $Result.IsConnected            | Should Be $MockTarget.IsConnected
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSITarget -Exactly 1
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}