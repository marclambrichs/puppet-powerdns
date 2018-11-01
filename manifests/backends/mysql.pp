# mysql backend for powerdns
# @param auth_package
# @param auth_service
# @param backend_create_tables
# @param backend_install
# @param db_host
# @param db_name
# @param db_password
# @param db_root_password
# @param db_username
# @param mysql_schema_file
class powerdns::backends::mysql (
  String  $auth_package          = $powerdns::auth_package,
  String  $auth_service          = $powerdns::auth_service,
  Boolean $backend_create_tables = $powerdns::backend_create_tables,
  Boolean $backend_install       = $powerdns::backend_install,
  String  $db_host               = $powerdns::db_host,
  String  $db_name               = $powerdns::db_name,
  String  $db_password           = $powerdns::db_password,
  String  $db_root_password      = $powerdns::db_root_password,
  String  $db_username           = $powerdns::db_username,
  String  $mysql_schema_file     = $powerdns::mysql_schema_file
) inherits powerdns {
  
  # set the configuration variables
  powerdns::config { 'launch':
    ensure  => present,
    setting => 'launch',
    value   => 'gmysql',
    type    => 'authoritative',
  }

  powerdns::config { 'gmysql-host':
    ensure  => present,
    setting => 'gmysql-host',
    value   => $db_host,
    type    => 'authoritative',
  }

  powerdns::config { 'gmysql-user':
    ensure  => present,
    setting => 'gmysql-user',
    value   => $db_username,
    type    => 'authoritative',
  }

  powerdns::config { 'gmysql-password':
    ensure  => present,
    setting => 'gmysql-password',
    value   => $db_password,
    type    => 'authoritative',
  }

  powerdns::config { 'gmysql-dbname':
    ensure  => present,
    setting => 'gmysql-dbname',
    value   => $db_name,
    type    => 'authoritative',
  }

  # set up the powerdns backend
  package { 'pdns-backend-mysql':
    ensure  => installed,
    before  => Service[$auth_service],
    require => Package[$auth_package],
  }

  if $backend_install {
    # mysql database
    if ! defined(Class['::mysql::server']) {
      class { '::mysql::server':
        root_password      => $db_root_password,
        create_root_my_cnf => true,
      }
    }

    if ! defined(Class['::mysql::server::account_security']) {
      class { '::mysql::server::account_security': }
    }
  }

  if $backend_create_tables {
    # make sure the database exists
    mysql::db { $db_name:
      user     => $db_username,
      password => $db_password,
      host     => $db_host,
      grant    => [ 'ALL' ],
      sql      => $mysql_schema_file,
      require  => Package['pdns-backend-mysql'],
    }
  }
}
