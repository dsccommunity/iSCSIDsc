$script:DSCModuleName   = 'iSCSIDsc'
$script:DSCResourceName = 'MSFT_iSCSIVirtualDisk'

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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
            Ensure                  = 'Present'
            DiskType                = 'Differencing'
            SizeBytes               = 100MB
            Description             = 'Unit Test iSCSI Virtual Disk'
            BlockSizeBytes          = 2MB
            PhysicalSectorSizeBytes = 4096
            LogicalSectorSizeBytes  = 512
            ParentPath              = 'c:\Parent.vhdx'
        }

        $MockVirtualDisk = [PSObject]@{
            Path                    = $TestVirtualDisk.Path
            DiskType                = $TestVirtualDisk.DiskType
            Size                    = $TestVirtualDisk.SizeBytes
            Description             = $TestVirtualDisk.Description
            ParentPath              = $TestVirtualDisk.ParentPath
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

        Describe "MSFT_iSCSIVirtualDisk\Get-TargetResource" {

            Context 'Virtual Disk does not exist' {

                Mock Get-iSCSIVirtualDisk

                It 'should return absent Virtual Disk' {
                    $Result = Get-TargetResource `
                        -Path $TestVirtualDisk.Path
                    $Result.Ensure                  | Should Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk does exist' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }

                It 'should return correct Virtual Disk' {
                    $Result = Get-TargetResource `
                        -Path $TestVirtualDisk.Path
                    $Result.Ensure                  | Should Be 'Present'
                    $Result.Path                    | Should Be $TestVirtualDisk.Path
                    $Result.DiskType                | Should Be $TestVirtualDisk.DiskType
                    $Result.SizeBytes               | Should Be $TestVirtualDisk.SizeBytes
                    $Result.Description             | Should Be $TestVirtualDisk.Description
                    $Result.ParentPath              | Should Be $TestVirtualDisk.ParentPath
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }
        }

        Describe "MSFT_iSCSIVirtualDisk\Set-TargetResource" {

            Context 'Virtual Disk does not exist but should' {

                Mock Get-iSCSIVirtualDisk
                Mock New-iSCSIVirtualDisk
                Mock Set-iSCSIVirtualDisk
                Mock Remove-iSCSIVirtualDisk

                It 'should not throw error' {
                    {
                        $Splat = $TestVirtualDisk.Clone()
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName Set-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIVirtualDisk -Exactly 0
                }
            }

            Context 'Virtual Disk exists and should but has a different Description' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }
                Mock New-iSCSIVirtualDisk
                Mock Set-iSCSIVirtualDisk
                Mock Remove-iSCSIVirtualDisk

                It 'should not throw error' {
                    {
                        $Splat = $TestVirtualDisk.Clone()
                        $Splat.Description = 'Different'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName Remove-iSCSIVirtualDisk -Exactly 0
                }
            }

            Context 'Virtual Disk exists and should but has a different DiskType' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }
                Mock New-iSCSIVirtualDisk
                Mock Set-iSCSIVirtualDisk
                Mock Remove-iSCSIVirtualDisk

                It 'should throw an iSCSIVirtualDiskRequiresRecreateError exception' {
                    $Splat = $TestVirtualDisk.Clone()
                    $Splat.DiskType = 'Fixed'
                    $Splat.ParentPath = $null

                    $errorId = 'iSCSIVirtualDiskRequiresRecreateError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.iSCSIVirtualDiskRequiresRecreateError) -f $Splat.Path
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Set-TargetResource @Splat } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIVirtualDisk -Exactly 0
                }
            }

            Context 'Virtual Disk exists and should but has a different SizeBytes' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }
                Mock New-iSCSIVirtualDisk
                Mock Set-iSCSIVirtualDisk
                Mock Remove-iSCSIVirtualDisk

                It 'should throw an iSCSIVirtualDiskRequiresRecreateError exception' {
                    $Splat = $TestVirtualDisk.Clone()
                    $Splat.SizeBytes = $Splat.SizeBytes + 100MB

                    $errorId = 'iSCSIVirtualDiskRequiresRecreateError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.iSCSIVirtualDiskRequiresRecreateError) -f $Splat.Path
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Set-TargetResource @Splat } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIVirtualDisk -Exactly 0
                }
            }

            Context 'Virtual Disk exists and should but has a different ParentPath' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }
                Mock New-iSCSIVirtualDisk
                Mock Set-iSCSIVirtualDisk
                Mock Remove-iSCSIVirtualDisk

                It 'should throw an iSCSIVirtualDiskRequiresRecreateError exception' {
                    $Splat = $TestVirtualDisk.Clone()
                    $Splat.ParentPath = 'c:\NewParent.vhdx'

                    $errorId = 'iSCSIVirtualDiskRequiresRecreateError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.iSCSIVirtualDiskRequiresRecreateError) -f $Splat.Path
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Set-TargetResource @Splat } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIVirtualDisk -Exactly 0
                }
            }

            Context 'Virtual Disk exists but should not' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }
                Mock New-iSCSIVirtualDisk
                Mock Set-iSCSIVirtualDisk
                Mock Remove-iSCSIVirtualDisk

                It 'should not throw error' {
                    {
                        $Splat = $TestVirtualDisk.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk does not exist and should not' {

                Mock Get-iSCSIVirtualDisk
                Mock New-iSCSIVirtualDisk
                Mock Set-iSCSIVirtualDisk
                Mock Remove-iSCSIVirtualDisk

                It 'should not throw error' {
                    {
                        $Splat = $TestVirtualDisk.Clone()
                        $Splat.Ensure = 'Absent'
                        Set-TargetResource @Splat
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                    Assert-MockCalled -commandName New-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Set-iSCSIVirtualDisk -Exactly 0
                    Assert-MockCalled -commandName Remove-iSCSIVirtualDisk -Exactly 0
                }
            }
        }

        Describe "MSFT_iSCSIVirtualDisk\Test-TargetResource" {

            Context 'Virtual Disk does not exist but should' {

                Mock Get-iSCSIVirtualDisk

                It 'should return false' {
                    $Splat = $TestVirtualDisk.Clone()
                    Test-TargetResource @Splat | Should Be $False

                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk exists and should but has a different Description' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }

                It 'should return false' {
                    {
                        $Splat = $TestVirtualDisk.Clone()
                        $Splat.Description = 'Different'
                        Test-TargetResource @Splat | Should Be $False
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk exists and should but has a different DiskType' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }

                It 'should throw an iSCSIVirtualDiskRequiresRecreateError exception' {
                    $Splat = $TestVirtualDisk.Clone()
                    $Splat.DiskType = 'Fixed'
                    $Splat.ParentPath = $null

                    $errorId = 'iSCSIVirtualDiskRequiresRecreateError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.iSCSIVirtualDiskRequiresRecreateError) -f $Splat.Path
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Test-TargetResource @Splat } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk exists and should but has a different SizeBytes' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }

                It 'should throw an iSCSIVirtualDiskRequiresRecreateError exception' {
                    $Splat = $TestVirtualDisk.Clone()
                    $Splat.SizeBytes = $Splat.SizeBytes + 100MB

                    $errorId = 'iSCSIVirtualDiskRequiresRecreateError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.iSCSIVirtualDiskRequiresRecreateError) -f $Splat.Path
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Test-TargetResource @Splat } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk exists and should but has a different ParentPath' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }

                It 'should throw an iSCSIVirtualDiskRequiresRecreateError exception' {
                    $Splat = $TestVirtualDisk.Clone()
                    $Splat.ParentPath = 'c:\NewParent.vhdx'

                    $errorId = 'iSCSIVirtualDiskRequiresRecreateError'
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    $errorMessage = $($LocalizedData.iSCSIVirtualDiskRequiresRecreateError) -f $Splat.Path
                    $exception = New-Object -TypeName System.InvalidOperationException `
                        -ArgumentList $errorMessage
                    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                        -ArgumentList $exception, $errorId, $errorCategory, $null

                    { Test-TargetResource @Splat } | Should Throw $errorRecord
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk exists and should and all parameters match' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }

                It 'should return true' {
                    {
                        $Splat = $TestVirtualDisk.Clone()
                        Test-TargetResource @Splat | Should Be $True
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk exists but should not' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }

                It 'should return false' {
                    {
                        $Splat = $TestVirtualDisk.Clone()
                        $Splat.Ensure = 'Absent'
                    Test-TargetResource @Splat | Should Be $False
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk does not exist and should not' {

                Mock Get-iSCSIVirtualDisk

                It 'should return true' {
                    {
                        $Splat = $TestVirtualDisk.Clone()
                        $Splat.Ensure = 'Absent'
                        Test-TargetResource @Splat | Should Be $True
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }
        }

        Describe "MSFT_iSCSIVirtualDisk\Get-VirtualDisk" {

            Context 'Virtual Disk does not exist' {

                Mock Get-iSCSIVirtualDisk

                It 'should return null' {
                    $Splat = $TestVirtualDisk.Clone()
                    $Result = Get-VirtualDisk -Path $Splat.Path
                    $Result | Should Be $null
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual Disk does exist' {

                Mock Get-iSCSIVirtualDisk -MockWith { return @($MockVirtualDisk) }

                It 'should return expected parameters' {
                    $Splat = $TestVirtualDisk.Clone()
                    $Result = Get-VirtualDisk -Path $Splat.Path
                    $Result.Path                    | Should Be $MockVirtualDisk.Path
                    $Result.DiskType                | Should Be $MockVirtualDisk.DiskType
                    $Result.Size                    | Should Be $MockVirtualDisk.Size
                    $Result.Description             | Should Be $MockVirtualDisk.Description
                    $Result.ParentPath              | Should Be $MockVirtualDisk.ParentPath
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-iSCSIVirtualDisk -Exactly 1
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
