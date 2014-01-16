sub dc_list_vm_volumes_info
    {
    my $dc_views;
    my @datastores;
    my $dc;

    $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['datastore']);
    
    if (!defined($dc_views))
       {
       print "There are no Datacenter\n";
       exit 2;
       }

    foreach $dc (@$dc_views)
            {
            if (defined($dc->datastore))
               {
               push(@datastores, @{$dc->datastore});
               }
            }

    return datastore_volumes_info(\@datastores);
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
