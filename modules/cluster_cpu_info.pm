sub cluster_cpu_info
{
        my ($cluster) = @_;

        my $state = 2;
        my $output = 'CLUSTER CPU Unknown error';

        if (defined($subselect))
        {
                if ($subselect eq "usage")
                {
                        $values = return_cluster_performance_values($cluster, 'cpu', ('usage.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
                                $perfdata = $perfdata . " cpu_usage=" . $value . "%;" . $perf_thresholds . ";;";
                                $output = "cpu usage=" . $value . "%"; 
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "usagemhz")
                {
                        $values = return_cluster_performance_values($cluster, 'cpu', ('usagemhz.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value));
                                $perfdata = $perfdata . " cpu_usagemhz=" . $value . "Mhz;" . $perf_thresholds . ";;";
                                $output = "cpu usagemhz=" . $value . " MHz";
                                $state = check_against_threshold($value);
                        }
                }
                else
                {
                get_me_out("Unknown CLUSTER CPU subselect");
                }
        }
        else
        {
                $values = return_cluster_performance_values($cluster, 'cpu', ('usagemhz.average', 'usage.average'));
                if (defined($values))
                {
                        my $value1 = simplify_number(convert_number($$values[0][0]->value));
                        my $value2 = simplify_number(convert_number($$values[0][1]->value) * 0.01);
                        $perfdata = $perfdata . " cpu_usagemhz=" . $value1 . "Mhz;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " cpu_usage=" . $value2 . "%;" . $perf_thresholds . ";;";
                        $state = 0;
                        $output = "cpu usage=" . $value1 . " MHz (" . $value2 . "%)";
                }
        }

        return ($state, $output);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;