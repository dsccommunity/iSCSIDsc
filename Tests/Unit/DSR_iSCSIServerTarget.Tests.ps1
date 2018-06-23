$script:DSCModuleName   = 'iSCSIDsc'
$script:DSCResourceName = 'DSR_iSCSIServerTarget'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\iSCSIDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {

        # Create the Mock Objects that will be used for running tests
        $TestVirtualDisk = [PSObject]@{
            Path                    = Join-Path -Path $ENV:Temp -ChildPath 'TestiSCSIVirtualDisk.vhdx'
        }

        $TestServerTarget = @{
            TargetName   = 'testtarget'
            Ensure       = 'Present'
            InitiatorIds = @( 'Iqn:iqn.1991-05.com.microsoft:fs1.contoso.com','Iqn:iqn.1991-05.com.microsoft:fs2.contoso.com' )
            Paths        = @( $TestVirtualDisk.Path )
        }

        $TestServerTargetWithiSNS = @{
            TargetName   = 'testtarget'
            Ensure       = 'Present'
            InitiatorIds = @( 'Iqn:iqn.1991-05.com.microsoft:fs1.contoso.com','Iqn:iqn.1991-05.com.microsoft:fs2.contoso.com' )
            Paths        = @( $TestVirtualDisk.Path )
            iSNSServer   = 'isns.contoso.com'
        }

        $MockServerTarget = @{
            TargetName = $TestServerTarget.TargetName
            InitiatorIds = @(
                [PSObject]@{ Method = 'IQN'; Value = $TestServerTarget.InitiatorIds[0] }
                [PSObject]@{ Method = 'IQN'; Value = $TestServerTarget.InitiatorIds[1] }
            )
            LunMappings = @(
                [PSObject]@{
                    TargetName = $TestServerTarget.TargetName
                    Path       = $TestServerTarget.Paths[0]
                    Lun        = 0
                }
            )
        }

         $MockiSNSSrver = @{
             Path               = "\\Localhost\root\wmi:WT_ISnsServer.ServerName=`"$($TestServerTargetWithiSNS.iSNSServer)`""
             ServerName         = $TestServerTargetWithiSNS.iSNSServer
         }

        # Ensure that the tests can be performed on this computer
        $ProductType = (Get-CimInstance Win32_OperatingSystem).ProductType
        Describe 'Environment' {
            Context 'Operating System' {
                It 'Should be a Server OS' {
                    $ProductType | Should -Be 3
                }
            }
        }
        if ($ProductType -ne 3)
        {
            Break
        }

        $Installed = (Get-WindowsFeature -Name FS-iSCSITarget-Server).Installed
        Describe 'Environment' {
            Context 'Windows Features' {
                It 'Should have the iSCSI Target Feature Installed' {
                    $Installed | Should -Be $true
                }
            }
        }
        if ($Installed -eq $false)
        {
            Break
        }

        Describe "DSR_iSCSIServerTarget\Get-TargetResource" {

            Context 'Server Target does not exist' {

                Mock Get-iSCSIServerTarget
                Mock Get-CimInstance

                It 'should return absent Server Target' {
                    $Result = Get-TargetResource `
                        -TargetName $TestServerTarget.TargetName `
                        -InitiatorIds $TestServerTarget.InitiatorIds `
                        -Paths $TestServerTarget.Paths
                    $Result.Ensure                  | Should -Be 'Absent'
                    $Result.iSNSServer              | Should -BeNullOrEmpty
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-Cimnstance -Exactly 1
                }
            }

            Context 'Server Target exists and iSNS Server not set' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstance

                It 'should return correct Server Target' {
                    $Result = Get-TargetResource `
                        -TargetName $TestServerTarget.TargetName `
                        -InitiatorIds $TestServerTarget.InitiatorIds `
                        -Paths $TestServerTarget.Paths
                    $Result.Ensure                  | Should -Be 'Present'
                    $Result.InitiatorIds            | Should -Be $TestServerTarget.InitiatorIds
                    $Result.Paths                   | Should -Be $TestServerTarget.Paths
                    $Result.iSNSServer              | Should -BeNullOrEmpty
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstance -Exactly 1
                }
            }

            Context 'Server Target exists and iSNS Server set' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstance -MockWith { return @($MockiSNSSrver) }

                It 'should return correct Server Target' {
                    $Result = Get-TargetResource `
                        -TargetName $TestServerTargetWithiSNS.TargetName `
                        -InitiatorIds $TestServerTargetWithiSNS.InitiatorIds `
                        -Paths $TestServerTargetWithiSNS.Paths
                    $Result.Ensure                  | Should -Be 'Present'
                    $Result.InitiatorIds            | Should -Be $TestServerTargetWithiSNS.InitiatorIds
                    $Result.Paths                   | Should -Be $TestServerTargetWithiSNS.Paths
                    $Result.iSNSServer              | Should -Be $TestServerTargetWithiSNS.iSNSServer
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstance -Exactly 1
                }
            }
        }

        Describe "DSR_iSCSIServerTarget\Set-TargetResource" {

            Context 'Server Target does not exist but should' {

                Mock Get-iSCSIServerTarget
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstance
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTarget.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 1
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Server Target exists and should but has an additional Path' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstance
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Paths += @( 'd:\NewVHD.vhdx' )
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 1
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Server Target exists and should but has different Paths' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstance
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Paths = @( 'd:\NewVHD.vhdx' )
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 1
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Server Target exists and should but has different InitiatorIds' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstnace
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTarget.Clone()
                        $Splat.InitiatorIds += @( 'Iqn:iqn.1991-05.com.microsoft:fs3.contoso.com' )
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Server Target exists but should not' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstnace
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Server Target does not exist and should not' {

                Mock Get-iSCSIServerTarget
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstnace
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Server Target exists and should but iSNS Server is different' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstnace -MockWith { return @($MockiSNSSrver) }
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTargetWithiSNS.Clone()
                        $Splat.iSNSServer = 'different.contoso.com'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Server Target exists and should but iSNS Server is not set' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstnace
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTargetWithiSNS.Clone()
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 1
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 0
                }
            }

            Context 'Server Target exists and should but iSNS Server should not be set' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstnace -MockWith { return @($MockiSNSSrver) }
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTargetWithiSNS.Clone()
                        $Splat.iSNSServer = ''
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 1
                }
            }

            Context 'Server Target does not exist but iSNS Server is set' {

                Mock Get-iSCSIServerTarget
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                Mock Get-CimInstnace -MockWith { return @($MockiSNSSrver) }
                Mock Set-WMIInstance
                Mock Remove-WMIObject

                It 'should not throw error' {
                    {
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should -Not -Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                    Assert-MockCalled -commandName Set-WMIInstance -Exactly 0
                    Assert-MockCalled -commandName Remove-WMIObject -Exactly 1
                }
            }
        }

        Describe "DSR_iSCSIServerTarget\Test-TargetResource" {

            Context 'Server Target does not exist but should' {

                Mock Get-iSCSIServerTarget
                Mock Get-CimInstnace

                It 'should return false' {
                    $Splat = $TestServerTarget.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target exists and should but has a different Paths' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstnace

                It 'should return false' {
                    $Splat = $TestServerTarget.Clone()
                    $Splat.Paths = @( 'd:\NewVHD.vhdx' )
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target exists and should but has a different InitiatorIds' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstnace

                It 'should return false' {
                    $Splat = $TestServerTarget.Clone()
                    $Splat.InitiatorIds += @( 'Iqn:iqn.1991-05.com.microsoft:fs3.contoso.com' )
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target exists and should and all parameters match' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstnace

                It 'should return true' {
                    $Splat = $TestServerTarget.Clone()
                    Test-TargetResource @Splat | Should -Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target exists but should not' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstnace

                It 'should return false' {
                    $Splat = $TestServerTarget.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target does not exist and should not' {

                Mock Get-iSCSIServerTarget
                Mock Get-CimInstnace

                It 'should return true' {
                    $Splat = $TestServerTarget.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should -Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target exists and should and iSNS Server is not set' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstnace

                It 'should return false' {
                    $Splat = $TestServerTargetWithiSNS.Clone()
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target exists and should and iSNS Server is different' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstnace -MockWith { return @($MockiSNSSrver) }

                It 'should return false' {
                    $Splat = $TestServerTargetWithiSNS.Clone()
                    $Splat.iSNSServer = 'different.contoso.com'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target exists and should and iSNS Server should be cleared' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock Get-CimInstnace -MockWith { return @($MockiSNSSrver) }

                It 'should return false' {
                    $Splat = $TestServerTargetWithiSNS.Clone()
                    $Splat.iSNSServer = ''
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }

            Context 'Server Target does not exist and should not but iSNS Server is set' {

                Mock Get-iSCSIServerTarget
                Mock Get-CimInstnace -MockWith { return @($MockiSNSSrver) }

                It 'should return false' {
                    $Splat = $TestServerTarget.Clone()
                    $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should -Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Get-CimInstnace -Exactly 1
                }
            }
        }

        Describe "DSR_iSCSIServerTarget\Get-ServerTarget" {

            Context 'Server Target does not exist' {

                Mock Get-iSCSIServerTarget

                It 'should return null' {
                    $Splat = $TestServerTarget.Clone()
                    $Result = Get-ServerTarget -TargetName $Splat.TargetName
                    $Result | Should -Be $null
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                }
            }

            Context 'Server Target does exist' {

                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }

                It 'should return expected parameters' {
                    $Splat = $TestServerTarget.Clone()
                    $Result = Get-ServerTarget -TargetName $Splat.TargetName
                    $Result.InitiatorIds            | Should -Be $MockServerTarget.InitiatorIds
                    $Result.Paths                   | Should -Be $MockServerTarget.Paths
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
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
