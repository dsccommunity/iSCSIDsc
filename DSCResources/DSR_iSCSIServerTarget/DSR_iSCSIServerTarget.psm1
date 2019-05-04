$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the iSCSI Common Module
Import-Module -Name (Join-Path -Path $modulePath `
    -ChildPath (Join-Path -Path 'iSCSIDsc.Common' `
        -ChildPath 'iSCSIDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'DSR_iSCSIServerTarget' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Returns the current state of the specified iSCSI Server Target.

    .PARAMETER TargetName
        Specifies the name of the iSCSI target.

    .PARAMETER InitiatorIds
        Specifies the iSCSI initiator identifiers (IDs) to which the iSCSI target is assigned.

    .PARAMETER Paths
        Specifies the path of the virtual hard disk (VHD) files that are associated with the Server
        Target.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $InitiatorIds,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Paths
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($script:localizedData.GettingiSCSIServerTargetMessage) `
            -f $TargetName
        ) -join '' )

    $serverTarget =  Get-ServerTarget -TargetName $TargetName

    $returnValue = @{
        TargetName = $TargetName
    }
    if ($serverTarget)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.iSCSIServerTargetExistsMessage) `
                -f $TargetName
            ) -join '' )

        $returnValue += @{
            Ensure = 'Present'
            InitiatorIds = @($serverTarget.InitiatorIds.Value)
            Paths = @($serverTarget.LunMappings.Path)
        }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.iSCSIServerTargetDoesNotExistMessage) `
                -f $TargetName
            ) -join '' )

        $returnValue += @{
            Ensure = 'Absent'
        }
    } # if

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject `
        -Class WT_iSNSServer `
        -Namespace root\wmi
    if ($iSNSServerCurrent)
    {
        $returnValue += @{
            iSNSServer = $iSNSServerCurrent.ServerName
        }
    } # if

    $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
        Creates, updates or removes an iSCSI Server Target.

    .PARAMETER TargetName
        Specifies the name of the iSCSI target.

    .PARAMETER Ensure
        Ensures that Server Target is either Absent or Present.

    .PARAMETER InitiatorIds
        Specifies the iSCSI initiator identifiers (IDs) to which the iSCSI target is assigned.

    .PARAMETER Paths
        Specifies the path of the virtual hard disk (VHD) files that are associated with the Server
        Target.

    .PARAMETER iSNSServer
        Specifies an iSNS Server to register this Server Target with.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $InitiatorIds,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Paths,

        [Parameter()]
        [System.String]
        $iSNSServer
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($script:localizedData.SettingiSCSIServerTargetMessage) `
            -f $TargetName
        ) -join '' )

    # Lookup the existing iSCSI Server Target
    $serverTarget = Get-ServerTarget -TargetName $TargetName

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject `
        -Class WT_iSNSServer `
        -Namespace root\wmi

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.EnsureiSCSIServerTargetExistsMessage) `
                -f $TargetName
            ) -join '' )

        if ($serverTarget)
        {
            # The iSCSI Server Target exists
            [String[]] $existingInitiatorIds = @($serverTarget.InitiatorIds.Value)
            if (($InitiatorIds) -and (Compare-Object `
                -ReferenceObject $InitiatorIds `
                -DifferenceObject $existingInitiatorIds).Count -ne 0)
            {
                Set-iSCSIServerTarget `
                    -ComputerName LOCALHOST `
                    -TargetName $TargetName `
                    -InitiatorIds $InitiatorIds `
                    -ErrorAction Stop

                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSIServerTargetUpdatedMessage) `
                        -f $TargetName
                    ) -join '' )
            } # if
        }
        else
        {
            # Create the iSCSI Server Target
            New-iSCSIServerTarget `
                -TargetName $TargetName `
                -InitiatorIds $InitiatorIds `
                -ComputerName LOCALHOST `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSIServerTargetCreatedMessage) `
                    -f $TargetName
                ) -join '' )
        } # if

        # Check that the Paths match in the Server Target
        foreach ($Path in $Paths)
        {
            if ($Path -notin $serverTarget.LunMappings.Path)
            {
                # Path is not in the LunMappings - so add it
                Add-IscsiVirtualDiskTargetMapping `
                    -ComputerName LOCALHOST `
                    -TargetName $TargetName `
                    -Path $Path

                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSIServerTargetDiskAddedMessage) `
                        -f $TargetName,$Path
                    ) -join '' )
            } # if
        } # foreach
        foreach ($Path in $serverTarget.LunMappings.Path)
        {
            if ($Path -notin $Paths)
            {
                # Existing Path is not in listed in the paths - so remove it
                Remove-IscsiVirtualDiskTargetMapping `
                    -ComputerName LOCALHOST `
                    -TargetName $TargetName `
                    -Path $Path

                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSIServerTargetDiskRemovedMessage) `
                        -f $TargetName,$Path
                    ) -join '' )
            } # if
        } # foreach

        # Check the iSNS Server setting
        if ($PSBoundParameters.ContainsKey('iSNSServer'))
        {
            if ([String]::IsNullOrEmpty($iSNSServer))
            {
                if ($iSNSServerCurrent)
                {
                    # The iSNS Server is set but should not be - remove it
                    Remove-WmiObject `
                       -Path $iSNSServerCurrent.Path `
                       -ErrorAction Stop

                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSNSServerRemovedMessage)
                        ) -join '' )
                } # if
            }
            else
            {
                try
                {
                    Set-WmiInstance `
                        -Namespace root\wmi `
                        -Class WT_iSNSServer `
                        -Arguments @{ServerName=$iSNSServer} `
                        -ErrorAction Stop

                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSNSServerUpdatedMessage) `
                            -f $iSNSServer
                        ) -join '' )
                }
                catch
                {
                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSNSServerUpdateErrorMessage) `
                            -f $iSNSServer
                        ) -join '' )
                }
            } # if
        } # if
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.EnsureiSCSIServerTargetDoesNotExistMessage) `
                -f $TargetName
            ) -join '' )

        if ($serverTarget)
        {
            # The iSCSI Server Target shouldn't exist - remove it
            Remove-iSCSIServerTarget `
                -ComputerName LOCALHOST `
                -TargetName $TargetName `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSIServerTargetRemovedMessage) `
                    -f $TargetName
                ) -join '' )
        } # if

        if ($iSNSServerCurrent)
        {
            # The iSNS Server is set but should not be - remove it
            Remove-WmiObject `
                -Path $iSNSServerCurrent.Path `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSNSServerRemovedMessage)
                ) -join '' )
        } # if
    } # if
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests if an iSCSI Server Target needs to be created, updated or removed.

    .PARAMETER TargetName
        Specifies the name of the iSCSI target.

    .PARAMETER Ensure
        Ensures that Server Target is either Absent or Present.

    .PARAMETER InitiatorIds
        Specifies the iSCSI initiator identifiers (IDs) to which the iSCSI target is assigned.

    .PARAMETER Paths
        Specifies the path of the virtual hard disk (VHD) files that are associated with the Server
        Target.

    .PARAMETER iSNSServer
        Specifies an iSNS Server to register this Server Target with.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $InitiatorIds,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Paths,

        [Parameter()]
        [System.String]
        $iSNSServer
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($script:localizedData.TestingiSCSIServerTargetMessage) `
            -f $TargetName
        ) -join '' )

    # Lookup the existing iSCSI Server Target
    $serverTarget = Get-ServerTarget -TargetName $TargetName

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject `
        -Class WT_iSNSServer `
        -Namespace root\wmi

    if ($Ensure -eq 'Present')
    {
        # The iSCSI Server Target should exist
        if ($serverTarget)
        {
            # The iSCSI Server Target exists already - check the parameters
            [String[]] $existingInitiatorIds = @($serverTarget.InitiatorIds.Value)
            if (($InitiatorIds) -and (Compare-Object `
                -ReferenceObject $InitiatorIds `
                -DifferenceObject $existingInitiatorIds).Count -ne 0)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSIServerTargetParameterNeedsUpdateMessage) `
                        -f $TargetName,'InitiatorIds'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            [String[]] $ExistingPaths = @($serverTarget.LunMappings.Path)
            if (($Paths) -and (Compare-Object `
                -ReferenceObject $Paths `
                -DifferenceObject $ExistingPaths).Count -ne 0)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSIServerTargetParameterNeedsUpdateMessage) `
                        -f $TargetName,'Paths'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if
        }
        else
        {
            # Ths iSCSI Server Target doesn't exist but should
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSIServerTargetDoesNotExistButShouldMessage) `
                    -f $TargetName
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if

        # Check the iSNS Server setting
        if ($PSBoundParameters.ContainsKey('iSNSServer') `
            -and ($iSNSServerCurrent.ServerName -ne $iSNSServer))
        {
            # The iSNS Server is different so needs update
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSNSServerNeedsUpdateMessage) `
                    -f $iSNSServerCurrent.ServerName,$iSNSServer
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    }
    else
    {
        # The iSCSI Server Target should not exist
        if ($serverTarget)
        {
            # The iSCSI Server Target exists but should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSIServerTargetExistsButShouldNotMessage) `
                    -f $TargetName
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The iSCSI Server Target does not exist and should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSIServerTargetDoesNotExistAndShouldNotMessage) `
                    -f $TargetName
                ) -join '' )
        } # if

        # Check the iSNS Server setting
        if ($iSNSServerCurrent)
        {
            # The iSNS Server is set but should not be
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSNSServerIsSetButShouldBeNotMessage)
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    } # if

    return $desiredConfigurationMatch
} # Test-TargetResource

# Helper Functions
<#
    .SYNOPSIS
        Looks up the specified iSCSI Server Target.

    .PARAMETER TargetName
        The Target Name of the iSCSI Server Target to look up.
#>
function Get-ServerTarget
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetName
    )
    try
    {
        $serverTarget = Get-iSCSIServerTarget `
            -ComputerName LOCALHOST `
            -TargetName $TargetName `
            -ErrorAction Stop
    }
    catch [Microsoft.Iscsi.Target.Commands.IscsiCmdException]
    {
        $serverTarget = $null
    }
    catch
    {
        Throw $_
    }
    Return $serverTarget
}

Export-ModuleMember -function *-TargetResource
