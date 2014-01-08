sub vm_mem_info
    {
    my ($vmname) = @_;
    my $state = 0;
    my $output;
    my $value;
    my $actual_state;            # Hold the actual state for to be compared
    my $true_sub_sel=1;          # Just a flag. To have only one return at the en
                                 # we must ensure that we had a valid subselect. If
                                 # no subselect is given we select all
                                 # 0 -> existing subselect
                                 # 1 -> non existing subselect

    $values = return_host_vmware_performance_values($vmname, 'mem', ('usage.average', 'consumed.average', 'overhead.average', 'active.average', 'vmmemctl.average'));
        
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
             $perfdata ="mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "mem usage=" . $value . "%"; 
             $perfdata ="mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
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
    
    if (($subselect eq "overhead") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][2]->value) / 1024);
          if ($subselect eq "all")
             {
             $output = $output . " - mem overhead=" . $value . " MB";
             $perfdata = $perfdata . " mem_overhead=" . $value . "MB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "mem overhead=" . $value . " MB";
             $perfdata = "mem_overhead=" . $value . "MB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       }
    
    if (($subselect eq "active") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][3]->value) / 1024);
          if ($subselect eq "all")
             {
             $output = $output . " - mem active=" . $value . " MB";
             $perfdata = $perfdata . " mem_active=" . $value . "MB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "mem active=" . $value . " MB";
             $perfdata = "mem_active=" . $value . "MB;" . $perf_thresholds . ";;";
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
             $output = $output . " - memctl=" . $value . " MB";
             $perfdata = $perfdata . " memctl=" . $value . "MB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "memctl=" . $value . " MB";
             $perfdata = "memctl=" . $value . "MB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown VM MEM subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
