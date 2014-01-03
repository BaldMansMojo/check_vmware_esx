sub vm_disk_io_info
    {
    my ($vmname) = @_;
    my $state = 2;
    my $output = 'VM IO Unknown error';
    my $value;
    
    if (defined($subselect))
       {
       if ($subselect eq "usage")
          {
          $values = return_host_vmware_performance_values($vmname, 'disk', ('usage.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_usage=" . $value . "KB/s;" . $perf_thresholds . ";;";
             $output = "$vmname io usage=" . $value . " KB/s";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "read")
          {
          $values = return_host_vmware_performance_values($vmname, 'disk', ('read.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_read=" . $value . "KB/s;" . $perf_thresholds . ";;";
             $output = "$vmname io read=" . $value . " KB/s";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }

       if ($subselect eq "write")
          {
          $values = return_host_vmware_performance_values($vmname, 'disk', ('write.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value), 0);
             $perfdata = $perfdata . " io_write=" . $value . "KB/s;" . $perf_thresholds . ";;";
             $output = "$vmname io write=" . $value . " KB/s";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       get_me_out("Unknown VM IO subselect");
       }
    else
       {

       if ($perf_thresholds ne ';')
          {
          print_help();
          print "\nERROR! Thresholds only allowed with subselects!\n\n";
          exit 2;
          }

       $values = return_host_vmware_performance_values($vmname, 'disk', ('usage.average:*', 'read.average:*', 'write.average:*'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value), 0);
          $perfdata = $perfdata . " io_usage=" . $value . "KB/s;;;";
          $output = "$vmname io usage=" . $value . " KB/s, ";

          $value = simplify_number(convert_number($$values[0][1]->value), 0);
          $perfdata = $perfdata . " io_read=" . $value . "KB/s;;;";
          $output = $output . "read=" . $value . " KB/s, ";

          $value = simplify_number(convert_number($$values[0][2]->value), 0);
          $perfdata = $perfdata . " io_write=" . $value . "KB/s;;;";
          $output = $output . "write=" . $value . " KB/s";

          $state = 0;
          }
        }

        return ($state, $output);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
