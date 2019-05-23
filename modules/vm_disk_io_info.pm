sub vm_disk_io_info
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

    $values = return_host_vmware_performance_values($vmname, 'disk', ('usage.average:*', 'read.average:*', 'write.average:*'));

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
          $value = simplify_number(convert_number($$values[0][0]->value), 0);
          if ($subselect eq "all")
             {
             $output = "I/O usage=" . $value . " KB/sec";
             $perfdata = $perfdata . " \'io_usage\'=" . $value . "KB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O usage=" . $value . " KB/sec";
             $perfdata = "\'io_usage\'=" . $value . "KB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          $actual_state = 3;
          $output = "I/O usage=Not available";
          $state = check_state($state, $actual_state);
          }
       }

    if (($subselect eq "read") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][1]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O read=" . $value . " KB/sec";
             $perfdata = $perfdata . " \'io_read\'=" . $value . "KB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O read=" . $value . " KB/sec";
             $perfdata = " \'io_read\'=" . $value . "KB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O read=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O read=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if (($subselect eq "write") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][2]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O write=" . $value . " KB/sec";
             $perfdata = $perfdata . " \'io_write\'=" . $value . "KB;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O write=" . $value . " KB/sec";
             $perfdata = " \'io_write\'=" . $value . "KB;" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O write=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O write=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown VM IO subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module
# is a common method to ensure this.
1;
