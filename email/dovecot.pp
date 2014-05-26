node ubuntu {

  include dovecot 

  class { dovecot::ssl:
    ssl          => 'yes',
    ssl_keyfile  => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_certfile => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  }
}