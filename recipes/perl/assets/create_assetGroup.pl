#!/usr/bin/env perl

require 'api_requests.pl';

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

my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

# subroutines for printing usage and library information required to run the script.
sub print_usage {
    print("\n\nUsage:");
    print("\nperl get_vmware_assets -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] \n\n\n");
}

sub print_disclaimer {
    print("--------------------------------------------------------\n");
    print("--       This script requires Perl 5.20.2 or later    --\n");
    print("--------------------------------------------------------\n");
    print("Executing this library requires some additional libraries like \n\t'LWP' \n\t'JSON'\ \n\t'Getopt'\ \n\n");
    print("You can specify the 'nbmaster', 'username', 'password', 'domainName', 'domainType' as command-line parameters\n");
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

# subroutine to Create Asset Group
sub create_assetGroup {
    my $url = "$base_url/asset-service/queries";

    my $asset_data = qq({
  "data": {
    "type": "query",
    "attributes": {
      "queryName": "create-or-update-assets",
      "workloads": ["vmware"],
      "parameters": {
        "objectList": [
        {
            "correlationId": "cor-123",
            "type": "vmwareGroupAsset",
            "assetGroup": {
              "description": "sampleDescription",
              "assetType": "vmGroup",
              "filterConstraint": "sampleFilterConstaint",
              "oDataQueryFilter": "commonAssetAttributes/displayName eq 'testing123'",
              "commonAssetAttributes": {
                "displayName": "sampleGroup123",
                "workloadType": "vmware",
                "protectionCapabilities": {
                  "isProtectable": "YES",
                  "isProtectableReason": "sampleReason",
                  "isRecoverable": "NO",
                  "isRecoverableReason": "sampleReason"
                },
                "detection": {
                  "detectionMethod": "MANUAL"
                }
              }
            }
          }
        ]
      }
    }
  }
});

    my $req = HTTP::Request->new(POST => $url);
    $req->header('Content-Type' => $content_type);
    $req->header('Authorization' => $token);
    $req->content($asset_data);

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to create assetGroup\n\n";

    my $resp = $ua->request($req);
 
        my $message = $resp->decoded_content;
        print "Create vmware Asset Group succeeded with status code: ", $resp->code, "\n\n\n";
        print "=======================\n";

        my $json = decode_json($message);
        my $id = $json->{'data'}->{'id'};
        print "id: ", $id, "\n\n\n";
        
        my $url = "$base_url/asset-service/queries/$id";
        my $req = HTTP::Request->new(GET => $url);
        $req->header('Accept' => $content_type);
        $req->header('Authorization' => $token);

        print "\n\n**************************************************************";
        print "\n\n Making GET Request for the QueryID response\n\n";

        my $resp = $ua->request($req);
        my $message = $resp->decoded_content;
        
        print "Create vmware Asset Group query id : ", $resp->code, "\n\n\n";

        my $json = decode_json($message);
        my @responses = @{$json->{'data'}};
        for my $response (@responses) {
            my @workitems = @{$response->{'attributes'}->{'workItemResponses'}};
            for my $workItem (@workitems) {
                my $status = $workItem->{'statusDetails'}->{'message'};
                if ($status eq 'Created') {
                    print "VMware Asset Group : ", $status ,"\n";
                } else {
                   print "VMware Asset Group Not Created due to: ", $status ,"\n";
                }
            }
        }
}

print_disclaimer();

user_input();

$token = perform_login($base_url, $username, $password, $domain_name, $domain_type);

create_assetGroup();
