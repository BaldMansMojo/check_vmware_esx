sub system_license_info {

    my ($host) = @_;
    my $host_defined = @_;
    my $state = 2;
    my $output = 'Licence request error';
    my $service_content;
    my $host_license_manager;
    my $license_name = "";
    my $license_key = "";
    my $evaluation_hours = -1;
    my $evaluation_minutes = -1;
    my $evaluation_seconds = -1;

    $service_content = Vim::get_service_content();

    # connected to ESXi host
    if ($service_content->about->apiType eq 'HostAgent') {

        $host_license_manager = Vim::get_view( mo_ref => $service_content->licenseManager, properties => [ 'licenses', 'evaluation.properties' ]);

        $license_name = @{$host_license_manager->licenses}[0]->name;
        $license_key  = @{$host_license_manager->licenses}[0]->licenseKey;

        foreach (@{$host_license_manager->get_property('evaluation.properties')}) {
            if ( $_->key eq "expirationHours" ) {
                $evaluation_hours = $_->value;
            }
            if ( $_->key eq "expirationMinutes" ) {
                $evaluation_minutes = $_->value;
            }
        }

    # connected to vCenter
    } elsif ($service_content->about->apiType eq 'VirtualCenter') {

        $vcenter_license_manager = Vim::get_view( mo_ref => $service_content->licenseManager, properties => [ 'licenses', 'evaluation.properties', 'licenseAssignmentManager' ]);

        $license_assignment_manager =  Vim::get_view(
            mo_ref => $vcenter_license_manager->licenseAssignmentManager
        );

        # request host licenses via vCenter
        if ($host_defined) {
            $host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => $host, properties => ['name']);

            # host not found
            if (!$host_view) {
                return (3, "Host ".$host->{name}." not found in vCenter!");
                print "ERROR\n";
            }
            $assigned_licenses = $license_assignment_manager->QueryAssignedLicenses(
                entityId => $host_view->get_property('mo_ref')->value,
            );

        # request vCenter license
        } else {
            $assigned_licenses = $license_assignment_manager->QueryAssignedLicenses(
                entityId => $service_content->about->instanceUuid,
            );
        }

        $assigned_license = @{$assigned_licenses}[0]->assignedLicense;

        $license_name = $assigned_license->name;
        $license_key = $assigned_license->licenseKey;

        my $licenses_properties = @{$assigned_licenses}[0]->properties;
        foreach (@{$licenses_properties}) {
            if ($_->key eq "Evaluation") {
                foreach (@{$_->value->properties}) {
                    if ($_->key eq "expirationHours" ) {
                        $evaluation_hours = $_->value;
                    }
                    if ($_->key eq "expirationMinutes" ) {
                        $evaluation_minutes = $_->value;
                    }
                }
            }
        }
    }

    # start output text with correct instance
    if ($host_defined) {
        $output = "Host";
    } else {
        $output = "vCenter";
    }

    # calculate expiration in seconds
    $evaluation_seconds = $evaluation_hours * 60 * 60 + $evaluation_minutes * 60;

    if ($evaluation_seconds lt 0) {
        $output .= " License query failed. Unable to retrieve \"evaluation_hours\" and \"evaluation_minutes\" from API.";
        $state = 3;
    } elsif ($license_name eq '') {
        $output .= " License query failed. Unable to retrieve type of license.";
        $state = 3;
    } elsif ($license_name eq 'Evaluation Mode') {
        $output .= " is in Evaluation Mode";
        $state = 1;

        if ($evaluation_seconds eq 0) {
            $output .= " - Evaluation period has expired, please install license.";
            $state = 2;
        } else {
            if ($evaluation_hours <= 24) {
                $state = 2;
            }
            $output .= " - Evaluation Period Remaining: ";
            $output .= duration_exact($evaluation_seconds);
            }
    } else {
        $output .= " is Licensed - Version: " . $license_name;
        if (!defined($hidekey)) {
            $output .= " - Key: " . $license_key;
        }
        $state = 0;
    }

    return ($state, $output);
}

# A module always must end with a return code of 1. So placing 1 at the end of a module
# is a common method to ensure this.
1;
