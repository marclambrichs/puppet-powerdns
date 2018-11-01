# powerdns
#
# @param authoritative
# @param auth_config
# @param auth_configdir
# @param auth_configpath
# @param auth_package
# @param auth_package_ensure
# @param auth_service
# @param backend
# @param backend_create_tables  
# @param backend_install
# @param custom_epel    
# @param custom_repo
# @param db_file
# @param db_root_password
# @param db_username
# @param db_password
# @param db_name
# @param db_host
# @param ldap_backend_package_name
# @param ldap_host
# @param ldap_basedn
# @param ldap_method
# @param ldap_binddn
# @param ldap_secret
# @param mysql_schema_file
# @param pgsql_backend_package_name
# @param pgsql_schema_file  
# @param recursor
# @param recursor_config
# @param recursor_configpath
# @param recursor_package
# @param recursor_package_ensure  
# @param recursor_service
# @param sqlite_backend_package_name
# @param sqlite_package_name
# @param sqlite_schema_file
# @param version  
class powerdns (
  Boolean $authoritative,
  Hash    $auth_config = {},
  String  $auth_configdir,
  String  $auth_configpath,
  String  $auth_package,
  Enum['present','installed','absent','purged','latest'] $auth_package_ensure,
  String  $auth_service,
  Enum['ldap', 'mysql', 'bind', 'postgresql', 'sqlite'] $backend,
  Boolean $backend_create_tables,  
  Boolean $backend_install,
  Boolean $custom_epel,    
  Boolean $custom_repo,
  String  $db_file,
  String  $db_root_password,
  String  $db_username,
  String  $db_password,
  String  $db_name,
  String  $db_host,
  String  $ldap_backend_package_name,
  String  $ldap_host,
  String  $ldap_basedn,
  String  $ldap_method,
  String  $ldap_binddn,
  String  $ldap_secret,
  String  $mysql_schema_file,
  String  $pgsql_backend_package_name,
  String  $pgsql_schema_file,  
  Boolean $recursor,
  Hash    $recursor_config = {},
  String  $recursor_configpath,
  String  $recursor_package,
  Enum['present','installed','absent','purged','latest'] $recursor_package_ensure,  
  String  $recursor_service,
  String  $sqlite_backend_package_name,
  String  $sqlite_package_name,
  String  $sqlite_schema_file,
  Enum['4.0','4.1'] $version,  
) {

  # Do some additional checks. In certain cases, some parameters are no longer optional.
  if $authoritative {
    if ($backend != 'bind') and ($backend != 'ldap') and ($backend != 'sqlite') {
      assert_type(String[1], $db_password) |$expected, $actual| {
        fail("'db_password' must be a non-empty string when 'authoritative' == true")
      }
      if $backend_install {
        assert_type(String[1], $db_root_password) |$expected, $actual| {
          fail("'db_root_password' must be a non-empty string when 'backend_install' == true")
        }
      }
    }
  }

  # Include the required classes
  unless $custom_repo {
    contain powerdns::repo
  }

  if $authoritative {
    contain powerdns::authoritative
  }

  if $recursor {
    contain powerdns::recursor
  }
}
