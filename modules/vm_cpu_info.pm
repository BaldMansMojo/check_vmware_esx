sub vm_cpu_info
    {
    my ($vmname) = @_;
    my $state = 2;
    my $output = 'HOST-VM CPU Unknown error';
    my $value;
    
    if (defined($subselect))
       {
       if ($subselect eq "wait")
          {
          $values = return_host_vmware_performance_values($vmname,'cpu', ('wait.summation:*'));
          
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value));
             }

          if (defined($value))
             {
             $perfdata = $perfdata . " cpu_wait=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "cpu wait=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }

       if ($subselect eq "ready")
          {
          $values = return_host_vmware_performance_values($vmname,'cpu', ('ready.summation:*'));
          
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value));
             }

          if (defined($value))
             {
             $perfdata = $perfdata . " cpu_ready=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "cpu ready=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       get_me_out("Unknown HOST CPU subselect");
       }
    else
       {
       $values = return_host_vmware_performance_values($vmname, 'cpu', ('usage.average'));

       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
          $perfdata = $perfdata . " cpu_usage=" . $value . "%;" . $perf_thresholds . ";;";
          $output = "$vmname: cpu usage=" . $value . "%"; 
          $state = check_against_threshold($value);
          }
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;