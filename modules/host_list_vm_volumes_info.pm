sub host_list_vm_volumes_info
    {
    my ($host, $maintenance_mode_state) = @_;
    my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'datastore', 'runtime.inMaintenanceMode']);

    if (!defined($host_view))
       {
       print "Host " . $$host{"name"} . " does not exist\n";
       exit 2;
       }

    if (($host_view->get_property('runtime.inMaintenanceMode')) eq "true")
       {
       print "Notice: " . $host_view->name . " is in maintenance mode, check skipped\n";
       exit $maintenance_mode_state;
       }

    if (!defined($host_view->datastore))
       {
       print "Insufficient rights to access Datastores on the Host\n";
       exit 2;
       }

    return datastore_volumes_info($host_view->datastore);
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
