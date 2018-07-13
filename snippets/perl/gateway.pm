package gateway;
use strict;
use warnings;
use common;

=head1 perform_login

 SYNOPSIS
    This subroutine is used to call login api using user credentials to get the token to be used by subsequent API calls

 PARAMETERS
    @param $_[0] - string
        The name of the master server.
        Ex: myhostname.myDomain.com
    @param $_[1] - string
        The username.
    @param $_[2] - string
        The password.
    @param $_[3] - string - optional
        The domain name
    @param $_[4] - string - optinoal
        The domain type

=cut
sub perform_login {
    my @argument_list = @_;
    my $master_server = $argument_list[0];
    my $username = $argument_list[1];
    my $password = $argument_list[2];

    my $token;

    # domainName and domainType are optional
    my $domainName = "";
    my $domainType = "";
    if (@argument_list >= 4) {
        $domainName = $argument_list[3];
    }
    if (@argument_list == 5) {
        $domainType = $argument_list[4];
    }

    # Construct url
    my $url = "https://$master_server:1556/netbackup/login";

    # Construct request body
    my $post_data;
    if (not $domainName and not $domainType) {
        $post_data = qq({ "userName": "$username", "password": "$password" });
    }
    else {
        $post_data = qq({ "domainType": "$domainType", "domainName": "$domainName", "userName": "$username", "password": "$password" });
    }

    print "\n\n**************************************************************";
    print "\n\n Making POST Request to login to get token \n\n";

    my $json_results = common::send_http_request($url, "post", undef, $post_data, undef, "application/json");

    if (defined $json_results){
        $token = $json_results->{"token"};
    }
    return $token;
}

=head1 perform_logout

 SYNOPSIS
    This subroutine is used to call logout api using the user's token.

 PARAMETERS
    @param $_[0] - string
        The name of the master server.
        Ex: myhostname.myDomain.com
    @param $_[1] - string
        The token.

=cut
sub perform_logout {
    my @argument_list = @_;
    my $master_server = $argument_list[0];
    my $token = $argument_list[1];

    # Construct url
    my $url = "https://$master_server:1556/netbackup/logout";
    my $results = common::send_http_request($url, "post", $token, undef, undef, undef);

    if (defined $results) {
        print "Successfully completed Logout Request.\n";
    }
    else {
        print "ERROR: Logout Request Failed!\n";
    }
}
1;
