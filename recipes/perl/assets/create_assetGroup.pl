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
            "correlationId": "cor1223",
            "type": "vmwareGroupAsset",
            "assetGroup": {
              "description": "sampleDescription",
              "assetType": "vmGroup",
              "filterConstraint": "sampleFilterConstaint",
              "oDataQueryFilter": "commonAssetAttributes/displayName eq 'test125478'",
              "commonAssetAttributes": {
                "displayName": "sampleGroup249vbgt",
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
        my @response = @{$json->{'data'}};
        my $response = $_;
        my @workItem = @{$response->{'attributes'}->{'workItemResponses'}};
        my $workitem = $_;
        my $status = $workItem->{'statusDetails'}->{'message'};

        if ($status = created) {
            print "Create vmware Asset Group : ", $status ,"\n";
        }
         else {
           print "HTTP GET error message: ", $status ,"\n";
        }

    
}

print_disclaimer();

user_input();

$token = login($base_url, $username, $password, $domain_name, $domain_type);

create_assetGroup();
