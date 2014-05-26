# Change the administrator password:
$admin_password='securepassword'

# Set the username of the new administrator (previously root):
$new_admin='admin'



# Change hostname if needed!
node ubuntu {

class { '::mysql::server':
    root_password    => $admin_password,
    override_options => { 
        'client' => {
            'local-infile' => '0',
        },
        'mysqld' => {
             'bind-address' => '127.0.0.1',
        }
    },
    restart => 'true',
    remove_default_accounts => 'true',
}


# Rename root user to admin
exec { "rename_root":
    command => "/usr/bin/mysql --user='root' --password='$admin_password' -e 'rename user 'root'@'localhost' to '${new_admin}'@'localhost';'",
    require => Class['::mysql::server'],
}

notify {"The root user is now ${new_admin}.":
    require => Exec['rename_root'],
}
}
