sub vm_mem_info
    {
    my ($vmname) = @_;

    my $state = 2;
    my $output = 'HOST-VM MEM Unknown error';
    my $value;
        
    if (defined($subselect))
       {
       if ($subselect eq "usage")
          {
          $values = return_host_vmware_performance_values($vmname, 'mem', ('usage.average'));
          
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
             $perfdata = $perfdata . " mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
             $output = "$vmname: mem usage=" . $value . "%"; 
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "consumed")
          {
          $values = return_host_vmware_performance_values($vmname, 'mem', ('consumed.average'));
       
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " consumed_memory=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "$vmname: consumed memory=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "overhead")
          {
          $values = return_host_vmware_performance_values($vmname, 'mem', ('overhead.average'));
       
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " mem_overhead=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "$vmname: mem overhead=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "active")
          {
          $values = return_host_vmware_performance_values($vmname, 'mem', ('active.average'));
       
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " mem_active=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "$vmname: mem active=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       get_me_out("Unknown HOST-VM MEM Unknown error");
       }
    else
       {
        if ($perf_thresholds ne ';')
           {
           print_help();
           print "\nERROR! Thresholds only allowed with subselects!\n\n";
           exit 2;
           }

       $values = return_host_vmware_performance_values($vmname, 'mem', ('consumed.average', 'usage.average'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
          $perfdata = $perfdata . " consumed_memory=" . $value . "MB;;;";
          $output = "$vmname: consumed memory=" . $value . " MB(";

          $value = simplify_number(convert_number($$values[0][1]->value) * 0.01);
          $perfdata = $perfdata . " mem_usage=" . $value . "%;;;";
          $output = $output . $value . "%)";

          $state = 0;
          }
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
