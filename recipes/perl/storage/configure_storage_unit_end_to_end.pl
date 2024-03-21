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
    print("\nperl configure_storage_unit_cloud_end_to_end.pl -nbmaster <masterServer> -username <username> -password <password> -sts_payload <pathToInputPayloadForStorageServer> -dp_payload <pathToInputPayloadForDiskPool> -stu_payload <pathToInputPayloadForStorageUnit> [-domainName <domainName>] [-domainType <domainType>]\n\n\n");
}

sub print_disclaimer {
    print("--------------------------------------------------------\n");
    print("--       This script requires Perl 5.20.2 or later    --\n");
    print("--------------------------------------------------------\n");
    print("Executing this library requires some additional libraries like \n\t'LWP' \n\t'JSON'\ \n\t'Getopt'\ \n\n");
    print("You can specify the 'nbmaster', 'username', 'password', 'sts_payload', 'dp_payload', 'stu_payload', 'domainName' and 'domainType' as command-line parameters\n");
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

    $base_url = "$protocol://$nbmaster:$port/netbackup";
}

sub storage_api_automation {
    my $token = storage::perform_login($nbmaster, $username, $password, $domain_name, $domain_type);
    storage::post_storage_server($nbmaster, $token, $sts_payload);
    storage::post_disk_pool($nbmaster, $token, $dp_payload);
    storage::post_storage_unit($nbmaster, $token, $stu_payload);
    
}

print_disclaimer();

user_input();

storage_api_automation();