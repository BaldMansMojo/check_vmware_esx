#!/usr/bin/perl -w
#
# Nagios plugin to monitor vmware ESX and vSphere servers
#
# License: GPL
# This plugin is a forked by Martin Fuerstenau from the original one (check_esx.pl) from op5
#
# Copyright (c) 2008 op5 AB
# Original author: Kostyantyn Hushchyn <dev@op5.com>
# Contributor(s):
#   Patrick Müller
#   Jeremy Martin
#   Eric Jonsson
#   stumpr
#   John Cavanaugh
#   Libor Klepac
#   maikmayers
#   Steffen Poulsen
#   Mark Elliott
#   Simon Meggle
#   Sebastien Prudhomme
#   Raphael Schitz
#   Markus Frosch
#   Michael Friedrich
#   Sven Nierlein
#   Gerhard Lausser
#   Danijel Tasov
#   6uellerBpanda
#   Ricardo Bartels
#   Claudio Kuenzler
#   Bob Carlson
#   Michael Geschwinder
#   Manfred W
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
# History and Changes:
#
# - 22 Mar 2012 M.Fuerstenau
#   - Started with actual version 0.5.0
#   - Impelemented check_esx3new2.diff from Simon (simeg / simmerl)
#   - Reimplemented the changes of Markus Obstmayer for the actual version
#   - Comments within the code inform you about the changes
#   - It may happen that controllers has been found which are not active.
#     Therefor around line 2300        the following was added:
#
#     # M.Fuerstenau - additional to avoid using inactive controllers --------------
#      elsif (uc($dev->status) eq "3")
#            {
#            $status = 0;
#            }
#     #----------------------------------------------------------------------------
#           else
#            {
#            $state = 3;
#           }
#            $actual_state = Nagios::Plugin::Functions::max_state($actual_state, $status);
#            }
#            $perfdata = $perfdata . " adapters=" . $count . ";"$perf_thresholds . ";;";
#
#           # M.Fuerstenau - changed the output a little bit 
#           $output .= $count . " of " . @{$storage->storageDeviceInfo->hostBusAdapter} . " defined/possible adapters online, ";
#
# - 30 Mar 2012 M.Fuerstenau
#   - added --ignore_unknown. This maps 3 to 0. Why? You have for example several host adapters. Some are reported as
#     unknown by the plugin because they are not used or have not the capability to reports something senseful.
#
# - 02 Apr 2012 M.Fuerstenau
#   - _info (Adapter/LUN/Path). Removed perfdata. To count such items and display as perfdata doesn't make sense
#   - Changed PATH to MPATH and help from "path - list logical unit paths" to "mpath - list logical unit multipath info" because
#     it is NOT an information about a path - it is an information about multipathing.
#
# - 08 Jan 2013 M.Fuerstenau
#   - Removed installation informations for the perl SDK from VMware. This informations are part of the SDK and have nothing to do
#     with this plugin.
#   - Replaced global variables with my variables. Instead of "define every variable on the fly as needed it is a good practice
#     to define variables at the beginning and place a comment within it. It gives you better readability.
#
# - 22 Jan 2013 M.Fuerstenau
#   - Merged with the actual version from op5. Therfore all changes done to the op5 version:
#
#   - 2012-05-28  Kostyantyn Hushchyn
#     Rename check_esx3 to check_vmware_api(Fixed issue #3745)
#
#   - 2012-05-28  Kostyantyn Hushchyn
#     Minor cosmetic changes
#
#   - 2012-05-29  Kostyantyn Hushchyn
#     Clear cluster failover perfdata units, as it describes count of possible failures
#     to tolerate, so can't be mesured in MB
#
#   - 2012-05-30  Kostyantyn Hushchyn
#     Minor help message changes
#
#   - 2012-05-30  Kostyantyn Hushchyn
#     Implemented timeshift for cluster checks, which could fix data retrievel issues. Small refactoring.
#
#   - 2012-05-31  Kostyantyn Hushchyn
#     Remove dependency on inteval value for cluster checks, which allows to run commands that doesn't require historical intervals
#
#   - 2012-05-31  Kostyantyn Hushchyn
#     Remove unnecessary/unimplemented function which caused cluster effectivecpu subcheck to fail
#
#   - 2012-06-01  Kostyantyn Hushchyn
#     Hide NIC status output for net check in case of empty perf data result(Fixed issue #5450)
#
#   - 2012-06-07  Kostyantyn Hushchyn
#     Fixed manipulation with undefined values, which caused perl interpreter warnings output
#
#   - 2012-06-08  Kostyantyn Hushchyn
#     Moved out global variables from perfdata functions. Added '-M' max sample number argument, which specify maximum data count to retrive.
#
#   - 2012-06-08  Kostyantyn Hushchyn
#     Added help text for Cluster checks.
#
#   - 2012-06-08  Kostyantyn Hushchyn
#     Increment version number Kostyantyn Hushchyn
#
#   - 2012-06-11  Kostyantyn Hushchyn
#     Reimplemented csv parser to process all values in sequence. Now all required functionality for max sample number argument are present in the plugin.
#
#   - 2012-06-13  Kostyantyn Hushchyn
#     Fixed cluster failover perf counter output.
#
#   - 2012-06-22  Kostyantyn Hushchyn
#     Added help message for literal values in interval argument.
#
#   - 2012-06-22  Kostyantyn Hushchyn
#     Added nicknames for intervals(-i argument), which helps to provide correct values in case you can not find them in GUI.
#     Supported values are: r - realtime interval, h<number> - historical interval at position <number>, starting from 0.
#
#   - 2012-07-02  Kostyantyn Hushchyn
#     Reimplemented Datastore checking in Datacenter using different approach(Might fix issue #5712)
#
#   - 2012-07-06  Kostyantyn Hushchyn
#     Fixed Datacenter runtime check Kostyantyn Hushchyn
#
#   - 2012-07-06  Kostyantyn Hushchyn
#     Fixed Datastore checking in Datacenter(Might fix issue #5712)
#
#   - 2012-07-09  Kostyantyn Hushchyn
#     Added help info for Host runtime 'sensor' subcheck
#
#   - 2012-07-09  Kostyantyn Hushchyn
#     Added Host runtime subcheck to threshold sensor data
#
#   - 2012-07-09  Kostyantyn Hushchyn
#     Fixed Host temperature subcheck causing perl interpreter messages output
#
#   - 2012-07-10  Kostyantyn Hushchyn
#     Added listall option to output all available sensors. Sensor name now trieted as regexp, so result will be outputed for the first match.
#
#   - 2012-07-26  Fixed issue which prevents plugin...   v2.8.8 v2.8.8-beta1 Kostyantyn Hushchyn
#     Fixed issue which prevents plugin from executing under EPN(Fixed issue #5796)
#
#   - 2012-09-03  Kostyantyn Hushchyn
#     Implemented plugin timeout(returns 3).
#
#   - 2012-09-05  Kostyantyn Hushchyn
#     Added storage refresh functionality in case when it's present(Fixed issue #5787)
#
#   - 2012-09-21  Kostyantyn Hushchyn
#     Added check for dead pathes, which generates 2 in case when at least one is present(Fixed issue #5811)
#
#   - 2012-09-25  Kostyantyn Hushchyn
#     Changed comparison logic in storage path check
#
#   - 2012-09-26  Kostyantyn Hushchyn
#     Fixed 'Global symbol normalizedPathState requires explicit package name'
#
#   - 2012-10-02  Kostyantyn Hushchyn
#     Changed timeshift argument type to integer, so that non number values will be treated as invalid.
#
#   - 2012-10-02  Kostyantyn Hushchyn
#     Changed to a conditional datastore refresh(Reduce overhead of solution suggested in issue #5787)
#
#   - 2012-10-05  Kostyantyn Hushchyn
#     Updated description so now almost all options are documented, though somewhere should be documented arguments like timeshift(-T),
#     max samples(-M) and interval(-i) (Solve ticket #5950)
#
######################################################################################################################################
#
#   General statement for all changes done by me:
#
#   Nagios, Icinga etc. are tools for
#
#   a) Alarming. That means checking values against thresholds (internal or handed over)
#   b) Collecting performance data. These data, collected with the checks, like network traffic, cpu usage or so should be
#      interpretable without a lot of other data.
#
#   So as a conclusion collecting historic performance data collected by a monitored system should not be done using Nagios,
#   pnp4nagios etc.. It should be interpreted with the appropriate admin tools of the relevant system. For vmware it means use
#   the (web)client for this and not Nagios. Same for performance counters not self explaining.
#
#   Example:
#   Monitoring swapped memory of a vmware guest system seems to makes sense. But on the second look it doesn't because on Nagios
#   you do not have the surrounding conditions in one view like
#   - the number of the running guest systems on the vmware server.
#   - the swap every guest system needs
#   - the total space allocated for all systems
#   - swap/memory usage of the hostcheck_vmware_esx.pl
#   - and a lot more
#
#   So monitoring memory of a host makes sense but the same for the guest via vmtools makes only a limited sense.
#   Martin Fuerstenau
#
######################################################################################################################################
#
# - 31 Jan 2013 M.Fuerstenau version 0.7.1
#   - Replaced most die with a normal if statement and an exit.
#
# - 1 Feb 2013 M.Fuerstenau version 0.7.2
#   - Replaced unless with if. unless was only used eight times in the program. In all other statements we had an if statement
#     with the appropriate negotiation for the statement.
#
# - 5 Feb 2013 M.Fuerstenau version 0.7.3
#   - Replaced all add_perfdata statements with simple concatenated variable $perfdata
#
# - 6 Feb 2013 M.Fuerstenau version 0.7.4
#   - Corrected bug. Name of subroutine was sub check_percantage but this was a typo.
#
# - 7 Feb 2013 M.Fuerstenau version 0.7.5
#   - Replaced $percc and $percw with $crit_is_percent and $warn_versionis_percent. This was just cosmetic for better readability.
#   - Removed check_percentage(). It was replaced by two one liners directly in the code. Easier to read.
#   - The only codeblocks using check_percentage() were the blocks checking warning and critical. But unfortunately the
#     plausability check was not sufficient. Now it is tested that no other values than numbers and the % sign can be
#     submitted. It is also checked that in case of percent the values are in a valid level between 0 and 100
#
# - 12 Feb 2013 M.Fuerstenau version 0.7.8
#   - Replaced literals like CRITICAL with numerical values. Easier to type and anyone developing plugins should be
#     safe with the use
#   - Replaced $state with $actual_state and $res with $state. More for cosmetical issues but the state is returned
#     to Nagios.
#   - check_against_threshold from Nagios::Plugin replaced with a little own subroutine check_against_threshold.
#   - Nagios::Plugin::Functions::max_state replaced with own routine check_state
#
# - 14 Feb 2013 M.Fuerstenau version 0.7.9
#   - Replaced hash %STATUS_TEXT from Nagios::Plugin::Functions with own hash %status2text.
#
# - 15 Feb 2013 M.Fuerstenau version 0.7.10
#   - Own help (print_help()) and usage (print_usage()) function.
#   - Nagios::plugin kicked finally out.
#   - Mo more global variables.
#
# - 25 Feb 2013 M.Fuerstenau version 0.7.11
#   - $quickstats instead of $quickStats for better readability.
#
# - 5 Mar 2013 M.Fuerstenau version 0.7.12
#   - Removed return_cluster_DRS_recommendations() because for daily use this was more of an exotical feature
#   - Removed --quickstats for host_cpu_info and dc_cpu_info because quickstats is not a valid option here.
#
# - 6 Mar 2013 M.Fuerstenau version 0.7.13
#   - Replaced -o listitems with --listitems
#
# - 8 Mar 2013 M.Fuerstenau version 0.7.14
#   - --usedspace replaces -o used. $usedflag has been replaced by $usedflag.
#   - --listvms replaces -o listvm. $outputlist has been replaced by $listvms.
#   - --alertonly replaces -o brief. $briefflag has been replaced by $alertonly.
#   - --blacklistregexp replaces -o blacklistregexp. $blackregexpflag has been replaced by $blacklistregexp.
#   - --isregexp replaces -o regexp. $regexpflag has been replaced by $isregexp.
#
# - 9 Mar 2013 M.Fuerstenau version 0.7.15
#   - Main selection is now transfered to a subroutine main_select because after
#     a successfull if statement the rest can be skipped leaving the subroutine
#     with return
#
# - 19 Mar 2013 M.Fuerstenau version 0.7.16
#   - Reformatted and cleaned up a lot of code. Variable definitions are now at the beginning of each 
#     subroutine instead of defining them "on the fly" as needed with "my". Especially using "my" for
#     definition in a loop is not goog coding style
#
# - 21 Mar 2013 M.Fuerstenau version 0.7.17
#   - --listvms removed as extra switch. Ballooning or swapping VMs will always be listed.
#   - Changed subselect list(vm) to listvm for better readability. listvm was accepted  before (equal to list)
#     but not mentioned in the help. To have list or listvm for the same is a little bit exotic. Fixed this inconsistency.
#
# - 22 Mar 2013 M.Fuerstenau version 0.7.18
#   - Removed timeshift, interval and maxsamples. If needed use original program from op5.
#
# - 25 Mar 2013 M.Fuerstenau version 0.7.19
#   - Removed $defperfargs because no values will be handled over. Only performance check that needed another 
#     another sampling invel was cluster. This is now fix with 3000.
#     
# - 11 Apr 2013 M.Fuerstenau version 0.7.20
#   - Rewritten and cleaned subroutine host_mem_info. Removed $value1 - $value5. Stepwise completion of $output makes
#     this unsophisticated construct obsolete.
#
# - 16 Apr 2013 M.Fuerstenau version 0.7.21
#   - Stripped down vm_cpu_info. Monitoring CPU usage in Mhz makes no sense under normal circumstances
#     Mhz is no valid unit for performance data according to the plugin developer guide. I have never found
#     a reason to monitor wait time or ready time in a normal alerting evironment. This data has some interest
#     for performance analysis. But this can be done better with the vmware tools.
#   - Rewritten and cleaned subroutine vm_mem_info. Removed $value1 - $value5. Stepwise completion of $output makes
#     this unsophisticated construct obsolete.
#
# - 24 Apr 2013 M.Fuerstenau version 0.7.22
#   - Because there is a lot of different performance counters for memory in vmware we ave changed something to be 
#     more specific.
#     - Enhenced explanations in help.
#     - Changed swap to swapUSED in host_mem_info().
#     - Changed usageMB to CONSUMED in host_mem_info(). Same for variables.
#     - Removed overall in host_mem_info(). After reading the documentation carefully the addition of consumed.average + overhead.average
#       seems a little bit senseless because consumed.average includes overhead.average.
#     - Changed usageMB to CONSUMED in vm_mem_info(). Same for variables.
#     - Removed swapIN and swapOUT in vm_mem_info(). Not so sensefull for Nagios alerting because it is hard to find 
#       valid thresholds
#     - Removed swap in vm_mem_info(). From the vmware documentation:
#       "Current amount of guest physical memory swapped out to the virtual machine's swap file by the VMkernel. Swapped 
#        memory stays on disk until the virtual machine needs it. This statistic refers to VMkernel swapping and not
#        to guest OS swapping. swapped = swapin + swapout"
#
#       This is more an issue of performance tuning rather than alerting. It is not swapping inside the virtual machine.
#       it is not possible to do any alerting here because (especially with vmotion) you have no thresholds.
#     - Removed OVERHEAD in vm_mem_info(). From the vmware documentation:
#       "Amount of machine memory used by the VMkernel to run the virtual machine."
#       So using this we have a useless information about a virtual machine because we have no valid context and we 
#       have no valid thresholds. More important is overhead for the host system. And if we are running in problems here
#       we have to look which machine must be moved to another host. 
#     - As a result of this overall in vm_mem_info() makes no sense.
#
# - 25 Apr 2013 M.Fuerstenau version 0.7.23
#   - Removed swap in vm_mem_info(). From vmware documentation:
#     "Amount of guest physical memory that is currently reclaimed from the virtual machine through ballooning.
#      This is the amount of guest physical memory that has been allocated and pinned by the balloon driver."
#     So here we have again data which makes no sense used alone. You need the context for interpreting them
#     and there are no thresholds for alerting.
#
# - 29 Apr 2013 M.Fuerstenau version 0.7.24
#   - Renamed $esx to $esx_server. This is only for cosmetics and better reading of the code.
#   - Reimplmented subselect ready in vm_cpu_info and implemented it new in host_cpu_info.
#     From the vmware documentation:
#     "Percentage of time that the virtual machine was ready, but could not get scheduled
#      to run on the physical CPU. CPU ready time is dependent on the number of virtual
#      machines on the host and their CPU loads."
#     High or growing ready time can be a hint CPU bottlenecks (host and guest system)
#   - Reimplmented subselect wait in vm_cpu_info and implemented it new in host_cpu_info.
#     From the vmware documentation:
#     "CPU time spent in wait state. The wait total includes time spent the CPU Idle, CPU Swap Wait,
#      and CPU I/O Wait states. "
#     High or growing wait time can be a hint I/O bottlenecks (host and guest system)
#
# - 30 Apr 2013 M.Fuerstenau version 0.7.25
#   - Removed subroutines return_dc_performance_values, dc_cpu_info, dc_mem_info, dc_net_info and dc_disk_io_info.
#     Monitored entity was view type HostSystem. This means, that the CPU of the data center server is monitored.
#     The data center server (vcenter) is either a physical MS Windows serversionver (which can be monitored better
#     directly with SNMP and/or NSClient++) or the new Linux based appliance which is a virtual machine and
#     can be monitored as any virtual machine. The OS (Linux) on that virtual machine can be monitored like
#     any standard Linux.
#
# - 5 May 2013 M.Fuerstenau version 0.7.26
#   - Revised the code of dc_list_vm_volumes_info()
#
# - 9 May 2013 M.Fuerstenau version 0.7.27
#   - Revised the code of host_net_info(). The function was devided in two parts (like others):
#     - subselects
#     - else which included all.
#     So most of the code existed twice. One for each subselect and nearly the same for all together.
#     The else block was removed and in case no subselect was defined we defined all as $subselect.
#     With the variable set to all we can decide wether to leave the function after a subselect section
#     has been processed or stay and enhance $output and $perfdata. So the code is more clear and
#     has nearly half the lines of code left.
#   - Removed KBps as unit in performance data. This unit is not specified in the plugin developer 
#     guide. Performance data is now just a number without a unit. Adding the unit has to be done 
#     in the graphing tool (like pnp4nagios).
#   - Removed the number of NICs as performance data. A little bit senseless to have those data here.
#
# - 10 May 2013 M.Fuerstenau version 0.7.27
#   - Revised the code of vm_net_info(). Same changes as for host_net_info() exept the NIC section.
#     This is not available for VMs.
#
# - 14 May 2013 M.Fuerstenau version 0.7.28
#   - Replaced $command and $subselect with $select and $subselect. Therfore also the options --command
#     --subselect changed to --select and --subselect. This has been done to become it more clear.
#     In fact these items where no commands (or subselects). It were selections from the amount of
#     performance counters available in vmware.
#
# - 15 May 2013 M.Fuerstenau version 0.7.29
#   - Kicked out all (I hope so) code for processing historic data from generic_performance_values().
#     generic_performance_values() is called by return_host_performance_values(), return_host_vmware_performance_values()
#     and return_cluster_performance_values() (return_cluster_performance_values() must be rewritten now).
#     The code length of generic_performance_values() was reduced to one third by doing this.
#
# - 6 Jun 2013 M.Fuerstenau version 0.7.30
#   - Substituted commandline option for select -l with -S. Therefore -S can't be used as option for the sessionfile
#     Only --sessionfile is accepted nor the name of the sessionfile.
#   - Corrected some bugs in check_against_threshold()
#   - Ensured that in case of thresholds critical must be greater than warning.
#
# - 11 Jun 2013 M.Fuerstenau version 0.7.31
#   - Changed select option for datastore from vmfs to volumes because we will have volumes on nfs AND vmfs on local or
#     SAN disks. 
#   - Changed output for datastore check to use the option --multiline. This will add a \n (unset -> default) for 
#     every line of output. If set it will use HTML tag <br>.
#
#     The option --multiline sets a <br> tag instead of \n. This must be filtered out
#     before using the output in notifications like an email. sed will do the job:
#
#     sed 's/<[Bb][Rr]>/&\n/g' | sed 's/<[^<>]*>//g'
#
#     Example:
#
#    # 'notify-by-email' command definition
#    define command{
#    	command_name	notify-by-email
#    	command_line	/usr/bin/printf "%b" "Message from Nagios:\n\nNotification Type: $NOTIFICATIONTYPE$\n\nService: $SERVICEDESC$\nHost: $HOSTNAME$\nHostalias: $HOSTALIAS$\nAddress: $HOSTADDRESS$\nState: $SERVICESTATE$\n\nDate/Time: $SHORTDATETIME$\n\nAdditional Info:\n\n$SERVICEOUTPUT$\n$LONGSERVICEOUTPUT$" | sed 's/<[Bb][Rr]>/&\n/g' | sed 's/<[^<>]*>//g' | /bin/mail -s "** $NOTIFICATIONTYPE$ alert - $HOSTNAME$/$SERVICEDESC$ is $SERVICESTATE$ **" $CONTACTEMAIL$
#    	}
#
# - 13 Jun 2013 M.Fuerstenau version 0.7.32
#   - Replaced a previous change because it was wrong done:
#     - --listvms replaced by subselect listvms
#
# - 14 Jun 2013 M.Fuerstenau version 0.7.33
#   - Some minor corrections like a doubled chop() in datastore_volumes_info()
#   - Added volume type to datastore_volumes_info(). So you can see whether the volume is vmfs (local or SAN) or NFS.
#   - variables like $subselect or $blacklist are global there is no need to handle them over to subroutines like
#     ($result, $output) = vm_cpu_info($vmname, local_uc($subselect)) . For $subselect we have now one uppercase
#     (around line 580) instead of having one with each call in the main selection.
#   - Later on I renamed local_uc to local_lc because I recognized that in cases the subselect is a volume name
#     upper cases won't work.
#   - replaced last -o $addopts (only for the name of a sensor) with --sensorname
#
# - 18 Jun 2013 M.Fuerstenau version 0.7.34
#   - Rewritten and cleaned subroutine host_disk_io_info(). Removed $value1 - $value7. Stepwise completion of $output makes
#     this unsophisticated construct obsolete.
#   - Removed use of performance thresholds in performance data when used disk io without subselect because threshold
#     can only be used for one item not for all. Therefore they weren't checked in that section. Senseless.
#   - Changed the output. Opposite to vm_disk_io_info() most values in host_disk_io_info() are not transfer rates
#     but latency in milliseconds. The output is now clearly understandable.
#   - Added subselect read. Average number of kilobytes read from the disk each second. Rate at which data is read
#     from each LUN on the host.read rate = # blocksRead per second x blockSize.
#   - Added subselect write. Average number of kilobytes written to disk each second. Rate at which data is written
#     to each LUN on the host.write rate = # blocksRead per second x blockSize
#   - Added subselect usage. Aggregated disk I/O rate. For hosts, this metric versionincludes the rates for all virtual
#     machines running on the host.
#
# - 21 Jun 2013 M.Fuerstenau version 0.7.35
#   - Rewritten and cleaned subroutine vm_disk_io_info(). Removed $value1 - $valuen. Stepwise completion of $output makes
#     this unsophisticated construct obsolete.
#   - Removed use of performance thresholds in performance data when used disk io without subselect because threshold
#     can only be used for on item not for all. Therefore they weren't checked in that section. Senseless.
#
# - 24 Jun 2013 M.Fuerstenau version 0.7.36
#   - Changed all .= (for example $output .= $xxx.....) to = $var... (for example $output = $output . $xxx...). .= is shorter
#     but the longer form of notification is better readable. The probability of overlooking the dot (especially for older eyes
#     like mine) is smaller. 
#
# - 07 Aug 2013 M.Fuerstenau version 0.8.0
#   - Changed "eval { require VMware::VIRuntime };" to "use VMware::VIRuntime;".  The eval construct 
#     made no sense. If the module isn't available the program will crash with a compile error.
#
#   - Removed own subroutine format_uptime() only used by host_uptime_info(). The complete work of this function
#     was done converting seconds to days, hours etc.. Instead of the we use the perl module Time::Duration.
#     So instead of
#        $output = "uptime=" . format_uptime($value);
#     we simply use
#        $output =  "uptime=" . duration_exact($value);
#
#   - Removed perfdata from host_uptime_info(). Perfdata for uptime seems senseless. Same for threshold.
#   - Started modularization of the plugin. The reason is that it is much more easier to 
#     patch modules than to patch a large file.
#   - Variables used in that functions which are defined on the top level
#     with "my" must now be defined with "our".
#
#     BEWARE! Using "our" with unknown modules can lead to curious results if
#     in this functions are variables with the same name. But in this 
#     case it is no risk because the modules are not generic. We have only
#     broken the plugin in handy pieces.
#
#   - Made an seperate modules:
#     - help.pm -> print_help()
#     - process_perfdata.pm  -> get_key_metrices()
#                            -> generic_performance_values()
#                            -> return_host_performance_values()
#                            -> return_host_vmware_performance_values()
#                            -> return_cluster_performance_values()
#                            -> return_host_temporary_vc_4_1_network_performance_values()
#     - host_cpu_info.pm -> host_cpu_info()
#     - host_mem_info.pm -> host_mem_info()
#     - host_net_info.pm -> host_net_info()
#     - host_disk_io_info.pm -> host_disk_io_info()
#     - datastore_volumes_info.pm -> datastore_volumes_info()
#     - host_list_vm_volumes_info.pm -> host_list_vm_volumes_info()
#     - host_runtime_info.pm -> host_runtime_info()
#     - host_service_info.pm -> host_service_info()
#     - host_storage_info.pm -> host_storage_info()
#     - host_uptime_info.pm -> host_uptime_info()
#
# - 13 Aug 2013 M.Fuerstenau version 0.8.1
#   - Moved host_device_info to host_mounted_media_info. Opposite to it's name
#     and the description this function wasn't designed to list all devices
#     on a host. It was designed to show host cds/dvds mounted to one or more
#     virtual machines. This is important for monitoring because a virtual machine
#     with a mount cd or dvd drive can not be moved to another host.
#   - Made an seperate modules:
#     - host_mounted_media_info.pm -> host_mounted_media_info()
#
# - 19 Aug 2013 M.Fuerstenau version 0.8.2
#   - Added SOAP check from Simon Meggle, Consol. Slightly modified to fit.
#   - Added isblacklisted and isnotwhitelisted from Simon Meggle, Consol. . Same as above.
#     Following subroutines or modules are affected:
#     - datastore_volumes_info.pm
#     - host_runtime_info.pm
#   - Enhanced host_mounted_media_info.pm
#     - Added check for host floppy
#     - Added isblacklisted and isnotwhitelisted
#     - Added $multiline
#
# - 21 Aug 2013 M.Fuerstenau version 0.8.3
#   - Reformatted and cleaned up host_runtime_info().
#   - A lot of bugs in it.
#
# - 17 Aug 2013 M.Fuerstenau version 0.8.4
#   - Minor bug fix.
#     - $subselect was always converted to lower case characters.
#       This is correct exect $subselect contains a name (e.g. volumes). Volume names
#       can contain upper and lower letters. Fixed.
#     - datastore_volumes_info.pm had  my ($datastore, $subselect) = @_; as second line
#       This was incorrect because "global" variables (defined as our in the main program)
#       are not handled over via function call. (Yes - may be handling over maybe more ok 
#       in the sense of structured programming. But really - does handling over and giving back 
#       a variable makes the code so much clearer? More a kind of philosophy :-)) )
#
# - 27 Oct 2013 M.Fuerstenau version 0.8.5
#   - Made an seperate modules:
#     - vm_cpu_info.pm -> vm_cpu_info()
#     - vm_mem_info.pm -> vm_mem_info()
#     - dc_list_vm_volumes_info.pm -> dc_list_vm_volumes_info()
#     - vm_net_info.pm -> vm_net_info()
#     - vm_disk_io_info.pm -> vm_disk_io_info()
#
# - 31 Oct 2013 M.Fuerstenau version 0.8.9
#   - Readded -V|--version to display the version number.
#
# - 01 Nov 2013 M.Fuerstenau version 0.8.10
#   - removed return_host_temporary_vc_4_1_network_performance_values() from
#     process_perfdata.pm. Not needed in ESX version 5 and above.
#     Affected subroutine:
#     host_net_info().
#   - Bug fixed in generic_performance_values(). Unfortunaltely I had moved
#     my @values = () to main function. Therefore instead of containing a 
#     new array reference with each run the new references were added to the array
#     but only the first one was processed. Thanks to Timo Weber for discovering this bug.
#
# - 20 Nov 2013 M.Fuerstenau version 0.8.11
#   - check_state(). Bugfix. Logical error. Complete rewrite.
#   - host_net_info()
#     - Minor bugfix. Added exit 2 in case of unallowed thresholds
#     - Simplified the output. Instead of doing it for every subselect (or not
#       if subselect=all for selecting all info) we have a new helper variable
#       called $true_sub_sel.
#       0 means not a true subselect.
#       1 means a true subselect (including all)
#   - host_runtime_info().
#     - Filtered out the sensor type "software components". Makes no sense for alerting.
#     - The complete else tree (no subselect) was scrap due to the fact that the return code
#       was always ok. There would never be any alarm. Kicked out.
#     - The else tree was replaced by a $subselect=all as in host_net_info().
#     - Same for output.
#     - subselect listvms.
#       - The (OK) in the output was a hardcoded. Replaced by the deliverd value (UP). (in my oipinion senseless)
#       - Removed perfdata. The number of virtual machines as perfdata doesn't
#         make so much sense.
#     - Rearranged the order of subselects. Must be the same as the statements
#       in the kicked out else sequence to get the same order in output
#     - connection state.
#
#       From the docs:
#       connected      Connected to the server. For ESX Server, this is always
#                      the setting.
#       disconnected   The user has explicitly taken the host down. VirtualCenter
#                      does not expect to receive heartbeats from the host. The
#                      next time a heartbeat is received, the host is moved to
#                      the connected state again and an event is logged.
#       notResponding  VirtualCenter is not receiving heartbeats from the server
#                    . The state automatically changes to connected once
#                      heartbeats are received again. This state is typically
#                      used to trigger an alarm on the host. 
#
#       In the past the presset of returncode was 2. It was set to 0 in case of a
#       connected. But disconnected doesn' mean a critical error. It means main-
#       tenance or somesting like that. Therefore we now return a 1 for warning.
#       notResonding will cause a 2 for critical.
#     - Kicked out maintenance info in runtime summary and as subselect. In the beginning of
#       the function is a check for maintenance. In the original program in this case
#       the program will be left with a die which caused a red alert in Nagios. Now an info 
#       is displayed and a return code of 1 (warning) is deliverd because a maintenance is
#       regular work. Although monitoring should take notice of it. Therefore a warning.
#       Therefor the maintenence check in the else tree was scrap. It was never reached.
#     - listvms
#       In case of no VMs the plugin returned a critical. But this is not correct. No VMs
#       on a host is not an error. It is simply what it says: No VMs.
#     - Replaced --listitems and --listall with --listsensors because there were two options
#       for the same use.
#     - Later on I decided to kick out the complete sensorname construction. To monitor a seperate sensor
#       by name (a string which ist different for each sensor) seems not to make so much sense. To monitor
#       sensors by type gave no usefull information (exept temperature which is still monitored. All usefull
#       informations are in the health section. Better to implement some out here if needed.
#       renamed -s temperature to -s temp (because I am lazy).
#     - Changed output of --listsensors. | is the seperation symbol for performance data. So it should not be
#       used in output strings.
#     - Same for the error output of sensors in case of a problem.
#     - subselect=health. Filter out sensors which have not valid data. Often a sensor is
#       reckognizedby vmware but has not the ability to report something senseful. In this
#       case an unknown is reported and the message "Cannot report on the current health state of
#       the element". This it can be skipped.
#   - Bugfix for vm_net_info(). It worked perfectly for -H but produced bullshit with the -D option.
#     With -D in PerfQuerySpec->new(...) intervalId and maxSample must be set. Default was 20 for intervalId
#     and 1 for maxSample
#   - datastore_volumes_info()
#     - New option --gigabyte
#     - Fixed bug for treating name as regexp (--isregexp).
#     - Fixed bug in perfdata (%:MB). Is now MB or GB.
#     - If no single volume is selected warning/critical threshold can be given
#       only in percent.
#   - Fixed bug in regexp for blacklists and whitelists and replace --blacklistregexp and --whitelistregexp with
#     --isregexp. Used in
#       - host_mounted_media_info()
#       - datastore_volumes_info()
#       - host_runtime_info()
#     All subroutines revised later will include it automatically
#   - Fixed bug in regexp for blacklists and whitelists and replace --blacklistregexp and --whitelistregexp with
#   - Opposite to the op5 original blacklists and whitelists can now contain true reular expressions.
#   - help.pm rewritten. It was too much output. Now the user has several choices:
#     -h|--help=<all>                    The complete help for all.
#     -h|--help=<dc|datacenter|vcenter>  Help for datacenter/vcenter checks.
#     -h|--help=<host>                   Help for vmware host checks.
#     -h|--help=<vm>                     Help for virtual machines checks.
#     -h|--help=<cluster>                Help for cluster checks.
#   - host_service_info() rewritten.
#     - No longer a list of services via subselect.
#     - Instead full blacklist/whitelist support
#     - With --isregexp blacklist/whitelist items are interpreted as regular expressions
#   - Changed switch of blacklist from -x to -B
#   - Changed switch of whitelist from -y to -W
#   - main_select(). Something for the scatterbrained of us. Replaced string compare (eq,ne etc.) with
#     a regexp pattern matching. So it is possible to type in services or Services instead of service.
#
# - 29 Nov 2013 M.Fuerstenau version 0.8.13
#   - In all functions checking host for maintenance we had the following contruction:
#
#     if (uc($host_view->get_property('runtime.inMaintenanceMode')) eq "TRUE")
#
#     This is quite stupid. runtime.inMaintenanceMode is xsd:boolean wich means true or false (in 
#     lower cas letters. So a uc() make no sense. Removed
#
#   - Bypass SSL certificate validation - thanks Robert Karliczek for the hint
#   - Added --sslport if any port other port than 443 is wanted. 443 is used as default.
#   - Rewritten authorization part. Sessionfiles are working now.
#   - Updated README.
#
# - 03 Dec 2013 M.Fuerstenau version 0.8.14
#   - host_runtime_info()
#     - Fixed minor bug. In case of an unknown with sensors the unknown was always mapped to
#       a warning. This wasn't sensefull under all circumstances. Now it is only mapped to warning
#       if --ignoreunknow is not set.
#   - README
#     - Updated installation notes
#   - Optional pathname for sessionfile
#
# - 10 Dec 2013 M.Fuerstenau version 0.8.15
#   - datastore_volumes_info()
#     - Changed "For all volumes" to "For all selected volumes". This should fit all. The subroutine datastore_volumes_info
#       is called from several subroutines and to make a difference here for a single volume or more volumes will cause
#       a lot of unnecessary work just for cosmetics.
#     - Fixed typo in error message.
#     - Modified error messages
#   - Removed plausibility check whether critical must be greater than warning. In case of freespace for example it must
#     be the other way round. The plausibility check was nice but too complicated for all the different conditions.
#   - check_against_threshold() - Cleaned up and partially rewritten.
#
# - 12 Dec 2013 M.Fuerstenau version 0.8.16
#   - datastore_volumes_info()
#     - Some small fixes
#       - Changed the output for OK from  "For all selected volumes" to "OK for all seleted volumes."
#       -  Same for error plus an error counter for the alarms
#     - Parameter usedspace was ignored on volume checks because a local variable defined with my instead of a more global
#       one. Changed it from my to our fixed it. Thanks to dgoetz for reporting (and fixing) this.
#     - Capacity is now displayed and deliverd as perfdata
#   - Main selection - GetOptions. Unce upon a time I had kicked out $timeout unintended. Fixed now. Thanks to 
#     Andreas Daubner for the hint.
#
# - 12 Dec 2013 M.Fuerstenau version 0.8.17
#   - host_net_info()
#     - Changed output
#     - Added total number of NICs
#
# - 13 Dec 2013 M.Fuerstenau version 0.8.18
#   - host_mounted_media()
#     - Delivers now a warning instead of a critical
#
# - 25 Dec 2013 M.Fuerstenau version 0.9.0
#   - help()
#     - Removed -v/--verbose. The code was not debugging the plugin but not for working with it.
#   - host_storage_info()
#     - Removed optional switch for adaptermodel. Displaying the adapter model is default now.
#     - Removed upper case conversion for status. The status was converted (for examplele online to ONLINE) and
#       compared with a upper case string like "ONLINE". Sensefull like a second asshole.
#     - Added working blacklist/whitelist.
#       - Blacklist: blacklisted adapters will not be displayed.
#       - Whitelist: only whitelisted adapters will be displayed.
#     - Removed perfdata for the number of hostbusadapters. These perfdata was absolutely senseless.     
#     - Status for hostbusadapters was not checked correctly. The check was only done for online and unknown but NOT(!!)
#       for offline and unbound.
#     - LUN states were not correct. UNKNOWN is not a valid state. Not all states different from unknown are 
#       supposed to be critical. From the docs:
#
#       degraded             One or more paths to the LUN are down, but I/O is still possible. Further
#                            path failures may result in lost connectivity.
#       error                The LUN is dead and/or not reachable.
#       lostCommunication    No more paths are available to the LUN.
#       off                  The LUN is off.
#       ok                   The LUN is on and available.
#       quiesced             The LUN is inactive.
#       timeout              All Paths have been down for the timeout condition determined by a
#                            user-configurable host advanced option.
#       unknownState         The LUN state is unknown.
#
#     - Removed number of LUNs as perfdata. Senseless (again).
#     - In the original selection for the displayed LUN the displayName was used first, then the deviceName and
#       the last one was the canonical name. Unfortunately in the GUI SCSI ID, canonical name an runtime name is
#       displayed. So using the freely configurable DisplayName is senseless. The device name is formed from the
#       path (/vmfs/devices/disks/) followed by the canonical name. So it is either senseless.
#     - The real numeric LUN number wasn'nt display. Fixed. Output is now LUN, canonical name, everything from
#       the display name not equal canonical name and status.  
#     - Complete rewrite of the paths part. Only the state of the multipath was checked but not the state of the
#       paths. So a multipath can be "Active" which is ok but the second line is dead. So if the active path becomes
#       dead the failover won't work.There must be an alarm for a standby path too. It is now grouped in the output.
#     - Multiline support for this.
#
# - 03 Jan 2014 M.Fuerstenau version 0.9.1
#   - check_vmware_esx.pl
#     Added new flag --ignore_warning. This will map a warning to ok.
#   - host_runtime_info() - some minor changes
#     - Changed state to powerstate. In the original version the power state was mapped:
#       poweredOn => UP
#       poweredOff => DOWN
#       suspended => SUSPENDED
#       This suggested a machine state but it is only a powerstate. All other than UP caused a critical. But this is 
#       not true. A power off machine can also be ok. But to be sure that it is noticed we will have a warning for
#       powerd off and suspended
#     - Perfdata changed.
#       - vm_up -> vm_powerdon
#       - New: vm_poweroff
#       - New: vm_suspended
#   - vm_runtime_info() -> vm_runtime_info.pm
#     - Removed a lot of unnecessary variables and hashes. Rewritten a lot.
#     - Connection state. Only "connected" was checked. All other caused a critical error without a usefull message.
#       This wa a little bit incomplete. Corrected. States delivered from VMware are connected, disconnected,
#       inaccessible, invalid and orphaned.
#     - Removed cpu. VirtualMachineRuntimeInfo maxCpuUsage (in Mhz) doesn't make so much sense for monitoring/alerting.
#       See VMware docs for further information for this performance counter.
#     - Removed mem. VirtualMachineRuntimeInfo maxMemoryUsage doesn't make so much sense for monitoring/alerting.
#       See VMware docs for further information for this performance counter.
#     - Changed state to powerstate. In the original version the power state was mapped:
#       poweredOn => UP
#       poweredOff => DOWN
#       suspended => SUSPENDED
#       This suggested a machine state but it is only a powerstate. All other than UP caused a critical. But this is 
#       not true. A power off machine can also be ok. But to be sure that it is noticed we will have a warning for
#       powerd off and suspended
#     - Changed guest to gueststate. This is more descriptive.
#       Removed mapping in guest state. Mapping was "running" => "Running", "notrunning" => "Not running",
#       "shuttingdown" => "Shutting down", "resetting" => "Resetting", "standby" => "Standby", "unknown" => "Unknown".
#       This was not necessary from a technical point of view. The original messages are clearly understandable.
#     - The guest states were not interpreted correctly. In check_vmware_api.pl all states different from running
#       caused a "Critical" error. But this is nonsense. A planned shutted down machine is not an error. It's daily
#       business. But the operator should probably have a notice of that. So it causing a "Warning".
#
#       The states are (from the docs):
#       running      -> Guest is running normally. (returns 0)
#       shuttingdown -> Guest has a pending shutdown command. (returns 1)
#       resetting    -> Guest has a pending reset command. (returns 1)
#       standby      -> Guest has a pending standby command. (returns 1)
#       notrunning   -> Guest is not running. (returns 1)
#       unknown      -> Guest information is not available. (returns 3)
#
#     - Rewritten subselect tools. VirtualMachineToolsStatus was deprecated. As of vSphere API 4.0
#       VirtualMachineToolsVersionStatus and VirtualMachineToolsRunningStatus
#       has to be used. So a great part of this subselect was not working.
#   - vm_disk_io_info()
#     - Minor bug in output and perfdata corrected. I/O is not in MB but in MB/s. Some
#       of the counters were in MB.
#     - Corrected help. The original on was nonsense.
#     - Changed all values to KB/s because so it is equal to host disk I/O and so it
#       it is deleverd from the API.
#   - help()
#     - Some small bug fixes.
#   - host_disk_io_info()
#     - added total_latency.
#
# - 08 Jan 2014 M.Fuerstenau version 0.9.2
#   - help()
#     - Some small bug fixes.
#   - vm_disk_io_info()
#     - Removed duplicated code. (if subselect ..... else ....)
#       The code was 90% identical.
#   - host_disk_io_info()
#     - Removed duplicated code. (if subselect ..... else ....)
#       The code was 90% identical.
#     - Bug fix. Usage was given without subselect but missing as subselect. Not
#       detected earlier due to the duplicate code.
#   - host_cpu_info()
#     - Removed duplicated code. (if subselect ..... else ....)
#       The code was 90% identical.
#     - Added usage as subselect.
#   - vm_cpu_info()
#     - Removed duplicated code. (if subselect ..... else ....)
#       The code was 90% identical.
#     - Added usage as subselect.
#   - host_mem_info()
#     - Removed duplicated code. (if subselect ..... else ....)
#       The code was 90% identical.
#     - swapused
#       - I swapused is a subselect there should be enhanced information about
#         the virtual machines and should be available. If this won't work
#         nothing will happen. In the past this caused a critical error which
#         is nonsense here.
#      - memctl
#        - Same as swapused
#   - vm_mem_info()
#     - Removed duplicated code. (if subselect ..... else ....)
#       The code was 90% identical.
#     - Added vmmemctl.average (memctl) to monitor balloning.
#
# - 16 Jan 2014 M.Fuerstenau version 0.9.3
#   - All modules
#     - Corrected typo at the end. common instead of commen
#   - host_storage_info()
#     - Removed ignored counter for whitelisted items. A typical copy and paste
#       b...shit.
#   - vm_runtime_info()
#     - issues
#       - Some bugs with the output. Corrected.
#     - tools
#       - Minor bug fixed. Previously used variable was not removed.
#   - host_runtime_info()
#     - issues.
#       - Some bugs with the output. Corrected.
#     - listvms
#       - output now sorted by powerstate (suspended, poweredoff, powerdon)
#     - Corrected some minor bugs
#   - dc_list_vm_volumes_info()
#     - Removed handing over of unnecessary parameters
#   - dc_runtime_info() -> dc_runtime_info.pm
#     - Code cleaned up and reformated
#     - listvms
#       - output now sorted by powerstate (suspended, poweredoff, powerdon)
#       - Added working blacklist/whitelist with the ability to use regular
#         expressions
#       - Added --alertonly here
#       - Added --multiline here
#     - listhosts
#       - %host_state_strings was mostly nonsense. The mapped poser states from
#         for virtual machines were used. Hash removed. Using now the orginal 
#         power states from the system (from the docs):
#         - poweredOff -> The host was specifically powered off by the user
#                         through VirtualCenter. This state is not a certain
#                         state, because after VirtualCenter issues the command
#                         to power off the host, the host might crash, or kill
#                         all the processes but fail to power off.
#         - poweredOn  -> The host is powered on
#         - standBy    -> The host was specifically put in standby mode, either
#                         explicitly by the user, or automatically by DPM. This
#                         state is not a cetain state, because after VirtualCenter
#                         issues the command to put the host in stand-by state,
#                         the host might crash, or kill all the processes but fail
#                         to power off.
#         - unknown    -> If the host is disconnected, or notResponding, we can
#                         not possibly have knowledge of its power state. Hence,
#                         the host is marked as unknown. 
#       - Added working blacklist/whitelist with the ability to use regular
#         expressions
#       - Added --alertonly here
#       - Added --multiline here
#     - listcluster
#       - Removed senseless perf data
#       - More detailed check than before
#       - Added working blacklist/whitelist with the ability to use regular
#         expressions
#       - Added --alertonly here
#       - Added --multiline here
#     - status
#       - Rewritten and reformatted
#     - tools
#       - Rewritten and reformatted
#       - Improved more detailed output.
#         expressions
#       - Added --alertonly here
#       - Added --multiline here
#
# - 24 Jan 2014 M.Fuerstenau version 0.9.4
#   - Merged pull request from Sven Nierlein
#     - Modified hel to work with Thruk
#     - Added Makefile. This is optional. Calling it generates a single file
#       from all the modules. Maybe it is a little bit slower than the modules.
#       The readon for modules was speed and better maintenance.
#   - host_runtime_info()
#     - Added quotes in perfdata for temp.
#   - Enhanced README. Explained the differences un host_storage_info() between
#     the original one and this one
#   - host_net_info()
#     - Minor bugfix in output. Corrected typo.
#
# - 29 Jan 2014 M.Fuerstenau version 0.9.5
#   - host_runtime_info()
#     - Minor bug. Corrected quotes in perfdata for temp.
#   - vm_net_info()
#     - Quotes in perfdata
#     - Removed VM name from output
#   - vm_mem_info()
#     - Quotes in perfdata
#   - vm_disk_io_info()
#     - Quotes in perfdata
#   - vm_cpu_info()
#     - Quotes in perfdata
#   - host_net_info()
#     - Quotes in perfdata
#   - host_mem_info()
#     - Quotes in perfdata
#   - host_disk_io_info()
#     - Quotes in perfdata
#   - host_cpu_info()
#     - Quotes in perfdata
#   - dc_runtime_info()
#     - Quotes in perfdata
#   - datastore_volumes_info()
#     - Quotes in perfdata
#
# - 04 Feb 2014 M.Fuerstenau version 0.9.6
#   - host_storage_info()
#     - New switch --standbyok for storage systems where a standby multipath is ok
#       and not a warning
#
# - 06 Feb 2014 M.Fuerstenau version 0.9.7
#   - Bugfixes/Enhancements
#     - In some cases it might happen that no performance counters are delivered
#       by VMware. Especially if the version is old (4.x, 3.x). Under these
#       circumstances an undef was returned by the routines from process_perfdata.pm
#       and not handled correctly in the calling subroutines. Fixed.
#       Affected subroutines:
#       - host_cpu_info()
#       - vm_net_info()
#       - vm_mem_info()
#       - vm_net_info()
#       - vm_disk_io_info()
#       - vm_cpu_info()
#       - host_net_info()
#       - host_mem_info()
#       - host_disk_io_info()
#   - vm_net_info()
#     - Rewritten to the same structure as similar modules
#   - host_net_info()
#     - Rewritten to the same structure as similar modules
#
# - 24 Feb 2014 M.Fuerstenau version 0.9.8
#   - Corrected a type in the help()
#   - Moved the block for constructing the full path of the sessionfile downward to the authentication
#     stuff to have all in one place.
#   - Authentication:
#     - To reduce amounts of login/logout events in the vShpere logfiles or a lot of open sessions using
#       sessionfiles the login part has been rewritten. Using session files is now the default. Only one
#       session file per host or vCenter is used as default
#
#       The sessionfile name is automatically set to the vSphere host or the vCenter (IP or name - whatever
#       is used in the check).
#
#       Multiple sessions are possible using different session file names. To form different session file
#       names the default name is enhenced by the value you set with --sessionfile.
#
#       NOTICE! All checks using the same session are serialized. So a lot of checks using only one session
#       can cause timeouts. In this case you should enhence the number of sessions by using --sessionfile
#       in the command definition and define the value in the service definition command as an extra argument
#       so it can be used in the command definition as $ARGn$.
#     - --sessionfile is now optional and only used to enhance the sessionfile name to have multiple sessions.
#     - If a session logs in it sets a lock file (sessionfilename_locked).
#     - The lock file is been set when the session starts and removed at the end of the plugin run.
#     - A newly started check looks for the lock file and waits until it is no longer there. So here we
#       have a serialization now. It will not hang forever due to the alarm routine.
#     - Fixed bug "Can't call method "unset_logout_on_disconnect"". I mixed object orientated code and classical
#       code. (Thanks copy & paste for this bug)
#   - $timeout set to 40 seconds instead of 30 to have a little longer waiting before automatic cancelling
#     the check to prevent unwanted cancelling due to longer waiting caused by serialization.
#
# - 25 Feb 2014 M.Fuerstenau version 0.9.9
#   - Bugfix and improvement for "lost" lock files. In case of a Nagios reload (or kill -HUP) Nagios is restarted with the
#     same PID as before. Unfortunately Nagios sends a SIGINT or SIGTERM to the plugins. This causes the plugin
#     to terminate without removing the lockfile.
#     - So we have to catch several signals now
#       - SIGINT and SIGTERM. One of this will be send from Nagios 
#       - SIGALRM. Caused by alarm(). Now with output usable in Nagios.
#     - Instead of generating an empty file as lock file we write the process identifier of the running plugin
#       process into the lock file. If a session crashes for some reason an a lock file is left we are in a 
#       situation where signal processing won't help. But here the next run of the plugin reads the PID and checks
#       for the process. If there is no process anymore it will remove the lock file and create a new one.
#       Thanks to Simon Meggle, Consol, for the idea.
#   - Removed "die" for opening the authfile or the session lock file with an unless construct. The plugin will
#     report an "understandable" message to the monitor instead of causing an internal error code.
#   - vm_cpu_info() and host_cpu_info()
#     - Removed threshold for ready and wait. Therefore thresholds are no possible 
#       without subselect.
#
# - 26 Feb 2014 M.Fuerstenau version 0.9.10
#   - Bugfixes.
#     - Corrected typo in dc_runtime_info() line 660.
#     - Corrected typo in help().
#     - Corrected bug in datastore_volumes_info(). Giving absolute thresholds
#       for a single volume was not possible. Fixed.
#   - Removed print_usage(). Due to mass of parameters it is not possible to display
#     a short usage message. Instead of that the output of the help is included
#     in the package as a file.
#   - Updated default timeout to 90 secs. to avoid timeouts.
#   - Before accessing the session file (and lock file) we have a random sleep up
#     7 secs.. This is to avoid a concurrent access in case of a monitor restart
#     or a "Schedule a check of all services on this host"
#   - In case of a locked session file the wait loop is not fix to 1 sec any more.
#     Instead of this it uses a random period up to 5 sec.. So we minimize the risc
#     of concurrent access.
#
# - 7 Mar 2014 M.Fuerstenau version 0.9.11
#   - Updated README
#     - Section for removing HTML tags was reworked
#   - Added blacklist to host_net_info() so that interfaces with -S net can
#     be blacklisted.
#
# - 11 Mar 2014 M.Fuerstenau version 0.9.12
#   - Changed sleep() to usleep() and using now microseconds instead of seconds
#   - So before accessing the session file (and lock file) we now have a random sleep
#     up to 1500 milliseconds (default - see $ms_ts). This is to avoid a concurrent access
#     in case of a monitor restart or a "Schedule a check of all services on this host"
#     but takes much less time while having much more alternatives.
#   - In case of a locked session file the wait loop is not fix to a random period up to
#     5 sec. any more. Instead of this it uses also $ms_ts which means a max of 1.5 secs.
#     instead of 5.
#
# - 3 Apr 2014 M.Fuerstenau version 0.9.13
#   - --trace=<tracelevel> was not working. Fixed. Small typo.
#   - Removed comment sign in front of unlink around. It was there due to some
#     some tests and I had forgotten to remove it.
#   - datastore_volumes_info(). Some bugs corrected.
#     - Wrong percent calculation
#     - Wrong processing of thresholds for usedspace
#     - Wrong processing for thresholds which are not percent
#     - If threshold is in percent it is calculated in MB/GB for perfdata
#       because mixing percent and MB/GB doesn't make sense.
#
# - 5 Apr 2014 M.Fuerstenau version 0.9.14
#   - host_runtime_info()
#     - Fixed some bugs with issues ignored and whitelist. Some counters were calculated
#       wrong
#
# - 29 Apr 2014 M.Fuerstenau version 0.9.15
#   - host_mem_info(), vm_mem_info(), host_cpu_info() and vm_cpu_info().
#     - Sometimes it may happen on Vmware 5.5 (not seen when testing with Update 1) that getting
#       the perfdata for cpu and/or memory will result in an empty construct because one
#       or more values are not delivered. In this case we have a fallback and and every value
#   - dc_runtime_info()
#     - New option --poweredonly to list only machines which are powered on
#
# - 20 May 2014 M.Fuerstenau version 0.9.16
#   - New option --nosession.
#     - This was implemented for 2 reasons.
#       - First when testing from the commandline using this switch to avoid
#         waiting and timeouts while the monitor system is checking the the same host.
#         This is the important reason.
#       - Second is that some people don't like sessionfiles and prefer full logs as
#         it was in the past. Good ol' times.
#   - host_runtime_info()
#     - added --nostoragestatus to -S runtime -s health to avoid a double alarm
#       when also doing a check with -S runtime -s storagehealth for the same
#       host.
#   - dc_runtime_info()
#     - changed 
#       if (($subselect eq "listcluster") || ($subselect eq "all"))
#       to
#       if (($subselect =~ m/listcluster.*$/) || ($subselect eq "all"))
#       This is to avoid unnecessary typos because it covers listcluster and listclusters ;-)
#   - datastore_volumes_info()
#     -  Heavily reworked lot of the logical structure. There were too much changes
#        changes after changes which lead to bugs. Now it is cleaned up.
#   - cluster_list_vm_volumes_info()
#     - Seperate module now
#   - cluster_cpu_info()
#     - Seperate module now but still not working.
#
# - 1 Jul 2014 M.Fuerstenau version 0.9.16a
#   - Unfortunately published some modules containing debugging outpu. Fixed.
#     - host_disk_io_info.pm
#     - process_perfdata.pm
#     - vm_disk_io_info.pm
#
# - 20 Jul 2014 M.Fuerstenau version 0.9.17
#   - Removing the last multiline character (\n or <br>) was moved
#     from several subroutines to the main exit in check_vmware_esx.pl. 
#     This was based this was implemented based on a proposal of Dietmar Eberth
#     Affected subroutines:
#     - vm_runtime_info()
#     - host_storage_info()
#     - host_runtime_info()
#     - dc_runtime_info()
#     -datastore_volumes_info()
#   - Fixed a bug on line 139 and 172. Thanks for fixing it to Dietmar Eberth.
#     - Instead of 
#     
#       if ( $state >= 0 )
#          {
#          $alertcnt++;
#          }
#         
#       it must be:
#
#       if ( $alertcnt > 0 )
#          {
#          $alertcnt++;
#          }
#
#   - Fixed a bug on line 139 and 172. Thanks for fixing it to Dietmar Eberth.
#   - If only one volume is selected we have a better output now. Also thanks
#     to Dietmar Eberth.
#
# - 21 Jul 2014 M.Fuerstenau version 0.9.17a
#   - Bugfix line 139 and 172 (now 140 and 173). It must be 
#
#     if ( $actual_state > 0 )
#
#     instead of
#
#     if ( $alertcnt > 0
#
# - 25 Jul 2014 M.Fuerstenau version 0.9.18
#   - New option --perf_free_space for checking volumes. It must be used 
#     with --usedspace. In versions prior to 0.9.18 perfdata was always 
#     deliverd as free space even if --usedspace was selected. From 0.9.18
#     on when using --usedspace perfdata is recorded as used space. To prevent
#     old perfdata use this option.
#   - Cluster - removed checks for CPU and MEM
#     - Both checks were senseless for alarming because there are no thresholds.
#       A cluster or resource group is a group of Vmware hosts. Not a logical 
#       construct taking parts of the hosts in a resource group in a manner
#       that several clusters are using the same hosts. So the amount of CPU
#       and memory of all hosts is the CPU and memory of the cluster. Monitoring
#       this makes no sense because there are no thresholds for alerting. For
#       example 50% CPU usage of a cluster can be one host with 90%, and two
#       with 30% each. With an average of 50% everything seems to be ok but one
#       machine has definetely a problem. Same for memory. 
#
# - 21 Aug 2014 M.Fuerstenau version 0.9.19
#   - host_runtime_info()
#     - Some minor corrections in output.
#   - host_storage_info()
#     - Some corrections in output for LUNs. Using <code> in output was a
#       really stupid idea because the code (like ok,error-lostCommunication or
#       whatever is valid there) was interpreted as non existing HTML code.
#     - Some corrections in output for multipath/paths.
#     - Bugfix. Due to a wrong placed curly bracked the output was doubled. Fixed.
#   - host_runtime_info()
#     - Small bugfix. It may happen within the heath check that some values are not set
#       by VMware/hardware. In this case we have an
#       "[Use of uninitialized value in concatenation (.) or string ..."
#       To avoid this we check the values of the hash with each loop an in case a value
#       is not set we replace it whit the string "Unknown".
#
# - 24 Aug 2014 M.Fuerstenau version 0.9.20
#   - datastore_volumes_info(). Some improvements.
#     - Output. Because it was hard to see an alerting volume within the mass of others
#       the output is now grouped so that all alerting volumes are listed on top with 
#       a leading comment. Second are the volumes with no errors. Theses volumes are
#       seperated by a line and also introduced by a comment.
#     - New commandline switch --spaceleft.  When checking multiple volumes the threshold
#       must be given in either percent (old) OR space left on device.(New)
#
# - 28 Aug 2014 M.Fuerstenau version 0.9.20a
#   - datastore_volumes_info().
#     - Fixed some small bugs in output.
#
# - 7 Oct 2014 M.Fuerstenau version 0.9.21
#   - host_runtime_info()
#     - If the CIM server is not running (or not running correctly) the health
#       check receives a lot of unknown events even in the case the hardware
#       status from the GUI looks ok. So we check for the first CPU. If it is
#       unknown be sure the CIM server has to be restarted. After this you will
#       notice a difference in the GUI too.
#   - host_net_info()
#     - In case of an unplugged/disconnected NIC the state is now warning
#       instead of critical because an unplugged card is not always a critical
#       situtation but the admin should take notice of that.
#
# - 16 Dec 2014 M.Fuerstenau version 0.9.22
#   - Around line 1680:
#     - The previous check for an valid session was done with a string compare. This method
#       was taken from the VMware website. But it didn't work correctly. In $@ you will find
#       after an eval the error message in case of an error or nothing when it was successfull.
#       The problem was the string compare. If another language as English was choosen this
#       didn't work. So now it's only checked whether $@ has a content (error) or is empty (success).
#
# - 27 Dec 2015 M.Fuerstenau version 0.9.22a
#   - Bugfix:
#     - Instead of mapping 1 to 0 with --ignore_warning 2 was mapped to 0. Corrected.
#
# - 31 May 2015 M.Fuerstenau version 0.9.23
#   - check_vmware_esx.pl:
#     - New option --statelabel to have the label OK, CRITICAL etc. in plugin output to
#       fulfill the rules of the plugin developer guidelines. This was proposed by Simon Meggle.
#       See Readme.
#     - Added test for session file directory. Thanks Simon.
#     - Replaced variable $plugin_cache with $sessionfile_dir_def. $plugin_cache was copied from
#       another plugin of me. But this plugin doesn't  store any data. it was only used to store the 
#       session files (and session file lock files) and therefore the name was misleading.
#   - host_storage_info()
#     - Bugfix: Fixed bug in host storage adapter whitelisting.(Simon Meggle)
#     - Bugfix: Elements not matching the whitelist were not counted as ignored.(Simon Meggle)
#   - host_net_info()
#     - Bugfix: Fixed missing semicolon between some perf values and warning threshold.(Simon Meggle)
#   - host_runtime_info()
#     - Bugfix: Elements not matching the whitelist were not counted as ignored.(Simon Meggle)
#     - Raise a message after first host runtime issue. Changed state for that check to warning.(Simon Meggle)
#   - dc_runtime_info.pm
#     - Bugfix: Elements not matching the whitelist were not counted as ignored.(Simon Meggle)
#     - New option --showall. Without this only the tool status of machines with problems is listed.
#     -  Bugfix: "Installed,running,supported and newer than the version available on the host." was set
#        to warning but this is quit ok.
#      - In case of a complete runtime check the output is shorted. 
#   - vm_net_info()
#     - Bugfix: Fixed missing semicolon between some perf values and warning threshold.(Simon Meggle)
#
# - 31 May 2015 M.Fuerstenau version 0.9.24
#   - check_vmware_esx.pl:
#     - Option --statelabels changed from a switch to handing over a value (y or n). This was done as mentioned 
#       earlier to fulfill to have the label OK, CRITICAL etc. in plugin output to
#       fulfill the rules of the plugin developer guidelines. This was proposed by Simon Meggle.
#       See Readme.
#     - Bugfix: Wrong output for --statelabels from the help.
#
# - 3 Jun 2015 M.Fuerstenau version 0.9.25
#   - check_vmware_esx.pl:and dc_runtime_info()
#     - New optione --open-vm-tools to signalize that Open VM Tools are used and that the 
#       version of the tools on the host is obsolete.
#   - dc_runtime_info()
#     - "VMware Tools is installed, but it is not managed by VMWare" will except the previous point
#       now lead to a warning (1) instead of a critical (2).
#
#- 10 Jun 2015 M.Fuerstenau version 0.9.26
#  - help()
#    - Bugfix: --nosession was printed out twice. Same line the not "not" was missing.
#      This was bad because it changed the meaning of the line. Same error in the command reference
#      because the reference is only the output from the help in a file.
#
# - 31 Jul 2015 Markus Frosch
#   - rewritten session locking behavior, locking is only done when writing a session due
#     a new login or when no session existed.
#     Parallel runs with no session will only cause the first process to write a sessionfile.
#
# - 4 Sep 2018 Ricardo Bartels version 0.9.26.1
#   - merged session locking behaviour from Markus Frosch
#
#   - Use Perl from env instead of a fixed path (Michael Friedrich)
#     - This allows the plugin to run on any distribution in a yet better way.
#
#   - renamed readme -> readme.md (Michael Friedrich)
#
#   -  Rewrite documentation for better installation and troubleshooting experience (Michael Friedrich)
#     - Add About section which explains the purpose of this plugin
#     - Explain two installation modes
#     - Move specific explanations into FAQ chapter
#     - Add a note on VMware API timeouts
#     - Add some examples and references to Icinga 2 configuration and CheckCommands
#     - Add chapters similar to known Icinga projects
#     - Reformat everything as proper Markdown
#
#   - make session file usage more robust (Sven Nierlein)
#     Compare the api returned url and the given url2connect less error prone.
#     Using --sslport=443 results in a url2connect https://vcenter:443/... while
#     get_option returns https://vcenter/...
#     Also it seems like some api returns .../sdk while others return .../sdk/webService
#     so just ignore that part.
#     Both leads to not resuing the existing session files.
#
#   - added support to query host/datacenter snapshots (Gerhard Lausser)
#     - List vm's wich have snapshots older or bigger than a certain threshold
#
#   - reduce API calls in datastore_volumes_info (Danijel Tasov)
#     Instead of calling Vim::get_view for each datastore call
#     Vim::get_views with all of them at once.
#
#   - lowercase hostnames in connect urls (Danijel Tasov)
#     otherwise cookies may not match with LWP
#
#   - Fix logic error (Danijel Tasov)
#     $host_state cannot equal to UP and "Maintenance Mode" at the same time
#
#   - increase $unknown on undefined $host_state (Danijel Tasov)
#
#   - warn if no volumes match (Danijel Tasov)
#
#   - fix bad OUM in vm_disk_io_info (6uellerBpanda)
#
#   - A unplugged network interface is considered critical (Ricardo Bartels)
#
#   - Be more consistent in return level of maintenance mode (Ricardo Bartels)
#     only write warning if host runtime is checked with no subselect
#
#   - Added option "--ignore_health" to host runtime (all) check
#     Sometimes not all hardware components are correctly reported via
#     CIM interface which leads to check errors when checking runtime
#     status all. This option ignores the health status and prevents the
#     the plugin from failing to report the overall status of the host.
#     IMPORTENT: make sure to monitor the host health status separately!
#     Most likely via ILO/ILOM interface. (Ricardo Bartels)
#
#   - declare all file handles as UTF-8 to be able to print multibyte strings
#     from CIM interface (e.g. snapshot names) (Ricardo Bartels)
#
# - 24 May 2019 M.Fuerstenau version 1.0.0
#   - Merged most pull requests (see 0.9.26.1)
#   - Bugfix - Back to direct call of the command interpreter in shebang. Using Linux
#     it normally only possible to one argument. So "/usr/bin/env perl" will
#     work while "/usr/bin/env perl -w " won't.
#
# - 25 May 2019 M.Fuerstenau version 1.1.0
#   - Merged most pull requests (see 0.9.26.1)
#
#   - New option  --maintenance_mode_state. Sets status in case ESX host is in maintenance
#     mode.
#
#     Possible values are:
#     OK or ok
#     CRITICAL or critical or CRIT or crit
#     WARNING or warning or WARN or warn
#
#     Default is UNKNOWN. Values are case insensitve.
#
#   - Renamed exit_error to exit_unknown because it exits with 3 and not with 2 or 1
#
#   - Moved exit_unknown(), debug() and save_session() before the cluster sub routines because
#     the cluster part is unfinished.
#
#   - Some minor reformatting of code.
#
# - 25 May 2019 M.Fuerstenau version 1.1.1
#   - Added modified SSL certificate validation by Justin Michael
#
# - 26 May 2019 M.Fuerstenau version 1.2.0
#   - Merged:
#      - 25 May 2019 Ricardo Bartels
#        - request ESXi host or vCenter version trough runtime
#        - add feature to request licenses informations from host or vCenter
#   - Bugfix
#     - An option --open_vm_tools_okto give OK instead of UNKNOWN was added 
#       in 2015(!) but only for dc_runtime_info() but not for vm_runtime_info().
#       It was also not part of help() or the command reference. Fixed.
#   - Reformatted code of system_license_info()
#     - Corresponding braces and brackets shouldbe in the same column. 
#       This makes reading of the code easier.
#     - Same for unified indentions
#     - Function calls should not be spread over several lines exept you have
#       clean indentions. Also for better readability.
#     - Replaced "elsif" by "else if" also for clean indention and ....
#     - New option --no_vm_tools_ok. It maybe for some reasons that you
#       have virtual machines without VMware tools. This should not cause an alarm.
#   - New option --unplugged_nics_state. Sets status for unplugged nics. This option
#     replaces hardcoded set to critical by Ricardo Bartels
#
#     Possible values are:
#     OK or ok
#     CRITICAL or critical or CRIT or crit
#     WARNING or warning or WARN or warn
#
#     Default is WARNING. Values are case insensitve.
#
# - 1 Jun 2019 M.Fuerstenau version 1.2.1
#   - Added some fixes from Ricardo Bartels
#     - fixed dates, names and typos in recent release notes
#     - documented/renamed new option unconnected_nics to unplugged_nics_state
#     - fix option maintenance_mode_state, now passed on to all host modules
#       (Thx to Ricardo to correct my lousy "middle-in-thenight-work - Martin)
#   - Added fix from Claudio Kuenzler
#     - Corrected perf data on net checks 
#   - Replace elsif by else ...if in datastore_volumes_info()
#
# - 9 Oct 2019 M.Fuerstenau version 1.2.2
#   - Added some fixes in host_runtime_info.pm and host_disk_io_info.pm
#     from Markus Frosch (lazyfrosch) - Netways. Fixes unknown states in 
#     host_runtime_info() and maintenance_mode_state in host_disk_io_info().
#     But elsif was replaced by else if because in my opninio elsif shredders the
#     structure of the code. 
#
# - 26 Nov 2019 M.Fuerstenau version 1.2.3
#   - Fixed duplicate definition in datastore_volumes_info.pm
#
# - 9 Jun 2022 M.Fuerstenau version 1.2.4
#   - Added several patches (pull requests) from Github:
#     - new command line option "--moref" that allows for selecting virtual
#       machines by their Managed Object Reference name (e.g. "vm-193")
#     - ESXi reports temperature sensors as category "Other" instead of
#       "Temperature" for some vendors, change selection critera from Category
#       to BaseUnit starting with "Degrees"
#     - Updated some links in the readme.
#       Patch by b0bcarlson
#     - It's possible to check hosts via datacenter but it was missing in help.
#       Updated by Danijel Tasov (datamuc) ConSol
#     - Catch connection errors
#     - Health check failed if system has no hardware sensors. Fixed.
#     - Add host CPU readiness % subselect
#     - Added error message when trying to check guest CPU without subselect
#       Instead of printing whole help like in the patch only vm part
#       is printed
#     - Remove output of guestToolsUnmanaged if --open_vm_tools_ok
#     - Fully ignore unknown states for hardware



