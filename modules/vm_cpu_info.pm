sub vm_cpu_info
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
 
    $values = return_host_vmware_performance_values($vmname,'cpu', ('wait.summation:*','ready.summation:*', 'usage.average'));

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

    if (($subselect eq "wait") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          if ($subselect eq "all")
             {
             $output = "CPU wait=" . $value . " ms";
             $perfdata = "\'cpu_wait\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "CPU wait=" . $value . " ms";
             $perfdata = "\'cpu_wait\'=" . $value . "ms;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          $actual_state = 3;
          $output = "CPU wait=Not available";
          $state = check_state($state, $actual_state);
          }
       }

    if (($subselect eq "ready") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][1]->value));
          if ($subselect eq "all")
             {
             $output = $output . " - CPU ready=" . $value . " ms";
             $perfdata = $perfdata . " \'cpu_ready\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "CPU ready=" . $value . " ms";
             $perfdata = "\'cpu_ready\'=" . $value . "ms;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - CPU ready=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "CPU ready=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][2]->value) * 0.01);
          if ($subselect eq "all")
             {
             $output = $output . " - CPU usage=" . $value . "%"; 
             $perfdata = $perfdata . " \'cpu_usage\'=" . $value . "%;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "CPU usage=" . $value . "%"; 
             $perfdata = "\'cpu_usage\'=" . $value . "%;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - CPU usage=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "CPU usage=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown VM CPU subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
