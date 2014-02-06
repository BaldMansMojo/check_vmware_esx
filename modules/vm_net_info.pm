sub vm_net_info
    {
    my ($vmname) = @_;
    my $state = 0;
    my $output;
    my $value;
    my $values;
    my $actual_state;            # Hold the actual state for to be compared
    my $true_sub_sel=1;          # Just a flag. To have only one return at the en
                                 # we must ensure that we had a valid subselect. If
                                 # no subselect is given we select all
                                 # 0 -> existing subselect
                                 # 1 -> non existing subselect

    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       $true_sub_sel = 0;
       if ( $perf_thresholds ne ";")
          {
          print "Error! Thresholds are only allowed with subselects!\n";
          }
       }

    $values = return_host_vmware_performance_values($vmname, 'net', ('usage.average:', 'received.average:*', 'transmitted.average:*'));

    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          if ($subselect eq "all")
             {
             $output = "net usage=" . $value . " KBps"; 
             $perfdata = $perfdata . " \'net_usage\'=" . $value . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "net usage=" . $value . " KBps"; 
             $perfdata = "\'net_usage\'=" . $value . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          $actual_state = 3;
          $output = "net usage=Not available"; 
          $state = check_state($state, $actual_state);
          }
       }

    if (($subselect eq "receive") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][1]->value));
          if ($subselect eq "all")
             {
             $output = $output . ", net receive=" . $value . " KBps"; 
             $perfdata = $perfdata . " \'net_receive\'=" . $value . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "net receive=" . $value . " KBps"; 
             $perfdata = "\'net_receive\'=" . $value . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " net receive=Not available"; 
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "net receive=Not available"; 
             $state = check_state($state, $actual_state);
             }
          }
       }

    if (($subselect eq "send") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][2]->value));
          if ($subselect eq "all")
             {
             $output =$output . ", net send=" . $value . " KBps"; 
             $perfdata = $perfdata . " \'net_send\'=" . $value . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "net send=" . $value . " KBps"; 
             $perfdata = "\'net_send\'=" . $value . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output =$output . ", net send=Not available"; 
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "net send=Not available"; 
             $state = check_state($state, $actual_state);
             }
          }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown HOST-VM NET subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