use strict;
use warnings;
use File::Basename;
use HTTP::Date;
use Getopt::Long;
use VMware::VIRuntime;
use Time::Duration;
use Time::HiRes qw(usleep);

# Own modules
use lib "modules";
#use lib "/usr/lib/nagios/vmware/modules";
use help;
use process_perfdata;
use datastore_volumes_info;

# Prevent SSL certificate validation

BEGIN {
    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
    eval {
        # required for new IO::Socket::SSL versions
        require IO::Socket::SSL;
        IO::Socket::SSL->import();
        IO::Socket::SSL::set_ctx_defaults( SSL_verify_mode => 0 );
    };
};

if ( $@ )
   {
   print "No VMware::VIRuntime found. Please download ";
   print "latest version of VMware-vSphere-SDK-for-Perl from VMware ";
   print "and install it.\n";
   exit 2;
   }

# Let's catch some signals
# Handle SIGALRM (timeout triggered by alarm() call)
$SIG{ALRM} = 'catch_alarm';
$SIG{INT}  = 'catch_intterm';
$SIG{TERM} = 'catch_intterm';

# define alle file handles as UTF-8
use open qw(:std :utf8);

#--- Start presets and declarations -------------------------------------
# 1. Define variables

# General stuff
our $version;                                  # Only for showing the version
our $prog_version = '1.2.4';                   # Contains the program version number
our $ProgName = basename($0);

