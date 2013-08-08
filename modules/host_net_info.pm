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
    my $OKCount = 0;
    my $BadCount = 0;
    my @switches = ();
    my $switch;
    my $nic_key;
    my %NIC = ();
        
    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       if ( $perf_thresholds ne ";")
          {
          print "Error! Thresholds are only allowed with subselects!\n";
          }
       }

    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       $values = return_host_temporary_vc_4_1_network_performance_values($host, ('received.average:*', 'transmitted.average:*'));
       if ($values)
          {
          $$values[0][0]{"value"} += $$values[0][1]{"value"};
          }
       else
          {
          $values = return_host_performance_values($host, 'net', ('usage.average'));
          }
          if (defined($values))
            {
            $value = simplify_number(convert_number($$values[0][0]->value));
            $perfdata = $perfdata . " net_usage=" . $value . $perf_thresholds . ";;";
            $output = "net usage=" . $value . " KBps";
            if ($subselect ne "all")
               {
               $state = check_against_threshold($value);
               }
            }
        if ($subselect ne "all")
           {
           return ($state, $output);
           }
       }
   
    if (($subselect eq "receive") || ($subselect eq "all"))
       {
       $values = return_host_temporary_vc_4_1_network_performance_values($host, ('received.average:*'));
       $values = return_host_performance_values($host, 'net', ('received.average')) if (!$values);
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " net_receive=" . $value . $perf_thresholds . ";;";
          if ($subselect ne "all")
             {
             $output = "net receive=" . $value . " KBps";
             $state = check_against_threshold($value);
             }
             else
             {
             $output = $output . ", net receive=" . $value . " KBps";
             }
          }
       if ($subselect ne "all")
          {
          return ($state, $output);
          }
       }
  
    if (($subselect eq "send") || ($subselect eq "all"))
       {
       $values = return_host_temporary_vc_4_1_network_performance_values($host, ('transmitted.average:*'));
       if (!$values)
          {
          $values = return_host_performance_values($host, 'net', ('transmitted.average'));
          }
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " net_send=" . $value . $perf_thresholds . ";;";
          if ($subselect ne "all")
             {
             $output = "net send=" . $value . " KBps";
             $state = check_against_threshold($value);
             }
             else
             {
             $output = $output . ", net send=" . $value . " KBps";
             }
          }
       if ($subselect ne "all")
          {
          return ($state, $output);
          }
       }

    if (($subselect eq "nic") || ($subselect eq "all"))
       {
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
                                  if (!defined($NIC{$nic_key}->linkSpeed))
                                     {
                                     if ($output_nic)
                                        {
                                        $output_nic = $output_nic . ", ";
                                        }
                                     $output_nic = $output_nic . $NIC{$nic_key}->device . " is unplugged";
                                     $state = 2;
                                     $BadCount++;
                                     }
                                  else
                                     {
                                     $OKCount++;
                                     }
                                  }
                          }
                       }
               }

       if (!$BadCount)
          {
          if ($subselect ne "all")
             {
             $output = "All $OKCount NICs are connected";
             }
          else
             {
             $output = $output . ", All $OKCount NICs are connected";
             }
          }
       else
          {
          if ($subselect ne "all")
             {
             $output = $BadCount ."/" . ($BadCount + $OKCount) . " NICs are disconnected: " . $output_nic;
             }
          else
             {
             $output = $output . ", " . $BadCount ."/" . ($BadCount + $OKCount) . " NICs are disconnected: " . $output_nic;
             }
          }
       return ($state, $output);
       }

    if ($subselect ne "all")
       {
       get_me_out("Unknown HOST NET subselect");
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
