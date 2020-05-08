<#
    These tests are disabled because they require iSCSI Loopback
    iSCSI Loopback is supposed to work in Windows Server 2012 R2
    However, as of 2016-01-03 I have not been able to get it to
    work and there is no documentation available on how to do so.
    See http://blogs.technet.com/b/filecab/archive/2012/05/21/introduction-of-iscsi-target-in-windows-server-2012.aspx
    This has been left here in case someone is able to figure out
    how to get it going.
#>
return

$script:dscModuleName = 'iSCSIDsc'
$script:dscResourceName = 'DSC_iSCSIInitiator'

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

    Describe "$($script:DSCResourceName)_Integration" {
        Context 'When creating an iSCSI Initiator' {
            BeforeAll {
                $script:ipAddress = (Get-NetIPAddress -InterfaceIndex (Get-NetConnectionProfile -IPv4Connectivity Internet).InterfaceIndex -AddressFamily IPv4).IPAddress
                $script:targetName = 'TestServerTarget'
                $script:Initiator = @{
                    NodeAddress            = "iqn.1991-05.com.microsoft:$($ENV:ComputerName)-$script:targetName-target-target"
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
                    iSNSServer             = "isns.contoso.com"
                }

                # Create a Server Target on this computer to test with
                $script:virtualDiskPath = Join-Path `
                    -Path $TestDrive `
                    -ChildPath ([System.IO.Path]::ChangeExtension([System.IO.Path]::GetRandomFileName(),'vhdx'))

                New-iSCSIVirtualDisk `
                    -ComputerName LOCALHOST `
                    -Path $script:virtualDiskPath `
                    -SizeBytes 500MB
                New-iSCSIServerTarget `
                    -TargetName $script:targetName `
                    -InitiatorIds "Iqn:iqn.1991-05.com.microsoft:$($script:Initiator.InitiatorPortalAddress)" `
                    -ComputerName LOCALHOST
                Add-IscsiVirtualDiskTargetMapping `
                    -ComputerName LOCALHOST `
                    -TargetName $script:targetName `
                    -Path $script:virtualDiskPath
            } # BeforeAll

            It 'Should compile and apply the MOF without throwing' {
                {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName               = 'localhost'
                                NodeAddress            = $script:initiator.NodeAddress
                                TargetPortalAddress    = $script:initiator.TargetPortalAddress
                                InitiatorPortalAddress = $script:initiator.InitiatorPortalAddress
                                Ensure                 = $script:initiator.Ensure
                                TargetPortalPortNumber = $script:initiator.TargetPortalPortNumber
                                InitiatorInstanceName  = $script:initiator.InitiatorInstanceName
                                AuthenticationType     = $script:initiator.AuthenticationType
                                ChapUsername           = $script:initiator.ChapUsername
                                ChapSecret             = $script:initiator.ChapSecret
                                IsDataDigest           = $script:initiator.IsDataDigest
                                IsHeaderDigest         = $script:initiator.IsHeaderDigest
                                IsMultipathEnabled     = $script:initiator.IsMultipathEnabled
                                IsPersistent           = $script:initiator.IsPersistent
                                ReportToPnP            = $script:initiator.ReportToPnP
                                iSNSServer             = $script:initiator.iSNSServer
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
                # Get the Target Portal details
                $targetPortalNew = Get-iSCSITargetPortal `
                    -TargetPortalAddress $TargetPortal.TargetPortalAddress `
                    -InitiatorPortalAddress $TargetPortal.InitiatorPortalAddress
                $script:Initiator.TargetPortalAddress    | Should -Be $targetPortalNew.TargetPortalAddress
                $script:Initiator.TargetPortalPortNumber | Should -Be $targetPortalNew.TargetPortalPortNumber
                $script:Initiator.InitiatorInstanceName  | Should -Be $targetPortalNew.InitiatorInstanceName
                $script:Initiator.InitiatorPortalAddress | Should -Be $targetPortalNew.InitiatorPortalAddress
                $script:Initiator.IsDataDigest           | Should -Be $targetPortalNew.IsDataDigest
                $script:Initiator.IsHeaderDigest         | Should -Be $targetPortalNew.IsHeaderDigest
                $targetNew = Get-iSCSITarget `
                    -NodeAddress $script:Initiator.NodeAddress
                $script:Initiator.IsConnected            | Should -Be $True
                $script:Initiator.NodeAddress            | Should -Be $targetNew.NodeAddress
                $sessionNew = Get-iSCSISession `
                    -IscsiTarget $targetNew
                $script:Initiator.TargetPortalAddress    | Should -Be $sessionNew.TargetAddress
                $script:Initiator.InitiatorPortalAddress | Should -Be $sessionNew.InitiatorAddress
                $script:Initiator.TargetPortalPortNumber | Should -Be $sessionNew.TargetPortNumber
                $script:Initiator.ConnectionIdentifier   | Should -Be $sessionNew.ConnectionIdentifier
                $connectionNew = Get-iSCSIConnection `
                    -NodeAddress $Target.NodeAddress
                $script:Initiator.AuthenticationType     | Should -Be $connectionNew.AuthenticationType
                $script:Initiator.InitiatorInstanceName  | Should -Be $connectionNew.InitiatorInstanceName
                $script:Initiator.InitiatorPortalAddress | Should -Be $connectionNew.InitiatorPortalAddress
                $script:Initiator.IsConnected            | Should -Be $connectionNew.IsConnected
                $script:Initiator.IsDataDigest           | Should -Be $connectionNew.IsDataDigest
                $script:Initiator.IsDiscovered           | Should -Be $connectionNew.IsDiscovered
                $script:Initiator.IsHeaderDigest         | Should -Be $connectionNew.IsHeaderDigest
                $script:Initiator.IsPersistent           | Should -Be $connectionNew.IsPersistent
                $iSNSServerNew = Get-WmiObject -Class MSiSCSIInitiator_iSNSServerClass -Namespace root\wmi
                # The iSNS Server is not usually accessible so won't be able to be set
                # $script:Initiator.iSNSServer          | Should Be $iSNSServerNew.iSNSServerAddress
            }

            AfterAll {
                # Clean up
                Disconnect-IscsiTarget `
                    -NodeAddress $script:Initiator.NodeAddress `
                    -Confirm:$False
                Remove-IscsiTargetPortal `
                    -TargetPortalAddress $script:Initiator.TargetPortalAddress `
                    -InitiatorPortalAddress $script:Initiator.InitiatorPortalAddress `
                    -Confirm:$False
                Remove-iSCSIServerTarget `
                    -ComputerName LOCALHOST `
                    -TargetName $script:targetName
                Remove-iSCSIVirtualDisk `
                    -ComputerName LOCALHOST `
                    -Path $script:virtualDiskPath
                Remove-Item `
                    -Path $script:virtualDiskPath `
                    -Force
            } # AfterAll
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
