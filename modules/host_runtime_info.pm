sub host_runtime_info
    {
    my ($host) = @_;
    # Modification by M.Obstmayer adapted by M.Fuerstenau
    #----------------------------------------------
    my $charging;
    my $summary;
    #----------------------------------------------
    my $state = 2;
    my $output;
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
    my $up;
    my $value;
    my $vm;
    my $vm_state;
    my %vm_state_strings;
    my $vm_views;
       
    $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'runtime', 'overallStatus', 'configIssue']);

    if (!defined($host_view))
       {
       print "Host " . $$host{"name"} . " does not exist\n";
       exit 2;
       }

    $host_view->update_view_data(['name', 'runtime', 'overallStatus', 'configIssue']);
    $runtime = $host_view->runtime;

    if ($runtime->inMaintenanceMode)
       {
       print "Notice: " . $host_view->name . " is in maintenance mode, check skipped\n";
       exit 0;
       }

    if (defined($subselect))
       {
       if ($subselect eq "con")
          {
          $output = "connection state=" . $runtime->connectionState->val;
          if (uc($runtime->connectionState->val) eq "CONNECTED")
             {
             $state = 0;
             }
          return ($state, $output);
          }

       if ($subselect eq "health")
          {
          $OKCount = 0;
          $AlertCount = 0;
          $state = 3;

          if (defined($runtime->healthSystemRuntime))
             {
             $cpuStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->cpuStatusInfo;
             $storageStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->storageStatusInfo;
             $memoryStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->memoryStatusInfo;
             $numericSensorInfo = $runtime->healthSystemRuntime->systemHealthInfo->numericSensorInfo;

             $output = '';

             if (defined($cpuStatusInfo))
                {
                foreach (@$cpuStatusInfo)
                        {
                        # print "CPU Name = ". $_->name .", Label = ". $_->status->label . ", Summary = ". $_->status->summary . ", Key = ". $_->status->key . "\n";
                        if (defined($blacklist))
                           {
                           if (isblacklisted(\$blacklist, $blackregexpflag, $_->name, "CPU"))
                              {
                              next;
                              }
                           }
                        if (defined($whitelist))
                           {
                           if (isnotwhitelisted(\$whitelist, $whiteregexpflag, $_->name, "CPU"))
                              {
                              next;
                              }
                           }
                        $actual_state = check_health_state($_->status->key);
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

             if (defined($storageStatusInfo))
                {
                foreach (@$storageStatusInfo)
                        {
                        # print "Storage Name = ". $_->name .", Label = ". $_->status->label . ", Summary = ". $_->status->summary . ", Key = ". $_->status->key . "\n";
                        if (defined($blacklist))
                           {
                           if (isblacklisted(\$blacklist, $blackregexpflag, $_->name, "Storage"))
                              {
                              next;
                              }
                           }
  
                        if (defined($whitelist))
                           {
                           if (isnotwhitelisted(\$whitelist, $whiteregexpflag, $_->name, "Storage"))
                              {
                              next;
                              }
                           }

                        $actual_state = check_health_state($_->status->key);
                        $itemref = {
                                   name => $_->name,
                                   summary => $_->status->summary
                                   };
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

             if (defined($memoryStatusInfo))
                {
                foreach (@$memoryStatusInfo)
                        {
                        # print "Memory Name = ". $_->name .", Label = ". $_->status->label . ", Summary = ". $_->status->summary . ", Key = ". $_->status->key . "\n";
                        if (defined($blacklist))
                           {
                           if (isblacklisted(\$blacklist, $blackregexpflag, $_->name, "Memory"))
                              {
                              next;
                              }
                           }
     
                        if (defined($whitelist))
                           {
                           if (isnotwhitelisted(\$whitelist, $whiteregexpflag, $_->name, "Memory"))
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

             if (defined($numericSensorInfo))
                {
                foreach (@$numericSensorInfo)
                        {
                        # print "Sensor Name = ". $_->name .", Type = ". $_->sensorType . ", Label = ". $_->healthState->label . ", Summary = ". $_->healthState->summary . ", Key = " . $_->healthState->key . "\n";
                        if (defined($blacklist))
                           {
                           if (isblacklisted(\$blacklist, $blackregexpflag, $_->name, $_->sensorType))
                              {
                              next;
                              }
                           }
  
                        if (defined($whitelist))
                           {
                           if (isnotwhitelisted(\$whitelist, $whiteregexpflag, $_->name, $_->sensorType))
                              {
                              next;
                              }
                        }
                        
                        $actual_state = check_health_state($_->healthState->key);
                        $itemref = {
                                   name => $_->name,
                                   summary => $_->healthState->summary
                                   };
                        push(@{$components->{$actual_state}{$_->sensorType}}, $itemref);
                        
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

             if ($listitems)
                {
                foreach $fstate (reverse(sort(keys(%$components))))
                        {
                        foreach $actual_state_ref ($components->{$fstate})
                                {
                                foreach $type (keys(%$actual_state_ref))
                                        {
                                        foreach $item_ref (@{$actual_state_ref->{$type}})
                                                {
                                                $output = $output . "($status2text{$fstate})  \[$type\]  |  $item_ref->{name}  |  $item_ref->{summary}\n";
                                                }
                                        }
                                }
                        }
                }
             else
                {
                if ($AlertCount > 0)
                   {
                   $output = "$AlertCount health issue(s) found in " . ($AlertCount + $OKCount) . " checks:\n";
                   $AlertIndex = 0;
                   
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
                                                   #print "$output\n";
                                                   $output = $output . ++$AlertIndex . ") $status2text{$fstate}\[$type\] Status of $item_ref->{name}: $item_ref->{summary}\n";
                                                   }
                                           }
                                   }
                           }
                   }
                else
                   {
                   $output = "All $OKCount health checks are GREEN:";
                   foreach $type (keys(%{$components->{0}}))
                           {
                           $output = $output . " " . $type . " (" . (scalar(@{$components->{0}{$type}})) . "x);";
                           }
                   }
                }
                $state = check_against_threshold($AlertCount);
             }
          else
             {
             $output = "System health status unavailable";
             }
          return ($state, $output);
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
                    if (defined($blacklist))
                       {
                       if (isblacklisted(\$blacklist, $blackregexpflag, $_->name))
                          {
                          next;
                          }
                       }
                    if (defined($whitelist))
                       {
                       if (isnotwhitelisted(\$whitelist, $whiteregexpflag, $_->name))
                          {
                          next;
                          }
                    }
                    
                    $actual_state = check_health_state($_->status->key);

                    # Modification by M.Obstmayer adapted by M.Fuerstenau - original part is commented out
                    #--------------------------------------------------------------------------------------
                    $sensorname = $_->name;
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
                                                    $output = $output . "$status2text{$fstate}: Status of $name: $actual_state_ref->{$type}{$name}\n";
                                                    }
                                            }
                                    }
                            }

                    if ($AlertCount > 0)
                       {
                       $output = "$AlertCount health issue(s) found: \n" . $output;
                       }
                    else
                       {
                       $output = "All $OKCount Storage health checks are GREEN: \n" . $output;
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

       if ($subselect eq "temperature")
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
                        # print "Sensor Name = ". $_->name .", Type = ". $_->sensorType . ", Label = ". $_->healthState->label . ", Summary = ". $_->healthState->summary . ", Key = " . $_->healthState->key . "\n";
                        if (uc($_->sensorType) ne 'TEMPERATURE')
                           {
                           next;
                           }
                        
                        if (defined($blacklist))
                           {
                           if (isblacklisted(\$blacklist, $blackregexpflag, $_->name))
                              {
                              next;
                              }
                           }
                        if (defined($whitelist))
                           {
                           if (isnotwhitelisted(\$whitelist, $whiteregexpflag, $_->name))
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
                           $perfdata = $perfdata . " " . $itemref->{name} . "=" . ($itemref->{value} * 10 ** $itemref->{power10}) . $base_units{$itemref->{unit}} . ";;;;";
                           }
                           else
                           {
                           $perfdata = $perfdata . " " . $itemref->{name} . "=" . ($itemref->{value} * 10 ** $itemref->{power10}) . ";;;;";
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
                                $output = $output . ", ";
                                }
                             $output = $output . "$status2text{$curstate} : $name = $value $unit";
                             }
                     }

                  if ($AlertCount > 0)
                     {
                     $output = "$AlertCount temperature issue(s) found:" . $output;
                     }
                  else
                     {
                     $output = "All $OKCount temperature checks are GREEN: " . $output;
                     $state = 0;
                     }                               
             }
          else
             {
             $output = "Temperature status unavailable";
             }
          return ($state, $output);
          }

       if ($subselect eq "sensor")
          {
#          if (!$sensorname)
#             {
#             print "Provide sensor name with --sensorname\n";
#             exit 2;
#             }

          $output = '';
          if (defined($runtime->healthSystemRuntime))
             {
             $numericSensorInfo = $runtime->healthSystemRuntime->systemHealthInfo->numericSensorInfo;

             if (defined($numericSensorInfo))
                {
                if (defined($listall))
                   {
                   foreach (@$numericSensorInfo)
                           {
                           $output = $output . "'" . $_->name . "', ";
                           }
                   if ($output)
                      {
                      chop($output);
                      chop($output);
                      $output = "numeric sensor list :" . $output;
                      }
                   else
                      {
                      $output = "numeric sensors unavailable";
                      }
                   }
                else
                   {
                   foreach (@$numericSensorInfo)
                           {
                           if ($_->name =~ $sensorname)
                              {
                              $value = $_->currentReading * 10 ** $_->unitModifier;
                              $output = "sensor '" . $_->name . "' = " . $value . (defined($_->baseUnits) ? " " . $_->baseUnits : "");
                              $state = check_against_threshold($value);
                              $perfdata = $perfdata . " " . $_->name . "=" . $value . ";" . $perf_thresholds . ";;";
                              last;
                              }
                            }
                            if (!$output)
                               {
                               $output = "Can not find sensor by name '" . $sensorname . "'";
                               }
                   }
                }
             else
                {
                $state = 3;
                $output = "System numeric sensors status unavailable";
                }
             }
          else
             {
             $state = 3;
             $output = "System health status unavailable";
             }
       return ($state, $output);
       }

       if ($subselect eq "maintenance")
          {
          %host_maintenance_state = (0 => "no", 1 => "yes");
          $output = "maintenance=" . $host_maintenance_state{$runtime->inMaintenanceMode};
          $state = 0;
          return ($state, $output);
          }

       if ($subselect eq "listvms")
          {
          %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
          $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $host_view, properties => ['name', 'runtime']);

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

          $up = 0;
          $output = '';

          foreach $vm (@$vm_views)
                  {
                  if (defined($blacklist))
                     {
                     if (isblacklisted(\$blacklist, $blackregexpflag, $vm->name))
                        {
                        next;
                        }
                     }
                  if (defined($whitelist))
                     {
                     if (isnotwhitelisted(\$whitelist, $whiteregexpflag, $vm->name))
                        {
                        next;
                        }
                      }

                  $vm_state = $vm_state_strings{$vm->runtime->powerState->val};
                  
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
          $output = $up . "/" . @$vm_views . " VMs up: " . $output;
          $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";
                        
          if ( $perf_thresholds eq 1 )
             {
             $state = check_against_threshold($up);
             }
          return ($state, $output);
          }

       if ($subselect eq "status")
          {
          $status = $host_view->overallStatus->val;
          $output = "overall status=" . $status;
          $state = check_health_state($status);
          return ($state, $output);
          }

       if ($subselect eq "issues")
          {
          $issues = $host_view->configIssue;

          $output = '';
          if (defined($issues))
             {
             foreach (@$issues)
                     {
                     if (defined($blacklist))
                        {
                        if (isblacklisted(\$blacklist, $blackregexpflag, $_->fullFormattedMessage))
                           {
                           next;
                           }
                        }
                     if (defined($whitelist))
                        {
                        if (isnotwhitelisted(\$whitelist, $whiteregexpflag, $_->fullFormattedMessage))
                           {
                           next;
                           }
                        }
                        $output = $output . format_issue($_) . "; ";
                     }
             }
             if ($output eq '')
                {
                $state = 0;
                $output = 'No config issues';
                }
             return ($state, $output);
             }
       get_me_out("Unknown HOST RUNTIME subselect");
       }
    else
       {
       %host_maintenance_state = (0 => "no", 1 => "yes");
       $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $host_view, properties => ['name', 'runtime']);
       $up = 0;

       if (!defined($vm_views))
          {
          print "Runtime error\n";
          exit 2;
          }

       if (@$vm_views)
          {
          foreach $vm (@$vm_views)
                  {
                  $up += $vm->runtime->powerState->val eq "poweredOn";
                  }
          $output = $up . "/" . @$vm_views . " VMs up";
          }
       else
          {
          $output = "No VMs installed";
          }

       $AlertCount = 0;
       $SensorCount = 0;
       if (defined($runtime->healthSystemRuntime))
          {
          $cpuStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->cpuStatusInfo;
          $storageStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->storageStatusInfo;
          $memoryStatusInfo = $runtime->healthSystemRuntime->hardwareStatusInfo->memoryStatusInfo;
          $numericSensorInfo = $runtime->healthSystemRuntime->systemHealthInfo->numericSensorInfo;
          }

       if (defined($cpuStatusInfo))
          {
          foreach (@$cpuStatusInfo)
                  {
                  $SensorCount++;
                  if (check_health_state($_->status->key) != 0)
                     {
                     $AlertCount++;
                     }
                  }
          }

       if (defined($storageStatusInfo))
          {
          foreach (@$storageStatusInfo)
                  {
                  $SensorCount++;
                  if (check_health_state($_->status->key) != 0)
                     {
                     $AlertCount++;
                     }
                  }
          }

       if (defined($memoryStatusInfo))
          {
          foreach (@$memoryStatusInfo)
                  {
                  $SensorCount++;
                  if (check_health_state($_->status->key) != 0)
                     {
                     $AlertCount++;
                     }
                  }
          }

       if (defined($numericSensorInfo))
          {
          foreach (@$numericSensorInfo)
                  {
                  $SensorCount++;
                  if (check_health_state($_->healthState->key) != 0)
                     {
                     $AlertCount++;
                     }
                  }
          }

       $state = 0;
       $output = $output . ", overall status=" . $host_view->overallStatus->val . ", connection state=" . $runtime->connectionState->val . ", maintenance=" . $host_maintenance_state{$runtime->inMaintenanceMode} . ", ";

       if ($AlertCount)
          {
          $output = $output . "$AlertCount health issue(s), ";
          }
       else
          {
          $output = $output . "All $SensorCount health checks are Green, ";
          }
       $perfdata = $perfdata . " health_issues=" . $AlertCount;

       $issues = $host_view->configIssue;
       if (defined($issues))
          {
          $output = $output . @$issues . " config issue(s)";
          $perfdata = $perfdata . " config_issues=" . "" . @$issues;
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
