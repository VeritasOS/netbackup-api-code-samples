#!/usr/bin/env perl

use LWP::UserAgent;
use LWP::Protocol::https;
print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";
use JSON;
require 'api_requests.pl';

#
# The token is the key to the NetBackup AuthN/AuthZ scheme.  You must login and get a token
# and use this token in your Authorization header for all subsequent requests.  Token validity
# is fixed at 24 hours
#
my $token;

#change this as per your host name
$fqdn_hostname = "localhost";

# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl create_policy_with_defaults -nbmaster <masterServer> -username <username> -password <password>\n\n\n");
}

sub print_disclaimer {
    print("--------------------------------------------------------\n");
    print("--       This script requires Perl 5.20.2 or later    --\n");
    print("--------------------------------------------------------\n");
    print("Executing this library requires some additional libraries like \n\t'LWP'\n\n");
    print("You can specify the 'nbmaster', 'username' and 'password' as command-line parameters\n");
    print_usage();
}


# subroutine to process user input
sub user_input {
    customtest();
    perform_login("https://localhost:1556/netbackup");
}

print_disclaimer();

user_input();
