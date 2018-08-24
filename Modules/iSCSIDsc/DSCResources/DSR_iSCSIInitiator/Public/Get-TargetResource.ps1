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
            $($LocalizedData.GettingiSCSIInitiatorMessage) `
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
                $($LocalizedData.iSCSITargetPortalExistsMessage) `
                    -f $TargetPortalAddress, $InitiatorPortalAddress
            ) -join '' )
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.iSCSITargetPortalDoesNotExistMessage) `
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
    $iSNSServerCurrent = Get-CimInstance `
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
