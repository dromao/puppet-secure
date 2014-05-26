#Network that should be able to reach the server:
$network="145.100.105.240"
$mask="255.255.255.240"
$mask_length="28"

#Name of NFS share:
$share="nfs_share"

#Change name of node if needed
node ubuntu {

    class { 'nfs::server':
      nfs_v4=>true,
      nfs_v4_export_root_clients =>
        "${network}/${mask_length}(rw,fsid=root,insecure,no_subtree_check,async,no_root_squash)"
    }
    
    nfs::server::export{ $share:
      ensure  => 'mounted',
      clients => "${network}/${mask_length}(rw,secure,no_subtree_check,async,root_squash) localhost(rw)"
    }
    
    # Allow connection to rpcbind only from the allowed network
    file_line { 'deny_rpcbind':
      path => '/etc/hosts.deny',
      line => 'rpcbind: ALL',
    }
    
    file_line { 'allow_network_rpcbind':
      path => '/etc/hosts.allow',
      line => "rpcbind: ${network}/{$mask}",
    }
}
