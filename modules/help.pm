sub print_usage
    {
    print "Usage:\n";
    }

sub version_lic
    {
    print "\n";
    print "$ProgName,Version $prog_version\n";
    print "\n";
    print "This vmware Infrastructure monitoring plugin is free software, and comes with ABSOLUTELY NO WARRANTY.\n";
    print "It may be used, redistributed and/or modified under the terms of the GNU General Public Licence \n";
    print "(see http://www.fsf.org/licensing/licenses/gpl.txt).\n\n";
    print "Copyright (c) 2013 all modifications starting from check_vmware_api.pl Martin Fuerstenau - Oce Printing Systems <martin.fuerstenau\@oce.com>\n";
    print "Copyright (c) 2008 op5 AB Kostyantyn Hushchyn <dev\@op5.com>\n";
    print "\n";
    }

sub help_options
    {
    print "   -h|--help=<all>                    The complete help for all.\n";
    print "   -h|--help=<dc|datacenter|vcenter>  Help for datacenter/vcenter checks.\n";
    print "   -h|--help=<host>                   Help for vmware host checks.\n";
    print "   -h|--help=<vm>                     Help for virtual machines checks.\n";
    print "   -h|--help=<cluster>                Help for cluster checks.\n";
    }

sub hint
    {
    print "\n";
    print "Some general information:\n";
    print "There are options like -B, --exclude=<black_list>, -W, --include=<white_list>,--isregexp or --multiline. These options are implemented for ";
    print "some selects/subselects but not for all. To make it more handy for the user and to avoid paging up and down we have listed these options more ";
    print "than once. So for every select statement all the options are listed that can be used there\n";
    print "\n";
    print "Example:\n";
    print "\n";
    print "    Host service info:\n";
    print "    ------------------\n";
    print "    -S, --select=service                shows host service info.\n";
    print "    -B, --exclude=<black_list>          blacklist services.\n";
    print "    -W, --include=<white_list>          whitelist services.\n";
    print "        --isregexp                      whether to treat blacklist and whitelist as regexp\n";
    print "        --multiline                     Multiline output in overview. This mean technically that\n";
    print "                                        a multiline output uses a HTML <br> for the GUI instead of\n";
    print "                                        Be aware that your messing connections (email, SMS...) must use\n";
    print "                                        a filter to file out the <br>. A sed oneliner like the following\n";
    print "                                        will do the job: sed 's/<[^<>]*>//g'\n";
    print "\n";
    }

