sub dc_runtime_info
    {
    my $state = 0;
    my $actual_state;
    my $output = '';
    my $tmp_output = '';
    my $issue_out = '';
    my $runtime;
    my $host_views;
    my $host_state;
    my $host;
    my $dc_views;
    my $dc;
    my $overallStatus;
    my $issues;
    my $issue_cnt = 0;
    my $issues_ignored_cnt = 0;
    my $poweredon = 0;           # Virtual machine powerstate counter
    my $poweredoff = 0;          # Virtual machine powerstate counter
    my $suspended = 0;           # Virtual machine powerstate counter
    my $poweredon_out = '';      # Virtual machine powerstate temporary output
    my $poweredoff_out = '';     # Virtual machine powerstate temporary output
    my $suspended_out = '';      # Virtual machine powerstate temporary output
    my $hpoweredon = 0;          # VMware ESX host powerstate counter
    my $hpoweredoff = 0;         # VMware ESX host powerstate counter
    my $hpoweredon_out = '';     # VMware ESX host powerstate temporary output
    my $hpoweredoff_out = '';    # VMware ESX host powerstate temporary output
    my $vm;
    my $vm_state;
    my $vm_views;
    my $vm_cnt = 0;       
    my $vm_bad_cnt = 0;       
    my $vm_ignored_cnt = 0;       
    my $guestToolsBlacklisted_cnt = 0;
    my $guestToolsCurrent_cnt = 0;
    my $guestToolsNeedUpgrade_cnt = 0;
    my $guestToolsSupportedNew_cnt = 0;
    my $guestToolsSupportedOld_cnt = 0;
    my $guestToolsTooNew_cnt = 0;
    my $guestToolsTooOld_cnt = 0;
    my $guestToolsUnmanaged_cnt = 0;
    my $guestToolsUnknown_cnt = 0;
    my $guestToolsNotRunning_cnt = 0;
    my $guestToolsNotInstalled_cnt = 0;
    my $guestToolsPOF_cnt = 0;
    my $guestToolsSuspendePOF_cnt = 0;
    my $vm_guest;
    my $tools_out = '';
    my $cluster;
    my $cluster_state;
    my $cluster_views;
    my $cluster_gray_cnt = 0;    # Cluster gray state counter
    my $cluster_green_cnt = 0;   # Cluster green state counter
    my $cluster_red_cnt = 0;     # Cluster red state counter
    my $cluster_yellow_cnt = 0;  # Cluster yellow state counter
    my $cluster_gray_out = '';   # Cluster gray temporary output
    my $cluster_green_out = '';  # Cluster green temporary output
    my $cluster_red_out = '';    # Cluster red temporary output
    my $cluster_yellow_out = ''; # Cluster yellow temporary output

    my $vc_gray_cnt = 0;         # Vcenter gray state counter
    my $vc_green_cnt = 0;        # Vcenter green state counter
    my $vc_red_cnt = 0;          # Vcenter red state counter
    my $vc_yellow_cnt = 0;       # Vcenter yellow state counter
    my $vc_name;

    my $true_sub_sel=1;          # Just a flag. To have only one return at the en
                                 # we must ensure that we had a valid subselect. If
                                 # no subselect is given we select all
                                 # 0 -> existing subselect
                                 # 1 -> non existing subselect

    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       $true_sub_sel = 0;
       if ( $perf_thresholds ne ";")
          {
          print "Error! Thresholds are only allowed with subselects but ";
          print "not with --subselect=health !\n";
          exit 2;
          }
       }


    if (($subselect eq "listvms") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       my %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
       $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'runtime']);

       if (!defined($vm_views))
          {
          print "Runtime error\n";
          exit 2;
          }
       
       if (!@$vm_views)
          {
          $output = "No VMs";
          }
       else
          {
          foreach $vm (@$vm_views)
                  {
                  if (defined($isregexp))
                     {
                     $isregexp = 1;
                     }
                  else
                     {
                     $isregexp = 0;
                     }
               
                  if (defined($blacklist))
                     {
                     if (isblacklisted(\$blacklist, $isregexp, $vm->name))
                        {
                        next;
                        }
                     }
                  if (defined($whitelist))
                     {
                     if (isnotwhitelisted(\$whitelist, $isregexp, $vm->name))
                        {
                        next;
                        }
                      }

                  $vm_state = $vm->runtime->powerState->val;
               
                  if ($vm_state eq "poweredOn")
                     {
                     $poweredon++;
                     if (!$alertonly)
                        {
                        $poweredon_out = $poweredon_out . $vm->name . " (" . $vm_state . ")" . $multiline;
                        }
                     }
                  if ($vm_state eq "poweredOff")
                     {
                     $poweredoff++;
                     $poweredoff_out = $poweredoff_out . $vm->name . " (" . $vm_state . ")" . $multiline;
                     }
                  if ($vm_state eq "suspended")
                     {
                     $suspended++;
                     $suspended_out = $suspended_out . $vm->name . " (" . $vm_state . ")" . $multiline;
                     }
                  }

          if ($subselect eq "all")
             {
             $output = $suspended . "/" . @$vm_views . " VMs suspended - ";
             $output = $output . $poweredoff . "/" . @$vm_views . " VMs powered off - ";
             $output = $output . $poweredon . "/" . @$vm_views . " VMs powered on";
             }
          else
             {
             $output = $suspended . "/" . @$vm_views . " VMs suspended - ";
             $output = $output . $poweredoff . "/" . @$vm_views . " VMs powered off - ";
             $output = $output . $poweredon . "/" . @$vm_views . " VMs powered on." . $multiline;
             $output = $output . $suspended_out . $poweredoff_out . $poweredon_out;
             $perfdata = "\'vms_total\'=" .  @$vm_views . ";;;; \'vms_poweredon\'=" . $poweredon . ";;;; \'vms_poweredoff\'=" . $poweredoff . ";;;; \'vms_suspended\'=" . $suspended . ";;;;";
             }
          }
       }


    if (($subselect eq "listhost") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $host_views = Vim::find_entity_views(view_type => 'HostSystem', properties => ['name', 'runtime.powerState']);

       if (!defined($host_views))
          {
          print "Runtime error\n";
          exit 2;
          }

       if (!@$host_views)
          {
          if ($subselect eq "all")
             {
             $output = $output . " - No VMware ESX hosts";
             }
          else
             {
             $output = "No VMware ESX hosts.";
             $state = 2;
             }
          }
       else
          {
          foreach $host (@$host_views)
                  {
                  $host->update_view_data(['name', 'runtime.powerState']);

                  if (defined($isregexp))
                     {
                     $isregexp = 1;
                     }
                  else
                     {
                     $isregexp = 0;
                     }
               
                  if (defined($blacklist))
                     {
                     if (isblacklisted(\$blacklist, $isregexp, $host->name))
                        {
                        next;
                        }
                     }
                  if (defined($whitelist))
                     {
                     if (isnotwhitelisted(\$whitelist, $isregexp, $host->name))
                        {
                        next;
                        }
                      }

                  $host_state = $host->get_property('runtime.powerState')->val;
                  
             
                  if ($host_state eq "poweredOn")
                     {
                     $hpoweredon++;
                     if (!$alertonly)
                        {
                        $hpoweredon_out = $hpoweredon_out . $host->name . "($host_state)" . $multiline;
                        }
                     }
                  if (($host_state eq "poweredOff") || ($host_state eq "standBy") || ($host_state eq "unknown"))
                     {
                     $hpoweredoff++;
                     $hpoweredoff_out = $hpoweredoff_out . $host->name . "($host_state)" . $multiline;
                     $actual_state = 1;
                     $state = check_state($state, $actual_state);
                     }
                  }
   
          if ($subselect eq "all")
             {
             $output = $output . " - " . $hpoweredon . "/" . @$host_views . " Hosts powered on - ";
             $output = $output . $hpoweredoff . "/" . @$host_views . " Hosts powered off/standby/unknown";
             }
          else
             {
             $output = $hpoweredon . "/" . @$host_views . " Hosts powered on - ";
             $output = $output . $hpoweredoff . "/" . @$host_views . " Hosts powered off/standby/unknown" . $multiline;
             $output = $output . $hpoweredoff_out . $hpoweredon_out;
             }
          }
       }
  
    if (($subselect =~ m/listcluster.*$/) || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $cluster_views = Vim::find_entity_views(view_type => 'ClusterComputeResource', properties => ['name', 'overallStatus']);

       if (!defined($cluster_views))
          {
          print "Runtime error\n";
          exit 2;
          }

       if (!@$cluster_views)
          {
          if ($subselect eq "all")
             {
             $output = $output . " - No VMware Clusters";
             }
          else
             {
             $output = "No VMware Clusters.";
             }
          }
       else
          {
          foreach $cluster (@$cluster_views)
                  {
                  $cluster->update_view_data(['name', 'overallStatus']);

                  if (defined($isregexp))
                     {
                     $isregexp = 1;
                     }
                  else
                     {
                     $isregexp = 0;
                     }
               
                  if (defined($blacklist))
                     {
                     if (isblacklisted(\$blacklist, $isregexp, $cluster->name))
                        {
                        next;
                        }
                     }
                  if (defined($whitelist))
                     {
                     if (isnotwhitelisted(\$whitelist, $isregexp, $cluster->name))
                        {
                        next;
                        }
                      }

                  $cluster_state = $cluster->get_property('overallStatus')->val;

                  if ($cluster_state eq "green")
                     {
                     $cluster_green_cnt++;
                     if (!$alertonly)
                        {
                        $cluster_green_out = $cluster_green_out . $cluster->name . " (" . $cluster_state . ")" . $multiline;
                        $actual_state = check_health_state($cluster_state);
                        $state = check_state($state, $actual_state);
                        }
                     }
                  if ($cluster_state eq "gray")
                     {
                     $cluster_gray_cnt++;
                     $cluster_gray_out = $cluster_gray_out . $cluster->name . " (" . $cluster_state . ")" . $multiline;
                     $actual_state = check_health_state($cluster_state);
                     $state = check_state($state, $actual_state);
                     }
                  if ($cluster_state eq "red")
                     {
                     $cluster_red_cnt++;
                     $cluster_red_out = $cluster_red_out . $cluster->name . " (" . $cluster_state . ")" . $multiline;
                     $actual_state = check_health_state($cluster_state);
                     $state = check_state($state, $actual_state);
                     }
                  if ($cluster_state eq "yellow")
                     {
                     $cluster_yellow_cnt++;
                     $cluster_yellow_out = $cluster_yellow_out . $cluster->name . " (" . $cluster_state . ")" . $multiline;
                     $actual_state = check_health_state($cluster_state);
                     $state = check_state($state, $actual_state);
                     }
                  }

          if ($subselect eq "all")
             {
             $output = $output . " - " . $cluster_green_cnt . "/" . @$cluster_views . " Clusters green - ";
             $output = $output . $cluster_red_cnt . "/" . @$cluster_views . " Clusters red - ";
             $output = $output . $cluster_yellow_cnt . "/" . @$cluster_views . " Clusters yellow - ";
             $output = $output . $cluster_gray_cnt . "/" . @$cluster_views . " Clusters gray";
             }
          else
             {
             $output = $cluster_green_cnt . "/" . @$cluster_views . " Clusters green - ";
             $output = $output . $cluster_red_cnt . "/" . @$cluster_views . " Clusters red - ";
             $output = $output . $cluster_yellow_cnt . "/" . @$cluster_views . " Clusters yellow - ";
             $output = $output . $cluster_gray_cnt . "/" . @$cluster_views . " Clusters gray" . $multiline;
             $output = $output . $cluster_red_out . $cluster_yellow_out . $cluster_gray_out . $cluster_green_out;
             }
          }
       }
    
    if (($subselect eq "tools") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;

       $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'runtime.powerState', 'summary.guest']);

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

       
       foreach $vm (@$vm_views)
               {
               $vm_cnt++;

               if (defined($isregexp))
                  {
                  $isregexp = 1;
                  }
               else
                  {
                  $isregexp = 0;
                  }
            
               if (defined($blacklist))
                  {
                  if (isblacklisted(\$blacklist, $isregexp, $vm->name))
                     {
                     $vm_ignored_cnt++;
                     next;
                     }
                  }
               if (defined($whitelist))
                  {
                  if (isnotwhitelisted(\$whitelist, $isregexp, $vm->name))
                     {
                     $vm_ignored_cnt++;
                     next;
                     }
                  }

# VirtualMachineToolsRunningStatus
# guestToolsExecutingScripts  VMware Tools is starting.
# guestToolsNotRunning        VMware Tools is not running.
# guestToolsRunning           VMware Tools is running. 
       
# VirtualMachineToolsVersionStatus
# guestToolsBlacklisted       VMware Tools is installed, but the installed version is known to have a grave bug and should be immediately upgraded.
# Since vSphere API 5.0
# guestToolsCurrent           VMware Tools is installed, and the version is current.
# guestToolsNeedUpgrade       VMware Tools is installed, but the version is not current.
# guestToolsNotInstalled      VMware Tools has never been installed.
# guestToolsSupportedNew      VMware Tools is installed, supported, and newer than the version available on the host.
# Since vSphere API 5.0
# guestToolsSupportedOld      VMware Tools is installed, supported, but a newer version is available.
# Since vSphere API 5.0
# guestToolsTooNew            VMware Tools is installed, and the version is known to be too new to work correctly with this virtual machine.
# Since vSphere API 5.0
# guestToolsTooOld            VMware Tools is installed, but the version is too old.
# Since vSphere API 5.0
# guestToolsUnmanaged         VMware Tools is installed, but it is not managed by VMWare. 

               if ($vm->get_property('runtime.powerState')->val eq "poweredOn")
                  {
                  $vm_guest = $vm->get_property('summary.guest');

                  if (exists($vm_guest->{toolsVersionStatus}) && defined($vm_guest->toolsVersionStatus) && exists($vm_guest->{toolsRunningStatus}) && defined($vm_guest->toolsRunningStatus))
                     {
                     if ($vm_guest->toolsVersionStatus ne "guestToolsNotInstalled")
                        {
                        if ($vm_guest->toolsRunningStatus ne "guestToolsNotRunning")
                           {
                           if ($vm_guest->toolsRunningStatus ne "guestToolsExecutingScripts")
                              {
                              if ($vm_guest->toolsVersionStatus eq "guestToolsBlacklisted")
                                 {
                                 $guestToolsBlacklisted_cnt++;
                                 $tools_out = $tools_out . "VM " . $vm->name . ": Installed,running,but the installed ";
                                 $tools_out = $tools_out ."version is known to have a grave bug and should ";
                                 $tools_out = $tools_out ."be immediately upgraded." . $multiline;
                                 $actual_state = 2; 
                                 $vm_bad_cnt++;
                                 $state = check_state($state, $actual_state);
                                 }
                              if ($vm_guest->toolsVersionStatus eq "guestToolsCurrent")
                                 {
                                 $guestToolsCurrent_cnt++;
                                 if (!$alertonly)
                                    {
                                    $actual_state = 0;
                                    $state = check_state($state, $actual_state);
                                    }
                                 }
                              if ($vm_guest->toolsVersionStatus eq "guestToolsNeedUpgrade")
                                 {
                                 $guestToolsNeedUpgrade_cnt++;
                                 $tools_out = $tools_out . "VM " . $vm->name . ": Installed,running,version is not current." . $multiline;
                                 $actual_state = 1;
                                 $vm_bad_cnt++;
                                 $state = check_state($state, $actual_state);
                                 }
                              if ($vm_guest->toolsVersionStatus eq "guestToolsSupportedNew")
                                 {
                                 $guestToolsSupportedNew_cnt++;
                                 $tools_out = $tools_out . "VM " . $vm->name . ": Installed,running,supported and newer than the ";
                                 $tools_out = $tools_out ."version available on the host." . $multiline;
                                 $actual_state = 1;
                                 $vm_bad_cnt++;
                                 $state = check_state($state, $actual_state);
                                 }
                              if ($vm_guest->toolsVersionStatus eq "guestToolsSupportedOld")
                                 {
                                 $guestToolsSupportedOld_cnt++;
                                 $tools_out = $tools_out . "VM " . $vm->name . ": Installed,running,supported, but a newer version is available." . $multiline;
                                 $actual_state = 1;
                                 $vm_bad_cnt++;
                                 $state = check_state($state, $actual_state);
                                 }
                              if ($vm_guest->toolsVersionStatus eq "guestToolsTooNew")
                                 {
                                 $guestToolsTooNew_cnt++;
                                 $tools_out = $tools_out . "VM " . $vm->name . ": Installed,running,but the version is known to be too new " . $multiline;
                                 $tools_out = $tools_out ."to work correctly with this virtual machine.";
                                 $actual_state = 2;
                                 $vm_bad_cnt++;
                                 $state = check_state($state, $actual_state);
                                 }
                              if ($vm_guest->toolsVersionStatus eq "guestToolsTooOld")
                                 {
                                 $guestToolsTooOld_cnt++;
                                 $tools_out = $tools_out . "VM " . $vm->name . ": Installed,running,but the version is too old." . $multiline;
                                 $actual_state = 1;
                                 $vm_bad_cnt++;
                                 $state = check_state($state, $actual_state);
                                 }
                              if ($vm_guest->toolsVersionStatus eq "guestToolsUnmanaged")
                                 {
                                 $guestToolsUnmanaged_cnt++;
                                 $tools_out = $tools_out . "VM " . $vm->name . ": Installed,running,but not managed by VMWare. " . $multiline;
                                 $actual_state = 2;
                                 $vm_bad_cnt++;
                                 $state = check_state($state, $actual_state);
                                 }
                              }
                           else
                              {
                              $guestToolsUnknown_cnt++;
                              $actual_state = 0;
                              $state = check_state($state, $actual_state);
                              }
                           }
                        else
                           {
                           $guestToolsNotRunning_cnt++;
                           $tools_out = $tools_out . "VM " . $vm->name . ": Tools not running." . $multiline;
                           $actual_state = 1;
                           $vm_bad_cnt++;
                           $state = check_state($state, $actual_state);
                           }
                        }
                     else
                        {
                        $guestToolsNotInstalled_cnt++;
                        $tools_out = $tools_out . "VM " . $vm->name . ": Tools not installed." . $multiline;
                        $actual_state = 1;
                        $vm_bad_cnt++;
                        $state = check_state($state, $actual_state);
                        }
                     }
                  else
                     {
                     $guestToolsUnknown_cnt++;
                     $tools_out = $tools_out . "VM " . $vm->name . ": No information about VMware tools available. Please check!" . $multiline;
                     $actual_state = 1;
                     $vm_bad_cnt++;
                     $state = check_state($state, $actual_state);
                     }
                  }
               else
                  {
                  if (!defined($vm_tools_poweredon_only))
                     {
                     if ($vm->get_property('runtime.powerState')->val eq "poweredOff")
                        {
                        $guestToolsPOF_cnt++;
                        $actual_state = 0;
                        $state = check_state($state, $actual_state);
                        }
                     if ($vm->get_property('runtime.powerState')->val eq "suspended")
                        {
                        $guestToolsSuspendePOF_cnt++;
                        $actual_state = 0;
                        $state = check_state($state, $actual_state);
                        }
                     }
                  }
               }

       if ($subselect eq "all")
          {
          $output = $output . $vm_cnt . " VMs checked for VMWare Tools state, " . $vm_bad_cnt . " are not OK.";
          }
       else
          {
          $output = $output . $vm_cnt . " VMs checked for VMWare Tools state, " . $vm_bad_cnt . " are not OK.";
          $output = $output . $multiline . $tools_out;
          }
       }
    

    if (($subselect eq "status") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['name', 'overallStatus']);
       $actual_state = 0;

       if (!defined($dc_views))
          {
          print "There is no datacenter\n";
          exit 2;
          }

       foreach $dc (@$dc_views)
               {
               if (defined($dc->overallStatus))
                  {
                  $overallStatus = $dc->overallStatus->val;

                  if ($overallStatus eq "green")
                     {
                     $vc_green_cnt++;
                     $tmp_output = $tmp_output . $dc->name . " overall status=" . $overallStatus . $multiline;
                     $actual_state = check_health_state($overallStatus);
                     $state = check_state($state, $actual_state);
                     }
                  if ($overallStatus eq "gray")
                     {
                     $vc_gray_cnt++;
                     $tmp_output = $tmp_output . $dc->name . " overall status=" . $overallStatus . $multiline;
                     $actual_state = check_health_state($overallStatus);
                     $state = check_state($state, $actual_state);
                     }
                  if ($overallStatus eq "red")
                     {
                     $vc_red_cnt++;
                     $tmp_output = $tmp_output . $dc->name . " overall status=" . $overallStatus . $multiline;
                     $actual_state = check_health_state($overallStatus);
                     $state = check_state($state, $actual_state);
                     }
                  if ($overallStatus eq "yellow")
                     {
                     $vc_yellow_cnt++;
                     $tmp_output = $tmp_output . $dc->name . " overall status=" . $overallStatus . $multiline;
                     $actual_state = check_health_state($overallStatus);
                     $state = check_state($state, $actual_state);
                     }
                  }
               else
                  {
                  $actual_state = 1;
                  $state = check_state($state, $actual_state);
                  $tmp_output = $tmp_output . "Maybe insufficient rights to access " . $dc->name . " status info on the DC" . $multiline;
                  }
               }

       if ($subselect eq "all")
          {
          $output = $output . " - " . $vc_green_cnt . "/" . @$dc_views . " Vcenters green - ";
          $output = $output . $vc_red_cnt . "/" . @$dc_views . " Vcenters red - ";
          $output = $output . $vc_yellow_cnt . "/" . @$dc_views . " Vcenters yellow - ";
          $output = $output . $vc_gray_cnt . "/" . @$dc_views . " Vcenters gray";
          }
       else
          {
          $output = $vc_green_cnt . "/" . @$dc_views . " Vcenters green - ";
          $output = $output . $vc_red_cnt . "/" . @$dc_views . " Vcenters red - ";
          $output = $output . $vc_yellow_cnt . "/" . @$dc_views . " Vcenters yellow - ";
          $output = $output . $vc_gray_cnt . "/" . @$dc_views . " Vcenters gray" . $multiline . $tmp_output;
          }
       }
    
    
    if (($subselect eq "issues") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['name', 'configIssue']);
       $actual_state = 0;

       if (!defined($dc_views))
          {
          print "There is no datacenter\n";
          exit 2;
          }

       foreach $dc (@$dc_views)
               {
               $issues = $dc->configIssue;
               if (defined($issues))
                  {
                  $actual_state = 1;
                  foreach (@$issues)
                          {
                          $vc_name = ref($_);
                          $issue_cnt++;
                          if (defined($isregexp))
                             {
                             $isregexp = 1;
                             }
                          else
                             {
                             $isregexp = 0;
                             }
                       
                          if (defined($blacklist))
                             {
                             if (isblacklisted(\$blacklist, $isregexp, $vc_name))
                                {
                                $issues_ignored_cnt++;
                                next;
                                }
                             }
                          if (defined($whitelist))
                             {
                             if (isnotwhitelisted(\$whitelist, $isregexp, $vc_name))
                                {
                                $issues_ignored_cnt++;
                                next;
                                }
                              }
                          $issue_out = $issue_out . format_issue($_) . " (" . $dc->name . ")" . $multiline;
                          }
                  }
               }

       if ($subselect eq "all")
          {
          $output = $output . " - " . $issue_cnt . " config issues  - " . $issues_ignored_cnt  . " config issues ignored";
          }
       else
          {
          $output = $issue_cnt . " config issues - " . $issues_ignored_cnt  . " config issues ignored" . $multiline . $issue_out;
          }
       $state = check_state($state, $actual_state);
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown DC RUNTIME subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
