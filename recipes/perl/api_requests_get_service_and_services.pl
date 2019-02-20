#!/usr/bin/env perl

use LWP::UserAgent;
use LWP::Protocol::https;
print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";
use JSON;

use FindBin;
use lib "$FindBin::RealBin/../../snippets/perl";
use gateway;
use common;

use Getopt::Long qw(GetOptions);

#
# The token is the key to the NetBackup AuthN/AuthZ scheme.  You must login and get a token
# and use this token in your Authorization header for all subsequent requests.  Token validity
# is fixed at 24 hours
#
my $token;

my $protocol = "https";
my $port = "1556";
my $content_type_v3 = "application/vnd.netbackup+json; version=3.0";
my $nbmaster;
my $username;
my $password;
my $domainName;
my $domainType;
my $base_url;

# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl api_requests_get_service_and_services.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n\n");
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

# subroutine to extract host uuid for the master, the same
# API could be used to extract the uuid for any host that 
# master server is able to talk to.
sub extract_host_uuid {
    my $host_url = "$base_url/config/hosts";

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to extract uuid for subsequent API's: $url \n";

    my $json_results = common::send_http_request($host_url, "get", $token, undef, $content_type_v3, undef);
    my @hosts = @{$json_results->{"hosts"}};
    return $hosts[0]->{"uuid"};
}

# subroutine to list policies
sub get_services {
    my $uuid = extract_host_uuid();
    my $url = "$base_url/admin/hosts/$uuid/services";

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to retrieve all the services using: $url \n";

    my $json_results = common::send_http_request($url, "get", $token, undef, $content_type_v3, undef);
    print JSON->new->pretty->encode($json_results);
}

# subroutine to list policies
sub get_service {
    my $uuid = extract_host_uuid();
    my $url = "$base_url/admin/hosts/$uuid/services/bpcd";

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to retrieve a service using: $url \n";

    my $json_results = common::send_http_request($url, "get", $token, undef, $content_type_v3, undef);
    print JSON->new->pretty->encode($json_results);
}

sub get_service_and_services {
    $token = gateway::perform_login($nbmaster, $username, $password, $domain_name, $domain_type);
    extract_host_uuid();
    get_service();
    get_services();
}

print_disclaimer();

user_input();

get_service_and_services();
