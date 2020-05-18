#!/usr/bin/env perl

use LWP::UserAgent;
use JSON;

my $content_type = "application/vnd.netbackup+json; version=4.0";

# Initialize HTTP client
my $http = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 0, verify_peer => 0 },
        protocols_allowed => ['https']
);

# List api keys
sub list_api_keys {
    my ($base_url, $token) = @_;

    my $media_type = "application/vnd.netbackup+json;version=4";
    my $api_keys_url = "$base_url/security/api-keys";

    # Update http client with default header
    $http->default_header('Accept' => $media_type);
    $http->default_header('Authorization' => $token);

    my $response = $http->get($api_keys_url);

    unless ($response->is_success) {
        print "HTTP GET error code: ", $response->code, "\n";
        print "HTTP GET error message: ", $response->message, "\n";

        die "Failed to get api keys.\n";
    }

    my $response_content = decode_json($response->content);
    print "API Keys: ", $response_content, "\n";
}

# List rbac roles
sub list_gen1_roles {
    my ($base_url, $token) = @_;

    my $media_type = "application/vnd.netbackup+json;version=1";
    my $gen1_roles_url = "$base_url/rbac/roles";

    $http->default_header('Accept' => $media_type);
    $http->default_header('Authorization' => $token);

    my $response = $http->get($gen1_roles_url);

    unless ($response->is_success) {
        print "HTTP GET error code: ", $response->code, "\n";
        print "HTTP GET error message: ", $response->message, "\n";

        die "Failed to get Gen-1 roles.\n";
    }

    my $response_content = decode_json($response->content);
    print "Gen-1 roles: ", $response_content, "\n";
}

# Create access control role
sub create_access_control_role {
    my ($base_url, $token, $name, $desc) = @_;

    my $media_type = "application/vnd.netbackup+json;version=4";
    my $access_control_roles_url = "$base_url/access-control/roles";

    $http->default_header('Accept' => $media_type);
    $http->default_header('Authorization' => $token);

    my %role = (
        'data' => {
            'type' => 'accessControlRole',
            'attribute' => {
                'name' => $name,
                'description' => $desc
	    }
	}
    );
    
    my $role_body = encode_json(\%role);

    my $response = $http->post($access_control_role_url, 'Content-Type' => $media_type, Content => $role_body);

    unless ($response->is_success) {
        print "HTTP POST error code: ", $response->code, "\n";
        print "HTTP POST error message: ", $response->message, "\n";

        die "Failed to create $name role.\n";
    }

    my $response_content = decode_json($response->content);
    my $new_role_id = $response_content->{data}{id};
    print "$name role created with ID $new_role_id\n";
}

1;
