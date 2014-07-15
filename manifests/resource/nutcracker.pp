# = Class definition for nutcracker config file
# TODO: Document the class.
define twemproxy::resource::nutcracker (
  $auto_eject_hosts     = true,
  $distribution         = 'ketama',
  $ensure               = 'present',
  $log_dir              = '/var/log/nutcracker',
  $members              = '',
  $nutcracker_hash      = 'fnv1a_64',
  $pid_dir              = '/var/run/nutcracker',
  $listen		= '0.0.0.0',
  $port                 = '22111',
  $redis                = true,
  $server_retry_timeout = '2000',
  $server_failure_limit = '3',
  $statsport            = '21111',
  $twemproxy_timeout    = '300',
  $service_state	= "stopped",
  $service_onboot	= false,
) {

  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  }

  $ensure_real = $ensure ? {
    'absent' => absent,
    default  => file,
  }

  # Ensure nutcracker config directory exists
  if ! defined(File['/etc/nutcracker']) {
    file { '/etc/nutcracker':
      ensure  => 'directory',
      mode    => '0755',
    }
  }

  # Ensure nutcracker log directory exists
  if ! defined(File["${log_dir}"]) {
    file { "${log_dir}":
      ensure  => 'directory',
      mode    => '0755',
    }
  }

  # Ensure nutcracker pid directory exists
  if ! defined(File["${pid_dir}"]) {
    file { "${pid_dir}":
      ensure  => 'directory',
      mode    => '0755',
    }
  }

  # Creates nutcracker config YML combining two templates members and pool.
  file { "/etc/nutcracker/${name}.yml":
    ensure  => "${ensure_real}",
    content => template('twemproxy/pool.erb',
                        'twemproxy/members.erb'),
    notify  => Service["nutcracker"]
  }

  # Setup the nutcracker service
  service { "nutcracker":
    enable => $service_boot,
    ensure => $service_run,
  }

  # Creates nutcracker init for the current pool
  file { "/etc/init.d/nutcracker":
    ensure  => "${ensure_real}",
    mode    => '0755',
    content => template('twemproxy/nutcracker.erb'),
    notify  => Service["nutcracker"],
    require => [ File["$log_dir"], File["$pid_dir"] ]
  }

}
