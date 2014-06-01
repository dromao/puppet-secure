
$server_hostname = "ubuntu"
$server_domain = "monaco.studlab.os3.nl"
$server_ip = "145.100.105.245"

class { '::postfix::server':
  myhostname              => $server_hostname,
  mydomain                => $server_domain,
  mydestination           => "\$myhostname, localhost.\$mydomain, localhost, $fqdn",
  inet_interfaces         => "$server_ip, 127.0.0.1",
  message_size_limit      => '15360000', # 15MB
  mail_name               => 'secure mail daemon',
  home_mailbox  	  => 'Maildir/',
  mail_spool_directory    => '/var/mail',
  mynetworks		  => '127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128',
  relay_domains 	  => $mydestination,
  smtpd_helo_required     => true,
  smtpd_helo_restrictions => [
   'permit_mynetworks',
   'permit_sasl_authenticated',
   'check_helo_access hash:/etc/postfix/helo_access',
   'reject_unauth_pipelining',
   'reject_non_fqdn_helo_hostname',
   'reject_invalid_helo_hostname',
  ],
  smtpd_sender_restrictions => [
    'permit_mynetworks',
    'reject_unknown_sender_domain',
  ],
  smtpd_client_restrictions => [
    'permit_mynetworks',
    'permit_sasl_authenticated',
    'check_client_access regexp:/etc/postfix/client_restrictions',
    'reject_invalid_hostname',
    'reject_unknown_client_hostname', 
  ],
  smtpd_data_restrictions =>   [
    'reject_unauth_pipelining',
  ],
  smtpd_recipient_restrictions => [
  'reject_non_fqdn_sender',
  'reject_non_fqdn_recipient',
  'reject_non_fqdn_hostname',
  'reject_invalid_hostname',
  'permit_sasl_authenticated',
  'permit_mynetworks',
  'reject_unauth_pipelining',
  'reject_unknown_sender_domain',
  'reject_unknown_recipient_domain',
  'reject_unknown_client',
  'reject_unauth_destination',
  'reject_rbl_client zen.spamhaus.org',
  'reject_rbl_client b.barracudacentral.org',
  'reject_rbl_client cbl.abuseat.org',
  'check_policy_service unix:private/policy-spf',
  'check_policy_service inet:127.0.0.1:10023',
  ],
  smtpd_sasl_auth       => true,
  #ssl                   => '',
  submission            => true,
  header_checks         => [
  '#### non-RFC Compliance headers',
  '/[^[:print:]]{7}/  REJECT 2047rfc',
  '/^.*=20[a-z]*=20[a-z]*=20[a-z]*=20[a-z]*/ REJECT 822rfc1',
  '/(.*)?\{6,\}/ REJECT 822rfc2',
  '/(.*)[X|x]\{3,\}/ REJECT 822rfc3',
  '#### Unreadable Language Types',
  '/^Subject:.*=\?(GB2312|big5|euc-kr|ks_c_5601-1987|koi8)\?/ REJECT NotReadable1',
  '/^Content-Type:.*charset="?(GB2312|big5|euc-kr|ks_c_5601-1987|koi8)/ REJECT NotReadable2',
  '#### Hidden Word Subject checks',
  '/^Subject:.*      / REJECT TooManySpaces',
  '/^Subject:.*r[ _\.\*\-]+o[ _\.\*\-]+l[ _\.\*\-]+e[ _\.\*\-]+x/ REJECT NoHiddenWords1',
  '/^Subject:.*p[ _\.\*\-]+o[ _\.\*\-]+r[ _\.\*\-]+n/ REJECT NoHiddenWords2',
  '#### Do not accept these types of attachments',
  '/^Content-(Type|Disposition):.*(file)?name=.*\.(bat|com|exe)/ REJECT Bad Attachment .${3}',
  ],
  smtp_tls_security_level   => may,
  smtpd_tls_key_file => '/etc/ssl/private/ssl-cert-snakeoil.key',
  smtpd_tls_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  postgrey              => true,
  #spamassassin          => false,
  # Send all emails to spampd on 10026
  #smtp_content_filter   => 'smtp:127.0.0.1:10026',
  # This is where we get emails back from spampd
  #master_services       => [ '127.0.0.1:10027 inet n  -       n       -      20       smtpd'],
  
}