my  $PID = $$;                                 # Stores the process identifier of the actual run. This will be
                                               # be stored in the lock file. 
my  $PID_exists;                               # For testing for the process that wrote the lock file the last time
my  $PID_old;                                  # PID read from lock file

my  $help;                                     # If some help is wanted....
my  $NoA="";                                   # Number of arguments handled over
                                               # the program
# Login options
my  $username;                                 # Username for vmware host or vsphere server (datacenter)
my  $password;                                 # Password for vmware host or vsphere server (datacenter)
my  $authfile;                                 # If username/password should read from a file ....
my  $sessionfile_name;                         # Contains the name of the sessionfile if a
                                               # a sessionfile is used for faster authentication
my  $sessionfile_dir;                          # Optinal. Contains the path to the sessionfile. Used in conjunction
                                               # with sessionfile
my  $sessionfile_dir_def="/tmp/";              # Directory for caching the session files and sessionfile lock files
                                               # Good idea to use a tmpfs because it speeds up operation    
my  $nosession;                                # Just a flag to avoid using a sessionfile
my  $vim;                                       # Needed to stroe results ov Vim.

our $host;                                     # Name of the vmware server
my  $cluster;                                  # Name of the monitored cluster
our $datacenter;                               # Name of the vCenter server
our $vmname;                                   # Name of the virtual machine
our $moref;                                    # Managed object reference of the virtual machine

