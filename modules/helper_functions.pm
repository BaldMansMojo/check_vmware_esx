sub check_against_threshold
    {
    my $check_result = shift(@_);
    my $return_state = 0;

    if (defined($warning) && defined($critical))
       {
       if ( $check_result >= $warning  && $check_result < $critical)
          {
          $return_state = 1;
          }
       }
          
    if (defined($warning))
       {
       if ( $check_result >= $warning)
          {
          $return_state = 1;
          }
       }

    if (defined($critical))
       {
       if ( $check_result >= $critical)
          {
          $return_state = 2;
          }
       }
    return $return_state;
    }
    
sub check_state
    {
    my ($tmp_state1, $tmp_state2) = @_;
    
    if ($tmp_state1 < $tmp_state2)
       {
       return $tmp_state2;
       }

    if ($tmp_state1 >= $tmp_state2)
       {
       return $tmp_state1;
       }
    }
    

sub local_lc
    {
    my ($val) = shift(@_);
    if (defined($val))
       {
       return lc($val);
       }
    else
       {
       return undef;
       }
    }

sub simplify_number
    {
    my ($number, $cnt) = @_;
    if (!defined($cnt))
       {
       $cnt = 2;
       }
    return sprintf("%.${cnt}f", "$number");
    }

sub convert_number
    {
    my @vals = split(/,/, shift(@_));
    my $state = 0;
    my $value;

    while (@vals)
          {
          $value = pop(@vals);
          $value =~ s/^\s+//;
          $value =~ s/\s+$//;
          
          if (defined($value) && $value ne '')
             {
             if ($value >= 0)
                {
                return $value;
                }
             if ($state == 0)
                {
                $state = $value;
                }
             }
          }
    return $state;
    }

sub check_health_state
    {
    my ($actual_state) = shift(@_);
    my $state = 3;

    if (uc($actual_state) eq "GREEN")
       {
       $state = 0
       }

    if (uc($actual_state) eq "YELLOW")
       {
       $state = 1;
       }
 
    if (uc($actual_state) eq "RED")
       {
       $state = 2;
       }
    return $state;
    }

sub format_issue
    {
    my ($issue) = shift(@_);
    my $output = '';

    if (defined($issue->datacenter))
       {
       $output = $output . 'Datacenter "' . $issue->datacenter->name . '", ';
       }

    if (defined($issue->host))
       {
       $output = $output . 'Host "' . $issue->host->name . '", ';
       }

    if (defined($issue->vm))
       {
       $output = $output . 'VM "' . $issue->vm->name . '", ';
       }

    if (defined($issue->computeResource))
       {
       $output = $output . 'Compute Resource "' . $issue->computeResource->name . '", ';
       }

    if (exists($issue->{dvs}) && defined($issue->dvs))
       {
       # Since vSphere API 4.0
       $output = $output . 'Virtual Switch "' . $issue->dvs->name . '", ';
       }

    if (exists($issue->{ds}) && defined($issue->ds))
       {
       # Since vSphere API 4.0
       $output = $output . 'Datastore "' . $issue->ds->name . '", ';
       }

    if (exists($issue->{net}) && defined($issue->net))
       {
       # Since vSphere API 4.0
       $output = $output . 'Network "' . $issue->net->name . '" ';
       }

       $output =~ s/, $/ /;
       $output = $output . ": " . $issue->fullFormattedMessage;
       if ($issue->userName ne "")
          {
          $output = $output . "(caused by " . $issue->userName . ")";
          }

       return $output;
}

# SOAP check, isblacklisted and isnotwhitelisted from Simon Meggle, Consol.
#  Slightly modified to for this plugin by M.Fuerstenau. Oce Printing Systems

sub soap_check
    {
    my $output = 'Fatal error: could not connect to the VMWare SOAP API.';
    my $state = Vim::get_vim_service();
    
    if (defined($state))
       {
       $state=0;
       $output = 'Successfully connected to the VMWare SOAP API.';
       }
    else
       {
       $state=2;
       }
    return ($state, $output);
    }

sub isblacklisted
    {
    my ($blacklist_ref,$regexpflag,@candidates) = @_;
    my $ret;
    
    if (!defined $$blacklist_ref)
       {
       return 0;
       }

    if ($regexpflag)
       {
       $ret = grep (/$$blacklist_ref/, @candidates);    
       }
    else
       {
       $ret = grep {$$blacklist_ref eq $_} @candidates;;
       }
    return $ret;
}

sub isnotwhitelisted
    {
    my ($whitelist_ref,$regexpflag,@candidates) = @_;
    my $ret;
    
    if (!defined $$whitelist_ref)
       {
       return 0;
       }
    
    if ($regexpflag)
       {
       $ret = ! grep (/$$whitelist_ref/, @candidates);
       }
       else
       {
       $ret = ! grep {$$whitelist_ref eq $_} @candidates;;
       }
    return $ret;
    }

# The "ejection seat". Display error message and leaves the program.
sub get_me_out
    {
    my ($msg) = @_;
    print "$msg\n";
    print "\n";
    print_help();
    exit 2;
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;