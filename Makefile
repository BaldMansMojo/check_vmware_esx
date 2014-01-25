#!/usr/bin/make -f

# This Makefile by Sven Nierlein is completely optional. It is for users
# who prefer a single big file instead of modules. According to my tests
# modules are a little bit faster. Don't make patches based on the big
# file. For patches always use modules

all: check_vmware_esx

check_vmware_esx: check_vmware_esx.pl modules/*.pm
	echo "#!/usr/bin/env perl"            > check_vmware_esx
	cat modules/*.pm check_vmware_esx.pl >> check_vmware_esx
	sed -i -e 's/use lib "modules";//g' check_vmware_esx
	for mod in $$(ls -1 modules/*.pm | sed 's/^modules\/\(.*\)\.pm/\1/'); do sed -i check_vmware_esx -e 's/^\s*use\s*'$$mod';//g' -e 's/^\s*require\s*'$$mod';//g' -e 's/^\s*import\s*'$$mod';//g'; done
	chmod 755 check_vmware_esx

clean:
	rm -f check_vmware_esx
