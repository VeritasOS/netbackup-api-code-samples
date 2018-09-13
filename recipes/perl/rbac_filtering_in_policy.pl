#!/usr/bin/env perl

use LWP::UserAgent;
use LWP::Protocol::https;
print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";
use JSON;
use Getopt::Long qw(GetOptions);

require 'api_requests.pl';
require 'api_requests_rbac_policy.pl';

#
# The token is the key to the NetBackup AuthN/AuthZ scheme.  You must login and get a token
# and use this token in your Authorization header for all subsequent requests.  Token validity
# is fixed at 24 hours
#
my $token;

my $protocol = "https";
my $port = "1556";
my $nbmaster;
my $username;
my $password;
my $domainName;
my $domainType;
my $base_url;
my $new_rbac_user = "testuser";
my $new_rbac_domain = "rmnus";
my $new_rbac_pass = "testpass";
my $new_rbac_domainType = "vx";

# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl rbac_filtering_in_policy -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n\n");
}

sub print_disclaimer {
    print("--------------------------------------------------------\n");
    print("--       This script requires Perl 5.20.2 or later    --\n");
    print("--------------------------------------------------------\n");
    print("Executing this library requires some additional libraries like \n\t'LWP' \n\t'JSON'\ \n\t'Getopt'\ \n\n");
    print("You can specify the 'nbmaster', 'username', 'password', 'domainName' and 'domainType' as command-line parameters\n");
    print_usage();
}


# subroutine to process user input
sub user_input {
    GetOptions(
        'nbmaster=s' => \$nbmaster,
        'username=s' => \$username,
        'password=s' => \$password,
        'domainName=s' => \$domainName,
        'domainType=s' => \$domainType,
    ) or die print_usage();

    if ($nbmaster eq "") {
        print("Please provide the value for 'nbmaster'");
        exit;
    }

    if ($username eq "") {
        print("Please provide the value for 'username'");
        exit;
    }

    if ($password eq "") {
        print("Please provide the value for 'password'");
        exit;
    }

    $base_url = "$protocol://$nbmaster:$port/netbackup";
}

my $token;
sub policy_rbac_automation {
    # perform login using user defined user and use the token for subsequent operations
    $token = perform_login($base_url, $username, $password, $domainName, $domainType);

    create_rbac_object_group_for_VMware_policy($base_url, $token);
    # -------------------------------------------------------------- #
    #  Create a new rbac user locally using bpnbat to assign object
    #  level permissions to the newly created user and perform
    #  subsequent operations.
    # -------------------------------------------------------------- #
    create_bpnbat_user($new_rbac_user, $new_rbac_domain, $new_rbac_pass);
    create_rbac_access_rules($base_url, $token, $new_rbac_user, $new_rbac_domain, $new_rbac_domainType);

    create_vmware_policy_with_defaults($base_url, $token);
    create_oracle_policy_with_defaults($base_url, $token);

    # list policies should display both oracle and vmware policy for admin user
    list_policies();


    my $new_rbac_user_token = perform_login($base_url, $new_rbac_user, $new_rbac_pass, $new_rbac_domain, $new_rbac_domainType);

    # all policy operations will only be allowed for vmware policyType for the user "testuser" since
    # we added vmware object level permissions to the user

    list_policies();
    create_oracle_policy_with_defaults($base_url, $new_rbac_user_token);
    # delete pre-existing vmware policy and try to recreate with new rbac user
    delete_policy("vmware_test_policy", $token);
    create_vmware_policy_with_defaults($base_url, $new_rbac_user_token);

    cleanup();
}

sub cleanup {
    delete_policy("oracle_test_policy", $token);
    delete_policy("vmware_test_policy", $token);
    delete_rbac_access_rule($base_url, $token);
    delete_rbac_object_group_for_VMware_policy($base_url, $token);
}

print_disclaimer();

user_input();

policy_rbac_automation();
