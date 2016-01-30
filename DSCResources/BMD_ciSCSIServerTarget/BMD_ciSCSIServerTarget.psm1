data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
GettingiSCSIServerTargetMessage=Getting iSCSI Server Target "{0}".
iSCSIServerTargetExistsMessage=iSCSI Server Target "{0}" exists.
iSCSIServerTargetDoesNotExistMessage=iSCSI Server Target "{0}" does not exist.
SettingiSCSIServerTargetMessage=Setting iSCSI Server Target "{0}".
EnsureiSCSIServerTargetExistsMessage=Ensuring iSCSI Server Target "{0}" exists.
EnsureiSCSIServerTargetDoesNotExistMessage=Ensuring iSCSI Server Target "{0}" does not exist.
iSCSIServerTargetCreatedMessage=iSCSI Server Target "{0}" has been created.
iSCSIServerTargetUpdatedMessage=iSCSI Server Target "{0}" has been updated.
iSCSIServerTargetRemovedMessage=iSCSI Server Target "{0}" has been removed.
TestingiSCSIServerTargetMessage=Testing iSCSI Server Target "{0}".
iSCSIServerTargetParameterNeedsUpdateMessage=iSCSI Server Target "{0}" {1} is different. Change required.
iSCSIServerTargetDoesNotExistAndShouldNotMessage=iSCSI Server Target "{0}" does not exist and should not. Change not required.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $TargetName,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $InitiatorIds,
        
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Paths        
    )
    
    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingiSCSIServerTargetMessage) `
            -f $TargetName
        ) -join '' )

    $ServerTarget =  Get-ServerTarget -TargetName $TargetName

    $returnValue = @{
        TargetName = $TargetName
    }
    if ($ServerTarget)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.iSCSIServerTargetExistsMessage) `
                -f $TargetName
            ) -join '' )

        $returnValue += @{
            Ensure = 'Present'
            InitiatorIds = @($ServerTarget.InitiatorIds.Value)
            Paths = @($ServerTarget.LunMappings.Path)
        }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.iSCSIServerTargetDoesNotExistMessage) `
                -f $TargetName
            ) -join '' )

        $returnValue += @{
            Ensure = 'Absent'
        }
    }

    $returnValue
} # Get-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $TargetName,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',
        
        [parameter(Mandatory = $true)]
        [System.String[]]
        $InitiatorIds,
        
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Paths
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.SettingiSCSIServerTargetMessage) `
            -f $TargetName
        ) -join '' )

    # Remove any parameters that can't be splatted.
    $null = $PSBoundParameters.Remove('Ensure')
    $null = $PSBoundParameters.Remove('Paths')

    # Lookup the existing iSCSI Server Target
    $ServerTarget = Get-ServerTarget -TargetName $TargetName

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureiSCSIServerTargetExistsMessage) `
                -f $TargetName
            ) -join '' )

        if ($ServerTarget)
        {
            # The iSCSI Server Target exists
            [String[]] $ExistingInitiatorIds = @($ServerTarget.InitiatorIds.Value)
            if (($InitiatorIds) -and (Compare-Object `
                -ReferenceObject $InitiatorIds `
                -DifferenceObject $ExistingInitiatorIds).Count -ne 0)
            {
                Set-iSCSIServerTarget `
                    -ComputerName LOCALHOST `
                    -TargetName $TargetName `
                    -InitiatorIds $InitiatorIds `
                    -ErrorAction Stop

                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIServerTargetUpdatedMessage) `
                        -f $TargetName
                    ) -join '' )
            }
        }
        else
        {
            # Create the iSCSI Server Target
            New-iSCSIServerTarget `
                @PSBoundParameters `
                -ComputerName LOCALHOST `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSIServerTargetCreatedMessage) `
                    -f $TargetName
                ) -join '' )
        }
        
        # Check that the Paths match in the Server Target
        foreach ($Path in $Paths)
        {
            if ($Path -notin $ServerTarget.LunMappings.Path)
            {
                # Path is not in the LunMappings - so add it
                Add-IscsiVirtualDiskTargetMapping `
                    -ComputerName LOCALHOST `
                    -TargetName $TargetName `
                    -Path $Path
            }
        }
        foreach ($Path in $ServerTarget.LunMappings.Path)
        {
            if ($Path -notin $Paths)
            {
                # Existing Path is not in listed in the paths - so remove it
                Remove-IscsiVirtualDiskTargetMapping `
                    -ComputerName LOCALHOST `
                    -TargetName $TargetName `
                    -Path $Path
            }
        }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureiSCSIServerTargetDoesNotExistMessage) `
                -f $TargetName
            ) -join '' )

        if ($ServerTarget)
        {
            # The iSCSI Server Target shouldn't exist - remove it
            Remove-iSCSIServerTarget `
                -ComputerName LOCALHOST `
                -TargetName $TargetName `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSIServerTargetRemovedMessage) `
                    -f $TargetName
                ) -join '' )
        } # if
    } # if
} # Set-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $TargetName,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',
        
        [parameter(Mandatory = $true)]
        [System.String[]]
        $InitiatorIds,
        
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Paths
    )
   
    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.TestingiSCSIServerTargetMessage) `
            -f $TargetName
        ) -join '' )

    # Lookup the existing iSCSI Server Target
    $ServerTarget = Get-ServerTarget -TargetName $TargetName

    if ($Ensure -eq 'Present')
    {
        # The iSCSI Server Target should exist
        if ($ServerTarget)
        {
            # The iSCSI Server Target exists already - check the parameters
            [String[]] $ExistingInitiatorIds = @($ServerTarget.InitiatorIds.Value)
            if (($InitiatorIds) -and (Compare-Object `
                -ReferenceObject $InitiatorIds `
                -DifferenceObject $ExistingInitiatorIds).Count -ne 0)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIServerTargetParameterNeedsUpdateMessage) `
                        -f $TargetName,'InitiatorIds'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            [String[]] $ExistingPaths = @($ServerTarget.LunMappings.Path)
            if (($Paths) -and (Compare-Object `
                -ReferenceObject $Paths `
                -DifferenceObject $ExistingPaths).Count -ne 0)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIServerTargetParameterNeedsUpdateMessage) `
                        -f $TargetName,'Paths'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
        }
        else
        {
            # Ths iSCSI Server Target doesn't exist but should
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.iSCSIServerTargetDoesNotExistButShouldMessage) `
                    -f $TargetName
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
    }
    else
    {
        # The iSCSI Server Target should not exist
        if ($ServerTarget)
        {
            # The iSCSI Server Target exists but should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.iSCSIServerTargetExistsButShouldNotMessage) `
                    -f $TargetName
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The iSCSI Server Target does not exist and should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.iSCSIServerTargetDoesNotExistAndShouldNotMessage) `
                    -f $TargetName
                ) -join '' )
        }
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource

# Helper Functions

Function Get-ServerTarget
{
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $TargetName
    )
    try
    {
        $ServerTarget = Get-iSCSIServerTarget `
            -ComputerName LOCALHOST `
            -TargetName $TargetName `
            -ErrorAction Stop
    }
    catch [Microsoft.Iscsi.Target.Commands.IscsiCmdException]
    {
        $ServerTarget = $null
    }
    catch
    {
        Throw $_
    }
    Return $ServerTarget
}

Export-ModuleMember -Function *-TargetResource