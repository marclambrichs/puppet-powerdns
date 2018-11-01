# postgresql backend for powerdns
#
# @param auth_configdir
# @param auth_package
# @param backend_create_tables
# @param backend_install
# @param db_host
# @param db_name
# @param db_password
# @param db_root_password
# @param db_username
# @param pgsql_backend_package_name
# @param pgsql_schema_file
class powerdns::backends::postgresql (
  String  $auth_configdir             = $powerdns::auth_configdir,
  String  $auth_package               = $powerdns::auth_package,
  Boolean $backend_create_tables      = $powerdns::backend_create_tables,
  Boolean $backend_install            = $powerdns::backend_install,
  String  $db_host                    = $powerdns::db_host,
  String  $db_name                    = $powerdns::db_name,
  String  $db_password                = $powerdns::db_password,
  String  $db_root_password           = $powerdns::db_root_password,
  String  $db_username                = $powerdns::db_username,  
  String  $pgsql_backend_package_name = $powerdns::pgsql_backend_package_name,
  String  $pgsql_schema_file          = $powerdns::pgsql_schema_file,
) inherits powerdns {
  
  if $facts['os']['family'] == 'Debian' {
    # Remove the debconf gpgsql configuration file auto-generated when using the package
    # from Debian repository as it interferes with this module's backend configuration.
    file { "${auth_configdir}/pdns.d/pdns.local.gpgsql.conf":
      ensure  => absent,
      require => Package[$pgsql_backend_package_name],
    }

    # The pdns-server package from the Debian APT repo automatically installs the bind
    # backend package which we do not want when using another backend such as pgsql.
    package { 'pdns-backend-bind':
      ensure  => purged,
      require => Package[$auth_package],
    }
  }

  # set the configuration variables
  powerdns::config { 'launch':
    ensure  => present,
    setting => 'launch',
    value   => 'gpgsql',
    type    => 'authoritative',
  }

  powerdns::config { 'gpgsql-host':
    ensure  => present,
    setting => 'gpgsql-host',
    value   => $db_host,
    type    => 'authoritative',
  }

  powerdns::config { 'gpgsql-user':
    ensure  => present,
    setting => 'gpgsql-user',
    value   => $db_username,
    type    => 'authoritative',
  }

  powerdns::config { 'gpgsql-password':
    ensure  => present,
    setting => 'gpgsql-password',
    value   => $db_password,
    type    => 'authoritative',
  }

  powerdns::config { 'gpgsql-dbname':
    ensure  => present,
    setting => 'gpgsql-dbname',
    value   => $db_name,
    type    => 'authoritative',
  }

  # set up the powerdns backend
  package { $pgsql_backend_package_name:
    ensure  => installed,
    before  => Service[$auth_service],
    require => Package[$auth_package],
  }

  if $backend_install {
    if ! defined(Class['::postgresql::server']) {
      class { '::postgresql::server':
        postgres_password => $db_root_password,
      }
    }
  }

  if $backend_create_tables {
    postgresql::server::db { $db_name:
      user     => $db_username,
      password => postgresql_password($db_username, $db_password),
      require  => Package[$pgsql_backend_package_name],
    }

    # define connection settings for powerdns user in order to create tables
    $connection_settings_powerdns = {
      'PGUSER'     => $db_username,
      'PGPASSWORD' => $db_password,
      'PGHOST'     => $db_host,
      'PGDATABASE' => $db_name,
    }

    postgresql_psql { 'Load SQL schema':
      connect_settings => $connection_settings_powerdns,
      command          => "\\i ${pgsql_schema_file}",
      unless           => "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'domains'",
      require          => Postgresql::Server::Db[$db_name],
    }
  }
}
