$Global:DSCModuleName   = 'ciSCSI'
$Global:DSCResourceName = 'BMD_ciSCSIServerTarget'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PlagueHO/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
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
        $TestVirtualDisk = [PSObject]@{
            Path                    = Join-Path -Path $ENV:Temp -ChildPath 'TestiSCSIVirtualDisk.vhdx'
        }
        
        $TestServerTarget = @{
            TargetName   = 'testtarget'
            Ensure       = 'Present'
            InitiatorIds = @( 'Iqn:iqn.1991-05.com.microsoft:fs1.contoso.com','Iqn:iqn.1991-05.com.microsoft:fs2.contoso.com' )
            Paths        = @( $TestVirtualDisk.Path )
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
       
        # Ensure that the tests can be performed on this computer
        $ProductType = (Get-CimInstance Win32_OperatingSystem).ProductType
        Describe 'Environment' {
            Context 'Operating System' {
                It 'Should be a Server OS' {
                    $ProductType | Should Be 3
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
                    $Installed | Should Be $true
                }
            }   
        }
        if ($Installed -eq $false)
        {
            Break
        }

        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
    
            Context 'Server Target does not exist' {
                
                Mock Get-iSCSIServerTarget
    
                It 'should return absent Server Target' {
                    $Result = Get-TargetResource `
                        -TargetName $TestServerTarget.TargetName `
                        -InitiatorIds $TestServerTarget.InitiatorIds `
                        -Paths $TestServerTarget.Paths
                    $Result.Ensure                  | Should Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                } 
            }
    
            Context 'Server Target does exist' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
    
                It 'should return correct Server Target' {
                    $Result = Get-TargetResource `
                        -TargetName $TestServerTarget.TargetName `
                        -InitiatorIds $TestServerTarget.InitiatorIds `
                        -Paths $TestServerTarget.Paths
                    $Result.Ensure                  | Should Be 'Present'
                    $Result.InitiatorIds            | Should Be $TestServerTarget.InitiatorIds
                    $Result.Paths                   | Should Be $TestServerTarget.Paths
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
    
            Context 'Server Target does not exist but should' {
                
                Mock Get-iSCSIServerTarget
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping   
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 1
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                }
            }
    
            Context 'Server Target exists and should but has an additional Path' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Paths += @( 'd:\NewVHD.vhdx' )
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 1
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                }
            }    

            Context 'Server Target exists and should but has different Paths' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Paths = @( 'd:\NewVHD.vhdx' )
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 1
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 1
                }
            }    

            Context 'Server Target exists and should but has different InitiatorIds' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.InitiatorIds += @( 'Iqn:iqn.1991-05.com.microsoft:fs3.contoso.com' )
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                }
            }    
   
            Context 'Server Target exists but should not' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
    
                It 'should not throw error' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                }
            }
    
            Context 'Server Target does not exist and should not' {
                
                Mock Get-iSCSIServerTarget
                Mock New-iSCSIServerTarget
                Mock Set-iSCSIServerTarget
                Mock Remove-iSCSIServerTarget
                Mock Add-IscsiVirtualDiskTargetMapping
                Mock Remove-IscsiVirtualDiskTargetMapping
                    
                It 'should not throw error' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIServerTarget -Exactly 0
                    Assert-MockCalled -commandName Add-IscsiVirtualDiskTargetMapping -Exactly 0
                    Assert-MockCalled -commandName Remove-IscsiVirtualDiskTargetMapping -Exactly 0
                }
            }
        }
    
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
    
            Context 'Server Target does not exist but should' {
                
                Mock Get-iSCSIServerTarget
    
                It 'should return false' {
                    $Splat = $TestServerTarget.Clone()
                    Test-TargetResource @Splat | Should Be $False
                    
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                }
            }
    
            Context 'Server Target exists and should but has a different Paths' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
    
                It 'should return false' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Paths = @( 'd:\NewVHD.vhdx' )
                        Test-TargetResource @Splat | Should Be $False
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                }
            }
    
            Context 'Server Target exists and should but has a different InitiatorIds' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
    
                It 'should return false' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.InitiatorIds += @( 'Iqn:iqn.1991-05.com.microsoft:fs3.contoso.com' )
                        Test-TargetResource @Splat | Should Be $False
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                }
            }

            Context 'Server Target exists and should and all parameters match' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
    
                It 'should return true' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        Test-TargetResource @Splat | Should Be $True
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                }
            }
    
            Context 'Server Target exists but should not' {
                
                Mock Get-iSCSIServerTarget -MockWith { return @($MockServerTarget) }
    
                It 'should return false' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should Be $False
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                }
            }
    
            Context 'Server Target does not exist and should not' {
                
                Mock Get-iSCSIServerTarget
    
                It 'should return true' {
                    { 
                        $Splat = $TestServerTarget.Clone()
                        $Splat.Ensure = 'Absent'
                        Test-TargetResource @Splat | Should Be $True
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIServerTarget -Exactly 1
                }
            }
        }

        Describe "$($Global:DSCResourceName)\Get-ServerTarget" {
    
            Context 'Server Target does not exist' {
                
                Mock Get-iSCSIServerTarget
    
                It 'should return null' {
                    $Splat = $TestServerTarget.Clone()
                    $Result = Get-ServerTarget -TargetName $Splat.TargetName 
                    $Result | Should Be $null             
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
                    $Result.InitiatorIds            | Should Be $MockServerTarget.InitiatorIds
                    $Result.Paths                   | Should Be $MockServerTarget.Paths
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