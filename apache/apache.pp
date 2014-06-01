node ubuntu {


class { 'apache':
	#Remove apache server and OS information 
	server_signature => 'Off',
	server_tokens => 'Prod',
	#Run apache with non-privileged account
	user => 'http-web',
	group => 'http-web',
	#Amount of time the server will wait for certain I/O events before it fails
        timeout => '50',
}

exec { "enable_access_compat":
    command => "/usr/sbin/a2enmod access_compat",
    require => [ Class['apache'] ]
}

include apache::mod::headers
include apache::mod::rewrite

include augeas

#disable directory browser listing
augeas { "configure_directory2":
    context => "/files/etc/apache2/apache2.conf",
    changes => [ "set Directory[2]/arg /var/www/html",
                 "set Directory[2]/directive[1]   Options",
                 "set Directory[2]/directive[1]/arg[1] +Indexes",
		 "set Directory[2]/directive[1]/arg[2] -Includes",
		 "set Directory[2]/directive[1]/arg[3] -ExecCGI",
		 "set Directory[2]/directive[1]/arg[4] -FollowSymLinks",
                 "set Directory[2]/directive[2]   Order",
                 "set Directory[2]/directive[2]/arg allow,deny",
                 "set Directory[2]/directive[3]   Allow",
                 "set Directory[2]/directive[3]/arg[1] from",
                 "set Directory[2]/directive[3]/arg[2] all",

    ],
    require => [ Augeas["configure_directory1"] ]
}

#disable access to root directory
augeas { "configure_directory1":
    context => "/files/etc/apache2/apache2.conf",
    changes => [ "set Directory[1]/arg /",
                 "set Directory[1]/directive[1]   Options",
                 "set Directory[1]/directive[1]/arg FollowSymLinks",
                 "set Directory[1]/directive[2]   AllowOverride", #Order",
                 "set Directory[1]/directive[2]/arg None", #deny,allow",
                 "set Directory[1]/directive[3]   Require", #Deny",
                 "set Directory[1]/directive[3]/arg[1] All", #from",
                 "set Directory[1]/directive[3]/arg[2] Denied", #all",

    ],
    # require => [ Class['apache'], Augeas["configure_directory1"] ]
}

#remove etag
file_line { 'etag':
      path => '/etc/apache2/apache2.conf',
      line => 'FileETag None',
      require => [ Class['apache'] ]
}

file_line { 'confs':
      path => '/etc/apache2/apache2.conf',
      line => 'IncludeOptional conf-enabled/*.conf'
}

#mitigate cross site scripting using HttpOnly and Secure flag in cookie
file_line { 'set_cookie':
      path => '/etc/apache2/conf-enabled/security.conf',
      line => 'Header edit Set-Cookie ^(.*)$ $1;HttpOnly;Secure',
      match => 'Header edit Set-Cookie',
      require => [ Class['apache'] ]
}

#prevent clickjacking attacks
file_line { 'clickjacking':
      path => '/etc/apache2/conf-enabled/security.conf',
      line => 'Header always append X-Frame-Options SAMEORIGIN',
      match => 'Header always append X-Frame',
      require => [ Class['apache'] ]
}

#set cross site scripting protection
file_line { 'x-xss':
      path => '/etc/apache2/conf-enabled/security.conf',
      line => 'Header set X-XSS-Protection "1; mode=block"',
      match => 'Header set X-XSS',
      require => [ Class['apache'] ]
}

#disable http1.0 unsecure protocol version
file_line { 'disable_http1':
      path => '/etc/apache2/conf-enabled/security.conf',
      line => 'RewriteEngine On',
      require => [ Class['apache'] ]
}

file_line { 'disable_http2':
      path => '/etc/apache2/conf-enabled/security.conf',
      line => 'RewriteCond %{THE_REQUEST} !HTTP/1\.1$',
      require => [ Class['apache'], File_line['disable_http1'] ]
}  

file_line { 'disable_http3':
      path => '/etc/apache2/conf-enabled/security.conf',
      line => 'RewriteRule .* - [F]',
      require => [ Class['apache'], File_line['disable_http2'] ]
}

#Set Log Format
file_line { 'log':
      path => '/etc/apache2/apache2.conf',
      line => 'LogFormat "%h %l %u %t \"%{sessionID}C\" \"%r\" %>s %b %T" common',
      require => [ Class['apache'] ]
}

file { '/usr/lib/libxml2.so.2':
   ensure => 'link',
   target => '/usr/lib/x86_64-linux-gnu/libxml2.so.2',
}

#Install mod-security
package { "libapache2-mod-security2":
    ensure => installed,
}

exec { 'move_ms':
command => '/bin/mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf',
creates => '/etc/modsecurity/modsecurity.conf',
require => Package['libapache2-mod-security2']
}
->
file { '/etc/modsecurity/modsecurity.conf-recommended':
ensure => absent,
}

/*
augeas { "configure_modsec":
    context => "/files/etc/modsecurity/modsecurity.conf",
    changes => [ "set directive['SecRuleEngine' = .]/arg On",
                 "set directive['SecRequestBodyInMemoryLimit' = .]/arg 16384000",
    ]
    #require => Exec['move_ms']
}*/

file_line { 'modsec1':
      path => '/etc/modsecurity/modsecurity.conf',
      line => 'SecRuleEngine On',
      match => '^SecRuleEngine',
      require => [ Exec['move_ms'] ]
}

file_line { 'modsec2':
      path => '/etc/modsecurity/modsecurity.conf',
      line => 'SecRequestBodyLimit 16384000',
      match => '^SecRequestBodyLimit 1',
      require => [ File_line['modsec1'] ]
}

file_line { 'modsec3':
      path => '/etc/modsecurity/modsecurity.conf',
      line => 'SecRequestBodyInMemoryLimit 16384000',
      match => '^SecRequestBodyInMemoryLimit 1',
      require => [ File_line['modsec2'] ]
}

#Download and include owasp rules
include wget

wget::fetch { "test":
       source      => 'https://github.com/SpiderLabs/owasp-modsecurity-crs/tarball/master',
       destination => '/tmp/SpiderLabs-owasp-modsecurity-crs.tar.gz',
       timeout     => 0,
       verbose     => false,
}
->
exec { 'untar':
command => "/bin/tar zxvf /tmp/SpiderLabs-owasp-modsecurity-crs.tar.gz -C /etc/modsecurity",
}
	
exec { 'move_owasp':
command => '/bin/mv /etc/modsecurity/SpiderLabs-owasp-modsecurity-crs-ebe8790/modsecurity_crs_10_setup.conf.example /etc/modsecurity/modsecurity_crs_10_setup.conf',
creates => '/etc/modsecurity/modsecurity_crs_10_setup.conf',
require => [ Package['libapache2-mod-security2'], Exec['untar'] ]
}
->
file { '/etc/modsecurity/modsecurity_crs_10_setup.conf.example':
ensure => absent,
}

file { "/etc/modsecurity/activated_rules/":
    ensure => "directory",
    require => [ Exec['untar'] ]
}
->
exec { 'rules':
command => '/bin/cp /etc/modsecurity/SpiderLabs-owasp-modsecurity-crs-ebe8790/base_rules/* /etc/modsecurity/activated_rules/',
require => [ Exec['untar'] ]
}
->
exec { 'rules1':
command => '/bin/cp /etc/modsecurity/SpiderLabs-owasp-modsecurity-crs-ebe8790/optional_rules/* /etc/modsecurity/activated_rules/',
require => [ Exec['untar'] ]
}

file { 'create_conf':
      path => '/etc/apache2/mods-available/security2.conf',
      ensure => file,
      content => "<IfModule security2_module>\n",
      require => Exec['rules1']
    }

file_line { 'mod_sec':
      path => '/etc/apache2/mods-available/security2.conf',
      line => '        SecDataDir /var/cache/modsecurity',
      require => File['create_conf']
}

file_line { 'mod_sec1':
      path => '/etc/apache2/mods-available/security2.conf',
      line => '        IncludeOptional /etc/modsecurity/*.conf',
      require => File_line['mod_sec']
}

file_line { 'mod_sec2':
      path => '/etc/apache2/mods-available/security2.conf',
      line => '        Include "/etc/modsecurity/activated_rules/*.conf"',
      require => File_line['mod_sec1']
}

file_line { 'mod_sec3':
      path => '/etc/apache2/mods-available/security2.conf',
      line => '</IfModule>',
      require => File_line['mod_sec2']
}

file {'/etc/apache2/mods-available/security2.load':
      ensure  => file,
      content => "LoadFile libxml2.so.2 \n",
      require => Package['libapache2-mod-security2']
    }

file_line { 'sec_load':
      path => '/etc/apache2/mods-available/security2.load',
      line => 'LoadModule security2_module /usr/lib/apache2/modules/mod_security2.so',
      require => File['/etc/apache2/mods-available/security2.load']
}

file { 'symlink_conf':
   path => '/etc/apache2/mods-enabled/security2.conf',
   ensure => 'link',
   target => '/etc/apache2/mods-available/security2.conf',
   require => File_line['mod_sec3']
}

file { 'symlink_load':
   path => '/etc/apache2/mods-enabled/security2.load',
   ensure => 'link',
   target => '/etc/apache2/mods-available/security2.load',
   require => File_line['sec_load']
}

exec { 'mod_unique':
command => '/usr/sbin/a2enmod unique_id',
require => [ File['symlink_conf'], File['symlink_load'] ]
}
->	
exec { 'mod_sec':
command => '/usr/sbin/a2enmod security2',
require => [ File['symlink_conf'], File['symlink_load'] ]
}

/*
augeas { "configure_mod":
    context => "/files/etc/apache2/mods-enabled/security2.conf",
    changes => [ "set IfModule/arg security2",
                 "set IfModule/directive[1]  "SecDataDir"",
                 "set IfModule/directive[1]/arg /var/cache/modsecurity",
                 "set IfModule/directive[2]   IncludeOptional",
                 "set IfModule/directive[2]/arg /etc/modsecurity/*.conf",
                 "set IfModule/directive[3]   Include",
                 "set IfModule/directive[3]/arg \"/etc/modsecurity/activated_rules/*.conf\"",
    ],
    require => File['/etc/apache2/mods-enabled/security2.conf'] 
}
*/

#Install mod evasive
package { "libapache2-mod-evasive":
    ensure => installed,
}

file { "/var/log/mod_evasive":
    ensure => "directory",
    owner => "http-web",
    group => "http-web",
}

file {'/etc/apache2/mods-available/evasive.conf':
      ensure  => file,
      content => "<ifmodule mod_evasive20.c> \n",
      require => Package['libapache2-mod-evasive']
    }

file_line { 'mod_ev1':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSHashTableSize 3097',
      require => File['/etc/apache2/mods-available/evasive.conf']
}

file_line { 'mod_ev2':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSPageCount  2',
      require => File_line['mod_ev1']
}

file_line { 'mod_ev3':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSSiteCount  50',
      require => File_line['mod_ev2']
}

file_line { 'mod_ev4':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSPageInterval 1',
      require => File_line['mod_ev3']
}

file_line { 'mod_ev5':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSSiteInterval  1',
      require => File_line['mod_ev4']
}

file_line { 'mod_ev6':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSBlockingPeriod  10',
      require => File_line['mod_ev5']
}

file_line { 'mod_ev7':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSLogDir   /var/log/mod_evasive',
      require => File_line['mod_ev6']
}

file_line { 'mod_ev8':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSEmailNotify email@domain.com',
      require => File_line['mod_ev7']
}

file_line { 'mod_ev9':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '   DOSWhitelist   127.0.0.1',
      require => File_line['mod_ev8']
}

file_line { 'mod_ev10':
      path => '/etc/apache2/mods-available/evasive.conf',
      line => '</ifmodule>',
      require => File_line['mod_ev9']
}

file {'/etc/apache2/mods-available/evasive.load':
      ensure  => file,
      content => "LoadModule evasive20_module /usr/lib/apache2/modules/mod_evasive20.so",
      require => Package['libapache2-mod-evasive']
    }

file { 'symlink_confe':
   path => '/etc/apache2/mods-enabled/evasive.conf',
   ensure => 'link',
   target => '/etc/apache2/mods-available/evasive.conf',
   require => File_line['mod_ev10']
}

file { 'symlink_confel':
   path => '/etc/apache2/mods-enabled/evasive.load',
   ensure => 'link',
   target => '/etc/apache2/mods-available/evasive.load',
   require => File['/etc/apache2/mods-available/evasive.load']
}


exec { 'mod_evas':
command => '/usr/sbin/a2enmod evasive',
require => [ File['symlink_confe'], File['symlink_confel'] ]
}

}
