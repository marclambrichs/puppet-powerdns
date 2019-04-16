# powerdns::repo
#
# @param auth_package
# @param custom_epel
# @param recursor_package
# @param version
class powerdns::repo (
  String $auth_package = $powerdns::auth_package,
  Boolean $custom_epel = $powerdns::custom_epel,
  String $recursor_package = $powerdns::recursor_package,
  String $version = $powerdns::version,
) inherits powerdns {

  # The repositories of PowerDNS use a version such as '40' for version 4.0
  # and 41 for version 4.1.
  case $version {
    '4.0': {
      $short_version = '40'
    }
    '4.1': {
      $short_version = '41'
    }
    default: {
      fail("Version ${version} is not supported.")
    }
  }

  case $facts['os']['family'] {
    'RedHat': {
      unless $custom_epel {
        include ::epel
      }

      Yumrepo['powerdns'] -> Package <| title == $auth_package |>
      Yumrepo['powerdns-recursor'] -> Package <| title == $recursor_package |>

      package { 'yum-plugin-priorities':
        ensure => installed,
        before => Yumrepo['powerdns'],
      }

      yumrepo { 'powerdns':
        name        => 'powerdns',
        descr       => "PowerDNS repository for PowerDNS Authoritative - version ${version}",
        baseurl     => "http://repo.powerdns.com/centos/\$basearch/\$releasever/auth-${short_version}",
        gpgkey      => 'https://repo.powerdns.com/FD380FBB-pub.asc',
        gpgcheck    => 1,
        enabled     => 1,
        priority    => 90,
        includepkgs => 'pdns*',
      }

      yumrepo { 'powerdns-recursor':
        name        => 'powerdns-recursor',
        descr       => "PowerDNS repository for PowerDNS Recursor - version ${version}",
        baseurl     => "http://repo.powerdns.com/centos/\$basearch/\$releasever/rec-${short_version}",
        gpgkey      => 'https://repo.powerdns.com/FD380FBB-pub.asc',
        gpgcheck    => 1,
        enabled     => 1,
        priority    => 90,
        includepkgs => 'pdns*',
      }
    }

    'Debian': {
      include ::apt

      $os = downcase($facts['os']['name'])

      # Make sure the repo's are added before we're managing packages
      # puppet-lint seems to error out on spaces here (bug?) so it looks a bit dodgy
      Class['apt::update']->Package<||>

      apt::key { 'powerdns':
        ensure => present,
        id     => '9FAAA5577E8FCF62093D036C1B0C6205FD380FBB',
        source => 'https://repo.powerdns.com/FD380FBB-pub.asc',
      }

      apt::source { 'powerdns':
        ensure       => present,
        location     => "http://repo.powerdns.com/${os}",
        repos        => 'main',
        release      => "${::lsbdistcodename}-auth-${short_version}",
        architecture => 'amd64',
        require      => Apt::Key['powerdns'],
      }

      apt::source { 'powerdns-recursor':
        ensure       => present,
        location     => "http://repo.powerdns.com/${os}",
        repos        => 'main',
        release      => "${::lsbdistcodename}-rec-${short_version}",
        architecture => 'amd64',
        require      => Apt::Key['powerdns'],
      }

      apt::pin { 'powerdns':
        priority => 600,
        packages => 'pdns-*',
        origin   => 'repo.powerdns.com',
        require  => Apt::Source['powerdns'],
      }
    }

    default: {
      fail("${facts['os']['family']} is not supported yet.")
    }
  }
}
