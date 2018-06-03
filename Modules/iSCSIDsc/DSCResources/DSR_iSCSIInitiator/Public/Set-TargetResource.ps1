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
            $($LocalizedData.SettingiSCSIInitiatorMessage) `
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
    $iSNSServerCurrent = Get-WmiObject `
        -Class MSiSCSIInitiator_iSNSServerClass `
        -Namespace root\wmi

    $returnValue += @{
        iSNSServer = $iSNSServerCurrent.iSNSServerAddress
    }

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.EnsureiSCSITargetPortalExistsMessage) `
                    -f $TargetPortalAddress, $InitiatorPortalAddress
            ) -join '' )

        [Boolean] $create = $false

        if ($targetPortal)
        {
            # The iSCSI Target Portal exists - check the parameters
            if (($TargetPortalPortNumber) `
                    -and ($targetPortal.TargetPortalPortNumber -ne $TargetPortalPortNumber))
            {
                $create = $true
            } # if
            if (($InitiatorInstanceName) `
                    -and ($targetPortal.InitiatorInstanceName -ne $InitiatorInstanceName))
            {
                $create = $true
            } # if
            if (($null -ne $IsDataDigest) `
                    -and ($targetPortal.IsDataDigest -ne $IsDataDigest))
            {
                $create = $true
            } # if
            if (($null -ne $IsHeaderDigest) `
                    -and ($targetPortal.IsHeaderDigest -ne $IsHeaderDigest))
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
                        $($LocalizedData.iSCSITargetPortalRemovedForRecreateMessage) `
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
                    $($LocalizedData.iSCSITargetPortalCreatedMessage) `
                        -f $TargetPortalAddress, $InitiatorPortalAddress
                ) -join '' )
        }

        # Lookup the Target
        $target = Get-Target `
            -NodeAddress $NodeAddress

        # Check the Target is connected
        [Boolean] $connect = $false

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.EnsureiSCSITargetIsConnectedMessage) `
                    -f $NodeAddress
            ) -join '' )

        if ($target)
        {
            # Lookup the Connection
            $connection = Get-Connection `
                -Target $target

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

                if ($connection.TargetAddress -notin $targetPortalIP)
                {
                    $connect = $true
                } # if
                if ($connection.InitiatorAddress -ne $InitiatorPortalAddress)
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
                        -and ($session.InitiatorPortalAddress -ne $InitiatorPortalAddress))
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

                if ($connect)
                {
                    # The Target/Session/Connection has different parameters
                    # So disconnect everything so it can be reconnected
                    Disconnect-IscsiTarget `
                        -NodeAddress $NodeAddress `
                        -Confirm:$False `
                        -ErrorAction Stop

                    Write-Verbose -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($LocalizedData.iSCSITargetDisconnectedMessage) `
                                -f $NodeAddress
                        ) -join '' )

                } # if
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
            $splat.Remove('IsMultipathEnabled')
            $splat.Remove('iSNSServer')

            $Session = Connect-IscsiTarget `
                @splat `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSITargetConnectedMessage) `
                        -f $NodeAddress
                ) -join '' )
        } # if

        if (($PSBoundParameters.ContainsKey('IsPersistent')) `
                -and ($IsPersistent -ne $session.IsPersistent))
        {
            if ($IsPersistent -eq $true)
            {
                # Ensure session is persistent
                $session | Register-IscsiSession `
                    -IsMultipathEnabled $IsMultipathEnabled `
                    -ErrorAction Stop

                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSISessionSetPersistentMessage) `
                            -f $NodeAddress
                    ) -join '' )
            }
            else
            {
                # Ensure session is not persistent
                $session | Unregister-IscsiSession `
                    -ErrorAction Stop

                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSISessionRemovedPersistentMessage) `
                            -f $NodeAddress
                    ) -join '' )
            }
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
                        -Arguments @{ServerName = $iSNSServer} `
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
                $($LocalizedData.EnsureiSCSITargetIsDisconnectedMessage) `
                    -f $NodeAddress
            ) -join '' )

        # Lookup the Target
        $target = Get-Target `
            -NodeAddress $NodeAddress

        if ($target)
        {
            if ($target.IsConnected)
            {
                Disconnect-IscsiTarget `
                    -NodeAddress $NodeAddress `
                    -Confirm:$false `
                    -ErrorAction Stop

                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($LocalizedData.iSCSITargetDisconnectedMessage) `
                            -f $NodeAddress
                    ) -join '' )
            }
        }

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.EnsureiSCSITargetPortalDoesNotExistMessage) `
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
                    $($LocalizedData.iSCSITargetPortalRemovedMessage) `
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
                    $($LocalizedData.iSCSIServerTargetiSNSRemovedMessage) `
                        -f $TargetName
                ) -join '' )
        } # if
    } # if
} # Set-TargetResource