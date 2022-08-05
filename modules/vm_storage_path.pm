sub vm_storage_path
    {
    my ($vmname) = @_;
    my $output;
    my $storage;
    my $storage_array;
    my $storage_path=" ";
    
    my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine', filter => {name => $vmname}, properties => ['name', 'storage']);

    if (defined($vm_view))
       {
       $storage_array = $vm_view->storage->perDatastoreUsage;
   
       if (defined $storage_array)
          {
          foreach $storage (@{$storage_array})
                  {
                  $storage_path = $storage->datastore->value;
                  }
       
          $storage_path =~ s/^.*://;
          }
          
       $output = $storage_path;
       }
       else
       {
       $output = "No storage information available";
       }
    
    return ($output);
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;

