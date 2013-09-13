sub main_select
    {
    if (defined($vmname))
       {
       if ($select eq "cpu")
          {
          ($result, $output) = vm_cpu_info($vmname);
          return($result, $output);
          }
       if ($select eq "mem")
          {
          ($result, $output) = vm_mem_info($vmname);
          return($result, $output);
          }
       if ($select eq "net")
          {
          ($result, $output) = vm_net_info($vmname);
          return($result, $output);
          }
       if ($select eq "io")
          {
          ($result, $output) = vm_disk_io_info($vmname);
          return($result, $output);
          }
       if ($select eq "runtime")
          {
          ($result, $output) = vm_runtime_info($vmname);
          return($result, $output);
          }
       if ($select eq "soap")
          {
          ($result, $output) = soap_check();
          return($result, $output);
          }

          get_me_out("Unknown HOST-VM command");
        }

    if (defined($host))
       {
       # The following if black is only needed if we check a ESX server via the 
       # the datacenten (vsphere server) instead of doing it directly.
       # Directly is better
       
       my $esx_server;
       if (defined($datacenter))
          {
          $esx_server = {name => $host};
          }
       if ($select eq "cpu")
          {
          require host_cpu_info;
          import host_cpu_info;
          ($result, $output) = host_cpu_info($esx_server);
          return($result, $output);
          }
       if ($select eq "mem")
          {
          require host_mem_info;
          import host_mem_info;
          ($result, $output) = host_mem_info($esx_server);
          return($result, $output);
          }
       if ($select eq "net")
          {
          require host_net_info;
          import host_net_info;
          ($result, $output) = host_net_info($esx_server);
          return($result, $output);
          }
       if ($select eq "io")
          {
          require host_disk_io_info;
          import host_disk_io_info;
          ($result, $output) = host_disk_io_info($esx_server);
          return($result, $output);
          }
       if ($select eq "volumes")
          {
          require host_list_vm_volumes_info;
          import host_list_vm_volumes_info;
          ($result, $output) = host_list_vm_volumes_info($esx_server);
          return($result, $output);
          }
       if ($select eq "runtime")
          {
          require host_runtime_info;
          import host_runtime_info;
          ($result, $output) = host_runtime_info($esx_server);
          return($result, $output);
          }
       if ($select eq "service")
          {
          require host_service_info;
          import host_service_info;
          ($result, $output) = host_service_info($esx_server);
          return($result, $output);
          }
       if ($select eq "storage")
          {
          require host_storage_info;
          import host_storage_info;
          ($result, $output) = host_storage_info($esx_server, $blacklist);
          return($result, $output);
          }
       if ($select eq "uptime")
          {
          require host_uptime_info;
          import host_uptime_info;
          ($result, $output) = host_uptime_info($esx_server);
          return($result, $output);
          }
       if ($select eq "hostmedia")
          {
          require host_mounted_media_info;
          import host_mounted_media_info;
          ($result, $output) = host_mounted_media_info($esx_server);
          return($result, $output);
          }
       if ($select eq "soap")
          {
          ($result, $output) = soap_check();
          return($result, $output);
          }

          get_me_out("Unknown HOST command");
        }

    if (defined($cluster))
       {
       if ($select eq "cpu")
          {
          ($result, $output) = cluster_cpu_info($cluster);
          return($result, $output);
          }
       if ($select eq "mem")
          {
          ($result, $output) = cluster_mem_info($cluster);
          return($result, $output);
          }
       if ($select eq "cluster")
          {
          ($result, $output) = cluster_cluster_info($cluster);
          return($result, $output);
          }
       if ($select eq "volumes")
          {
          ($result, $output) = cluster_list_vm_volumes_info($cluster);
          return($result, $output);
          }
       if ($select eq "runtime")
          {
          ($result, $output) = cluster_runtime_info($cluster, $blacklist);
          return($result, $output);
          }
       if ($select eq "soap")
          {
          ($result, $output) = soap_check();
          return($result, $output);
          }

          get_me_out("Unknown CLUSTER command");
        }

    if (defined($datacenter))
       {
       if ($select eq "volumes")
          {
          ($result, $output) = dc_list_vm_volumes_info($blacklist, $whitelist);
          return($result, $output);
          }
       if ($select eq "runtime")
          {
          ($result, $output) = dc_runtime_info($blacklist);
          return($result, $output);
          }
       if ($select eq "soap")
          {
          ($result, $output) = soap_check();
          return($result, $output);
          }

       get_me_out("Unknown DATACENTER command");
       }
    get_me_out("You should never end here. Totally unknown anything.");
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;