my  $unplugged_nics_state;                     # Which state should be deliverd in state of unconnected nics?

                                               # Possible values are
                                               # OK or ok
                                               # CRITICAL or critical or CRIT or crit
                                               # WARNING or warning or WARN or warn
my  $unplugged_nics_state_def="warning";       # Default status for unconnected nics?

my  $maintenance_mode_state;                   # Status in case ESX host is in maintenance mode

                                               # Possible values are
                                               # OK or ok
                                               # CRITICAL or critical or CRIT or crit
                                               # WARNING or warning or WARN or warn
my  $maintenance_mode_state_def="unknown";     # Default status for maintenance mode

my  $output;                                   # Contains the output string
my  $values;
my  $result;                                   # Contains the output string
our $perfdata;                                 # Contains the perfdata string.
my  $perfdata_init = "perfdata:";              # Contains the perfdata init string. We init $perfdata with
                                               # a stupid string because in case of concatenate perfdata
                                               # it is much more simple to remove a leading string with
                                               # a regular expression than to decide in every case wether
                                               # the variablecontains content or not.
$perfdata = $perfdata_init;                    # Init of perfdata. Using variables instead of literals ensures
                                               # that the string can be changed here without harm the function.
our $perf_thresholds = ";";                    # This contains the string with $warning, $critical or nothing
                                               # for $perfdata. If no thresold is set it is just ;

