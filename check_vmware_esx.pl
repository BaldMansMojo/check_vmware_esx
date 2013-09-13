#!/usr/bin/perl -w
#
# Nagios plugin to monitor vmware ESX and vSphere servers
#
# License: GPL
# This plugin is a forked from the original one from op5 by Martin Fuerstenau
# Copyright (c) 2008 op5 AB
# Author: Kostyantyn Hushchyn <dev@op5.com>
# Contributor(s): Patrick Müller, Jeremy Martin, Eric Jonsson, stumpr, John Cavanaugh, Libor Klepac, maikmayers, Steffen Poulsen, Mark Elliott, simeg, sebastien.prudhomme, Raphael Schitz
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use File::Basename;
use HTTP::Date;
use Getopt::Long;
use VMware::VIRuntime;
use Time::Duration;

# Own modules
use lib "modules";
use help;
use process_perfdata;
use datastore_volumes_info;

# Only for debugging
use Data::Dumper;
#            print "------------------------------------------\n" . Dumper ($store) . "\n" . "------------------------------------------\n";


if ( $@ )
   {
   print "No VMware::VIRuntime found. Please download ";
   print "latest version of VMware-vSphere-SDK-for-Perl from VMware ";
   print "and install it.\n";
   exit 2;
   }

#--- Start presets and declarations -------------------------------------
# 1. Define variables

# General stuff
our $version = '0.7.1';                        # Contains the program version number
our $ProgName = basename($0);
my $help;                                      # If some help is wanted....
my $NoA="";                                    # Number of arguments handled over
                                               # the program
# Login options
my $username;                                  # Username for vmware host or vsphere server (datacenter)
my $password;                                  # Password for vmware host or vsphere server (datacenter)
my $authfile;                                  # If username/password should read from a file ....
my $sessionfile_name;                          # Contains the name of the sessionfile if a
                                               # a sessionfile is used for faster authentication


my $host;                                      # Name of the vmware server
my $cluster;                                   # Name of the monitored cluster
my $datacenter;                                # Name of the vCenter server
my $vmname;                                    # Name of the virtual machine

my $output;                                    # Contains the output string
my $values;
my $result;                                    # Contains the output string
our $perfdata;                                 # Contains the perfdata string.
my $perfdata_init = "perfdata:";               # Contains the perfdata init string. We init $perfdata with
                                               # a stupid string because in case of concatenate perfdata
                                               # it is much more simple to remove a leading string with
                                               # a regular expression than to decide in every case wether
                                               # the variablecontains content or not.
$perfdata = $perfdata_init;                    # Init of perfdata. Using variables instead of literals ensures
                                               # that the string can be changed here without harm the function.
our $perf_thresholds = ";";                    # This contains the string with $warning, $critical or nothing
                                               # for $perfdata. If no thresold is set it is just ;

my $url2connect;                               # Contains the URL to connect to the host
                                               # or the datacenter depending on the selected type
my $select;
our $subselect;

my $warning;                                   # Warning threshold.
my $critical;                                  # Critical threshold.

my $crit_is_percent;                           # Flag. If it is set to one critical threshold is percent.
my $warn_is_percent;                           # Flag. If it is set to one warning threshold is percent.
my $thresholds_given = 0;                      # During checking the threshold it will be set to one. Only if
                                               # it is set we will check the threshold against warning or critical
                                        
my $plugin_cache="/var/nagios_plugin_cache/";  # Directory for caching plaugin data. Good idea to use a tmpfs
                                               # because it speeds up operation    
my $listitems;                                 # This flag set in conjunction with -l runtime -s health will list all sensors
my $usedspace;                                 # Show used spaced instead of free
my $adaptermodel;                              # Additional information about storage adapters
                                               
my $alertonly;                                 # vmfs - list only alerting volumes

our $blacklist;                                # Contains the blacklist
our $blacklistregexp;                          # treat blacklist as regexp
our $whitelist;                                # Contains the whitelist
our $whitelistregexp;                          # treat whitelist as regexp

my $isregexp;                                  # treat vmfs volume names as regexp

my $sec;                                       # Seconds      - used for some date functions
my $min;                                       # Minutes      - used for some date functions
my $hour;                                      # Hour         - used for some date functions
my $mday;                                      # Day of month - used for some date functions
my $mon;                                       # Month        - used for some date functions
my $year;                                      # Year         - used for some date functions

# Output options
our $multiline;                                # Multiline output in overview. This mean technically that
                                               # a multiline output uses a HTML <br> for the GUI instead of
                                               # Be aware that your messing connections (email, SMS...) must use
                                               # a filter to file out the <br>. A sed oneliner like the following
                                               # will do the job:
                                               # sed 's/<[^<>]*>//g'
