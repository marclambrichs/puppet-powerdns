# the powerdns recursor
#
# @param config
# @param package
# @param package_ensure
# @param service
class powerdns::recursor (
  Hash   $config         = $powerdns::recursor_config,
  String $package        = $powerdns::recursor_package,
  String $package_ensure = $powerdns::recursor_package_ensure,
  String $service        = $powerdns::recursor_service,
) inherits powerdns {
  package { $package:
    ensure => $package_ensure,
  }

  # create config
  if length($config) > 0 {
    $auth_defaults = { 'type' => 'recursor' }
    create_resources(powerdns::config, $config, $auth_defaults)
  }  

  service { $service:
    ensure  => running,
    enable  => true,
    require => Package[$package],
  }
}
