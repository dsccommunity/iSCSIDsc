$script:DSCModuleName   = 'iSCSIDsc'
$script:DSCResourceName = 'DSR_iSCSIServerTarget'

#region HEADER
# Integration Test Template Version: 1.1.1
[System.String] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\iSCSIDsc'

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $script:moduleRoot -ChildPath "$($script:DSCModuleName).psd1") -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
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

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            New-iSCSIVirtualDisk `
                -Path $VirtualDisk.Path `
                -Size 10GB
        } # BeforeAll

        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -not -throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            # Get the Rule details
            $ServerTargetNew = Get-iSCSIServerTarget -TargetName $ServerTarget.TargetName
            $ServerTargetNew.TargetName       | Should -Be $ServerTarget.TargetName
            $ServerTargetNew.InitiatorIds     | Should -Be $ServerTarget.InitiatorIds
            $ServerTargetNew.LunMappings.Path | Should -Be $ServerTarget.Paths
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
                -TargetName $ServerTarget.TargetName
            Remove-iSCSIVirtualDisk `
                -Path $VirtualDisk.Path
            Remove-Item `
                -Path $VirtualDisk.Path `
                -Force
        } # AfterAll
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
