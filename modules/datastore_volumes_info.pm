sub datastore_volumes_info
    {
    my ($datastore) = @_;
    my $state = 0;
    my $actual_state = 0;
    my $output = '';
    my $freespace;
    my $freespace_percent;
    my $used_capacity;
    my $used_capacity_percent;
    my $ref_store;
    my $store;
    my $name;
    my $volume_type;
    my $uom = "MB";
        
    if (defined($subselect) && defined($blacklist) && !defined($isregexp))
       {
       print "Blacklist is supported only in overall check (no subselect) or regexp subcheck\n";
       exit 2;
       }

    if (defined($subselect) && defined($whitelist) && !defined($isregexp))
       {
       print "Whitelist is supported only in overall check (no subselect) or regexp subcheck\n";
       exit 2;
       }

    if (defined($isregexp))
       {
       $isregexp = 1;
       }
    else
       {
       $isregexp = 0;
       }
               
    foreach $ref_store (@{$datastore})
            {
            $store = Vim::get_view(mo_ref => $ref_store, properties => ['summary', 'info']);

            $name = $store->summary->name;
            $volume_type = $store->summary->type;

            if (!defined($subselect) || ($name eq $subselect) || (($isregexp == 1) && ($name =~ m/$subselect/)))
               {
               
               if (defined($blacklist))
                  {
                  if (isblacklisted(\$blacklist, $isregexp, $name ))
                     {
                     next;
                     }
                  }

               if (defined($whitelist))
                  {
                  if (isnotwhitelisted(\$whitelist, $isregexp, $name))
                     {
                     next;
                     }
                  }

               if ((!defined($blacklist)) && (!defined($blacklist)) && ((defined($subselect) && $name !~ m/$subselect/)))
                  {
                  next;
                  }

               if ($store->summary->accessible)
                  {
                  if ($gigabyte)
                     {
                     $freespace = simplify_number(convert_number($store->summary->freeSpace) / 1024 / 1024 / 1024);
                     $uom = "GB";
                     }
                  else
                     {
                     $freespace = simplify_number(convert_number($store->summary->freeSpace) / 1024 / 1024);
                     }

                  $used_capacity = convert_number($store->summary->capacity);
                  $used_capacity_percent = simplify_number(convert_number($store->info->freeSpace) / $used_capacity * 100);
                  if ($usedspace)
                     {
                     if ($gigabyte)
                        {
                        $freespace = simplify_number(convert_number($store->summary->capacity) / 1024 / 1024 / 1024) - $freespace;
                        $uom = "GB";
                        }
                     else
                        {
                        $freespace = simplify_number(convert_number($store->summary->capacity) / 1024 / 1024) - $freespace;
                        }
                     $used_capacity_percent = 100 - $used_capacity_percent;
                     }
  
                     $used_capacity_percent =  sprintf "%.0f", $used_capacity_percent;

                  if (($warn_is_percent) || ($crit_is_percent))
                     {
                     $actual_state = check_against_threshold($used_capacity_percent);
                     $state = check_state($state, $actual_state);
                     }
                  else
                     {
                     if (defined($warning) && defined($critical))
                        {
                        print "On multiple volumes setting warning or critical threshold is only allowed in percent and not in absolute values!\n";
                        exit 2;
                        }
                     }

                  $perfdata = $perfdata . " " . $name . "=" . $freespace . "$uom;" . $perf_thresholds . ";;";

                  if (!$alertonly || $actual_state != 0)
                     {
                     $output = $output . "$name" . " (" . $volume_type . ")" . ($usedspace ? " used" : " free") . ": ". $freespace . " $uom (" . $used_capacity_percent . "%)". $multiline;
                     }
                  }
               else
                  {
                  $state = 2;
                  $output = $output . "'$name' is not accessible, ";
                  }
            
               if (!$isregexp && defined($subselect) && ($name eq $subselect))
                  {
                  last;
                  }
               }
            }

    if ($output)
       {
       chop($output);
       if ( $state == 0 )
          {
          $output = "For all volumes: " . $multiline . $output;
          }
       else
          {
          if ($alertonly)
             {
             $output = "Alerts for the following volumes: " . $multiline . $output;
             }
             else
             {
             $output = "Alerts some for the following volumes (please check): " . $multiline . $output;
             }
          }
       }
    else
       {
       if ($alertonly)
          {
          $output = "There are no alerts";
          }
       else
          {
          $state = 1;
          $output = defined($subselect)?$isregexp? "No matching volumes for regexp \"$subselect\" found":"No volume named \"$subselect\" found":"There are no volumes";
          }
       }
       return ($state, $output);
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
