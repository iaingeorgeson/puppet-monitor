# This resource is realised on the nagios server. Don't use it
# directly, use monitor::service instead.

define monitor::service_serverside (
    $command_line   = false,
    $command_name,
    $command_source = false,
    $command_args   = false,
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

    nagiosng::object::service
    { "${host}-${service}":
        attributes => {host_name           => $host,
                       service_description => $service,
                       check_command       => $command_name,
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

    ensure_resource  ('nagiosng::object::command', $command_name,
                     {attributes => {command_name => $command_name,
                                     command_line => $command_line,}})
}
