sub cluster_cluster_info
{
        my ($cluster) = @_;
         
        my $state = 2;
        my $output = 'CLUSTER clusterServices Unknown error';
        
        if (defined($subselect))
        {
                if ($subselect eq "effectivecpu")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('effectivecpu.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
                                $perfdata = $perfdata . " effective cpu=" . $value . "Mhz;" . $perf_thresholds . ";;";
                                $output = "effective cpu=" . $value . "%"; 
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "effectivemem")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('effectivemem.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
                                $perfdata = $perfdata . " effectivemem=" . $value . "MB;" . $perf_thresholds . ";;";
                                $output = "effective mem=" . $value . " MB";
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "failover")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('failover.latest:*'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value));
                                $perfdata = $perfdata . " failover=" . $value . ";" . $perf_thresholds . ";;";
                                $output = "failover=" . $value . " ";
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "cpufairness")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('cpufairness.latest'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value));
                                $perfdata = $perfdata . " cpufairness=" . $value . "%;" . $perf_thresholds . ";;";
                                $output = "cpufairness=" . $value . "%";
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "memfairness")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('memfairness.latest'));
                        if (defined($values))
                        {
                                my $value = simplify_number((convert_number($$values[0][0]->value)));
                                $perfdata = $perfdata . " memfairness=" .  $value . "%;" . $perf_thresholds . ";;";
                                $output = "memfairness=" . $value . "%";
                                $state = check_against_threshold($value);
                        }
                }
                else
                {
                get_me_out("Unknown CLUSTER clusterservices subselect");
                }
        }
        else
        {
                $values = return_cluster_performance_values($cluster, 'clusterServices', ('effectivecpu.average', 'effectivemem.average'));
                if (defined($values))
                {
                        my $value1 = simplify_number(convert_number($$values[0][0]->value));
                        my $value2 = simplify_number(convert_number($$values[0][1]->value) / 1024);
                        $perfdata = $perfdata . " effective cpu=" . $value1 . "Mhz;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " effective mem=" . $value2 . "MB;" . $perf_thresholds . ";;";
                        $state = 0;
                        $output = "effective cpu=" . $value1 . " Mhz, effective Mem=" . $value2 . " MB";
                }
        }

        return ($state, $output);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;