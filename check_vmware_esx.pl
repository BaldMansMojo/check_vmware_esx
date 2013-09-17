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
#host_list_vm_volumes_info.pm
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
#   Nagios, Icingia etc. are tools for
#
#   a) Alarming. That means checking values against thresholds (internal or handed over)
#   b) Collecting performance data. These data, collected with the checks, like network traffic, cpu usage or so should be
#      interpretable without a lot of other data.
#
#   So as a conclusion collecting historic performance data collected by a monitored system should not be done using Nagios,
#   pnp4nagios etc.. It should be interpreted with the approriate admin tools of the relevant system. For vmware it means use
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
# - 31 Jan 2013 M.Fuerstenau
#   - Replaced most die with a normal if statement and an exit.
#
# - 1 Feb 2013 M.Fuerstenau
#   - Replaced unless with if. unless was only used eight times in the program. In all other statements we had an if statement
#     with the appropriate negotiation for the statement.
#
# - 5 Feb 2013 M.Fuerstenau
#   - Replaced all add_perfdata statements with simple concatenated variable $perfdata
#
# - 6 Feb 2013 M.Fuerstenau
#   - Corrected bug. Name of subroutine was sub check_percantage but thist was a typo.
#
# - 7 Feb 2013 M.Fuerstenau
#   - Replaced $percc and $percw with $crit_is_percent and $warn_is_percent. This was just cosmetic for better readability.
#   - Removed check_percentage(). It was replaced by two one liners directly in the code. Easier to read.
#   - The only codeblocks using check_percentage() were the blocks checking warning and critical. But unfortunately the
#     plausability check was not sufficient. Now it is tested that no other values than numbers and the % sign can be
#     submitted. It is also checked that in case of percent the values are in a valid level between 0 and 100
#
# - 12 Feb 2013 M.Fuerstenau
#   - Replaced literals like CRITICAL with numerical values. Easier to type and anyone developing plugins should be
#     safe with the use
#   - Replaced $state with $actual_state and $res with $state. More for cosmetical issues but the state is returned
#     to Nagios.
#   - check_against_threshold from Nagios::Plugin replaced with a little own subroutine check_against_threshold.
#   - Nagios::Plugin::Functions::max_state replaced with own routine check_state
#
# - 14 Feb 2013 M.Fuerstenau
#   - Replaced hash %STATUS_TEXT from Nagios::Plugin::Functions with own hash %status2.
#
# - 15 Feb 2013 M.Fuerstenau
#   - Own help (print_help()) and usage (print_usage()) function.
#   - Nagios::plugin kicked finally out.
#   - Mo more global variables.
#
# - 25 Feb 2013 M.Fuerstenau
#   - $quickstats instead of $quickStats for better readability.
#
# - 5 Mar 2013 M.Fuerstenau
#   - Removed return_cluster_DRS_recommendations() because for daily use this was more of an exotical feature
#   - Removed --quickstats for host_cpu_info and dc_cpu_info because quickstats is not a valid option here.
#
# - 6 Mar 2013 M.Fuerstenau
#   - Replaced -o listitems with --listitems
#
# - 8 Mar 2013 M.Fuerstenau
#   - --usedspace replaces -o used. $usedflag has been replaced by $usedflag.
#   - --listvms replaces -o listvm. $outputlist has been replaced by $listvms.
#   - --alertonly replaces -o brief. $briefflag has been replaced by $alertonly.
#   - --blacklistregexp replaces -o blacklistregexp. $blackregexpflag has been replaced by $blacklistregexp.
#   - --isregexp replaces -o regexp. $regexpflag has been replaced by $isregexp.
#
# - 9 Mar 2013 M.Fuerstenau
#   - Main selection is now transfered to a subrouting main_select because after
#     a successfull if statement the rest can be skipped leaving the subroutine
#     with return
#
# - 19 Mar 2013 M.Fuerstenau
#   - Reformatted and cleaned up a lot of code. Variable definitions are now at the beginning of each 
#     subroutine instead of defining them "on the fly" as needed with "my". Especially using "my" for
#     definition in a loop is not goog coding style
#
# - 21 Mar 2013 M.Fuerstenau
#   - --listvms removed as extra switch. Ballooning or swapping VMs will always be listed.
#   - Changed subselect list(vm) to listvm for better readability. listvm was accepted  before (equal to list)
#     but not mentioned in the help. To have list or listvm for the same is a little bit exotic. Fixed this inconsistency.
#
# - 22 Mar 2013 M.Fuerstenau
#   - Removed timeshift, interval and maxsamples. If needed use original program from op5.
#
# - 25 Mar 2013 M.Fuerstenau
#   - Removed $defperfargs because no values will be handled over. Only performance check that needed another which 
#     needed another sampling invel was cluster. This is now fix with 3000.
#     
# - 11 Apr 2013 M.Fuerstenau
#   - Rewritten and cleaned subroutine host_mem_info. Removed $value1 - $value5. Stepwise completion of $output makes
#     this unsophisticated construct obsolete.
#
# - 16 Apr 2013 M.Fuerstenau
#   - Stripped down vm_cpu_info. Monitoring CPU usage in Mhz makes no sense under normal circumstances
#     Mhz is no valid unit for performance data according to the plugin developer guide. I have never found
#     a reason to monitor wait time or ready time in a normal alerting evironment. This data has some interest
#     for performance analysis. But this can be done better with the vmware tools.
#   - Rewritten and cleaned subroutine vm_mem_info. Removed $value1 - $value5. Stepwise completion of $output makes
#     this unsophisticated construct obsolete.
#
# - 24 Apr 2013 M.Fuerstenau
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
# - 25 Apr 2013 M.Fuerstenau
#   - Removed swap in vm_mem_info(). From vmware documentation:
#     "Amount of guest physical memory that is currently reclaimed from the virtual machine through ballooning.
#      This is the amount of guest physical memory that has been allocated and pinned by the balloon driver."
#     So here we have again data which makes no sense used alone. You need the context for interpreting them
#     and there are no thresholds for alerting.
#
# - 29 Apr 2013 M.Fuerstenau
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
# - 30 Apr 2013 M.Fuerstenau
#   - Removed subroutines return_dc_performance_values, dc_cpu_info, dc_mem_info, dc_net_info and dc_disk_io_info.
#     Monitored entity was view type HostSystem. This means, that the CPU of the data center server is monitored.
#     The data center server (vcenter) is either a physical MS Windows server (which can be monitored better
#     directly with SNMP and/or NSClient++) or the new Linux based appliance which is a virtual machine and
#     can be monitored as any virtual machine. The OS (Linux) on that virtual machine can be monitored like
#     any standard Linux.
#
# - 5 May 2013 M.Fuerstenau
#   - Revised the code of dc_list_vm_volumes_info()
#
# - 9 May 2013 M.Fuerstenau
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
# - 10 May 2013 M.Fuerstenau
#   - Revised the code of vm_net_info(). Same changes as for host_net_info() exept the NIC section.
#     This is not available for VMs.
#
# - 14 May 2013 M.Fuerstenau
#   - Replaced $command and $subselect with $select and $subselect. Therfore also the options --command
#     --subselect changed to --select and --subselect. This has been done to become it more clear.
#     In fact these items where no commands (or subselects). It were selections from the amount of
#     performance counters available in vmware.
#
# - 15 May 2013 M.Fuerstenau
#   - Kicked out all (I hope so) code for processing historic data from generic_performance_values().
#     generic_performance_values() is called by return_host_performance_values(), return_host_vmware_performance_values()
#     and return_cluster_performance_values() (return_cluster_performance_values() must be rewritten now).
#     The code length of generic_performance_values() was reduced to one third by doing this.
#
# - 6 Jun 2013 M.Fuerstenau
#   - Substituted commandline option for select -l with -S. Therefore -S can't be used as option for the sessionfile
#     Only --sessionfile is accepted nor the name of the sessionfile.
#   - Corrected some bugs in check_against_threshold()
#   - Ensured that in case of thresholds critical must be greater than warning.
#
# - 11 Jun 2013 M.Fuerstenau
#   - Changed select option for datastore from vmfs to volumes because we will have volumes on nfs AND vmfs. 
#   - Changed output for datastore check to use the option --multiline. This will add a \n (unset -> default) for 
#     every line of output. If set it will use HTML tag <br>.
#
# - 13 Jun 2013 M.Fuerstenau
#   - Replaced a previous change because it was wrong done:
#     - --listvms replaced by subselect listvms
#
# - 14 Jun 2013 M.Fuerstenau
#   - Some minor corrections like a doubled chop() datastore_volumes_info()
#   - Added volume type to datastore_volumes_info(). So you can see whether the volume is vmfs (local or SAN) or NFS.
#   - variables like $subselect or $blacklist are global there is no need to handle them over to subroutines like
#     ($result, $output) = vm_cpu_info($vmname, local_uc($subselect)) . For $subselect we have now one uppercase
#     (around line 580) instead of having one with each call in the main selection.
#   - Later on I renamed local_uc to local_lc because I recognized that in cases the subselect is a volume name
#     upper cases won't work.
#   - replaced last -o $addopts (only for the name of a sensor) with --sensorname
#
# - 18 Jun 2013 M.Fuerstenau
#   - Rewritten and cleaned subroutine host_disk_io_info(). Removed $value1 - $value7. Stepwise completion of $output makes
#     this unsophisticated construct obsolete.
#   - Removed use of performance thresholds in performance data when used disk io without subselect because threshold
#     can only be used for on item not for all. Therefore they weren't checked in that section. Senseless.
#   - Changed the output. Opposite to vm_disk_io_info() most vlues in host_disk_io_info() are not transfer rates
#     but latency in milliseconds. The output is now clearly understandable.
#   - Added subselect read. Average number of kilobytes read from the disk each second. Rate at which data is read
#     from each LUN on the host.read rate = # blocksRead per second x blockSize.
#   - Added subselect write. Average number of kilobytes written to disk each second. Rate at which data is written
#     to each LUN on the host.write rate = # blocksRead per second x blockSize
#   - Added subselect usage. Aggregated disk I/O rate. For hosts, this metric includes the rates for all virtual
#     machines running on the host.
#
# - 21 Jun 2013 M.Fuerstenau
#   - Rewritten and cleaned subroutine vm_disk_io_info(). Removed $value1 - $valuen. Stepwise completion of $output makes
#     this unsophisticated construct obsolete.
#   - Removed use of performance thresholds in performance data when used disk io without subselect because threshold
#     can only be used for on item not for all. Therefore they weren't checked in that section. Senseless.
#
# - 24 Jun 2013 M.Fuerstenau
#   - Changed all .= (for example $output .= $xxx.....) to = $var... (for example $output = $output . $xxx...). .= is shorter
#     but the longer form of notification is better readable. The probability of overlooking the dot (especially for older eyes
#     like mine) is smaller. 
#
# - 07 Aug 2013 M.Fuerstenau
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
# - 13 Aug 2013 M.Fuerstenau
#   - Moved host_device_info to host_mounted_media_info. Opposite to it's name
#     and the description this function wasn't designed to list all devices
#     on a host. It was designed to show host cds/dvds mounted to one or more
#     virtual machines. This is important for monitoring because a virtual machine
#     with a mount cd or dvd drive can not be moved to another host.
#   - Made an seperate modules:
#     - host_mounted_media_info.pm -> host_mounted_media_info()
#
# - 19 Aug 2013 M.Fuerstenau
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
# - 21 Aug 2013 M.Fuerstenau
#   - Reformatted and cleaned up host_runtime_info().
#   - A lot of bugs in it.
#
# - 17 Aug 2013 M.Fuerstenau
#   - Minor bug fix.
#     - $subselect was always converted to lower case characters.
#       This is correct exect $subselect contains a name (e.g. volumes). Volume names
#       can contain upper and lower letters. Fixed.
#     - datastore_volumes_info.pm had  my ($datastore, $subselect) = @_; as second line
#       This was incorrect because "global" variables (defined as our in the main program)
#       are not handled over via function call. (Yes - may be handling over maybe more ok 
#       in the sense of structured programming. But really - does handling over and giving back 
#       a variable makes the code so much clearer? More a kind of philosophy :-)) )



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

