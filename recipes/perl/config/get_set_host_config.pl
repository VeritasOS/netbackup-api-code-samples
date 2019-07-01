#!/usr/bin/env perl

use LWP::UserAgent;
use LWP::Protocol::https;
use JSON;
use Getopt::Long qw(GetOptions);

require 'api_requests.pl';

print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";

#
# The token is the key to the NetBackup AuthN/AuthZ scheme.  You must login and get a token
# and use this token in your Authorization header for all subsequent requests.  Token validity
# is fixed at 24 hours
#

my $nbmaster;
my $username;
my $password;
my $domainName;
my $domainType;
my $protocol = "https";
my $port = "1556";
my $base_url;

my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl get_set_host_config.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] -client <client>\n\n\n");
}

sub print_disclaimer {
    print("--------------------------------------------------------\n");
    print("--       This script requires Perl 5.20.2 or later    --\n");
    print("--------------------------------------------------------\n");
    print("Executing this library requires some additional libraries like \n\t'LWP' \n\t'JSON'\ \n\t'Getopt'\ \n\n");
    print("You can specify the 'nbmaster', 'username', 'password', 'domainName', 'domainType', and 'client' as command-line parameters\n");
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
        'client=s' => \$client,
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

    if ($client eq "") {
        print("Please provide the value for 'client'");
        exit;
    }

    $base_url = "$protocol://$nbmaster:$port/netbackup";
}

sub get_set_config {
    get_exclude_list($host_uuid);
    set_exclude_list($host_uuid);
    get_exclude_list($host_uuid);
}

print_disclaimer();

user_input();

perform_login($base_url, $username, $password, $domainName, $domainType);

my $host_uuid = get_host_uuid($client);

get_set_config();
