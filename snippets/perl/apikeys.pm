package apikeys;

use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use LWP::Protocol::https;

# constants
my $APIKEY_URL = "/netbackup/security/api-keys";
my $APIKEY_NB_CONTENT_TYPE_V3 = "application/vnd.netbackup+json; version=3.0";
my $SUCCESS = 1;
my $FAILURE = 0;

=head1 create_apikey

 SYNOPSIS
    This subroutine is used to call /security/api-keys api to create apikey 
	 for self or a user specified

 PARAMETERS
    @param $_[0] - string
        The name of the master server.
        Ex: myhostname.myDomain.com
    @param $_[1] - string
        The authentication token fetched after invoking /login api using 
		  user credentials or apikey.
    @param $_[2] - int
        The expiration period in days from today.
    @param $_[3] - string
        The description to be associated with api-key
    @param $_[4] - scalarRef
        Reference variable to hold apikey value generated. 
    @param $_[5] - scalarRef
        Reference variable to hold apikey tag value. 
    @param $_[6] - scalarRef
        Reference variable to hold apikey expiration date-time value. 
    @param $_[7] - string - optional
        The username of the user whose api key needs to be generated. If not 
		  specified, api key will be created for the user whose token is mentioned
		  in the paramater to this function.
		  Either mention username, domainname and domaintype or provide none. 
    @param $_[8] - string - optional
        The domain in which the user belongs.
		  Either mention username, domainname and domaintype or provide none.
    @param $_[9] - string - optional
        The domain type of the user.
		  Either mention username, domainname and domaintype or provide none.
		  
 RETURNS
    1 - SUCCESS, 0 - FAILURE

=cut
sub create_apikey {
    my @argument_list = @_;
    my $master_server = $argument_list[0];
    my $token = $argument_list[1];
    my $expiry_in_days = $argument_list[2];
    my $description = $argument_list[3];
	 my $apikey_ref = $argument_list[4];
	 my $apikey_tag_ref = $argument_list[5];
	 my $apikey_expiration_ref = $argument_list[6];

    # Validate arguement count to the function
	 if (@argument_list != 7 and @argument_list != 10) {
	     print "ERROR :: Incorrect number of arguments passed to create_apikey()\n";
		  print "Usage : create_apikey( <masterserver>, <auth_token>, <expiry_in_days>, <description>, <apikey_ref>, <apikey_tag_ref>, <apikey_expiration_ref>[, <user_name>, <domain_name>, <domain_type>] ) \n";
		  return $FAILURE;
	 }
	 
	 # user_name, domain_name and domain_type are optional
	 my($user_name, $domain_name, $domain_type);
	 if (@argument_list == 10) {
	     $user_name = $argument_list[7];
	     $domain_name = $argument_list[8];
	     $domain_type = $argument_list[9];
	 }

    # Construct url
    my $url = "https://$master_server:1556" . $APIKEY_URL;

    # Construct request body
    my $request_body =  "{"
                        . "\"data\": {"
                            . "\"type\": \"apiKeyCreationRequest\","
                            . "\"attributes\": {"
                                . "\"description\" : \"" . $description . "\","
                                . "\"expireAfterDays\": \"P" . $expiry_in_days . "D\"";
										  
    if (@argument_list == 10) {
	     $request_body = $request_body 
		                          . ",\"userName\": \"" . $user_name . "\","
                                . "\"userDomain\": \"" . $domain_name . "\","
                                . "\"userDomainType\": \"" . $domain_type . "\"";
    }
	 
	 $request_body = $request_body 
	                         . "}"
                        . "}"
                     . "}";

    

    my $request = HTTP::Request->new(POST => $url);
    $request->header('Authorization' => $token);
    $request->header('content-type' => $APIKEY_NB_CONTENT_TYPE_V3);
    $request->content($request_body);

    my $ua = LWP::UserAgent->new(
  	    timeout => 500,
  	    ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
    );

    print "\nCreating API key";
    my $response = $ua->request($request);
	 if (!$response->is_success) {
		 print "\n API request failed"; 
	    return $FAILURE;
		
	 }
	 my $response_content = decode_json($response->content);
	 if ($response->code != 201) {
	     print "API key creation failed with HTTP code [" . $response->code . "].\n";
		  print "Response: " . $response->content . " \n"; 
		  return $FAILURE;
	 }
	 print "\nSuccessfully created API key.";

    $$apikey_ref = $response_content->{"data"}{"attributes"}{"apiKey"};
    $$apikey_tag_ref = $response_content->{"data"}{"id"};
    $$apikey_expiration_ref = $response_content->{"data"}{"attributes"}{"expiryDateTime"};
	 
    return $SUCCESS;
}

=head1 delete_apikey

 SYNOPSIS
    This subroutine is used to call /security/api-keys api to delete apikey 
	 with apikey tag specified

 PARAMETERS
    @param $_[0] - string
        The name of the master server.
        Ex: myhostname.myDomain.com
    @param $_[1] - string
        The authentication token fetched after invoking /login api using 
		  user credentials or apikey.
    @param $_[2] - int
        The API key tag of the API key to be deleted.
		  
 RETURNS
    1 - SUCCESS, 0 - FAILURE

=cut
sub delete_apikey {
    my @argument_list = @_;
    my $master_server = $argument_list[0];
    my $token = $argument_list[1];
    my $apikey_tag = $argument_list[2];

    # Validate arguement count to the function
	 if (@argument_list != 3) {
	     print "ERROR :: Incorrect number of arguments passed to delete_apikey()\n";
		  print "Usage : delete_apikey( <masterserver>, <auth_token>, <apikey_tag> ) \n";
		  return $FAILURE;
	 }

    # Construct url
    my $url = "https://$master_server:1556" . $APIKEY_URL . "/" . $apikey_tag;

    my $request = HTTP::Request->new(DELETE => $url);
    $request->header('Authorization' => $token);
    $request->header('content-type' => $APIKEY_NB_CONTENT_TYPE_V3);

    my $ua = LWP::UserAgent->new(
  	    timeout => 500,
  	    ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
    );

    print "\nDeleting API key";
    my $response = $ua->request($request);
	 
	 if ($response->code != 204) {
		  print "\nAPI key deletion failed with HTTP code [" . $response->code . "].\n";
		  print "\nResponse: " . $response->content . " \n"; 
		  return $FAILURE;
	 }
	 print "\nSuccessfully deleted API key.";
	 
    return $SUCCESS;
}

1;
