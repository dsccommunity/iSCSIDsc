# Description

This resource is used to add or remove an iSCSI Target Portal and connect it to
an iSCSI Target.

## Example

An example of an iscsi target defined with multiple sessions:

In hiera, exmaple of an iscsi target definition with multiple sessions:

```yaml
iscsi_hh_target:
  'iqn.2009-01.com.ANYIQN:storageBox.k2.33555':                        # This is the IQN, will be the nodeaddress name
      iscsi_sessions:                                                  # this hashtable contains all the sessions for a Target, key == initiator ip, value == array of target ip's
        '192.168.1.2':                                                 # String value, has to be an ip address
          - '192.168.1.2'                                              # String value, has to be an ip address
          - '192.168.1.3'                                              # String value, has to be an ip address
        '192.168.2.2':                                                 # String value, has to be an ip address
          - '192.168.2.2'                                              # String value, has to be an ip address
          - '192.168.2.3'                                              # String value, has to be an ip address
      properties:                                                      # these are the properties applied to each session (1 target needs to have the same config options for sessions)
        ensure                 : 'Present'                             # defines the state of a session 'Present' or 'Absent'
        initiatornodeaddress   : "iqn.1991-05.com.microsoft:%{fqdn}"   # this can be a custom value but for uniformity let's use this value.
        isdatadigest           : true                                  # Boolean value
        isheaderdigest         : true                                  # Boolean value
        targetportalportnumber : 3260                                  # Int value representing the port number for the target ip
        authenticationtype     : 'None'                                # String value has to be one of 'None', 'OneWayCHAP', 'MutualCHAP'
        ismultipathenabled     : true                                  # Boolean value
        ispersistent           : true                                  # Boolean value

```

Definition in the puppet module manifest to add the target with it's sessions:

```ruby
$iscsi_hh_target = lookup('iscsi_hh_target', {value_type => Hash, default_value => {}})
$iscsi_hh_target.each | String $nodeaddress,Hash $initiator_hash | {
          $initiator_hash[iscsi_sessions].each | $initiator, $targets | {
            $targets.each | $target | {
              dsc_iscsiinitiator{ "Initiator ${initiator}, target ${target}":
                dsc_ensure                 => $initiator_hash[properties][ensure],
                dsc_targetportaladdress    => $target,
                dsc_initiatorportaladdress => $initiator,
                dsc_initiatornodeaddress   => $initiator_hash[properties][initiatornodeaddress],
                dsc_targetnodeaddress      => $target,
                dsc_nodeaddress            => $nodeaddress,
                dsc_isdatadigest           => $initiator_hash[properties][isdatadigest],
                dsc_isheaderdigest         => $initiator_hash[properties][isheaderdigest],
                dsc_targetportalportnumber => $initiator_hash[properties][targetportalportnumber],
                dsc_authenticationtype     => $initiator_hash[properties][authenticationtype],
                dsc_ismultipathenabled     => $initiator_hash[properties][ismultipathenabled],
                dsc_ispersistent           => $initiator_hash[properties][ispersistent];
            }
        }
    }
}
```
