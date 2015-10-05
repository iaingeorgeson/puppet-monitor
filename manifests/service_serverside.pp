# This resource is realised on the nagios server. Don't use it
# directly, use monitor::service instead.

define monitor::service_serverside (
    $command_line   = false,
    $command_name,
    $command_args   = false,
    $check_interval = false,
    $server_include = false,
    $host,
    $hostgroup      = false,
    $address,
    $parents        = false,
    $service,
    $icon           = 'server.png',
    $notes_url      = false,
)
{
    if $server_include
    {
        include $server_include
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
                         {attributes => {host_name       => $hostgroup,
                                         alias           => $hostgroup,
                                         notes_url       => $notes_url,
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