#==========================================================================| VM |============================================================================#

sub vm_cpu_info
    {
    my ($vmname) = @_;
    my $state = 2;
    my $output = 'HOST-VM CPU Unknown error';
    my $value;
    
    if (defined($subselect))
       {
       if ($subselect eq "wait")
          {
          $values = return_host_vmware_performance_values($vmname,'cpu', ('wait.summation:*'));
          
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value));
             }

          if (defined($value))
             {
             $perfdata = $perfdata . " cpu_wait=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "cpu wait=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }

       if ($subselect eq "ready")
          {
          $values = return_host_vmware_performance_values($vmname,'cpu', ('ready.summation:*'));
          
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value));
             }

          if (defined($value))
             {
             $perfdata = $perfdata . " cpu_ready=" . $value . "ms;" . $perf_thresholds . ";;";
             $output = "cpu ready=" . $value . " ms";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       get_me_out("Unknown HOST CPU subselect");
       }
    else
       {
       $values = return_host_vmware_performance_values($vmname, 'cpu', ('usage.average'));

       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
          $perfdata = $perfdata . " cpu_usage=" . $value . "%;" . $perf_thresholds . ";;";
          $output = "$vmname: cpu usage=" . $value . "%"; 
          $state = check_against_threshold($value);
          }
       return ($state, $output);
       }
    }

