# powerdns::config
define powerdns::config (
  String                            $setting = $title,
  Variant[String, Integer]          $value   = '',
  Enum['present', 'absent']         $ensure  = 'present',
  Enum['authoritative', 'recursor'] $type    = 'authoritative'
) {

  unless $ensure == 'absent' or ($setting in [ 'gmysql-dnssec', 'only-notify', 'allow-notify-from' ]) {
    assert_type(Variant[String[1], Integer], $value) |$_expected, $_actual| {
      fail("Value for ${setting} can't be empty.")
    }
  }

  if $setting == 'gmysql-dnssec' { $line = $setting }
  else { $line = "${setting}=${value}" }

  if $type == 'authoritative' {
    $path            = $::powerdns::auth_configpath
    $require_package = $::powerdns::auth_package
    $notify_service  = $::powerdns::auth_service
  } else {
    $path            = $::powerdns::recursor_configpath
    $require_package = $::powerdns::recursor_package
    $notify_service  = $::powerdns::recursor_service
  }

  file_line { "powerdns-config-${setting}-${path}":
    ensure            => $ensure,
    path              => $path,
    line              => $line,
    match             => "^${setting}=",
    match_for_absence => true, # ignored when ensure == 'present'
    require           => Package[$require_package],
    notify            => Service[$notify_service],
  }
}
