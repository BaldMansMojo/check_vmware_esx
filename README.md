check_vmware_esx.pl
===================

chech_vmware_esx.pl - a fork of check_vmware_api.pl


General
=======

Why a fork? According to my personal unterstanding Nagios, Icingia etc. are tools for

a) Monitoring and alarming. That means checking values against thresholds (internal or handed over)
b) Collecting performance data. These data, collected with the checks, like network traffic, cpu usage or so should be
   interpretable without a lot of other data.

Athough check_vmware_api.pl is a great plugin it suffers from various things.
a) It acts as a monitoring plugin for Nagios etc.
b) It acts a more comfortable commandline interfacescript.
c) It collects all a lot of historical data to have all informations in one interface.

While a) is ok b) and c) needs to be discussed. b) was necessary when you had only the Windows GUI and working on Linux
meant "No interface". this is obsolete now with the new webgui.

c) will be better used by using the webgui because historical data (in most situations) means adjusted data. Most of these
collected data is not feasible for alerting but for analysing performance gaps.

So as a conclusion collecting historic performance data collected by a monitored system should not be done using Nagios,
pnp4nagios etc.. It should be interpreted with the approriate admin tools of the relevant system. For vmware it means use
the (web)client for this and not Nagios. Same for performance counters not self explaining.

Example:
Monitoring swapped memory of a vmware guest system seems to makes sense. But on the second look it doesn't because on Nagios
you do not have the surrounding conditions in one view like
- the number of the running guest systems on the vmware server.
- the swap every guest system needs
- the total space allocated for all systems
- swap/memory usage of the hostcheck_vmware_esx.pl
- and a lot more

So monitoring memory of a host makes sense but the same for the guest via vmtools makes only a limited sense.

But this were only a few problems. Furthermore we had

- misleading descriptions
- things monitored for hosts but not for vmware servers
- a lot of absolutely unnesseary performance data (who needs a performane graph for uptime?)
- unnessessary output (CPU usage in Mhz for example)
- and a lot more.

This plugin is old and big and cluttered like the room of my little son.  So it was time for some house cleaning.
I try to clean up the code of every routine, change things and will try to ease maintenance of the code.

The plugin is not really ready but working. Due to the mass
of options the help module needs work.

See history for changes

One last notice for technical issues. For better maintenance (and partly improved runtime)
I have decided to modularize the plugin. It makes patching a lot easier. Modules which must be there every time are
included with use, the others are include using require at runtime. This ensures that only
that part of code is loaded which is needed.


Installation
============

First install the VMware Perl SDK.
----------------------------------

