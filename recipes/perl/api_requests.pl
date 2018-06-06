#!/usr/bin/env perl
use LWP::UserAgent;

my $content_type_v2 = "application/vnd.netbackup+json; version=2.0";

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
        print "Received token: $token\n";
    }
    else {
        print "HTTP POST error code: ", $resp->code, "\n";
        print "HTTP POST error message: ", $resp->message, "\n";
    }
}

# create VMWare policy with the name veritas_policy1 with default values
sub create_policy_with_defaults {

    my $url = "$base_url/config/policies";
    my $policy_name = "veritas_policy1";

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
        print "HTTP POST error code: ", $resp->code, "\n";
        print "HTTP POST error message: ", $resp->message, "\n";
    }
}

# create VMWare policy with the name veritas_policy1
sub create_policy {

    my $url = "$base_url/config/policies";
    my $policy_name = "veritas_policy1";

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
    print "\n\n Making POST Request to create VMWare policy with defaults \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Policy [$policy_name] with default values is create with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP POST error code: ", $resp->code, "\n";
        print "HTTP POST error message: ", $resp->message, "\n";
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
        print "HTTP GET error code: ", $resp->code, "\n";
        print "HTTP GET error message: ", $resp->message, "\n";
    }
}

# subroutine to read policy
sub read_policy {
    my $policy_name = "veritas_policy1";
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
    }
    else {
        print "HTTP GET error code: ", $resp->code, "\n";
        print "HTTP GET error message: ", $resp->message, "\n";
    }
}

# subroutine to create client. For VIP query, we expect
# hostName to be MEDIA_SERVER, OS and hardware to be VMWare.
sub add_clients {
    my $policy_name = "veritas_policy1";
    my $url = "$base_url/config/policies/$policy_name/clients/MEDIA_SERVER";

    my $req = HTTP::Request->new(PUT => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    my $post_data = qq({ "data": { "type": "client", "id": "MEDIA_SERVER", "attributes": {
    "hardware": "VMware", "OS": "VMware", "hostName": "MEDIA_SERVER" } } } );
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making PUT Request to add clients to policy \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Client is added to policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP PUT error code: ", $resp->code, "\n";
        print "HTTP PUT error message: ", $resp->message, "\n";
    }
}

# subroutine to add backupSelections to a policy
sub add_backupselections {
    my $policy_name = "veritas_policy1";
    my $url = "$base_url/config/policies/$policy_name/backupselections";

    my $req = HTTP::Request->new(PUT => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    my $post_data = qq({ "data": { "type": "backupSelection", "attributes": {
    "selections": [ "vmware:/?filter=Displayname Equal \\\"Redacted-Test\\\"" ] } } } );
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making PUT Request to add backupselection to policy \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "BackupSelection is added to policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP PUT error code: ", $resp->code, "\n";
        print "HTTP PUT error message: ", $resp->message, "\n";
    }
}

# subroutine to add schedule to a policy
sub add_schedule {
    my $policy_name = "veritas_policy1";
    my $schedule_name = "schedule1";
    my $url = "$base_url/config/policies/$policy_name/schedules/$schedule_name";

    my $req = HTTP::Request->new(PUT => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

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

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Schedule [$schedule_name] is added to policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP PUT error code: ", $resp->code, "\n";
        print "HTTP PUT error message: ", $resp->message, "\n";
    }
}

# subroutine to delete client from a policy
sub delete_client {
    my $policy_name = "veritas_policy1";
    my $url = "$base_url/config/policies/$policy_name/clients/MEDIA_SERVER";

    my $req = HTTP::Request->new(DELETE => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making DELETE Request to remove clients from the policy \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Client [MEDIA_SERVER] is deleted from policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP DELETE error code: ", $resp->code, "\n";
        print "HTTP DELETE error message: ", $resp->message, "\n";
    }
}

# subroutine to delete schedule from a policy
sub delete_schedule {
    my $policy_name = "veritas_policy1";
    my $schedule_name = "schedule1";
    my $url = "$base_url/config/policies/$policy_name/schedules/$schedule_name";

    my $req = HTTP::Request->new(DELETE => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making DELETE Request to remove schedule from the policy \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Schedule [$schedule_name] is deleted from policy [$policy_name] with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP DELETE error code: ", $resp->code, "\n";
        print "HTTP DELETE error message: ", $resp->message, "\n";
    }
}

# subroutine to delete policy
sub delete_policy {

    my $policy_name = "veritas_policy1";
    my $url = "$base_url/config/policies/$policy_name";

    my $req = HTTP::Request->new(DELETE => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making DELETE Request to remove the policy \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Policy is deleted with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP DELETE error code: ", $resp->code, "\n";
        print "HTTP DELETE error message: ", $resp->message, "\n";
    }
}

1;