data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
GettingiSCSIInitiatorMessage=Getting iSCSI Initiator '{0}', '{1}' from '{2}'.
iSCSITargetPortalExistsMessage=iSCSI Target Portal '{0}' from '{1}' exists.
iSCSITargetPortalDoesNotExistMessage=iSCSI Target Portal '{0}' from '{1}' does not exist.
iSCSITargetExistsMessage=iSCSI Target '{0}' exists.
iSCSITargetDoesNotExistMessage=iSCSI Target '{0}' does not exist.
iSCSIConnectionExistsMessage=iSCSI Connection '{0}' exists.
iSCSIConnectionDoesNotExistMessage=iSCSI Connection '{0}' does not exist.
iSCSISessionExistsMessage=iSCSI Session '{0}' exists.
iSCSISessionDoesNotExistMessage=iSCSI Session '{0}' does not exist.
SettingiSCSIInitiatorMessage=Setting iSCSI Initiator '{0}', '{1}' from '{2}'.
EnsureiSCSITargetPortalExistsMessage=Ensuring iSCSI Target Portal '{0}' from '{1}' exists.
EnsureiSCSITargetPortalDoesNotExistMessage=Ensuring iSCSI Target Portal '{0}' from '{1}' does not exist.
iSCSITargetPortalCreatedMessage=iSCSI Target Portal '{0}' from '{1}' has been created.
iSCSITargetPortalRemovedForRecreateMessage=iSCSI Target Portal '{0}' from '{1}' has been removed so it can be recreated.
iSCSITargetDisconnectedMessage=iSCSI Target '{0}' has been disconnected.
iSCSITargetConnectedMessage=iSCSI Target '{0}' has been connected.
iSCSISessionSetPersistentMessage=iSCSI Session '{0}' is set as persistent.
iSCSISessionRemovedPersistentMessage=iSCSI Session '{0}' is no longer persistent.
iSCSITargetPortalRemovedMessage=iSCSI Target Portal '{0}' from '{1}' has been removed.
EnsureiSCSITargetIsConnectedMessage=Ensuring iSCSI Target '{0}' is connected.
EnsureiSCSITargetIsDisconnectedMessage=Ensuring iSCSI Target '{0}' is disconnected.
iSNSServerRemovedMessage=iSNS Server has been cleared.
iSNSServerUpdatedMessage=iSNS Server has been set to '{0}'.
iSNSServerUpdateErrorMessage=An error occurred setting the iSNS Server to '{0}'. This is usually caused by the iSNS Server not being accessible.
TestingiSCSIInitiatorMessage=Testing iSCSI Initiator '{0}', '{1}' from '{2}'.
iSCSIInitiatorParameterNeedsUpdateMessage=iSCSI {3} '{0}', '{1}' from '{2}' {4} is different. Change required.
iSCSITargetPortalDoesNotExistButShouldMessage=iSCSI Target Portal '{0}' from '{1}' does not exist but should. Change required.
iSCSITargetPortalExistsButShouldNotMessage=iSCSI Target Portal '{0}' from '{1}' exists but should not. Change required.
iSCSITargetExistsButShouldNotMessage=iSCSI Target '{0}' exists but should not. Change required.
iSCSITargetPortalDoesNotExistAndShouldNotMessage=iSCSI Target Portal '{0}' from '{1}' does not exist and should not. Change not required.
iSCSITargetDoesNotExistButShouldMessage=iSCSI Target '{0}' does not exist but should. Change required.
iSCSITargetNotConnectedMessage=iSCSI Target '{0}' exists but is not connected. Change required.
iSCSIConnectionDoesNotExistButShouldMessage=iSCSI Connection '{0}' does not exist but should. Change required.
iSCSISessionDoesNotExistButShouldMessage=iSCSI Session '{0}' does not exist but should. Change required.
iSNSServerNeedsUpdateMessage=iSNS Server is '{0}' but should be '{1}'. Change required.
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
        $NodeAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $TargetPortalAddress,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.String]
        $InitiatorPortalAddress
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingiSCSIInitiatorMessage) `
            -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress
        ) -join '' )

    $returnValue = @{
        NodeAddress                             = $NodeAddress
        TargetPortalAddress                     = $TargetPortalAddress
        InitiatorPortalAddress                  = $InitiatorPortalAddress
        Ensure = 'Absent'
    }

    # Lookup the Target Portal
    $TargetPortal =  Get-TargetPortal `
        -TargetPortalAddress $TargetPortalAddress `
        -InitiatorPortalAddress $InitiatorPortalAddress
    
    if ($TargetPortal)
    {
        $returnValue.TargetPortalAddress        = $TargetPortal.TargetPortalAddress
        $returnValue.InitiatorPortalAddress     = $TargetPortal.InitiatorPortalAddress
        $returnValue.TargetPortalPortNumber     = $TargetPortal.TargetPortalPortNumber
        $returnValue.InitiatorInstanceName      = $TargetPortal.InitiatorInstanceName
        $returnValue.IsDataDigest               = $TargetPortal.IsDataDigest
        $returnValue.IsHeaderDigest             = $TargetPortal.IsHeaderDigest
        
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.iSCSITargetPortalExistsMessage) `
                -f $TargetPortalAddress,$InitiatorPortalAddress
            ) -join '' )
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.iSCSITargetPortalDoesNotExistMessage) `
                -f $TargetPortalAddress,$InitiatorPortalAddress
            ) -join '' )
    } # if

    # Lookup the Target
    $Target = Get-Target `
        -NodeAddress $NodeAddress

    if ($Target)
    {
        $returnValue.NodeAddress                = $Target.NodeAddress
        $returnValue.IsConnected                = $Target.IsConnected
        
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.iSCSITargetExistsMessage) `
                -f $NodeAddress
            ) -join '' )
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.iSCSITargetDoesNotExistMessage) `
                -f $NodeAddress
            ) -join '' )
    } # if

    # The rest of the properties can only be populated if the Target is connected.
    if ($Target.IsConnected)
    {
        # Lookup the Connection
        $Connection = Get-Connection `
            -Target $Target

        $returnValue.Ensure                 = 'Present'

        if ($Connection)
        {
            $returnValue.TargetPortalAddress    = $Connection.TargetAddress
            $returnValue.InitiatorPortalAddress = $Connection.InitiatorAddress
            $returnValue.TargetPortalPortNumber = $Connection.TargetPortNumber
            $returnValue.ConnectionIdentifier   = $Connection.ConnectionIdentifier

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSIConnectionExistsMessage) `
                    -f $NodeAddress
                ) -join '' )
        }
        else
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSIConnectionDoesNotExistMessage) `
                    -f $NodeAddress
                ) -join '' )
        } # if

        # Lookup the Session
        $Session = Get-Session `
            -Target $Target

        if ($Session)
        {
            $returnValue.AuthenticationType     = $Session.AuthenticationType
            $returnValue.InitiatorInstanceName  = $Session.InitiatorInstanceName
            $returnValue.InitiatorPortalAddress = $Session.InitiatorPortalAddress
            $returnValue.IsConnected            = $Session.IsConnected
            $returnValue.IsDataDigest           = $Session.IsDataDigest
            $returnValue.IsDiscovered           = $Session.IsDiscovered
            $returnValue.IsHeaderDigest         = $Session.IsHeaderDigest
            $returnValue.IsPersistent           = $Session.IsPersistent
            $returnValue.SessionIdentifier      = $Session.SessionIdentifier

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSISessionExistsMessage) `
                    -f $NodeAddress
                ) -join '' )
        }
        else
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSISessionDoesNotExistMessage) `
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
    
    $returnValue
} # Get-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $NodeAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $TargetPortalAddress,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.String]
        $InitiatorPortalAddress,

        [System.Uint16]
        $TargetPortalPortNumber,

        [System.String]
        $InitiatorInstanceName,

        [ValidateSet('None','OneWayCHAP','MutualCHAP')]
        [System.String]
        $AuthenticationType,

        [System.String]
        $ChapUsername,

        [System.String]
        $ChapSecret,

        [System.Boolean]
        $IsDataDigest,

        [System.Boolean]
        $IsHeaderDigest,

        [System.Boolean]
        $IsMultipathEnabled,

        [System.Boolean]
        $IsPersistent,

        [System.Boolean]
        $ReportToPNP,

        [System.String]
        $iSNSServer
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.SettingiSCSIInitiatorMessage) `
            -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress
        ) -join '' )

    # Remove any parameters that can't be splatted.
    $null = $PSBoundParameters.Remove('Ensure')

    $TargetSplat = @{ TargetPortalAddress = $TargetPortalAddress }
    if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress'))
    {
        $TargetSplat += @{ InitiatorPortalAddress = $InitiatorPortalAddress }
    }

    # Lookup the existing iSCSI Target Portal
    $TargetPortal = Get-TargetPortal @TargetSplat

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
                -f $TargetPortalAddress,$InitiatorPortalAddress
            ) -join '' )

        [Boolean] $create = $false

        if ($TargetPortal)
        {
            # The iSCSI Target Portal exists - check the parameters
            if (($TargetPortalPortNumber) `
                -and ($TargetPortal.TargetPortalPortNumber -ne $TargetPortalPortNumber))
            {
                $create = $true
            } # if
            if (($InitiatorInstanceName) `
                -and ($TargetPortal.InitiatorInstanceName -ne $InitiatorInstanceName))
            {
                $create = $true
            } # if
            if (($IsDataDigest -ne $null) `
                -and ($TargetPortal.IsDataDigest -ne $IsDataDigest))
            {
                $create = $true
            } # if
            if (($IsHeaderDigest -ne $null) `
                -and ($TargetPortal.IsHeaderDigest -ne $IsHeaderDigest))
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
                        -f $TargetPortalAddress,$InitiatorPortalAddress
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
            [PSObject] $Splat = [PSObject]@{} + $PSBoundParameters
            $Splat.Remove('NodeAddress')
            $Splat.Remove('IsMultipathEnabled')
            $Splat.Remove('IsPersistent')
            $Splat.Remove('ReportToPNP')
            $Splat.Remove('iSNSServer')
            New-iSCSITargetPortal `
                @Splat `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSITargetPortalCreatedMessage) `
                    -f $TargetPortalAddress,$InitiatorPortalAddress
                ) -join '' )
        }

        # Lookup the Target
        $Target = Get-Target `
            -NodeAddress $NodeAddress

        # Check the Target is connected
        [Boolean] $connect = $false

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureiSCSITargetIsConnectedMessage) `
                -f $NodeAddress
            ) -join '' )

        if ($Target)
        {
            # Lookup the Connection
            $Connection = Get-Connection `
                -Target $Target

            # Lookup the Session
            $Session = Get-Session `
                -Target $Target

            if ($Connection -and $Session)
            {
                # Check that the session and connection parameters are correct

                # The Connection.TargetAddress will always be an IP Address
                # even if the TargetPortalAddress was specified as a Hostname
                try
                {
                    $TargetPortalIP = @(
                        ([System.Net.IPAddress]$TargetPortalAddress).IPAddressToString
                    )
                }
                catch
                {
                    # This is a TargetPortalAddress is a Hostname so resolve it to IP addresses
                    $TargetPortalIP = @(
                        (Resolve-DNSName -Name $TargetPortalAddress -Type A).IPAddress
                    )
                } # try

                if ($Connection.TargetAddress -notin $TargetPortalIP)
                {
                    $connect = $true
                } # if
                if ($Connection.InitiatorAddress -ne $InitiatorPortalAddress)
                {
                    $connect = $true
                } # if
                if (($TargetPortalPortNumber) `
                    -and ($Connection.TargetPortNumber -ne $TargetPortalPortNumber))
                {
                    $connect = $true
                } # if
                if (($AuthenticationType) `
                    -and ($Session.AuthenticationType -ne $AuthenticationType))
                {
                    $connect = $true
                } # if
                if (($InitiatorInstanceName) `
                    -and ($Session.InitiatorInstanceName -ne $InitiatorInstanceName))
                {
                    $connect = $true
                } # if
                if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress') `
                     -and ($Session.InitiatorPortalAddress -ne $InitiatorPortalAddress))
                {
                    $connect = $true
                } # if
                if (($IsDataDigest -ne $null) `
                    -and ($Session.IsDataDigest -ne $IsDataDigest))
                {
                    $connect = $true
                } # if
                if (($IsHeaderDigest -ne $null) `
                    -and ($Session.IsHeaderDigest -ne $IsHeaderDigest))
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
            [PSObject] $Splat = [PSObject]@{} + $PSBoundParameters
            $Splat.Remove('IsMultipathEnabled')
            $Splat.Remove('iSNSServer')
            
            $Session = Connect-IscsiTarget `
                @Splat `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSITargetConnectedMessage) `
                    -f $NodeAddress
                ) -join '' )
        } # if

        if (($PSBoundParameters.ContainsKey('IsPersistent')) `
            -and ($IsPersistent -ne $Session.IsPersistent))
        {
            if ($IsPersistent -eq $true)
            {
                # Ensure session is persistent
                $Session | Register-IscsiSession `
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
                $Session | Unregister-IscsiSession `
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
            $($LocalizedData.EnsureiSCSITargetIsDisconnectedMessage) `
                -f $NodeAddress
            ) -join '' )

        # Lookup the Target
        $Target = Get-Target `
            -NodeAddress $NodeAddress

        if ($Target)
        {
            if ($Target.IsConnected)
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
                -f $TargetPortalAddress,$InitiatorPortalAddress
            ) -join '' )

        if ($TargetPortal)
        {
            # The iSCSI Target Portal shouldn't exist - remove it
            Remove-iSCSITargetPortal `
                @TargetSplat `
                -Confirm:$False `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSITargetPortalRemovedMessage) `
                    -f $TargetPortalAddress,$InitiatorPortalAddress
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

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $NodeAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $TargetPortalAddress,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.String]
        $InitiatorPortalAddress,

        [System.Uint16]
        $TargetPortalPortNumber,

        [System.String]
        $InitiatorInstanceName,

        [ValidateSet('None','OneWayCHAP','MutualCHAP')]
        [System.String]
        $AuthenticationType,

        [System.String]
        $ChapUsername,

        [System.String]
        $ChapSecret,

        [System.Boolean]
        $IsDataDigest,

        [System.Boolean]
        $IsHeaderDigest,

        [System.Boolean]
        $IsMultipathEnabled,

        [System.Boolean]
        $IsPersistent,

        [System.Boolean]
        $ReportToPNP,

        [System.String]
        $iSNSServer
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.TestingiSCSIInitiatorMessage) `
            -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress
        ) -join '' )

    $TargetSplat = @{ TargetPortalAddress = $TargetPortalAddress }
    if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress'))
    {
        $TargetSplat += @{ InitiatorPortalAddress = $InitiatorPortalAddress }
    }

    # Lookup the existing iSCSI Target Portal
    $TargetPortal = Get-TargetPortal @TargetSplat

    # Get the iSNS Server
    $iSNSServerCurrent = Get-WmiObject `
        -Class MSiSCSIInitiator_iSNSServerClass `
        -Namespace root\wmi
    $returnValue += @{
        iSNSServer = $iSNSServerCurrent.iSNSServerAddress
    }

    if ($Ensure -eq 'Present')
    {
        # The iSCSI Target Portal should exist
        if ($TargetPortal)
        {
            # The iSCSI Target Portal exists already - check the parameters
            if (($TargetPortalPortNumber) `
                -and ($TargetPortal.TargetPortalPortNumber -ne $TargetPortalPortNumber))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'TargetPortal','TargetPortalPortNumber'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($InitiatorInstanceName) `
                -and ($TargetPortal.InitiatorInstanceName -ne $InitiatorInstanceName))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'TargetPortal','InitiatorInstanceName'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($IsDataDigest -ne $null) `
                -and ($TargetPortal.IsDataDigest -ne $IsDataDigest))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'TargetPortal','IsDataDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($IsHeaderDigest -ne $null) `
                -and ($TargetPortal.IsHeaderDigest -ne $IsHeaderDigest))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'TargetPortal','IsHeaderDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            # Lookup the Target
            $Target = Get-Target `
                -NodeAddress $NodeAddress

            if (! $Target)
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

            if (-not $Target.IsConnected)
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
            $Connection = Get-Connection `
                -Target $Target

            if (-not $Connection)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIConnectionDoesNotExistButShouldMessage) `
                        -f $NodeAddress
                    ) -join '' )
                $desiredConfigurationMatch = $false
                return $desiredConfigurationMatch
            } # if

            # Check the Connection parameters are correct

            # The Connection.TargetAddress will always be an IP Address
            # even if the TargetPortalAddress was specified as a Hostname
            try
            {
                $TargetPortalIP = @(
                    ([System.Net.IPAddress]$TargetPortalAddress).IPAddressToString
                )
            }
            catch
            {
                # This is a TargetPortalAddress is a Hostname so resolve it to IP addresses
                $TargetPortalIP = @(
                    (Resolve-DNSName -Name $TargetPortalAddress -Type A).IPAddress
                )
            } # try

            if ($Connection.TargetAddress -notin $TargetPortalIP)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Connection','TargetAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress') `
                -and ($Connection.InitiatorAddress -ne $InitiatorPortalAddress))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Connection','InitiatorAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($TargetPortalPortNumber) `
                -and ($Connection.TargetPortNumber -ne $TargetPortalPortNumber))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Connection','TargetPortNumber'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            # Lookup the Session
            $Session = Get-Session `
                -Target $Target

            if (-not $Session)
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
                -and ($Session.AuthenticationType -ne $AuthenticationType))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Session','AuthenticationType'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($InitiatorInstanceName) `
                -and ($Session.InitiatorInstanceName -ne $InitiatorInstanceName))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Session','InitiatorInstanceName'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if ($PSBoundParameters.ContainsKey('InitiatorPortalAddress') `
                -and ($Session.InitiatorPortalAddress -ne $InitiatorPortalAddress))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Session','InitiatorAddress'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($IsDataDigest -ne $null) `
                -and ($Session.IsDataDigest -ne $IsDataDigest))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Session','IsDataDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($IsHeaderDigest -ne $null) `
                -and ($Session.IsHeaderDigest -ne $IsHeaderDigest))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Session','IsHeaderDigest'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            } # if

            if (($IsPersistent -ne $null) `
                -and ($Session.IsPersistent -ne $IsPersistent))
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.iSCSIInitiatorParameterNeedsUpdateMessage) `
                        -f $NodeAddress,$TargetPortalAddress,$InitiatorPortalAddress,'Session','IsPersistent'
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
                    -f $TargetPortalAddress,$InitiatorPortalAddress
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
                    -f $iSNSServerCurrent.iSNSServerAddress,$iSNSServer
                ) -join '' )
            $desiredConfigurationMatch = $false
        } # if
    }
    else
    {
        # Lookup the Target
        $Target = Get-Target `
            -NodeAddress $NodeAddress
            
        if ($Target.IsConnected)
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
        if ($TargetPortal)
        {
            # The iSCSI Target Portal exists but should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.iSCSITargetPortalExistsButShouldNotMessage) `
                    -f $TargetPortalAddress,$InitiatorPortalAddress
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The iSCSI Target Portal does not exist and should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.iSCSITargetPortalDoesNotExistAndShouldNotMessage) `
                    -f $TargetPortalAddress,$InitiatorPortalAddress
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

# Helper Functions

Function Get-TargetPortal
{
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $TargetPortalAddress,
        
        [System.String]
        $InitiatorPortalAddress
    )
    try
    {
        $TargetPortal = Get-iSCSITargetPortal @PSBoundParameters `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $TargetPortal = $null
    }
    catch
    {
        Throw $_
    }
    Return $TargetPortal
} # Get-TargetPortal

Function Get-Target
{
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $NodeAddress
    )
    try
    {
        $Target = Get-iSCSITarget @PSBoundParameters `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $Target = $null
    }
    catch
    {
        Throw $_
    }
    Return $Target
} # Get-Target

Function Get-Session
{
    param
    (
        [parameter(Mandatory = $true)]
        $Target
    )
    try
    {
        $Session = Get-iSCSISession `
            -IscsiTarget $Target `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $Session = $null
    }
    catch
    {
        Throw $_
    }
    Return $Session
} # Get-Session

Function Get-Connection
{
    param
    (
        [parameter(Mandatory = $true)]
        $Target
    )
    try
    {
        $Connection = Get-iSCSIConnection `
            -IscsiTarget $Target `
            -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
        $Connection = $null
    }
    catch
    {
        Throw $_
    }
    Return $Connection
} # Get-Connection

Export-ModuleMember -Function *-TargetResource
