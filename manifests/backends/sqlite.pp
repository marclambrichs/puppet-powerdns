# sqlite backend for powerdns
#
# @param auth_package
# @param auth_service
# @param backend_create_tables
# @param backend_install
# @param db_file
# @param sqlite_backend_package_name
# @param sqlite_package_name
# @param sqlite_schema_file
class powerdns::backends::sqlite (
  String  $auth_package                = $powerdns::auth_package,
  String  $auth_service                = $powerdns::auth_service,
  Boolean $backend_create_tables       = $powerdns::backend_create_tables,
  Boolean $backend_install             = $powerdns::backend_install,
  String  $db_file                     = $powerdns::db_file,
  String  $sqlite_backend_package_name = $powerdns::sqlite_backend_package_name,
  String  $sqlite_package_name         = $powerdns::sqlite_package_name,
  String  $sqlite_schema_file          = $powerdns::sqlite_schema_file,
) inherits powerdns {
  # set the configuration variables
  powerdns::config { 'launch':
    ensure  => present,
    setting => 'launch',
    value   => 'gsqlite3',
    type    => 'authoritative',
  }

  powerdns::config { 'gsqlite3-database':
    ensure  => present,
    setting => 'gsqlite3-database',
    value   => $db_file,
    type    => 'authoritative',
  }

  # set up the powerdns backend
  package { $sqlite_backend_package_name:
    ensure  => installed,
    before  => Service[$auth_service],
    require => Package[$auth_package],
  }
  if $backend_install {
    if ! defined(Package[$sqlite_package_name]) {
      package { $sqlite_package_name:
        ensure => installed,
      }
    }
  }
  if $backend_create_tables {
    file { '/var/lib/powerdns':
      ensure => directory,
      mode   => '0755',
      owner  => 'pdns',
      group  => 'pdns',
    }
    -> file { $db_file:
      ensure => present,
      mode   => '0644',
      owner  => 'pdns',
      group  => 'pdns',
    }
    -> exec { 'powerdns-sqlite3-create-tables':
      command => "/usr/bin/sqlite3 ${db_file} < ${sqlite_schema_file}",
      unless  => "/usr/bin/test `echo '.tables domains' | sqlite3 ${db_file} | wc -l` -eq 1",
      before  => Service[$auth_service],
      require => Package[$auth_package],
    }
  }
}
