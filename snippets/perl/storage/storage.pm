#!/usr/bin/env perl

package storage;

use common;
use JSON;
use warnings;
use LWP::UserAgent;
use LWP::Protocol::https;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$CONTENT_TYPE = "application/vnd.netbackup+json;version=3.0";
$PROTOCOL = "https://";
$NB_PORT = 1556;

# Create a storage server
sub post_storage_server {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to post_storage_server()\n";
        print "Usage : post_storage_server( <Master Server Hostname>, <Token>, <Payload>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-servers";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed POST Storage Server Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Storage Server Request Failed!\n";
    }
}

# Update storage server
sub patch_storage_server {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 4) {
        print "ERROR :: Incorrect number of arguments passed to patch_storage_server()\n";
        print "Usage : patch_storage_server( <Master Server Hostname>, <Token>, <Payload>, <stsid>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
	my $stsid = $_[3];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-servers/$stsid";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "PATCH", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed PATCH Storage Server Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: PATCH Storage Server Request Failed!\n";
    }
}

# Create a storage unit
sub post_storage_unit {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to post_storage_unit()\n";
        print "Usage : post_storage_unit( <Master Server Hostname>, <Token>, <Payload>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-units";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed POST Storage Unit Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Storage Unit Request Failed!\n";
    }
}

# Create a storage unit
sub post_disk_pool {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to post_disk_pool()\n";
        print "Usage : post_disk_pool( <Master Server Hostname>, <Token>, <Payload>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/disk-pools";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed POST Disk Pool Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Disk Pool Request Failed!\n";
    }
}

# get storage unit
sub get_storage_unit {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 2) {
        print "ERROR :: Incorrect number of arguments passed to get_storage_unit()\n";
        print "Usage : get_storage_unit( <Master Server Hostname>, <Token>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-units";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed GET Storage Unit Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: GET Storage Unit Request Failed!\n";
    }
}

# Update disk pool
sub patch_disk_pool {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 4) {
        print "ERROR :: Incorrect number of arguments passed to patch_disk_pool()\n";
        print "Usage : patch_disk_pool( <Master Server Hostname>, <Token>, <Payload>, <dpid>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
	my $filename = $_[2];
	my $dpid = $_[3];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/disk-pools/$dpid";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "PATCH", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed PATCH Disk Pool Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: PATCH Disk Pool Request Failed!\n";
    }
}

# get Disk Pool
sub get_disk_pool {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 2) {
        print "ERROR :: Incorrect number of arguments passed to get_disk_pool()\n";
        print "Usage : get_disk_pool( <Master Server Hostname>, <Token>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/disk-pools";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed GET DiskPool Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: GET DiskPool Request Failed!\n";
    }
}

# update storage unit
sub patch_storage_unit {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 4) {
        print "ERROR :: Incorrect number of arguments passed to patch_storage_unit()\n";
        print "Usage : patch_storage_unit( <Master Server Hostname>, <Token>, <Payload>, <Stu Name>) \n";
        return;
    }

    my $master_server = $_[0];
    my $stu_name = $_[3];
    my $token = $_[1];
	my $filename = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-units/$stu_name";
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	my $payload = "";
	while (my $row = <$fh>) {
	  chomp $row;
	  $payload .= $row;
	}
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "PATCH", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed PATCH Storage unit Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: PATCH Storage unit Request Failed!\n";
    }
}

# get storage server
sub get_storage_server {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 2) {
        print "ERROR :: Incorrect number of arguments passed to get_storage_server()\n";
        print "Usage : get_storage_server( <Master Server Hostname>, <Token>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-servers";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed GET Storage Server Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: GET Storage Server Request Failed!\n";
    }
}

# get storage server
sub delete_storage_server {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to delete_storage_server()\n";
        print "Usage : delete_storage_server( <Master Server Hostname>, <Token>, <stsid>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $stsid = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-servers/$stsid";

    my $json = common::send_http_request($url, "DELETE", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed DELETE Storage Server Request.\n";

    }
    else {
        print "ERROR :: DELETE Storage Server Request Failed!\n";
    }
}

# delete disk pool
sub delete_disk_pool {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to delete_disk_pool()\n";
        print "Usage : delete_disk_pool( <Master Server Hostname>, <Token>, <dpid>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $dpid = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/disk-pools/$dpid";

    my $json = common::send_http_request($url, "DELETE", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed DELETE Disk Pool Request.\n";
    }
    else {
        print "ERROR :: DELETE Disk pool Request Failed!\n";
    }
}

# delete disk pool
sub delete_storage_unit {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to delete_storage_unit()\n";
        print "Usage : delete_storage_unit( <Master Server Hostname>, <Token>, <stu_name>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $stu_name = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-units/$stu_name";

    my $json = common::send_http_request($url, "DELETE", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed DELETE Storage unit Request.\n";
    }
    else {
        print "ERROR :: DELETE Storage unit Request Failed!\n";
    }
}

# get storage server
sub get_storage_server_by_id {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to get_storage_server_by_id()\n";
        print "Usage : get_storage_server_by_id( <Master Server Hostname>, <Token>, <stsid>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $stsid = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-servers/$stsid";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
         print "Successfully completed GET Storage Server Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;

    }
    else {
        print "ERROR :: GET Storage Server by ID Failed!\n";
    }
}

# delete disk pool
sub get_disk_pool_by_id {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to get_disk_pool_by_id()\n";
        print "Usage : get_disk_pool_by_id( <Master Server Hostname>, <Token>, <dpid>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $dpid = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/disk-pools/$dpid";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
         print "Successfully completed GET Disk Pool Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: GET Disk Pool by ID Request Failed!\n";
    }
}

# delete disk pool
sub get_storage_unit_by_name {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to get_storage_unit_by_name()\n";
        print "Usage : get_storage_unit_by_name( <Master Server Hostname>, <Token>, <stu_name>) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $stu_name = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/storage/storage-units/$stu_name";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
         print "Successfully completed GET Storage Unit Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: GET Storage unit by Name Request Failed!\n";
    }
}
1;

