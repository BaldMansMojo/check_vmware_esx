sub cluster_list_vm_volumes_info
{
        my ($cluster, $blacklist) = @_;

        my $cluster_view = Vim::find_entity_view(view_type => 'ClusterComputeResource', filter => {name => "$cluster"}, properties => ['name', 'datastore']);

        if (!defined($cluster_view->datastore))
           {
           print "Insufficient rights to access Datastores on the Host\n";
           exit 2;
           }

        return datastore_volumes_info($cluster_view->datastore, $subselect, $blacklist);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
