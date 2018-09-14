#!/usr/bin/env perl

package asset_group;

use common;
use JSON;
use warnings;
use LWP::UserAgent;
use LWP::Protocol::https;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$CONTENT_TYPE = "application/vnd.netbackup+json;version=2.0";
$PROTOCOL = "https://";
$NB_PORT = 1556;

# Retrieve asset groups
sub get_asset_groups {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 2) {
        print "ERROR :: Incorrect number of arguments passed to getAssetGroups()\n";
        print "Usage : get_asset_groups( <Master Server Hostname>, <Token> ) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/asset-groups";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed Get Asset-Groups Request.\n";
        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: Get Asset-Groups Request Failed!\n";
    }
}

# Create a new asset group
sub post_asset_groups {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 2) {
        print "ERROR :: Incorrect number of arguments passed to postAssetGroups()\n";
        print "Usage : post_asset_groups( <Master Server Hostname>, <Token> ) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/asset-groups";
    my $payload = qq({
                        "data": {
                            "attributes": {
                                "assetType": "Virtual Machine",
                                "displayName": "DemoAssetGroup",
                                "filterConstraint": "abc",
                                "workloadType": "VMware"
                            },
                            "type": "assetGroup"
                        }
                    });
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed POST Asset-Groups Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Asset-Groups Request Failed!\n";
    }
}

# Retrieves a list of assets that would be included in an asset group without actually creating one
sub post_preview_asset_group {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 2) {
        print "ERROR :: Incorrect number of arguments passed to postPreviewAssetGroup()\n";
        print "Usage : post_preview_asset_group( <Master Server Hostname>, <Token> ) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/preview-asset-group";
    my $payload = qq({
                        "data": {
                            "attributes": {
                                "filterConstraint": "abc",
                                "oDataQueryFilter": "true",
                                "workloadType": "VMware"
                            },
                            "type": "assetGroupPreview"
                        }
                    });
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "POST", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed POST Asset-Groups Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: POST Asset-Groups Request Failed!\n";
    }
}

# Update an existing asset group.
sub patch_asset_groups {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to patchAssetGroups()\n";
        print "Usage : patch_asset_groups( <Master Server Hostname>, <Token>, <AssetGroupGuid> ) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $guid = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/asset-groups/$guid";
    my $payload = qq({
                        "data": {
                            "attributes": {
                                "displayName": "DemoAssetGroupUpdated",
                                "odataFilterCriteria": "true"
                            },
                            "type": "assetGroup"
                        }
                    });
    print "payload: $payload\n";

    my $json = common::send_http_request($url, "PATCH", $token, $payload, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed PATCH Asset-Groups Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: PATCH Asset-Groups Request Failed!\n";
    }
}

# Delete an access group.
sub delete_asset_groups {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to deleteAssetGroups()\n";
        print "Usage : delete_asset_groups( <Master Server Hostname>, <Token>, <AssetGroupGuid> ) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $guid = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/asset-groups/$guid";

    my $json = common::send_http_request($url, "DELETE", $token, undef, undef, undef);

    if (defined $json) {
        print "Successfully completed DELETE Asset-Groups Request.\n";
    }
    else {
        print "ERROR :: DELETE Asset-Groups Request Failed!\n";
    }
}

# Retrieves the specified asset group
sub get_asset_groups_with_guid {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to getAssetGroupsWithGuid()\n";
        print "Usage : get_asset_groups_with_guid( <Master Server Hostname>, <Token>, <Guid> ) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $guid = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/asset-groups/$guid";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed Get Asset-Groups with Guid Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: Get Asset-Groups with Guid Request Failed!\n";
    }
}

# Retrieves the asset groups to which the given asset belongs.
sub get_asset_guid_asset_groups {
    my $arguments_count = scalar(@_);
    if ($arguments_count != 3) {
        print "ERROR :: Incorrect number of arguments passed to getAssetGroupsWithGuid()\n";
        print "Usage : get_asset_guid_asset_groups( <Master Server Hostname>, <Token>, <Guid> ) \n";
        return;
    }

    my $master_server = $_[0];
    my $token = $_[1];
    my $guid = $_[2];
    my $url = "$PROTOCOL$master_server:$NB_PORT/netbackup/assets/$guid/asset-groups";

    my $json = common::send_http_request($url, "GET", $token, undef, undef, $CONTENT_TYPE);

    if (defined $json) {
        print "Successfully completed Get Asset guid asset group Request.\n";

        my $pretty = JSON->new->pretty->encode($json);
        return $pretty;
    }
    else {
        print "ERROR :: Get Asset guid asset group Request Failed!\n";
    }
}

1;
