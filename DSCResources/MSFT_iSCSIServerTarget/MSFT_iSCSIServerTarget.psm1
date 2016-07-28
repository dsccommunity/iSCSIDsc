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
iSCSIServerTargetDiskAddedMessage=iSCSI Server Target "{0}" Virtual Disk "{1}" added.
iSCSIServerTargetDiskRemovedMessage=iSCSI Server Target "{0}" Virtual Disk "{1}" removed.
iSCSIServerTargetUpdatedMessage=iSCSI Server Target "{0}" has been updated.
iSCSIServerTargetRemovedMessage=iSCSI Server Target "{0}" has been removed.
iSNSServerRemovedMessage=iSNS Server has been cleared.
iSNSServerUpdatedMessage=iSNS Server has been set to "{0}".
iSNSServerUpdateErrorMessage=An error occurred setting the iSNS Server to "{0}". This is usually caused by the iSNS Server not being accessible.
TestingiSCSIServerTargetMessage=Testing iSCSI Server Target "{0}".
iSCSIServerTargetParameterNeedsUpdateMessage=iSCSI Server Target "{0}" {1} is different. Change required.
iSCSIServerTargetExistsButShouldNotMessage=iSCSI Server Target "{0}" exists but should not. Change required.
iSCSIServerTargetDoesNotExistButShouldMessage=iSCSI Server Target "{0}" does not exist but should. Change required.
iSCSIServerTargetDoesNotExistAndShouldNotMessage=iSCSI Server Target "{0}" does not exist and should not. Change not required.
iSNSServerNeedsUpdateMessage=iSNS Server is "{0}" but should be "{1}". Change required.
iSNSServerIsSetButShouldBeNotMessage=iSNS Server is set but should not be. Change required.
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
        $Paths,

        [System.String]
        $iSNSServer
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.SettingiSCSIServerTargetMessage) `
            -f $TargetName
        ) -join '' )

    # Lookup the existing iSCSI Server Target
    $ServerTarget = Get-ServerTarget -TargetName $TargetName

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject `
        -Class WT_iSNSServer `
        -Namespace root\wmi

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
                $($LocalizedData.iSCSIServerTargetCreatedMessage) `
                    -f $TargetName
                ) -join '' )
        } # if

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

                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIServerTargetDiskAddedMessage) `
                        -f $TargetName,$Path
                    ) -join '' )
            } # if
        } # foreach
        foreach ($Path in $ServerTarget.LunMappings.Path)
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
                    $($LocalizedData.iSCSIServerTargetDiskRemovedMessage) `
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
                        $($LocalizedData.iSNSServerRemovedMessage)
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
                        $($LocalizedData.iSNSServerUpdatedMessage) `
                            -f $iSNSServer
                        ) -join '' )
                }
                catch
                {
                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSNSServerUpdateErrorMessage) `
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

        if ($iSNSServerCurrent)
        {
            # The iSNS Server is set but should not be - remove it
            Remove-WmiObject `
                -Path $iSNSServerCurrent.Path `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSNSServerRemovedMessage)
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
        $Paths,

        [System.String]
        $iSNSServer
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

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject `
        -Class WT_iSNSServer `
        -Namespace root\wmi

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
            } # if

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
            } # if
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
        } # if

        # Check the iSNS Server setting
        if ($PSBoundParameters.ContainsKey('iSNSServer') `
            -and ($iSNSServerCurrent.ServerName -ne $iSNSServer))
        {
            # The iSNS Server is different so needs update
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSNSServerNeedsUpdateMessage) `
                    -f $iSNSServerCurrent.ServerName,$iSNSServer
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
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
        } # if

        # Check the iSNS Server setting
        if ($iSNSServerCurrent)
        {
            # The iSNS Server is set but should not be
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSNSServerIsSetButShouldBeNotMessage)
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
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
