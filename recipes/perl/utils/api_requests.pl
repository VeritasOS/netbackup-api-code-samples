#!/usr/bin/env perl
use LWP::UserAgent;
use JSON;
use Try::Tiny;

my $content_type_v2 = "application/vnd.netbackup+json; version=2.0";
my $content_type_v3 = "application/vnd.netbackup+json; version=3.0";

#We will get this token using login api and the token will be used
#in subsequent api requests of policy
my $token;

my $json = JSON->new;
my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

my $base_url;

# subroutine to call login api using user credentials to get the token to be used
# by subsequent API calls
sub perform_login {

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
        printErrorResponse($resp);
    }
    return $token;
}

# create VMWare policy with the name vmware_test_policy with default values
sub create_policy_with_defaults {

    my $url = "$base_url/config/policies";
    my $policy_name = "vmware_test_policy";

    my $req = HTTP::Request->new(POST => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    my $post_data = qq({ "data": { "type": "policy", "id": "$policy_name", "attributes": {
    "policy": { "policyName": "$policy_name", "policyType": "VMware" } } } });
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to create VMWare policy with defaults \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Policy [$policy_name] with default values is create with status code: ", $resp->code, "\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# create VMWare policy with the name vmware_test_policy
sub create_policy {

    my $url = "$base_url/config/policies";
    my $policy_name = "vmware_test_policy";

    my $req = HTTP::Request->new(POST => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    my $backupSelections = qq("backupSelections": {  
    "selections": [ "vmware:/?filter=Displayname Equal \\\"Redacted-Test\\\"" ] });
    my $clients = qq("clients": [
    { "hardware": "VMware", "OS": "VMware", "hostName": "MEDIA_SERVER" } ]);
    my $schedules = qq("schedules": [ {"acceleratorForcedRescan": false, "backupType": "Full Backup", "backupCopies": {
    "priority": 9999, "copies": [ { "mediaOwner": "owner1", "storage": null, "retentionPeriod": { 
    "value": 9, "unit": "WEEKS" }, "volumePool": "NetBackup", "failStrategy": "Continue"}]},
    "excludeDates": { "lastDayOfMonth": true, "recurringDaysOfWeek": [ "4:6", "2:5" ], "recurringDaysOfMonth": [ 10 ],
    "specificDates": [ "2000-1-1", "2016-2-30" ] }, "frequencySeconds": 4800, "includeDates": { 
    "lastDayOfMonth": true, "recurringDaysOfWeek": [ "2:3", "3:4" ], "recurringDaysOfMonth": [ 10,13], "specificDates": [
    "2016-12-31" ] }, "mediaMultiplexing":2, "retriesAllowedAfterRunDay": true, "scheduleType": "Calendar", "snapshotOnly": false,
    "startWindow": [ { "dayOfWeek": 1, "startSeconds": 14600, "durationSeconds": 24600 }, { "dayOfWeek": 2, "startSeconds": 14600, "durationSeconds": 24600 },
    { "dayOfWeek": 3, "startSeconds": 14600, "durationSeconds": 24600 }, { "dayOfWeek": 4, "startSeconds": 14600, "durationSeconds": 24600 },
    { "dayOfWeek": 5, "startSeconds": 14600, "durationSeconds": 24600 }, { "dayOfWeek": 6, "startSeconds": 14600, "durationSeconds": 24600 },
    { "dayOfWeek": 7, "startSeconds": 14600, "durationSeconds": 24600 } ], "syntheticBackup": false, "storageIsSLP": false, "scheduleName": "sched-9-weeks" } ]);
    my $policy_attributes = qq("policyAttributes": { "active": true, "snapshotMethodArgs": "skipnodisk=0", "jobLimit": 10} );

    my $post_data = qq({ "data": { "type": "policy", "id": "$policy_name", "attributes": {
    "policy": { "policyName": "$policy_name", "policyType": "VMware", $policy_attributes, $clients, $backupSelections, $schedules } } } });
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to create VMWare policy without defaults \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Policy [$policy_name] without default values is created with status code: ", $resp->code, "\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to list policies
sub list_policies {
    my $url = "$base_url/config/policies";

    my $req = HTTP::Request->new(GET => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to list policies \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        print "List policy succeeded with status code: ", $resp->code, "\n";
        print "Compact Json body for list policy: \n", $message, "\n\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to read policy
sub read_policy {
    my $policy_name = "vmware_test_policy";
    my $url = "$base_url/config/policies/$policy_name";

    my $req = HTTP::Request->new(GET => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to read policy \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        print "Get policy on [$policy_name] succeeded with status code: ", $resp->code, "\n";
        print "Compact Json body for list policy: \n", $message, "\n\n";
        # Etag (integer): The current generation ID of the policy.
        print "Respnse headers: \n", $resp->headers()->as_string, "\n\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to read policy and extract generation number from response
my $generation;
sub read_policy_extract_Generation_Number_From_Response {
    my $policy_name = "vmware_test_policy";
    my $url = "$base_url/config/policies/$policy_name";

    my $req = HTTP::Request->new(GET => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        $generation = $resp->header('ETag');
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to create client. For VIP query, we expect
# hostName to be MEDIA_SERVER, OS and hardware to be VMWare.
sub add_clients {
    my $policy_name = "vmware_test_policy";
    my $url = "$base_url/config/policies/$policy_name/clients/MEDIA_SERVER";

    read_policy_extract_Generation_Number_From_Response();

    my $req = HTTP::Request->new(PUT => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);
    # The audit reason for chaning the policy (this header is optional)
    $req->header('X-NetBackup-Audit-Reason' => "adding client to the policy $policy_name");
    $req->header('If-Match' => $generation);

    my $post_data = qq({ "data": { "type": "client", "id": "MEDIA_SERVER", "attributes": {
    "hardware": "VMware", "OS": "VMware", "hostName": "MEDIA_SERVER" } } } );
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making PUT Request to add clients to policy \n\n";

    print "Using ETag : [", $generation, "] in the request If-Match to update the policy", "\n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Client is added to policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to add backupSelections to a policy
sub add_backupselections {
    my $policy_name = "vmware_test_policy";
    my $url = "$base_url/config/policies/$policy_name/backupselections";

    read_policy_extract_Generation_Number_From_Response();

    my $req = HTTP::Request->new(PUT => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);
    # The audit reason for chaning the policy (this header is optional)
    $req->header('X-NetBackup-Audit-Reason' => "adding backupSelection to the policy [$policy_name]");
    $req->header('If-Match' => $generation);

    my $post_data = qq({ "data": { "type": "backupSelection", "attributes": {
    "selections": [ "vmware:/?filter=Displayname Equal \\\"Redacted-Test\\\"" ] } } } );
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making PUT Request to add backupselection to policy \n\n";

    print "Using ETag : [", $generation, "] in the request If-Match to update the policy", "\n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "BackupSelection is added to policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to add schedule to a policy
sub add_schedule {
    my $policy_name = "vmware_test_policy";
    my $schedule_name = "schedule1";
    my $url = "$base_url/config/policies/$policy_name/schedules/$schedule_name";

    read_policy_extract_Generation_Number_From_Response();

    my $req = HTTP::Request->new(PUT => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);
    # The audit reason for chaning the policy (this header is optional)
    $req->header('X-NetBackup-Audit-Reason' => "adding schedule [$schedule_name] to the policy [$policy_name]");
    $req->header('If-Match' => $generation);

    my $post_data = qq({ "data": { "type": "schedule", "id": "$schedule_name", "attributes": {
    "acceleratorForcedRescan": false, "backupType": "Full Backup", "backupCopies": {
    "priority": 9999, "copies": [ { "mediaOwner": "owner1", "storage": null, "retentionPeriod": { 
    "value": 9, "unit": "WEEKS" }, "volumePool": "NetBackup", "failStrategy": "Continue"}]},
    "excludeDates": { "lastDayOfMonth": true, "recurringDaysOfWeek": [ "4:6", "2:5" ], "recurringDaysOfMonth": [ 10 ],
    "specificDates": [ "2000-1-1", "2016-2-30" ] }, "frequencySeconds": 4800, "includeDates": { 
    "lastDayOfMonth": true, "recurringDaysOfWeek": [ "2:3", "3:4" ], "recurringDaysOfMonth": [ 10,13], "specificDates": [
    "2016-12-31" ] }, "mediaMultiplexing":2, "retriesAllowedAfterRunDay": true, "scheduleType": "Calendar", "snapshotOnly": false,
    "startWindow": [ { "dayOfWeek": 1, "startSeconds": 14600, "durationSeconds": 24600 }, { "dayOfWeek": 2, "startSeconds": 14600, "durationSeconds": 24600 },
    { "dayOfWeek": 3, "startSeconds": 14600, "durationSeconds": 24600 }, { "dayOfWeek": 4, "startSeconds": 14600, "durationSeconds": 24600 },
    { "dayOfWeek": 5, "startSeconds": 14600, "durationSeconds": 24600 }, { "dayOfWeek": 6, "startSeconds": 14600, "durationSeconds": 24600 },
    { "dayOfWeek": 7, "startSeconds": 14600, "durationSeconds": 24600 } ], "syntheticBackup": false, "storageIsSLP": false } } } );
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making PUT Request to add schedule to policy \n\n";

    print "Using ETag : [", $generation, "] in the request If-Match to update the policy", "\n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Schedule [$schedule_name] is added to policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to delete client from a policy
sub delete_client {
    my $policy_name = "vmware_test_policy";
    my $url = "$base_url/config/policies/$policy_name/clients/MEDIA_SERVER";

    read_policy_extract_Generation_Number_From_Response();

    my $req = HTTP::Request->new(DELETE => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);
    # The audit reason for chaning the policy (this header is optional)
    $req->header('X-NetBackup-Audit-Reason' => "deleting client from the policy [$policy_name]");
    $req->header('If-Match' => $generation);

    print "\n\n**************************************************************";
    print "\n\n Making DELETE Request to remove clients from the policy \n\n";

    print "Using ETag : [", $generation, "] in the request If-Match to update the policy", "\n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Client [MEDIA_SERVER] is deleted from policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to delete schedule from a policy
sub delete_schedule {
    my $policy_name = "vmware_test_policy";
    my $schedule_name = "schedule1";
    my $url = "$base_url/config/policies/$policy_name/schedules/$schedule_name";

    read_policy_extract_Generation_Number_From_Response();

    my $req = HTTP::Request->new(DELETE => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);
    # The audit reason for chaning the policy (this header is optional)
    $req->header('X-NetBackup-Audit-Reason' => "deleting schedule [$schedule_name] from the policy [$policy_name]");
    $req->header('If-Match' => $generation);

    print "\n\n**************************************************************";
    print "\n\n Making DELETE Request to remove schedule from the policy \n\n";

    print "Using ETag : [", $generation, "] in the request If-Match to update the policy", "\n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Schedule [$schedule_name] is deleted from policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        printErrorResponse($resp);
    }
}

# subroutine to delete policy
sub delete_policy {

    my @argument_list = @_;
    my $policy_name = $argument_list[0];

    # check if the user provides the token to use otherwise
    # use the default token created from the perform_login subroutine.
    if ($argument_list[1] ne "") {
        $token = $argument_list[1];
    }

    # if the user provides the policyname use that to delete otherwise
    # delete the policy named "vmware_test_policy".
    if ($policy_name eq "") {
        $policy_name = "vmware_test_policy";
    }

    my $url = "$base_url/config/policies/$policy_name";

    my $req = HTTP::Request->new(DELETE => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making DELETE Request to remove the policy \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Policy [$policy_name] is deleted with status code: ", $resp->code, "\n";
    }
    else {
        printErrorResponse($resp);
    }
}

sub get_host_uuid {

    my @argument_list = @_;
    $host = $argument_list[0];
    my $host_url = "$base_url/config/hosts?filter=hostName eq '$host'";

    print "\n\n**************************************************************";
    print "\n\n Get the UUID for host ", $host, "\n\n";

    my $req = HTTP::Request->new(GET => $host_url);
    $req->header('Authorization' => $token);
    $req->header('Accept' => $content_type_v3);

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $payload = decode_json($resp->content);
        $host_uuid = $payload->{"hosts"}->[0]->{"uuid"};
        print "Host UUID: ", $host_uuid, "\n";
    }
    else {
        printErrorResponse($resp);
    }

    return $host_uuid;
}

sub get_exclude_list {

    my @argument_list = @_;
    $hostuuid = $argument_list[0];
    my $exclude_url = "$base_url/config/hosts/$hostuuid/configurations/exclude";

    print "\n\n**************************************************************";
    print "\n\n Get exclude list for the host ", $hostuuid, "\n\n";

    my $req = HTTP::Request->new(GET => $exclude_url);
    $req->header('Authorization' => $token);

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $payload = decode_json($resp->content);
        my $exclude_list= $payload->{"data"}->{"attributes"}->{"value"};

        for my $item( @{$exclude_list} ){
            print $item. "\n";
        };
    }
    else {
        printErrorResponse($resp);
    }

    return $exclude_list;
}

sub set_exclude_list {

    my @argument_list = @_;
    $hostuuid = $argument_list[0];
    my $exclude_url = "$base_url/config/hosts/$hostuuid/configurations/exclude";

    print "\n\n**************************************************************";
    print "\n\n Set exclude list for the host ", $hostuuid, "\n\n";

    my $exclude_list = qq({ "data": {
                                "type": "hostConfiguration",
                                "attributes": {
                                    "name": "exclude",
                                    "value": ["C:\\\\Program Files\\\\Veritas\\\\NetBackup\\\\bin\\\\*.lock",
                                              "C:\\\\Program Files\\\\Veritas\\\\NetBackup\\\\bin\\\\bprd.d\\\\*.lock",
                                              "C:\\\\Program Files\\\\Veritas\\\\NetBackup\\\\bin\\\\bpsched.d\\\\*.lock",
                                              "C:\\\\Program Files\\\\Veritas\\\\Volmgr\\\\misc\\\\*",
                                              "C:\\\\Program Files\\\\Veritas\\\\NetBackupDB\\\\data\\\\*",
                                              "C:\\\\tmp"]
                                }
                            }
                        });
    $req = HTTP::Request->new(PUT => $exclude_url);
    $req->header('Authorization' => $token);
    $req->header('content-type' => $content_type_v3);
    $req->content($exclude_list);

    $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Exclude list was configured successfully. \n";
    }
    else {
        if ($resp->code == 404) {
            my $config_url = "$base_url/config/hosts/$hostuuid/configurations";

            $req = HTTP::Request->new(POST => $config_url);
            $req->header('Authorization' => $token);
            $req->header('content-type' => $content_type_v3);
            $req->content($exclude_list);

            $resp = $ua->request($req);
            if ($resp->is_success) {
                print "Exclude list was configured successfully. \n";
            }
            else {
                printErrorResponse($resp);
            }
        }
        else {
            printErrorResponse($resp);
        }
    }
}

sub printErrorResponse {
    my @argument_list = @_;
    $resp = $argument_list[0];

    print "Request failed with status code: ", $resp->code, "\n";

    try {
        my $message = decode_json($resp->content);

        my $errorCode = $message->{"errorCode"};
        print "error code: ", $errorCode, "\n";
        my $errorMessage = $message->{"errorMessage"};
        print "error mesage: ", $errorMessage, "\n";
    } catch {
        print $resp->message;
    }

}

1;
