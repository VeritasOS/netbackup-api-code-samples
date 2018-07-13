package common;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use JSON;

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, verify_peer => 0});

=head1 send_http_request

 SYNOPSIS
    Sends a properly encoded HTTP request

 PARAMETERS
    $_[0] - string
        The url of the request, unencoded
    $_[1] - string
        The request type. This field is case sensitive
        Valid values: post, get, delete, patch, put
    $_[2] - string - optional
        The authenication token
    $_[2] - string - optional
        The body of the request
    $_[3] - string - optional
        The Accept header contents
    $_[4] - string - optional
        The Content-Type header contents

 RETURNS
    The undef if an error occurred.  If successful, it will return the serialized JSON from the response,
    if it's present, otherwise it will return an empty string.

=cut
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

1;
