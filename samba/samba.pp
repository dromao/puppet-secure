#Secure Samba Server

#Name of node, need to be changed!
node ubuntu {
  class {'samba::server':
    workgroup => 'SecureGroup', #Not default for security
    server_string => "Secure Samba Server",
    interfaces => "eth0 lo", #Restrict interfaces
    bind_interfaces_only => 'yes', #Only bind to the named interfaces and/or networks
    unix_password_sync => 'yes',
  }

  samba::server::share {'secure-share':
    comment => 'Secure Share',
    path => '/mnt/share',
    guest_ok => false, #To require password for each user
    browsable => false, #The share cannot be seen in the list of available shares in a net view and in the browse list.
    create_mask => 0700,
    directory_mask => 0700,
    read_only => '', #Enable if you want the file to remain unspoilt
    writable => true, #Enable to create or modify files
    write_list => '', #List of uses that can create or modify files
#   read_list => '', #List of uses that can only read the files
    valid_users => '', #List of users that are allowed to login to this service.
    require => [ Class['samba::server'], File_line['conf1'], File_line['conf2'], File_line['conf3'], File_line['conf4'], File_line['conf5'], File_line['conf6'], File_line['conf7'], File_line['conf8'], File_line['conf9'], File_line['conf10'], File_line['conf11'], File_line['conf12'], File_line['conf13'], File_line['conf14'], File_line['conf15'], File_line['conf16'] ]
  }


file_line { 'conf1':
      path => '/etc/samba/smb.conf',
      line => '   dns proxy = no',
      require => Class['samba::server'],
}

file_line { 'conf2':
      path => '/etc/samba/smb.conf',
      line => '   log file = /var/log/samba/log.%m',
      require => Class['samba::server'],
}

file_line { 'conf3':
      path => '/etc/samba/smb.conf',
      line => '   max log size = 1000',
      require => Class['samba::server'],
}

file_line { 'conf4':
      path => '/etc/samba/smb.conf',
      line => '   syslog = 0',
      require => Class['samba::server'],
}

file_line { 'conf5':
      path => '/etc/samba/smb.conf',
      line => '   panic action = /usr/share/samba/panic-action %d',
      require => Class['samba::server'],
}

file_line { 'conf6':
      path => '/etc/samba/smb.conf',
      line => '   server role = standalone server',
      require => Class['samba::server'],
}

file_line { 'conf7':
      path => '/etc/samba/smb.conf',
      line => '   passdb backend = tdbsam',
      require => Class['samba::server'],
}

file_line { 'conf8':
      path => '/etc/samba/smb.conf',
      line => '   obey pam restrictions = yes',
      require => Class['samba::server'],
}

file_line { 'conf9':
      path => '/etc/samba/smb.conf',
      line => '   unix password sync = yes',
      require => Class['samba::server'],
}

file_line { 'conf10':
      path => '/etc/samba/smb.conf',
      line => '   passwd program = /usr/bin/passwd %u',
      require => Class['samba::server'],
}

file_line { 'conf11':
      path => '/etc/samba/smb.conf',
      line => '   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .',
      require => Class['samba::server'],
}

file_line { 'conf12':
      path => '/etc/samba/smb.conf',
      line => '   pam password change = yes',
      require => Class['samba::server'],
}

file_line { 'conf13':
      path => '/etc/samba/smb.conf',
      line => '   map to guest = bad user',
      require => Class['samba::server'],
}

file_line { 'conf14':
      path => '/etc/samba/smb.conf',
      line => '   usershare allow guests = no',
      require => Class['samba::server'],
}

#Hosts that allowed to connect to the server
file_line { 'conf15':
      path => '/etc/samba/smb.conf',
      line => '   hosts allow = # allowed hosts',
      require => Class['samba::server'],
}

#Hosts that denied access to the server
file_line { 'conf16':
      path => '/etc/samba/smb.conf',
      line => '   hosts deny = # denied hosts',
      require => Class['samba::server'],
}

}