my $multiline_def="\n";                        # Default for $multiline;

my $ignoreunknown;                             # Maps unknown to ok
our $listall;                                   # used for host. Lists all available devices(use for listing purpose only)
my $sensorname;                                # Contains the name of a single sensor


my @values;

my $trace;
my $timeout = 30;


# 2. Define arrays and hashes  

# The same as in Nagios::plugin::functions but it is ridiculous to buy a truck for a
# "one time one box" transportations job.

my %status2text = (
    0 => 'OK',
    1 => 'WARNING',
    2 => 'CRITICAL',
    3 => 'UNKNOWN',
    4 => 'DEPENDENT',
);

#--- End presets --------------------------------------------------------

# First we have to fix  the number of arguments

$NoA=$#ARGV;

Getopt::Long::Configure('bundling');
GetOptions
	("h"   => \$help,                "help"             => \$help,
	 "H=s" => \$host,                "host=s"           => \$host,
	 "C=s" => \$cluster,             "cluster=s"        => \$cluster,
	 "D=s" => \$datacenter,          "datacenter=s"     => \$datacenter,
	 "w=s" => \$warning,             "warning=s"        => \$warning,
	 "c=s" => \$critical,            "critical=s"       => \$critical,
	 "N=s" => \$vmname,              "name=s"           => \$vmname,
	 "u=s" => \$username,            "username=s"       => \$username,
	 "p=s" => \$password,            "password=s"       => \$password,
	 "f=s" => \$authfile,            "authfile=s"       => \$authfile,
	 "S=s" => \$select,              "select=s"         => \$select,
	 "s=s" => \$subselect,           "subselect=s"      => \$subselect,
	                                 "sessionfile=s"    => \$sessionfile_name,
	 "x=s" => \$blacklist,           "exclude=s"        => \$blacklist,
                                         "blacklistregexp"  => \$blacklistregexp,
	 "y=s" => \$whitelist,           "include=s"        => \$whitelist,
                                         "whitelistregexp"  => \$whitelistregexp,
	                                 "ignore_unknown"   => \$ignoreunknown,
	                                 "adaptermodel"     => \$adaptermodel,
	                                 "trace"            => \$trace,
                                         "listitems"        => \$listitems,
                                         "usedspace"        => \$usedspace,
                                         "alertonly"        => \$alertonly,
                                         "multiline"        => \$multiline,
                                         "isregexp"         => \$isregexp,
                                         "listall"          => \$listall,
                                         "sensorname"       => \$sensorname);

# Several checks to check parameters
if ($help)
   {
   print_help();

   exit 0;
   }

# Multiline output in GUI overview?
if ($multiline)
   {
   $multiline = "<br>";
   }
else
   {
   $multiline = $multiline_def;
   }

# Right number of arguments (therefore NoA :-)) )

if ( $NoA == -1 )
   {
   print_help();
   exit 1;
   }

# If you have set a timeout exit with alarm()
if ($timeout)
   {
   alarm($timeout);
   }

$output = "Unknown ERROR!";
$result = 2;

if (defined($sessionfile_name))
   {
   $sessionfile_name =~ s/ +//g;
   $sessionfile_name = $plugin_cache . $host . "_" . $sessionfile_name;
   }

# Check $subselect and if defined set it to upper case letters
if (defined($subselect))
   {
   if ($subselect eq '')
      {
      $subselect = undef;
      }
      else
      {
      $subselect = local_lc($subselect)
      }
   }

# Now we remove the percent sign if warning or critical is givenin percent
# Construct threshold part for perfomance data

if (defined($warning))
   {
   $warn_is_percent  = $warning =~ s/\%//;

   if ($warning eq '')
      {
      $warning = undef;
      $perf_thresholds = $perf_thresholds . ";";
      }
   else
      {
      # Numeric now or not?
      if ($warning =~ m/^[0-9]+$/)
         {
         $thresholds_given = 1;
         
         # If percent check a valid range
         if ($warn_is_percent eq 1)
            {
            if (!($warning > 0 && $warning <= 100 ))
               {
               print "Invalid warning threshold: $warning%\n\n";
               exit 2;
               }
            }
         $perf_thresholds = $warning .$perf_thresholds;
         }
      else
         {
         print "Warning threshold contains unwanted characters: $warning\n\n";
         exit 2;
         }
      }
   }

