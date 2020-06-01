package migration;

use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use LWP::Protocol::https;
use Try::Tiny;

# constants
my $BASE_URL;
my $MIGRATION_NB_CONTENT_TYPE_V4 = "application/vnd.netbackup+json; version=4.0";

my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

=head1 initiate_migration
 SYNOPSIS
    This subroutine is used to call /security/certificate-authorities/initiate-migration api to
    initiate CA migration with specified keysize.
 PARAMETERS
    @param $_[0] - string
        The name of the master server.
        Ex: myhostname.myDomain.com
    @param $_[1] - string
        The authentication token fetched after invoking /login api using 
        user credentials or apikey.
    @param $_[2] - int
        Keysize of the CA.
    @param $_[3] - string - optional
        A textual description for initiating the CA migration process.
		  
 RETURNS
    None
=cut

sub initiate_migration {
    my @argument_list = @_;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];
    my $keysize = $argument_list[2];
    my $des;
    if (defined $argument_list[3]) {
        $des = $argument_list[3];
    }

    my $url = "$base_url/security/certificate-authorities/initiate-migration";
    my $req = HTTP::Request->new(POST => $url);
    $req->header('Content-Type' => $MIGRATION_NB_CONTENT_TYPE_V4);
    $req->header('Authorization' => $token);
    $req->header('X-NetBackup-Audit-Reason' => $des) if (defined $des);
    my $post_data = qq({ "data": { "type": "initiateCAMigrationRequest", "attributes": {
                         "keySize": $keysize } } });

    $req->content($post_data);

    print "\n**************************************************************";
    print "\n Making POST Request to initiate CA migration \n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
         my $message = decode_json($resp->content);
         print "Successfully initiated the CA migration with status code: ", $resp->code, "\n";
         print "Printing the response content: ", $resp->decoded_content, "\n";
    } else {
         printErrorResponse($resp);
    }
}

=head1 activate_migration
 SYNOPSIS
    This subroutine is used to call /security/certificate-authorities/activate api to
    activate the new CA in migration process.
 PARAMETERS
    @param $_[0] - string
        The name of the master server.
        Ex: myhostname.myDomain.com
    @param $_[1] - string
        The authentication token fetched after invoking /login api using 
        user credentials or apikey.
    @param $_[2] - string - optional
        A textual description to activate the new CA.
    @param $_[3] - int [0/1] - optional
        Forcefully activate the new CA.
		  
 RETURNS
    None
=cut

sub activate_migration {
    my @argument_list = @_;
    my $force = 0;
    my $reason;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];
    if (@argument_list == 4) {
        $reason = $argument_list[2];
        $force = $argument_list[3];
    } elsif (@argument_list == 3) {
        $force = $argument_list[2];
    }

    my $url = "$base_url/security/certificate-authorities/activate";
    my $req = HTTP::Request->new(POST => $url);
    $req->header('Content-Type' => $MIGRATION_NB_CONTENT_TYPE_V4);
    $req->header('Authorization' => $token);
    $req->header('X-NetBackup-Audit-Reason' => $reason) if (defined $reason);
    my $post_data;
    if ($force) {
        $post_data = qq({ "data": { "type": "nbcaMigrationActivateRequest", "attributes": {
                         "force": "true" } } });
    }
    else {
        $post_data = qq({ "data": { "type": "nbcaMigrationActivateRequest", "attributes": { }}});
    }

    $req->content($post_data);

    print "\n**************************************************************";
    print "\n Making POST Request to activate the new CA \n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
         print "Successfully activated the new CA with status code: ", $resp->code, "\n";
    } else {
         printErrorResponse($resp);
    }
}

=head1 complete_migration
 SYNOPSIS
    This subroutine is used to call /security/certificate-authorities/complete-migration api to
    complete the CA migration process.
 PARAMETERS
    @param $_[0] - string
        The name of the master server.
        Ex: myhostname.myDomain.com
    @param $_[1] - string
        The authentication token fetched after invoking /login api using 
        user credentials or apikey.
    @param $_[2] - string - optional
        A textual description to complete the CA migration process.
    @param $_[3] - int [0/1] - optional
        Forcefully complete the CA migration process.
		  
 RETURNS
    None
=cut

sub complete_migration {
    my @argument_list = @_;
    my $force = 0;
    my $reason;
    my $base_url = $argument_list[0];
    my $token = $argument_list[1];

    if (@argument_list == 4) {
        $reason = $argument_list[2];
        $force = $argument_list[3];
    } elsif (@argument_list == 3) {
        $force = $argument_list[2];
    }

    my $url = "$base_url/security/certificate-authorities/migration-complete";
    my $req = HTTP::Request->new(POST => $url);
    $req->header('Content-Type' => $MIGRATION_NB_CONTENT_TYPE_V4);
    $req->header('Authorization' => $token);
    $req->header('X-NetBackup-Audit-Reason' => $reason) if (defined $reason);
    my $post_data;
    if ($force) {
        $post_data = qq({ "data": { "type": "nbcaMigrationCompleteRequest", "attributes": {
                         "force": "true" } } });
    }
    else {
        $post_data = qq({ "data": { "type": "nbcaMigrationCompleteRequest", "attributes": { }}});
    }

    $req->content($post_data);

    print "\n**************************************************************";
    print "\n Making POST Request to complete the CA migration\n";

    my $resp = $ua->request($req);
    if ($resp->is_success) {
         print "CA migration completed successfully with status code: ", $resp->code, "\n";
    } else {
         printErrorResponse($resp);
    }
}
 
sub printErrorResponse {
    my @argument_list = @_;
    my $resp = $argument_list[0];

    print "Request failed with status code: ", $resp->code, "\n\n";
    print "Response: ", $resp->content, "\n";
}

1;
