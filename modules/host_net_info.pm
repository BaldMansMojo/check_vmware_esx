# Notice for further development of this module:
# - more information about the nics

sub host_net_info
    {
    my ($host) = @_;
    my $state = 0;
    my $value;
    my $output;
    my $output_nic = "";
    my $host_view;
    my $network_system;
    my $network_config;
    my $ignored = 0;             # Counter for blacklisted items
    my $OKCount = 0;
    my $BadCount = 0;
    my $TotalCount = 0;
    my @switches = ();
    my $switch;
    my $nic_key;
    my %NIC = ();
    my $actual_state;            # Hold the actual state for to be compared
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
          print "Error! Thresholds are only allowed with subselects!\n";
          exit 3;
          }
       }

    $values = return_host_performance_values($host, 'net', ('usage.average', 'received.average', 'transmitted.average'));


    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;

       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          if ($subselect eq "all")
             {
             $output = "net usage=" . $value . " KBps";
             $perfdata = "\'net_usage\'=" . $value . ";". $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "net usage=" . $value . " KBps";
             $perfdata = "\'net_usage\'=" . $value . ";" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          $actual_state = 3;
          $output = "net usage=Not available";
          $state = check_state($state, $actual_state);
          }
       }
   
    if (($subselect eq "receive") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][1]->value));
          if ($subselect eq "all")
             {
             $output = $output . " net receive=" . $value . " KBps";
             $perfdata = $perfdata . " \'net_receive\'=" . $value . ";" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "net receive=" . $value . " KBps";
             $perfdata = "\'net_receive\'=" . $value . ";" . $perf_thresholds . ";;";
             $state = check_state($state, $actual_state);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output = $output . " net receive=Not available"; 
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "net receive=Not available"; 
             $state = check_state($state, $actual_state);
             }
          }
       }
  
    if (($subselect eq "send") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][2]->value));
          if ($subselect eq "all")
             {
             $output =$output . ", net send=" . $value . " KBps"; 
             $perfdata = $perfdata . " \'net_send\'=" . $value . ";" . $perf_thresholds . ";;";
             }
          else
             {
             $actual_state = check_against_threshold($value);
             $output = "net send=" . $value . " KBps"; 
             $perfdata = "\'net_send\'=" . $value . ";" . $perf_thresholds . ";;";
             $state = check_against_threshold($value);
             }
          }
       else
          {
          if ($subselect eq "all")
             {
             $actual_state = 3;
             $output =$output . ", net send=Not available"; 
             $state = check_state($state, $actual_state);
             }
          else
             {
             $actual_state = 3;
             $output = "net send=Not available"; 
             $state = check_state($state, $actual_state);
             }
          }
       }

    if (($subselect eq "nic") || ($subselect eq "all"))
       {
       $true_sub_sel = 0;
       $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'configManager.networkSystem', 'runtime.inMaintenanceMode']);

       if (!defined($host_view))
          {
          print "Host " . $$host{"name"} . " does not exist\n";
          exit 2;
          }
       
       if (uc($host_view->get_property('runtime.inMaintenanceMode')) eq "TRUE")
          {
          print "Notice: " . $host_view->name . " is in maintenance mode, check skipped\n";
          exit 0;
          }
 
       $network_system = Vim::get_view(mo_ref => $host_view->get_property('configManager.networkSystem') , properties => ['networkInfo']);
       $network_system->update_view_data(['networkInfo']);
       $network_config = $network_system->networkInfo;

       if (!defined($network_config))
          {
          print "Host " . $$host{"name"} . " has no network info in the API.\n";
          exit 2;
          }

       # create a hash of NIC info to facilitate easy lookups
       foreach (@{$network_config->pnic})
               {
               $NIC{$_->key} = $_;
               $TotalCount++;
               }

       if (exists($network_config->{vswitch}))
          {
          push(@switches, $network_config->vswitch);
          }
       if (exists($network_config->{proxySwitch}))
          {
          push(@switches, $network_config->proxySwitch);
          }

       # see which NICs are actively part of a switch
       foreach $switch (@switches)
               {
               foreach (@{$switch})
                       {
                       # get list of physical nics
                       if (defined($_->pnic))
                          {
                          foreach $nic_key (@{$_->pnic})
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
                                     if (isblacklisted(\$blacklist, $isregexp, $NIC{$nic_key}->device))
                                        {
                                        $ignored++;
                                        next;
                                        }
                                     }
                   
                                  if (!defined($NIC{$nic_key}->linkSpeed))
                                     {
                                     if ($output_nic)
                                        {
                                        $output_nic = $output_nic . ", ";
                                        }
                                     $output_nic = $output_nic . $multiline . $NIC{$nic_key}->device . " is unplugged";
                                     $state = 1;
                                     $BadCount++;
                                     }
                                  else
                                     {
                                     $output_nic = $output_nic . $multiline . $NIC{$nic_key}->device . " is ok";
                                     $OKCount++;
                                     }
                                  }
                          }
                       }
               }

        if ($subselect ne "all")
           {
           $output = "NICs total:" . $TotalCount . " NICs attached to switch:" . ($OKCount + $BadCount) . " NICs connected:" . $OKCount . " NICs disconnected:" . $BadCount . " NICs ignored:" . $ignored . $output_nic;
           }
        else
           {
           $output = $output . " NICs total:" . $TotalCount . " NICs attached to switch:" . ($OKCount + $BadCount) . " NICs connected:" . $OKCount . " NICs disconnected:" . $BadCount . " NICs ignored:" . $ignored;
           }
       }

    if ($true_sub_sel == 1)
       {
       get_me_out("Unknown HOST NET subselect");
       }
    else
       {
       return ($state, $output);
       }
   }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
