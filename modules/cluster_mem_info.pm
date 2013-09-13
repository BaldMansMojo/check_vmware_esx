sub cluster_mem_info
{
        my ($cluster) = @_;

        my $state = 2;
        my $output = 'CLUSTER MEM Unknown error';

        if (defined($subselect))
        {
                if ($subselect eq "usage")
                {
                        $values = return_cluster_performance_values($cluster, 'mem', ('usage.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
                                $perfdata = $perfdata . " mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
                                $output = "mem usage=" . $value . "%"; 
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "usagemb")
                {
                        $values = return_cluster_performance_values($cluster, 'mem', ('consumed.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
                                $perfdata = $perfdata . " mem_usagemb=" . $value . "MB;" . $perf_thresholds . ";;";
                                $output = "mem usage=" . $value . " MB";
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "swap")
                {
                        my $cluster_view;
                        ($cluster_view, $values) = return_cluster_performance_values($cluster, 'mem', ('swapused.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
                                $perfdata = $perfdata . " mem_swap=" . $value . "MB;" . $perf_thresholds . ";;";
                                $output = "swap usage=" . $value . " MB: ";
                                $state = check_against_threshold($value);
                                if ($state != 0)
                                {
                                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $$cluster_view[0], properties => ['name', 'runtime.powerState']);

                                        if (!defined($vm_views))
                                           {
                                           print "Runtime error\n";
                                           exit 2;
                                           }

                                        if (!@$vm_views)
                                           {
                                           print "There are no VMs.\n";
                                           exit 2;
                                           }

                                        my @vms = ();
                                        foreach my $vm (@$vm_views)
                                        {
                                                push(@vms, $vm) if ($vm->get_property('runtime.powerState')->val eq "poweredOn");
                                        }
                                        $values = generic_performance_values(\@vms, 'mem', ('swapped.average'));
                                        if (defined($values))
                                        {
                                                foreach my $index (0..@vms-1) {
                                                        my $value = simplify_number(convert_number($$values[$index][0]->value) / 1024);
                                                        $output = $output . $vms[$index]->name . " (" . $value . "MB), " if ($value > 0);
                                                }
                                        }
                                }
                                chop($output);
                                chop($output);
                        }
                }
                elsif ($subselect eq "memctl")
                {
                        my $cluster_view;
                        ($cluster_view, $values) = return_cluster_performance_values($cluster, 'mem', ('vmmemctl.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
                                $perfdata = $perfdata . " mem_memctl=" . $value . "MB;" . $perf_thresholds . ";;";
                                $output = "memctl=" . $value . " MB: ";
                                $state = check_against_threshold($value);
                                if ($state != 0)
                                {
                                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $$cluster_view[0], properties => ['name', 'runtime.powerState']);

                                        if (!defined($vm_views))
                                           {
                                           print "Runtime error\n";
                                           exit 2;
                                           }

                                        if (!@$vm_views)
                                           {
                                           print "There are no VMs.\n";
                                           exit 2;
                                           }

                                        my @vms = ();
                                        foreach my $vm (@$vm_views)
                                        {
                                                push(@vms, $vm) if ($vm->get_property('runtime.powerState')->val eq "poweredOn");
                                        }
                                        $values = generic_performance_values(\@vms, 'mem', ('vmmemctl.average'));
                                        if (defined($values))
                                        {
                                                foreach my $index (0..@vms-1) {
                                                        my $value = simplify_number(convert_number($$values[$index][0]->value) / 1024);
                                                        $output = $output . $vms[$index]->name . " (" . $value . "MB), " if ($value > 0);
                                                }
                                        }
                                }
                                chop($output);
                                chop($output);
                        }
                }
                else
                {
                get_me_out("Unknown CLUSTER MEM subselect");
                }
        }
        else
        {
                $values = return_cluster_performance_values($cluster, 'mem', ('consumed.average', 'usage.average', 'overhead.average', 'swapused.average', 'vmmemctl.average'));
                if (defined($values))
                {
                        my $value1 = simplify_number(convert_number($$values[0][0]->value) / 1024);
                        my $value2 = simplify_number(convert_number($$values[0][1]->value) * 0.01);
                        my $value3 = simplify_number(convert_number($$values[0][2]->value) / 1024);
                        my $value4 = simplify_number(convert_number($$values[0][3]->value) / 1024);
                        my $value5 = simplify_number(convert_number($$values[0][4]->value) / 1024);
                        $perfdata = $perfdata . " mem_usagemb=" . $value1 . "MB;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " mem_usage=" . $value2 . "%;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " mem_overhead=" . $value3 . "MB;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " mem_swap=" . $value4 . "MB;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " mem_memctl=" . $value5 . "MB;" . $perf_thresholds . ";;";
                        $state = 0;
                        $output = "mem usage=" . $value1 . " MB (" . $value2 . "%), overhead=" . $value3 . " MB, swapped=" . $value4 . " MB, memctl=" . $value5 . " MB";
                }
        }

        return ($state, $output);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;