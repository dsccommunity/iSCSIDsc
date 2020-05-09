<#
    .SYNOPSIS
        Returns an invalid argument exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function Get-InvalidArgumentRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message,
        $ArgumentName )
    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $argumentException, $ArgumentName, 'InvalidArgument', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Returns an invalid operation exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function Get-InvalidOperationRecord
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $Message)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
    }
    elseif ($null -eq $ErrorRecord)
    {
        $invalidOperationException =
            New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message )
    }
    else
    {
        $invalidOperationException =
            New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message,
                $ErrorRecord.Exception )
    }

    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect',
            'InvalidOperation', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Asserts if the system is able to run integration tests.

    .NOTES
        When running integrations tests in Azure DevOps agents an exception is thrown
        when creating a virtual iSCSI disk on the system:
        UnauthorizedAccessException: Access is denied. (Exception from HRESULT: 0x80070005 (E_ACCESSDENIED))

        This previously did not occur and a solution to this has not been found.
        Therefore suppress execution of these tests if the Virtual Disk can not
        be created.
#>
function Assert-CanRunIntegrationTest
{
    [CmdletBinding()]
    param ()

    # Ensure that the tests can be performed on this computer
    $productType = (Get-CimInstance Win32_OperatingSystem).ProductType

    if ($productType -ne 3)
    {
        throw 'Integration tests can only be run on Windows Server operating systems'
    }

    $installed = (Get-WindowsFeature -Name FS-iSCSITarget-Server).Installed

    if ($installed -eq $false)
    {
        throw 'Integration tests require FS-iSCSITarget-Server windows feature to be installed'
    }

    $virtualDiskPath = Join-Path -Path $ENV:Temp -ChildPath 'AssertCreateIscsiVirtualDisk.vhdx'

    try
    {
        New-iSCSIVirtualDisk `
            -Path $virtualDiskPath `
            -Size 10MB
    }
    catch
    {
        Remove-iSCSIVirtualDisk `
            -Path $virtualDiskPath `
            -ErrorAction SilentlyContinue
        Remove-Item `
            -Path $virtualDiskPath `
            -Force `
            -ErrorAction SilentlyContinue

        throw ('Integration tests can only be run if an iSCSI Virtual Disk can be created. Failed with {0}' -f $_)
    }
}

Export-ModuleMember -Function `
    Get-InvalidArgumentRecord, `
    Get-InvalidOperationRecord, `
    Assert-CanRunIntegrationTest
