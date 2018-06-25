# Dot Source DSC Resource Files
Get-ChildItem -Path (Join-Path (Join-Path $PSScriptRoot "Public") "*.ps1") | ForEach-Object { . $_.FullName }

<#
function get-TargetResource
{
}

function Test-Targetresource
{
}

functionSet-TargetResource
{
}
#>

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
    -ChildPath (Join-Path -Path 'iSCSIDsc.ResourceHelper' `
        -ChildPath 'iSCSIDsc.ResourceHelper.psm1'))

# Import Localization Strings
$LocalizedData = Get-LocalizedData `
    -ResourceName 'DSR_iSCSIInitiator' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

# Helper Functions
<#
    .SYNOPSIS
        Looks up the specified iSCSI Target Portal.

    .PARAMETER TargetPortalAddress
        Represents the IP address or DNS name of the target portal.

    .PARAMETER InitiatorPortalAddress
        Specifies the IP address associated with the portal.
#>
function Get-TargetPortal
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetPortalAddress,

        [Parameter()]
        [System.String]
        $InitiatorPortalAddress
    )
    try
    {
        $targetPortal = Get-iSCSITargetPortal @PSBoundParameters `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $targetPortal = $null
    }
    catch
    {
        Throw $_
    }
    return $targetPortal
} # Get-TargetPortal

<#
    .SYNOPSIS
        Looks up the specified iSCSI Target.

    .PARAMETER NodeAddress
        Represents the IQN of the discovered target.
#>
function Get-Target
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $NodeAddress
    )
    try
    {
        $target = Get-iSCSITarget @PSBoundParameters `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $target = $null
    }
    catch
    {
        Throw $_
    }
    return $target
} # Get-Target

<#
    .SYNOPSIS
        Looks up the specified iSCSI Session.

    .PARAMETER Target
        The iSCSI Target to look up the session for.
#>
function Get-Session
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Target
    )
    try
    {
        $session = Get-iSCSISession `
            -IscsiTarget $Target `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $session = $null
    }
    catch
    {
        Throw $_
    }
    return $session
} # Get-Session

<#
    .SYNOPSIS
        Looks up the specified iSCSI Connection.

    .PARAMETER Target
        The iSCSI Target to look up the connection for.
#>
function Get-Connection
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Target
    )
    try
    {
        $connection = Get-iSCSIConnection `
            -IscsiTarget $Target `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $connection = $null
    }
    catch
    {
        Throw $_
    }
    return $Connection
} # Get-Connection
