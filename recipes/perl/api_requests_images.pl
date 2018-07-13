#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../snippets/perl";

use common;
use gateway;
use catalog_images;

use LWP::UserAgent;
use HTTP::Request;
use JSON;
use Getopt::Long qw(GetOptions);

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

#
# Login and get token
#
my $token = gateway::perform_login($master_server, $username, $password, $domain_name, $domain_type);

#
# Get the first two pages of images, and record their backup ids
#
my $backup_ids = get_all_images(undef, 2);

#
# Check if there are any backup ids in the list, and if so, list details for the first one
#
if (exists $backup_ids->[0]){
    my $json_results = catalog_images::get_image_details($master_server, $token, $backup_ids->[0]);
    if ($verbose and defined $json_results){
        print JSON->new->pretty->encode($json_results);
    }
}
else {
    print "No images were found\n\n";
}

#
# Get the first two pages of vmware images, and record their backup ids
#
my $vmware_backup_ids = get_all_vmware_images(undef, 2);

#
# Check if there are any backup ids in the list, and if so, list details for the first one
#
if (exists $vmware_backup_ids->[0]) {
    my $json_results = catalog_images::get_vmware_image_details($master_server, $token, $vmware_backup_ids->[0]);
    if ($verbose and defined $json_results){
        print JSON->new->pretty->encode($json_results);
    }
}
else {
    print "No vmware images were found\n\n";
}

#
# Let's try a sample filter, to demonstrate encoding
#
my $filter = "backupId eq 'a%20b_123'";
$backup_ids = get_all_images($filter);

#
# By default, the get images and get vmware images APIs filter on images that are within the last 24 hours.
# Let's try getting the first page of values since January 2nd 2016
#
$filter = "backupTime ge '2016-01-02T00:00:00.000Z'";
my $json_results = catalog_images::get_images($master_server, $token, $filter);
if ($verbose and defined $json_results){
    print JSON->new->pretty->encode($json_results);
}

=head1 get_all_images

 SYNOPSIS
    This subroutine calls get_images with proper pagination.

 PARAMETERS
    $_[0] - string - optional
        The filter to use while gathering images
    $_[1] - int - optional
        The number of pages to get. Must be 1 or greater

 RETURNS
    An array reference of the backup IDs found

=cut
sub get_all_images {
    my $filter;
    my $num_pages;
    my $page_limit = 10; #This matches the default value
    my $offset = 0;
    my @backup_ids;

    if (exists $_[0]){
        $filter = $_[0];
    }
    if (exists $_[1]){
        $num_pages = $_[1];
        if ($num_pages <= 1){
            print "Number of pages must be 1 or more";
            return \@backup_ids;
        }
    }

    my $json_results = catalog_images::get_images($master_server, $token, $filter, $page_limit, $offset);
    if ($verbose and defined $json_results){
        print JSON->new->pretty->encode($json_results);
    }

    my $pages_so_far = 1;
    while (defined $json_results) {
        # Save the first backup id, if it exists
        foreach my $data_entry (@{$json_results->{"data"}}) {
            push @backup_ids, $data_entry->{"id"};
        }

        # Determine if there is a next page, and if so call the API again
        if (exists $json_results->{"meta"}{"pagination"}{"next"} and $num_pages > $pages_so_far){
            $json_results = catalog_images::get_images($master_server, $token, $filter, $page_limit, $json_results->{"meta"}{"pagination"}{"next"});
            $pages_so_far = $pages_so_far + 1;
            if ($verbose and defined $json_results){
                print JSON->new->pretty->encode($json_results);
            }
        }
        else {
            last;
        }
    }

    return \@backup_ids;
}

=head1 get_all_vmware_images

 SYNOPSIS
    This subroutine prints information about all vmware images on the system.

 PARAMETERS
    $_[0] - string - optional
        The filter to use while gathering images
    $_[1] - int - optional
        The number of pages to retrieve. Must be 1 or more.

 RETURNS
    An array reference of the backup IDs found

=cut
sub get_all_vmware_images {
    my $filter;
    my $num_pages;
    my $page_limit = 10; #This matches the default value
    my $offset = 0;
    my @backup_ids;
    if (exists $_[0]){
        $filter = $_[0];
    }
    if (exists $_[1]){
        $num_pages = $_[1];
    }

    my $json_results = catalog_images::get_vmware_images($master_server, $token, $filter, $page_limit, $offset);
    if ($verbose and defined $json_results){
        print JSON->new->pretty->encode($json_results);
    }

    my $pages_so_far = 1;
    while (defined $json_results) {
        # Save the backup IDs
        foreach my $data_entry (@{$json_results->{"data"}}) {
            push @backup_ids, $data_entry->{"id"};
        }

        # Determine if there is a next page, and if so call the API again
        if (exists $json_results->{"meta"}{"pagination"}{"next"} and $num_pages > $pages_so_far){
            $json_results = catalog_images::get_vmware_images($master_server, $token, $filter, $page_limit, $json_results->{"meta"}{"pagination"}{"next"});
            if ($verbose and defined $json_results){
                print JSON->new->pretty->encode($json_results);
            }
            $pages_so_far = $pages_so_far + 1;
        }
        else {
            last;
        }
    }

    return \@backup_ids;
}
