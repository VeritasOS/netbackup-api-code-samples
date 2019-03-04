package restclient;

use LWP::UserAgent;
use JSON;
use Data::Dumper;

# Constants
my $APPLICATION_HEADER_JSON     = "application/json";

###################################################
# Rest Request Sevice
# Used to communicate with snapshot server
###################################################
sub rest_request {
    my ($method, $host, $url, $cookie, $request_body) = @_;
    my $decoded_response;

    # Create Request
    my $req = HTTP::Request->new($method, "https://" . $host . $url);
    $req->header('Content-Type' => $APPLICATION_HEADER_JSON);
    $req->header('Cookie' => $cookie);
    $req->content($request_body);
    my $uaObj = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 },{ verify_peer => 0 });

    # Get Response
    my $response = $uaObj->request($req);
    if( $response->is_success ) {
        $res_code = $response->code();
        $decoded_response = decode_json($response->decoded_content());
        $response = Dumper($decoded_response);
    }
    else {
        $res_code = $response->code( );
        print "HTTP Error: $res_code - " . $response->status_line . ".\n";
        print $response->decoded_content;
        return undef;
    }
    return $decoded_response;
}

1;