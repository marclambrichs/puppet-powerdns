# bind backend for powerdns
#
# @param auth_configdir
# @param auth_package
# @param auth_service
class powerdns::backends::bind (
  String $auth_configdir = $powerdns::auth_configdir,
  String $auth_package   = $powerdns::auth_package,
  String $auth_service   = $powerdns::auth_service
) inherits powerdns {
  # Remove the default simplebind configuration as we prefer to manage PowerDNS
  # consistently across all operating systems. This file is added to Debian
  # based systems due to Debian's policies.
  file { "${auth_configdir}/pdns.d/pdns.simplebind.conf":
    ensure  => absent,
    require => Package[$auth_package],
  }

  # set the configuration variables
  powerdns::config { 'launch':
    ensure  => present,
    setting => 'launch',
    value   => 'bind',
    type    => 'authoritative',
  }

  powerdns::config { 'bind-config':
    ensure  => present,
    setting => 'bind-config',
    value   => "${auth_configdir}/named.conf",
    type    => 'authoritative',
    require => Package[$auth_package],
  }

  file { "${auth_configdir}/named.conf":
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package[$auth_package],
  }

  file_line { 'powerdns-bind-baseconfig':
    ensure  => present,
    path    => "${auth_configdir}/named.conf",
    line    => "options { directory \"${auth_configdir}/named\"; };",
    match   => 'options',
    notify  => Service[$auth_service],
    require => File["${auth_configdir}/named.conf"],
  }

  file { "${auth_configdir}/named":
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package[$auth_package],
  }
}
