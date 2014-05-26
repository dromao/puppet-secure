# Secure Ubuntu 14.04 LTS (might work with others)


#Change name of node if needed
node ubuntu {

## 1. UFW ##

# Install and enable ufw:
include ufw

# Open port 1022 for SSH
ufw::allow { "allow-ssh-on-port-1022":
  port => 1022,
}

# Enable logging for PSAD
ufw::logging { "enable_logging":
    level => 'on',
}

## 2. Secure shared memory ##

file_line { 'tmpfs':
      path => '/etc/fstab',
      line => 'tmpfs     /run/shm     tmpfs     defaults,noexec,nosuid     0     0',
      match => 'tmpfs',      
}


## 3. Harden SSH

# First, make sure it is installed and running
package { "openssh-server":
  ensure => installed,
}

service { "ssh":
    ensure  => "running",
    enable  => "true",
    require => Package["openssh-server"],
}

include augeas

# Change the sshd_config file and restart the daemon
augeas { "configure_sshd":
    context => "/files/etc/ssh/sshd_config",
    changes => [ "set Port 1022" ],
    require => Package["openssh-server"],
    notify  => Service["ssh"]
}


## 4. Harden Network ##

# Make the changes
augeas { "configure_sysctl":
    context => "/files/etc/sysctl.conf",
    changes => [ "set net.ipv4.conf.all.rp_filter 1", 
                 "set net.ipv4.conf.default.rp_filter 1",
                 "set net.ipv4.icmp_echo_ignore_broadcasts 1",
                 "set net.ipv4.conf.all.accept_source_route 0",
                 "set net.ipv6.conf.all.accept_source_route 0",
                 "set net.ipv4.conf.default.accept_source_route 0",
                 "set net.ipv6.conf.default.accept_source_route 0",
                 "set net.ipv4.conf.all.send_redirects 0",
                 "set net.ipv4.conf.default.send_redirects 0",
                 "set net.ipv4.tcp_syncookies 1",
                 "set net.ipv4.tcp_max_syn_backlog 2048",
                 "set net.ipv4.tcp_synack_retries 2",
                 "set net.ipv4.tcp_syn_retries 5",
                 "set net.ipv4.conf.all.log_martians 1",
                 "set net.ipv4.icmp_ignore_bogus_error_responses 1",
                 "set net.ipv4.conf.all.accept_redirects 0",
                 "set net.ipv6.conf.all.accept_redirects 0",
                 "set net.ipv4.conf.default.accept_redirects 0",
                 "set net.ipv6.conf.default.accept_redirects 0",
                 "set net.ipv4.icmp_echo_ignore_all 1" ]
}

# Apply changes
exec { "apply_changes_sysctl":
    command => "/sbin/sysctl -p",
    require => Augeas['configure_sysctl'],
}


## 5. Prevent IP spoofing ##

augeas {"configure_hosts":
    context => "/files/etc/host.conf",
    changes => [ "set nospoof on" ]
}

file_line { 'configure_hosts2':
      path => '/etc/host.conf',
      line => 'order bind,hosts',
      match => "^order",
}

## 6. Keep them out! ##

# Install and configure fail2ban

class { 'fail2ban':
  jails_config   => 'concat',
}

# Jail for SSH
fail2ban::jail { 'sshd':
  port     => '1022',
  logpath  => '/var/log/auth.log',
  maxretry => '3',
}


## 7. PSAD

package { "psad":
    ensure => "installed"
}

# Restart PSAD
exec { "psad_restart":
    command => "/usr/sbin/psad -R",
    require => Package['psad'],
}

# Update signature file
exec { "psad_sig_update":
    command => "/usr/sbin/psad --sig-update",
    require => Exec['psad_restart'],
}


## 8. Check for rootkits:

# RKHunter
package { "rkhunter":
    ensure => "installed"
}

# Create cronjob
cron::daily{
  'rkhunter':
    minute  => '00',
    hour    => '2',
    user    => 'root',
    command => '/usr/bin/rkhunter --cronjob --report-warnings-only';
}

# CHKRootKit
package { "chkrootkit":
    ensure => "installed"
}

cron::daily{
  'chkrootkit':
    minute  => '20',
    hour    => '2',
    user    => 'root',
    command => '/usr/sbin/chkrootkit >> /var/log/chkrootkit.log';
}


## 9. Analyse log files

# Install logwatch
package { "logwatch":
    ensure => "installed"
}

# And a dependency
package { "libdate-manip-perl":
    ensure => "installed"
}

cron::daily{
  'logwatch':
    minute  => '30',
    hour    => '2',
    user    => 'root',
    command => "logwatch --filename /var/log/logwatch.log --range 'today'";
}


## 10. Audit system

package { "tiger":
    ensure => "installed"
}

cron::daily{
  'tiger':
    minute  => '40',
    hour    => '2',
    user    => 'root',
    command => 'tiger';
}
}
