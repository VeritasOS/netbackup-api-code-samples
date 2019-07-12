#!/usr/bin/env perl

package netbackup;

use JSON;
use warnings;
use Text::Table;
use LWP::UserAgent;
use LWP::Protocol::https;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$CONTENT_TYPE_V1 = "application/vnd.netbackup+json; version=1.0";
$CONTENT_TYPE_V2 = "application/vnd.netbackup+json; version=2.0";
$CONTENT_TYPE_V3 = "application/vnd.netbackup+json; version=3.0";
$HYPERV = "Hyper-V";
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
  $req->header('content-type' => "$CONTENT_TYPE_V1");
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
    print "Successfully completed Login Request.\n\n";
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

  print "\n\nPerforming Logout Request on $logout_url\n";
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
  $jobs_req->header('content-type' => "$CONTENT_TYPE_V1");

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
  $catalog_req->header('content-type' => "$CONTENT_TYPE_V1");

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
# This function returns requested VM server.
#
sub getVM_Server {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 3) {
    print "ERROR :: Incorrect number of arguments passed to getVM_Server()\n";
    print "Usage : getVM_Server( <FQDN Hostname>, <Token>, <ServerName> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];
  my $servername = $_[2];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/config/servers/vmservers/";
  $url .= $servername;
  my $vmserver_req = HTTP::Request->new(GET => $url);
  $vmserver_req->header('Authorization' => $token);
  $vmserver_req->header('content-type' => "$CONTENT_TYPE_V2");

  my $ua = LWP::UserAgent->new(
    timeout => 500,
    ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing GET VM server request on $url\n";
  my $response = $ua->request($vmserver_req);
  if ($response->is_success) {
    print "Successfully completed GET VM server request.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: Get VM server request Failed!\n";
    print "HTTP GET error code: ", $response->code, "\n";
    print "HTTP GET error message: ", $response->message, "\n";
    #die;  let this fall through to cleanup code
  }

}

#
# This function returns a list of VM servers
#
sub getVM_Servers {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 2) {
    print "ERROR :: Incorrect number of arguments passed to getVM_Servers()\n";
    print "Usage : getVM_Servers( <FQDN Hostname>, <Token> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/config/servers/vmservers/";
  my $vmservers_req = HTTP::Request->new(GET => $url);
  $vmservers_req->header('Authorization' => $token);
  $vmservers_req->header('content-type' => "$CONTENT_TYPE_V2");

  my $ua = LWP::UserAgent->new(
    timeout => 500,
    ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing GET VM servers request on $url\n";
  my $response = $ua->request($vmservers_req);
  if ($response->is_success) {
    print "Successfully completed GET VM servers request.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: GET VM servers request Failed!\n";
    print "HTTP GET error code: ", $response->code, "\n";
    print "HTTP GET error message: ", $response->message, "\n";
    #die;  let this fall through to cleanup code
  }

}


#
# This function returns a list of all NetBackup resource limits
#
sub getAllResourceLimits {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 2) {
    print "ERROR :: Incorrect number of arguments passed to getAllResourceLimits()\n";
    print "Usage : getAllResourceLimits( <FQDN Hostname>, <Token> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/config/resource-limits";
  my $allResourceLimits_req = HTTP::Request->new(GET => $url);
  $allResourceLimits_req->header('Authorization' => $token);
  $allResourceLimits_req->header('content-type' => "$CONTENT_TYPE_V3");

  my $ua = LWP::UserAgent->new(
    timeout => 500,
    ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing GET all NetBackup resource limits request on $url\n";
  my $response = $ua->request($allResourceLimits_req);
  if ($response->is_success) {
    print "Successfully completed GET all NetBackup resource limits request.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: GET all NetBackup resource limits request Failed!\n";
    print "HTTP GET error code: ", $response->code, "\n";
    print "HTTP GET error message: ", $response->message, "\n";
    #die;  let this fall through to cleanup code
  }

}

#
# This function returns a list of resource limits for a given workload type.
#
sub getResourceLimits {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 3) {
    print "ERROR :: Incorrect number of arguments passed to getResourceLimits()\n";
    print "Usage : getResourceLimits( <FQDN Hostname>, <Token>, <Workload Type> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];
  my $workloadtype = $_[2];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/config/resource-limits/";
  $url .= $workloadtype;
  my $resourceLimits_req = HTTP::Request->new(GET => $url);
  $resourceLimits_req->header('Authorization' => $token);
  $resourceLimits_req->header('content-type' => "$CONTENT_TYPE_V3");

  my $ua = LWP::UserAgent->new(
    timeout => 500,
    ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing GET resource limits for a given workload type request on $url\n";
  my $response = $ua->request($resourceLimits_req);
  if ($response->is_success) {
    print "Successfully completed GET resource limits for a given workload type.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: GET resource limits for a given workload type request Failed!\n";
    print "HTTP GET error code: ", $response->code, "\n";
    print "HTTP GET error message: ", $response->message, "\n";
    #die;  let this fall through to cleanup code
  }

}

#
# This function returns a list of all NetBackup resource limits templates.
#
sub getAllResourceLimitsTemplates {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 2) {
    print "ERROR :: Incorrect number of arguments passed to getAllResourceLimitsTemplates()\n";
    print "Usage : getAllResourceLimitsTemplates( <FQDN Hostname>, <Token> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/config/resource-limit-templates";
  my $allResourceLimitsTemplates_req = HTTP::Request->new(GET => $url);
  $allResourceLimitsTemplates_req->header('Authorization' => $token);
  $allResourceLimitsTemplates_req->header('content-type' => "$CONTENT_TYPE_V3");

  my $ua = LWP::UserAgent->new(
    timeout => 500,
    ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing Get all resource limits templates request on $url\n";
  my $response = $ua->request($allResourceLimitsTemplates_req);
  if ($response->is_success) {
    print "Successfully completed Get all resource limits templates request.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: Get all resource limits templates Failed!\n";
    print "HTTP GET error code: ", $response->code, "\n";
    print "HTTP GET error message: ", $response->message, "\n";
    #die;  let this fall through to cleanup code
  }

}

#
# This function returns NetBackup resource limits template for a given workload type. 
#
sub getResourceLimitsTemplate {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 3) {
    print "ERROR :: Incorrect number of arguments passed to getResourceLimitsTemplate()\n";
    print "Usage : getResourceLimitsTemplate( <FQDN Hostname>, <Token>, <Workload Type> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];
  my $workloadtype = $_[2];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/config/resource-limit-templates/";
  $url .= $workloadtype;
  my $resourceLimitsTemplate_req = HTTP::Request->new(GET => $url);
  $resourceLimitsTemplate_req->header('Authorization' => $token);
  $resourceLimitsTemplate_req->header('content-type' => "$CONTENT_TYPE_V3");

  my $ua = LWP::UserAgent->new(
    timeout => 500,
    ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing GET resource limits template for a given workload type request on $url\n";
  my $response = $ua->request($resourceLimitsTemplate_req);
  if ($response->is_success) {
    print "Successfully completed GET resource limits template for a given workload type request.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: GET resource limits template for a given workload type Failed!\n";
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

#
# This function displays the Json content returned from VM Servers API
# in a tabular format
#
sub displayVM_Servers {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
    print "ERROR :: Incorrect number of arguments passed to displayVM_Servers()\n";
    print "Usage : displayVM_Servers( <Json content returned from Jobs API> ) \n";
    return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @vm_servers = @{$json->{'data'}};

  my @tablerows;

  foreach (@vm_servers) {
    my $vm_server = $_;

    my $serverName = $vm_server->{'attributes'}->{'vmServer'}->{'serverName'};
    my $vmType = $vm_server->{'attributes'}->{'vmServer'}->{'vmType'};
    my $userId = $vm_server->{'attributes'}->{'vmServer'}->{'userId'};
    my $port = $vm_server->{'attributes'}->{'vmServer'}->{'port'};

    my @tablerow = ($serverName, $vmType, $userId, $port);
    push @tablerows, \@tablerow;
  }

  my @title = ("Server Name", "VM Type", "User ID", "Port");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}

#
# This function displays the Json content returned from VM Server API
# in a tabular format
#
sub displayVM_Server {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
    print "ERROR :: Incorrect number of arguments passed to displayVM_Servers()\n";
    print "Usage : displayVM_Servers( <Json content returned from Jobs API> ) \n";
    return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);

  my $serverName = $json->{'vmServer'}->{'serverName'};
  my $vmType = $json->{'vmServer'}->{'vmType'};
  my $userId = $json->{'vmServer'}->{'userId'};
  my $port = $json->{'vmServer'}->{'port'};

  my @tablerow = ($serverName, $vmType, $userId, $port);
  push @tablerows, \@tablerow;

  my @title = ("Server Name", "VM Type", "User ID", "Port");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}


#
# This function displays the Json content returned from GET all resource limits API
# in a tabular format
#
sub displayAllResourceLimits {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
    print "ERROR :: Incorrect number of arguments passed to displayAllResourceLimits()\n";
    print "Usage : displayAllResourceLimits( <Json content returned from all resource limits API> ) \n";
    return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @allResourceLimits = @{$json->{'data'}};

  my @tablerows;

  foreach (@allResourceLimits) {
    my $allResourceLimitsElement = $_;
    my @resourceLimits = @{$allResourceLimitsElement->{'attributes'}->{'resources'}};
    my $workloadType = $allResourceLimitsElement->{'attributes'}->{'workloadType'};

    foreach(@resourceLimits) {
      my $resourceLimit = $_;

      my $resourceType = $resourceLimit->{'resourceType'};
      my $resourceName = $resourceLimit->{'resourceName'};
      my $resourceLimitValue = $resourceLimit->{'resourceLimit'};
      my @tablerow = ($workloadType, $resourceType, $resourceName, $resourceLimitValue);
      push @tablerows, \@tablerow;
    }
  }

  my @title = ("Workload Type", "Resource Type", "Resource Name", "Resource Limit");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}

#
# This function displays the Json content returned from GET resource limits for a given workload type API.
# in a tabular format
#
sub displayResourceLimits {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
    print "ERROR :: Incorrect number of arguments passed to displayResourceLimits()\n";
    print "Usage : displayResourceLimits( <Json content returned from resource limits API> ) \n";
    return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @resourceLimits = @{$json->{'data'}->{'attributes'}->{'resources'}};
  my $workloadType = $json->{'data'}->{'attributes'}->{'workloadType'};

  foreach(@resourceLimits) {
    my $resourceLimit = $_;

    my $resourceType = $resourceLimit->{'resourceType'};
    my $resourceName = $resourceLimit->{'resourceName'};
    my $resourceLimitValue = $resourceLimit->{'resourceLimit'};
    my @tablerow = ($workloadType, $resourceType, $resourceName, $resourceLimitValue);
    push @tablerows, \@tablerow;
  }

  my @title = ("Workload Type", "Resource Type", "Resource Name", "Resource Limit");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}

#
# This function displays the Json content returned from GET all resource limits templates API
# in a tabular format
#
sub displayAllResourceLimitsTemplates {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
    print "ERROR :: Incorrect number of arguments passed to displayAllResourceLimitsTemplates()\n";
    print "Usage : displayAllResourceLimitsTemplates( <Json content returned from all resource limits templates API> ) \n";
    return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @allResourceLimits = @{$json->{'data'}};

  my @tablerows;

  foreach (@allResourceLimits) {
    my $allResourceLimitsElement = $_;
    my @resourceLimits = @{$allResourceLimitsElement->{'attributes'}->{'resources'}};
    my $workloadType = $allResourceLimitsElement->{'attributes'}->{'workloadType'};

    foreach(@resourceLimits) {
      my $resourceLimit = $_;

      my $resourceType = $resourceLimit->{'resourceType'};
      my $resourceDescription = $resourceLimit->{'resourceDescription'};
      $resourceDescription = join('',split(/\n/,$resourceDescription));
      my $backupMethod = "";
      if($workloadType eq $HYPERV) {
        $backupMethod = $resourceLimit->{'backupMethod'};
      }

      my @tablerow = ($workloadType, $resourceType, $backupMethod, $resourceDescription);
      push @tablerows, \@tablerow;
    }
  }

  my @title = ("Workload Type", "Resource Type", "Backup Method", "Resource Description");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}


#
# This function displays the Json content returned from GET resource limits template for a given workload type API.
# in a tabular format
#
sub displayResourceLimitsTemplate {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
    print "ERROR :: Incorrect number of arguments passed to displayResourceLimitsTemplate()\n";
    print "Usage : displayResourceLimitsTemplate( <Json content returned from resource limits template API> ) \n";
    return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @resourceLimits = @{$json->{'data'}->{'attributes'}->{'resources'}};
  my $workloadType = $json->{'data'}->{'attributes'}->{'workloadType'};

  foreach(@resourceLimits) {
    my $resourceLimit = $_;

    my $resourceType = $resourceLimit->{'resourceType'};
    my $resourceDescription = $resourceLimit->{'resourceDescription'};
    $resourceDescription = join('',split(/\n/,$resourceDescription));
    my $backupMethod = "";
    if($workloadType eq $HYPERV) {
      $backupMethod = $resourceLimit->{'backupMethod'};
    }

    my @tablerow = ($workloadType, $resourceType, $backupMethod, $resourceDescription);
    push @tablerows, \@tablerow;
  }

  my @title = ("Workload Type", "Resource Type", "Backup Method", "Resource Description");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}

#
# This function returns a list of Asset based on
# a filter parameter
#

sub getAssetsByFilter {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 3) {
    print "ERROR :: Incorrect number of arguments passed to getAssetsByFilter()\n";
    print "Usage : getAssetsByFilter( <Asset filter> ) \n";
    return;
  }

  my $fqdn_hostname = $_[0];
  my $token = $_[1];
  my $filter = $_[2];

  my $url = "https://$fqdn_hostname:$NB_PORT/netbackup/assets?filter=$filter";
  my $assets_req = HTTP::Request->new(GET => $url);
  $assets_req->header('Authorization' => $token);
  $assets_req->header('content-type' => "$CONTENT_TYPE_V1");

  my $ua = LWP::UserAgent->new(
        timeout => 1000,
        ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing Get Assets Request on $url\n";
  my $response = $ua->request($assets_req);
  if ($response->is_success) {
    print "Successfully completed Get Assets by filter Request.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  }
  else {
    print "ERROR :: Get Assets Request Failed!\n";
    print "HTTP GET error code: ", $response->code, "\n";
    print "HTTP GET error message: ", $response->message, "\n";
  }

}

#
## This function displays the JSON content returned from Asset API
## using query filter in a tabular format
##
sub displayAssets {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
     print "ERROR :: Incorrect number of arguments passed to displayAssets()\n";
     print "Usage : displayAssets( <JSON content returned from Assets API> ) \n";
     return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @assets = @{$json->{'data'}};

  my @tablerows;

  foreach (@assets) {
     my $asset = $_;

     my $assetId = $asset->{'id'};
     my $assetType = $asset->{'attributes'}->{'assetType'};
     my $workloadType = $asset->{'attributes'}->{'workloadType'};
     my $displayName = $asset->{'attributes'}->{'displayName'};
     my $version = $asset->{'attributes'}->{'version'};

     my @tablerow = ($assetId, $assetType, $workloadType, $displayName, $version);
            push @tablerows, \@tablerow;
  }

  my @title = ("Asset ID", "Asset Type", "Workload Type", "Display Name", "Version");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}

#
## This function create the Json payload for the Asset Cleanup API
## It receives 2 paramters, the Json response from the GetAssetByFilter
## and the cleanupTime. The response of this function is a proper payload
## with all Assets from the filter.
##
sub createAssetCleanupPayload {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 2) {
     print "ERROR :: Incorrect number of arguments passed to createAssetCleanupPayload()\n";
     print "Usage : createAssetCleanupPayload( <Json content returned from Assets API>, <cleanupTime> ) \n";
     return;
  }

  my $jsonstring = $_[0];
  my $cleanupTime = $_[1];
  my $valid_input = "false"; 
  my $json = decode_json($jsonstring);
  my @assets = @{$json->{'data'}};

  my $payload = "{ \"data\":{ \"type\":\"assetCleanup\", \"id\":\"cleanupId\",";
  $payload = "$payload  \"attributes\": { \"cleanupTime\":\"$cleanupTime\",";
  $payload = "$payload \"assetIds\":[";

  foreach (@assets) {
    my $asset = $_;

    my $assetId = $asset->{'id'};
    $payload = " $payload \"$assetId\",";
    $valid_input = "true"; 
  }

  $payload = substr($payload, 0,  (length $payload) - 1);
  $payload = " $payload ] } } }";

  if ($valid_input eq "false"){ 
     return $valid_input;
  } else {
     return $payload;
  }

}

#
## This function makes the call to the Asset Cleanup API.
## If the web service goes successfully a HTTP 204 code is returned.
## Any other HTTP response code will be considered a error in the Asset Cleanup API.
##
sub cleanAssets {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 4) {
      print "ERROR :: Incorrect number of arguments passed to cleanAssets()\n";
      print "Usage : cleanAssets( <Host Name>, <Authorization Token>, <Json content returned from Assets API>, <Cleanup Time> ) \n";
      return;
   }

  my $hostname = $_[0];
  my $myToken = $_[1];
  my $jsonstring = $_[2];
  my $cleanuptime = $_[3];

  my $payload = createAssetCleanupPayload($jsonstring, $cleanuptime);

  if ($payload ne "false"){

  	my $asset_cleanup_url = "https://$hostname:$NB_PORT/netbackup/assets/asset-cleanup";
  	my $asset_cleanup_req = HTTP::Request->new(POST => $asset_cleanup_url);
  	$asset_cleanup_req->header('Authorization' => $myToken);
  	$asset_cleanup_req->header('content-type' => "$CONTENT_TYPE_V2");
  	$asset_cleanup_req->content($payload);

  	my $ua = LWP::UserAgent->new(
        	timeout => 1000,
        	ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  	);

  	print "\n\nPerforming Asset Cleanup Request on $asset_cleanup_url\n";
  	my $resp = $ua->request($asset_cleanup_req);
  	if ($resp->is_success) {
      		print "Successfully completed Asset Cleanup Request.\n";
  	}
  	else {
      		print "ERROR :: Asset Cleanup Request Failed!\n";
      		print "HTTP POST error code: ", $resp->code, "\n";
      		print "HTTP POST error message: ", $resp->message, "\n";
     	}
    } else {
	print "There is no asset to be clean\n";
   
    }
}

1;