augeas { "configure_postfix":
    context => "/files/etc/postfix/main.cf",
    changes => [ "set recipient_delimiter +",
		 "set default_process_limit 100",
		 "set smtpd_client_connection_count_limit 10",
		 "set smtpd_client_connection_rate_limit 30",
		 "set queue_minfree 20971520",
		 "set header_size_limit 51200",
		 "set message_size_limit 10485760",
		 "set smtpd_recipient_limit 100",
		 "set show_user_unknown_table_name no",
		 "set disable_vrfy_command yes",
		 "set smtpd_error_sleep_time 20",
		 "set smtpd_soft_error_limit 1",
		 "set smtpd_hard_error_limit 3",
		 "set smtpd_junk_command_limit 2",
		 "set policy-spf_time_limit 3600s",
                 "set smtp_tls_note_starttls_offer yes",
                 "set smtpd_tls_security_level may",
		 "set smtpd_tls_loglevel 1",
                 "set smtpd_tls_received_header yes",
		 "set content_filter scan:127.0.0.1:10025",
		 "set receive_override_options no_address_mappings",
	         "set smtpd_client_recipient_rate_limit 100",
		 "set smtpd_client_message_rate_limit 100",
		]
}

package { "postfix-policyd-spf-python":
  ensure => installed,
}
->
file_line { 'spf':
      path => '/etc/postfix/master.cf',
      line => 'policy-spf  unix  -       n       n       -       -       spawn',
      match => 'policy-spf',
}
->
file_line { 'spf1':
      path => '/etc/postfix/master.cf',
      line => '     user=nobody argv=/usr/bin/policyd-spf',
}

package { "dovecot-common":
  ensure => installed,
}
->
package { "dovecot-imapd":
  ensure => installed,
}
->
augeas { "dovecot_conf":
    context => "/files/etc/dovecot/conf.d/10-master.conf",
    changes => [ "set service[6]/unix_listener[1]  auth-userdb",
                 "set service[6]/unix_listener[2]  /var/spool/postfix/private/auth",
                 "set  service[6]/unix_listener[2]/mode  0660",
                 "set  service[6]/unix_listener[2]/user  postfix",
                 "set  service[6]/unix_listener[2]/group  postfix",
    ],
    require => [ Package["dovecot-common"] ]
}
->
file_line { 'dovecot_protocols':
      path => '/etc/dovecot/dovecot.conf',
      line => 'protocols = imap imaps',
      match => 'protocols =',
}
->
file_line { 'dovecot_maildir':
      path => '/etc/dovecot/conf.d/10-mail.conf',
      line => 'mail_location = maildir:~/Maildir',
      match => '^mail_location =',
}
->
augeas { "dovecot_ssl":
    context => "/files/etc/dovecot/conf.d/10-ssl.conf",
    changes => [ "set ssl yes",
                 "set  ssl_cert </etc/ssl/certs/ssl-cert-snakeoil.pem",
                 "set  ssl_key </etc/ssl/private/ssl-cert-snakeoil.key",
    ],
    require => [ Package["dovecot-common"] ]
}
->
service { "dovecot":
    ensure  => "running",
    enable  => "true",
}

package { "clamav":
  ensure => installed,
}
->
package { "clamsmtp":
  ensure => installed,
}
->
file_line { 'clamav1':
      path => '/etc/clamsmtpd.conf',
      line => 'OutAddress: 10027',
      match => 'OutAddress',
}
->
file_line { 'clamav2':
      path => '/etc/clamsmtpd.conf',
      line => 'Listen: 127.0.0.1:10025',
      match => '127.0.0.1',
}

