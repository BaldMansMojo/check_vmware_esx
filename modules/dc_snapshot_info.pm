sub dc_snapshot_info
    {
    my $count = 0;
    my $state;
    my $output;
    my $host_view;
    my $vm_views;
    my $vm;
    my $istemplate;
    my $match;
    my $displayname;
    my $devices;

    $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'config.template', 'snapshot', 'runtime.powerState']);

    if (!defined($vm_views))
       {
       print "Runtime error\n";
       exit 2;
       }
    $output = '';

    if (!defined($subselect))
       {
       $subselect = "age";
       }

    foreach $vm (@$vm_views)
            {
            my $vm_snapinfo = $vm->{snapshot};
            next unless defined $vm_snapinfo;
            # change get_property to {} to avoid infinite loop
            $istemplate = $vm->{'config.template'};

            if ($istemplate && ($istemplate eq 'true'))
               {
               next;
               }

            $match = 0;
            $displayname = $vm->name;

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
               if (isblacklisted(\$blacklist, $isregexp, $displayname))
                  {
                  next;
                  }
               }
            if (defined($whitelist))
               {
               if (isnotwhitelisted(\$whitelist, $isregexp, $displayname))
                  {
                  next;
                  }
               }
            my $snapstate = 0;
            my $snapoutput = "";
            if ($subselect eq "age")
               {
               ($snapstate, $snapoutput) = check_snapshot_age( $vm->{name}, $vm_snapinfo->{rootSnapshotList} );
               }
               elsif ($subselect eq "count")
               {
               my %vm_snapshot_count;
               ($snapstate, $snapoutput) = check_snapshot_count( $vm->{name},
                   $vm_snapinfo->{rootSnapshotList}, \%vm_snapshot_count );
               }
            if ($snapstate)
               {
               $state = final_state($state, $snapstate);
               $count++;
               $output = "$snapoutput" . $multiline . $output;
               }
               else
               {
               if ($listall)
                  {
                  $output .= "$snapoutput" . $multiline;
                  }
               }
            }

    #Cut the last multiline of $output. Second line is better than 2 time chop() like the original :-)
    if ($output ne '')
       {
       $output  =~ s/<br>$//i;
       $output  =~ s/\n$//i;
       }

    if ($count)
       {
       $output = "VMs with snapshots:" . $multiline . $output;
       }
    else
       {
       if ($listall)
          {
          $output = "No VMs with outdated/too many snapshots found. VMs." . $multiline . $output;
          }
       else
          {
          $output = "No VMs with outdated/too many snapshots found.";
          }
       $state = 0;
       }

    return ($state, $output);
    }

sub check_snapshot_age
    {
    my $vm_name = shift;
    my $vm_snaplist = shift;
    my $output = "";
    my $state = 0;

    foreach my $vm_snap (@{$vm_snaplist})
            {
            if ($vm_snap->{childSnapshotList})
               {
               my ($cstate, $coutput) = check_snapshot_age($vm_name, $vm_snap->{childSnapshotList});
               if ($cstate)
                  {
                  $output .= $coutput . $multiline;
                  $state = final_state($state, $cstate);
                  }
               }

            my $epoch_snap = str2time( $vm_snap->{createTime} );
            my $days_snap = ( ( time() - $epoch_snap ) / 86400 );
            my $tstate = check_against_threshold($days_snap);
            if ($tstate)
               {
               $output .= sprintf "Snapshot \"%s\" (VM: '%s') is %0.1f days old",
                $vm_snap->{name}, $vm_name, $days_snap . $multiline;
               $state = final_state($state, $tstate);
               }
            }
    return ($state, $output);
    }

sub check_snapshot_count
    {
    my $vm_name = shift;
    my $vm_snaplist = shift;
    my $vm_snapcount = shift;
    my $recursion = shift || 0;
    my $output = "";
    my $state = 0;

    foreach my $vm_snap (@{$vm_snaplist})
            {
            if ($vm_snap->{childSnapshotList})
               {
               my ($cstate, $coutput) = check_snapshot_count($vm_name, $vm_snap->{childSnapshotList}, $vm_snapcount, 1);
               }
               $vm_snapcount->{$vm_name}++;
            }
            if ($recursion == 0)
               {
               my $tstate = check_against_threshold($vm_snapcount->{$vm_name});
               $output .= sprintf "VM '%s' has %d snapshots",
                   $vm_name, $vm_snapcount->{$vm_name} . $multiline;
               $state = final_state($state, $tstate);
               return ($state, $output);
               }
    }

sub final_state
    {
    my ($state1, $state2) = @_;

    if ($state1)
       {
       if ($state2 == 2)
          {
          return $state2;
          }
          elsif ($state1 == 1 && $state2 == 3)
          {
          return $state1;
          }
          else
          {
          return $state1;
          }
       }
       else
       {
       return $state2;
       }
    }
# A module always must end with a return code of 1. So placing 1 at the end of a module
# is a common method to ensure this.
1;
