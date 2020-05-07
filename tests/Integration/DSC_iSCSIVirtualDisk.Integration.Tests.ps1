$script:dscModuleName = 'iSCSIDsc'
$script:dscResourceName = 'DSC_iSCSIVirtualDisk'

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
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).Config.ps1"
    . $configFile

    # Ensure that the tests can be performed on this computer
    $productType = (Get-CimInstance Win32_OperatingSystem).ProductType

    Describe 'Environment' {
        Context 'Operating System' {
            It 'Should be a Server OS' {
                $productType | Should -Be 3
            }
        }
    }

    if ($productType -ne 3)
    {
        Break
    }

    $installed = (Get-WindowsFeature -Name FS-iSCSITarget-Server).Installed

    Describe 'Environment' {
        Context 'Windows Features' {
            It 'Should have the iSCSI Target Feature Installed' {
                $installed | Should -Be $true
            }
        }
    }

    if ($installed -eq $false)
    {
        Break
    }

    Describe "$($script:DSCResourceName)_Integration" {
        Context 'When creating a iSCSI Virtual Disk' {
            BeforeAll {
                $script:virtualDisk = @{
                    Path            = Join-Path -Path $TestDrive -ChildPath 'TestiSCSIVirtualDisk.vhdx'
                    Ensure          = 'Present'
                    DiskType        = 'Dynamic'
                    SizeBytes       = 104857600
                    Description     = 'Integration Test iSCSI Virtual Disk'
                }
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                Path        = $script:virtualDisk.Path
                                Ensure      = $script:virtualDisk.Ensure
                                DiskType    = $script:virtualDisk.DiskType
                                SizeBytes   = $script:virtualDisk.SizeBytes
                                Description = $script:virtualDisk.Description
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                {
                    Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -throw
            }

            It 'Should have set the resource and all the parameters should match' {
                # Get the Rule details
                $virtualDiskNew = Get-iSCSIVirtualDisk -Path $script:virtualDisk.Path
                $script:virtualDisk.Path               | Should -Be $virtualDiskNew.Path
                $script:virtualDisk.DiskType           | Should -Be $virtualDiskNew.DiskType
                $script:virtualDisk.SizeBytes          | Should -Be $virtualDiskNew.SizeBytes
                $script:virtualDisk.Description        | Should -Be $virtualDiskNew.Description
            }

            AfterAll {
                # Clean up
                Remove-iSCSIVirtualDisk `
                    -Path $script:virtualDisk.Path
                Remove-Item `
                    -Path $script:virtualDisk.Path `
                    -Force
            } # AfterAll
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
