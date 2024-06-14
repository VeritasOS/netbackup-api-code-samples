#!/usr/bin/env perl

use LWP::UserAgent;
use LWP::Protocol::https;
print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";
use JSON;
use Getopt::Long qw(GetOptions);
use storage;

# This script consists of the helper functions to excute NetBackup APIs to create storage unit.
# 1) Login to Netbackup
# 2) Create storage server
# 3) Create disk Pool
# 4) Create storage unit

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
my $sts_payload;
my $dp_payload;
my $stu_payload;
my $domainName;
my $domainType;
my $base_url;


# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl replication_target_operations_end_to_end.pl -nbmaster <master_server> -username <username> -password <password> -sts_payload <input JSON for storage server> -dp_payload <input JSON for disk pool> -stu_payload <input JSON for storage unit> -add_reptarget_payload <input JSON for add replication target> -delete_reptarget_payload <input JSON for delete replication target> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n\n")
}

sub print_disclaimer {
    print("--------------------------------------------------------\n");
    print("--       This script requires Perl 5.20.2 or later    --\n");
    print("--------------------------------------------------------\n");
    print("Executing this library requires some additional libraries like \n\t'LWP' \n\t'JSON'\ \n\t'Getopt'\ \n\n");
    print("You can specify the 'nbmaster', 'username', 'password', 'sts_payload', 'dp_payload', 'stu_payload', 'add_reptarget_payload', '-delete_reptarget_payload', 'domainName' and 'domainType' as command-line parameters\n");
    print_usage();
}

# subroutine to process user input
sub user_input {
    GetOptions(
        'nbmaster=s' => \$nbmaster,
        'username=s' => \$username,
        'password=s' => \$password,
        'sts_payload=s' => \$sts_payload,
        'dp_payload=s' => \$dp_payload,
        'stu_payload=s' => \$stu_payload,
        'add_reptarget_payload=s' => \$add_reptarget_payload,
        'delete_reptarget_payload=s' => \$delete_reptarget_payload,
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
    if ($sts_payload eq "") {
        print("Please provide the value for 'sts_payload'");
        exit;
    }

    if ($dp_payload eq "") {
        print("Please provide the value for 'dp_payload'");
        exit;
    }

    if ($stu_payload eq "") {
        print("Please provide the value for 'stu_payload'");
        exit;
    }

    if ($add_reptarget_payload eq "") {
        print("Please provide the value for 'add_reptarget_payload'");
        exit;
    }

    if ($delete_reptarget_payload eq "") {
        print("Please provide the value for 'delete_reptarget_payload'");
        exit;
    }

    $base_url = "$protocol://$nbmaster:$port/netbackup";
}

sub storage_api_automation {
    my $token = storage::perform_login($nbmaster, $username, $password, $domain_name, $domain_type);
    my $response_sts = storage::post_storage_server($nbmaster, $token, $sts_payload);
    my $response_dp = storage::post_disk_pool($nbmaster, $token, $dp_payload);
    storage::post_storage_unit($nbmaster, $token, $stu_payload);

    # Get the stsid from response_sts, dvid from response_dp.
    my $stsid = $response_sts->{data}->{id}
    my $dvid = $response_dp->{data}->{attributes}->{diskVolumes}[0]->{name}

    storage::post_add_replication_target_on_dv($nbmaster, $token, $stsid, $dvid, $add_reptarget_payload)
    my $response_reptarget = storage::get_all_replication_targets($nbmaster, $token, $stsid, $dvid)
    my $reptargetid = $response_reptarget->{data}[0]->{id}

    storage::get_replication_targets_by_id($nbmaster, $token, $stsid, $dvid, $reptargetid)

    storage::post_delete_replication_target_on_dv($nbmaster, $token, $stsid, $dvid, $delete_reptarget_payload)
}

print_disclaimer();

user_input();

storage_api_automation();
