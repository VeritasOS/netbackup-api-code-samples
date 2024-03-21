#!/usr/bin/env perl

use Getopt::Long;

require 'api_requests.pl';
require 'access_control_api_requests.pl';

my $hostname;
my $username;
my $password;
my $domain_name;
my $domain_type;

my $base_url;
my $token;

GetOptions(
    'hostname=s' => \$hostname,
    'username=s' => \$username,
    'password=s' => \$password,
    'domain_name=s' => \$domain_name,
    'domain_type=s' => \$domain_type
) or pod2usage(2);

$hostname ne "" or die "Please provide a value for '--hostname'\n";

$username ne "" or die "Please provide a value for '--username'\n";

$password ne "" or die "Please provide a value for '--password'\n";

$base_url = "https://$hostname/netbackup";
$token = perform_login($base_url, $username, $password, $domain_name, $domain_type);

list_gen1_roles($base_url, $token);


sub print_usage {
    say "Usage:";
    say "perl list_gen1_roles.pl -hostname <master_server> -username <username> -password <password> [-domain_name <domain_name>] [-domain_type <domain_type>]";
}

