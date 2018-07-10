#!/usr/bin/env perl

use LWP::UserAgent;
use LWP::Protocol::https;
print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";
use JSON;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

#
# The token is the key to the NetBackup AuthN/AuthZ scheme.  You must login and get a token
# and use this token in your Authorization header for all subsequent requests.  Token validity
# is fixed at 24 hours
#
my $token;

#change this as per your host name
$fqdn_hostname = "localhost";

#
# This script will use the "Enhanced Auditing" feature in NetBackup to create a non-root admin
# account in NetBackup.  This admin account can then be used to invoke REST API requests.
#

print "\n\n Adding the user\n\n";
system q["/usr/openv/netbackup/bin/bpnbat" -addUser testuser Test1234 vx];

print "Enabling enhanced auditing...\n\n";
system q[echo y|"/usr/openv/netbackup/bin/admincmd/bpnbaz" -SetupExAudit];

print "Granting VxSS user administrator privileges...\n\n";
system q["/usr/openv/netbackup/bin/admincmd/bpnbaz" -AddUser vx:vx:testuser];

print "Restarting services...";
system q["/usr/openv/netbackup/bin/bp.kill_all"];
system q["/usr/openv/netbackup/bin/bp.start_all"];

#
# for the sake of this test, ignore ssl certificate
#
my $ua = LWP::UserAgent->new(
	timeout => 500,
	ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
);
		 
my $token_url = "https://$fqdn_hostname:1556/netbackup/login";

my $req = HTTP::Request->new(POST => $token_url);
$req->header('content-type' => 'application/json');
 
my $post_data = '{ "domainType": "vx", "domainName": "vx", "userName": "testuser", "password": "Test1234" }';
$req->content($post_data);
 
print "**************************************************************";
print "\n\n Making Post Request to login to get token \n\n";
my $resp = $ua->request($req);
if ($resp->is_success) {
	my $message = decode_json($resp->content);
	$token = $message->{"token"};
    	print "Received token: $token\n";
}
else {
    	print "HTTP POST error code: ", $resp->code, "\n";
    	print "HTTP POST error message: ", $resp->message, "\n";
	#die;  let this fall through to cleanup code
}

#
# Here we use the Front End Data report as an example of how to use the token to invoke a
# REST API request
#
my $url = "https://$fqdn_hostname:1556/netbackup/catalog/frontenddata";
my $catalog_req = HTTP::Request->new(GET => $url);
$catalog_req->header('Authorization' => $token);

my $response = $ua->request($catalog_req);

print "**************************************************************";
print "\n\n Making Get Request to Catalog/FrontendData with token \n\n";
if ($response->is_success) {
    	print "/Catalog/frontenddata request was successful \n\n";
    
    	$data = decode_json($response->content);
    	my $pretty = JSON->new->pretty->encode($data);
    	print "Received data \n$pretty\n\n\n";
}
else {
    	print "HTTP GET error code: ", $response->code, "\n";
    	print "HTTP GET error message: ", $response->message, "\n";
	#die;  let this fall through to cleanup code	
}

#
# Another example, list jobs...
#
my $url = "https://$fqdn_hostname:1556/netbackup/admin/jobs";
my $jobs_req = HTTP::Request->new(GET => $url);
$jobs_req->header('Authorization' => $token);

my $response = $ua->request($jobs_req);

print "**************************************************************";
print "\n\n Making Get Request to list all jobs \n\n";
if ($response->is_success) {
        print "List jobs request was successful \n\n";

        $data = decode_json($response->content);
        my $pretty = JSON->new->pretty->encode($data);
        print "Received data \n$pretty\n\n\n";
}
else {
        print "HTTP GET error code: ", $response->code, "\n";
        print "HTTP GET error message: ", $response->message, "\n";
        #die;  let this fall through to cleanup code    
}



#
# Logging out will cleanup the session and invalidate the token immediately.
# If you do not log out, the session expires after 24 hours.
#
print "**************************************************************";
print "\n\nLogout of the REST APIs and cleanup the session(optional)\n";

my $logout_url = "https://$fqdn_hostname:1556/netbackup/logout";
my $logout_req = HTTP::Request->new(POST => $logout_url);
$logout_req->header('content-type' => $content_type);
$logout_req->header('Authorization' => $token);

my $resp = $ua->request($logout_req);
if ($resp->is_success) {
    print "Successfully logged out\n\n";
} else {
    print "Failed to logout of the current session\n";
    print "HTTP POST error code: ", $resp->code, "\n";
    print "HTTP POST error message: ", $resp->message, "\n";
    die;
}


print "Revoking the user's administrator privileges...\n\n";
system q["/usr/openv/netbackup/bin/admincmd/bpnbaz" -DelUser vx:vx:testuser];

print "Disabling enhanced auditing...\n\n";
system q[echo y|"/usr/openv/netbackup/bin/admincmd/bpnbaz" -DisableExAudit];

print "\n\n Deleting the user\n\n";
system q["/usr/openv/netbackup/bin/bpnbat" -RemoveUser testuser vx];