if (defined($critical))
   {
   $crit_is_percent  = $critical =~ s/\%//;

   if ($critical eq '')
      {
      $critical = undef;
      $perf_thresholds = $perf_thresholds . ";";
      }
   else
      {
      # Numeric now or not?
      if ($critical =~ m/^[0-9]+$/)
         {
         $thresholds_given = 1;

         # If percent check a valid range
         if ($crit_is_percent eq 1)
            {
            if (!($critical > 0 && $critical <= 100 ))
               {
               print "\nInvalid critical threshold: $critical%\n";
               exit 2;
               }
            }
         $perf_thresholds = $perf_thresholds . $critical;
         }
      else
         {
         print "Critical threshold contains unwanted characters: $critical\n\n";
         exit 2;
         }
      }
   }

# Is critical greater than warning?
if (defined($warning) && defined($critical))
   {
   if ( $warning >= $critical)
      {
      print "ERROR! Warning should not be greater or equal than critical\n";
      exit 1;
      }
   }

# Check for authfile or valid username/password

if ((!defined($password) || !defined($username) || defined($authfile)) && (defined($password) || defined($username) || !defined($authfile)) && (defined($password) || defined($username) || defined($authfile) || !defined($sessionfile_name)))
   {
   print "Provide either Password/Username or Auth file or Session file\n";
   exit 2;
   }

# Check threshold unit

if (($warn_is_percent && !$crit_is_percent && defined($critical)) || (!$warn_is_percent && $crit_is_percent && defined($warning)))
   {
   print "Both threshold values must be the same units\n";
   exit 2;
   }

if (defined($authfile))
   {
   open (AUTH_FILE, $authfile) || die "Unable to open auth file \"$authfile\"\n";
   
   while ( <AUTH_FILE> )
         {
         if (s/^[ \t]*username[ \t]*=//)
            {
            s/^\s+//;s/\s+$//;
            $username = $_;
            }
         if (s/^[ \t]*password[ \t]*=//)
            {
            s/^\s+//;s/\s+$//;
            $password = $_;
            }
         }
   if (!(defined($username) && defined($password)))
      {
      print "Auth file must contain both username and password\n";
      exit 2;
      }
   }

# Connection to a single host or a datacenter server?

if (defined($datacenter))
   {
   $url2connect = $datacenter;
   }
else
   {
   if (defined($host))
      {
      $url2connect = $host;
      }
   else
      {
      print "No Host or Datacenter specified\n";
      exit 2;
      }
   }

if (index($url2connect, ":") == -1)
   {
   $url2connect = $url2connect . ":443";
   }

$url2connect = "https://" . $url2connect . "/sdk/webService";

if (defined($sessionfile_name) and -e $sessionfile_name)
   {
   Opts::set_option("sessionfile", $sessionfile_name);
   Util::connect($url2connect, $username, $password);
   
   if (Opts::get_option("url") ne $url2connect)
      {
      print "Connected host doesn't match reqested URL.\n";
      Opts::set_option("sessionfile", undef);
      Util::connect($url2connect, $username, $password);
      }
   }
else
   {
   Util::connect($url2connect, $username, $password);
   }

if (defined($sessionfile_name))
   {
   Vim::save_session(session_file => $sessionfile_name);
   }

# Tracemode?
if (defined($trace))
   {
   $Util::tracelevel = $Util::tracelevel;

   if (($trace =~ m/^\d$/) && ($trace >= 0) && ($trace <= 4))
      {
      $Util::tracelevel = $trace;
      }
   }

$select = lc($select);

# This calls the main selection. It is now in a subroutine
# because after a successfull if statement the rest can be skipped
# leaving the subroutine with return

main_select();

if ($@)
   {
   if (uc(ref($@)) eq "HASH")
      {
      $output = $@->{msg};
      $result = $@->{code};
      }
   else
      {
      $output = $@ . "";
      $result = 2;
      }
   }

Util::disconnect();

# Added for mapping unknown to ok - M.Fuerstenau - 30 Mar 2011

if (defined($ignoreunknown))
   {
   if ($result eq 3)
      {
      $result = 0;
      }
   }

# Now we remove the leading init string and whitespaces from the perfdata
$perfdata =~ s/^$perfdata_init//;
$perfdata =~ s/^[ \t]*//;

if ( $result == 0 )
   {
   print "Ok. $output";
   if ($perfdata)
      {
      print "|$perfdata\n";
      }
      else
      {
      print "\n";
      }
   }

if ( $result == 1 )
   {
   print "Warning! $output";
   if ($perfdata)
      {
      print "|$perfdata\n";
      }
      else
      {
      print "\n";
      }
   }

if ( $result == 2 )
   {
   print "Critical! $output";
   if ($perfdata)
      {
      print "|$perfdata\n";
      }
      else
      {
      print "\n";
      }
   }

if ( $result == 3 )
   {
   print "Unknown! $output";
   if ($perfdata)
      {
      print "|$perfdata\n";
      }
      else
      {
      print "\n";
      }
   }

exit $result;

#######################################################################################################################################################################
#here be dragons