- Download the SDK from vmware.
  - Go to [www.vmware.com](www.vmware.com) -> Downloads -> "All downloads,drivers & tools""
  - Search for "Perl SDK"
  - Download the appropriate Perl SDK for your release (the SDK is free but you have to register yourself for this).
  - Install it. (Installation guide can be found here: http://www.vmware.com/support/developer/viperltoolkit/)
  

Second install the plugin
-------------------------
  
- Download the archive (.zip from github or .tar.gz/.tgz from other locations) and unpack it in a location suitable for you.

It is recommended not to merge third party plugins with plugins deliverd by Nagios/Icingia/Shinken etc.. So it is a good practice
to have seperate directories for your own and/or third party plugins.

Ensure the the path to the perl interpreter in the program is set to the right perl executable on your system.

-> Adjust the path for the modules directory (use lib "modules") to fit your system (for example: use lib "/usr/local/libexec/myplugins/modules")
-> If using a session file adjust the path for the sessionfile ($plugin_cache in variable definition)


Optional
--------

Some people prefer a single file instead of modules. Use this makefile for Sven Nierlein to generate a single file plugin. Maybe it is a little
bit slower than the modularized version. Test it.If you open issues in GitHub be careful with line numbers and so on.


HTML in output
==============

HTML in output is caused by the option --multiline or in some situtations where you need a multiline output in the service overview window. 
So here a <br> tag is used to have a line break. Using --multiline will always cause a <br> instead of \n. (Remember - having a standard multiline
output from a plugin only the first line will be displayed in the overwiew window. The rest is with the details view).

The HTML tags must be filtered out before using the output in notifications like an email. sed will do the job:

sed 's/<[Bb][Rr]>/&\n/g' | sed 's/<[^<>]*>//g'

Example:
--------

# 'notify-by-email' command definition
define command{
	command_name	notify-by-email
	command_line	/usr/bin/printf "%b" "Message from Nagios:\n\nNotification Type: $NOTIFICATIONTYPE$\n\nService: $SERVICEDESC$\nHost: $HOSTNAME$\nHostalias: $HOSTALIAS$\nAddress: $HOSTADDRESS$\nState: $SERVICESTATE$\n\nDate/Time: $SHORTDATETIME$\n\nAdditional Info:\n\n$SERVICEOUTPUT$\n$LONGSERVICEOUTPUT$" | sed 's/<[Bb][Rr]>/&\n/g' | sed 's/<[^<>]*>//g' | /bin/mail -s "** $NOTIFICATIONTYPE$ alert - $HOSTNAME$/$SERVICEDESC$ is $SERVICESTATE$ **" $CONTACTEMAIL$
	}


Using a sessionfile
===================

To reduce amounts of login/logout events in the vShpere logfiles or a lot of open sessions using sessionfiles the login part has been totally
rewritten with version 0.9.8..

Using session files is now the default. Only one session file per host or vCenter is used as default. The sessionfile name is automatically set
to the vSphere host or the vCenter (IP or name - whatever is used in the check).

Multiple sessions are possible using different session file names. To form different session file names the default name is enhenced by the value
you set with --sessionfile.

NOTICE! All checks using the same session are serialized. So a lot of checks using only one session can cause timeouts. In this case you should
enhence the number of sessions by using --sessionfile in the command definition and define the value in the service definition command as an extra
argument so it can be used in the command definition as $ARGn$.

--sessionfile is now optional and only used to enhance the sessionfile name to have multiple sessions.

If a session logs in it sets a lock file (sessionfilename_locked). The lock file is been set when the session starts and removed at the end of the
plugin run. A newly started check looks for the lock file and waits until it is no longer there. So here we have a serialization now. It will not
hang forever due to the alarm routine. Therefore the default for the timeout is enhenced to 40 secs. instead of 30 secs..

Example command and service check definition:
----------------------------------------------

define command{
       command_name    check_vsphere_health
       command_line    /MyPluginPath/check_vmware_esx.pl -H $HOSTADDRESS$ -u $ARG1$ -p $ARG2$ -S runtime -s health
       }


define service{
       active_checks_enabled           1
       passive_checks_enabled          1
       parallelize_check               1
       obsess_over_service             1
       check_freshness                 0
       notifications_enabled           1
       event_handler_enabled           1
       flap_detection_enabled          1
       process_perf_data               0
       retain_status_information       1
       retain_nonstatus_information    1
       
       host_name                       vmsrv1
       service_description             Health
       is_volatile                     0
       check_period                    24x7
       max_check_attempts              5
       normal_check_interval           5
       retry_check_interval            1
       contact_groups                  sysadmins
       notification_interval           1440
       notification_period             24x7
       notification_options            c,w,r
       check_command                   check_vsphere_health!Nagios!MyMonitorPassword
       }

Example for session file name and lock file name:
-------------------------------------------------
192.168.10.12_session (default)
192.168.10.12_session_locked (default)


Example caommand and service check definition (enhenced):
---------------------------------------------------------

define command{
       command_name    check_vsphere_health
       command_line    /MyPluginPath/check_vmware_esx.pl -H $HOSTADDRESS$ -u $ARG1$ -p $ARG2$ -S runtime -s health --sessionfile=$ARG3$
       }


define service{
       active_checks_enabled           1
       passive_checks_enabled          1
       parallelize_check               1
       obsess_over_service             1
       check_freshness                 0
       notifications_enabled           1
       event_handler_enabled           1
       flap_detection_enabled          1
       process_perf_data               0
       retain_status_information       1
       retain_nonstatus_information    1
       
       host_name                       vmsrv1
       service_description             Health
       is_volatile                     0
       check_period                    24x7
       max_check_attempts              5
       normal_check_interval           5
       retry_check_interval            1
       contact_groups                  sysadmins
       notification_interval           1440
       notification_period             24x7
       notification_options            c,w,r
       check_command                   check_vsphere_health!Nagios!MyMonitorPassword!healthchecks
       }

Example for session file name and lock file name:
-------------------------------------------------
192.168.10.12_healthchecks_session (enhenced)
192.168.10.12_healthchecks_session_locked (enhenced)


Optional a path different from the default one can be set with --sessionfilename=<directory>.


Storage
=======

The module host_storage_info.pm (contains host_storage_info()) is a extensive rewrite. Most of the code was rewritten. It now tested with iSCSI by
customers and it is reported to run without problems.

Multipath:
- - - - - 

The orignial version was as buggy and misleading as a piece of code can be. A threshold here was absolute nonsense. Why? At top level is a LUN which
has a SCSI-ID. This LUN is connected to the storage in a SAN with a virtual path called a multipath because it consists of several physical
connections(physical paths). I f you break down the data deliverd by VMware you will see that in the section for each physical path the associated
multipath with it's state was also listed. check_vmware_api.pl (and check_esx3.pl) counted all those multipath entry. For example if you had 4 physical
paths for one multipath the counted 4 multipaths and checked the multipath state. This was absolute nonsense because (under normal conditions) a 
multipath state is is only dead if all physical paths (4 in the example) are dead.

The new check checks the state of the multipath AND the state of the physical paths. So for example if you have two parallel FC switches in a multipath
environment and one is dead the multipath state is still ok but you will get an alarm now for the broken connection regardless if a switch, a line or a 
controller is broken.

This is much more detailed then counting lines.


Help
====

A lot of general options is listed more than once. Why? The help is very complex and large. By having all options for a a select/subselect listed
nearby we avoid scrolling up/down and minimize confusion which (general) option is valid.

Notice
======
Cluster part is not completly rewritten. Volume is rewritten, runtime works but the rest needs attention.
