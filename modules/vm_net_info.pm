sub vm_net_info
    {
    my ($vmname) = @_;
    my $state = 0;
    my $output;
    my $value;
    my $values;

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

    $values = return_host_vmware_performance_values($vmname, 'net', ('usage.average:', 'received.average:*', 'transmitted.average:*'));

    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " \'net_usage\'=" . $value . $perf_thresholds . ";;";
          $output = "net usage=" . $value . " KBps"; 
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

    if (($subselect eq "receive") || ($subselect eq "all"))
       {
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][1]->value));
          $perfdata = $perfdata . " \'net_receive\'=" . $value . $perf_thresholds . ";;";
          if ($subselect ne "all")
             {
             $output = "net receive=" . $value . " KBps"; 
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
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][2]->value));
          $perfdata = $perfdata . " \'net_send\'=" . $value . $perf_thresholds . ";;";
          if ($subselect ne "all")
             {
             $output = "net send=" . $value . " KBps"; 
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
# is a common method to ensure this.
1;