my  $url2connect;                              # Contains the URL to connect to the host
                                               # or the datacenter depending on the selected type
my  $sslport;                                  # If a port other than 443 is used.
my  $sslport_def = 443;                        # Default port
my  $select;
our $subselect;

our $warning;                                  # Warning threshold.
our $critical;                                 # Critical threshold.
our $reverse_threshold;                        # Flag. Needed if critical must be smaller than warning

our $crit_is_percent;                          # Flag. If it is set to one critical threshold is percent.
our $warn_is_percent;                          # Flag. If it is set to one warning threshold is percent.
my  $thresholds_given = 0;                     # During checking the threshold it will be set to one. Only if
                                               # it is set we will check the threshold against warning or critical
                                        
our $spaceleft;                                # This is used for datastore volumes. When checking multiple volumes
                                               # the threshol must be given in either percent or space left on device.

our $listsensors;                              # This flag set in conjunction with -l runtime -s health or -s sensors
                                               # will list all sensors
our $ignorehealth;                             # ignore health issues when requesting runtime informations
our $usedspace;                                # Show used spaced instead of free
our $gigabyte;                                 # Output in gigabyte instead of megabyte
our $perf_free_space;                          # To display perfdata as free space instead of used when using
                                               # --usedspace
                                               
our $alertonly;                                # vmfs - list only alerting volumes

