# Change the hostname and domain variables to match you systems' configuration
$server_hostname = "ubuntu"
$server_domain = "monaco.studlab.os3.nl"

node ubuntu {

  package { "clamav":
    ensure => installed,
  }

  package { "libsasl2-2":
    ensure => installed,
  }

  package { "sasl2-bin":
    ensure => installed,
  }

  package { "libsasl2-modules":
    ensure => installed,
  }

  package { "postfix-policyd-spf-python":
    ensure => installed,
  }


  include postfix

  postfix::config { "smtpd_tls_cert_file": value  => "/etc/ssl/certs/ssl-cert-snakeoil.pem" }
  postfix::config { "smtpd_tls_key_file": value  => "/etc/ssl/private/ssl-cert-snakeoil.key" }
  postfix::config { "smtpd_use_tls": value  => "yes" }
  postfix::config { "smtpd_tls_session_cache_database": value  => "btree:${data_directory}/smtpd_scache" }
  postfix::config { "smtp_tls_session_cache_database": value  => "btree:${data_directory}/smtp_scache" }
  
  postfix::config { "default_process_limit": value  => "100" }
  postfix::config { "smtpd_client_connection_count_limit": value  => "10" }
  postfix::config { "smtpd_client_connection_rate_limit": value  => "30" }
  postfix::config { "queue_minfree": value  => "20971520" }
  postfix::config { "header_size_limit": value  => "51200" }
  postfix::config { "message_size_limit": value  => "10485760" }
  postfix::config { "smtpd_recipient_limit": value  => "100" }
  postfix::config { "policy-spf_time_limit": value  => "3600s" }

  postfix::config { "content_filter": value  => "scan:127.0.0.1:10025" }
  postfix::config { "receive_override_options": value  => "no_address_mappings" }

  postfix::config { "bounce_size_limit": value  => "1000" }
  postfix::config { "mailbox_size_limit": value  => "0" }
  postfix::config { "bounce_queue_lifetime": value  => "4h" }
  postfix::config { "maximal_queue_lifetime": value  => "4h" }
  postfix::config { "delay_warning_time": value  => "1h" }
}