sub vm_mem_info
    {
    my ($vmname) = @_;

    my $state = 2;
    my $output = 'HOST-VM MEM Unknown error';
    my $value;
        
    if (defined($subselect))
       {
       if ($subselect eq "usage")
          {
          $values = return_host_vmware_performance_values($vmname, 'mem', ('usage.average'));
          
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
             $perfdata = $perfdata . " mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
             $output = "$vmname: mem usage=" . $value . "%"; 
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "consumed")
          {
          $values = return_host_vmware_performance_values($vmname, 'mem', ('consumed.average'));
       
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " consumed_memory=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "$vmname: consumed memory=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "overhead")
          {
          $values = return_host_vmware_performance_values($vmname, 'mem', ('overhead.average'));
       
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " mem_overhead=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "$vmname: mem overhead=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "active")
          {
          $values = return_host_vmware_performance_values($vmname, 'mem', ('active.average'));
       
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " mem_active=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "$vmname: mem active=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       get_me_out("Unknown HOST-VM MEM Unknown error");
       }
    else
       {
        if ($perf_thresholds ne ';')
           {
           print_help();
           print "\nERROR! Thresholds only allowed with subselects!\n\n";
           exit 2;
           }

       $values = return_host_vmware_performance_values($vmname, 'mem', ('consumed.average', 'usage.average'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
          $perfdata = $perfdata . " consumed_memory=" . $value . "MB;;;";
          $output = "$vmname: consumed memory=" . $value . " MB(";

          $value = simplify_number(convert_number($$values[0][1]->value) * 0.01);
          $perfdata = $perfdata . " mem_usage=" . $value . "%;;;";
          $output = $output . $value . "%)";

          $state = 0;
          }
       return ($state, $output);
       }
    }

sub vm_net_info
    {
    my ($vmname) = @_;
    my $state = 2;
    my $output;
    my $value;

    if (!defined($subselect))
       {
       # This means no given subselect. So all checks must be performemed
       # Therefore with all set no threshold check can be performed
       $subselect = "all";
       if ( $perf_thresholds ne ";")
          {
          print "Error! Thresholds are only allowed with subselects!\n";
          }
       }

    if (($subselect eq "usage") || ($subselect eq "all"))
       {
       $values = return_host_vmware_performance_values($vmname, 'net', ('usage.average:*'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " net_usage=" . $value . $perf_thresholds . ";;";
          $output = "$vmname: net usage=" . $value . " KBps"; 
          if ($subselect ne "all")
             {
             $state = check_against_threshold($value);
             }
          }
       if ($subselect ne "all")
          {
          return ($state, $output);
          }
       }

    if (($subselect eq "RECEIVE") || ($subselect eq "all"))
       {
       $values = return_host_vmware_performance_values($vmname, 'net', ('received.average:*'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " net_receive=" . $value . $perf_thresholds . ";;";
          if ($subselect ne "all")
             {
             $output = "$vmname: net receive=" . $value . " KBps"; 
             $state = check_against_threshold($value);
             }
          else
             {
             $output = $output . ", net receive=" . $value . " KBps"; 
             }
           }
       if ($subselect ne "all")
          {
          return ($state, $output);
          }
       }

    if (($subselect eq "send") || ($subselect eq "all"))
       {
       $values = return_host_vmware_performance_values($vmname, 'net', ('transmitted.average:*'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value));
          $perfdata = $perfdata . " net_send=" . $value . $perf_thresholds . ";;";
          if ($subselect ne "all")
             {
             $output = "$vmname: net send=" . $value . " KBps"; 
             $state = check_against_threshold($value);
             }
          else
             {
             $output =$output . ", net send=" . $value . " KBps"; 
             }
          }
       return ($state, $output);
       }

    if ($subselect ne "all")
       {
       get_me_out("Unknown HOST-VM NET subselect");
       }
    }

sub vm_disk_io_info
    {
    my ($vmname) = @_;
    my $state = 2;
    my $output = 'VM IO Unknown error';
    my $value;
    
    if (defined($subselect))
       {
       if ($subselect eq "usage")
          {
          $values = return_host_vmware_performance_values($vmname, 'disk', ('usage.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " io_usage=" . $value . "MB;" . $perf_thresholds . ";;";
             $output = "$vmname io usage=" . $value . " MB";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       if ($subselect eq "read")
          {
          $values = return_host_vmware_performance_values($vmname, 'disk', ('read.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " io_read=" . $value . "MB/s;" . $perf_thresholds . ";;";
             $output = "$vmname io read=" . $value . " MB/s";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }

       if ($subselect eq "write")
          {
          $values = return_host_vmware_performance_values($vmname, 'disk', ('write.average:*'));
          if (defined($values))
             {
             $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
             $perfdata = $perfdata . " io_write=" . $value . "MB/s;" . $perf_thresholds . ";;";
             $output = "$vmname io write=" . $value . " MB/s";
             $state = check_against_threshold($value);
             }
          return ($state, $output);
          }
       
       get_me_out("Unknown VM IO subselect");
       }
    else
       {

       if ($perf_thresholds ne ';')
          {
          print_help();
          print "\nERROR! Thresholds only allowed with subselects!\n\n";
          exit 2;
          }

       $values = return_host_vmware_performance_values($vmname, 'disk', ('usage.average:*', 'read.average:*', 'write.average:*'));
       if (defined($values))
          {
          $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
          $perfdata = $perfdata . " io_usage=" . $value . "MB;;;";
          $output = "$vmname io usage=" . $value . " MB, ";

          $value = simplify_number(convert_number($$values[0][1]->value) / 1024);
          $perfdata = $perfdata . " io_read=" . $value . "MB;;;";
          $output = $output . "read=" . $value . " MB/s, ";

          $value = simplify_number(convert_number($$values[0][2]->value) / 1024);
          $perfdata = $perfdata . " io_write=" . $value . "MB;;;";
          $output = $output . "write=" . $value . " MB/s";

          $state = 0;
          }
        }

        return ($state, $output);
}

sub vm_runtime_info
    {
    my ($vmname) = @_;
    my $state = 2;
    my $output = 'VM RUNTIME Unknown error';
    my $runtime;
    my $tools_status;
    my $tools_runstate;
    my $tools_version;
    my %vm_guest_state;
    my %vm_tools_strings;
    my %vm_tools_status;
    my $issues;
    my %vm_state_strings;
    my $actual_state;
    my $status;
    
    my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine', filter => {name => $vmname}, properties => ['name', 'runtime', 'overallStatus', 'guest', 'configIssue']);

    if (!defined($vm_view))
       {
       print "VMware machine " . $vmname . " does not exist\n";
       exit 2;
       }

    $runtime = $vm_view->runtime;

    if (defined($subselect))
       {
       if ($subselect eq "con")
          {
          $output = "$vmname connection state=" . $runtime->connectionState->val;
          if ($runtime->connectionState->val eq "connected")
             {
             $state = 0;
             }
          return ($state, $output);
          }

       if ($subselect eq "cpu")
          {
          $output = "$vmname max cpu=" . $runtime->maxCpuUsage . " MHz";
          $state = 0;
          return ($state, $output);
          }

       if ($subselect eq "mem")
          {
          $output = "$vmname max mem=" . $runtime->maxMemoryUsage . " MB";
          $state = 0;
          return ($state, $output);
          }

       if ($subselect eq "state")
          {
          %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
          $actual_state = $vm_state_strings{$runtime->powerState->val};
          $output = "$vmname run state=" . $actual_state;

          if ($actual_state eq "UP")
             {
             if ($actual_state eq "UP")
                {
                $state = 0;
                }
             }
          return ($state, $output);
          }

       if ($subselect eq "status")
          {
          $status = $vm_view->overallStatus->val;
          $output = "$vmname overall status=" . $status;
          $state = check_health_state($status);
          return ($state, $output);
          }

       if ($subselect eq "consoleconnections")
          {
          $output = "$vmname console connections=" . $runtime->numMksConnections;
          $state = check_against_threshold($runtime->numMksConnections);
          return ($state, $output);
          }

       if ($subselect eq "guest")
          {
          %vm_guest_state = ("running" => "Running", "notRunning" => "Not running", "shuttingDown" => "Shutting down", "resetting" => "Resetting", "standby" => "Standby", "unknown" => "Unknown");
          $actual_state = $vm_guest_state{$vm_view->guest->guestState};
          $output = "$vmname guest state=" . $actual_state;
          if ($actual_state eq "Running")
             {
             $state = 0;
             }
          return ($state, $output);
          }

       if ($subselect eq "tools")
          {
          if (exists($vm_view->guest->{toolsRunningStatus}) && defined($vm_view->guest->toolsRunningStatus))
             {
             $tools_runstate = $vm_view->guest->toolsRunningStatus;
             }
          if (exists($vm_view->guest->{toolsVersionStatus}) && defined($vm_view->guest->toolsVersionStatus))
             {
             $tools_version = $vm_view->guest->toolsVersionStatus;
             }

          if (defined($tools_runstate) || defined($tools_version))
             {
             %vm_tools_strings = ("guestToolsCurrent" => "Newest", "guestToolsNeedUpgrade" => "Old", "guestToolsNotInstalled" => "Not installed", "guestToolsUnmanaged" => "Unmanaged", "guestToolsExecutingScripts" => "Starting", "guestToolsNotRunning" => "Not running", "guestToolsRunning" => "Running");

             if (defined($tools_runstate))
                {
                $tools_status = $vm_tools_strings{$tools_runstate} . "-";
                }
   
             if (defined($tools_version))
                {
                $tools_status = $tools_status . $vm_tools_strings{$tools_version} . "-";
                }

             chop($tools_status);

             if (($tools_status eq "Running-Newest") || ($tools_status eq "Running-Unmanaged"))
                {
                $state = 0;
                }
             }
          else
             {
             %vm_tools_strings = ("toolsNotInstalled" => "Not installed", "toolsNotRunning" => "Not running", "toolsOk" => "0", "toolsOld" => "Old", "notDefined" => "Not defined");
             $tools_status = $vm_view->guest->toolsStatus;

             if (defined($tools_status))
                {
                $tools_status = $vm_tools_strings{$tools_status->val};
                }
             else
                {
                $tools_status = $vm_tools_strings{"notDefined"};
                }

             if ($tools_status eq "0")
                {
                $state = 0;
                }
             }
          $output = "$vmname tools status=" . $tools_status;
          return ($state, $output);
          }

       if ($subselect eq "issues")
          {
          $issues = $vm_view->configIssue;

          if (defined($issues))
             {
             $output = "\"$vmname\": ";
             foreach (@$issues)
                     {
                     $output = $output . $_->fullFormattedMessage . "(caused by " . $_->userName . "); ";
                     }
             }
          else
             {
             $state = 0;
             $output = "$vmname has no config issues";
             }
          return ($state, $output);
          }
       get_me_out("Unknown VM RUNTIME subselect");
       }
    else
       {
       %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
       %vm_tools_status = ("toolsNotInstalled" => "Not installed", "toolsNotRunning" => "Not running", "toolsOk" => "0", "toolsOld" => "Old");
       %vm_guest_state = ("running" => "Running", "notRunning" => "Not running", "shuttingDown" => "Shutting down", "resetting" => "Resetting", "standby" => "Standby", "unknown" => "Unknown");
       $state = 0;
       $output = "$vmname status=" . $vm_view->overallStatus->val . ", run state=" . $vm_state_strings{$runtime->powerState->val} . ", guest state=" . $vm_guest_state{$vm_view->guest->guestState} . ", max cpu=" . $runtime->maxCpuUsage . " MHz, max mem=" . $runtime->maxMemoryUsage . " MB, console connections=" . $runtime->numMksConnections . ", tools status=" . $vm_tools_status{$vm_view->guest->toolsStatus->val} . ", ";
       $issues = $vm_view->configIssue;

       if (defined($issues))
          {
          $output = $output . @$issues . " config issue(s)";
          }
       else
          {
          $output = $output . "has no config issues";
          }
       }
       return ($state, $output);
    }

#==========================================================================| DC |============================================================================#


sub dc_list_vm_volumes_info
    {
    my ($blacklist, $whitelist) = @_;
    my $dc_views;
    my @datastores;
    my $dc;

    $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['datastore']);
    
    if (!defined($dc_views))
       {
       print "There are no Datacenter\n";
       exit 2;
       }

    foreach $dc (@$dc_views)
            {
            if (defined($dc->datastore))
               {
               push(@datastores, @{$dc->datastore});
               }
            }

    return datastore_volumes_info(\@datastores, $subselect, $blacklist, $whitelist);
    }


sub dc_runtime_info
{
        my ($blacklist) = @_;

        my $state = 2;
        my $output = 'DC RUNTIME Unknown error';
        my $runtime;

        if (defined($subselect))
        {
                if ($subselect eq "listvms")
                {
                        my %vm_state_strings = ("poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED");
                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'runtime']);

                        if (!defined($vm_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!@$vm_views)
                           {
                           print "There are no VMs.\n";
                           exit 2;
                           }

                        my $up = 0;
                        $output = '';

                        foreach my $vm (@$vm_views) {
                                my $vm_state = $vm_state_strings{$vm->runtime->powerState->val};
                                if ($vm_state eq "UP")
                                {
                                        $up++;
                                        $output = $output . $vm->name . "(UP), ";
                                }
                                else
                                {
                                        $output = $vm->name . "(" . $vm_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $up . "/" . @$vm_views . " VMs up: " . $output;
                        $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($up);
                           }
                }
                elsif ($subselect eq "listhost")
                {
                        my %host_state_strings = ("unknown" => "3", "poweredOn" => "UP", "poweredOff" => "DOWN", "suspended" => "SUSPENDED", "standBy" => "STANDBY", "MaintenanceMode" => "Maintenance Mode");
                        my $host_views = Vim::find_entity_views(view_type => 'HostSystem', properties => ['name', 'runtime.powerState']);

                        if (!defined($host_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!@$host_views)
                           {
                           print "There are no VMs.\n";
                           exit 2;
                           }

                        my $up = 0;
                        my $unknown = 0;
                        $output = '';

                        foreach my $host (@$host_views) {
                                $host->update_view_data(['name', 'runtime.powerState']);
                                my $host_state = $host_state_strings{$host->get_property('runtime.powerState')->val};
                                $unknown += $host_state eq "3";
                                if ($host_state eq "UP") {
                                        $up++;
                                        $output = $output . $host->name . "(UP), ";
                                }
                                else
                                {
                                        $output = $host->name . "(" . $host_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $up . "/" . @$host_views . " Hosts up: " . $output;
                        $perfdata = $perfdata . " hostcount=" . $up . ";" . $perf_thresholds . ";;";
 
                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($up);
                           }

                        if ($state == 0 && $unknown)
                           {
                           $state = 3;
                           }
                }
                elsif ($subselect eq "listcluster")
                {
                        my %cluster_state_strings = ("gray" => "3", "green" => "GREEN", "red" => "RED", "yellow" => "YELLOW");
                        my $cluster_views = Vim::find_entity_views(view_type => 'ClusterComputeResource', properties => ['name', 'overallStatus']);

                        if (!defined($cluster_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!@$cluster_views)
                           {
                           print "There are no Clusters.\n";
                           exit 2;
                           }

                        my $green = 0;
                        my $unknown = 0;
                        $output = '';

                        foreach my $cluster (@$cluster_views) {
                                $cluster->update_view_data(['name', 'overallStatus']);
                                my $cluster_state = $cluster_state_strings{$cluster->get_property('overallStatus')->val};
                                $unknown += $cluster_state eq "3";
                                if ($cluster_state eq "GREEN") {
                                        $green++;
                                        $output = $output . $cluster->name . "(GREEN), ";
                                }
                                else
                                {
                                        $output = $cluster->name . "(" . $cluster_state . "), " . $output;
                                }
                        }

                        chop($output);
                        chop($output);
                        $state = 0;
                        $output = $green . "/" . @$cluster_views . " Cluster green: " . $output;
                        $perfdata = $perfdata . " clustercount=" . $green . ";" . $perf_thresholds . ";;";

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($green);
                           }

                        if ($state == 0 && $unknown)
                           {
                           $state = 3;
                           }
                }
                elsif ($subselect eq "tools")
                {
                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'runtime.powerState', 'summary.guest']);

                        if (!defined($vm_views))
                           {
                           print "Runtime error\n";
                           exit 2;
                           }

                        if (!@$vm_views)
                           {
                           print "There are no VMs.\n";
                           exit 2;
                           }

                        $output = '';
                        my $tools_ok = 0;
                        my $vms_up = 0;
                        foreach my $vm (@$vm_views) {
                                my $name = $vm->name;
                                if (defined($blacklist))
                                {
                                        next if ($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/);
                                }
                                if ($vm->get_property('runtime.powerState')->val eq "poweredOn")
                                {
                                        my $vm_guest = $vm->get_property('summary.guest');
                                        my $tools_status;
                                        my $tools_runstate;
                                        my $tools_version;
                                        $tools_runstate = $vm_guest->toolsRunningStatus if (exists($vm_guest->{toolsRunningStatus}) && defined($vm_guest->toolsRunningStatus));
                                        $tools_version = $vm_guest->toolsVersionStatus if (exists($vm_guest->{toolsVersionStatus}) && defined($vm_guest->toolsVersionStatus));

                                        $vms_up++;
                                        if (defined($tools_runstate) || defined($tools_version))
                                        {
                                                my %vm_tools_strings = ("guestToolsCurrent" => "Newest", "guestToolsNeedUpgrade" => "Old", "guestToolsNotInstalled" => "Not installed", "guestToolsUnmanaged" => "Unmanaged", "guestToolsExecutingScripts" => "Starting", "guestToolsNotRunning" => "Not running", "guestToolsRunning" => "Running");
                                                $tools_status = $vm_tools_strings{$tools_runstate} . "-" if (defined($tools_runstate));
                                                $tools_status = $tools_status . $vm_tools_strings{$tools_version} . "-" if (defined($tools_version));
                                                chop($tools_status);
                                                if ($tools_status eq "Running-Newest")
                                                {
                                                        $output = $output . $name . "(Running-Newest), ";
                                                        $tools_ok++;
                                                }
                                                else
                                                {
                                                        $output = $name . "(" . $tools_status . "), " . $output;
                                                }
                                        }
                                        else
                                        {
                                                my %vm_tools_strings = ("toolsNotInstalled" => "Not installed", "toolsNotRunning" => "Not running", "toolsOk" => "0", "toolsOld" => "Old", "notDefined" => "Not defined");
                                                $tools_status = $vm_guest->toolsStatus;
                                                if (defined($tools_status))
                                                {
                                                        $tools_status = $vm_tools_strings{$tools_status->val};
                                                        if ($tools_status eq "0")
                                                        {
                                                                $output = $output . $name . "(0), ";
                                                                $tools_ok++;
                                                        }
                                                        else
                                                        {
                                                                $output = $name . "(" . $tools_status . "), " . $output;
                                                        }
                                                }
                                                else
                                                {
                                                        $output = $name . "(" . $vm_tools_strings{"notDefined"} . "), " . $output;
                                                }
                                        }
                                }
                        }
                        chop($output);
                        chop($output);
                        if ($vms_up)
                        {
                                $tools_ok /= $vms_up / 100;
                        }
                        else
                        {
                                $tools_ok = 100;
                        }

                        if ( $perf_thresholds eq 1 )
                           {
                           $state = check_against_threshold($tools_ok);
                           }

                        $perfdata = $perfdata . " toolsok=" . $tools_ok . "%;" . $perf_thresholds . ";;";
                }
                elsif ($subselect eq "status")
                {
                        my $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['name', 'overallStatus']);

                        if (!defined($dc_views))
                           {
                           print "There are no Datacenter\n";
                           exit 2;
                           }

                        $state = 0;
                        $output = '';
                        foreach my $dc (@$dc_views) {
                                if (defined($dc->overallStatus))
                                {
                                        my $status = $dc->overallStatus->val;
                                        $output = $output . $dc->name . " overall status=" . $status . ", ";
                                        $status = check_health_state($status);
                                        $state = 3 if ($status == 3);
                                        $state = check_state($state, $status) if (($state != 3) || ($status != 0));
                                }
                                else
                                {
                                        $output = $output . "Insufficient rights to access " . $dc->name . " status info on the DC, ";
                                        $state = check_state($state, 1);
                                }
                        }
                        if ($output) {
                                chop($output);
                                chop($output);
                        }
                }
                elsif ($subselect eq "issues")
                {
                        my $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['name', 'configIssue']);

                        if (!defined($dc_views))
                           {
                           print "There are no Datacenter\n";
                           exit 2;
                           }

                        my $issues_count = 0;
                        $output = '';

                        foreach my $dc (@$dc_views) {
                                my $issues = $dc->configIssue;

                                if (defined($issues))
                                {
                                        foreach (@$issues)
                                        {
                                                if (defined($blacklist))
                                                {
                                                        my $name = ref($_);
                                                        next if ($blacklist =~ m/(^|\s|\t|,)\Q$name\E($|\s|\t|,)/);
                                                }
                                                $output = $output . format_issue($_) . "(" . $dc->name . "); ";
                                                $issues_count++;
                                        }
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
                get_me_out("Unknown DC RUNTIME subselect");
                }
        }
        else
        {
                my $dc_views = Vim::find_entity_views(view_type => 'Datacenter', properties => ['name', 'overallStatus', 'configIssue']);

                if (!defined($dc_views))
                   {
                   print "There are no Datacenter\n";
                   exit 2;
                   }

                my %host_maintenance_state = (0 => "no", 1 => "yes");
                my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name', 'runtime.powerState']);

                if (!defined($vm_views))
                   {
                   print "Runtime error\n";
                   exit 2;
                   }

                my $up = 0;

                if (@$vm_views)
                {
                        foreach my $vm (@$vm_views) {
                                $up += $vm->get_property('runtime.powerState')->val eq "poweredOn";
                        }
                        $output = $up . "/" . @$vm_views . " VMs up, ";
                }
                else
                {
                        $output = "No VMs installed, ";
                }
                $perfdata = $perfdata . " vmcount=" . $up . ";" . $perf_thresholds . ";;";

                my $host_views = Vim::find_entity_views(view_type => 'HostSystem', properties => ['name', 'runtime.powerState']);

                if (!defined($host_views))
                   {
                   print "Runtime error\n";
                   exit 2;
                   }

                $up = 0;

                if (@$host_views)
                {
                        foreach my $host (@$host_views) {
                                $up += $host->get_property('runtime.powerState')->val eq "poweredOn"
                        }
                        $output = $output . $up . "/" . @$host_views . " Hosts up, ";
                }
                else
                {
                        $output = $output . "there are no hosts, ";
                }
                $perfdata = $perfdata . " hostcount=" . $up . ";;;;";

                $state = 0;

                foreach my $dc (@$dc_views) {
                        $output = $output . $dc->name . " overall status=" . $dc->overallStatus->val . ", " if (defined($dc->overallStatus));
                }

                my $issue_count = 0;
                foreach my $dc (@$dc_views) {
                        my $issues = $dc->configIssue;
                        $issue_count += @$issues if (defined($issues));
                }
                
                if ($issue_count)
                {
                        $output = $output . $issue_count . " config issue(s)";
                        $perfdata = $perfdata . " config_issues=" . $issue_count;
                }
                else
                {
                        $output = $output . "no config issues";
                        $perfdata = $perfdata . " config_issues=" . 0;
                }
        }

        return ($state, $output);
}

#=====================================================================| Cluster |============================================================================#

sub cluster_cpu_info
{
        my ($cluster) = @_;

        my $state = 2;
        my $output = 'CLUSTER CPU Unknown error';

        if (defined($subselect))
        {
                if ($subselect eq "usage")
                {
                        $values = return_cluster_performance_values($cluster, 'cpu', ('usage.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
                                $perfdata = $perfdata . " cpu_usage=" . $value . "%;" . $perf_thresholds . ";;";
                                $output = "cpu usage=" . $value . "%"; 
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "usagemhz")
                {
                        $values = return_cluster_performance_values($cluster, 'cpu', ('usagemhz.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value));
                                $perfdata = $perfdata . " cpu_usagemhz=" . $value . "Mhz;" . $perf_thresholds . ";;";
                                $output = "cpu usagemhz=" . $value . " MHz";
                                $state = check_against_threshold($value);
                        }
                }
                else
                {
                get_me_out("Unknown CLUSTER CPU subselect");
                }
        }
        else
        {
                $values = return_cluster_performance_values($cluster, 'cpu', ('usagemhz.average', 'usage.average'));
                if (defined($values))
                {
                        my $value1 = simplify_number(convert_number($$values[0][0]->value));
                        my $value2 = simplify_number(convert_number($$values[0][1]->value) * 0.01);
                        $perfdata = $perfdata . " cpu_usagemhz=" . $value1 . "Mhz;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " cpu_usage=" . $value2 . "%;" . $perf_thresholds . ";;";
                        $state = 0;
                        $output = "cpu usage=" . $value1 . " MHz (" . $value2 . "%)";
                }
        }

        return ($state, $output);
}

sub cluster_mem_info
{
        my ($cluster) = @_;

        my $state = 2;
        my $output = 'CLUSTER MEM Unknown error';

        if (defined($subselect))
        {
                if ($subselect eq "usage")
                {
                        $values = return_cluster_performance_values($cluster, 'mem', ('usage.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) * 0.01);
                                $perfdata = $perfdata . " mem_usage=" . $value . "%;" . $perf_thresholds . ";;";
                                $output = "mem usage=" . $value . "%"; 
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "usagemb")
                {
                        $values = return_cluster_performance_values($cluster, 'mem', ('consumed.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
                                $perfdata = $perfdata . " mem_usagemb=" . $value . "MB;" . $perf_thresholds . ";;";
                                $output = "mem usage=" . $value . " MB";
                                $state = check_against_threshold($value);
                        }
                }
                elsif ($subselect eq "swap")
                {
                        my $cluster_view;
                        ($cluster_view, $values) = return_cluster_performance_values($cluster, 'mem', ('swapused.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
                                $perfdata = $perfdata . " mem_swap=" . $value . "MB;" . $perf_thresholds . ";;";
                                $output = "swap usage=" . $value . " MB: ";
                                $state = check_against_threshold($value);
                                if ($state != 0)
                                {
                                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $$cluster_view[0], properties => ['name', 'runtime.powerState']);

                                        if (!defined($vm_views))
                                           {
                                           print "Runtime error\n";
                                           exit 2;
                                           }

                                        if (!@$vm_views)
                                           {
                                           print "There are no VMs.\n";
                                           exit 2;
                                           }

                                        my @vms = ();
                                        foreach my $vm (@$vm_views)
                                        {
                                                push(@vms, $vm) if ($vm->get_property('runtime.powerState')->val eq "poweredOn");
                                        }
                                        $values = generic_performance_values(\@vms, 'mem', ('swapped.average'));
                                        if (defined($values))
                                        {
                                                foreach my $index (0..@vms-1) {
                                                        my $value = simplify_number(convert_number($$values[$index][0]->value) / 1024);
                                                        $output = $output . $vms[$index]->name . " (" . $value . "MB), " if ($value > 0);
                                                }
                                        }
                                }
                                chop($output);
                                chop($output);
                        }
                }
                elsif ($subselect eq "memctl")
                {
                        my $cluster_view;
                        ($cluster_view, $values) = return_cluster_performance_values($cluster, 'mem', ('vmmemctl.average'));
                        if (defined($values))
                        {
                                my $value = simplify_number(convert_number($$values[0][0]->value) / 1024);
                                $perfdata = $perfdata . " mem_memctl=" . $value . "MB;" . $perf_thresholds . ";;";
                                $output = "memctl=" . $value . " MB: ";
                                $state = check_against_threshold($value);
                                if ($state != 0)
                                {
                                        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', begin_entity => $$cluster_view[0], properties => ['name', 'runtime.powerState']);

                                        if (!defined($vm_views))
                                           {
                                           print "Runtime error\n";
                                           exit 2;
                                           }

                                        if (!@$vm_views)
                                           {
                                           print "There are no VMs.\n";
                                           exit 2;
                                           }

                                        my @vms = ();
                                        foreach my $vm (@$vm_views)
                                        {
                                                push(@vms, $vm) if ($vm->get_property('runtime.powerState')->val eq "poweredOn");
                                        }
                                        $values = generic_performance_values(\@vms, 'mem', ('vmmemctl.average'));
                                        if (defined($values))
                                        {
                                                foreach my $index (0..@vms-1) {
                                                        my $value = simplify_number(convert_number($$values[$index][0]->value) / 1024);
                                                        $output = $output . $vms[$index]->name . " (" . $value . "MB), " if ($value > 0);
                                                }
                                        }
                                }
                                chop($output);
                                chop($output);
                        }
                }
                else
                {
                get_me_out("Unknown CLUSTER MEM subselect");
                }
        }
        else
        {
                $values = return_cluster_performance_values($cluster, 'mem', ('consumed.average', 'usage.average', 'overhead.average', 'swapused.average', 'vmmemctl.average'));
                if (defined($values))
                {
                        my $value1 = simplify_number(convert_number($$values[0][0]->value) / 1024);
                        my $value2 = simplify_number(convert_number($$values[0][1]->value) * 0.01);
                        my $value3 = simplify_number(convert_number($$values[0][2]->value) / 1024);
                        my $value4 = simplify_number(convert_number($$values[0][3]->value) / 1024);
                        my $value5 = simplify_number(convert_number($$values[0][4]->value) / 1024);
                        $perfdata = $perfdata . " mem_usagemb=" . $value1 . "MB;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " mem_usage=" . $value2 . "%;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " mem_overhead=" . $value3 . "MB;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " mem_swap=" . $value4 . "MB;" . $perf_thresholds . ";;";
                        $perfdata = $perfdata . " mem_memctl=" . $value5 . "MB;" . $perf_thresholds . ";;";
                        $state = 0;
                        $output = "mem usage=" . $value1 . " MB (" . $value2 . "%), overhead=" . $value3 . " MB, swapped=" . $value4 . " MB, memctl=" . $value5 . " MB";
                }
        }

        return ($state, $output);
}

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
                                $unknown += $host_state eq "3";
                                if ($host_state eq "UP" && $host_state eq "Maintenance Mode") {
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

sub cluster_list_vm_volumes_info
{
        my ($cluster, $blacklist) = @_;

        my $cluster_view = Vim::find_entity_view(view_type => 'ClusterComputeResource', filter => {name => "$cluster"}, properties => ['name', 'datastore']);

        if (!defined($cluster_view->datastore))
           {
           print "Insufficient rights to access Datastores on the Host\n";
           exit 2;
           }

        return datastore_volumes_info($cluster_view->datastore, $subselect, $blacklist);
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
    
