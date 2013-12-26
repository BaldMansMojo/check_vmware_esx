sub host_service_info
    {
    my ($host) = @_;
    my $state = 0;
    my $output;
    my $services;
    my $service_name;
    my $service_state;
    my %service_state = (0 => "down", 1 => "up");
    my $service_count = 0;
    my $alert_count = 0;;

    my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'configManager', 'runtime.inMaintenanceMode']);

    if (!defined($host_view))
       {
       print "Host " . $$host{"name"} . " does not exist\n";
       exit 2;
       }

    if (($host_view->get_property('runtime.inMaintenanceMode')) eq "true")
       {
       print "Notice: " . $host_view->name . " is in maintenance mode, check skipped\n";
       exit 0;
       }

    $services = Vim::get_view(mo_ref => $host_view->configManager->serviceSystem, properties => ['serviceInfo'])->serviceInfo->service;

    foreach (@$services)
            {
            $service_name = $_->key;
            $service_state = $_->running;

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
               if (isblacklisted(\$blacklist, $isregexp, $service_name))
                  {
                  next;
                  }
               }
            if (defined($whitelist))
               {
               if (isnotwhitelisted(\$whitelist, $isregexp, $service_name))
                  {
                  next;
                  }
               }
            $service_count++;
            if ($service_state == 0)
               {
               $state = 2;
               $state = check_state($state, $service_state);
               $alert_count++;
               }
            if (!$output)
               {
               $output = $multiline . $service_name . " (" . $service_state{$service_state} . ")";
               }
            else
               {
               $output = $output . $multiline . $service_name . " (" . $service_state{$service_state} . ")";
               }
            }

    # An alert should only be caused if the selection is more specific.. Otherwise you will have an alert for every
    # b...shit.

    if (!((defined($blacklist)) || (defined($whitelist))))
       {
       $state = 0;
       }
       
    $output = "Checked services:(" . $service_count . ") Services up:(" . ($service_count - $alert_count) . ") Services down:(" . $alert_count . ")" . $output;


    return ($state, $output);
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
