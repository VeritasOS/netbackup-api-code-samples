#!/usr/bin/env perl
use LWP::UserAgent;
use JSON;

my $content_type_v2 = "application/vnd.netbackup+json; version=2.0";

my $json = JSON->new;
my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

# create object group to access only VMware policies
my $object_group_id;
sub create_rbac_object_group_for_VMware_policy {

    my @argument_list = @_;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];

    my $url = "$base_url/rbac/object-groups";
    my $object_group_name = "VMwarePolicy";

    my $req = HTTP::Request->new(POST => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    my $post_data = qq({ "data": { "type": "object-group", "attributes": {
    "name": "$object_group_name", "criteria": [
    { "objectCriterion": "policyType eq 40", "objectType": "NBPolicy" } ]} } });
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to create object group to access only VMware policies \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $json_message = decode_json($resp->decoded_content);
        $object_group_id = $json_message->{"data"}{"id"};
        print "Object group [$object_group_name] is created with id [$object_group_id] to access only VMware policies with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP POST error code: ", $resp->code, "\n";
        print "HTTP POST error message: ", $resp->message, "\n";
    }
}

# create access rule for a user with object group
my $access_rule_id;
sub create_rbac_access_rules {

    my @argument_list = @_;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];
    my $user = $argument_list[2];
    my $domain = $argument_list[3];
    my $domainType = $argument_list[4];

    my $url = "$base_url/rbac/access-rules";

    my $req = HTTP::Request->new(POST => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    my $post_data = qq({ "data": { "type": "access-rule", "attributes": {
    "description": "adding VMwarePolicy object group"}, "relationships": {
    "userPrincipal": { "data": { "type" : "user-principal", "id": "$domain:$user:$domainType:$user" } },
    "objectGroup": { "data": { "type": "object-group", "id": "$object_group_id" } },
    "role": { "data": { "type": "role", "id": "3" } } } } });
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to create access rule \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $json_message = decode_json($resp->decoded_content);
        $access_rule_id = $json_message->{"data"}{"id"};
        print "Access rule is created with id [$access_rule_id] to access only VMware policies with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP POST error code: ", $resp->code, "\n";
        print "HTTP POST error message: ", $resp->message, "\n";
    }
}

# subroutine to delete the object group
sub delete_rbac_object_group_for_VMware_policy {

    my @argument_list = @_;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];

    my $url = "$base_url/rbac/object-groups/$object_group_id";

    my $req = HTTP::Request->new(DELETE => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making DELETE Request to remove the object group \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Policy is deleted with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP DELETE error code: ", $resp->code, "\n";
        print "HTTP DELETE error message: ", $resp->message, "\n";
    }
}

# subroutine to delete the object group
sub delete_rbac_access_rule {

    my @argument_list = @_;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];

    my $url = "$base_url/rbac/access-rules/$access_rule_id";

    my $req = HTTP::Request->new(DELETE => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    print "\n\n**************************************************************";
    print "\n\n Making DELETE Request to remove the access rule \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Policy is deleted with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP DELETE error code: ", $resp->code, "\n";
        print "HTTP DELETE error message: ", $resp->message, "\n";
    }
}

# create VMWare policy with the name vmware_test_policy with default values
sub create_bpnbat_user {

    my @argument_list = @_;
    my $username = $argument_list[0];
    my $domainName = $argument_list[1];
    my $password = $argument_list[2];

    print "\n\n**************************************************************";
    print "\n\n Creating user for RBAC filtering using bpnbat \n\n";

    if ( $^O =~ /MSWin32/ ) {
        my $path = 'C:/\"Program Files\"/Veritas/NetBackup/bin/bpnbat.exe';
        my $cmd = qq($path -AddUser $username $password $domainName);
        my $rc = system($cmd); # returns exit status values
        die "system() failed with status $rc" unless $rc == 0;
    } else {
        my $path = '/usr/openv/netbackup/bin/bpnbat';
        my $cmd = qq($path -AddUser $username $password $domainName);
        my $rc = system($cmd); # returns exit status values
        die "system() failed with status $rc" unless $rc == 0;
    }
    print "\n\n";
}

# create VMWare policy with the name vmware_test_policy with default values
sub create_oracle_policy_with_defaults {

    my @argument_list = @_;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];

    my $url = "$base_url/config/policies";
    my $policy_name = "oracle_test_policy";

    my $req = HTTP::Request->new(POST => $url);
    $req->header('content-type' => $content_type_v2);
    $req->header('Authorization' => $token);

    my $post_data = qq({ "data": { "type": "policy", "id": "$policy_name", "attributes": {
    "policy": { "policyName": "$policy_name", "policyType": "Oracle" } } } });
    $req->content($post_data);

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to create Oracle policy with defaults \n\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        print "Policy [$policy_name] with default values is create with status code: ", $resp->code, "\n";
    }
    else {
        print "HTTP POST error code: ", $resp->code, "\n";
        print "HTTP POST error message: ", $resp->message, "\n";
    }
}

# create VMWare policy with the name vmware_test_policy with default values
sub create_vmware_policy_with_defaults {

    my @argument_list = @_;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];

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
        print "HTTP POST error code: ", $resp->code, "\n";
        print "HTTP POST error message: ", $resp->message, "\n";
    }
}

1;