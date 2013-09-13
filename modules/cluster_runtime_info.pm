sub cluster_runtime_info
{
        my ($cluster, $blacklist) = @_;

        my $state = 2;
        my $output = 'CLUSTER RUNTIME Unknown error';
        my $runtime;
        my $cluster_view = Vim::find_entity_view(view_type => 'ClusterComputeResource', filter => { name => "$cluster" }, properties => ['name', 'overallStatus', 'configIssue']);

        if (!defined($cluster_view))
           {
           print "Cluster " . $$cluster{"name"} . " does not exist.\n";
           exit 2;
           }

        $cluster_view->update_view_data();

        if (defined($subselect))
        {
                if ($subselect eq "listvms")
                {
                        my %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $cluster_view, properties => ['name', 'runtime']);

                        if (!defined($vm_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!defined($vm_views))
                           {
                           print "There are no VMs.\n";
                           exit 2;
                           }

                        my $up = 0;
                        $output = '';

                        foreach my $vm (@$vm_views)
                        {
                                my $vm_state = $vm_state_strings{$vm->runtime->powerState->val};
                                if ($vm_state eq "UP")
                                {
                                        $up++;
                                        $output = $output . $vm->name . "(0), ";
                                }
                                else
                                {
                                        $output = $vm->name . "(" . $vm_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $up .  "/" . @$vm_views . " VMs up: " . $output;
                        $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($up);
                           }
                }
                elsif ($subselect eq "listhost")
                {
                        my %host_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED", "standBy" => "STANDBY", "MaintenanceMode" => "Maintenance Mode");
                        my $host_views = Vim::find_entity_views(view_type => 'HostSystem', begin_entity => $cluster_view, properties => ['name', 'runtime.powerState']);

                        if (!defined($host_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!defined($host_views))
                           {
                           print "There are no hosts.\n" ;
                           exit 2;
                           }

                        my $up = 0;
                        my $unknown = 0;
                        $output = '';

                        foreach my $host (@$host_views) {
                                $host->update_view_data(['name', 'runtime.powerState']);
                                my $host_state = $host_state_strings{$host->get_property('runtime.powerState')->val};
                                $unknown += $host_state eq "3";
                                if ($host_state eq "UP" && $host_state eq "Maintenance Mode") {
                                        $up++;
                                        $output = $output . $host->name . "(UP), ";
                                } else
                                {
                                        $output = $host->name . "(" . $host_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $up .  "/" . @$host_views . " Hosts up: " . $output;
                        $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($up);
                           }

                        $state = 3 if ($state == 0 && $unknown);
                }
                elsif ($subselect eq "status")
                {
                        if (defined($cluster_view->overallStatus))
                        {
                                my $status = $cluster_view->overallStatus->val;
                                $output = "overall status=" . $status;
                                $state = check_health_state($status);
                        }
                        else
                        {
                                $output = "Insufficient rights to access status info on the DC\n";
                                $state = 1;
                        }
                }
                elsif ($subselect eq "issues")
                {
                        my $issues = $cluster_view->configIssue;
                        my $issues_count = 0;

                        $output = '';
                        if (defined($issues))
                        {
                                foreach (@$issues)
                                {
                                        if (defined($blacklist))
                                        {
                                                my $name = ref($_);
                                                next if ($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/);
                                        }
                                        $output = $output . format_issue($_) . "; ";
                                        $issues_count++;
                                }
                        }

                        if ($output eq '')
                        {
                                $state = 0;
                                $output = 'No config issues';
                        }
                        $perfdata = $perfdata . " issues=" . $issues_count;
                }
                else
                {
                get_me_out("Unknown CLUSTER RUNTIME subselect");
                }
        }
        else
        {
                my %cluster_maintenance_state = (0 => "no", 1 => "yes");
                my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $cluster_view, properties => ['name', 'runtime.powerState']);
                my $up = 0;

                if (defined($vm_views))
                {
                        foreach my $vm (@$vm_views) {
                                $up += $vm->get_property('runtime.powerState')->val eq "poweredOn";
                        }
                        $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";
                        $output = $up . "/" . @$vm_views . " VMs up";
                }
                else
                {
                        $output = "No VMs installed";
                }

                my $AlertCount = 0;
                my $SensorCount = 0;
                my ($cpuStatusInfo, $storageStatusInfo, $memoryStatusInfo, $numericSensorInfo);

                $state = 0;
                $output = $output . ", overall status=" . $cluster_view->overallStatus->val . ", " if (defined($cluster_view->overallStatus));

                my $issues = $cluster_view->configIssue;
                if (defined($issues))
                {
                        $output = $output . @$issues . " config issue(s)";
                }
                else
                {
                        $output = $output . "no config issues";
                }
        }

        return ($state, $output);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;