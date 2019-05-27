sub get_key_metrices
    {
    my ($perfmgr_view, $group, @names) = @_;

    my $perfCounterInfo = $perfmgr_view->perfCounter;
    my @counters;
    my $cur_name;
    my $index;

    if (!defined($perfCounterInfo))
       {
       print "Insufficient rights to access perfcounters\n";
       exit 2;
       }

    foreach (@$perfCounterInfo)
            {
            if ($_->groupInfo->key eq $group)
               {
               $cur_name = $_->nameInfo->key . "." . $_->rollupType->val;
               foreach $index (0..@names-1)
                       {
                       if ($names[$index] =~ /$cur_name/)
                          {
                          $names[$index] =~ /(\w+).(\w+):*(.*)/;
                          $counters[$index] = PerfMetricId->new(counterId => $_->key, instance => $3);
                          }
                       }
               }
            }

    return \@counters;
    }

sub generic_performance_values
    {
    my ($views, $group, @list) = @_;
    my $amount = @list;
    my $counter = 0;
    my @host_values;
    my $id;
    my $index;
    my $metrices;
    my $perfargs;
    my $perf_interval;
    my $perfMgr = $perfargs->{perfCounter};
    my @perf_query_spec;
    my $unsorted;
    my $perf_data;
    my @values = ();

    if (!defined($perfMgr))
       {
       $perfMgr = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager, properties => [ 'perfCounter' ]);
       $perfargs->{perfCounter} = $perfMgr;
       }
     
    $metrices = get_key_metrices($perfMgr, $group, @list);

    @perf_query_spec = ();

       foreach (@$views)
               {
               push(@perf_query_spec, PerfQuerySpec->new(entity => $_, metricId => $metrices, format => 'csv', intervalId => 20, maxSample => 1));
               }

        $perf_data = $perfMgr->QueryPerf(querySpec => \@perf_query_spec);
        $amount *= @$perf_data;

        while (@$perf_data)
              {
              $unsorted = shift(@$perf_data)->value;
              @host_values = ();

              foreach $id (@$unsorted)
                      {
                      foreach $index (0..@$metrices-1)
                              {
                              if ($id->id->counterId == $$metrices[$index]->counterId)
                                 {
                                 if (!defined($host_values[$index]))
                                    {
                                    $counter++;
                                    }
                                 $host_values[$index] = $id;
                                 }
                              }
                      }
              push(@values, \@host_values);
              }
        if ($counter != $amount || $counter == 0)
           {
           return undef;
           }
        else
           {
           return \@values;
           }
    }

sub return_host_performance_values
    {
    my $values;
    my $host_name = shift(@_);
    my $maintenance_mode_state = shift(@_);
    my $host_view;

    $host_view = Vim::find_entity_views(view_type => 'HostSystem', filter => $host_name, properties => (['name', 'runtime.inMaintenanceMode']) ); # Added properties named argument.

    if (!defined($maintenance_mode_state))
       {
       $maintenance_mode_state = 0;
       }
    if (!defined($host_view))
       {
       print "Runtime error\n";
       exit 2;
       }

    if (!@$host_view)
       {
       print "Host " . $$host_name{"name"} . " does not exist\n";
       exit 2;
       }

    if (($$host_view[0]->get_property('runtime.inMaintenanceMode')) eq "true")
       {
       print "Notice: " . $$host_view[0]->name . " is in maintenance mode, check skipped\n";
       exit $maintenance_mode_state;
       }

    $values = generic_performance_values($host_view, @_);

    if ($@)
       {
       return undef;
       }
    else
       {
       return ($host_view, $values);
       }
    }

sub return_host_vmware_performance_values
    {
    my $values;
    my $vmname = shift(@_);
    my $vm_view;
        
    $vm_view = Vim::find_entity_views(view_type => 'VirtualMachine', filter => {name => "$vmname"}, properties => [ 'name', 'runtime.powerState' ]);

    if (!defined($vm_view))
       {
       print "Runtime error\n";
       exit 2;
       }

    if (!@$vm_view)
       {
       print "VMware machine " . $vmname . " does not exist\n";
       exit 2;
       }

    if ($$vm_view[0]->get_property('runtime.powerState')->val ne "poweredOn")
       {
       print "VMware machine " . $vmname . " is not running. Current state is " . $$vm_view[0]->get_property('runtime.powerState')->val . "\n";
       exit 2;
       }

    $values = generic_performance_values($vm_view, @_);

    if ($@)
       {
       return $@;
       }
    else
       {
       return ($vm_view, $values);
       }
    }

sub return_cluster_performance_values
    {

    my $values;
    my $cluster_name = shift(@_);
    my $cluster_view; # Added properties named argument.

    $cluster_view = Vim::find_entity_views(view_type => 'ClusterComputeResource', filter => { name => "$cluster_name" }, properties => [ 'name' ]); # Added properties named argument.

    if (!defined($cluster_view))
       {
       print "Runtime error\n";
       exit 2;
       }

    if (!@$cluster_view)
       {
       print "Cluster " . $cluster_name . " does not exist\n";
       exit 2;
       }
        
    $values = generic_performance_values($cluster_view, @_);

    if ($@)
       {
       return undef;
       }
    else
       {
       return ($values);
       }
    }


# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
