$script:dscModuleName = 'iSCSIDsc'
$script:dscResourceName = 'DSC_iSCSIServerTarget'

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
    Assert-CanRunIntegrationTest -Verbose
}
catch
{
    Write-Warning -Message $_
    return
}

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).Config.ps1"
    . $configFile

    Describe "$($script:DSCResourceName)_Integration" {
        Context 'When creating an iSCSI Server Target' {
            BeforeAll {
                $script:virtualDisk = @{
                    Path         = Join-Path -Path $TestDrive -ChildPath 'TestiSCSIServerTarget.vhdx'
                }
                $script:serverTarget = @{
                    TargetName   = 'testtarget'
                    Ensure       = 'Present'
                    InitiatorIds = @( 'Iqn:iqn.1991-05.com.microsoft:fs1.contoso.com','Iqn:iqn.1991-05.com.microsoft:fs2.contoso.com' )
                    Paths        = @( $script:virtualDisk.Path )
                    iSNSServer   = 'isns.contoso.com'
                }

                New-iSCSIVirtualDisk `
                    -Path $script:virtualDisk.Path `
                    -Size 104857600
            } # BeforeAll


            It 'Should compile and apply the MOF without throwing' {
                {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName     = 'localhost'
                                TargetName   = $script:serverTarget.TargetName
                                Ensure       = $script:serverTarget.Ensure
                                InitiatorIds = $script:serverTarget.InitiatorIds
                                Paths        = $script:serverTarget.Paths
                                iSNSServer   = $script:serverTarget.iSNSServer
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
                $ServerTargetNew = Get-iSCSIServerTarget -TargetName $script:serverTarget.TargetName
                $ServerTargetNew.TargetName       | Should -Be $script:serverTarget.TargetName
                $ServerTargetNew.InitiatorIds     | Should -Be $script:serverTarget.InitiatorIds
                $ServerTargetNew.LunMappings.Path | Should -Be $script:serverTarget.Paths
                $iSNSServerNew = Get-WmiObject -Class WT_iSNSServer -Namespace root\wmi
                # The iSNS Server is not usually accessible so won't be able to be set
                # $iSNSServerNew.ServerName         | Should Be $ServerTarget.iSNSServer
            }

            AfterAll {
                # Clean up
                Get-WmiObject `
                    -Class WT_iSNSServer `
                    -Namespace root\wmi | Remove-WmiObject
                Remove-iSCSIServerTarget `
                    -TargetName $script:serverTarget.TargetName
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
