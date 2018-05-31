#!/usr/bin/env perl
use LWP::UserAgent;

my $content_type_v2 = "application/json";

#We will get this token using login api and the token will be used
#in subsequent api requests of policy
my $token;

sub perform_login {
    my $base_url;

    foreach $item (@_) {
        $base_url = $item;
    }

    my $url = "$base_url/login";
    print "\nUsing url: $url\n";

    my $req = HTTP::Request->new(POST => $url);
    $req->header('content-type' => $content_type_v2);
    my $post_data = '{ "domainType": "nt", "domainName": "rmnus", "userName": "akumar1", "password": "FEELDheat9193" }';
    $req->content($post_data);

    my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

    print "\n\n**************************************************************";
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
    }
}

sub customtest {
    print "we made it here";
}
1;