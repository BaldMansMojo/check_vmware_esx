sub host_storage_info
{

        my ($host, $blacklist) = @_;

        my $count = 0;
        my $state = 2;
        my $actual_state;
        my $output = 'HOST RUNTIME Unknown error';
        my $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name', 'configManager', 'runtime.inMaintenanceMode']);

        if (!defined($host_view))
           {
           print "Host " . $$host{"name"} . " does not exist\n";
           exit 2;
           }
        
        if (uc($host_view->get_property('runtime.inMaintenanceMode')) eq "TRUE")
           {
           print "Notice: \"" . $host_view->name . "\" is in maintenance mode, check skipped\n";
           exit 0;
           }

        my $storage = Vim::get_view(mo_ref => $host_view->configManager->storageSystem, properties => ['storageDeviceInfo']);

        if (defined($subselect))
        {
                if ($subselect eq "adapter")
                {
                        $output = "";
                        $state = 0;
                        foreach my $dev (@{$storage->storageDeviceInfo->hostBusAdapter})
                        {
                                my $name = $dev->device;
                                my $status = $dev->status;
                                if (defined($blacklist))
                                {
                                        my $key = $dev->key;
                                        if (($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/) || ($blacklist =~ m/(^|\s|\t|,)\Q$key\E($|\s|\t|,)/))
                                        {
                                                $count++;
                                                $status = "ignored";
                                        }
                                }
                                $count ++ if (uc($status) eq "ONLINE");
                                $state = 3 if (uc($status) eq "3");
                                $output = $output . $name . " (" . $status . "); ";
                        }
                        $actual_state = check_against_threshold($count);

                        if ($actual_state != 0)
                           {
                           $state = $actual_state;
                           }

                        $perfdata = $perfdata . " adapters=" . $count . ";" . $perf_thresholds . ";;";
                }
                elsif ($subselect eq "lun")
                {
                        $output = "";
                        $state = 0;
                        my $actual_state = 0; # For unkonwn or other statuses
                        foreach my $scsi (@{$storage->storageDeviceInfo->scsiLun})
                        {
                                my $name = "";
                                if (exists($scsi->{displayName}))
                                {
                                        $name = $scsi->displayName;
                                }
                                elsif (exists($scsi->{canonicalName}))
                                {
                                        $name = $scsi->canonicalName;
                                }
                                else
                                {
                                        $name = $scsi->deviceName;
                                }
                                $actual_state = 0;

                                my $operationState;
                                if (defined($blacklist) && ($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/))
                                {
                                        $operationState = "ignored";
                                }
                                else
                                {
                                        $operationState = join("-", @{$scsi->operationalState});
                                        foreach (@{$scsi->operationalState})
                                        {
                                                if (uc($_) eq "0")
                                                {
                                                        # $actual_state = 0;
                                                }
                                                elsif (uc($_) eq "3")
                                                {
                                                        $state = 3;
                                                }
                                                elsif (uc($_) eq "3STATE")
                                                {
                                                        $state = 3;
                                                }
                                                else
                                                {
                                                        $actual_state = 2;
                                                }
                                        }
                                }

                                if ($actual_state == 0)
                                   {
                                   $count++;
                                   }
                                   
                                $output = $output .$name . " <" . $operationState . ">; ";
                        }
                        $perfdata = $perfdata . " LUNs=" . $count . ";" . $perf_thresholds . ";;";
                        $actual_state = check_against_threshold($count);
                        if ($actual_state != 0)
                           {
                           $state = $actual_state;
                           }
                }
                elsif ($subselect eq "path")
                {
                        if (exists($storage->storageDeviceInfo->{multipathInfo}))
                        {
                                $output = "";
                                $state = 0;
                                foreach my $lun (@{$storage->storageDeviceInfo->multipathInfo->lun})
                                {
                                        foreach my $path (@{$lun->path})
                                        {
                                                my $status = 3; # For unknown or other statuses
                                                my $pathState = "unknown";
                                                my $name = $path->name;

                                                if (exists($path->{state}))
                                                {
                                                        $pathState = $path->state;
                                                }
                                                else
                                                {
                                                        $pathState = $path->pathState;
                                                }

                                                if (defined($blacklist) && ($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/))
                                                {
                                                        $pathState = "ignored";
                                                        $count++;
                                                }

                                                my $normalizedPathState = uc($pathState);
                                                $count++ if ($normalizedPathState eq "ACTIVE");
                                                $state = 3 if (($state == 0) && ($normalizedPathState eq "3"));
                                                $state = 2 if ($normalizedPathState eq "DEAD");
                                                $output = $output . $name . " <" . $pathState . ">; ";
                                        }
                                }
                                $perfdata = $perfdata . " paths=" . $count . ";" . $perf_thresholds . ";;";
                                $actual_state = check_against_threshold($count);
                                if ($actual_state != 0)
                                   {
                                   $state = $actual_state;
                                   }
                        }
                        else
                        {
                                $output = "path info is unavailable on this host";
                                $state = 3;
                        }
                }
                else
                {
                get_me_out("Unknown HOST STORAGE subselect");
                }
        }
        else
        {
                my $status = 3;
                my $actual_state = 0;
                $output = "";
                $state = 0;
                foreach my $dev (@{$storage->storageDeviceInfo->hostBusAdapter})
                {
                        $status = 3;
                        if (uc($dev->status) eq "ONLINE")
                        {
                                $status = 0;
                                $count++;
                        }
                        elsif (uc($dev->status) eq "OFFLINE")
                        {
                                $status = 2;
                        }
                        elsif (uc($dev->status) eq "FAULT")
                        {
                                $status = 2;
                        }
                        else
                        {
                                $state = 3;
                        }
                        $actual_state = check_state($actual_state, $status);
                }

                $perfdata = $perfdata . " adapters=" . $count . ";" . $perf_thresholds . ";;";
                $output = $output . $count . "/" . @{$storage->storageDeviceInfo->hostBusAdapter} . " adapters online, ";

                $count = 0;
                foreach my $scsi (@{$storage->storageDeviceInfo->scsiLun})
                {
                        $status = 3;
                        foreach (@{$scsi->operationalState})
                        {
                                if (uc($_) eq "0")
                                {
                                        $status = 0;
                                        $count++;
                                }
                                elsif (uc($_) eq "ERROR")
                                {
                                        $status = 2;
                                }
                                elsif (uc($_) eq "3STATE")
                                {
                                        $status = 3;
                                }
                                elsif (uc($_) eq "OFF")
                                {
                                        $status = 2;
                                }
                                elsif (uc($_) eq "QUIESCED")
                                {
                                        $status = 1;
                                }
                                elsif (uc($_) eq "DEGRADED")
                                {
                                        $status = 1;
                                }
                                elsif (uc($_) eq "LOSTCOMMUNICATION")
                                {
                                        $status = 2;
                                }
                                else
                                {
                                        $state = 3;
                                        $status = 3;
                                }
                                $actual_state = check_state($actual_state, $status);
                        }
                }
                $perfdata = $perfdata . " LUNs=" . $count . ";" . $perf_thresholds . ";;";
                $output = $output . $count . "/" . @{$storage->storageDeviceInfo->scsiLun} . " LUNs ok, ";

                if (exists($storage->storageDeviceInfo->{multipathInfo}))
                {
                        $count = 0;
                        my $amount = 0;
                        foreach my $lun (@{$storage->storageDeviceInfo->multipathInfo->lun})
                        {
                                foreach my $path (@{$lun->path})
                                {
                                        my $status = 3; # For unkonwn or other statuses
                                        my $pathState = "unknown";
                                        if (exists($path->{state}))
                                        {
                                                $pathState = $path->state;
                                        }
                                        else
                                        {
                                                $pathState = $path->pathState;
                                        }

                                        $status = 3;
                                        if (uc($pathState) eq "ACTIVE")
                                        {
                                                $status = 0;
                                                $count++;
                                        }
                                        elsif (uc($pathState) eq "DISABLED")
                                        {
                                                $status = 1;
                                        }
                                        elsif (uc($pathState) eq "STANDBY")
                                        {
                                                $status = 1;
                                        }
                                        elsif (uc($pathState) eq "DEAD")
                                        {
                                                $status = 2;
                                        }
                                        else
                                        {
                                                $state = 3;
                                                $status = 3;
                                        }
                                        $actual_state = check_state($actual_state, $status);
                                        $amount++;
                                }
                        }
                        $perfdata = $perfdata . " paths=" . $count . ";" . $perf_thresholds . ";;";
                        $output = $output . $count . "/" . $amount . " paths active";
                }
                else
                {
                        $output = $output . "no path info";
                }

                $state = $actual_state if ($actual_state != 0);
        }

        return ($state, $output);
}

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