our $blacklist;                                # Contains the blacklist
our $whitelist;                                # Contains the whitelist

our $isregexp;                                 # treat names, blacklist and whitelists as regexp

my  $sec;                                      # Seconds      - used for some date functions
my  $min;                                      # Minutes      - used for some date functions
my  $hour;                                     # Hour         - used for some date functions
my  $mday;                                     # Day of month - used for some date functions
my  $mon;                                      # Month        - used for some date functions
my  $year;                                     # Year         - used for some date functions

my  $timeout = 90;                             # Time in seconds befor the plugin kills itself when it' not ready
my  $debug = 0;                                # global switch for debugging

my  $program_start = time();                   # record the program_start

# Output options
our $multiline;                                # Multiline output in overview. This mean technically that
                                               # a multiline output uses a HTML <br> for the GUI instead of
                                               # Be aware that your messing connections (email, SMS...) must use
                                               # a filter to file out the <br>. A sed oneliner like the following
                                               # will do the job:
                                               # sed 's/<[^<>]*>//g'
my  $multiline_def="\n";                       # Default for $multiline;

our $vm_tools_poweredon_only;                  # Used with Vcenter runtime check to list only powered on VMs when
                                               # checking the tools
our $showall;                                  # Shows all where used
                                               # checking the tools
our $ignoreunknown;                            # Maps unknown to ok
our $ignorewarning;                            # Maps warning to ok
our $standbyok;                                # For multipathing if a standby multipath is ok
our $listall;                                  # used for host. Lists all available devices(use for listing purpose only)
our $nostoragestatus;                          # To avoid a double alarm when also doing a check with -S runtime -s health
                                               # and -S runtime -s storagehealth for the same host.

my $statelabels_def="y";                       # Default value for state labels in plugin output as described in the
                                               # Nagios Plugin Developer Guidelines. In my opinion this values don't make
                                               # sense but to to be compatible.... . It can be overwritten via commandline.
                                               # If you prefer no state labels (as it was default in earlier versions)
                                               # set this default to "n".
my $statelabels;                               # To overwrite $statelabels_def via commandline.
our $openvmtools;                              # Signalize that you use Open VM Tools instead of the servers one.
our $no_vmtools;                                # Signalize that not having VMware tools is ok
our $hidekey;                                  # Hide licenses key when requesting license informations



my  $trace;


# 2. Define arrays and hashes  

# The same as in Nagios::plugin::functions but it is ridiculous to buy a truck for a
# "one time one box" transportations job.

