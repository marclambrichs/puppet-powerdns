# ldap backend for powerdns
#
# @param auth_package
# @param auth_service
# @param backend_create_tables
# @param backend_install
# @param ldap_backend_package_name
# @param ldap_basedn
# @param ldap_binddn
# @param ldap_host
# @param ldap_method
# @param ldap_secret
class powerdns::backends::ldap (
  String  $auth_package              = $powerdns::auth_package,
  String  $auth_service              = $powerdns::auth_service,
  Boolean $backend_create_tables     = $powerdns::backend_create_tables,
  Boolean $backend_install           = $powerdns::backend_install,
  String  $ldap_backend_package_name = $powerdns::ldap_backend_package_name,
  String  $ldap_basedn               = $powerdns::ldap_basedn,  
  String  $ldap_binddn               = $powerdns::ldap_binddn,
  String  $ldap_host                 = $powerdns::ldap_host,
  String  $ldap_method               = $powerdns::ldap_method,  
  String  $ldap_secret               = $powerdns::ldap_secret,

) inherits powerdns {
  
  if $facts['os']['family'] == 'Debian' {
    # The pdns-server package from the Debian APT repo automatically installs the bind
    # backend package which we do not want when using another backend such as ldap.
    package { 'pdns-backend-bind':
      ensure  => purged,
      require => Package[$auth_package],
    }
  }

  # set the configuration variables
  powerdns::config { 'launch':
    ensure  => present,
    setting => 'launch',
    value   => 'ldap',
    type    => 'authoritative',
  }

  powerdns::config { 'ldap-host':
    ensure  => present,
    setting => 'ldap-host',
    value   => $ldap_host,
    type    => 'authoritative',
  }

  powerdns::config { 'ldap-binddn':
    ensure  => present,
    setting => 'ldap-binddn',
    value   => $ldap_binddn,
    type    => 'authoritative',
  }

  powerdns::config { 'ldap-secret':
    ensure  => present,
    setting => 'ldap-secret',
    value   => $ldap_secret,
    type    => 'authoritative',
  }

  powerdns::config { 'ldap-basedn':
    ensure  => present,
    setting => 'ldap-basedn',
    value   => $ldap_basedn,
    type    => 'authoritative',
  }

  powerdns::config { 'ldap-method':
    ensure  => present,
    setting => 'ldap-method',
    value   => $ldap_method,
    type    => 'authoritative',
  }

  # set up the powerdns backend
  package { $ldap_backend_package_name:
    ensure  => installed,
    before  => Service[$auth_service],
    require => Package[$auth_package],
  }

  if $backend_install {
    fail('backend_install is not supported with ldap')
  }

  if $backend_create_tables {
    fail('backend_create_tables is not supported with ldap')
  }
}
