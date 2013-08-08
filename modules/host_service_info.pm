sub host_service_info
    {
    my ($host) = @_;
    my $state = 2;
    my $output = 'HOST service info unknown error';
    my $services;
    my $srvname;
    my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'configManager', 'runtime.inMaintenanceMode']);

    if (!defined($host_view))
       {
       print "Host " . $$host{"name"} . " does not exist\n";
       exit 2;
       }

    if (uc($host_view->get_property('runtime.inMaintenanceMode')) eq "TRUE")
       {
       print "Notice: " . $host_view->name . " is in maintenance mode, check skipped\n";
       exit 0;
       }

    $services = Vim::get_view(mo_ref => $host_view->configManager->serviceSystem, properties => ['serviceInfo'])->serviceInfo->service;

    if (defined($subselect))
       {
       $subselect = ',' . $subselect . ',';
       $output = '';
       foreach (@$services)
               {
               $srvname = $_->key;
               if ($subselect =~ s/,$srvname,/,/g)
                  {
                  while ($subselect =~ s/,$srvname,/,/g){};
                                $output = $output . $srvname . ", " if (!$_->running);
                        }
                }
                $subselect =~ s/^,//;
                chop($subselect);

                if ($subselect ne '')
                {
                        $state = 3;
                        $output = "unknown services : $subselect";
                }
                elsif ($output eq '')
                {
                        $state = 0;
                        $output = "All services are in their apropriate state.";
                }
                else
                {
                        chop($output);
                        chop($output);
                        $output = $output . " are down";
                }
        }
        else
        {
                my %service_state = (0 => "down", 1 => "up");
                $state = 0;
                $output = "services : ";
                $output = $output . $_->key . " (" . $service_state{$_->running} . "), " foreach (@$services);
                chop($output);
                chop($output);
        }

        return ($state, $output);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
