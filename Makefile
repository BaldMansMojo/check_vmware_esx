#!/usr/bin/make -f

all: check_vmware_esx

check_vmware_esx: check_vmware_esx.pl modules/*.pm
	echo "#!/usr/bin/env perl"            > check_vmware_esx
	cat modules/*.pm check_vmware_esx.pl >> check_vmware_esx
	sed -i -e 's/use lib "modules";//g' check_vmware_esx
	for mod in $$(ls -1 modules/*.pm | sed 's/^modules\/\(.*\)\.pm/\1/'); do sed -i check_vmware_esx -e 's/^use '$$mod';//g'; done
	chmod 755 check_vmware_esx

clean:
	rm -f check_vmware_esx
