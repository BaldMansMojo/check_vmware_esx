sub datastore_volumes_info
    {
    my ($datastore) = @_;
    my $state = 0;
    my $actual_state = 0;
    my $output = '';
    my $space_total;
    my $space_total_MB;
    my $space_total_GB;
    my $space_total_percent;
    my $space_free;
    my $space_free_MB;
    my $space_free_GB;
    my $space_free_percent;
    my $space_used;
    my $space_used_MB;
    my $space_used_GB;
    my $space_used_percent;
    my $warn_out;
    my $crit_out;
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
                  $space_total = $store->summary->capacity;
                  $space_free = $store->summary->freeSpace;
                  $space_used = $space_total - $space_free;
                  $space_used_percent = simplify_number(100 * $space_used/ $space_total);
                  $space_free_percent = 100 - $space_used_percent;

                  if ($gigabyte)
                     {
                     $space_total_GB = simplify_number($space_total / 1024 / 1024 / 1024);
                     $space_free_GB = simplify_number($space_free / 1024 / 1024 / 1024);
                     $space_used_GB = simplify_number($space_used / 1024 / 1024 / 1024);
                     $uom = "GB";
                     }
                  else
                     {
                     $space_total_MB = simplify_number($space_total / 1024 / 1024);
                     $space_free_MB = simplify_number($space_free / 1024 / 1024);
                     $space_used_MB = simplify_number($space_used / 1024 / 1024);
                     }

                  if (defined($warning) || defined($critical))
                     {
                     if (!(defined($warning) && defined($critical)))
                        {
                        print "For checking thresholds on volumes you MUST specify threshols for warning AND critical. Otherwise it is not possible";
                        print " to determine whether you are checking for used or free space!\n";
                        exit 2;
                        }
                     }
                  if (defined($warning) && defined($critical))
                     {
                     if ($usedspace)
                        {
                        if (!defined($subselect))
                           {
                           if ((!($warn_is_percent)) && (!($crit_is_percent)))
                              {
                              print "On multiple volumes setting warning or critical threshold is only allowed";
                              print " in percent for used space\n";
                              exit 2;
                              }
                           }
                        }
                     }
                     
                  if (($warn_is_percent) || ($crit_is_percent))
                     {
                     if ($usedspace)
                        {
                        $actual_state = check_against_threshold($space_used_percent);
                        $state = check_state($state, $actual_state);
                        }
                     else
                        {
                        $actual_state = check_against_threshold($space_free_percent);
                        $state = check_state($state, $actual_state);
                        }
                     if ( $state >= 0 )
                        {
                        $alertcnt++;
                        }
                     }
                  else
                     {
                     if ($usedspace)
                        {
                        if ($gigabyte)
                           {
                           $actual_state = check_against_threshold($space_used_GB);
                           $state = check_state($state, $actual_state);
                           }
                        else
                           {
                           $actual_state = check_against_threshold($space_used_MB);
                           $state = check_state($state, $actual_state);
                           }
                        }
                     else
                        {
                        if ($gigabyte)
                           {
                           $actual_state = check_against_threshold($space_free_GB);
                           $state = check_state($state, $actual_state);
                           }
                        else
                           {
                           $actual_state = check_against_threshold($space_free_MB);
                           $state = check_state($state, $actual_state);
                           }
                        }
                     if ( $state >= 0 )
                        {
                        $alertcnt++;
                        }
                     }

                  if ($gigabyte)
                     {
                     $space_total = $space_total_GB;
                     $space_free = $space_free_GB;
                     $space_used = $space_used_GB;
                     }
                  else
                     {
                     $space_total = $space_total_MB;
                     $space_free = $space_free_MB;
                     $space_used = $space_used_MB;
                     }
                     
                  if (($warn_is_percent) || ($crit_is_percent))
                     {
                     $warn_out =  $space_total / 100 * $warning;
                     $warn_out =  sprintf "%.2f", $warn_out;
                     $crit_out =  $space_total / 100 * $critical;
                     $crit_out =  sprintf "%.2f", $crit_out;
                     $perf_thresholds = $warn_out . ";" . $crit_out;
                     }
                     
                  $perfdata = $perfdata . " \'" . $name . "\'=" . $space_free . "$uom;" . $perf_thresholds . ";;" . $space_total;

                  if (!$alertonly || $actual_state != 0)
                     {
                     $output = $output . "$name ($volume_type)" . ($usedspace ? " used" : " free");
                     $output = $output . ": ". ($usedspace ? $space_used : $space_free);
                     $output = $output . " (" . ($usedspace ? $space_used_percent : $space_free_percent) . "%) / $space_total $uom (100%)";
                     $output = $output . $multiline;
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
             if (($warn_is_percent) || ($crit_is_percent))
                {
                $output = $alertcnt . " alerts for the selected volumes (warn:" . $warning . "%,crit:" . $critical . "%)." . $multiline . $output;
                }
             else
                {
                $output = $alertcnt . " alerts for the selected volumes (warn:" . $warning . ",crit:" . $critical . ")." . $multiline . $output;
                }
             }
          else
             {
             if (($warn_is_percent) || ($crit_is_percent))
                {
                $output = $alertcnt . " alerts found for some for the selected volumes (warn:" . $warning . "%,crit:" . $critical . "%)." . $multiline . $output;
                }
             else
                {
                $output = $alertcnt . " alerts found for some for the selected volumes (warn:" . $warning . ",crit:" . $critical . ")." . $multiline . $output;
                }
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
