<#PSScriptInfo
.VERSION 1.0.0
.GUID b5db6465-b609-4e35-b7aa-ddc62efc8553
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/iSCSIDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/iSCSIDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module iSCSIDsc

<#
    .DESCRIPTION
    This example starts the MSiSCSI service on a cluster node and then configures an iSCSI Target
    Portal and then connects to the iSCSI Target.
#>
Configuration iSCSIInitiator_ConfigureTargetPortal_Config
{
    Import-DscResource -Module iSCSIDSc

    Node localhost
    {
        Service iSCSIService
        {
            Name        = 'MSiSCSI'
            StartupType = 'Automatic'
            State       = 'Running'
        }

        iSCSIInitiator iSCSIInitiator
        {
            Ensure                 = 'Present'
            NodeAddress            = 'iqn.1991-05.com.microsoft:fileserver01-cluster-target'
            TargetPortalAddress    = '192.168.128.10'
            InitiatorPortalAddress = '192.168.128.20'
            IsPersistent           = $true
            iSNSServer             = 'isns.contoso.com'
            DependsOn              = "[Service]iSCSIService"
        } # End of iSCSIInitiator Resource
    } # End of Node
} # End of Configuration


<#
    A more complex example of a situation where multiple targets need to be defined per target
#>
# Provided a hastable of nodeaddressess containing iscsi session with multiple targets.
$iscsi_hh_target = @{
    'iqn.2009-01.com.ANYIQN:storageBox.k2.33555' =  @{                  # The key is the IQN, will be the nodeaddress name
        iscsi_sessions = @{                                             # iscsi_sessions hashtable contains all the sessions for a Target, key == initiator ip, value == array of target ip's
            '192.168.1.2' = @(                                          # String value, has to be an ip address
                '192.168.1.3',                                          # String value, has to be an ip address
                '192.168.1.4'                                           # String value, has to be an ip address
            );                                              
            '192.168.2.2' = @(                                          # String value, has to be an ip address
                '192.168.2.3',                                          # String value, has to be an ip address
                '192.168.2.4'                                           # String value, has to be an ip address
            );
        };
        properties = @{                                                  # these are the properties applied to each session (1 target needs to have the same config options for sessions)
            ensure                 = 'Present';                              # defines the state of a session 'Present' or 'Absent'
            initiatornodeaddress   = "iqn.1991-05.com.microsoft:%{fqdn}";    # this can be a custom value but for uniformity let's use this value.
            isdatadigest           = $True;                                  # Boolean value
            isheaderdigest         = $True;                                  # Boolean value
            targetportalportnumber = 3260;                                   # Int value representing the port number for the target ip
            authenticationtype     = 'None';                                 # String value has to be one of 'None', 'OneWayCHAP', 'MutualCHAP'
            ismultipathenabled     = $True;                                  # Boolean value
            ispersistent           = $True;                                  # Boolean value
        }
    };
}
#foreach ($nodeaddress in $iscsi_hh_target.Keys ){ foreach($iscsi_sessions in $iscsi_hh_target["$nodeaddress"].iscsi_sessions){ foreach($target in $iscsi_sessions) { $target } }   }
foreach ($nodeaddress in $iscsi_hh_target.Keys ){                       # we need to loop over each nodeaddress, in case there are multiple
    foreach($initiator in $iscsi_hh_target["$nodeaddress"].iscsi_sessions.keys){   # we need to loop over the sessions defined to get to each target seperately
        foreach($target in $iscsi_hh_target["$nodeaddress"].iscsi_sessions["$initiator"]) {   
            Configuration iSCSIInitiator_ConfigureTargetPortal_Config
            {
                Import-DscResource -Module iSCSIDSc

                Node localhost
                {                          # we need to loop over the targets so we can define the multiple targets for one session
                    iSCSIInitiator iSCSIInitiator
                    {
                        Ensure                 = $iscsi_hh_target["$nodeaddress"].properties.ensure,
                        TargetPortalAddress    = $target,
                        InitiatorPortalAddress = $initiator,
                        InitiatorNodeAddress   = $iscsi_hh_target["$nodeaddress"].properties.initiatornodeaddress,
                        TargetNodeAddress      = $target,
                        NodeAddress            = $nodeaddress,
                        IsDataDigest           = $iscsi_hh_target["$nodeaddress"].properties.isdatadigest,
                        IsHeaderDigest         = $iscsi_hh_target["$nodeaddress"].properties.isheaderdigest,
                        TargetPortalPortNumber = $iscsi_hh_target["$nodeaddress"].properties.targetportalportnumber,
                        AuthenticationType     = $iscsi_hh_target["$nodeaddress"].properties.authenticationtype,
                        IsMultipathEnabled     = $iscsi_hh_target["$nodeaddress"].properties.ismultipathenabled,
                        IsPersistent           = $iscsi_hh_target["$nodeaddress"].properties.ispersistent;
                        DependsOn              = "[Service]iSCSIService"
                    }
                }
            }
        }
    }
}