sub print_help
    {
    my ($section) = @_;
    my $page;
    
    if ($section =~ m/^[a-z].*$/i)
       {
       $section = lc($section);
       if (!(($section eq "dc") || ($section eq "datacenter") || ($section eq "vcenter") || ($section eq "host") || ($section eq "vm") || ($section eq "all") || ($section eq "cluster")))
          {
          print "\n$section is not a valid value for help. Valid values are:\n\n";
          help_options();
          version_lic();
          exit 1;
          }
       }
    else
       {
       print "\nBecause the output of the complete help is very large you have to select what you want:\n\n";
       help_options();
       print "<--Hit enter for next page-->";
       $page = <STDIN>;
       undef $page;
       hint();
       print "<--Hit enter for next page-->";
       $page = <STDIN>;
       undef $page;
       version_lic();
       exit 0;
       }

    if (($section eq "dc") || ($section eq "datacenter") || ($section eq "vcenter") || ($section eq "host") || ($section eq "vm") || ($section eq "all") || ($section eq "cluster"))
       {
       version_lic();
       print "General options:\n";
       print "================\n";
       print "\n";
       print "-?, --usage                          Print usage information\n";
       print "-h, --help                           Print detailed help screen\n";
       print "-V, --version                        Print version information\n";
       print "--ignore_unknown                     Sometimes 3 (unknown) is returned from a component.\n";
       print "                                     But the check itself is ok.\n";
       print "                                     With this option the plugin will return 0 (0) instead of 3 (3).\n";
       print "-t, --timeout=INTEGER                Seconds before plugin times out (default: 30)\n";
       print "    --trace=<level>                  Set verbosity level of vSphere API request/respond trace.\n";
       print "\n";

       print "Options for authentication:\n";
       print "===========================\n";
       print "\n";
       print "     --sessionfile=<sessionfile>     If this option is set a session file will be used for login. The name will \n";
       print "                                     be generated automatically. A good idea is to use the servicedescription. It is \n";
       print "                                     combined with the hostname and so it is dynamic for every service.\n";
       print "     --sessionfiledir=<directory>    If this option is set a path different from the path stored in \$nagios_plugin_cache\n";
       print "                                     will be used.\n";
       print "-u, --username=<username>            Username to connect with.\n";
       print "-p, --password=<password>            Password to use with the username.\n";
       print "-f, --authfile=<path>                Authentication file with login and password.\n";
       print "                                     File syntax :\n";
       print "                                     username=<login>\n";
       print "                                     password=<password>\n";
       print "\n";
       }

#--- Data Center ----------------------

    if (($section eq "dc") || ($section eq "datacenter") || ($section eq "vcenter") || ($section eq "all"))
       {
       print "Monitoring the vmware datacenter:\n";
       print "=================================\n";
       print "\n";
       print "-D, --datacenter=<DCname>           Datacenter/Vcenter hostname.\n";
       print "    --sslport=<port>                If a SSL port different from 443 is used.\n";
       print "\n";
       print "Volumes:\n";
       print "--------\n";
       print "\n";
       print "-S, --select=volumes                Shows all datastore volumes info\n";
       print "\n";
       print "-s, --subselect=<name>              free space info for volume with name <name>\n\n";
       print "    --usedspace                     Output used space instead of free\n";
       print "    --alertonly                     List only alerting volumes\n";
       print "-B, --exclude=<black_list>          Blacklist volumes.\n";
       print "-W, --include=<white_list>          Whitelist volumes.\n";
       print "    --isregexp                      Whether to treat name, blacklist and whitelist as regexp\n";
       print "-w, --warning=<threshold>           Warning threshold.\n";
       print "-c, --critical=<threshold>          Critical threshold.\n";
       print "                                    Thresholds should be either a simple counter or a percentage value in the nn% (i.e. 90%).\n";
       print "                                    If checking more than a single volume only percent is alloed as threshold.\n";
       print "\n";
   
       print "        * runtime - shows all runtime info(except cluster and tools and no thresholds)\n";
       print "            + listvms - list of vmware machines and their statuses\n";
       print "            + listhost - list of vmware esx host servers and their statuses\n";
       print "            + listcluster - list of vmware clusters and their statuses\n";
       print "            + tools - vmware Tools status\n";
   
       print "            + status - overall object status (gray/green/red/yellow)\n";
       print "            + issues - all issues for the host\n";
   
       print "SOAP API:\n";
       print "---------\n";
       print "\n";
       print "-S, --select=soap                   simple check to verify a successfull connection\n";
       print "                                    to VMWare SOAP API.\n";
       print "\n";
       }

#--- Host ----------------------

    if (($section eq "host") || ($section eq "all"))
       {
       print "Monitoring the vmware host:\n";
       print "===========================\n";
       print "\n";
       print "-H, --host=<hostname>               ESX or ESXi hostname.\n";
       print "    --sslport=<port>                If a SSL port different from 443 is used.\n";
       print "\n";
       print "Uptime:\n";
       print "-------\n";
       print "\n";
       print "-S, --select=uptimeu                Displays uptime of the vmware host.\n";
       print "or with\n";
       print "\n";
       print "CPU:\n";
       print "----\n";
       print "\n";
       print "-S, --select=cpu                    CPU usage in percentage\n";
       print "or with\n";
       print "-s, --subselect=ready               Percentage of time that the virtual machine was\n";
       print "                                    ready, but could not get scheduled to run on the\n";
       print "                                    physical CPU. CPU ready time is dependent on the\n";
       print "                                    number of virtual machines on the host and their\n";
       print "                                    CPU loads. High or growing ready time can be a\n";
       print "                                    hint CPU bottlenecks\n";
       print "or\n";
       print "-s, --subselect=wait                CPU time spent in wait state. The wait total includes\n";
       print "                                    time spent the CPU idle, CPU swap wait, and CPU I/O\n";
       print "                                    wait states. High or growing wait time can be a\n";
       print "                                    hint I/O bottlenecks.\n";
       print "\n";
       print "Memory:\n";
       print "-------\n";
       print "\n";
       print "-S, --select=mem                    All mem info(except overall and no thresholds)\n";
       print "or with\n";
       print "-s, --subselect=usage               Average mem usage in percentage\n";
       print "or\n";
       print "-s, --subselect=consumed            Amount of machine memory used on the host. Consumed\n";
       print "                                    memory includes Includes memory used by the Service\n";
       print "                                    Console, the VMkernel vSphere services, plus the\n";
       print "                                    total consumed metrics for all running virtual\n";
       print "                                    machines in MB\n";
       print "or\n";
       print "-s, --subselect=swapused            Amount of memory that is used by swap. Sum of memory\n";
       print "                                    swapped of all powered on VMs and vSphere services\n";
       print "                                    on the host in MB\n";
       print "or\n";
       print "-s, --subselect=overhead            Additional mem used by VM Server in MB\n";
       print "or\n";
       print "-s, --subselect=memctl              The sum of all vmmemctl values in MB for all powered-on\n";
       print "                                    virtual machines, plus vSphere services on the host.\n";
       print "                                    If the balloon target value is greater than the balloon\n";
       print "                                    value, the VMkernel inflates the balloon, causing more\n";
       print "                                    virtual machine memory to be reclaimed. If the balloon\n";
       print "                                    target value is less than the balloon value, the VMkernel\n";
       print "                                    deflates the balloon, which allows the virtual machine to\n";
       print "                                    consume additional memory if needed.used by VM memory\n";
       print "                                    control driver.\n";
       print "\n";
       print "Network:\n";
       print "-------\n";
       print "\n";
       print "-S, --select=net                    Shows net info\n";
       print "or with\n";
       print "-s, --subselect=usage               Overall network usage in KBps(Kilobytes per Second).\n";
       print "or\n";
       print "-s, --subselect=receive             Receive in KBps(Kilobytes per Second).\n";
       print "or\n";
       print "-s, --subselect=send                Send in KBps(Kilobytes per Second).\n";
       print "or\n";
       print "-s, --subselect=nic                 Check all active NICs.\n";
       print "\n";
       print "Volumes:\n";
       print "--------\n";
       print "\n";
       print "-S, --select=volumes                Shows all datastore volumes info\n";
       print "or with\n";
       print "-s, --subselect=<name>              Free space info for volume with name <name>\n\n";
       print "    --gigabyte                      Output in GB instead of MB\n";
       print "    --usedspace                     Output used space instead of free\n";
       print "    --alertonly                     List only alerting volumes\n";
       print "-B, --exclude=<black_list>          Blacklist volumes.\n";
       print "-W, --include=<white_list>          Whitelist volumes.\n";
       print "    --isregexp                      Whether to treat name, blacklist and whitelist as regexp\n";
       print "-w, --warning=<threshold>           Warning threshold.\n";
       print "-c, --critical=<threshold>          Critical threshold.\n";
       print "                                    Thresholds should be either a simple counter or a percentage value in the nn% (i.e. 90%).\n";
       print "                                    If checking more than a single volume only percent is alloed as threshold.\n";
       print "\n";
       print "Disk I/O:\n";
       print "---------\n";
       print "\n";
       print "-S, --select=io                     Shows all disk io info. Without subselect no thresholds\n";
       print "                                    can be checked. All I/O values are aggregated from historical\n";
       print "                                    intervals over the past 24 hours with a 5 minute sample rate\n";
       print "or with\n";
       print "-s, --subselect=aborted             Number of aborted SCSI commands\n";
       print "or\n";
       print "-s, --subselect=resets              Number of SCSI bus resets\n";
       print "or\n";
       print "-s, --subselect=read                Average number of kilobytes read from the disk each second\n";
       print "                                    Rate at which data is read from each LUN on the host.\n";
       print "                                    read rate = # blocksRead per second x blockSize\n";
       print "                                    issued from the Guest OS to the virtual machine. The sum\n";
       print "                                    of kernelReadLatency and deviceReadLatency.\n";
       print "or\n";
       print "-s, --subselect=read_latency        Average amount of time (ms) to process a SCSI read command\n";
       print "                                    issued from the Guest OS to the virtual machine. The sum\n";
       print "                                    of kernelReadLatency and deviceReadLatency.\n";
       print "or\n";
       print "-s, --subselect=write               Average number of kilobytes written to disk each second.\n";
       print "                                    Rate at which data is written to each LUN on the host.\n";
       print "                                    write rate = # blocksRead per second x blockSize\n";
       print "or\n";
       print "-s, --subselect=write_latency       Average amount of time (ms) taken to process a SCSI write\n";
       print "                                    command issued by the Guest OS to the virtual machine. The\n";
       print "                                    sum of kernelWriteLatency and deviceWriteLatency.\n";
       print "or\n";
       print "-s, --subselect=usage               Aggregated disk I/O rate. For hosts, this metric includes\n";
       print "                                    the rates for all virtual machines running on the host\n";
       print "or\n";
       print "-s, --subselect=kernel_latency      Average amount of time (ms) spent by VMkernel processing\n";
       print "                                    each SCSI command.\n";
       print "or\n";
       print "-s, --subselect=device_latency      Average amount of time (ms) to complete a SCSI command\n";
       print "                                    from the physical device\n";
       print "or\n";
       print "-s, --subselect=queue_latency       Average amount of time (ms) spent in the VMkernel queue,\n";
       print "                                    per SCSI command, during thequeue latency in ms\n";
       print "\n";
       print "Host mounted media:\n";
       print "-------------------\n";
       print "\n";
       print "-S, --select=hostmedia              List vm's with attached host mounted media like cd,dvd or\n";
       print "                                    floppy drives. This is important for monitoring because a\n";
       print "                                    virtual machine with a mount cd or dvd drive can not be\n";
       print "                                    moved to another host.\n";
       print "-B, --exclude=<black_list>          Blacklist VMs.\n";
       print "-W, --include=<white_list>          Whitelist VMs.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "    --listall                       List all VMs with all mounted media.\n";
       print "    --multiline                     Multiline output in overview. This mean technically that\n";
       print "                                    a multiline output uses a HTML <br> for the GUI instead of\n";
       print "                                    Be aware that your messing connections (email, SMS...) must use\n";
       print "                                    a filter to file out the <br>. A sed oneliner like the following\n";
       print "                                    will do the job: sed 's/<[^<>]*>//g'\n";
       print "\n";
       print "Service info:\n";
       print "-------------\n";
       print "-S, --select=service                Shows host service info.\n";
       print "-B, --exclude=<black_list>          Blacklist services.\n";
       print "-W, --include=<white_list>          Whitelist services.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "    --multiline                     Multiline output in overview. This mean technically that\n";
       print "                                    a multiline output uses a HTML <br> for the GUI instead of\n";
       print "                                    Be aware that your messing connections (email, SMS...) must use\n";
       print "                                    a filter to file out the <br>. A sed oneliner like the following\n";
       print "                                    will do the job: sed 's/<[^<>]*>//g'\n";
       print "\n";
       print "Runtime info:\n";
       print "-------------\n";
       print "\n";
       print "\n";
       print "-S, --select=runtime                Shows runtime info. Used without -s show all runtime info:\n";
       print "                                    VMs, overall status, connection state, health, storagehealth, temperature\n";
       print "                                    and sensor are represented as one value and without thresholds.\n";
       print "or with\n";
       print "-s, --subselect=con                 Shows connection state.\n";
       print "or\n";
       print "-s, --subselect=listvms             List of vmware machines and their statuses.\n";
       print "-B, --exclude=<black_list>          Blacklist VMs.\n";
       print "-W, --include=<white_list>          Whitelist VMs.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "    --multiline                     Multiline output in overview. This mean technically that\n";
       print "                                    a multiline output uses a HTML <br> for the GUI instead of\n";
       print "                                    Be aware that your messing connections (email, SMS...) must use\n";
       print "                                    a filter to file out the <br>. A sed oneliner like the following\n";
       print "                                    will do the job: sed 's/<[^<>]*>//g'\n";
       print "or\n";
       print "-s, --subselect=status              Overall object status (gray/green/red/yellow).\n";
       print "or\n";
       print "-s, --subselect=health              Checks cpu/storage/memory/sensor status.\n";
       print "    --listsensors                   List all available sensors(use for listing purpose only)\n";
       print "-B, --exclude=<black_list>          Blacklist storage, memory and sensors.\n";
       print "-W, --include=<white_list>          Whitelist storage, memory and sensors.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "or\n";
       print "-s, --subselect=storagehealth       Local(!) storage status check.\n";
       print "-B, --exclude=<black_list>          Blacklist storage.\n";
       print "-W, --include=<white_list>          Whitelist storage.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "    --multiline                     Multiline output in overview. This mean technically that\n";
       print "                                    a multiline output uses a HTML <br> for the GUI instead of\n";
       print "                                    Be aware that your messing connections (email, SMS...) must use\n";
       print "                                    a filter to file out the <br>. A sed oneliner like the following\n";
       print "                                    will do the job: sed 's/<[^<>]*>//g'\n";
       print "or\n";
       print "-s, --subselect=temp                Lists all temperature sensors.\n";
       print "-B, --exclude=<black_list>          Blacklist sensors.\n";
       print "-W, --include=<white_list>          Whitelist sensors.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "    --multiline                     Multiline output in overview. This mean technically that\n";
       print "                                    a multiline output uses a HTML <br> for the GUI instead of\n";
       print "                                    Be aware that your messing connections (email, SMS...) must use\n";
       print "                                    a filter to file out the <br>. A sed oneliner like the following\n";
       print "                                    will do the job: sed 's/<[^<>]*>//g'\n";
       print "or\n";
       print "-s, --subselect=issues              Lists all configuration issues for the host.\n";
       print "-B, --exclude=<black_list>          Blacklist configuration issues.\n";
       print "-W, --include=<white_list>          Whitelist configuration issues.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "\n";
       print "Storage info:\n";
       print "-------------\n";
       print "\n";
       print "-S, --select=storage                Shows Host storage info.\n";
       print "\n";
       print "                                    BEWARE!! Without a subselect only a summary will be listed.\n";
       print "                                    Larger environments in SAN systems can cause trouble displaying the\n";
       print "                                    informations needed due to the mass of data even when used with subselects\n";
       print "                                  . Use --alertonly to avoid this.\n";
       print "\n";
       print "-B, --exclude=<black_list>          Blacklist adapters, luns (use blacklist on canonical names for it)\n";
       print "                                    and paths. All items can be in one blacklist. Beware of regexp.\n";
       print "                                    A given regexp must give a destinct result.\n";
       print "-W, --include=<white_list>          Whitelist adapters, luns (use whitelist on canonical names for it)\n";
       print "                                    and paths. All items can be in one whitelist. Beware of regexp.\n";
       print "                                    A given regexp must give a destinct result.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "or with\n";
       print "-s, --subselect=adapter             List host bus adapters.\n";
       print "-B, --exclude=<black_list>          Blacklist adapters. Blacklisted adapters will not be displayed.\n";
       print "-W, --include=<white_list>          Whitelist adapters.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "    --multiline                     Multiline output in overview. This mean technically that\n";
       print "                                    a multiline output uses a HTML <br> for the GUI instead of\n";
       print "                                    Be aware that your messing connections (email, SMS...) must use\n";
       print "                                    a filter to file out the <br>. A sed oneliner like the following\n";
       print "                                    will do the job: sed 's/<[^<>]*>//g'\n";
       print "or with\n";
       print "-s, --subselect=lun                 List SCSI logical units. The listing will include:\n";
       print "                                    - LUN\n";
       print "                                    - canonical name of the disc\n";
       print "                                    - all of displayed name which is not part of the canonical name\n";
       print "                                    - the status\n";
       print "-B, --exclude=<black_list>          Blacklist luns (use blacklist on canonical names for it).\n";
       print "                                    Blacklisted luns will not be displayed.\n";
       print "-W, --include=<white_list>          Whitelist luns (use whitelist on canonical names for it).\n";
       print "                                    Only whitelisted adapters will be displayed.\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "    --alertonly                     List only alerting units. Important here to avoid masses of data.\n";
       print "    --multiline                     Multiline output in overview. This mean technically that\n";
       print "                                    a multiline output uses a HTML <br> for the GUI instead of\n";
       print "                                    Be aware that your messing connections (email, SMS...) must use\n";
       print "                                    a filter to file out the <br>. A sed oneliner like the following\n";
       print "                                    will do the job: sed 's/<[^<>]*>//g'\n";
       print "or with\n";
       print "-s, --subselect=path                List multipaths and the associated paths.\n";
       print "-B, --exclude=<black_list>          Blacklist paths.\n";
       print "-W, --include=<white_list>          Whitelist paths.\n";
       print "                                    A multipath SCSI ID is in the form:\n";
       print "                                    02003c000060a98000375274315a244276694e67684c554e202020\n";
       print "    --isregexp                      Whether to treat blacklist and whitelist as regexp\n";
       print "    --alertonly                     List only alerting units. Important here to avoid masses of data.\n";
       print "    --multiline                     Multiline output in overview. This mean technically that\n";
       print "                                    a multiline output uses a HTML <br> for the GUI instead of\n";
       print "                                    Be aware that your messing connections (email, SMS...) must use\n";
       print "                                    a filter to file out the <br>. A sed oneliner like the following\n";
       print "                                    will do the job: sed 's/<[^<>]*>//g'\n";
       print "\n";
       print "SOAP API:\n";
       print "---------\n";
       print "\n";
       print "-S, --select=soap                   Simple check to verify a successfull connection\n";
       print "                                    to VMWare SOAP API.\n";
       print "\n";
       }


#--- Virtual machine ----------------------

    if (($section eq "vm") || ($section eq "all"))
       {
       print "Monitoring a virtual machine via vmware datacenter or vmware host:\n";
       print "==================================================================\n";
       print "\n";
       print "-D, --datacenter=<DCname>           Datacenter hostname.\n";
       print "  or \n";
       print "-H, --host=<hostname>               ESX or ESXi hostname.\n";
       print "\n";
       print "-N, --name=<vmname>                 Virtual machine name.\n";
       print "    --sslport=<port>                If a SSL port different from 443 is used.\n";
       print "\n";
       print "CPU:\n";
       print "----\n";
       print "\n";
       print "-S, --select=cpu                    CPU usage in percentage\n";
       print "\n";
       print "Memory:\n";
       print "-------\n";
       print "\n";
       print "-S, --select=mem                    all mem info(except overall and no thresholds)\n";
       print "or with\n";
       print "-s, --subselect=usage               Average mem usage in percentage of configured virtual\n";
       print "                                    machine \"physical\" memory.\n";
       print "or\n";
       print "-s, --subselect=consumed            Amount of guest physical memory in MB consumed by the\n";
       print "                                    virtual machine for guest memory. Consumed memory does\n";
       print "                                    not include overhead memory. It includes shared memory\n";
       print "                                    and memory that might be reserved, but not actually\n";
       print "                                    used. Use this metric for charge-back purposes.\n";
       print "                                    vm consumed memory = memory granted - memory saved\n";
       print "\n";
       print "Network:\n";
       print "-------\n";
       print "\n";
       print "-S, --select=net                    Shows net info\n";
       print "or with\n";
       print "-s, --subselect=usage               Overall network usage in KBps(Kilobytes per Second).\n";
       print "or\n";
       print "-s, --subselect=receive             Receive in KBps(Kilobytes per Second).\n";
       print "or\n";
       print "-s, --subselect=send                Send in KBps(Kilobytes per Second).\n";
       print "\n";
       print "Disk I/O:\n";
       print "---------\n";
       print "\n";
       print "        * io - shows all disk I/O info Without subselect no thresholds\n";
       print "                                      can be checked.\n";
       print "            + usage - overall disk usage in MB/s\n";
       print "                                      (5 minute samples)\n";
       print "            + read - read latency in ms (totalReadLatency.average)\n";
       print "                                      (5 minute samples)\n";
       print "            + write - write latency in ms (totalWriteLatency.average)\n";
       print "                                      (5 minute samples)\n";
   
       print "        * runtime - shows runtime info\n";
       print "            + con - connection state\n";
       print "            + cpu - allocated CPU in MHz\n";
       print "            + mem - allocated mem in MB\n";
       print "            + state - virtual machine state (UP, DOWN, SUSPENDED)\n";
       print "            + status - overall object status (gray/green/red/yellow)\n";
       print "            + consoleconnections - console connections to VM\n";
       print "            + guest - guest OS status, needs VMware Tools\n";
       print "            + tools - vmware Tools status\n";
       print "            + issues - all issues for the host\n";
       print "            ^ all runtime info(except con and no thresholds)\n";
       print "-B, --exclude=<black_list>\n";
       print "   Specify black list\n";
   
       print "SOAP API:\n";
       print "---------\n";
       print "\n";
       print "-S, --select=soap                   simple check to verify a successfull connection\n";
       print "                                    to VMWare SOAP API.\n";
       print "\n";
       }

#--- Cluster ----------------------

    if (($section eq "all") || ($section eq "cluster"))
       {
       print "Monitoring a vmware cluster via vmware datacenter or vmware host:\n";
       print "=================================================================\n";
       print "\n";
       print "-D, --datacenter=<DCname>           Datacenter hostname.\n";
       print "  or \n";
       print "-H, --host=<hostname>               ESX or ESXi hostname.\n";
       print "\n";
       print "-C, --cluster=<clustername>         ESX or ESXi clustername.\n";
       print "    --sslport=<port>                If a SSL port different from 443 is used.\n";
   
       print "-S, --select=COMMAND\n";
       print "   Specify command type (cpu,mem,net,io,volumes,runtime, ...)\n";
       print "-s, --subselect=SUBCOMMAND\n";
       print "   Specify subselect\n";
       print "\n";
       print "-B, --exclude=<black_list>\n";
       print "   Specify black list\n";
       print "\n";
       print "    Cluster specific :\n";
       print "\n";
       print "CPU:\n";
       print "----\n";
       print "\n";
       print "        * cpu - shows cpu info\n";
       print "            + usage - CPU usage in percentage\n";
       print "            + usagemhz - CPU usage in MHz\n";
       print "            ^ all cpu info\n";
       print "\n";
       print "Memory:\n";
       print "-------\n";
       print "\n";
       print "        * mem - shows mem info\n";
       print "            + usage - mem usage in percentage\n";
       print "            + usagemb - mem usage in MB\n";
       print "            + swap - swap mem usage in MB\n";
       print "            + memctl - mem used by VM memory control driver(vmmemctl) that controls ballooning\n";
       print "            ^ all mem info(plus overhead and no thresholds)\n";
       print "        * cluster - shows cluster services info\n";
       print "            + effectivecpu - total available cpu resources of all hosts within cluster\n";
       print "            + effectivemem - total amount of machine memory of all hosts in the cluster\n";
       print "            + failover - vmware HA number of failures that can be tolerated\n";
       print "            + cpufainess - fairness of distributed cpu resource allocation\n";
       print "            + memfainess - fairness of distributed mem resource allocation\n";
       print "            ^ only effectivecpu and effectivemem values for cluster services\n";
       print "        * runtime - shows runtime info\n";
       print "            + listvms - list of vmware machines in cluster and their statuses\n";
       print "            + listhost - list of vmware esx host servers in cluster and their statuses\n";
       print "            + status - overall cluster status (gray/green/red/yellow)\n";
       print "            + issues - all issues for the cluster\n";
       print "                b - blacklist issues\n";
       print "            ^ all cluster runtime info\n";
       print "\n";
       print "Volumes:\n";
       print "--------\n";
       print "\n";
       print "-S, --select=volumes                Shows all datastore volumes info\n";
       print "or with\n";
       print "-s, --subselect=<name>              free space info for volume with name <name>)\n\n";
       print "    --usedspace                     output used space instead of free\n";
       print "    --alertonly                     list only alerting volumes\n";
       print "-B, --exclude=<black_list>          blacklist volumes.\n";
       print "-W, --include=<white_list>          whitelist volumes.\n";
       print "    --isregexp                      whether to treat name, blacklist and whitelist as regexp\n";
       print "\n";
       }
    }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a commen method to ensure this.
1;
