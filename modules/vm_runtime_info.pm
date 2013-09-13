sub vm_runtime_info
    {
    my ($vmname) = @_;
    my $state = 2;
    my $output = 'VM RUNTIME Unknown error';
    my $runtime;
    my $tools_status;
    my $tools_runstate;
    my $tools_version;
    my %vm_guest_state;
    my %vm_tools_strings;
    my %vm_tools_status;
    my $issues;
    my %vm_state_strings;
    my $actual_state;
    my $status;
    
    my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine', filter => {name => $vmname}, properties => ['name', 'runtime', 'overallStatus', 'guest', 'configIssue']);

    if (!defined($vm_view))
       {
       print "VMware machine " . $vmname . " does not exist\n";
       exit 2;
       }

    $runtime = $vm_view->runtime;

    if (defined($subselect))
       {
       if ($subselect eq "con")
          {
          $output = "$vmname connection state=" . $runtime->connectionState->val;
          if ($runtime->connectionState->val eq "connected")
             {
             $state = 0;
             }
          return ($state, $output);
          }

       if ($subselect eq "cpu")
          {
          $output = "$vmname max cpu=" . $runtime->maxCpuUsage . " MHz";
          $state = 0;
          return ($state, $output);
          }

       if ($subselect eq "mem")
          {
          $output = "$vmname max mem=" . $runtime->maxMemoryUsage . " MB";
          $state = 0;
          return ($state, $output);
          }

       if ($subselect eq "state")
          {
          %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
          $actual_state = $vm_state_strings{$runtime->powerState->val};
          $output = "$vmname run state=" . $actual_state;

          if ($actual_state eq "UP")
             {
             if ($actual_state eq "UP")
                {
                $state = 0;
                }
             }
          return ($state, $output);
          }

       if ($subselect eq "status")
          {
          $status = $vm_view->overallStatus->val;
          $output = "$vmname overall status=" . $status;
          $state = check_health_state($status);
          return ($state, $output);
          }

       if ($subselect eq "consoleconnections")
          {
          $output = "$vmname console connections=" . $runtime->numMksConnections;
          $state = check_against_threshold($runtime->numMksConnections);
          return ($state, $output);
          }

       if ($subselect eq "guest")
          {
          %vm_guest_state = ("running" => "Running", "notRunning" => "Not running", "shuttingDown" => "Shutting down", "resetting" => "Resetting", "standby" => "Standby", "unknown" => "Unknown");
          $actual_state = $vm_guest_state{$vm_view->guest->guestState};
          $output = "$vmname guest state=" . $actual_state;
          if ($actual_state eq "Running")
             {
             $state = 0;
             }
          return ($state, $output);
          }

       if ($subselect eq "tools")
          {
          if (exists($vm_view->guest->{toolsRunningStatus}) && defined($vm_view->guest->toolsRunningStatus))
             {
             $tools_runstate = $vm_view->guest->toolsRunningStatus;
             }
          if (exists($vm_view->guest->{toolsVersionStatus}) && defined($vm_view->guest->toolsVersionStatus))
             {
             $tools_version = $vm_view->guest->toolsVersionStatus;
             }

          if (defined($tools_runstate) || defined($tools_version))
             {
             %vm_tools_strings = ("guestToolsCurrent" => "Newest", "guestToolsNeedUpgrade" => "Old", "guestToolsNotInstalled" => "Not installed", "guestToolsUnmanaged" => "Unmanaged", "guestToolsExecutingScripts" => "Starting", "guestToolsNotRunning" => "Not running", "guestToolsRunning" => "Running");

             if (defined($tools_runstate))
                {
                $tools_status = $vm_tools_strings{$tools_runstate} . "-";
                }
   
             if (defined($tools_version))
                {
                $tools_status = $tools_status . $vm_tools_strings{$tools_version} . "-";
                }

             chop($tools_status);

             if (($tools_status eq "Running-Newest") || ($tools_status eq "Running-Unmanaged"))
                {
                $state = 0;
                }
             }
          else
             {
             %vm_tools_strings = ("toolsNotInstalled" => "Not installed", "toolsNotRunning" => "Not running", "toolsOk" => "0", "toolsOld" => "Old", "notDefined" => "Not defined");
             $tools_status = $vm_view->guest->toolsStatus;

             if (defined($tools_status))
                {
                $tools_status = $vm_tools_strings{$tools_status->val};
                }
             else
                {
                $tools_status = $vm_tools_strings{"notDefined"};
                }

             if ($tools_status eq "0")
                {
                $state = 0;
                }
             }
          $output = "$vmname tools status=" . $tools_status;
          return ($state, $output);
          }

       if ($subselect eq "issues")
          {
          $issues = $vm_view->configIssue;

          if (defined($issues))
             {
             $output = "\"$vmname\": ";
             foreach (@$issues)
                     {
                     $output = $output . $_->fullFormattedMessage . "(caused by " . $_->userName . "); ";
                     }
             }
          else
             {
             $state = 0;
             $output = "$vmname has no config issues";
             }
          return ($state, $output);
          }
       get_me_out("Unknown VM RUNTIME subselect");
       }
    else
       {
       %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
       %vm_tools_status = ("toolsNotInstalled" => "Not installed", "toolsNotRunning" => "Not running", "toolsOk" => "0", "toolsOld" => "Old");
       %vm_guest_state = ("running" => "Running", "notRunning" => "Not running", "shuttingDown" => "Shutting down", "resetting" => "Resetting", "standby" => "Standby", "unknown" => "Unknown");
       $state = 0;
       $output = "$vmname status=" . $vm_view->overallStatus->val . ", run state=" . $vm_state_strings{$runtime->powerState->val} . ", guest state=" . $vm_guest_state{$vm_view->guest->guestState} . ", max cpu=" . $runtime->maxCpuUsage . " MHz, max mem=" . $runtime->maxMemoryUsage . " MB, console connections=" . $runtime->numMksConnections . ", tools status=" . $vm_tools_status{$vm_view->guest->toolsStatus->val} . ", ";
       $issues = $vm_view->configIssue;

       if (defined($issues))
          {
          $output = $output . @$issues . " config issue(s)";
          }
       else
          {
          $output = $output . "has no config issues";
          }
       }
       return ($state, $output);
    }
    
# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;