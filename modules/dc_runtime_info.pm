sub dc_runtime_info
{
        my ($blacklist) = @_;

        my $state = 2;
        my $output = 'DC RUNTIME Unknown error';
        my $runtime;

        if (defined($subselect))
        {
                if ($subselect eq "listvms")
                {
                        my %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'runtime']);

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

                        my $up = 0;
                        $output = '';

                        foreach my $vm (@$vm_views) {
                                my $vm_state = $vm_state_strings{$vm->runtime->powerState->val};
                                if ($vm_state eq "UP")
                                {
                                        $up++;
                                        $output = $output . $vm->name . "(UP), ";
                                }
                                else
                                {
                                        $output = $vm->name . "(" . $vm_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $up . "/" . @$vm_views . " VMs up: " . $output;
                        $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($up);
                           }
                }
                elsif ($subselect eq "listhost")
                {
                        my %host_state_strings = ("unknown" => "3", "poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED", "standBy" => "STANDBY", "MaintenanceMode" => "Maintenance Mode");
                        my $host_views = Vim::find_entity_views(view_type => 'HostSystem', properties => ['name', 'runtime.powerState']);

                        if (!defined($host_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!@$host_views)
                           {
                           print "There are no VMs.\n";
                           exit 2;
                           }

                        my $up = 0;
                        my $unknown = 0;
                        $output = '';

                        foreach my $host (@$host_views) {
                                $host->update_view_data(['name', 'runtime.powerState']);
                                my $host_state = $host_state_strings{$host->get_property('runtime.powerState')->val};
                                $unknown += $host_state eq "3";
                                if ($host_state eq "UP") {
                                        $up++;
                                        $output = $output . $host->name . "(UP), ";
                                }
                                else
                                {
                                        $output = $host->name . "(" . $host_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $up . "/" . @$host_views . " Hosts up: " . $output;
                        $perfdata = $perfdata . " hostcount=" . $up . ";" . $perf_thresholds . ";;";
 
                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($up);
                           }

                        if ($state == 0 && $unknown)
                           {
                           $state = 3;
                           }
                }
                elsif ($subselect eq "listcluster")
                {
                        my %cluster_state_strings = ("gray" => "3", "green" => "GREEN", "red" => "RED", "yellow" => "YELLOW");
                        my $cluster_views = Vim::find_entity_views(view_type => 'ClusterComputeResource', properties => ['name', 'overallStatus']);

                        if (!defined($cluster_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!@$cluster_views)
                           {
                           print "There are no Clusters.\n";
                           exit 2;
                           }

                        my $green = 0;
                        my $unknown = 0;
                        $output = '';

                        foreach my $cluster (@$cluster_views) {
                                $cluster->update_view_data(['name', 'overallStatus']);
                                my $cluster_state = $cluster_state_strings{$cluster->get_property('overallStatus')->val};
                                $unknown += $cluster_state eq "3";
                                if ($cluster_state eq "GREEN") {
                                        $green++;
                                        $output = $output . $cluster->name . "(GREEN), ";
                                }
                                else
                                {
                                        $output = $cluster->name . "(" . $cluster_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $green . "/" . @$cluster_views . " Cluster green: " . $output;
                        $perfdata = $perfdata . " clustercount=" . $green . ";" . $perf_thresholds . ";;";

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($green);
                           }

                        if ($state == 0 && $unknown)
                           {
                           $state = 3;
                           }
                }
                elsif ($subselect eq "tools")
                {
                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'runtime.powerState', 'summary.guest']);

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

                        $output = '';
                        my $tools_ok = 0;
                        my $vms_up = 0;
                        foreach my $vm (@$vm_views) {
                                my $name = $vm->name;
                                if (defined($blacklist))
                                {
                                        next if ($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/);
                                }
                                if ($vm->get_property('runtime.powerState')->val eq "poweredOn")
                                {
                                        my $vm_guest = $vm->get_property('summary.guest');
                                        my $tools_status;
                                        my $tools_runstate;
                                        my $tools_version;
                                        $tools_runstate = $vm_guest->toolsRunningStatus if (exists($vm_guest->{toolsRunningStatus}) && defined($vm_guest->toolsRunningStatus));
                                        $tools_version = $vm_guest->toolsVersionStatus if (exists($vm_guest->{toolsVersionStatus}) && defined($vm_guest->toolsVersionStatus));

                                        $vms_up++;
                                        if (defined($tools_runstate) || defined($tools_version))
                                        {
                                                my %vm_tools_strings = ("guestToolsCurrent" => "Newest", "guestToolsNeedUpgrade" => "Old", "guestToolsNotInstalled" => "Not installed", "guestToolsUnmanaged" => "Unmanaged", "guestToolsExecutingScripts" => "Starting", "guestToolsNotRunning" => "Not running", "guestToolsRunning" => "Running");
                                                $tools_status = $vm_tools_strings{$tools_runstate} . "-" if (defined($tools_runstate));
                                                $tools_status = $tools_status . $vm_tools_strings{$tools_version} . "-" if (defined($tools_version));
                                                chop($tools_status);
                                                if ($tools_status eq "Running-Newest")
                                                {
                                                        $output = $output . $name . "(Running-Newest), ";
                                                        $tools_ok++;
                                                }
                                                else
                                                {
                                                        $output = $name . "(" . $tools_status . "), " . $output;
                                                }
                                        }
                                        else
                                        {
                                                my %vm_tools_strings = ("toolsNotInstalled" => "Not installed", "toolsNotRunning" => "Not running", "toolsOk" => "0", "toolsOld" => "Old", "notDefined" => "Not defined");
                                                $tools_status = $vm_guest->toolsStatus;
                                                if (defined($tools_status))
                                                {
                                                        $tools_status = $vm_tools_strings{$tools_status->val};
                                                        if ($tools_status eq "0")
                                                        {
                                                                $output = $output . $name . "(0), ";
                                                                $tools_ok++;
                                                        }
                                                        else
                                                        {
                                                                $output = $name . "(" . $tools_status . "), " . $output;
                                                        }
                                                }
                                                else
                                                {
                                                        $output = $name . "(" . $vm_tools_strings{"notDefined"} . "), " . $output;
                                                }
                                        }
                                }
                        }
                        chop($output);
                        chop($output);
                        if ($vms_up)
                        {
                                $tools_ok /= $vms_up / 100;
                        }
                        else
                        {
                                $tools_ok = 100;
                        }

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($tools_ok);
                           }

                        $perfdata = $perfdata . " toolsok=" . $tools_ok . "%;" . $perf_thresholds . ";;";
                }
                elsif ($subselect eq "status")
                {
                        my $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['name', 'overallStatus']);

                        if (!defined($dc_views))
                           {
                           print "There are no Datacenter\n";
                           exit 2;
                           }

                        $state = 0;
                        $output = '';
                        foreach my $dc (@$dc_views) {
                                if (defined($dc->overallStatus))
                                {
                                        my $status = $dc->overallStatus->val;
                                        $output = $output . $dc->name . " overall status=" . $status . ", ";
                                        $status = check_health_state($status);
                                        $state = 3 if ($status == 3);
                                        $state = check_state($state, $status) if (($state != 3) || ($status != 0));
                                }
                                else
                                {
                                        $output = $output . "Insufficient rights to access " . $dc->name . " status info on the DC, ";
                                        $state = check_state($state, 1);
                                }
                        }
                        if ($output) {
                                chop($output);
                                chop($output);
                        }
                }
                elsif ($subselect eq "issues")
                {
                        my $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['name', 'configIssue']);

                        if (!defined($dc_views))
                           {
                           print "There are no Datacenter\n";
                           exit 2;
                           }

                        my $issues_count = 0;
                        $output = '';

                        foreach my $dc (@$dc_views) {
                                my $issues = $dc->configIssue;

                                if (defined($issues))
                                {
                                        foreach (@$issues)
                                        {
                                                if (defined($blacklist))
                                                {
                                                        my $name = ref($_);
                                                        next if ($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/);
                                                }
                                                $output = $output . format_issue($_) . "(" . $dc->name . "); ";
                                                $issues_count++;
                                        }
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
                get_me_out("Unknown DC RUNTIME subselect");
                }
        }
        else
        {
                my $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['name', 'overallStatus', 'configIssue']);

                if (!defined($dc_views))
                   {
                   print "There are no Datacenter\n";
                   exit 2;
                   }

                my %host_maintenance_state = (0 => "no", 1 => "yes");
                my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'runtime.powerState']);

                if (!defined($vm_views))
                   {
                   print "Runtime error\n";
                   exit 2;
                   }

                my $up = 0;

                if (@$vm_views)
                {
                        foreach my $vm (@$vm_views) {
                                $up += $vm->get_property('runtime.powerState')->val eq "poweredOn";
                        }
                        $output = $up . "/" . @$vm_views . " VMs up, ";
                }
                else
                {
                        $output = "No VMs installed, ";
                }
                $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";

                my $host_views = Vim::find_entity_views(view_type => 'HostSystem', properties => ['name', 'runtime.powerState']);

                if (!defined($host_views))
                   {
                   print "Runtime error\n";
                   exit 2;
                   }

                $up = 0;

                if (@$host_views)
                {
                        foreach my $host (@$host_views) {
                                $up += $host->get_property('runtime.powerState')->val eq "poweredOn"
                        }
                        $output = $output . $up . "/" . @$host_views . " Hosts up, ";
                }
                else
                {
                        $output = $output . "there are no hosts, ";
                }
                $perfdata = $perfdata . " hostcount=" . $up . ";;;;";

                $state = 0;

                foreach my $dc (@$dc_views) {
                        $output = $output . $dc->name . " overall status=" . $dc->overallStatus->val . ", " if (defined($dc->overallStatus));
                }

                my $issue_count = 0;
                foreach my $dc (@$dc_views) {
                        my $issues = $dc->configIssue;
                        $issue_count += @$issues if (defined($issues));
                }
                
                if ($issue_count)
                {
                        $output = $output . $issue_count . " config issue(s)";
                        $perfdata = $perfdata . " config_issues=" . $issue_count;
                }
                else
                {
                        $output = $output . "no config issues";
                        $perfdata = $perfdata . " config_issues=" . 0;
                }
        }

        return ($state, $output);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;