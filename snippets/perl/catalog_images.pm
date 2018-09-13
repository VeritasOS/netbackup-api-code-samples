package catalog_images;
use strict;
use warnings FATAL => 'all';

use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(abs_path $0);

use common;

# Constants
my $CONTENT_TYPE_V2 = "application/vnd.netbackup+json; version=2.0";

# Variables
my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, verify_peer => 0});


=head1 get_images

 SYNOPSIS
    This subroutine calls GET /catalog/images API with the specified criteria to get a page of images

 PARAMETERS
    $_[0] - string
        The master server
    $_[1] - string
        The authenication token
    $_[2] - string - optional
        The filter to use while gathering images
    $_[3] - string - optional
        The page limit
    $_[4] - string - optional
        The page offset

 RETURNS
    The serialized json, or undef if an error occurred

=cut
sub get_images {
    my $filter;
    my $page_limit;
    my $offset;

    my $master_server = $_[0];
    my $token = $_[1];
    if (exists $_[2]){
        $filter = $_[2];
    }
    if (exists $_[3]){
        $page_limit = $_[3];
    }
    if (exists $_[4]){
        $offset = $_[4];
    }

    # construct the url
    my $url = "https://$master_server:1556/netbackup/catalog/images";
    my $append_char = "?";
    if (defined $filter){
        $url = "$url$append_char" . "filter=$filter";
        $append_char = "&";
    }
    if (defined $page_limit){
        $url = "$url$append_char" . "page[limit]=$page_limit";
        $append_char = "&";
    }
    if (defined $offset){
        $url = "$url$append_char" . "page[offset]=$offset";
    }

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to view existing images \n\n";

    my $json_results = common::send_http_request($url, "get", $token, undef, $CONTENT_TYPE_V2, undef);
    return $json_results;
}

=head1 get_image_details

 SYNOPSIS
    This subroutine gets information about a specified image

 PARAMETERS
    $_[0] - string
        The master server
    $_[1] - string
        The authenication token
    $_[2] - string
        The backup id of the image

=cut
sub get_image_details {
    my $master_server = $_[0];
    my $token = $_[1];
    my $backup_id = $_[2];

    if (not defined $backup_id){
        print "Error: backup id is a required field";
        return undef;
    }

    my $url = "https://$master_server:1556/netbackup/catalog/images/$backup_id";

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to view specified image [$backup_id] \n\n";

    my $json_results = common::send_http_request($url, "get", $token, undef, $CONTENT_TYPE_V2, undef);
    return $json_results;
}

=head1 get_vmware_images

 SYNOPSIS
    This subroutine calls GET /catalog/vmware-images API with the specified criteria to get a page of vmware images

 PARAMETERS
    $_[0] - string
        The master server
    $_[1] - string
        The authenication token
    $_[2] - string - optional
        The filter to use while gathering vmware images
    $_[3] - string - optional
        The page limit
    $_[4] - string - optional
        The page offset

 RETURNS
    The serialized json, or undef if an error occurred

=cut
sub get_vmware_images {
    my $filter;
    my $page_limit;
    my $offset;
    my $master_server = $_[0];
    my $token = $_[1];
    if (exists $_[2]){
        $filter = $_[2];
    }
    if (exists $_[3]){
        $page_limit = $_[3];
    }
    if (exists $_[4]){
        $offset = $_[4];
    }

    # construct the url
    my $url = "https://$master_server:1556/netbackup/catalog/vmware-images";
    my $append_char = "?";
    if (defined $filter){
        $url = "$url$append_char" . "filter=$filter";
        $append_char = "&";
    }
    if (defined $page_limit){
        $url = "$url$append_char" . "page[limit]=$page_limit";
        $append_char = "&";
    }
    if (defined $offset){
        $url = "$url$append_char" . "page[offset]=$offset";
    }

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to view existing vmware images \n\n";

    my $json_results = common::send_http_request($url, "get", $token, undef, $CONTENT_TYPE_V2, undef);
    return $json_results;
}

=head1 get_vmware_image_details

 SYNOPSIS
    This subroutine gets information about a specified vmware image

 PARAMETERS
    $_[0] - string
        The master server
    $_[1] - string
        The authenication token
    $_[2] - string
        The backup id of the vmware image

 RETURNS
    The serialized json response, or undef if an error occurred

=cut
sub get_vmware_image_details {
    my $master_server = $_[0];
    my $token = $_[1];
    my $backup_id = $_[2];

    if (not defined $backup_id){
        print "Error: backup id is a required field";
        return undef;
    }

    my $url = "https://$master_server:1556/netbackup/catalog/vmware-images/$backup_id";

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to view specified vmware image [$backup_id] \n\n";

    my $json_results = common::send_http_request($url, "get", $token, undef, $CONTENT_TYPE_V2, undef);
    return $json_results;
}

=head1 get_request_id

 SYNOPSIS
    This subroutine retrieves a request ID that can be used to list all contents of a specified image

 PARAMETERS
    $_[0] - string
        The master server
    $_[1] - string
        The authenication token
    $_[2] - string
        The backup ID of the image for which you wish to list all contents
    $_[3] - string - optional
        The page limit

 RETURNS
    The request ID, or undef if an error occurred

=cut
sub get_request_id {
    my $page_limit;
    my $master_server = $_[0];
    my $token = $_[1];
    my $backup_id = $_[2];

    if (exists $_[3]){
        $page_limit = $_[3];
    }

    if (not defined $backup_id){
        print "Error: backup id is a required field";
        return undef;
    }

    # construct the url
    my $url = "https://$master_server:1556/netbackup/catalog/images/$backup_id/contents";
    if (defined $page_limit){
        $url = "$url?page[limit]=$page_limit";
    }

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to retrieve request ID for backup ID [$backup_id] \n URL: $url \n";

    my $json_results = common::send_http_request($url, "get", $token, undef, $CONTENT_TYPE_V2, undef);
    if (exists $json_results->{"requestId"}){
        return $json_results->{"requestId"};
    }
    else {
        return undef;
    }
}

=head1 get_image_contents

 SYNOPSIS
    This subroutine gets the image contents for the image provided with the specified request ID.
    Calling this subroutine requires calling get_request_id first to obtain a request ID.

 PARAMETERS
    $_[0] - string
        The master server
    $_[1] - string
        The authenication token
    $_[2] - string
        The request ID

 RETURNS
    The serialized json response

=cut
sub get_image_contents {
    my $master_server = $_[0];
    my $token = $_[1];
    my $request_id = $_[2];

    my $url = "https://$master_server:1556/netbackup/catalog/images/contents/$request_id";

    print "\n\n**************************************************************";
    print "\n\n Making GET Request to retrieve contents for specified request ID [$request_id] \n URL: $url \n";

    my $json_results = common::send_http_request($url, "get", $token, undef, $CONTENT_TYPE_V2, undef);
    return $json_results;
}

1;