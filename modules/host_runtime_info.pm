sub host_runtime_info
    {
    my ($host, $maintenance_mode_state) = @_;
    my $charging;
    my $summary;
    my $sensorname;
    my $state = 0;
    my $actual_state;
    my $output = '';
    my $runtime;
    my $host_view;
    my %base_units = (
                     'Degrees C' => 'C',
                     'Degrees F' => 'F',
                     'Degrees K' => 'K',
                     'Volts' => 'V',
                     'Amps' => 'A',
                     'Watts' => 'W',
                     'Percentage' => 'Pct'
                     );
    my $components = {};
    my $cpuStatusInfo;
    my $curstate;
    my $fstate;
    my %host_maintenance_state;
    my $issues;
    my $issue_out = '';
    my $issue_cnt = 0;
    my $issues_ignored_cnt = 0;
    my $issues_alarm_cnt = 0;
    my $itemref;
    my $item_ref;
    my $memoryStatusInfo;
    my $name;
    my $numericSensorInfo;;
    my $OKCount;
    my $SensorCount;
    my $status;
    my $storageStatusInfo;;
    my $type;
    my $unit;
    my $poweredon = 0;         # Virtual machine powerstate
    my $poweredoff = 0;        # Virtual machine powerstate
    my $suspended = 0;         # Virtual machine powerstate
    my $poweredon_out = '';    # Virtual machine powerstate temporary output
    my $poweredoff_out = '';   # Virtual machine powerstate temporary output
    my $suspended_out = '';    # Virtual machine powerstate temporary output
    my $value;
    my $stor_path;
    my $vm;
    my $vm_state;
    my $vm_views;
    my $true_sub_sel=1;        # Just a flag. To have only one return at the en
                               # we must ensure that we had a valid subselect. If
                               # no subselect is given we select all
                               # 0 -> existing subselect
                               # 1 -> non existing subselect

    if ((!defined($subselect)) || ($subselect eq "health"))
       {
       if ( $perf_thresholds ne ";")
          {
          print "Error! Thresholds are only allowed with subselects but ";
          print "not with --subselect=health !\n";
          exit 2;
          }
       }

    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       $true_sub_sel = 0;
       }


    if ((defined($listsensors)) && ($subselect ne "health"))
       {
       print "Error! --listsensors only allowed whith -s health!\n";
       exit 2;
       }
       
    $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'runtime', 'overallStatus', 'configIssue']);

    if (!defined($host_view))
       {
       print "Host " . $$host{"name"} . " does not exist\n";
       exit 2;
       }

    $host_view->update_view_data(['name', 'runtime', 'overallStatus', 'configIssue', 'summary.config.product.fullName']);
    $runtime = $host_view->runtime;

    if ($runtime->inMaintenanceMode)
       {
       print "Notice: " . $host_view->name . " is in maintenance mode, check skipped\n";
       exit $maintenance_mode_state;
       }

    if (($subselect eq "listvms") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (!defined($vm_tools_poweredon_only))
          {
          $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $host_view, properties => ['name', 'runtime']);
          }
       else
          {
          $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', filter => {'runtime.powerState' => 'poweredOn'}, begin_entity => $host_view, properties => ['name', 'runtime']);
          }

       if (!defined($vm_views))
          {
          print "Runtime error\n";
          exit 2;
          }
       if (!@$vm_views)
          {
          if ($subselect eq "all")
             {
             $output = $output . "No VMs - ";
             }
          else
             {
             $output = "No VMs - ";
             }
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

                  if (defined $show_storage)
                     {
                     $stor_path = vm_storage_path($vm->name);
                     }
                  
                  if ($vm_state eq "poweredOn")
                     {
                     $poweredon++;
                     if (!$alertonly)
                        {
                        if (defined $show_storage)
                           {
                           $poweredon_out = $poweredon_out . $vm->name . " (" . $vm_state . ") - Storage: " .$stor_path . $multiline;
                           }
                        else
                           {
                           $poweredon_out = $poweredon_out . $vm->name . " (" . $vm_state . ")" . $multiline;
                           }
                        }
                     }
                  if ($vm_state eq "poweredOff")
                     {
                     $poweredoff++;
                     if (defined $show_storage)
                        {
                        $poweredon_out = $poweredoff_out . $vm->name . " (" . $vm_state . ") - Storage: " .$stor_path . $multiline;
                        }
                        else
                        {
                        $poweredon_out = $poweredoff_out . $vm->name . " (" . $vm_state . ")" . $multiline;
                        }
                     }
                  if ($vm_state eq "suspended")
                     {
                     $suspended++;
                     if (defined $show_storage)
                        {
                        $suspended_out = $suspended_out . $vm->name . " (" . $vm_state . ") - Storage: " .$stor_path . $multiline;
                        }
                        else
                        {
                        $suspended_out = $suspended_out . $vm->name . " (" . $vm_state . ")" . $multiline;
                        }
                     }
                  }

          if ($subselect eq "all")
             {
             $output = $suspended . "/" . @$vm_views . " VMs suspended - ";
             $output = $output . $poweredoff . "/" . @$vm_views . " VMs powered off - ";
             $output = $output . $poweredon . "/" . @$vm_views . " VMs powered on - ";
             }
          else
             {
             $output = $suspended . "/" . @$vm_views . " VMs suspended - ";
             $output = $output . $poweredoff . "/" . @$vm_views . " VMs powered off - ";
             $output = $output . $poweredon . "/" . @$vm_views . " VMs powered on." . $multiline;
             $output = $output . $suspended_out . $poweredoff_out . $poweredon_out;
             $perfdata = "vms_total=" .  @$vm_views . ";;;; vms_poweredon=" . $poweredon . ";;;; vms_poweredoff=" . $poweredoff . ";;;; vms_suspended=" . $suspended . ";;;;";
             }
          }
       }

    if (($subselect eq "status") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $status = $host_view->overallStatus->val;
       if ($subselect eq "all")
          {
          $output = $output . "overallstatus=" . $status;
          }
       else
          {
          $output = "overall status=" . $status;
          }
       $state = check_health_state($status);
       }

    if (($subselect eq "con") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;

       if (lc($runtime->connectionState->val) eq "disconnected")
          {
          $state = 1;
          }
       if (lc($runtime->connectionState->val) eq "notResponding")
          {
          $state = 2;
          }

       if ($subselect eq "all")
          {
          $output = $output . " - connection state=" . $runtime->connectionState->val;
          }
       else
          {
          $output = "connection state=" . $runtime->connectionState->val;
          }
       }

    if ((($subselect eq "health") || ($subselect eq "all")) && (not defined($ignorehealth)))
       {
       $true_sub_sel = 0;
       $OKCount = 0;
       $AlertCount = 0;

       if (defined($runtime->healthSystemRuntime))
          {
          if (defined($runtime->healthSystemRuntime->hardwareStatusInfo)) {
            $cpuStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->cpuStatusInfo;
            $storageStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->storageStatusInfo;
            $memoryStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->memoryStatusInfo;
          }
          $numericSensorInfo = $runtime->healthSystemRuntime->systemHealthInfo->numericSensorInfo;

          if (defined($cpuStatusInfo))
             {
             foreach (@$cpuStatusInfo)
                     {
                     $actual_state = check_health_state($_->status->key);

                     # Ejection seat for not running CIM Server
                     if ($actual_state == 3)
                        {
                        print "Critical! No result from CIM server regarding health state. CIM server is probably not running or not running correctly! Please restart!\n";
                        exit 2;
                        }
                        
                     $itemref = {
                                name => $_->name,
                                summary => $_->status->summary
                                };
                     push(@{$components->{$actual_state}{CPU}}, $itemref);
                     if ($actual_state != 0)
                        {
                        $state = check_state($state, $actual_state);
                        $AlertCount++;
                        }
                     else
                        {
                        $OKCount++;
                        }
                     }
             }

          if (!defined($nostoragestatus))
             {
             if (defined($storageStatusInfo))
                {
                foreach (@$storageStatusInfo)
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
                           if (isblacklisted(\$blacklist, $isregexp, $_->name, "Storage"))
                              {
                              next;
                              }
                           }
     
                        if (defined($whitelist))
                           {
                           if (isnotwhitelisted(\$whitelist, $isregexp, $_->name, "Storage"))
                              {
                              next;
                              }
                           }
   
                        $actual_state = check_health_state($_->status->key);
                        $itemref = {
                                   name => $_->name,
                                   summary => $_->status->summary
                                   };

                        if ($actual_state == 3)
                           {
                              # Ignore unknown sensors
                              # https://kb.vmware.com/s/article/57171
                              next;
                           }
                        else
                           {
                           # Only add state for component if it is not unknown
                           push(@{$components->{$actual_state}{Storage}}, $itemref);

                           if ($actual_state != 0)
                              {
                              $state = check_state($state, $actual_state);
                              $AlertCount++;
                              }
                           else
                              {
                              $OKCount++;
                              }
                           }
                        }
                }
             }

          if (defined($memoryStatusInfo))
             {
             foreach (@$memoryStatusInfo)
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
                        if (isblacklisted(\$blacklist, $isregexp, $_->name, "Memory"))
                           {
                           next;
                           }
                        }
  
                     if (defined($whitelist))
                        {
                        if (isnotwhitelisted(\$whitelist, $isregexp, $_->name, "Memory"))
                           {
                           next;
                           }
                        }
                     
                     $actual_state = check_health_state($_->status->key);
                     $itemref = {
                                name => $_->name,
                                summary => $_->status->summary
                                };
                     push(@{$components->{$actual_state}{Memory}}, $itemref);
                     
                     if ($actual_state == 3)
                        {
                           # Ignore unknown sensors
                           # https://kb.vmware.com/s/article/57171
                           next;
                        }
                     else
                        {
                        if ($actual_state != 0)
                           {
                           $state = check_state($state, $actual_state);
                           $AlertCount++;
                           }
                        else
                           {
                           $OKCount++;
                           }
                        }
                     }
             }

          if (defined($numericSensorInfo))
             {
             foreach (@$numericSensorInfo)
                     {
                     # Just for debugging. comment it out and see what happens :-))
                     #print "Debug: Sensor Name = ". $_->name;
                     #print ", Type = " . $_->sensorType;
                     #print ", Label = ". $_->healthState->label;
                     #print ", Summary = ". $_->healthState->summary;
                     #print ", Key = " . $_->healthState->key;
                     #print ", Current Reading = " . $_->currentReading;
                     #print ", Unit Modifier = " . $_->unitModifier;
                     #print ", Baseunits  = " . $_->baseUnits . "\n";
                    
                     # Filter out software components. Doesn't make sense here
                     if ( $_->sensorType eq "Software Components" )
                        {
                        next;
                        }

                     # Filter out sensors which have not valid data. Often a sensor is reckognized by vmware 
                     # but has not the ability to report something senseful. So it can be skipped.
                     if (( $_->healthState->label =~ m/unknown/i ) && ( $_->healthState->summary  =~ m/Cannot report/i ))
                        {
                        next;
                        }

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
                        if (isblacklisted(\$blacklist, $isregexp, $_->name, $_->sensorType))
                           {
                           next;
                           }
                        }
  
                     if (defined($whitelist))
                        {
                        if (isnotwhitelisted(\$whitelist, $isregexp, $_->name, $_->sensorType))
                           {
                           next;
                           }
                     }
                     
                     $actual_state = check_health_state($_->healthState->key);
                     $itemref = {
                                name => $_->name,
                                summary => $_->healthState->summary,
                                label => $_->healthState->label
                                };
                     push(@{$components->{$actual_state}{$_->sensorType}}, $itemref);
                     
                     if ($actual_state == 3)
                        {
                           # Ignore unknown sensors
                           # https://kb.vmware.com/s/article/57171
                           next;
                        }
                     else
                        {
                        if ($actual_state != 0)
                           {
                           $state = check_state($state, $actual_state);
                           $AlertCount++;
                           }
                        else
                           {
                           $OKCount++;
                           }
                        }
                     }
             }

          if ($listsensors)
             {
             foreach $fstate (reverse(sort(keys(%$components))))
                     {
                     foreach $actual_state_ref ($components->{$fstate})
                             {
                             foreach $type (keys(%$actual_state_ref))
                                     {
                                     foreach $item_ref (@{$actual_state_ref->{$type}})
                                             {
                                             $output = $output . "[$status2text{$fstate}] [Type: $type] [Name: $item_ref->{name}] [Label: $item_ref->{label}] [Summary: $item_ref->{summary}]$multiline";
                                             }
                                     }
                             }
                     }
             }
          else
             {
             # From here on perform output of health
             if ($AlertCount > 0)
                {
                if ($subselect eq "all")
                   {
                   $output = $output . " - $AlertCount health issue(s) found in " . ($AlertCount + $OKCount) . " checks";
                   }
                else
                   {
                   $output = "$AlertCount health issue(s) found in " . ($AlertCount + $OKCount) . " checks: ";
                   }
                
                $AlertIndex = 0;
                
                if ($subselect ne "all")
                   {
                   foreach $fstate (reverse(sort(keys(%$components))))
                           {
                           if ($fstate == 0)
                              {
                              next;
                              }
                           foreach $actual_state_ref ( $components->{$fstate})
                                   {
                                   foreach $type ( keys(%$actual_state_ref))
                                           {
                                           foreach $item_ref (@{$actual_state_ref->{$type}})
                                                   {
                                                   if (!$item_ref->{name})
                                                      {
                                                      $item_ref->{name} = "Unknown";
                                                      }
                                                   if (!$item_ref->{label})
                                                      {
                                                      $item_ref->{label} = "Unknown";
                                                      }
                                                   if (!$item_ref->{summary})
                                                      {
                                                      $item_ref->{summary} = "Unknown";
                                                      }
                                                   $output = $output . ++$AlertIndex . ") [$status2text{$fstate}] [Type: $type] [Name: $item_ref->{name}] [Label: $item_ref->{label}] [Summary: $item_ref->{summary}]$multiline";
                                                   }
                                           }
                                   }
                           }
                   }
                }
             else
                {
                if ($subselect eq "all")
                   {
                   $output = $output . " - All $OKCount health checks are GREEN:";
                   }
                else
                   {
                   $output = "All $OKCount health checks are GREEN:";
                   }
                $actual_state = 0;
                $state = check_state($state, $actual_state);
                foreach $type (keys(%{$components->{0}}))
                        {
                        $output = $output . " " . $type . " (" . (scalar(@{$components->{0}{$type}})) . "x),";
                        }
                chop ($output);
                }
             }
          }
       else
          {
          $output = "System health status unavailable";
          }
       }

    if ($subselect eq "storagehealth")
       {
       $OKCount = 0;
       $AlertCount = 0;
       $components = {};
       $state = 3;

       if(defined($runtime->healthSystemRuntime) && defined($runtime->healthSystemRuntime->hardwareStatusInfo->storageStatusInfo))
         {
         $storageStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->storageStatusInfo;
         $output = '';
         foreach (@$storageStatusInfo)
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
                   if (isblacklisted(\$blacklist, $isregexp, $_->name))
                      {
                      next;
                      }
                   }
                if (defined($whitelist))
                   {
                   if (isnotwhitelisted(\$whitelist, $isregexp, $_->name))
                      {
                      next;
                      }
                }
                 
                $actual_state = check_health_state($_->status->key);
                $sensortype = $_->name;
                $components->{$actual_state}{"Storage"}{$_->name} = $_->status->summary;
                 
                if ($actual_state != 0)
                   {
                   $state = check_state($state, $actual_state);
                   $AlertCount++;
                   }
                else
                   {
                   $OKCount++;
                   }
                }

                foreach $fstate (reverse(sort(keys(%$components))))
                        {
                        foreach $actual_state_ref ($components->{$fstate})
                                {
                                foreach $type (keys(%$actual_state_ref))
                                        {
                                        foreach $name (keys(%{$actual_state_ref->{$type}}))
                                                {
                                                $output = $output . "$status2text{$fstate}: Status of $name: $actual_state_ref->{$type}{$name}$multiline";
                                                }
                                        }
                                }
                        }

                if ($AlertCount > 0)
                   {
                   $output = "$AlertCount health issue(s) found. $multiline" . $output;
                   }
                else
                   {
                   $output = "All $OKCount Storage health checks are GREEN. $multiline" . $output;
                   $state = 0;
                   }
         }
      else
         {
         $state = 3;
         $output = "Storage health status unavailable";
         }
       return ($state, $output);
       }

    if ($subselect eq "temp")
       {
       $OKCount = 0;
       $AlertCount = 0;
       $components = {};
       $state = 3;

       if (defined($runtime->healthSystemRuntime))
          {
          $numericSensorInfo = $runtime->healthSystemRuntime->systemHealthInfo->numericSensorInfo;
          $output = '';

          if (defined($numericSensorInfo))
             {
             foreach (@$numericSensorInfo)
                     {
                     if (lc($_->baseUnits) !~ m/^degrees.*/)
                        {
                        next;
                        }
                     
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
                        if (isblacklisted(\$blacklist, $isregexp, $_->name))
                           {
                           next;
                           }
                        }
                     if (defined($whitelist))
                        {
                        if (isnotwhitelisted(\$whitelist, $isregexp, $_->name))
                           {
                           next;
                           }
                        }
                     
                     $actual_state = check_health_state($_->healthState->key);
                     $_->name =~ m/(.*?)\s-.*$/;
                     $itemref = {
                                name => $1,
                                power10 => $_->unitModifier,
                                state => $_->healthState->key,
                                value => $_->currentReading,
                                unit => $_->baseUnits,
                                };
                     push(@{$components->{$actual_state}}, $itemref);
                     if ($actual_state != 0)
                        {
                        $state = check_state($state, $actual_state);
                        $AlertCount++;
                        }
                     else
                        {
                        $OKCount++;
                        }
                        
                     if (exists($base_units{$itemref->{unit}}))
                        {
                        $perfdata = $perfdata . " \'" . $itemref->{name} . "\'=" . ($itemref->{value} * 10 ** $itemref->{power10}) . $base_units{$itemref->{unit}} . ";;;;";
                        }
                        else
                        {
                        $perfdata = $perfdata . " \'" . $itemref->{name} . "\'=" . ($itemref->{value} * 10 ** $itemref->{power10}) . ";;;;";
                        }
                     }
             }

          foreach $curstate (reverse(sort(keys(%$components))))
                  {
                  foreach $itemref (@{$components->{$curstate}})
                          {
                          $value = $itemref->{value} * 10 ** $itemref->{power10};
                          $unit = exists($base_units{$itemref->{unit}}) ? $base_units{$itemref->{unit}} : '';
                          $name = $itemref->{name};
                          if ($output)
                             {
                             $output = $output . $multiline;
                             }
                          $output = $output . $status2text{$curstate} . ": " . $name . " = " . $value . $unit;
                          }
                  }

               if ($AlertCount > 0)
                  {
                  $output = "$AlertCount temperature issue(s) found.". $multiline . $output;
                  }
               else
                  {
                  $output = "All $OKCount temperature checks are GREEN." . $multiline . $output;
                  $state = 0;
                  }                               
          }
       else
          {
          $output = "Temperature status unavailable";
          }
       return ($state, $output);
       }


    if ($subselect eq "version")
       {
       $output = $host_view->get_property('summary.config.product.fullName');
       $state = 0;
       return ($state, $output);
       }

    if (($subselect eq "issues") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $issues = $host_view->configIssue;
       $actual_state = 0;

       if (defined($issues))
          {
          foreach (@$issues)
                  {
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
                     if (isblacklisted(\$blacklist, $isregexp, $_->fullFormattedMessage))
                        {
                        $issues_ignored_cnt++;
                        next;
                        }
                     }
                  if (defined($whitelist))
                     {
                     if (isnotwhitelisted(\$whitelist, $isregexp, $_->fullFormattedMessage))
                        {
                        $issues_ignored_cnt++;
                        next;
                        }
                     }
                  $issue_out = $issue_out . format_issue($_) . $multiline;
                  }
          }

       $issues_alarm_cnt = $issue_cnt - $issues_ignored_cnt;

       if ($issues_alarm_cnt > 0)
          {
          $actual_state = 1;
          }
       else
          {
          $actual_state = 0;
          }
       
       $state = check_state($state, $actual_state);
          
       if ($subselect eq "all")
          {
          $output = $output . " - " . $issue_cnt . " config issues  - " . $issues_ignored_cnt  . " config issues ignored";
          }
       else
          {
          $output = $issue_cnt . " config issues - " . $issues_ignored_cnt  . " config issues ignored" . $multiline . $issue_out;
          }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown HOST RUNTIME subselect");
       }
    else
       {
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
