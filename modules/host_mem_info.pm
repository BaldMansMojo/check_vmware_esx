sub host_mem_info
    {
    my ($host) = @_;
    my $state = 2;
    my $output = 'HOST MEM Unknown error';
    my $value;
    my $vm;
    my $host_view;
    my $vm_view;
    my $vm_views;
    my @vms = ();
    my $index;
    
    if (defined($subselect))
       {
       if ($subselect eq "usage")
          {
          $values = return_host_performance_values($host, 'mem', ('usage.average'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
             }

          if (defined($value))
             {
             $perfdata = $perfdata . " mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
             $output = "mem usage=" . $value . "%"; 
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
          
       if ($subselect eq "consumed")
          {
          $values = return_host_performance_values($host, 'mem', ('consumed.average'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             }
             
          if (defined($value))
             {
             $perfdata = $perfdata . " consumed_memory=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "consumed memory=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }

       if ($subselect eq "swapused")
          {
          ($host_view, $values) = return_host_performance_values($host, 'mem', ('swapused.average'));
          
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " mem_swap=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "swap used=" . $value . " MB: ";
             $state = check_against_threshold($value);
             if ($state != 0)
                {
                $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $$host_view[0], properties => ['name', 'runtime.powerState']);

                if (!defined($vm_views))
                   {
                   print "Runtime error\n";
                   exit 2;
                   }

                if (!@$vm_views)
                   {
                   print "There are no VMs.\n";
                   exit 2;
                   }

                @vms = ();
                foreach $vm (@$vm_views)
                        {
                        push(@vms, $vm) if ($vm->get_property('runtime.powerState')->val eq "poweredOn");
                        }
             
                $values = generic_performance_values(\@vms, 'mem', ('swapped.average'));
                if (defined($values))
                   {
                   foreach $index (0..@vms-1)
                           {
                           $value = simplify_number(convert_number($$values[$index][0]->value) / 1024);
                           if ($value > 0)
                              {
                              $output = $output . $vms[$index]->name . " (" . $value . "MB), " if ($value > 0);
                              }
                           }
                   }
                }
             chop($output);
             chop($output);
             }
          return ($state, $output);
          }

       if ($subselect eq "overhead")
          {
          $values = return_host_performance_values($host, 'mem', ('overhead.average'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " mem_overhead=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "overhead=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }

       if ($subselect eq "memctl")
          {
          ($host_view, $values) = return_host_performance_values($host, 'mem', ('vmmemctl.average'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " mem_memctl=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "memctl=" . $value . " MB: ";
             $state = check_against_threshold($value);
             if ($state != 0)
                {
                $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $$host_view[0], properties => ['name', 'runtime.powerState']);

                if (!defined($vm_views))
                   {
                   print "Runtime error\n";
                   exit 2;
                   }

                if (!@$vm_views)
                   {
                   print "There are no VMs.\n";
                   exit 2;
                   }

                foreach $vm (@$vm_views)
                        {
                        if ($vm->get_property('runtime.powerState')->val eq "poweredOn")
                           {
                           push(@vms, $vm) if ($vm->get_property('runtime.powerState')->val eq "poweredOn");
                           }
                        }
                $values = generic_performance_values(\@vms, 'mem', ('vmmemctl.average'));

                if (defined($values))
                   {
                   foreach $index (0..@vms-1)
                           {
                           $value = simplify_number(convert_number($$values[$index][0]->value) / 1024);
                           if ($value > 0)
                              {
                              $output = $output . $vms[$index]->name . " (" . $value . "MB), ";
                              }
                           }
                   }
                }
             chop($output);
             chop($output);
             }
          return ($state, $output);
          }
       # So we have decided to use a subselect but submitted no valid one we have to leave,
       get_me_out("Unknown HOST MEM subselect");
       }
    else
       {
        if ($perf_thresholds ne ';')
           {
           print_help();
           print "\nERROR! Thresholds only allowed with subselects!\n\n";
           exit 2;
           }

       $values = return_host_performance_values($host, 'mem', ('consumed.average', 'usage.average', 'overhead.average', 'swapused.average', 'vmmemctl.average'));
       
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
          $perfdata = $perfdata . " consumed_memory=" . $value . "MB;;;";
          $output = "consumed memory=" . $value  . " MB (";

          $value = simplify_number(convert_number($$values[0][1]->value) * 0.01);
          $perfdata = $perfdata . " mem_usage=" . $value . "%;;;";
          $output = $output . $value . "%), overhead=";

          $value = simplify_number(convert_number($$values[0][2]->value) / 1024);
          $perfdata = $perfdata . " mem_overhead=" . $value . "MB;;;";
          $output = $output . $value . " MB, swap used=";

          $value = simplify_number(convert_number($$values[0][3]->value) / 1024);
          $perfdata = $perfdata . " mem_swap=" . $value . "MB;;;";
          $output = $output . $value . " MB, memctl=";

          $value = simplify_number(convert_number($$values[0][4]->value) / 1024);
          $perfdata = $perfdata . " mem_memctl=" . $value . "MB;;;";
          $output = $output . $value . " MB";

          $state = 0;
          }
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
