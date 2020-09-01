#!/usr/bin/env perl

use LWP::UserAgent;
use LWP::Protocol::https;
print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";
use JSON;
use Getopt::Long qw(GetOptions);


#
# The token is the key to the NetBackup AuthN/AuthZ scheme.  You must login and get a token
# and use this token in your Authorization header for all subsequent requests.  Token validity
# is fixed at 24 hours
#

my $content_type = "application/vnd.netbackup+json; version=4.0";
my $protocol = "https";
my $port = "1556";
my $nbmaster;
my $username;
my $password;
my $domainName;
my $domainType;
my $token;
my $base_url;
my $assetsFilter;

my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl get_vmware_assets -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] [-assetsFilter <filter>]\n\n\n");
}

sub print_disclaimer {
    print("--------------------------------------------------------\n");
    print("--       This script requires Perl 5.20.2 or later    --\n");
    print("--------------------------------------------------------\n");
    print("Executing this library requires some additional libraries like \n\t'LWP' \n\t'JSON'\ \n\t'Getopt'\ \n\n");
    print("You can specify the 'nbmaster', 'username', 'password', 'domainName', 'domainType' and 'assetsFilter' as command-line parameters\n");
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
        'assetsFilter=s' => \$assetsFilter,
    ) or (print_usage() && exit);

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

sub login {

    my @argument_list = @_;
    $base_url = $argument_list[0];
    my $username = $argument_list[1];
    my $password = $argument_list[2];
    my $domainName = $argument_list[3];
    my $domainType = $argument_list[4];

    my $url = "$base_url/login";

    my $req = HTTP::Request->new(POST => $url);
    $req->header('content-type' => 'application/json');

    if ($domainName eq "" && $domainType eq "") {
        $post_data = qq({ "userName": "$username", "password": "$password" });
    }
    else {
        $post_data = qq({ "domainType": "$domainType", "domainName": "$domainName", "userName": "$username", "password": "$password" });
    }
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to login to get token \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $message = decode_json($resp->content);
        $token = $message->{"token"};
        print "Login succeeded with status code: ", $resp->code, "\n";
    }
    else {
        print "Request failed with status code: ", $resp->code, "\n";
    }
    return $token;
}

# subroutine to get assets
sub get_assets {
    my $url = "$base_url/asset-service/workloads/vmware/assets";

    my $req = HTTP::Request->new(GET => $url);
    $req->header('Accept' => $content_type);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to get assets\n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        print "Get vmware Assets succeeded with status code: ", $resp->code, "\n\n\n";
        print "Below is the list of asset IDs:\n";
        print "=======================\n";

        my $json = decode_json($message);
        my @assets = @{$json->{'data'}};
        foreach (@assets) {
            my $asset = $_;
            my $id = $asset->{'id'};

            printf("Asset id : %s \n", $id);
            
        }
    }
    else {
        print "HTTP GET error code: ", $resp->code, "\n";
        print "HTTP GET error message: ", $resp->decoded_content, "\n";
    }
}

print_disclaimer();

user_input();

$token = login($base_url, $username, $password, $domain_name, $domain_type);

get_assets();
