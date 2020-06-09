#!/usr/bin/env perl

package eventlogs;

use JSON;
use warnings;
use Text::Table;
use LWP::UserAgent;
use LWP::Protocol::https;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$CONTENT_TYPE_V4 = "application/vnd.netbackup+json; version=4.0";
$NB_PORT = 1556;

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
# This function returns a list of notifications based on
# a filter parameter
#

sub getNotificationsByFilter {

  my $arguments_count = scalar(@_);
  my $fqdn_hostname;
  my $token;
  my $filter;

  if ($arguments_count == 2) {
    $fqdn_hostname = $_[0];
    $token = $_[1];
  } elsif ($arguments_count == 3) {
    $fqdn_hostname = $_[0];
    $token = $_[1];
    $filter = $_[2];
  } else {
    print "ERROR :: Incorrect number of arguments passed to getNotificationsByFilter()\n";
    print "Usage : getNotificationsByFilter( <FQDN Hostname>, <Token>. (optional) <filter> ) \n";
    return;
  }

  my $url;
  if ($filter) {
    $url = "https://$fqdn_hostname:$NB_PORT/netbackup/eventlog/notifications?filter=$filter";
  } else {
    $url = "https://$fqdn_hostname:$NB_PORT/netbackup/eventlog/notifications";
  }

  my $notifications_req = HTTP::Request->new(GET => $url);
  $notifications_req->header('Authorization' => $token);

  my $ua = LWP::UserAgent->new(
        timeout => 1000,
        ssl_opts => { verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE },
  );

  print "Performing Get Notifications Request on $url\n";
  my $response = $ua->request($notifications_req);
  if ($response->is_success) {
    print "Successfully completed Get Notifications Request.\n";

    $data = decode_json($response->content);
    my $pretty = JSON->new->pretty->encode($data);
    return $pretty;
  } else {
    print "ERROR :: Get Notifications Request Failed!\n";
    print "HTTP GET error code: ", $response->code, "\n";
    print "HTTP GET error message: ", $response->message, "\n";
  }

}

#
## This function displays the JSON content returned from GET Notifications API
## using query filter in a tabular format
##
sub displayNotifications {

  my $arguments_count = scalar(@_);
  if ($arguments_count != 1) {
     print "ERROR :: Incorrect number of arguments passed to displayNotifications()\n";
     print "Usage : displayNotifications( <JSON content returned from GET Notifications API> ) \n";
     return;
  }

  my $jsonstring = $_[0];
  my $json = decode_json($jsonstring);
  my @notifications = @{$json->{'data'}};

  my @tablerows;

  foreach (@notifications) {
     my $notification = $_;

     my $type = $notification->{'type'};
     my $id = $notification->{'id'};
     my $version = $notification->{'attributes'}->{'version'};
     my $priority = $notification->{'attributes'}->{'priority'};
     my $severity = $notification->{'attributes'}->{'severity'};
     my $createdDateTime = $notification->{'attributes'}->{'createdDateTime'};
     my $insertionDateTime = $notification->{'attributes'}->{'insertionDateTime'};
     my $displayString = $notification->{'attributes'}->{'displayString'};
     my $notificationType = $notification->{'attributes'}->{'notificationType'};
     my $producerName = $notification->{'attributes'}->{'producerName'};
     my $producerId = $notification->{'attributes'}->{'producerId'};
     my $producerType = $notification->{'attributes'}->{'producerType'};
     my $producerSubType = $notification->{'attributes'}->{'producerSubType'};
     my $namespace = $notification->{'attributes'}->{'namespace'};

     my @tablerow = ($type, $id, $version, $priority, $severity, $createdDateTime, $insertionDateTime, $displayString,
                           $notificationType, $producerName, $producerId, $producerType,
                           $producerSubType, $namespace);
            push @tablerows, \@tablerow;
  }

  my @title = ("Type", "ID", "Version", "Priority", "Severity", "Created Date Time", "Insertion Date Time",
                  "Display String", "Notification Type", "Producer Name", "Producer ID", "Producer Type",
                  "Producer Sub Type", "Namespace");
  print "\n";
  displayDataInTable(\@title, \@tablerows);
  print "\n";

}

# Post notifications
sub postNotifications {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to postNotifications()\n";
        print "Usage : postNotifications( <Master Server Hostname>, <Token>, <Payload>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
    my $url = "https://$master_server:$NB_PORT/netbackup/eventlog/notifications";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";

	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE_V4);

    if (defined $json) {
        print "Successfully completed POST Notifications.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Notifications Request Failed!\n";
    }
}

1;
