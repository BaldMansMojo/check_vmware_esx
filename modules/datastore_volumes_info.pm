sub datastore_volumes_info
    {
    my ($datastore, $subselect, $blacklist) = @_;
    my $state = 0;
    my $actual_state;
    my $output = '';
    my $value1;
    my $value2;
    my $ref_store;
    my $store;
    my $name;
    my $volume_type;
    
    if (defined($subselect) && defined($blacklist) && !defined($isregexp))
       {
       print "Blacklist is supported only in generic check or regexp subcheck\n";
       exit 2;
       }

    if (defined($isregexp) && defined($subselect))
       {
       eval {qr{$subselect};};

       if ($@)
          {
          $@ =~ s/ at.*line.*\.//;
          die $@;
          }
        }

    foreach $ref_store (@{$datastore})
            {
            $store = Vim::get_view(mo_ref => $ref_store, properties => ['summary', 'info']);

            $name = $store->summary->name;
            $volume_type = $store->summary->type;
            
            if (!defined($subselect) || ($name eq $subselect) || (defined($isregexp) && $name =~ /$subselect/))
               {
               if (defined($blacklist))
                  {
                  if ($blacklistregexp?$name =~ /$blacklist/:$blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/)
                     {
                     next;
                     }
                  }

               if ($store->summary->accessible)
                  {
                  $value1 = simplify_number(convert_number($store->summary->freeSpace) / 1024 / 1024);
                  $value2 = convert_number($store->summary->capacity);
                  if ($value2 > 0)
                     {
                     $value2 = simplify_number(convert_number($store->info->freeSpace) / $value2 * 100);
                     }

                  if ($usedspace)
                     {
                     $value1 = simplify_number(convert_number($store->summary->capacity) / 1024 / 1024) - $value1;
                     $value2 = 100 - $value2;
                     }

                  $actual_state = check_against_threshold($value1);
                  $state = check_state($state, $actual_state);
                  $perfdata = $perfdata . " " . $name . "=" . $value1 . "%:MB;" . $perf_thresholds . ";;";
                  if (!$alertonly || $actual_state != 0)
                     {
                     $output = $output . "$name" . " (" . $volume_type . ")" . ($usedspace ? " used" : " free") . ": ". $value1 . " MB (" . $value2 . "%)". $multiline;
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
               if (defined($blacklist))
                  {
                  $blacklist = $blacklist . $blacklistregexp?"|^$name\$":",$name";
                  }
               }
            }

    if ($output)
       {
       chop($output);
       $output = "For all Storages : " . $multiline . $output;
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
