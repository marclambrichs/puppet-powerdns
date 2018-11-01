# powerdns::authoritative
#
# @param backend
# @param config
# @param package
# @param package_ensure
# @param service
class powerdns::authoritative (
  String $backend        = $powerdns::backend,  
  Hash   $config         = $powerdns::auth_config,
  String $package        = $powerdns::auth_package,
  String $package_ensure = $powerdns::auth_package_ensure,
  String $service        = $powerdns::auth_service,
) inherits powerdns {
  
  # install the powerdns package
  package { $package:
    ensure => $package_ensure,
  }

  # install the right backend
  case $backend {
    'mysql': {
      include powerdns::backends::mysql
    }
    'bind': {
      include powerdns::backends::bind
    }
    'postgresql': {
      include powerdns::backends::postgresql
    }
    'ldap': {
      include powerdns::backends::ldap
    }
    'sqlite': {
      include powerdns::backends::sqlite
    }
    default: {
      fail("${backend} is not supported. We only support 'mysql', 'bind', 'postgresql', 'ldap' and 'sqlite' at the moment.")
    }
  }

  # create config
  if length($config) > 0 {
    $auth_defaults = { 'type' => 'authoritative' }
    create_resources(powerdns::config, $config, $auth_defaults)
  }

  service { $service:
    ensure  => running,
    enable  => true,
    require => Package[$package],
  }
}
