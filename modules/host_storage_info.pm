sub host_storage_info
    {
    my ($host, $blacklist) = @_;
    my $count = 0;                        # Counter for items (adapter,luns etc.)
    my $warn_count = 0;                   # Warning counter for items (adapter,luns etc.)
    my $err_count = 0;                    # Error counter for items (adapter,luns etc.)
    my $ignored = 0;                      # Counter for blacklisted items

    my $state = 0;                        # Return state
    my $actual_state = 0;                 # Return state from the current check. Will be compared with $state
                                          # If higher than $state $state will be set to $actual_state
    my $storage;                          # A pointer to the datastructure deliverd by API call
    my $dev;                              # A pointer to the hostbusadapter data structure
    my $canonicalName;                    # Canonical name of LUN
    my $displayName;                      # The displayName is not a fixed identifier. It is freely configurable
                                          # and should (but this is not a must) be unique. Often the canonicalName
                                          # is part of it. So here we extract the canonicalName and take the
                                          # rest as information.

    my $model;
    my $status;
    my $disc_key;                         # The key of the disc. A string like
                                          # key-vim.host.ScsiDisk-020000000060030057003663801344ae770e1cdda34d6567615241
    my %lun2disc_key;                     # Hold the assignment between the key of the disc and the LUN
    my $no_online = 0;
    my $no_offline = 0;
    my $no_unbound = 0;
    my $no_unknown = 0;
    my $scsi;
    my $scsi_id;                          # Contains the SCSI ID
    my $scsi_id_old = "init";             # Contains the SCSI ID from the previous loop. the string
                                          # "init" is needed for the first loop giving a result.
                                          # A counter won't work here due to the fact than SISI ID can
                                          # be black-/whitelisted
    my $operationState;
    my $adapter;
    my $adapter_long;
    my $mpInfolun;
    my $scsiTopology_adapter;
    my $scsiTopology_adapter_target;
    my $scsiTopology_adapter_target_lun;

    my $path;                             # A pointer to the data structure of the path
    my $pathname;                         # The pathname of a LUN
    my $pathState;                        # The state of the path pathname
    my $multipathState;
    my $WWNN;
    my $WWPN;
    my $path_cnt = 0;                     # Counter for paths
    my $path_warn_cnt = 0;                # Warning counter for paths
    my $path_err_cnt = 0;                 # Error counter for paths
    my $mpath_cnt = 0;                    # Counter for multipaths
    my $mpath_warn_cnt = 0;               # Warning counter for multipaths
    my $mpath_err_cnt = 0;                # Error counter for multipaths
    my $mpath_output = " ";
    my $mpath_tmp_output = " ";
    my $mpath_ok_output = " ";
    my $mpath_error_output = " ";
    my $this_mpath_error = 0;             # Flag.
                                          # 0: ok
                                          # 1: one or more the paths has an error 

    my $output = " ";
    my $lun_ok_output = " ";
    my $lun_warn_output = " ";
    my $lun_error_output = " ";


    my $true_sub_sel=1;                   # Just a flag. To have only one return at the end
                                          # we must ensure that we had a valid subselect. If
                                          # no subselect is given we select all
                                          # 0 -> existing subselect
                                          # 1 -> non existing subselect

    my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'configManager', 'runtime.inMaintenanceMode']);


    if (!defined($host_view))
       {
       print "Host " . $$host{"name"} . " does not exist\n";
       exit 2;
       }

    if (($host_view->get_property('runtime.inMaintenanceMode')) eq "true")
       {
       print "Notice: " . $host_view->name . " is in maintenance mode, check skipped\n";
       exit 1;
       }
   
    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       $true_sub_sel = 0;
       }

    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       $true_sub_sel = 0;
       }

    $storage = Vim::get_view(mo_ref => $host_view->configManager->storageSystem, properties => ['storageDeviceInfo']);

    if (($subselect eq "adapter") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;

       foreach $dev (@{$storage->storageDeviceInfo->hostBusAdapter})
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
                  if (isblacklisted(\$blacklist, $isregexp, $dev->device))
                     {
                     $count++;
                     $ignored++;
                     next;
                     }
                  if (isblacklisted(\$blacklist, $isregexp, $dev->model))
                     {
                     $count++;
                     $ignored++;
                     next;
                     }
                  if (isblacklisted(\$blacklist, $isregexp, $dev->key))
                     {
                     $count++;
                     $ignored++;
                     next;
                     }
                  }

                  if (defined($whitelist))
                  {
                  if (isnotwhitelisted(\$whitelist, $isregexp, $dev->device) and
                      isnotwhitelisted(\$whitelist, $isregexp, $dev->model) and
                      isnotwhitelisted(\$whitelist, $isregexp, $dev->key) )
                     {
                     $count++;
                     next;
                     }
                  }                    
 
               if ($dev->status eq "online")
                  {
                  $count++;
                  $actual_state = 0;
                  $no_online++;
                  $state = check_state($state, $actual_state);
                  }
               if ($dev->status eq "offline")
                  {
                  $count++;
                  $actual_state = 2;
                  $no_offline++;
                  $state = check_state($state, $actual_state);
                  }
               if ($dev->status eq "unbound")
                  {
                  $count++;
                  $actual_state = 1;
                  $no_unbound++;
                  $state = check_state($state, $actual_state);
                  }
               if ($dev->status eq "unknown")
                  {
                  $count++;
                  $actual_state = 3;
                  $no_unknown++;
                  $state = check_state($state, $actual_state);
                  }
               $output = $output . $dev->model . " " . $dev->device . "(" . $dev->status . ")" . $multiline;
               }

       # Remove the leading blank
       $output =~ s/^ //;
       
       if ($subselect eq "all")
          {
          $output = "Adapters:" . $count++ . " Ignored:" . $ignored++ . " Online:" . $no_online . " Offline:" . $no_offline . " Unbound:" . $no_unbound . " Unknown:" . $no_unknown . $multiline;
          }
       else
          {
          $output = "Adapters:" . $count++ . " Ignored:" . $ignored++ . " Online:" . $no_online . " Offline:" . $no_offline . " Unbound:" . $no_unbound . " Unknown:" . $no_unknown . $multiline . $output;
          }
       }


    # Build a hash containing the LUN identifier and the SCSI ID
    if (($subselect eq "lun") || ($subselect eq "path") || ($subselect eq "all"))
       {
       foreach $scsiTopology_adapter (@{$storage->storageDeviceInfo->scsiTopology->adapter})
               {
               if (exists($scsiTopology_adapter->{target}))
                  {
                  foreach $scsiTopology_adapter_target (@{$scsiTopology_adapter->target})
                          {
                          if (exists($scsiTopology_adapter_target->{lun}))
                             {
                             foreach $scsiTopology_adapter_target_lun (@{$scsiTopology_adapter_target->lun})
                                     {
                                     # $scsiTopology_adapter_target_lun->scsiLun is not the LUN. The misleading name
                                     # is a string like
                                     # key-vim.host.ScsiDisk-020000000060030057003663801344ae770e1cdda34d6567615241
                                     # It is the same as storageDeviceInfo->scsiLun->key (see below)
                                     $disc_key = $scsiTopology_adapter_target_lun->scsiLun;
                                     $disc_key =~ s/^.*-//;
                                     $lun2disc_key{$disc_key} = sprintf("%03d", $scsiTopology_adapter_target_lun->lun);
                                     }
                             }
                          }
                  }
               }
       }


    if (($subselect eq "lun") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $ignored = 0;

       foreach $scsi (@{$storage->storageDeviceInfo->scsiLun})
               {
               $canonicalName = $scsi->canonicalName;
               $scsi_id = $scsi->uuid;
               $disc_key = $scsi->key;
               $disc_key =~ s/^.*-//;

               # The displayName is not a fixed identifier. It is freely configurable
               # and should (but this is not a must) be unique. Often the canonicalName is
               # part of it. So here we extract the canonicalName and take the rest as information.
               if (exists($scsi->{displayName}))
                  {
                  $displayName = $scsi->displayName;
                  $displayName =~ s/$canonicalName//;
                  $displayName =~ s/[^\w\s]//g;
                  $displayName =~ s/\s+$//g;
                  $canonicalName = $canonicalName . " (" . $displayName . ")";
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
                  if (isblacklisted(\$blacklist, $isregexp, $canonicalName))
                     {
                     $count++;
                     $ignored++;
                     next;
                     }
                  }
               if (defined($whitelist))
                  {
                  if (isnotwhitelisted(\$whitelist, $isregexp, $canonicalName))
                     {
                     $count++;
                     next;
                     }
                  }

               $operationState = join("-", @{$scsi->operationalState});

               foreach (@{$scsi->operationalState})
                       {
                       #       degraded             One or more paths to the LUN are down, but I/O is still possible. Further
                       #                            path failures may result in lost connectivity.
                       #       error                The LUN is dead and/or not reachable.
                       #       lostCommunication    No more paths are available to the LUN.
                       #       off                  The LUN is off.
                       #       ok                   The LUN is on and available.
                       #       quiesced             The LUN is inactive.
                       #       timeout              All Paths have been down for the timeout condition determined by a
                       #                            user-configurable host advanced option.
                       #       unknownState         The LUN state is unknown.
                       if (($_) eq "ok")
                          {
                          $count++;
                          $actual_state = 0;
                          $lun_ok_output = $lun_ok_output . "LUN:" . $lun2disc_key{$disc_key} . " - State: " . $operationState . " - Name: " . $canonicalName . $multiline;
                          }
                       if ((($_) eq "degraded") || (($_) eq "unknownState"))
                          {
                          $count++;
                          $actual_state = 1;
                          $warn_count++;
                          $lun_warn_output = $lun_warn_output . "LUN:" . $lun2disc_key{$disc_key} . " - State: " . $operationState . " - Name: " . $canonicalName . $multiline;
                          }
                       if ((($_) eq "error") || (($_) eq "off") || (($_) eq "quiesced") || (($_) eq "timeout"))
                          {
                          $count++;
                          $actual_state = 2;
                          $err_count++;
                          $lun_error_output = $lun_error_output . "LUN:" . $lun2disc_key{$disc_key} . " - State: " . $operationState . " - Name: " . $canonicalName . $multiline;
                          }
                       $state = check_state($state, $actual_state);
                       }
                 }

       # Remove the leading blank
       $lun_ok_output =~ s/^ //;
       $lun_warn_output =~ s/^ //;
       $lun_error_output =~ s/^ //;

       if ($subselect eq "all")
          {
          $output = $output . " LUNs:" . $count . " - LUNs(ignored):" . $ignored . " - LUNs(warn):" . $warn_count . " - LUNSs(crit):" . $err_count;
          }
       else
          {
          $output = "LUNs:" . $count . " - LUNs(ignored):" . $ignored . " - LUNs(warn):" . $warn_count . " - LUNSs(crit):" . $err_count;
          if (defined($alertonly))
             {
             $output = $output . $multiline . $lun_error_output . $lun_warn_output;
             }
             else
             {
             $output = $output . $multiline . $lun_error_output . $lun_warn_output . $lun_ok_output;
             }
          }
       
       # Remove the last \n or <br>
       $output =~ s/$multiline$//;
       }


    if (($subselect eq "path") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $ignored = 0;

       if (exists($storage->storageDeviceInfo->{multipathInfo}))
          {
          foreach $mpInfolun (@{$storage->storageDeviceInfo->multipathInfo->lun})
                  {
                  foreach $path (@{$mpInfolun->path})
                          {
                          $scsi_id = $path->lun;
                          $scsi_id =~ s/^.*-//;
                          
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
                             if (isblacklisted(\$blacklist, $isregexp, $scsi_id))
                                {
                                if ($scsi_id ne $scsi_id_old)
                                   {
                                   $mpath_cnt++;
                                   $ignored++;
                                   next;
                                   }
                                }
                             }
                          if (defined($whitelist))
                             {
                             if (isnotwhitelisted(\$whitelist, $isregexp, $scsi_id))
                                {
                                if ($scsi_id ne $scsi_id_old)
                                   {
                                   $mpath_cnt++;
                                   next;
                                   }
                                }
                             }
           
                          if ($scsi_id ne $scsi_id_old)
                             {
                             # If we are here we have a new multipath
                             if ($scsi_id_old ne "init")
                                {
                                # Processing the results of the previous loop
                                if ($this_mpath_error != 0)
                                   {
                                   $mpath_error_output = $mpath_error_output . $mpath_tmp_output . $multiline;
                                   $mpath_error_output =~ s/^ //;
                                   }
                                else
                                   {
                                   $mpath_ok_output = $mpath_ok_output . $mpath_tmp_output . $multiline;
                                   $mpath_ok_output =~ s/^ //;
                                   }
                                }
                             $this_mpath_error = 0;
                             $scsi_id_old = $scsi_id;
                             $mpath_cnt++;
                             $mpath_tmp_output = "LUN:" . $lun2disc_key{$scsi_id} . $multiline;
                             $mpath_tmp_output = $mpath_tmp_output . "SCSI-ID:" . $scsi_id . $multiline;

                             if (exists($path->{state}))
                                {
                                $multipathState = $path->state;
                                if (($multipathState eq "active") || ($multipathState eq "disabled"))
                                   {
                                   $mpath_tmp_output = $mpath_tmp_output . "Mpath State: " . $multipathState . $multiline; 
                                   $actual_state = 0;
                                   $state = check_state($state, $actual_state);
                                   }
                                if ($multipathState eq "dead")
                                   {
                                   $mpath_tmp_output = $mpath_tmp_output . "Mpath State: " . $multipathState . $multiline; 
                                   $actual_state = 2;
                                   $state = check_state($state, $actual_state);
                                   $this_mpath_error = 1;
                                   $mpath_err_cnt++;
                                   }
                                if ($multipathState eq "standby")
                                   {
                                   $mpath_tmp_output = $mpath_tmp_output . "Mpath State: " . $multipathState . $multiline; 
                                   if (defined($standbyok))
                                      {
                                      $actual_state = 0;
                                      $state = check_state($state, $actual_state);
                                      }
                                   else
                                      {
                                      $actual_state = 1;
                                      $state = check_state($state, $actual_state);
                                      $this_mpath_error = 1;
                                      $mpath_warn_cnt++;
                                      }
                                   }
                                if ($multipathState eq "unknown")
                                   {
                                   $mpath_tmp_output = $mpath_tmp_output . "Mpath State: " . $multipathState . $multiline; 
                                   $actual_state = 3;
                                   $state = check_state($state, $actual_state);
                                   $this_mpath_error = 1;
                                   $mpath_unknown_cnt++;
                                   }
                                }
                              }

                          $adapter_long = $path->adapter;
                          $adapter = $adapter_long;
                          $adapter =~ s/^.*-vm/vm/;

                          $mpath_tmp_output = $mpath_tmp_output . "Adapter: " . $adapter;

                          if ($adapter_long =~ m/FibreChannel/i )
                             {
                             $WWNN = $path->transport->nodeWorldWideName;
                             $WWPN = $path->transport->portWorldWideName;
                             $mpath_tmp_output = $mpath_tmp_output . " WWNN: " . $WWNN;
                             $mpath_tmp_output = $mpath_tmp_output . " WWPN: " . $WWPN . $multiline;
                             }
                             else
                             {
                             $mpath_tmp_output = $mpath_tmp_output . $multiline;
                             }

                          $pathname = $path->name;
                          $mpath_tmp_output = $mpath_tmp_output . "Path: " . $pathname;

                          if (exists($path->{pathState}))
                             {
                             $pathState = $path->pathState;
                             $path_cnt++;

                             if (($pathState eq "active") || ($pathState eq "standby") || ($pathState eq "disabled"))
                                {
                                $mpath_tmp_output = $mpath_tmp_output . $multiline . "State: " . $pathState . $multiline; 
                                $actual_state = 0;
                                $state = check_state($state, $actual_state);
                                }
                             if ($pathState eq "dead")
                                {
                                $mpath_tmp_output = $mpath_tmp_output . $multiline . "State: " . $pathState . $multiline; 
                                $actual_state = 2;
                                $state = check_state($state, $actual_state);
                                $this_mpath_error = 1;
                                $path_err_cnt++;
                                }
                             if ($pathState eq "unknown")
                                {
                                $mpath_tmp_output = $mpath_tmp_output . $multiline . "State: " . $pathState . $multiline; 
                                $actual_state = 1;
                                $state = check_state($state, $actual_state);
                                $this_mpath_error = 1;
                                $path_warn_cnt++;
                                }
                             }
                          }
                  }

               if ($this_mpath_error != 0)
                  {
                  $mpath_error_output = $mpath_error_output . $mpath_tmp_output;
                  $mpath_error_output =~ s/^ //;
                  }
               else
                  {
                  $mpath_ok_output = $mpath_ok_output . $mpath_tmp_output;
                  $mpath_ok_output =~ s/^ //;
                  }

            if ($subselect eq "all")
               {
               $output = $output . " Multipaths:" . $mpath_cnt . " - Multipaths(ignored):" . $ignored . " - Multipaths(warn):" . $mpath_warn_cnt . " - Multipaths(error):" . $mpath_err_cnt . " - Paths:" . $path_cnt . " - Paths(warn):" . $path_warn_cnt . " - Paths(error):" . $path_err_cnt;
               }
            else
               {
               $output = "Multipaths:" . $mpath_cnt . " - Multipaths(ignored):" . $ignored . " - Multipaths(warn):" . $mpath_warn_cnt . " - Multipaths(error):" . $mpath_err_cnt . " - Paths:" . $path_cnt . " - Paths(warn):" . $path_warn_cnt . " - Paths(error):" . $path_err_cnt;
               if (defined($alertonly))
                  {
                  $output = $output . $multiline . $mpath_error_output;
                  }
                  else
                  {
                  $output = $output . $multiline . $mpath_error_output . $mpath_ok_output;
                  }
               }
            }
         else
            {
            $output = "Path info is unavailable on this host";
            $state = 3;
            }
         }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown host storage subselect");
       }
    else
       {
#       $output = "miist";
       return ($state, $output);
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
