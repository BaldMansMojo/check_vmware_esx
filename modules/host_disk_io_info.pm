sub host_disk_io_info
    {
    my ($host) = @_;
    my $value;
    my $state = 0;
    my $output;
    my $actual_state;            # Hold the actual state for to be compared
    my $true_sub_sel=1;          # Just a flag. To have only one return at the en
                                 # we must ensure that we had a valid subselect. If
                                 # no subselect is given we select all
                                 # 0 -> existing subselect
                                 # 1 -> non existing subselect

    $values = return_host_performance_values($host, 'disk', ('commandsAborted.summation:*', 'busResets.summation:*', 'read.average:*', 'totalReadLatency.average:*', 'write.average:*', 'totalWriteLatency.average:*', 'usage.average:*', 'kernelLatency.average:*', 'deviceLatency.average:*', 'queueLatency.average:*', 'totalLatency.average:*'));

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

    if (($subselect eq "aborted") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value), 0);
          if ($subselect eq "all")
             {
             $output = "I/O commands aborted=" . $value;
             $perfdata = "\'io_aborted\'=" . $value . ";" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "io commands aborted=" . $value;
             $perfdata = "\'io_aborted\'=" . $value . ";" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          $actual_state = 3;
          $output = "I/O commands aborted=Not available";
          $state = check_state($state, $actual_state);
          }
       }

    if (($subselect eq "resets") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][1]->value), 0);
          if ($subselect eq "all")
             {
             $output =  $output . " - I/O bus resets=" . $value;
             $perfdata = $perfdata . " \'io_busresets\'=" . $value . ";" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O bus resets=" . $value;
             $perfdata = "\'io_busresets\'=" . $value . ";" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O bus resets=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O bus resets=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }
    
    if (($subselect eq "read") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][2]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O read=" . $value . " KB/sec.";
             $perfdata = $perfdata . " \'io_read\'=" . $value . ";" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O read=" . $value . " KB/sec.";
             $perfdata = "\'io_read\'=" . $value . ";" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
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
    
    if (($subselect eq "read_latency") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][3]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O read latency=" . $value . " ms";
             $perfdata = $perfdata . " \'io_read_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O read latency=" . $value . " ms";
             $perfdata = "\'io_read_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O read latency=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O read latency=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }
    
    if (($subselect eq "write") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][4]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O write=" . $value . " KB/sec.";
             $perfdata = $perfdata . " \'io_write\'=" . $value . ";" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O write=" . $value . " KB/sec.";
             $perfdata = "\'io_write\'=" . $value . ";" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
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
    
    if (($subselect eq "write_latency") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][5]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . "I/O write latency=" . $value . " ms";
             $perfdata = $perfdata . " \'io_write_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O write latency=" . $value . " ms";
             $perfdata = "\'io_write_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O write latency==Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O write latency==Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }
    
    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][6]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O usage=" . $value . " KB/sec.";
             $perfdata = $perfdata . " \'io_usage\'=" . $value . ";;;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O usage=" . $value . " KB/sec., ";
             $perfdata = "\'io_usage\'=" . $value . ";;;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O usage=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O usage=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if (($subselect eq "kernel_latency") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][7]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O kernel latency=" . $value . " ms";
             $perfdata = $perfdata . " \'io_kernel_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O kernel latency=" . $value . " ms";
             $perfdata = "\'io_kernel_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O kernel latency=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O kernel latency=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }
    
    if (($subselect eq "device_latency") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][8]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O device latency=" . $value . " ms";
             $perfdata = $perfdata . " \'io_device_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O device latency=" . $value . " ms";
             $perfdata = "\'io_device_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O device latency=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O device latency=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }
    
    if (($subselect eq "queue_latency") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][9]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O queue latency=" . $value . " ms";
             $perfdata = $perfdata . " \'io_queue_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O queue latency=" . $value . " ms";
             $perfdata = "\'io_queue_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O queue latency=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O queue latency=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }
    
    if (($subselect eq "total_latency") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][10]->value), 0);
          if ($subselect eq "all")
             {
             $output = $output . " - I/O total latency=" . $value . " ms";
             $perfdata = $perfdata . " \'io_total_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "I/O total latency=" . $value . " ms";
             $perfdata = "\'io_total_latency\'=" . $value . "ms;" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " - I/O total latency=Not available";
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "I/O total latency=Not available";
             $state = check_state($state, $actual_state);
             }
          }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown HOST IO subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
