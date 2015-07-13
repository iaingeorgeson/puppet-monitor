# monitor::device - check a non-puppet-host service

# As ever, the resource name needs to be unique. We may have multiple
# services on the same host, or the same service on multiple hosts, so
# the resource name needs to contain both.

# The monitor::service infrastructure has a lot of magic to do things
# automatically for you. This resource requires the user to be more
# explicit, and doesn't pull information from hiera and facter.

# The host and service names for the check are taken by default from
# the resource name, split on ':'. You can if you wish override any
# of service, host or address by setting them explicitly.

# Similarly to the monitor::service resource, the command_line must be
# the same for all checks with the same command_name - if you want two
# different check_pings to behave differently, you must give them
# different names.

define monitor::device (
    $service        = false,
    $host           = false,
    $address        = false,
    $command_line   = false,
    $command_source = false,
    $plugin_path    = '/usr/lib64/nagios/plugins',
    $check_interval = false,
    $icon           = 'server.png',
    $parents        = false,
    $notes_url_fmt  = false,
)
{
    # Split the ${host}-${service} out of the name
    $name_array = split ($name, ':')

    if $service
    {
        $real_service = $service
    }
    else
    {
        if $name_array[1]
        {
            $real_service = $name_array[1]
        }
        else
        {
            fail ('No service name found')
        }
    }

    if $host
    {
        $real_host = $host
    }
    else
    {
        if $name_array[0]
        {
            $real_host = $name_array[0]
        }
        else
        {
            fail ('No host name found')
        }
    }

    if $address
    {
        $real_address = $address
    }
    else
    {
        if $name_array[0]
        {
            $real_address = $name_array[0]
        }
        else
        {
            fail ('No address name found')
        }
    }

    # Set the command_name for nagios to use. This is based on the
    # resource's $name.
    $safe_service = regsubst($real_service, '[/:\n]', '_', 'GM')
    $command_name = "check_${safe_service}"

    # Unless the $command_line is absolute (starts with / or $)
    # prepend the $USER1$ variable so the nagios server can
    # substitute its own plugin path.
    if $command_line =~ /^[\/\$]/
    {
        $real_command_line = $command_line
    }
    else
    {
        $real_command_line = "\$USER1\$/${command_line}"
    }

    if $command_source
    {
        $command_source_basename =
        regsubst($command_source, '^.*/', '')

        ensure_resource('file', "${plugin_path}/${command_source_basename}",
        {
            owner  => 'nagios',
            group  => 'nagios',
            mode   => 755,
            source => $command_source,
        })
    }

    if $parents
    {
        $real_parents = $parents
    }
    else
    {
        $real_parents = hiera('monitor::service::parents', false)
    }

    if $notes_url_fmt
    {
        $notes_url = sprintf($notes_url_fmt, $service)
    }
    else
    {
        $notes_url = false
    }

    # And spin up the nagios stanzas
    nagiosng::object::service { "${real_host}-${$real_service}":
        attributes => {host_name           => $real_host,
                       service_description => $real_service,
                       check_command       => $command_name,
                       check_interval      => $check_interval,
                       notes_url           => $notes_url,
        },
    }

    ##FIXME: This would be better as  if ! defined(...)
    ensure_resource ('nagiosng::object::host', $real_host,
                     {attributes => {host_name       => $real_host,
                                     alias           => $real_host,
                                     address         => $real_address,
                                     icon_image      => $icon,
                                     statusmap_image => $icon,
                                     parents         => $real_parents,
                     }})

    ##FIXME: This would be better as  if ! defined(...)
    ensure_resource  ('nagiosng::object::command', $command_name,
                     {attributes => {command_name => $command_name,
                                     command_line => $real_command_line,}})
}
