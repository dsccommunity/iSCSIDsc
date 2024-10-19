<#
    .SYNOPSIS
        Tests if the current machine is a Nano server.
#>
function Test-IsNanoServer
{
    if (Test-Command -Name Get-ComputerInfo)
    {
        $computerInfo = Get-ComputerInfo

        if ("Server" -eq $computerInfo.OsProductType `
            -and "NanoServer" -eq $computerInfo.OsServerLevel)
        {
            return $true
        }
    }

    return $false
}

<#
    .SYNOPSIS
        Tests if the the specified command is found.
#>
function Test-Command
{
    param
    (
        [Parameter()]
        [String]
        $Name
    )

    return ($null -ne (Get-Command -Name $Name -ErrorAction Continue 2> $null))
}

<#
    .SYNOPSIS
        Creates and throws an invalid argument exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function New-InvalidArgumentException
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
    $errorRecord = New-Object @newObjectParams

    throw $errorRecord
}

<#
    .SYNOPSIS
        Creates and throws an invalid operation exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function New-InvalidOperationException
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
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
    $errorRecordToThrow = New-Object @newObjectParams
    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.

        For example:
            For WindowsOptionalFeature: DSR_xWindowsOptionalFeature
            For Service: DSR_xServiceResource
            For Registry: DSR_xRegistryResource

    .PARAMETER ResourcePath
        The path the resource file is located in.
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourcePath
    )

    $localizedStringFileLocation = Join-Path -Path $ResourcePath -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $ResourcePath -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}
function Get-ISCSIPersistentTarget() {
    # This functions uses iscsli to get a persistent target based on the targetporalIP, targetportnumber & the targetnodeaddres. 
    # The result is returned as a hashtable with as key the targetportalip_nodeaddress = $hashofiscslipersistenttarget info
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")]
        [String]$targetPortalIpAddress,
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^\d{4}$")]
        [int]$targetPortNumber,
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^iqn\.(\d{4}-\d{2})\.([a-zA-Z0-9]+\.[a-zA-Z0-9]+):([a-zA-Z0-9\.]+)$")]
        [String]$targetNodeAddress
    )
    #escape the . character in the ip address
    $escapedIP = $targetPortalIpAddress -replace '\.', '\.'
    #query iscscli for persistent targets
    $iscsi = "iscsicli listpersistenttargets | Select-String -Pattern `"\s*Address and Socket\s*:\s*($escapedIP)\s+(\d+)`" -Context 1, 10"
    $search = invoke-expression $iscsi
    $return = @{}
    foreach ($matchObject in $search) {
        $blob = ($matchObject[0].Context.PreContext + $matchObject[0].Line.TrimStart('--') + $matchObject[0].Context.PostContext) -join "`n" | out-string
        # Convert $blob to hashtable
        $hashtable = @{}
        $lines = $blob -split "`n"
        foreach ($line in $lines) {
            if ($line -match ':') {
                $parts = $line.Split(':', 2)
                if ($parts[1].Trim() -ne '') {
                    $hashtable[$parts[0].Trim()] = $parts[1].Trim()
                }
            }
        }
        [String]$key = "$targetPortalIpAddress`_$($hashtable.'Target Name')"
        if ($targetNodeAddress -eq $hashtable.'Target Name') { $return[$key] = $hashtable }
    }
    return $return
}

function Remove-ISCSIPersistentTarget() {
    # This function will remove the persistent iscsi targets based on targetporalIP, targetportnumber & the targetnodeaddres.
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")]
        [String]$targetPortalIpAddress,
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^\d{4}$")]
        [int]$targetPortNumber,
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^iqn\.(\d{4}-\d{2})\.([a-zA-Z0-9]+\.[a-zA-Z0-9]+):([a-zA-Z0-9\.]+)$")]
        [String]$targetNodeAddress
    )
    #build the iscsicli command
    $peristentTargetSearch = get-iSCSIPersistentTarget -targetPortalIpAddress $targetPortalIpAddress -targetPortNumber $targetPortNumber -targetNodeAddress $targetNodeAddress
    foreach ($result in $peristentTargetSearch) {
        $result.value
        $iscsi = "iscsicli removepersistenttarget $($result.values.'Initiator Name') $($result.values.'Target Name') $($result.values.'Port Number') $($result.values.'Address and Socket')"
        write-verbose "iscsicli command == $iscsi"
        invoke-expression $iscsi
    }
}

function Get-ISCSICLIListSessions() {
    # This functions uses iscsli to get a persistent target based on the targetporalIP, targetportnumber & the targetnodeaddres. 
    # The result is returned as a hashtable with as key the targetportalip_nodeaddress = $hashofiscslipersistenttarget info
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")]
        [String]$targetPortalIpAddress,
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^\d{4}$")]
        [int]$targetPortNumber,
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^iqn\.(\d{4}-\d{2})\.([a-zA-Z0-9]+\.[a-zA-Z0-9]+):([a-zA-Z0-9\.]+)$")]
        [String]$targetNodeAddress,
        [Parameter(Mandatory = $false)]
        [ValidatePattern("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")]
        [String]$initiatorPortalIpAddress
    )
    #escape the . character in the ip address
    $escapedTargetIP = $targetPortalIpAddress -replace '\.', '\.'
    #query iscscli for persistent targets
    $iscsi = "iscsicli sessionlist | Select-String -Pattern `"\s*Target\sPortal\s*:\s*($escapedTargetIP)\/($targetPortNumber)`" -Context 12, 1"
    $search = invoke-expression $iscsi
    $return = @{}
    foreach ($matchObject in $search) {
        $blob = ($matchObject[0].Context.PreContext + $matchObject[0].Line.TrimStart('--') + $matchObject[0].Context.PostContext) -join "`n" | out-string
        # Convert $blob to hashtable
        $hashtable = @{}
        $lines = $blob -split "`n"
        foreach ($line in $lines) {
            if ($line -match ':') {
                $parts = $line.Split(':', 2)
                if ($parts[1].Trim() -ne '') {
                    $hashtable[$parts[0].Trim()] = $parts[1].Trim()
                }
            }
        }
        if ($targetNodeAddress -eq $hashtable.'Target Name' -and $hashtable.'Initiator Portal' -match "$initiatorPortalIpAddress\/\d+" ) {
            $hashtable['initiatorPortalIpAddress']= $initiatorPortalIpAddress
            $hashtable['targetPortalIpAddress']   = $targetPortalIpAddress
            [String]$key                          = "$targetPortalIpAddress`_$($hashtable.'Target Name')"
            $return[$key]                         = $hashtable 
        }
    }
    return $return
}

Export-ModuleMember -Function @(
    'Test-IsNanoServer',
    'New-InvalidArgumentException',
    'New-InvalidOperationException',
    'Get-LocalizedData',
    'Get-ISCSIPersistentTarget',
    'Remove-ISCSIPersistentTarget',
    'Get-ISCSICLIListSessions'
)
