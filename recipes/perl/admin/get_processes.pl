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

my $content_type_v3 = "application/vnd.netbackup+json; version=3.0";
my $protocol = "https";
my $port = "1556";
my $nbmaster;
my $username;
my $password;
my $domainName;
my $domainType;
my $token;
my $base_url;
my $client;

my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl get_processes -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] -client <client>\n\n\n");
}

sub print_disclaimer {
    print("--------------------------------------------------------\n");
    print("--       This script requires Perl 5.20.2 or later    --\n");
    print("--------------------------------------------------------\n");
    print("Executing this library requires some additional libraries like \n\t'LWP' \n\t'JSON'\ \n\t'Getopt'\ \n\n");
    print("You can specify the 'nbmaster', 'username', 'password', 'domainName', 'domainType' and 'client' as command-line parameters\n");
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

# subroutine to get hostid for a given host name
sub get_hostid {
	my $uuid;
    my @argument_list = @_;
    $host_name = $argument_list[0];

    my $url = "$base_url/config/hosts?filter=hostName eq '$host_name'";
    my $req = HTTP::Request->new(GET => $url);
    $req->header('Accept' => $content_type_v3);
    $req->header('Authorization' => $token);
    print "\n\n**************************************************************";
    print "\n\n Making GET Request to get host id \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        print "Get host succeeded with status code: ", $resp->code, "\n";
        my $json = decode_json($message);
        my @hosts = @{$json->{'hosts'}};
        $uuid = @hosts[0]->{'uuid'};
       print "uuid=$uuid\n";
    }
    else {
        print "HTTP GET error code: ", $resp->code, "\n";
        print "HTTP GET error message: ", $resp->decoded_content, "\n";
    }
   return $uuid;
}

# subroutine to get processes
sub get_processes {
	my @argument_list = @_;
    my $uuid = $argument_list[0];
    my $url = "$base_url/admin/hosts/$uuid/processes";

    my $req = HTTP::Request->new(GET => $url);
    $req->header('Accept' => $content_type_v3);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to get processes\n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        print "Get processes succeeded with status code: ", $resp->code, "\n\n\n";
        print "Process List for NetBackup Client \"$client\"\n\n";
        print "pid     processName      priority memoryUsageMB startTime              elapsedTime\n";
        print "=======.================.========.=============.======================.======================\n";

        my $json = decode_json($message);
        my @processes = @{$json->{'data'}};
        foreach (@processes) {
            my $process = $_;
            my $pid = $process->{'attributes'}->{'pid'};
            my $processName = $process->{'attributes'}->{'processName'};
            my $priority = $process->{'attributes'}->{'priority'};
            my $memoryUsageMB = $process->{'attributes'}->{'memoryUsageMB'};
            my $startTime = $process->{'attributes'}->{'startTime'};
            my $elapsedTime = $process->{'attributes'}->{'elapsedTime'};
            printf("%7s %-16s %8s %13s %22s %22s\n", $pid, $processName, $priority, $memoryUsageMB, $startTime, $elapsedTime);
        }
    }
    else {
        print "HTTP GET error code: ", $resp->code, "\n";
        print "HTTP GET error message: ", $resp->decoded_content, "\n";
    }
}

print_disclaimer();

user_input();

$token = perform_login($base_url, $username, $password, $domainName, $domainType);

my $uuid = get_hostid($client);
if ($uuid eq "") {
	print("\nUnable to read host uuid for client $client\n");
	exit;
}

get_processes($uuid);
