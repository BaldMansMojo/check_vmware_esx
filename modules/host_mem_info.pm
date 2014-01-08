sub host_mem_info
    {
    my ($host) = @_;
    my $state = 0;
    my $output;
    my $value;
    my $vm;
    my $host_view;
    my $vm_view;
    my $vm_views;
    my @vms = ();
    my $index;
    my $actual_state;            # Hold the actual state for to be compared
    my $true_sub_sel=1;          # Just a flag. To have only one return at the en
                                 # we must ensure that we had a valid subselect. If
                                 # no subselect is given we select all
                                 # 0 -> existing subselect
                                 # 1 -> non existing subselect
    
    ($host_view, $values) = return_host_performance_values($host, 'mem', ( 'usage.average', 'consumed.average','swapused.average', 'overhead.average', 'vmmemctl.average'));

    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       $true_sub_sel = 0;
       if ($perf_thresholds ne ';')
          {
          print_help();
          print "\nERROR! Thresholds only allowed with subselects!\n\n";
          exit 2;
          }
       }

    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
          if ($subselect eq "all")
             {
             $output = "mem usage=" . $value . "%"; 
             $perfdata = "mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "mem usage=" . $value . "%"; 
             $perfdata = "mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       }
       
    if (($subselect eq "consumed") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][1]->value) / 1024);
          if ($subselect eq "all")
             {
             $output = $output . " - consumed memory=" . $value . " MB";
             $perfdata = $perfdata . " consumed_memory=" . $value . "MB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "consumed memory=" . $value . " MB";
             $perfdata = "consumed_memory=" . $value . "MB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if (($subselect eq "swapused") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][2]->value) / 1024);
          if ($subselect eq "all")
             {
             $output = $output . " - swap used=" . $value . " MB";
             $perfdata = $perfdata . " mem_swap=" . $value . "MB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "swap used=" . $value . " MB";
             $perfdata = "mem_swap=" . $value . "MB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);

             if ($actual_state != 0)
                {
                $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $$host_view[0], properties => ['name', 'runtime.powerState']);
   
                if (defined($vm_views))
                   {
                   if (@$vm_views)
                      {
                      @vms = ();
                      foreach $vm (@$vm_views)
                              {
                              if ($vm->get_property('runtime.powerState')->val eq "poweredOn")
                                 {
                                 push(@vms, $vm);
                                 }
                              }
                   
                      $values = generic_performance_values(\@vms, 'mem', ('swapped.average'));
                      if (defined($values))
                         {
                         foreach $index (0..@vms-1)
                                 {
                                 $value = simplify_number(convert_number($$values[$index][0]->value) / 1024);
                                 if ($value > 0)
                                    {
                                    if ($value > 0)
                                       {
                                       $output = $output . $multiline . $vms[$index]->name . " (" . $value . "MB)";
                                       }
                                    }
                                 }
                         }
                      }
      
                   }
                }
             }
          }
       }

    if (($subselect eq "overhead") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][3]->value) / 1024);
          if ($subselect eq "all")
             {
             $output = $output . " - overhead=" . $value . " MB";
             $perfdata = $perfdata . " mem_overhead=" . $value . "MB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "overhead=" . $value . " MB";
             $perfdata = "mem_overhead=" . $value . "MB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if (($subselect eq "memctl") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][4]->value) / 1024);
          if ($subselect eq "all")
             {
             $output = $output . " - memctl=" . $value . " MB: ";
             $perfdata = $perfdata . " mem_memctl=" . $value . "MB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "memctl=" . $value . " MB";
             $perfdata = "mem_memctl=" . $value . "MB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);

             if ($actual_state != 0)
                {
                $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $$host_view[0], properties => ['name', 'runtime.powerState']);
   
                if (defined($vm_views))
                   {
                   if (@$vm_views)
                      {
                      foreach $vm (@$vm_views)
                              {
                              if ($vm->get_property('runtime.powerState')->val eq "poweredOn")
                                 {
                                 push(@vms, $vm);
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
                                    $output = $output . $multiline . $vms[$index]->name . " (" . $value . "MB)";
                                    }
                                 }
                         }
                      }
                   }
                }
             }
          }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown HOST MEM subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
