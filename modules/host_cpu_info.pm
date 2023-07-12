sub host_cpu_info
    {
    my ($host, $maintenance_mode_state) = @_;
    my $state = 0;
    my $output;
    my $host_view;
    my $value;
    my $perf_val_error = 1;      # Used as a flag when getting all the values 
                                 # with one call won't work.
    my $actual_state;            # Hold the actual state for to be compared
    my $true_sub_sel=1;          # Just a flag. To have only one return at the en
                                 # we must ensure that we had a valid subselect. If
                                 # no subselect is given we select all
                                 # 0 -> existing subselect
                                 # 1 -> non existing subselect

    $values = return_host_performance_values($host, $maintenance_mode_state, 'cpu', ('wait.summation:*','ready.summation:*','readiness.average', 'usage.average'));
        
    if (defined($values))
       {
       $perf_val_error = 0;
       }
       
    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       $true_sub_sel = 0;
       }

    if (($subselect eq "wait") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;

       if ($perf_val_error == 1)
          {
          $values = return_host_performance_values($host, $maintenance_mode_state, 'cpu', ('wait.summation:*'));
          }

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
             $output = "CPU wait=" . $value . " ms";
             $perfdata ="\'cpu_wait\'=" . $value . "ms;" . $perf_thresholds . ";;";
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

       if ($perf_val_error == 1)
          {
          $values = return_host_performance_values($host, $maintenance_mode_state, 'cpu', ('ready.summation:*'));
          }

       if (defined($values))
          {
          if ($perf_val_error == 1)
             {
             $value = simplify_number(convert_number($$values[0][0]->value));
             }
          else
             {
             $value = simplify_number(convert_number($$values[0][1]->value));
             }

          if ($subselect eq "all")
             {
             $output = $output . " - CPU ready=" . $value . " ms";
             $perfdata = $perfdata . " \'cpu_ready\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $output = "CPU ready=" . $value . " ms";
             $perfdata = "\'cpu_ready\'=" . $value . "ms;" . $perf_thresholds . ";;";
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

       if ($perf_val_error == 1)
          {
          $values = return_host_performance_values($host, $maintenance_mode_state, 'cpu', ('usage.average'));
          }

       if (defined($values))
          {
          if ($perf_val_error == 1)
             {
             $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
             }
          else
             {
             $value = simplify_number(convert_number($$values[0][2]->value) * 0.01);
             }

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

    if (($subselect eq "readiness") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;

       if ($perf_val_error == 1)
          {
          $values = return_host_performance_values($host, $maintenance_mode_state, 'cpu', ('readiness.average'));
          }

       if (defined($values))
          {
          if ($perf_val_error == 1)
             {
             $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
             }
          else
             {
             $value = simplify_number(convert_number($$values[0][3]->value) * 0.01);
             }

          if ($subselect eq "all")
             {
             $output = $output . " - CPU readiness=" . $value . "%"; 
             $perfdata = $perfdata . " \'cpu_readiness\'=" . $value . "%;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "CPU readiness=" . $value . "%"; 
             $perfdata = "\'cpu_readiness\\'=" . $value . "%;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - CPU readiness=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "CPU readiness=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown HOST CPU subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
