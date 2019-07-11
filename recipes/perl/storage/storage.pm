#!/usr/bin/env perl

package storage;

use JSON;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use LWP::Protocol::https;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$CONTENT_TYPE = "application/vnd.netbackup+json;version=3.0";
$PROTOCOL = "https://";
$NB_PORT = 1556;

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, verify_peer => 0});


sub send_http_request {
    my $url = $_[0];
    my $request_type = $_[1];
    my $token = $_[2];
    my $body = $_[3];
    my $accept = $_[4];
    my $content_type = $_[5];

    if (not defined $url or not defined $request_type){
        print "Error: url and request type are required fields";
        return undef;
    }

    print "Unencoded URL is $url\n";
    # assume string is un-encoded, and '%' is a literal that needs to be replaced by '%25'.
    # All other types of encoding are handled gracefully by the LWP module except literal percent
    $url =~ s/%/%25/;

    # determine correct request type
    my $req;
    if (uc($request_type) eq "GET" ){
        $req = HTTP::Request->new(GET => $url);
    }
    elsif ((uc($request_type) eq "POST")){
        $req = HTTP::Request->new(POST => $url);
    }
    elsif ((uc($request_type) eq "DELETE")){
        $req = HTTP::Request->new(DELETE => $url);
    }
    elsif ((uc($request_type) eq "PUT")) {
        $req = HTTP::Request->new(PUT => $url);
    }
    elsif ((uc($request_type) eq "PATCH")){
        $req = HTTP::Request->new(PATCH => $url);
    }
    else {
        print "Unrecognized request type [$request_type]. If this is a valid HTTP request type, please update me";
        return undef;
    }

    # print encoded url to the screen
    print "Encoded URL is ${$req->uri}\n";

    if (defined $token) {
        $req->header('Authorization' => $token);
    }
    if (defined $accept) {
        $req->header('Accept' => $accept);
    }
    if (defined $content_type){
        $req->header('Content-Type' => $content_type);
    }
    if (defined $body){
        $req->content($body);
    }

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $json_results;
        if (defined($resp->content) && $resp->content ne "") {
            $json_results = decode_json($resp->content);
        }
        else {
            $json_results = "";
        }
        return $json_results;
    }
    else {
        print "HTTP error code: ", $resp->code, "\n";
        print "HTTP response content: ", $resp->content, "\n";
        return undef;
    }
}

sub perform_login {
    my @argument_list = @_;
    my $master_server = $argument_list[0];
    my $username = $argument_list[1];
    my $password = $argument_list[2];

    my $token;

    # domainName and domainType are optional
    my $domainName = "";
    my $domainType = "";
    if (@argument_list >= 4) {
        $domainName = $argument_list[3];
    }
    if (@argument_list == 5) {
        $domainType = $argument_list[4];
    }

    # Construct url
    my $url = "https://$master_server:1556/netbackup/login";

    # Construct request body
    my $post_data;
    if (not $domainName and not $domainType) {
        $post_data = qq({ "userName": "$username", "password": "$password" });
    }
    else {
        $post_data = qq({ "domainType": "$domainType", "domainName": "$domainName", "userName": "$username", "password": "$password" });
    }

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to login to get token \n\n";

    my $json_results = send_http_request($url, "post", undef, $post_data, undef, "application/json");

    if (defined $json_results){
        $token = $json_results->{"token"};
    }
    return $token;
}

# Create a storage server
sub post_storage_server {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to post_storage_server()\n";
        print "Usage : post_storage_server( <Master Server Hostname>, <Token>, <Payload>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-servers";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed POST Storage Server Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Storage Server Request Failed!\n";
    }
}


# Create a storage unit
sub post_storage_unit {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to post_storage_unit()\n";
        print "Usage : post_storage_server( <Master Server Hostname>, <Token>, <Payload>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-units";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed POST Storage Unit Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Storage Unit Request Failed!\n";
    }
}

# Create a Disk Pool
sub post_disk_pool {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to post_disk_pool()\n";
        print "Usage : post_storage_server( <Master Server Hostname>, <Token>, <Payload>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/disk-pools";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed POST Disk Pool Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Disk Pool Request Failed!\n";
    }
}

1;