our %status2text = (
    0 => 'Ok',
    1 => 'Warning',
    2 => 'Critical',
    3 => 'Unknown',
    4 => 'Dependent',
);

#--- End presets --------------------------------------------------------

# First we have to fix  the number of arguments

$NoA=$#ARGV;

Getopt::Long::Configure('bundling');
GetOptions
	("h:s" => \$help,                "help:s"                   => \$help,
	 "H=s" => \$host,                "host=s"                   => \$host,
	 "C=s" => \$cluster,             "cluster=s"                => \$cluster,
	 "D=s" => \$datacenter,          "datacenter=s"             => \$datacenter,
	 "w=s" => \$warning,             "warning=s"                => \$warning,
	 "c=s" => \$critical,            "critical=s"               => \$critical,
	 "N=s" => \$vmname,              "name=s"                   => \$vmname,
                                         "moref=s"                  => \$moref,
	 "u=s" => \$username,            "username=s"               => \$username,
	 "p=s" => \$password,            "password=s"               => \$password,
	 "f=s" => \$authfile,            "authfile=s"               => \$authfile,
	 "S=s" => \$select,              "select=s"                 => \$select,
	 "s=s" => \$subselect,           "subselect=s"              => \$subselect,
	                                 "sessionfile=s"            => \$sessionfile_name,
	                                 "sessionfiledir=s"         => \$sessionfile_dir,
	                                 "nosession"                => \$nosession,
	 "B=s" => \$blacklist,           "exclude=s"                => \$blacklist,
	 "W=s" => \$whitelist,           "include=s"                => \$whitelist,
         "t=s" => \$timeout,             "timeout=s"                => \$timeout,
         "V"   => \$version,             "version"                  => \$version,
         "d"   => \$debug,               "debug"                    => \$debug,
	                                 "ignore_unknown"           => \$ignoreunknown,
	                                 "ignore_warning"           => \$ignorewarning,
	                                 "trace=s"                  => \$trace,
                                         "listsensors"              => \$listsensors,
                                         "ignore_health"            => \$ignorehealth,
                                         "usedspace"                => \$usedspace,
                                         "perf_free_space"          => \$perf_free_space,
                                         "alertonly"                => \$alertonly,
                                         "multiline"                => \$multiline,
                                         "isregexp"                 => \$isregexp,
                                         "listall"                  => \$listall,
                                         "poweredonly"              => \$vm_tools_poweredon_only,
                                         "showall"                  => \$showall,
                                         "standbyok"                => \$standbyok,
                                         "sslport=s"                => \$sslport,
                                         "gigabyte"                 => \$gigabyte,
                                         "nostoragestatus"          => \$nostoragestatus,
                                         "statelabels"              => \$statelabels,
                                         "open_vm_tools_ok"         => \$openvmtools,
                                         "no_vm_tools_ok"           => \$no_vmtools,
                                         "hidekey"                  => \$hidekey,
                                         "spaceleft"                => \$spaceleft,
                                         "maintenance_mode_state=s" => \$maintenance_mode_state,
                                         "unplugged_nics_state=s"   => \$unplugged_nics_state
);

# Show version
if ($version)
   {
   print "Version $prog_version\n";
   print "This program is free software; you can redistribute it and/or modify\n";
   print "it under the terms of the GNU General Public License version 2 as\n";
   print "published by the Free Software Foundation.\n";
   exit 0;
   }

# Several checks to check parameters
if (defined($help))
   {
   print_help($help);
   exit 0;
   }

if (defined($blacklist) && defined($whitelist))
   {
   print "Error: -B|--exclude and -W|--include should not be used together.\n\n";
   print_help($help);
   exit 1;
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
   print_help($help);
   exit 1;
   }

# If you have set a timeout exit with alarm()
if ($timeout)
   {
   # Start the timer to script timeout
   alarm($timeout);
   }

$output = "Unknown ERROR!";
$result = 2;

# Set exit code for checks when in maintenance mode
if (!(defined($maintenance_mode_state)))
   {
   $maintenance_mode_state=$maintenance_mode_state_def;
   }

# We are using regex instead of a simple compare to be fault tolerant
if ($maintenance_mode_state =~ m/^ok.*$/i)
   {
   $maintenance_mode_state = 0;
   }
else
   {
   if ($maintenance_mode_state =~ m/^wa.*$/i)
      {
      $maintenance_mode_state = 1;
      }
   else
      {
      if ($maintenance_mode_state =~ m/^cr.*$/i)
         {
         $maintenance_mode_state = 2;
         }
      else
         {
         if ($maintenance_mode_state =~ m/^un.*$/i)
            {
            $maintenance_mode_state = 3;
            }
         else
            {
            print "Error: Unknown exit status for checks when in maintenance mode. Please check.\n";
            exit 2;
            }
         }
      }
   }
   
# Set state for unconnected nics
if (!(defined($unplugged_nics_state)))
   {
   $unplugged_nics_state=$unplugged_nics_state_def;
   }

# We are using regex instead of a simple compare to be fault tolerant
if ($unplugged_nics_state =~ m/^ok.*$/i)
   {
   $unplugged_nics_state = 0;
   }
else
   {
   if ($unplugged_nics_state =~ m/^wa.*$/i)
      {
      $unplugged_nics_state = 1;
      }
   else
      {
      if ($unplugged_nics_state =~ m/^cr.*$/i)
         {
         $unplugged_nics_state = 2;
         }
      else
         {
         print "Error: Unknown states for unconnected nics. Please check.\n";
         exit 2;
         }
      }
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
      if ( $select ne "volumes")
         {
         $subselect = local_lc($subselect)
         }
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
   unless(open AUTH_FILE, '<', $authfile)
         {
         print "Unable to open auth file \"$authfile\"\n";
         exit 3;
         }
   
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
   $url2connect = lc($datacenter);
   }
else
   {
   if (defined($host))
      {
      $url2connect = lc($host);
      }
   else
      {
      print "No Host or Datacenter specified\n";
      exit 2;
      }
   }

if (defined($sslport))
   {
   $url2connect = $url2connect . ":" . $sslport;
   }

$url2connect = "https://" . $url2connect . "/sdk/webService";

# Now let's do the login stuff

if (!defined($nosession))
   {
   if (defined($datacenter))
      {
      if (defined($sessionfile_name))
         {
         $sessionfile_name =~ s/ +//g;
         $sessionfile_name = $datacenter . "_" . $sessionfile_name . "_session";
         }
      else
         {
         $sessionfile_name = $datacenter . "_session";
         }
      }
   else
      {
      if (defined($sessionfile_name))
         {
         $sessionfile_name =~ s/ +//g;
         $sessionfile_name = $host . "_" . $sessionfile_name . "_session";
         }
      else
         {
         $sessionfile_name = $host . "_session";
         }
      }
      
   # Set default best location for sessionfile_dir_def in this environment
   if ( $ENV{OMD_ROOT}) 
      {
      $sessionfile_dir_def = $ENV{OMD_ROOT} . "/var/check_vmware_esx/";
      if ( ! -d $sessionfile_dir_def ) 
         {
         unless (mkdir $sessionfile_dir_def) 
            {
            die(sprintf "UNKNOWN: Unable to create sessionfile_dir_def directory %s.", $sessionfile_dir_def);
            }
         } 
      }

   if (defined($sessionfile_dir))
      {
      # If path contains trailing slash remove it
      $sessionfile_dir =~ s/\/$//;
      $sessionfile_name = $sessionfile_dir . "/" . $sessionfile_name;
      }
   else
      {
      $sessionfile_name = $sessionfile_dir_def . $sessionfile_name;
      }
   
   unless (-d $sessionfile_dir_def) 
          {
          die(sprintf "UNKNOWN: sessionfile_dir_def directory %s does not exist.", $sessionfile_dir_def);
          }

   if ( -e $sessionfile_name )
      {
      debug("Trying to resume existing session from '%s'", $sessionfile_name);

      eval {Vim::load_session(session_file => $sessionfile_name)};
      if (($@ ne '') || (trim_connect_url(Opts::get_option("url")) ne trim_connect_url($url2connect)))
         {
         debug("session resume failed, logging in at %s as %s", $url2connect, $username);
         Util::connect($url2connect, $username, $password);

         save_session($sessionfile_name);
         }
      }
   else
      {
      debug("sessionfile '%s' does not exist", $sessionfile_name);

      debug("logging in at %s as %s", $url2connect, $username);
      Util::connect($url2connect, $username, $password);

      save_session($sessionfile_name);
      }
   }
