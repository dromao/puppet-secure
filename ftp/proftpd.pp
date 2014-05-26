$servername="ubuntu.monaco.studlab.os3.nl"

node ubuntu {

#include proftpd

#Create proftpd group 
  group { "proftpd":
    ensure => present,
    gid => 500,
  }

#Add it to the conf
  class { 'proftpd':
  daemon_group => 'proftpd',
  require => Group['proftpd'],
#For security purposes, look up the host name of users as they connect
  identlookups => 'on',
  }

#Create user proftpd
  user { "proftpd":
    ensure => present,
    uid => 500,
    gid => 500,
  }

#Include TLS conf
file_line { 'tls':
      path => '/etc/proftpd/proftpd.conf',
      line => 'Include /etc/proftpd/tls.conf',
      match => 'Include /etc/proftpd/tls',
  }

#Enable TLS
file_line { 'tls1':
      path => '/etc/proftpd/tls.conf',
      line => 'TLSEngine on',
      match => 'TLSEngine',
  }

#Enables TLS log
file_line { 'tls2':
      path => '/etc/proftpd/tls.conf',
      line => 'TLSLog /var/log/proftpd/tls.log',
      match => 'TLSLog',
  }

#Use only SSLv3 and TLSv1
file_line { 'tls3':
      path => '/etc/proftpd/tls.conf',
      line => 'TLSProtocol SSLv23',
      match => 'TLSProtocol',
  }

#Certificate used for tls, we used the openssl default
file_line { 'tls4':
      path => '/etc/proftpd/tls.conf',
      line => 'TLSRSACertificateFile                   /etc/ssl/certs/ssl-cert-snakeoil.pem',
      match => 'TLSRSACertificateFile',
  }

#Certificate key used for tls, openssl default
file_line { 'tls5':
      path => '/etc/proftpd/tls.conf',
      line => 'TLSRSACertificateKeyFile                /etc/ssl/private/ssl-cert-snakeoil.key',
      match => 'TLSRSACertificateKeyFile',
  }

#Do not authenticate clients tha use ftp over tls
file_line { 'tls7':
      path => '/etc/proftpd/tls.conf',
      line => 'TLSVerifyClient                         off',
      match => 'TLSVerifyClient',
  }

#Required to use FTP over TLS
file_line { 'tls8':
      path => '/etc/proftpd/tls.conf',
      line => 'TLSRequired                             on',
      match => 'TLSRequired',
  }

#Login timeout after 120seconds
file_line { 'tls9':
      path => '/etc/proftpd/proftpd.conf',
      line => 'TimeoutLogin 120',
      match => 'TimeoutLogin',
  }

#Allow file overwriting of files in all directories
#file_line { 'tls10':
#      path => '/etc/proftpd/proftpd.conf',
#      line => '<Directory /\*> AllowOverwrite on </Directory>',
#      match => 'AllowOverwrite',
#  }

#Maximum number of authenticated clients logged into the server. Might need change.
file_line { 'tls11':
      path => '/etc/proftpd/proftpd.conf',
      line => 'MaxClients                      30',
      match => '^MaxClients',
  }

#Maximum number of login attempts to authenticate to the server during a connection 
file_line { 'tls12':
      path => '/etc/proftpd/proftpd.conf',
      line => 'MaxLoginAttempts                3 "Maximum authentication attempts exceeded"',
      match => 'MaxLoginAttempts',
  }

#Maximum number of clients allowed to connect per host. Might need change.
file_line { 'tls13':
      path => '/etc/proftpd/proftpd.conf',
      line => 'MaxClientsPerHost               50',
      match => 'MaxClientsPerHost',
  }

#Daemon accepts commands containing alphanumeric characters and white-space for security reasons.
file_line { 'tls14':
      path => '/etc/proftpd/proftpd.conf',
      line => 'AllowFilter "^[a-zA-Z0-9 ,]*$"',
      match => 'AllowFilter',
  }

#Proper logging
file_line { 'tls15':
      path => '/etc/proftpd/proftpd.conf',
      line => 'LogFormat default "%h %l %u %t \\"%r\\" %s %b"',
      match => 'LogFormat default',
  }

file_line { 'tls16':
      path => '/etc/proftpd/proftpd.conf',
      line => 'LogFormat auth "%v [%P] %h %t \\"%r\\" %s"',
      match => 'LogFormat auth',
  }

file_line { 'tls17':
      path => '/etc/proftpd/proftpd.conf',
      line => 'LogFormat write "%h %l %u %t \\"%r\\" %s %b"',
      match => 'LogFormat write',
  }

file_line { 'tls20':
      path => '/etc/proftpd/proftpd.conf',
      line => 'ExtendedLog /var/log/proftpd/access.log WRITE,READ write',
      match => 'ExtendedLog /var/log/proftpd/access.log',
  }

file_line { 'tls21':
      path => '/etc/proftpd/proftpd.conf',
      line => 'ExtendedLog /var/log/proftpd/auth.log AUTH auth',
      match => 'ExtendedLog /var/log/proftpd/auth.log',
  }

file_line { 'tls22':
      path => '/etc/proftpd/proftpd.conf',
      line => 'ExtendedLog /var/log/proftpd/paranoid.log ALL default',
      match => 'ExtendedLog /var/log/proftpd/paranoid.log',
  }


#To avoid misconfigured DNS
file_line { 'tls18':
      path => '/etc/proftpd/proftpd.conf',
      line => 'UseReverseDNS off',
      match => 'UseReverseDNS',
  }

/*
#Prevent users from creating files outside of their home directories.
file_line { 'tls23':
      path => '/etc/proftpd/proftpd.conf',
      line => '<Limit WRITE>',
  }

file_line { 'tls24':
      path => '/etc/proftpd/proftpd.conf',
      line => 'DenyAll',
  }

file_line { 'tls25':
      path => '/etc/proftpd/proftpd.conf',
      line => '</Limit>',
  }
*/

#Load tls module
file_line { 'tls26':
      path => '/etc/proftpd/modules.conf',
      line => 'LoadModule mod_tls.c',
      match => 'LoadModule mod_tls',
  }

#For security purposes, look up the host name of users as they connect
#file_line { 'tls27':
#      path => '/etc/proftpd/modules.conf',
#      line => 'IdentLookups on',
#      match => 'IdentLookups',
#  }

# Reload Proftpd
exec { "proftpd_reload":
    command => "/etc/init.d/proftpd start",
    unless  => '/usr/bin/pgrep -f "proftpd >/dev/null"',
}

#Restart proftpd using service proftpd restart or /etc/init.d/proftpd restart
}
