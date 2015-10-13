# This resource is realised on the nagios server. Don't use it
# directly, use monitor::service instead.

# These exported resources are created by the monitor::service type.
# A monitor::service_serverside resource contains attributes to create
# all the related Nagios objects - host, hostgroup, service and
# command - as well as managing a Nagios check script if that's required.

# One of these resources is created for each combination of host and
# service. However we only need - for example - one host object per
# host. We need to create one single host object from all the
# individual service objects. The same applies to commands and
# hostgroups.

# So we use ensure_resource to make sure the host object is created
# only once. The weakness with this is that ensure_resource requires
# the resource to be identical each time it is called. This might not
# be true if you're changing the attributes. We're going to see if we
# can fix this with a different approach.

define monitor::service_serverside (
    $command_line   = false,
    $command_name,
    $command_source = false,
    $command_args   = [],
    $check_interval = false,
    $server_include = false,
    $host,
    $hostgroup      = false,
    $address,
    $parents        = false,
    $service,
    $icon           = 'server.png',
    $plugin_path    = '/usr/lib64/nagios/plugins',
    $notes_url      = false,
)
{
    if $server_include
    {
        include $server_include
    }

    if $command_source
    {
        $command_source_basename = regsubst($command_source, '^.*/', '')

        ensure_resource ('file', "${plugin_path}/${command_source_basename}",
        {
            owner  => 'nagios',
            group  => 'nagios',
            mode   => '0755',
            source => $command_source,
        })
    }

    if type($command_args) == 'array' and ! empty($command_args)
    {
        $command_args_string = join ($command_args, '!')
        $real_command_name = "$command_name!$command_args_string"
    }
    else
    {
        $real_command_name = $command_name
    }

    nagiosng::object::service { "${host}-${service}":
        attributes => {host_name           => $host,
                       service_description => $service,
                       check_command       => $real_command_name,
                       check_interval      => $check_interval,
                       notes_url           => $notes_url,
        },
    }

    if $hostgroup
    {
        ensure_resource ('nagiosng::object::hostgroup', $hostgroup,
                         {attributes => {hostgroup_name => $hostgroup,
                                         alias          => $hostgroup,
                         }})
    }

    ensure_resource ('nagiosng::object::host', $host,
                     {attributes => {host_name       => $host,
                                     alias           => $host,
                                     hostgroups      => $hostgroup,
                                     address         => $address,
                                     icon_image      => $icon,
                                     statusmap_image => $icon,
                                     parents         => $parents,
                     }})

    if ! defined(Nagiosng::Object::Command[$command_name])
    {
        nagiosng::object::command { $command_name:
            attributes => {command_name => $command_name,
                           command_line => $command_line,}
        }
    }
}