else
   {
   Util::connect($url2connect, $username, $password);
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

if (defined($sessionfile_name) and -e $sessionfile_name)
   {
   Vim::unset_logout_on_disconnect();
   }
else
   {
   Util::disconnect();
   }

# Added for mapping unknown to ok - M.Fuerstenau - 30 Mar 2011

if (defined($ignoreunknown))
   {
   if ($result eq 3)
      {
      $result = 0;
      }
   }
# Added for mapping warning to ok - M.Fuerstenau - 31 Dec 2013

if (defined($ignorewarning))
   {
   if ($result eq 1)
      {
      $result = 0;
      }
   }

# Now we remove the leading init string and whitespaces from the perfdata
$perfdata =~ s/^$perfdata_init//;
$perfdata =~ s/^[ \t]*//;

# $statelabels set or using default?
if (defined($statelabels))
   {
   # This eliminates typos like Y or yes or nO etc.
   if ($statelabels =~ m/^y.*$/i)
      {
      $statelabels = "y";
      }
   else
      {
      if ($statelabels =~ m/^n.*$/i)
         {
         $statelabels = "n";
         }
      else
         {
         print "Wrong value for --statelabels. Must be y or no and not $statelabels\n";
         exit 2;
         }
      }
   }
else
   {
   $statelabels = $statelabels_def;
   }
   
   
if ( $result == 0 )
   {
   if ($statelabels eq "y")
      {
      print "OK: $output";
      }
   else
      {
      print "$output";
      }

   if ($perfdata)
      {
      print "|$perfdata\n";
      }
      else
      {
      print "\n";
      }
   }

# Remove the last multiline regardless whether it is \n or <br>
$output =~ s/$multiline$//;

if ( $result == 1 )
   {
   if ($statelabels eq "y")
      {
      print "WARNING: $output";
      }
   else
      {
      print "$output";
      }

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
   if ($statelabels eq "y")
      {
      print "CRITICAL: $output";
      }
   else
      {
      print "$output";
      }

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
   if ($statelabels eq "y")
      {
      print "UNKNOWN: $output";
      }
   else
      {
      print "$output";
      }

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

sub main_select
    {
    if (defined($moref))
       {
       # try to resolve MORef to a virtual machine name
       local $@;
       eval
           {
           my $mo_ref = ManagedObjectReference->new(type => 'VirtualMachine', value => $moref);
           my $vm = Vim::get_view(mo_ref => $mo_ref, view_type => 'VirtualMachine', properties => [ 'name' ]);
           $vmname = $vm->name;
           };
       if ($@)
           {
           print "Failed to resolve MORef \"$moref\" to a virtual machine name!\n";
           exit(2);
           }
       }

    if (defined($vmname))
       {
       if ($select eq "cpu")
          {
          require vm_cpu_info;
          import vm_cpu_info;
          ($result, $output) = vm_cpu_info($vmname);
          return($result, $output);
          }
       if ($select eq "mem")
          {
          require vm_mem_info;
          import vm_mem_info;
          ($result, $output) = vm_mem_info($vmname);
          return($result, $output);
          }
       if ($select eq "net")
          {
          require vm_net_info;
          import vm_net_info;
          ($result, $output) = vm_net_info($vmname);
          return($result, $output);
          }
       if ($select eq "io")
          {
          require vm_disk_io_info;
          import vm_disk_io_info;
          ($result, $output) = vm_disk_io_info($vmname);
          return($result, $output);
          }
       if ($select eq "runtime")
          {
          require vm_runtime_info;
          import vm_runtime_info;
          ($result, $output) = vm_runtime_info($vmname);
          return($result, $output);
          }
       if ($select eq "soap")
          {
          ($result, $output) = soap_check();
          return($result, $output);
          }

          get_me_out("Unknown host-vm select");
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
          ($result, $output) = host_cpu_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "mem")
          {
          require host_mem_info;
          import host_mem_info;
          ($result, $output) = host_mem_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "net")
          {
          require host_net_info;
          import host_net_info;
          ($result, $output) = host_net_info($esx_server, $maintenance_mode_state, $unplugged_nics_state);
          return($result, $output);
          }
       if ($select eq "io")
          {
          require host_disk_io_info;
          import host_disk_io_info;
          ($result, $output) = host_disk_io_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "volumes")
          {
          require host_list_vm_volumes_info;
          import host_list_vm_volumes_info;
          ($result, $output) = host_list_vm_volumes_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "runtime")
          {
          require host_runtime_info;
          import host_runtime_info;
          ($result, $output) = host_runtime_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       # service OR services because I always type the wrong one :-)) - M.Fuerstenau
       if ($select =~ m/^service.?$/)
          {
          require host_service_info;
          import host_service_info;
          ($result, $output) = host_service_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "storage")
          {
          require host_storage_info;
          import host_storage_info;
          ($result, $output) = host_storage_info($esx_server, $blacklist, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "uptime")
          {
          require host_uptime_info;
          import host_uptime_info;
          ($result, $output) = host_uptime_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "hostmedia")
          {
          require host_mounted_media_info;
          import host_mounted_media_info;
          ($result, $output) = host_mounted_media_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "soap")
          {
          ($result, $output) = soap_check();
          return($result, $output);
          }
       if ($select eq "snapshots")
          {
          require host_snapshot_info;
          import host_snapshot_info;
          ($result, $output) = host_snapshot_info($esx_server, $maintenance_mode_state);
          return($result, $output);
          }
       if ($select eq "license")
          {
          require system_license_info;
          import system_license_info;
          ($result, $output) = system_license_info($esx_server);
          return($result, $output);
          }

          get_me_out("Unknown host select");
        }

    if (defined($cluster))
       {
       if ($select eq "cluster")
          {
          ($result, $output) = cluster_cluster_info($cluster);
          return($result, $output);
          }
       if ($select eq "volumes")
          {
          require cluster_list_vm_volumes_info;
          import cluster_list_vm_volumes_info;
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

          get_me_out("Unknown cluster select");
        }

    if (defined($datacenter))
       {
       if ($select eq "volumes")
          {
          require dc_list_vm_volumes_info;
          import dc_list_vm_volumes_info;
          ($result, $output) = dc_list_vm_volumes_info();
          return($result, $output);
          }
       if ($select eq "runtime")
          {
          require dc_runtime_info;
          import dc_runtime_info;
          ($result, $output) = dc_runtime_info();
          return($result, $output);
          }
       if ($select eq "soap")
          {
          ($result, $output) = soap_check();
          return($result, $output);
          }
       if ($select eq "snapshots")
          {
          require dc_snapshot_info;
          import dc_snapshot_info;
          ($result, $output) = dc_snapshot_info();
          return($result, $output);
          }
       if ($select eq "license")
          {
          require system_license_info;
          import system_license_info;
          ($result, $output) = system_license_info();
          return($result, $output);
          }

       get_me_out("Unknown datacenter select");
       }
    get_me_out("You should never end here. Totally unknown anything.");
    }
    
sub check_against_threshold
    {
    my $check_result = shift(@_);
    my $return_state = 0;
 

    if ((defined($warning)) && (defined($critical)))
       {
       if ( $warning >= $critical )
          {
          if ( $check_result <= $warning)
             {
             $return_state = 1;
             }
          if ( $check_result <= $critical)
             {
             $return_state = 2;
             }
          }
       else
          {
          if ( $check_result >= $warning)
             {
             $return_state = 1;
             }
          if ( $check_result >= $critical)
             {
             $return_state = 2;
             }
          }
       }
    else
       {
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
       }
    return $return_state;
    }
    
sub check_state
    {
    if (grep { $_ == 2 } @_)
       {
       return 2;
       }
    if (grep { $_ == 1 } @_)
       {
       return 1;
       }
    if (grep { $_ == 3 } @_)
       {
       return 3;
       }
    if (grep { $_ == 0 } @_)
       {
       return 0;
       }
    return 3;
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

sub trim_connect_url
    {
    my($url) = @_;
    $url =~ s/:443//gmx;
    $url =~ s/\/webService$//gmx;
    return($url);
    }

sub check_health_state
    {
    my ($actual_state) = shift(@_);
    my $state = 3;

    if (lc($actual_state) eq "green")
       {
       $state = 0
       }

    if (lc($actual_state) eq "yellow")
       {
       $state = 1;
       }
 
    if (lc($actual_state) eq "red")
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
    my ($blacklist_ref,$regexpflag,$candidate) = @_;
    my $ret = 0;
    my @blacklist;
    my $blacklist;
    my $hitcount = 0;
    
    if (!defined $$blacklist_ref)
       {
       return 0;
       }

    if ($regexpflag == 0)
       {
       $ret = grep(/$candidate/, $$blacklist_ref);
       }
    else
       {
       @blacklist = split(/,/, $$blacklist_ref);

       foreach $blacklist (@blacklist)
               {
               if ($candidate =~ m/$blacklist/)
                  {
                  $hitcount++;
                  }
               }

       if ($hitcount >= 1)
          {
          $ret = 1;
          }
       }
    return $ret;
}

sub isnotwhitelisted
    {
    my ($whitelist_ref,$regexpflag,$candidate) = @_;
    my $ret = 0;
    my @whitelist;
    my $whitelist;
    my $hitcount = 0;

    if (!defined $$whitelist_ref)
       {
       return $ret;
       }

    if ($regexpflag == 0)
       {
       $ret = ! grep(/$candidate/, $$whitelist_ref);
       }
    else
       {
       @whitelist = split(/,/, $$whitelist_ref);

       foreach $whitelist (@whitelist)
               {
               if ($candidate =~ m/$whitelist/)
                  {
                  $hitcount++;
                  }
               }

       if ($hitcount == 0)
          {
          $ret = 1;
          }
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
    
# Catching some signals
sub catch_alarm
    {
    print "UNKNOWN: Script timed out.\n";
    exit 3;
    }

sub catch_intterm
    {
    print "UNKNOWN: Script killed by monitor.\n";
    exit 3;
    }

sub exit_unknown
    {
    my $message = shift;
    printf "$message\n", @_;
    exit 3;
    }
 
sub debug
    {
    unless ($debug)
           {
           return;
           }
    my $message = shift;
    printf "$message\n", @_;
    }

sub save_session
    {
    my $sessionfile = shift
        or exit_unknown("save_session needs a parameter!");
    my $lock = $sessionfile . "_locked";
    my $fh;
    my $mtime;

    if (-e $sessionfile)
       {
       $mtime = (stat($sessionfile))[9];
       if ($mtime > $program_start)
          {
          debug("Not saving session, session file '%s' is newer than program start!", $sessionfile);
          return;
          }
       }

    open $fh, '>', $lock
        or exit_unknown "Unable to create session lock file '%s'!", $lock;

    flock $fh, 2
        or exit_unknown "could not lock '$lock'!";

    debug("Saving session to '%s'", $sessionfile);
    Vim::save_session(session_file => $sessionfile);

    close $fh;
    unlink $lock;
    }

#=====================================================================| Cluster |============================================================================#

sub cluster_cluster_info
{
        my ($cluster) = @_;
         
        my $state = 2;
        my $output = 'CLUSTER clusterServices Unknown error';
        
        if (defined($subselect))
        {
                if ($subselect eq "effectivecpu")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('effectivecpu.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
                                $perfdata = $perfdata . " effective cpu=" . $value . "Mhz;" . $perf_thresholds . ";;";
                                $output = "effective cpu=" . $value . "%"; 
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "effectivemem")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('effectivemem.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
                                $perfdata = $perfdata . " effectivemem=" . $value . "MB;" . $perf_thresholds . ";;";
                                $output = "effective mem=" . $value . " MB";
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "failover")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('failover.latest:*'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value));
                                $perfdata = $perfdata . " failover=" . $value . ";" . $perf_thresholds . ";;";
                                $output = "failover=" . $value . " ";
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "cpufairness")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('cpufairness.latest'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value));
                                $perfdata = $perfdata . " cpufairness=" . $value . "%;" . $perf_thresholds . ";;";
                                $output = "cpufairness=" . $value . "%";
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "memfairness")
                {
                        $values = return_cluster_performance_values($cluster, 'clusterServices', ('memfairness.latest'));
                        if (defined($values))
                        {
                                my $value = simplify_number((convert_number($$values[0][0]->value)));
                                $perfdata = $perfdata . " memfairness=" .  $value . "%;" . $perf_thresholds . ";;";
                                $output = "memfairness=" . $value . "%";
                                $state = check_against_threshold($value);
                        }
                }
                else
                {
                get_me_out("Unknown CLUSTER clusterservices subselect");
                }
        }
        else
        {
                $values = return_cluster_performance_values($cluster, 'clusterServices', ('effectivecpu.average', 'effectivemem.average'));
                if (defined($values))
                {
                        my $value1 = simplify_number(convert_number($$values[0][0]->value));
                        my $value2 = simplify_number(convert_number($$values[0][1]->value) / 1024);
                        $perfdata = $perfdata . " effective cpu=" . $value1 . "Mhz;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " effective mem=" . $value2 . "MB;" . $perf_thresholds . ";;";
                        $state = 0;
                        $output = "effective cpu=" . $value1 . " Mhz, effective Mem=" . $value2 . " MB";
                }
        }

        return ($state, $output);
}


sub cluster_runtime_info
{
        my ($cluster, $blacklist) = @_;

        my $state = 2;
        my $output = 'CLUSTER RUNTIME Unknown error';
        my $runtime;
        my $cluster_view = Vim::find_entity_view(view_type => 'ClusterComputeResource', filter => { name => "$cluster" }, properties => ['name', 'overallStatus', 'configIssue']);

        if (!defined($cluster_view))
           {
           print "Cluster " . $$cluster{"name"} . " does not exist.\n";
           exit 2;
           }

        $cluster_view->update_view_data();

        if (defined($subselect))
        {
                if ($subselect eq "listvms")
                {
                        my %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $cluster_view, properties => ['name', 'runtime']);

                        if (!defined($vm_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!defined($vm_views))
                           {
                           print "There are no VMs.\n";
                           exit 2;
                           }

                        my $up = 0;
                        $output = '';

                        foreach my $vm (@$vm_views)
                        {
                                my $vm_state = $vm_state_strings{$vm->runtime->powerState->val};
                                if ($vm_state eq "UP")
                                {
                                        $up++;
                                        $output = $output . $vm->name . "(0), ";
                                }
                                else
                                {
                                        $output = $vm->name . "(" . $vm_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $up .  "/" . @$vm_views . " VMs up: " . $output;
                        $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($up);
                           }
                }
                elsif ($subselect eq "listhost")
                {
# Reminder: Wie bei host_runtime_info die virtuellen Maschinen als performancedaten ausgeben
                        my %host_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED", "standBy" => "STANDBY", "MaintenanceMode" => "Maintenance Mode");
                        my $host_views = Vim::find_entity_views(view_type => 'HostSystem', begin_entity => $cluster_view, properties => ['name', 'runtime.powerState']);

                        if (!defined($host_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!defined($host_views))
                           {
                           print "There are no hosts.\n" ;
                           exit 2;
                           }

                        my $up = 0;
                        my $unknown = 0;
                        $output = '';

                        foreach my $host (@$host_views) {
                                $host->update_view_data(['name', 'runtime.powerState']);
                                my $host_state = $host_state_strings{$host->get_property('runtime.powerState')->val};
                                $unknown += !defined($host_state);
                                $unknown += $host_state eq "3";
                                if ($host_state eq "UP" || $host_state eq "Maintenance Mode") {
                                        $up++;
                                        $output = $output . $host->name . "(UP), ";
                                } else
                                {
                                        $output = $host->name . "(" . $host_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $up .  "/" . @$host_views . " Hosts up: " . $output;
                        $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($up);
                           }

                        $state = 3 if ($state == 0 && $unknown);
                }
                elsif ($subselect eq "status")
                {
                        if (defined($cluster_view->overallStatus))
                        {
                                my $status = $cluster_view->overallStatus->val;
                                $output = "overall status=" . $status;
                                $state = check_health_state($status);
                        }
                        else
                        {
                                $output = "Insufficient rights to access status info on the DC\n";
                                $state = 1;
                        }
                }
                elsif ($subselect eq "issues")
                {
                        my $issues = $cluster_view->configIssue;
                        my $issues_count = 0;

                        $output = '';
                        if (defined($issues))
                        {
                                foreach (@$issues)
                                {
                                        if (defined($blacklist))
                                        {
                                                my $name = ref($_);
                                                next if ($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/);
                                        }
                                        $output = $output . format_issue($_) . "; ";
                                        $issues_count++;
                                }
                        }

                        if ($output eq '')
                        {
                                $state = 0;
                                $output = 'No config issues';
                        }
                        $perfdata = $perfdata . " issues=" . $issues_count;
                }
                else
                {
                get_me_out("Unknown CLUSTER RUNTIME subselect");
                }
        }
     else
        {
                my %cluster_maintenance_state = (0 => "no", 1 => "yes");
                my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $cluster_view, properties => ['name', 'runtime.powerState']);
                my $up = 0;

                if (defined($vm_views))
                {
                        foreach my $vm (@$vm_views) {
                                $up += $vm->get_property('runtime.powerState')->val eq "poweredOn";
                        }
                        $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";
                        $output = $up . "/" . @$vm_views . " VMs up";
                }
                else
                {
                        $output = "No VMs installed";
                }

                my $AlertCount = 0;
                my $SensorCount = 0;
                my ($cpuStatusInfo, $storageStatusInfo, $memoryStatusInfo, $numericSensorInfo);

                $state = 0;
                $output = $output . ", overall status=" . $cluster_view->overallStatus->val . ", " if (defined($cluster_view->overallStatus));

                my $issues = $cluster_view->configIssue;
                if (defined($issues))
                {
                        $output = $output . @$issues . " config issue(s)";
                }
                else
                {
                        $output = $output . "no config issues";
                }
        }

        return ($state, $output);
}

