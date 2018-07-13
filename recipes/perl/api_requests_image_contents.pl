#!/usr/bin/env perl
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use JSON;
use Getopt::Long qw(GetOptions);

use FindBin;
use lib "$FindBin::RealBin/../../snippets/perl";

use gateway;
use catalog_images;

# Constants
my $CONTENT_TYPE_V2 = "application/vnd.netbackup+json; version=2.0";

# Variables
my $master_server;
my $username;
my $password;
my $domain_name;
my $domain_type;
my $verbose;

sub printUsage {
  print "\nUsage : perl api_requests_images.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n";
  die;
}

GetOptions(
'nbmaster=s' => \$master_server,
'username=s' => \$username,
'password=s' => \$password,
'domainname=s' => \$domain_name,
'domaintype=s' => \$domain_type,
'verbose' => \$verbose,
) or printUsage();

if (!$master_server || !$username || !$password) {
  printUsage();
}

my $token = gateway::perform_login($master_server, $username, $password, $domain_name, $domain_type);

my $json_results = catalog_images::get_images($master_server, $token);
if ($verbose and defined $json_results){
    print JSON->new->pretty->encode($json_results);
}
if (exists $json_results->{"data"}[0]{"id"}){
    my $backup_id = $json_results->{"data"}[0]{"id"};
    my $files = get_all_image_contents($backup_id);
    my $file_count = scalar(@$files);
    print "Found $file_count files in image with backup ID $backup_id\n";
}
else {
    print "No images were found\n";
}

=head1 get_all_image_contents

 SYNOPSIS
    This subroutine retrieves a list of all files in a specified image

 PARAMETERS
    $_[0] - string
        The backup ID of the image for which you wish to list all contents

 RETURNS
    An array reference containing the absolute path to each file in the image

=cut
sub get_all_image_contents {
    my $page_limit = 200; #This matches the default value
    my @files;
    my $backup_id = $_[0];
    if (not defined $backup_id){
        print "Error: backup ID is a required field\n";
        return \@files;
    }

    my $request_id = catalog_images::get_request_id($master_server, $token, $backup_id);
    my $json_results = catalog_images::get_image_contents($master_server, $token, $request_id);
    if ($verbose and defined $json_results) {
        print JSON->new->pretty->encode($json_results);
    }

    # continute calling image contents API with the same request ID until we get a 404
    while (defined $json_results) {
        # Save the file names
        foreach my $data_entry (@{$json_results->{"data"}}) {
            push @files, $data_entry->{"attributes"}{"filePath"};
        }

        $json_results = catalog_images::get_image_contents($master_server, $token, $request_id);
        if ($verbose and defined $json_results){
            print JSON->new->pretty->encode($json_results);
        }
    }

    print "\nPrevious 404 marks the end of image contents\n";
    return \@files;
}