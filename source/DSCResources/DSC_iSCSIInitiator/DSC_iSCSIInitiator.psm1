$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-localizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the specified iSCSI Initiator.

    .PARAMETER NodeAddress
        Represents the IQN of the discovered target.

    .PARAMETER TargetPortalAddress
        Represents the IP address or DNS name of the target portal.

    .PARAMETER Ensure
        Ensures that Target is Absent or Present.

    .PARAMETER InitiatorPortalAddress
        Specifies the IP address associated with the portal.
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
        $NodeAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetPortalAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $InitiatorPortalAddress
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingiSCSIInitiatorMessage) `
                -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress
        ) -join '' )

    $returnValue = @{
        NodeAddress            = $NodeAddress
        TargetPortalAddress    = $TargetPortalAddress
        InitiatorPortalAddress = $InitiatorPortalAddress
        Ensure                 = 'Absent'
    }

    # Lookup the Target Portal
    $targetPortal = Get-TargetPortal `
        -TargetPortalAddress $TargetPortalAddress `
        -InitiatorPortalAddress $InitiatorPortalAddress

    if ($targetPortal)
    {
        $returnValue.TargetPortalAddress = $targetPortal.TargetPortalAddress
        $returnValue.InitiatorPortalAddress = $targetPortal.InitiatorPortalAddress
        $returnValue.TargetPortalPortNumber = $targetPortal.TargetPortalPortNumber
        $returnValue.InitiatorInstanceName = $targetPortal.InitiatorInstanceName
        $returnValue.IsDataDigest = $targetPortal.IsDataDigest
        $returnValue.IsHeaderDigest = $targetPortal.IsHeaderDigest

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSITargetPortalExistsMessage) `
                    -f $TargetPortalAddress, $InitiatorPortalAddress
            ) -join '' )
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSITargetPortalDoesNotExistMessage) `
                    -f $TargetPortalAddress, $InitiatorPortalAddress
            ) -join '' )
    } # if

    # Lookup the Target
    $target = Get-Target `
        -NodeAddress $NodeAddress

    if ($target)
    {
        $returnValue.NodeAddress = $target.NodeAddress
        $returnValue.IsConnected = $target.IsConnected

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSITargetExistsMessage) `
                    -f $NodeAddress
            ) -join '' )
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.iSCSITargetDoesNotExistMessage) `
                    -f $NodeAddress
            ) -join '' )
    } # if

    # The rest of the properties can only be populated if the Target is connected.
    if ($target.IsConnected)
    {
        # Lookup the Connection
        $connection = Get-Connection `
            -Target $Target

        $returnValue.Ensure = 'Present'

        if ($connection)
        {
            $returnValue.TargetPortalAddress = $connection.TargetAddress
            $returnValue.InitiatorPortalAddress = $connection.InitiatorAddress
            $returnValue.TargetPortalPortNumber = $connection.TargetPortNumber
            $returnValue.ConnectionIdentifier = $connection.ConnectionIdentifier

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSIConnectionExistsMessage) `
                        -f $NodeAddress
                ) -join '' )
        }
        else
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSIConnectionDoesNotExistMessage) `
                        -f $NodeAddress
                ) -join '' )
        } # if

        # Lookup the Session
        $session = Get-Session `
            -Target $target

        if ($session)
        {
            $returnValue.AuthenticationType = $session.AuthenticationType
            $returnValue.InitiatorInstanceName = $session.InitiatorInstanceName
            $returnValue.InitiatorPortalAddress = $session.InitiatorPortalAddress
            $returnValue.IsConnected = $session.IsConnected
            $returnValue.IsDataDigest = $session.IsDataDigest
            $returnValue.IsDiscovered = $session.IsDiscovered
            $returnValue.IsHeaderDigest = $session.IsHeaderDigest
            $returnValue.IsPersistent = $session.IsPersistent
            $returnValue.SessionIdentifier = $session.SessionIdentifier

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSISessionExistsMessage) `
                        -f $NodeAddress
                ) -join '' )
        }
        else
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSISessionDoesNotExistMessage) `
                        -f $NodeAddress
                ) -join '' )
        } # if
    } # if

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject `
        -Class MSiSCSIInitiator_iSNSServerClass `
        -Namespace root\wmi
    if ($iSNSServerCurrent)
    {
        $returnValue += @{
            iSNSServer = $iSNSServerCurrent.iSNSServerAddress
        }
    }

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
        Creates, updates or removes an iSCSI Initiator.

    .PARAMETER NodeAddress
        Represents the IQN of the discovered target.

    .PARAMETER TargetPortalAddress
        Represents the IP address or DNS name of the target portal.

    .PARAMETER Ensure
        Ensures that Target is Absent or Present.

    .PARAMETER InitiatorPortalAddress
        Specifies the IP address associated with the portal.

    .PARAMETER TargetPortalPortNumber
        Specifies the TCP/IP port number for the target portal.

    .PARAMETER InitiatorInstanceName
        The name of the initiator instance that the iSCSI initiator service uses to send SendTargets
        requests to the target portal. If no instance name is specified, the iSCSI initiator service
        chooses the initiator instance.

    .PARAMETER AuthenticationType
        Specifies the type of authentication to use when logging into the target.

    .PARAMETER ChapUsername
        Specifies the user name to use when establishing a connection authenticated by using Mutual
        CHAP.

    .PARAMETER ChapSecret
        Specifies the CHAP secret to use when establishing a connection authenticated by using CHAP.

    .PARAMETER IsDataDigest
        Enables data digest when the initiator logs into the target portal.

    .PARAMETER IsHeaderDigest
        Enables header digest when the initiator logs into the target portal. By not specifying this
        parameter, the digest setting is determined by the initiator kernel mode driver.

    .PARAMETER IsMultipathEnabled
        Indicates that the initiator has enabled Multipath I/O (MPIO) and it will be used when logging
        into the target portal.

    .PARAMETER IsPersistent
        Specifies that the session is to be automatically connected after each restart.

    .PARAMETER ReportToPnP
        Specifies that the operation is reported to PNP.

    .PARAMETER iSNSServer
        Specifies an iSNS Server to register this Initiator with.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $NodeAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetPortalAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $InitiatorPortalAddress,

        [Parameter()]
        [System.Uint16]
        $TargetPortalPortNumber,

        [Parameter()]
        [System.String]
        $InitiatorInstanceName,

        [Parameter()]
        [ValidateSet('None', 'OneWayCHAP', 'MutualCHAP')]
        [System.String]
        $AuthenticationType,

        [Parameter()]
        [System.String]
        $ChapUsername,

        [Parameter()]
        [System.String]
        $ChapSecret,

        [Parameter()]
        [System.Boolean]
        $IsDataDigest,

        [Parameter()]
        [System.Boolean]
        $IsHeaderDigest,

        [Parameter()]
        [System.Boolean]
        $IsMultipathEnabled,

        [Parameter()]
        [System.Boolean]
        $IsPersistent,

        [Parameter()]
        [System.Boolean]
        $ReportToPNP,

        [Parameter()]
        [System.String]
        $iSNSServer
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.SettingiSCSIInitiatorMessage) `
                -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress
        ) -join '' )

    # Remove any parameters that can't be splatted.
    $null = $PSBoundParameters.Remove('Ensure')

    $targetSplat = @{ TargetPortalAddress = $TargetPortalAddress }
    if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress'))
    {
        $targetSplat += @{ InitiatorPortalAddress = $InitiatorPortalAddress }
    }

    # Lookup the existing iSCSI Target Portal
    $targetPortal = Get-TargetPortal @TargetSplat

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject -Class MSiSCSIInitiator_iSNSServerClass -Namespace root\wmi

    $returnValue += @{iSNSServer = $iSNSServerCurrent.iSNSServerAddress }

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.EnsureiSCSITargetPortalExistsMessage) `
                    -f $TargetPortalAddress, $InitiatorPortalAddress
            ) -join '' )

        [Boolean] $create = $false

        if ($targetPortal)
        {
            # The iSCSI Target Portal exists - check the parameters
            if (($TargetPortalPortNumber) -and ($targetPortal.TargetPortalPortNumber -ne $TargetPortalPortNumber))
            {
                $create = $true
            } # if
            if (($InitiatorInstanceName) -and ($targetPortal.InitiatorInstanceName -ne $InitiatorInstanceName))
            {
                $create = $true
            } # if
            if (($null -ne $IsDataDigest) -and ($targetPortal.IsDataDigest -ne $IsDataDigest))
            {
                $create = $true
            } # if
            if (($null -ne $IsHeaderDigest) -and ($targetPortal.IsHeaderDigest -ne $IsHeaderDigest))
            {
                $create = $true
            } # if

            if ($create)
            {
                # The Target Portal exists but has different parameters
                # so it has to be removed and recreated
                Remove-iSCSITargetPortal @TargetSplat -ErrorAction Stop

                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSITargetPortalRemovedForRecreateMessage) `
                            -f $TargetPortalAddress, $InitiatorPortalAddress
                    ) -join '' )
            } # if
        }
        else
        {
            $create = $true
        } # if

        if ($create)
        {
            # Create the iSCSI Target Portal using a splat
            [PSObject] $splat = [PSObject]@{} + $PSBoundParameters
            $splat.Remove('NodeAddress')
            $splat.Remove('IsMultipathEnabled')
            $splat.Remove('IsPersistent')
            $splat.Remove('ReportToPNP')
            $splat.Remove('iSNSServer')
            New-iSCSITargetPortal `
                @splat `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSITargetPortalCreatedMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
                ) -join '' )
        }

        # Lookup the Target
        $target = Get-Target -NodeAddress $NodeAddress

        # Check the Target is connected
        [Boolean] $connect = $false

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.EnsureiSCSITargetIsConnectedMessage) `
                    -f $NodeAddress
            ) -join '' )

        if ($target)
        {
            # Lookup the Connection
            $connection = Get-Connection -Target $target
            # Lookup the Session
            $session = Get-Session `
                -Target $target
            if ($connection -and $session)
            {
                # Check that the session and connection parameters are correct

                # The Connection.TargetAddress will always be an IP Address
                # even if the TargetPortalAddress was specified as a Hostname
                try
                {
                    $targetPortalIP = @(
                                ([System.Net.IPAddress]$TargetPortalAddress).IPAddressToString
                    )
                }
                catch
                {
                    # This is a TargetPortalAddress is a Hostname so resolve it to IP addresses
                    $targetPortalIP = @(
                                (Resolve-DNSName -Name $TargetPortalAddress -Type A).IPAddress
                    )
                } # try

                if ($targetPortalIP -notin $connection.TargetAddress)
                {
                    $connect = $true
                } # if
                if ($InitiatorPortalAddress -notin $connection.InitiatorAddress)
                {
                    $connect = $true
                } # if
                if (($TargetPortalPortNumber) `
                        -and ($connection.TargetPortNumber -ne $TargetPortalPortNumber))
                {
                    $connect = $true
                } # if
                if (($AuthenticationType) `
                        -and ($session.AuthenticationType -ne $AuthenticationType))
                {
                    $connect = $true
                } # if
                if (($InitiatorInstanceName) `
                        -and ($session.InitiatorInstanceName -ne $InitiatorInstanceName))
                {
                    $connect = $true
                } # if
                if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress') `
                        -and ($InitiatorPortalAddress -notin $connection.InitiatorAddress))
                {
                    $connect = $true
                } # if
                if (($null -ne $IsDataDigest) `
                        -and ($session.IsDataDigest -ne $IsDataDigest))
                {
                    $connect = $true
                } # if
                if (($null -ne $IsHeaderDigest) `
                        -and ($session.IsHeaderDigest -ne $IsHeaderDigest))
                {
                    $connect = $true
                } # if
            }

            if ($connect)
            {
                #Removed disconnect to allow multisession when doing the connect-iscsitarget
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSITargetDisconnectedMessage) `
                            -f $NodeAddress
                    ) -join '' )

            }
            else
            {
                # Either the session or connection doesn't exist
                # so reconnect or the target is not connected
                $connect = $true
            } # if
        }
        else
        {
            $connect = $true
        } # if

        if ($connect)
        {
            [PSObject] $splat = [PSObject]@{} + $PSBoundParameters
            $splat.Remove('iSNSServer')

            $Session = Connect-IscsiTarget `
                @splat `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSITargetConnectedMessage) `
                        -f $NodeAddress
                ) -join '' )
        }
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
                        -Arguments @{ServerName = $iSNSServer } `
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
                $($script:localizedData.EnsureiSCSITargetIsDisconnectedMessage) `
                    -f $NodeAddress
            ) -join '' )

        # Lookup the Target
        $target = Get-Target `
            -NodeAddress $NodeAddress

        if ($target)
        {
            if ($target.IsConnected)
            {
                #lookup the session for this target and remove it
                if ($InitiatorPortalAddress -and $TargetPortalAddress)
                {
                    $connection = Get-Connection -Target $target | Where-Object { $_.initiatoraddress -eq $InitiatorPortalAddress -and $_.targetaddress -eq $TargetPortalAddress }
                }
                else
                {
                    $connection = Get-Connection -Target $target
                }
                foreach ($session in $connection)
                {
                    Get-IscsiSession -IscsiConnection $session | ForEach-Object {
                        Unregister-IscsiSession -SessionIdentifier $_.sessionidentifier -ErrorAction SilentlyContinue
                        Disconnect-IscsiTarget -NodeAddress $_.TargetNodeAddress -SessionIdentifier $_.sessionidentifier -Confirm:$false -ErrorAction SilentlyContinue
                        Write-Verbose -Message ( @(
                                "$($MyInvocation.MyCommand): "
                                $($script:localizedData.iSCSITargetDisconnectedMessage) `
                                    -f $NodeAddress
                            ) -join '' )
                    }
                }
            }
        }

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.EnsureiSCSITargetPortalDoesNotExistMessage) `
                    -f $TargetPortalAddress, $InitiatorPortalAddress
            ) -join '' )

        if ($targetPortal)
        {
            # The iSCSI Target Portal shouldn't exist - remove it
            Remove-iSCSITargetPortal `
                @TargetSplat `
                -Confirm:$False `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSITargetPortalRemovedMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
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
                    $($script:localizedData.iSCSIServerTargetiSNSRemovedMessage) `
                        -f $TargetName
                ) -join '' )
        } # if
    } # if
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests if an iSCSI Initiator needs to be created, updated or removed.
    .PARAMETER NodeAddress
        Represents the IQN of the discovered target.

    .PARAMETER TargetPortalAddress
        Represents the IP address or DNS name of the target portal.

    .PARAMETER Ensure
        Ensures that Target is Absent or Present.

    .PARAMETER InitiatorPortalAddress
        Specifies the IP address associated with the portal.

    .PARAMETER TargetPortalPortNumber
        Specifies the TCP/IP port number for the target portal.

    .PARAMETER InitiatorInstanceName
        The name of the initiator instance that the iSCSI initiator service uses to send SendTargets
        requests to the target portal. If no instance name is specified, the iSCSI initiator service
        chooses the initiator instance.

    .PARAMETER AuthenticationType
        Specifies the type of authentication to use when logging into the target.

    .PARAMETER ChapUsername
        Specifies the user name to use when establishing a connection authenticated by using Mutual
        CHAP.

    .PARAMETER ChapSecret
        Specifies the CHAP secret to use when establishing a connection authenticated by using CHAP.

    .PARAMETER IsDataDigest
        Enables data digest when the initiator logs into the target portal.

    .PARAMETER IsHeaderDigest
        Enables header digest when the initiator logs into the target portal. By not specifying this
        parameter, the digest setting is determined by the initiator kernel mode driver.

    .PARAMETER IsMultipathEnabled
        Indicates that the initiator has enabled Multipath I/O (MPIO) and it will be used when logging
        into the target portal.

    .PARAMETER IsPersistent
        Specifies that the session is to be automatically connected after each restart.

    .PARAMETER ReportToPnP
        Specifies that the operation is reported to PNP.

    .PARAMETER iSNSServer
        Specifies an iSNS Server to register this Initiator with.
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
        $NodeAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetPortalAddress,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $InitiatorPortalAddress,

        [Parameter()]
        [System.Uint16]
        $TargetPortalPortNumber,

        [Parameter()]
        [System.String]
        $InitiatorInstanceName,

        [Parameter()]
        [ValidateSet('None', 'OneWayCHAP', 'MutualCHAP')]
        [System.String]
        $AuthenticationType,

        [Parameter()]
        [System.String]
        $ChapUsername,

        [Parameter()]
        [System.String]
        $ChapSecret,

        [Parameter()]
        [System.Boolean]
        $IsDataDigest,

        [Parameter()]
        [System.Boolean]
        $IsHeaderDigest,

        [Parameter()]
        [System.Boolean]
        $IsMultipathEnabled,

        [Parameter()]
        [System.Boolean]
        $IsPersistent,

        [Parameter()]
        [System.Boolean]
        $ReportToPNP,

        [Parameter()]
        [System.String]
        $iSNSServer
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.TestingiSCSIInitiatorMessage) `
                -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress
        ) -join '' )

    $targetSplat = @{ TargetPortalAddress = $TargetPortalAddress }
    if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress'))
    {
        $targetSplat += @{ InitiatorPortalAddress = $InitiatorPortalAddress }
    }

    # Lookup the existing iSCSI Target Portal
    $targetPortal = Get-TargetPortal @TargetSplat

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject -Class MSiSCSIInitiator_iSNSServerClass -Namespace root\wmi

    $returnValue += @{ iSNSServer = $iSNSServerCurrent.iSNSServerAddress }

    if ($Ensure -eq 'Present')
    {
        # The iSCSI Target Portal should exist
        if ($targetPortal)
        {
            # The iSCSI Target Portal exists already - check the parameters
            if (($TargetPortalPortNumber) -and ($targetPortal.TargetPortalPortNumber -ne $TargetPortalPortNumber))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'TargetPortal', 'TargetPortalPortNumber'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($InitiatorInstanceName) -and ($targetPortal.InitiatorInstanceName -ne $InitiatorInstanceName))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'TargetPortal', 'InitiatorInstanceName'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsDataDigest) -and ($targetPortal.IsDataDigest -ne $IsDataDigest))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'TargetPortal', 'IsDataDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsHeaderDigest) -and ($targetPortal.IsHeaderDigest -ne $IsHeaderDigest))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'TargetPortal', 'IsHeaderDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            # Lookup the Target
            $target = Get-Target -NodeAddress $NodeAddress

            if (! $target)
            {
                # Ths iSCSI Target doesn't exist but should
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSITargetDoesNotExistButShouldMessage) `
                            -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
                return $desiredConfigurationMatch
            } # if

            if (-not $target.IsConnected)
            {
                # Ths iSCSI Target exists but is not connected
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSITargetNotConnectedMessage) `
                            -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
                return $desiredConfigurationMatch
            } # if

            # Lookup the Connection, with the target and initiator address as a filter to allow multiple session
            if ($InitiatorPortalAddress -and $TargetPortalAddress)
            {
                $connection = Get-Connection -Target $target | Where-Object { $_.initiatoraddress -eq $initiatorportaladdress -and $_.targetaddress -eq $TargetPortalAddress }
            }
            else
            {
                $connection = Get-Connection -Target $target
            }

            if (-not $connection)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIConnectionDoesNotExistButShouldMessage) `
                            -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
                return $desiredConfigurationMatch
            } # if

            <#
                Check the Connection parameters are correct
                The Connection.TargetAddress will always be an IP Address
                even if the TargetPortalAddress was specified as a Hostname
                !! adaptation add multiple session
            #>
            try
            {
                $targetPortalIP = @(
                        ([System.Net.IPAddress]$TargetPortalAddress).IPAddressToString
                )
            }
            catch
            {
                # This is a TargetPortalAddress is a Hostname so resolve it to IP addresses
                $targetPortalIP = @(
                        (Resolve-DNSName -Name $TargetPortalAddress -Type A).IPAddress
                )
            } # try

            if ($targetPortalIP -notin $connection.TargetAddress)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Connection', 'TargetAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress') -and ($InitiatorPortalAddress -notin $connection.InitiatorAddress))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Connection', 'InitiatorAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($TargetPortalPortNumber) -and ($TargetPortalPortNumber -notin $connection.TargetPortNumber))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Connection', 'TargetPortNumber'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            # Lookup the Session
            $session = Get-Session -Target $target

            if (-not $session)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSISessionDoesNotExistButShouldMessage) `
                            -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
                return $desiredConfigurationMatch
            } # if

            # Check the Session parameters are correct
            if (($AuthenticationType) -and ($AuthenticationType -notin $session.AuthenticationType))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'AuthenticationType'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($InitiatorInstanceName) -and ($InitiatorInstanceName -notin $session.InitiatorInstanceName))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'InitiatorInstanceName'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress') -and ($InitiatorPortalAddress -notin $connection.InitiatorAddress))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'InitiatorAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsDataDigest) -and ($session.IsDataDigest -ne $IsDataDigest))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'IsDataDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsHeaderDigest) -and ($session.IsHeaderDigest -ne $IsHeaderDigest))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'IsHeaderDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsPersistent) -and ($session.IsPersistent -ne $IsPersistent))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'IsPersistent'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if
        }
        else
        {
            # Ths iSCSI Target Portal doesn't exist but should
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSITargetPortalDoesNotExistButShouldMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if

        # Check the iSNS Server setting
        if ($PSBoundParameters.ContainsKey('iSNSServer') -and ($iSNSServerCurrent.iSNSServerAddress -ne $iSNSServer))
        {
            # The iSNS Server is different so needs update
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSNSServerNeedsUpdateMessage) `
                        -f $iSNSServerCurrent.iSNSServerAddress, $iSNSServer
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    }
    else
    {
        # Lookup the Target
        $target = Get-Target -NodeAddress $NodeAddress

        if ($target.IsConnected)
        {
            #lookup the session for this target and remove it
            if ($InitiatorPortalAddress -and $TargetPortalAddress)
            {
                $connection = Get-Connection -Target $target | Where-Object { $_.initiatoraddress -eq $initiatorportaladdress -and $_.targetaddress -eq $TargetPortalAddress }
            }
            else
            {
                $connection = Get-Connection -Target $target
            }
            if ($connection)
            {
                # The iSCSI Target exists and is connected
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.iSCSITargetExistsButShouldNotMessage) `
                            -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
        } # if

        # The iSCSI Target Portal should not exist
        if ($targetPortal)
        {
            # The iSCSI Target Portal exists but should not
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSITargetPortalExistsButShouldNotMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The iSCSI Target Portal does not exist and should not
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSCSITargetPortalDoesNotExistAndShouldNotMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
                ) -join '' )
        } # if

        # Check the iSNS Server setting
        if ($iSNSServerCurrent)
        {
            # The iSNS Server is set but should not be
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.iSNSServerIsSetButShouldNotBeMessage)
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource

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

Export-ModuleMember -function *-TargetResource
