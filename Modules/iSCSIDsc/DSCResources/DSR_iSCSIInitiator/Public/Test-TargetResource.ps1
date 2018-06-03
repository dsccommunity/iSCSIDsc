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
            $($LocalizedData.TestingiSCSIInitiatorMessage) `
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
    $iSNSServerCurrent = Get-CimInstance `
        -Class MSiSCSIInitiator_iSNSServerClass `
        -Namespace root\wmi

    $returnValue += @{
        iSNSServer = $iSNSServerCurrent.iSNSServerAddress
    }

    if ($Ensure -eq 'Present')
    {
        # The iSCSI Target Portal should exist
        if ($targetPortal)
        {
            # The iSCSI Target Portal exists already - check the parameters
            if (($TargetPortalPortNumber) `
                    -and ($targetPortal.TargetPortalPortNumber -ne $TargetPortalPortNumber))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'TargetPortal', 'TargetPortalPortNumber'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($InitiatorInstanceName) `
                    -and ($targetPortal.InitiatorInstanceName -ne $InitiatorInstanceName))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'TargetPortal', 'InitiatorInstanceName'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsDataDigest) `
                    -and ($targetPortal.IsDataDigest -ne $IsDataDigest))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'TargetPortal', 'IsDataDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsHeaderDigest) `
                    -and ($targetPortal.IsHeaderDigest -ne $IsHeaderDigest))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'TargetPortal', 'IsHeaderDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            # Lookup the Target
            $target = Get-Target `
                -NodeAddress $NodeAddress

            if (! $target)
            {
                # Ths iSCSI Target doesn't exist but should
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSITargetDoesNotExistButShouldMessage) `
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
                        $($LocalizedData.iSCSITargetNotConnectedMessage) `
                            -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
                return $desiredConfigurationMatch
            } # if

            # Lookup the Connection
            $connection = Get-Connection `
                -Target $target

            if (-not $connection)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIConnectionDoesNotExistButShouldMessage) `
                            -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
                return $desiredConfigurationMatch
            } # if

            <#
                Check the Connection parameters are correct
                The Connection.TargetAddress will always be an IP Address
                even if the TargetPortalAddress was specified as a Hostname
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

            if ($connection.TargetAddress -notin $targetPortalIP)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Connection', 'TargetAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress') `
                    -and ($connection.InitiatorAddress -ne $InitiatorPortalAddress))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Connection', 'InitiatorAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($TargetPortalPortNumber) `
                    -and ($connection.TargetPortNumber -ne $TargetPortalPortNumber))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Connection', 'TargetPortNumber'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            # Lookup the Session
            $session = Get-Session `
                -Target $target

            if (-not $session)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSISessionDoesNotExistButShouldMessage) `
                            -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
                return $desiredConfigurationMatch
            } # if

            # Check the Session parameters are correct
            if (($AuthenticationType) `
                    -and ($session.AuthenticationType -ne $AuthenticationType))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'AuthenticationType'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($InitiatorInstanceName) `
                    -and ($session.InitiatorInstanceName -ne $InitiatorInstanceName))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'InitiatorInstanceName'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress') `
                    -and ($session.InitiatorPortalAddress -ne $InitiatorPortalAddress))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'InitiatorAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsDataDigest) `
                    -and ($session.IsDataDigest -ne $IsDataDigest))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'IsDataDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsHeaderDigest) `
                    -and ($session.IsHeaderDigest -ne $IsHeaderDigest))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                            -f $NodeAddress, $TargetPortalAddress, $InitiatorPortalAddress, 'Session', 'IsHeaderDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($null -ne $IsPersistent) `
                    -and ($session.IsPersistent -ne $IsPersistent))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
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
                    $($LocalizedData.iSCSITargetPortalDoesNotExistButShouldMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if

        # Check the iSNS Server setting
        if ($PSBoundParameters.ContainsKey('iSNSServer') `
                -and ($iSNSServerCurrent.iSNSServerAddress -ne $iSNSServer))
        {
            # The iSNS Server is different so needs update
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSNSServerNeedsUpdateMessage) `
                        -f $iSNSServerCurrent.iSNSServerAddress, $iSNSServer
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    }
    else
    {
        # Lookup the Target
        $target = Get-Target `
            -NodeAddress $NodeAddress

        if ($target.IsConnected)
        {
            # The iSCSI Target exists and is connected
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSITargetExistsButShouldNotMessage) `
                        -f $NodeAddress
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if

        # The iSCSI Target Portal should not exist
        if ($targetPortal)
        {
            # The iSCSI Target Portal exists but should not
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSITargetPortalExistsButShouldNotMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The iSCSI Target Portal does not exist and should not
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSITargetPortalDoesNotExistAndShouldNotMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
                ) -join '' )
        } # if

        # Check the iSNS Server setting
        if ($iSNSServerCurrent)
        {
            # The iSNS Server is set but should not be
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSNSServerIsSetButShouldNotBeMessage)
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource
