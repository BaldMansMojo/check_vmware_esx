sub host_mounted_media_info
    {
    my ($host, $maintenance_mode_state) = @_;
    my $count = 0;
    my $state;
    my $output;
    my $host_view;
    my $vm_views;
    my $vm;
    my $istemplate;
    my $match;
    my $displayname;
    my $devices;
   
    $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'runtime.inMaintenanceMode']);
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

    $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $host_view, properties => ['name', 'config.template', 'config.hardware.device', 'runtime.powerState']);

    if (!defined($vm_views))
       {
       print "Runtime error\n";
       exit 2;
       }
    $output = '';
      
    foreach $vm (@$vm_views)
            {
            # change get_property to {} to avoid infinite loop
            $istemplate = $vm->{'config.template'};
            
            if ($istemplate && ($istemplate eq 'true'))
               {
               next;
               }
            
            $match = 0;
            $displayname = $vm->name;

            if (defined($isregexp))
               {
               $isregexp = 1;
               }
            else
               {
               $isregexp = 0;
               }
               
            if (defined($blacklist))
               {
               if (isblacklisted(\$blacklist, $isregexp, $displayname))
                  {
                  next;
                  }
               }
            if (defined($whitelist))
               {
               if (isnotwhitelisted(\$whitelist, $isregexp, $displayname))
                  {
                  next;
                  }
               }
            $devices = $vm->{'config.hardware.device'};
            foreach $dev (@$devices)
                    {
                    if ((ref($dev) eq "VirtualCdrom") && ($dev->connectable->connected == 1))
                       {
                       $match++;
                       }
                    if ((ref($dev) eq "VirtualFloppy") && ($dev->connectable->connected == 1))
                       {
                       $match++;
                       }
                    }
            if ($match)
               {
               $count++;
               $output = "$displayname(Hits: $match)" . $multiline . $output;
               }
               else
               {
               if ($listall)
                  {
                  $output = $output . "$displayname(Hits: $match)" . $multiline;
                  }
               }
            }

    #Cut the last multiline of $output. Second line is better than 2 time chop() like the original :-)
    if ($output ne '')
       {
       $output  =~ s/<br>$//i;
       $output  =~ s/\n$//i;
       }

    if ($count)
       {
       $output = "VMs mounted host media devices (floppy, cd or dvd):" . $multiline . $output;
       $state = 1;
       }
    else
       {
       if ($listall)
          {
          $output = "No VMs with mounted host media devices (floppy, cd or dvd) found VMs." . $multiline . $output;
          }
       else
          {
          $output = "No VMs with mounted host media devices (floppy, cd or dvd) found.";
          }
       $state = 0;
       }

    return ($state, $output);
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
