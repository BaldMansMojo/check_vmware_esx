sub datastore_volumes_info
    {
    my ($datastore) = @_;
    my $state = 0;
    my $actual_state = 0;
    my $output = '';
    my $freespace;
    my $freespace_percent;
    my $capacity;
    my $used_capacity;
    my $capacity_percent;
    my $ref_store;
    my $store;
    my $name;
    my $volume_type;
    my $uom = "MB";
    my $alertcnt = 0;
        
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

                  $capacity = convert_number($store->summary->capacity);
                  $capacity_percent = simplify_number(convert_number($store->summary->freeSpace) / $capacity * 100);
                  $capacity_percent =  sprintf "%.0f", $capacity_percent;

                  if ($gigabyte)
                     {
                     $capacity = simplify_number(convert_number($store->summary->capacity) / 1024 / 1024 / 1024);
                     }
                  else
                     {
                     $capacity = simplify_number(convert_number($store->summary->capacity) / 1024 / 1024);
                     }

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
                     $capacity_percent = 100 - $capacity_percent;
                     }
  
                  $freespace =  sprintf "%.2f", $freespace;

                  if (defined($warning) || defined($critical))
                     {
                     if (!(defined($warning) && defined($critical)))
                        {
                        print "For checking thresholds on volumes you MUST specify threshols for warning AND critical. Otherwise it is not possible";
                        print " to determine whether you are checking for used or free space!\n";
                        exit 2;
                        }
                     }
                     
                  if (($warn_is_percent) || ($crit_is_percent))
                     {
                     $actual_state = check_against_threshold($capacity_percent);
                     $state = check_state($state, $actual_state);
                     if ( $state >= 0 )
                        {
                        $alertcnt++;
                        }
                     }
                  else
                     {
                     if (defined($warning) && defined($critical))
                        {
                        print "On multiple volumes setting warning or critical threshold is only allowed in percent and not in absolute values!\n";
                        exit 2;
                        }
                     }

                  $perfdata = $perfdata . " " . $name . "=" . $freespace . "$uom;" . $perf_thresholds . ";;" . $capacity;

                  if (!$alertonly || $actual_state != 0)
                     {
                     $output = $output . "$name" . " (" . $volume_type . ")" . ($usedspace ? " used" : " free") . ": ". $freespace . " / " . $capacity . " $uom (" . $capacity_percent . "%)". $multiline;
                     }
                  }
               else
                  {
                  $state = 2;
                  $output = $output . "'$name' is not accessible, ";
                  $alertcnt++;
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
          $output = "OK for all selected volumes." . $multiline . $output;
          }
       else
          {
          if ($alertonly)
             {
             $output = $alertcnt . " alerts for the selected volumes (warn:" . $warning . "%,crit:" . $critical . "%)." . $multiline . $output;
             }
             else
             {
             $output = $alertcnt . " alerts found for some for the selected volumes (warn:" . $warning . "%,crit:" . $critical . "%)." . $multiline . $output;
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
# is a common method to ensure this.
1;