file_line { 'clamav_master1':
      path => '/etc/postfix/master.cf',
      line => 'scan      unix  -       -       n       -       16      smtp',
}
->
file_line { 'clamav_master2':
      path => '/etc/postfix/master.cf',
      line => '  -o smtp_send_xforward_command=yes',
}
->
file_line { 'clamav_master3':
      path => '/etc/postfix/master.cf',
      line => '127.0.0.1:10027 inet n       -       n       -       16       smtpd',
}
->
file_line { 'clamav_master4':
      path => '/etc/postfix/master.cf',
      line => '  -o content_filter=',
}
->
file_line { 'clamav_master5':
      path => '/etc/postfix/master.cf',
      line => '  -o receive_override_options=no_unknown_recipient_checks,no_header_body_checks',
}
->
file_line { 'clamav_master6':
      path => '/etc/postfix/master.cf',
      line => '  -o smtpd_helo_restrictions=',
}
->
file_line { 'clamav_master7':
      path => '/etc/postfix/master.cf',
      line => '  -o smtpd_client_restrictions=',
}
->
file_line { 'clamav_master8':
      path => '/etc/postfix/master.cf',
      line => '  -o smtpd_sender_restrictions=',
}
->
file_line { 'clamav_master9':
      path => '/etc/postfix/master.cf',
      line => '  -o smtpd_recipient_restrictions=permit_mynetworks,reject',
}
->
file_line { 'clamav_master10':
      path => '/etc/postfix/master.cf',
      line => '  -o mynetworks_style=host',
}
->
file_line { 'clamav_master11':
      path => '/etc/postfix/master.cf',
      line => '  -o smtpd_authorized_xforward_hosts=127.0.0.0/8',
}
->
service { "clamsmtp":
    ensure  => "running",
    enable  => "true",
}


file_line { 'default_postgrey':
      path => '/etc/default/postgrey',
      line => 'POSTGREY_OPTS="--inet=127.0.0.1:60000 --delay=60"',
      match => 'POSTGREY_OPTS=',
}

file {'helo_access':
      path    => '/etc/postfix/helo_access',
      ensure  => present,
      mode    => 0644,
      content => "localhost REJECT_BadSender \n",
    }
->
file_line { 'helo_access1':
    path => '/etc/postfix/helo_access',
    line => '127.0.0.1 REJECT_BadSender',
}
exec { "create helo db":
   command => "/usr/sbin/postmap /etc/postfix/helo_access",
}

file {'client_access':
      path    => '/etc/postfix/client_restrictions',
      ensure  => present,
      mode    => 0644,
      content => "### WHITE LIST ### \n",
    }
->
file_line { 'client_access1':
    path => '/etc/postfix/client_restrictions',
    line => '/\.hotmail\.com$/      OK',
}
->
file_line { 'client_access2':
    path => '/etc/postfix/client_restrictions',
    line => '/\.google\.com$/       OK',
}
->
file_line { 'client_access3':
    path => '/etc/postfix/client_restrictions',
    line => '/\.yahoo\.com$/        OK',
}
->
file_line { 'client_access4':
    path => '/etc/postfix/client_restrictions',
    line => '### Generic Block of DHCP machines or those with many numbers in the hostname ###',
}
->
file_line { 'client_access5':
    path => '/etc/postfix/client_restrictions',
    line => '/^(dhcp|dialup|ppp|adsl|pool)[^.]*[0-9]/  550 S25R6 check',
}
->
file_line { 'client_access6':
    path => '/etc/postfix/client_restrictions',
    line => '### BLACK LIST known spammer friendly ISPs ###',
}
->
file_line { 'client_access7':
    path => '/etc/postfix/client_restrictions',
    line => '/\.(internetdsl|adsl|sdi)\.tpnet\.pl$/  550 domain check tpnet',
}
->
file_line { 'client_access8':
    path => '/etc/postfix/client_restrictions',
    line => '/^user.+\.mindspring\.com$/             550 domain check mind',
}
->
file_line { 'client_access9':
    path => '/etc/postfix/client_restrictions',
    line => '/[0-9a-f]{4}\.[a-z]+\.pppool\.de$/      550 domain check pppool',
}
->
file_line { 'client_access10':
    path => '/etc/postfix/client_restrictions',
    line => '/\.dip\.t-dialin\.net$/                 550 domain check t-dialin',
}
->
file_line { 'client_access11':
    path => '/etc/postfix/client_restrictions',
    line => '/\.(adsl|cable)\.wanadoo\.nl$/          550 domain check wanadoo',
}
