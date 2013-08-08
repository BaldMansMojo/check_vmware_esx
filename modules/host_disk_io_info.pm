sub host_disk_io_info
    {
    my ($host) = @_;
    my $value;
    my $state = 2;
    my $output = 'HOST IO Unknown error';

    if (defined($subselect))
       {
       if ($subselect eq "aborted")
          {
          $values = return_host_performance_values($host, 'disk', ('commandsAborted.summation:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_aborted=" . $value . ";" . $perf_thresholds . ";;";
             $output = "io commands aborted=" . $value;
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }

       if ($subselect eq "resets")
          {
          $values = return_host_performance_values($host, 'disk', ('busResets.summation:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_busresets=" . $value . ";" . $perf_thresholds . ";;";
             $output = "io bus resets=" . $value;
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "read")
          {
          $values = return_host_performance_values($host, 'disk', ('read.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_read=" . $value . "KB;" . $perf_thresholds . ";;";
             $output = "io read=" . $value . " KB/sec.";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "read_latency")
          {
          $values = return_host_performance_values($host, 'disk', ('totalReadLatency.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_read_latency=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "io read latency=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "write")
          {
          $values = return_host_performance_values($host, 'disk', ('write.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_write=" . $value . "KB;" . $perf_thresholds . ";;";
             $output = "io write=" . $value . " KB/sec.";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "write_latency")
          {
          $values = return_host_performance_values($host, 'disk', ('totalWriteLatency.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_write_latency=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "io write latency=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "kernel_latency")
          {
          $values = return_host_performance_values($host, 'disk', ('kernelLatency.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_kernel_latency=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "io kernel latency=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "device_latency")
          {
          $values = return_host_performance_values($host, 'disk', ('deviceLatency.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_device_latency=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "io device latency=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "queue_latency")
          {
          $values = return_host_performance_values($host, 'disk', ('queueLatency.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_queue_latency=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "io queue latency=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
        get_me_out("Unknown HOST IO subselect");
        }
     else
        {
        if ($perf_thresholds ne ';')
           {
           print_help();
           print "\nERROR! Thresholds only allowed with subselects!\n\n";
           exit 2;
           }
        
        $values = return_host_performance_values($host, 'disk', ('commandsAborted.summation:*', 'busResets.summation:*', 'read.average:*', 'totalReadLatency.average:*', 'write.average:*', 'totalWriteLatency.average:*', 'usage.average:*', 'kernelLatency.average:*', 'deviceLatency.average:*', 'queueLatency.average:*'));
        if (defined($values))
           {
           $value = simplify_number(convert_number($$values[0][0]->value), 0);
           $perfdata = $perfdata . " io_aborted=" . $value . ";;;";
           $output = "io commands aborted=" . $value . ", ";

           $value = simplify_number(convert_number($$values[0][1]->value), 0);
           $perfdata = $perfdata . " io_busresets=" . $value . ";;;";
           $output = $output . "io bus resets=" . $value . ", ";

           $value = simplify_number(convert_number($$values[0][2]->value), 0);
           $perfdata = $perfdata . " io_read=" . $value . "KB;;;";
           $output = $output . "io read=" . $value . " KB/sec., ";

           $value = simplify_number(convert_number($$values[0][3]->value), 0);
           $perfdata = $perfdata . " io_read_latency=" . $value . "ms;;;";
           $output = $output . "io read latency=" . $value . " ms, ";

           $value = simplify_number(convert_number($$values[0][4]->value), 0);
           $perfdata = $perfdata . " io_write=" . $value . "KB;;;";
           $output = $output . "write=" . $value . " KB/sec., ";

           $value = simplify_number(convert_number($$values[0][5]->value), 0);
           $perfdata = $perfdata . " io_write_latency=" . $value . "ms;;;";
           $output = $output . "write latency=" . $value . " ms, ";

           $value = simplify_number(convert_number($$values[0][6]->value), 0);
           $perfdata = $perfdata . " io_usage=" . $value . "KB;;;";
           $output = $output . "io_usage=" . $value . " KB/sec., ";

           $value = simplify_number(convert_number($$values[0][7]->value), 0);
           $perfdata = $perfdata . " io_kernel_latency=" . $value . "ms;;;";
           $output = $output . "kernel latency=" . $value . " ms, ";

           $value = simplify_number(convert_number($$values[0][8]->value), 0);
           $perfdata = $perfdata . " io_device_latency=" . $value . "ms;;;";
           $output = $output . "device latency=" . $value . " ms, ";

           $value = simplify_number(convert_number($$values[0][9]->value), 0);
           $perfdata = $perfdata . " io_queue_latency=" . $value . "ms;;;";
           $output = $output . "queue latency=" . $value ." ms";

           $state = 0;
           }
        return ($state, $output);
        }

    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
