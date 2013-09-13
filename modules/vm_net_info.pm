sub vm_net_info
    {
    my ($vmname) = @_;
    my $state = 2;
    my $output;
    my $value;

    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       if ( $perf_thresholds ne ";")
          {
          print "Error! Thresholds are only allowed with subselects!\n";
          }
       }

    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       $values = return_host_vmware_performance_values($vmname, 'net', ('usage.average:*'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " net_usage=" . $value . $perf_thresholds . ";;";
          $output = "$vmname: net usage=" . $value . " KBps"; 
          if ($subselect ne "all")
             {
             $state = check_against_threshold($value);
             }
          }
       if ($subselect ne "all")
          {
          return ($state, $output);
          }
       }

    if (($subselect eq "RECEIVE") || ($subselect eq "all"))
       {
       $values = return_host_vmware_performance_values($vmname, 'net', ('received.average:*'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " net_receive=" . $value . $perf_thresholds . ";;";
          if ($subselect ne "all")
             {
             $output = "$vmname: net receive=" . $value . " KBps"; 
             $state = check_against_threshold($value);
             }
          else
             {
             $output = $output . ", net receive=" . $value . " KBps"; 
             }
           }
       if ($subselect ne "all")
          {
          return ($state, $output);
          }
       }

    if (($subselect eq "send") || ($subselect eq "all"))
       {
       $values = return_host_vmware_performance_values($vmname, 'net', ('transmitted.average:*'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " net_send=" . $value . $perf_thresholds . ";;";
          if ($subselect ne "all")
             {
             $output = "$vmname: net send=" . $value . " KBps"; 
             $state = check_against_threshold($value);
             }
          else
             {
             $output =$output . ", net send=" . $value . " KBps"; 
             }
          }
       return ($state, $output);
       }

    if ($subselect ne "all")
       {
       get_me_out("Unknown HOST-VM NET subselect");
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;