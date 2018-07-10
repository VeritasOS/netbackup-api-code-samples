#!/usr/bin/env perl

package netbackup;

use JSON;
use warnings;
use Text::Table;
use LWP::UserAgent;
use LWP::Protocol::https;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$CONTENT_TYPE = "application/vnd.netbackup+json; version=1.0";
$NB_PORT = 1556;


#
# This function performs login and returns a NetBackup token.
# The token is the key to the NetBackup AuthN/AuthZ scheme.
# You must login, get a token and use this token in your
# Authorization header for all subsequent requests.
# Token validity is fixed at 24 hours.
#
sub login {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 3 && $arguments_count != 5 ) {
    print "ERROR :: Incorrect number of arguments passed to login()\n";
    print "Usage : login( <FQDN Hostname>, <Username>, <Password>, (optional) <Domain name>, (optional) <Domain type> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $username = $_[1];
  my $password = $_[2];

  my $domainname;
  my $domaintype;
  if ($arguments_count == 5){
    $domainname = $_[3];
    $domaintype = $_[4];
  }

  my $token_url = "https://$fqdn_hostname:$NB_PORT/netbackup/login";

  my $post_data = '{ "userName": "'.$username.'", "password": "'.$password.'" }';
  if ($arguments_count == 5){
    $post_data = '{ "userName": "'.$username.'", "password": "'.$password.'", "domainName": "'.$domainname.'", "domainType": "'.$domaintype.'" }';
  }

  my $req = HTTP::Request->new(POST => $token_url);
  $req->header('content-type' => "$CONTENT_TYPE");
  $req->content($post_data);

  my $ua = LWP::UserAgent->new(
  	timeout => 500,
  	ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing Login Request on $token_url\n";
  my $resp = $ua->request($req);
  if ($resp->is_success) {
  	my $message = decode_json($resp->content);
  	my $token = $message->{"token"};
    print "Successfully completed Login Request.\n";
    return $token;
  }
  else {
    print "ERROR :: Login Request Failed!\n";
    print "HTTP POST error code: ", $resp->code, "\n";
    print "HTTP POST error message: ", $resp->message, "\n";
  	#die;  let this fall through to cleanup code
  }

}


#
# This function performs logout. Logging out will cleanup
# the session and invalidates the token immediately.
# If you do not log out, the session will expire after 24 hours.
#
sub logout {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 2) {
    print "ERROR :: Incorrect number of arguments passed to logout()\n";
    print "Usage : logout( <FQDN Hostname>, <Token> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];

  my $logout_url = "https://$fqdn_hostname:$NB_PORT/netbackup/logout";
  my $logout_req = HTTP::Request->new(POST => $logout_url);
  $logout_req->header('Authorization' => $token);

  my $ua = LWP::UserAgent->new(
  	timeout => 500,
  	ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing Logout Request on $logout_url\n";
  my $resp = $ua->request($logout_req);
  if ($resp->is_success) {
      print "Successfully completed Logout Request.\n";
  }
  else {
      print "ERROR :: Logout Request Failed!\n";
      print "HTTP POST error code: ", $resp->code, "\n";
      print "HTTP POST error message: ", $resp->message, "\n";
      #die;
  }

}


#
# This function returns a list of jobs
#
sub getJobs {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 2) {
    print "ERROR :: Incorrect number of arguments passed to getJobs()\n";
    print "Usage : getJobs( <FQDN Hostname>, <Token> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/admin/jobs";
  my $jobs_req = HTTP::Request->new(GET => $url);
  $jobs_req->header('Authorization' => $token);
  $jobs_req->header('content-type' => "$CONTENT_TYPE");

  my $ua = LWP::UserAgent->new(
  	timeout => 500,
  	ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing Get Jobs Request on $url\n";
  my $response = $ua->request($jobs_req);
  if ($response->is_success) {
    print "Successfully completed Get Jobs Request.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: Get Jobs Request Failed!\n";
    print "HTTP GET error code: ", $response->code, "\n";
    print "HTTP GET error message: ", $response->message, "\n";
    #die;  let this fall through to cleanup code
  }

}


#
# This function returns a list of catalog images
#
sub getCatalogImages {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 2) {
    print "ERROR :: Incorrect number of arguments passed to getCatalogImages()\n";
    print "Usage : getCatalogImages( <FQDN Hostname>, <Token> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/catalog/images";
  my $catalog_req = HTTP::Request->new(GET => $url);
  $catalog_req->header('Authorization' => $token);
  $catalog_req->header('content-type' => "$CONTENT_TYPE");

  my $ua = LWP::UserAgent->new(
  	timeout => 500,
  	ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing Get Catalog Images Request on $url\n";
  my $response = $ua->request($catalog_req);
  if ($response->is_success) {
  	print "Successfully completed Get Catalog Images Request.\n";

  	$data = decode_json($response->content);
  	my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: Get Catalog Images Request Failed!\n";
  	print "HTTP GET error code: ", $response->code, "\n";
  	print "HTTP GET error message: ", $response->message, "\n";
  	#die;  let this fall through to cleanup code
  }

}


#
# This function displays data in a tabular form. It takes table title array and
# table data (2-d matrix) as inputs and renders it in a tabular form with border
#
sub displayDataInTable {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 2) {
    print "ERROR :: Incorrect number of arguments passed to displayDataInTable()\n";
    print "Usage : displayDataInTable( <Array of Table Column Titles>, <Matrix of table data> ) \n";
    return;
  }

  my @titletext = @{$_[0]};
  my @data = @{$_[1]};

  my @tabletitle;
  my $val;
  foreach $val (@titletext) {
    push @tabletitle, {is_sep => 1, title => '| ', body => '| '};
    push @tabletitle, $val;
  }
  push @tabletitle, {is_sep => 1, title => '| ', body => '| '};

  my $tb = Text::Table->new( @tabletitle );
  $tb->load(@data);

  print $tb->rule('-', '+');
  for (0 .. @data) {
    print $tb->table($_);
    print $tb->rule('-', '+');
  }

}


#
# This function displays the Json content returned from Jobs API
# in a tabular format
#
sub displayJobs {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
    print "ERROR :: Incorrect number of arguments passed to displayJobs()\n";
    print "Usage : displayJobs( <Json content returned from Jobs API> ) \n";
    return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @jobs = @{$json->{'data'}};

  my @tablerows;

  foreach (@jobs) {
    my $job = $_;

    my $jobId = $job->{'attributes'}->{'jobId'};
    my $jobType = $job->{'attributes'}->{'jobType'};
    my $state = $job->{'attributes'}->{'state'};
    my $status = $job->{'attributes'}->{'status'};

    my @tablerow = ($jobId, $jobType, $state, $status);
    push @tablerows, \@tablerow;
  }

  my @title = ("Job ID", "Type", "State", "Status");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}


#
# This function displays the Json content returned from Catalog Images API
# in a tabular format
#
sub displayCatalogImages {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
    print "ERROR :: Incorrect number of arguments passed to displayJobs()\n";
    print "Usage : displayJobs( <Json content returned from Jobs API> ) \n";
    return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @images = @{$json->{'data'}};

  my @tablerows;

  foreach (@images) {
    my $image = $_;

    my $imageId = $image->{'id'};
    my $policyName = $image->{'attributes'}->{'policyName'};
    my $clientName = $image->{'attributes'}->{'clientName'};
    my $backupTime = $image->{'attributes'}->{'backupTime'};

    my @tablerow = ($imageId, $policyName, $clientName, $backupTime);
    push @tablerows, \@tablerow;
  }

  my @title = ('Image ID','Policy','Client','Backup Time');
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}


1;
