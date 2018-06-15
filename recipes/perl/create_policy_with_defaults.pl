#!/usr/bin/env perl

use LWP::UserAgent;
use LWP::Protocol::https;
print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";
use JSON;
use Getopt::Long qw(GetOptions);

require 'api_requests.pl';

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


#change this as per your host name
$fqdn_hostname = "localhost";

# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl create_policy_with_defaults -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n\n");
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
        print("Please provide the value for 'nbmaster', 'username' and 'password'");
        exit;
    }

    if ($username eq "") {
        print("Please provide the value for 'nbmaster', 'username' and 'password'");
        exit;
    }

    if ($password eq "") {
        print("Please provide the value for 'nbmaster', 'username' and 'password'");
        exit;
    }

    $base_url = "$protocol://$nbmaster:$port/netbackup";
}

sub policy_automation {
    perform_login($base_url, $username, $password, $domainName, $domainType);
    create_policy_with_defaults();
    list_policies();
    read_policy();
    add_clients();
    add_backupselections();
    add_schedule();
    read_policy();
    delete_client();
    delete_schedule();
    read_policy();
    delete_policy();
    list_policies();
}

print_disclaimer();

user_input();

policy_automation();
