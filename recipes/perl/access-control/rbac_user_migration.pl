#!/usr/bin/env perl
# $Copyright: Copyright (c) 2020 Veritas Technologies LLC. All rights reserved $

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use JSON::PP;
use LWP::Protocol::https;
use LWP::UserAgent;
use Pod::Usage;


# Set umask to 022 to make sure files and directories
# are not created with world writable permissions.
if ($^O !~ m/Win/i) {
	umask 0022;
}

# Configuration variables
my $hostname = 'localhost';
my $username = '';
my $password = '';
my $domain_type = '';
my $domain_name = '';
my $token = '';
my %security_role_operation_map = (
	'|' => [
		'|OPERATIONS|MANAGE-ACCESS|',
		'|OPERATIONS|VIEW|'
	],
	'|MANAGE|HOSTS|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|MANAGE|HOSTS|COMMENT|',
        '|OPERATIONS|MANAGE|HOSTS|HOSTMAPPINGS|DELETE|',
        '|OPERATIONS|MANAGE|HOSTS|HOSTMAPPINGS|UPDATE|',
        '|OPERATIONS|MANAGE|HOSTS|HOSTMAPPINGS|VIEW|',
        '|OPERATIONS|MANAGE|HOSTS|RESET|',
        '|OPERATIONS|UPDATE|'
	],
	'|SECURITY|ACCESS-CONTROL|PRINCIPALS|' => [
		'|OPERATIONS|SECURITY|ACCESS-CONTROL|PRINCIPALS|ASSIGN-TO-ROLE|'
	],
	'|SECURITY|ACCESS-CONTROL|ROLES|' => [
		'|OPERATIONS|ADD|',
		'|OPERATIONS|DELETE|',
		'|OPERATIONS|SECURITY|ACCESS-CONTROL|ROLES|ASSIGN-ACCESS|',
		'|OPERATIONS|UPDATE|'
	],
	'|SECURITY|CERTIFICATE-MANAGEMENT|CERTIFICATE-AUTHORITIES|' => [
		'|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|CERTIFICATE-AUTHORITIES|MIGRATE-CA|',
		'|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|CERTIFICATE-AUTHORITIES|VIEW-HOSTS-MIGRATE-CA|'
	],
	'|SECURITY|CERTIFICATE-MANAGEMENT|ECA|' => [
		'|OPERATIONS|ADD|',
		'|OPERATIONS|DELETE|',
		'|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|ECA|RESET|'
	],
	'|SECURITY|CERTIFICATE-MANAGEMENT|NETBACKUP-CERTIFICATES|' => [
		'|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|NETBACKUP-CERTIFICATES|REVOKE|',
		'|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|NETBACKUP-CERTIFICATES|DISSOCIATE|'
	],
	'|SECURITY|CERTIFICATE-MANAGEMENT|TOKENS|' => [
		'|OPERATIONS|ADD|',
		'|OPERATIONS|DELETE|'
	],
	'|SECURITY|CREDENTIALS|' => [
		'|OPERATIONS|ADD|'
	],
	'|SECURITY|IDP|' => [
		'|OPERATIONS|ADD|',
		'|OPERATIONS|DELETE|',
		'|OPERATIONS|UPDATE|'
	],
	'|SECURITY|KMS|' => [
		'|OPERATIONS|ADD|',
		'|OPERATIONS|DELETE|',
		'|OPERATIONS|SECURITY|KMS|SERVICES|CREATE|',
		'|OPERATIONS|SECURITY|KMS|SERVICES|VIEW|',
		'|OPERATIONS|SECURITY|KMS|VALIDATE|',
		'|OPERATIONS|UPDATE|'
	],
	'|SECURITY|SETTINGS|' => [
		'|OPERATIONS|SECURITY|SETTINGS|RELOAD|',
		'|OPERATIONS|UPDATE|'
	],
	'|SECURITY|USERS|API-KEYS|' => [
		'|OPERATIONS|ADD|',
		'|OPERATIONS|DELETE|',
		'|OPERATIONS|UPDATE|'
	],
	'|SECURITY|USERS|CERTIFICATE-MANAGEMENT|' => [
		'|OPERATIONS|ADD|',
		'|OPERATIONS|DELETE|'
	],
	'|SECURITY|USERS|USER-SESSIONS|' => [
		'|OPERATIONS|DELETE|',
		'|OPERATIONS|SECURITY|USERS|USER-SESSIONS|CLOSE|',
		'|OPERATIONS|SECURITY|USERS|USER-SESSIONS|CLOSE-ALL|',
		'|OPERATIONS|SECURITY|USERS|USER-SESSIONS|UNLOCK|', 
		'|OPERATIONS|SECURITY|USERS|USER-SESSIONS|VIEW-LOCKED-USERS|',
		'|OPERATIONS|UPDATE|'
	]
);

# Parse command line options
my ($help, $man, $debug);
GetOptions(
	'help|h!'          => \$help,
	'man|m!'           => \$man,
	'debug|d!',        => \$debug,
	'hostname|host=s'  => \$hostname,
	'username|user=s'  => \$username,
	'password|pass=s'  => \$password,
	'domain_type=s'    => \$domain_type,
	'domain_name=s'    => \$domain_name,
	'token=s'          => \$token
) or pod2usage(2);

if ($help) {
	pod2usage(1);
	exit;
}

if ($man) {
	pod2usage(-verbose => 2);
	exit;
}

if (!($token || ($username && $password))) {
    print "Either -username and -password needs to be specified or -token needs to be specified\n";
    pod2usage(2);
}

# Initialize HTTP client
my $http = LWP::UserAgent->new(
	ssl_opts => {verify_hostname => 0, verify_peer => 0},
	protocols_allowed => ['https']
);
my $response;

# Ping server to verify connection and get API version
my $ping_url = "https://$hostname/netbackup/ping";
$response = $http->get($ping_url, 'Accept' => 'text/plain');
unless ($response->is_success) {
	if ($debug) {
		print Dumper($response);
	}
	die "Failed to ping server!\n" ;
}

my $api_version = $response->header('x-netbackup-api-version');
if ($api_version < 4) {  # NetBackup 8.3
	die "Script should not be run on NetBackup releases before 8.3!\n";
}

# Set meda type with discovered API version
my $media_type = "application/vnd.netbackup+json;version=$api_version";

# Log in to get a token if needed
unless ($token) {  ## REMOVE token ##
	my $login_url = "https://$hostname/netbackup/login";
	my %creds = (
		domainType => "$domain_type",
		domainName => "$domain_name",
		userName => "$username",
		password => "$password"
	);
	my $login_body = encode_json(\%creds);
	$response = $http->post($login_url, 'Content-Type' => $media_type, Content => $login_body);
	unless ($response->is_success) {
		if ($debug) {
			print Dumper($response);
		}
		die "Failed to log into server!\n" ;
	}
	$token = decode_json($response->content)->{token};
}

# Update HTTP client with default headers
$http->default_header('Accept' => $media_type);
$http->default_header('Authorization' => $token);

# Find old backup and security admin role IDs
my $rbac_roles_url = "https://$hostname/netbackup/rbac/roles";
$response = $http->get($rbac_roles_url);
unless ($response->is_success) {
	if ($debug) {
		print Dumper($response);
	}
	if ($response->code() == 401) {
		print "Access to perform the operation was denied.\n";
	}
	die "Failed to get old RBAC roles!\n" ;
}
my ($old_backup_admin_role_id, $old_security_admin_role_id) = extract_role_ids($response);

# Find user and group principals from old access rules that reference backup and security roles
my $rbac_access_rules_url = "https://$hostname/netbackup/rbac/access-rules";
$response = $http->get($rbac_access_rules_url);
unless ($response->is_success) {
	if ($debug) {
		print Dumper($response);
	}
	die "Failed to get old RBAC access rules!\n" ;
}
my ($backup_user_principals_ref, $backup_group_principals_ref, $security_user_principals_ref, $security_group_principals_ref) = extract_principals($response);

# Remove duplicates from security so that any user/group that exists in both will only be added to Administrator role
$security_user_principals_ref = remove_duplicates($backup_user_principals_ref, $security_user_principals_ref);
$security_group_principals_ref = remove_duplicates($backup_group_principals_ref, $security_group_principals_ref);

# Dereference arrays for later use
my @backup_user_principals = @{$backup_user_principals_ref};
my @backup_group_principals = @{$backup_group_principals_ref};
my @security_user_principals = @{$security_user_principals_ref};
my @security_group_principals = @{$security_group_principals_ref};

if (!@backup_user_principals and !@backup_group_principals and !@security_user_principals and !@security_group_principals) {
	print "No principals found in old RBAC access rules!\n";
	exit;
}

# Prompt user for backup to Administrator migration confirmation
if (@backup_user_principals) {
	print "Found the following backup administrator principals:\n";
	foreach my $backup_user (@backup_user_principals) {
		print "\t$backup_user\n";
	}
}
if (@backup_group_principals) {
	print "Found the following backup administrator group principals:\n";
	foreach my $backup_group (@backup_group_principals) {
		print "\t$backup_group\n";
	}
}
print "\nWould you like to migrate these principals to the Administrator role? (y/N) ";
my $do_backup = <>;
chomp($do_backup);

# Add backup user principals to new Administrator role
if (@backup_user_principals && $do_backup =~ /y/i) {
	my $user_administrator_role_url = "https://$hostname/netbackup/access-control/roles/0/relationships/user-principals";
	my $backup_users = encode_json(generate_user_principal_resource_identifier_objects(@backup_user_principals));
	$response = $http->post($user_administrator_role_url, 'Content-Type' => $media_type, Content => $backup_users);
	unless ($response->is_success) {
		if ($debug) {
			print Dumper($response);
		}
		die "Failed to add backup admin users!\n" ;
	}
}

# Add backup group principals to new Administrator role
if (@backup_group_principals && $do_backup =~ /y/i) {
	my $group_administrator_role_url = "https://$hostname/netbackup/access-control/roles/0/relationships/group-principals";
	my $backup_groups = encode_json(generate_group_principal_resource_identifier_objects(@backup_group_principals));
	$response = $http->post($group_administrator_role_url, 'Content-Type' => $media_type, Content => $backup_groups);
	unless ($response->is_success) {
		if ($debug) {
			print Dumper($response);
		}
		die "Failed to add backup admin groups!\n" ;
	}
}

# Prompt user for security to Security Administrator migration confirmation
print "\n";
if (@security_user_principals) {
	print "Found the following security administrator principals:\n";
	foreach my $security_user(@security_user_principals) {
		print "\t$security_user\n";
	}
}
if (@security_group_principals) {
	print "Found the following security administrator group principals:\n";
	foreach my $security_group(@security_group_principals) {
		print "\t$security_group\n";
	}
}

my $accesscontrol_roles_url = "https://$hostname/netbackup/access-control/roles";
$response = $http->get($accesscontrol_roles_url);
my $new_security_admin_role_id = extract_security_role_id($response);

my $do_security;
if ($new_security_admin_role_id > 0) {
	print "The Security Administrator role already exists.\nWould you like to migrate these principals to the existing Security Administrator role? (y/N) ";
	$do_security = <>;
	chomp($do_security);
	if ($do_security !~ /y/i) {
		exit;
	}
} else {
	print "\nWould you like to migrate these principals to a new Security Administrator role? (y/N) ";
	$do_security = <>;
	chomp($do_security);

	# Create new Security Administrator role
	if ($do_security =~ /y/i) {
		my $access_control_roles_url = "https://$hostname/netbackup/access-control/roles";
		my $security_role_admin_body = <<'EOL';
{
	"data": {
		"type": "accessControlRole",
		"attributes": {
			"name": "Security Administrator",
			"description": "Security administrator with privileges for performing actions including access control, certificates, security settings etc."
		}
	}
}
EOL
		$response = $http->post($access_control_roles_url, 'Content-Type' => $media_type, Content => $security_role_admin_body);
		unless ($response->is_success) {
			if ($debug) {
				print Dumper($response);
			}

			die "Failed to create security administrator role!\n" ;
		}
		my $response_content = decode_json($response->content);
		$new_security_admin_role_id = $response_content->{data}{id};
		print "New Security Administrator role created with ID: ", $new_security_admin_role_id, "\n";
	}
}

# Create access definitions for new Security Administrator role
if ($do_security =~ /y/i) {
	for my $managed_object (keys %security_role_operation_map) {
		my $access_definitions_url = "https://$hostname/netbackup/access-control/managed-objects/$managed_object/access-definitions";
		my $operations = $security_role_operation_map{$managed_object};
		my $access_definition_object = encode_json(generate_access_definition_object($new_security_admin_role_id, $managed_object, $operations));
		$response = $http->post($access_definitions_url, 'Content-Type' => $media_type, Content => $access_definition_object);
		unless ($response->is_success) {
			if ($debug) {
				print Dumper($response);
			}
			die "Failed to create access definition for security administrator role!\n";
		}
	}
}

# Add security user principals to new Security Administrator role
if (@security_user_principals && $do_security =~ /y/i) {
	my $user_security_role_url = "https://$hostname/netbackup/access-control/roles/$new_security_admin_role_id/relationships/user-principals";
	my $security_users = encode_json(generate_user_principal_resource_identifier_objects(@security_user_principals));
	$response = $http->post($user_security_role_url, 'Content-Type' => $media_type, Content => $security_users);
	unless ($response->is_success) {
		if ($debug) {
			print Dumper($response);
		}
		die "Failed to add security admin users!\n" ;
	}
}

# Add security group principals to new Security Administrator role
if (@security_group_principals && $do_security =~ /y/i) {
	my $group_security_role_url = "https://$hostname/netbackup/access-control/roles/$new_security_admin_role_id/relationships/group-principals";
	my $security_groups = encode_json(generate_group_principal_resource_identifier_objects(@security_group_principals));
	$response = $http->post($group_security_role_url, 'Content-Type' => $media_type, Content => $security_groups);
	unless ($response->is_success) {
		if ($debug) {
			print Dumper($response);
		}
		die "Failed to add security admin groups!\n" ;
	}
}


sub extract_role_ids {
	my ($response) = @_;
	my $content = decode_json($response->content);
	my @data = $content->{data};
	my ($backup_id, $security_id);
	foreach my $role (@{ $content->{data} }) {
		if ($role->{attributes}{isSystemDefined}) {
			if ($role->{attributes}{name} =~ "Backup administrator") {
				$backup_id = $role->{id};
			} elsif ($role->{attributes}{name} =~ "Security administrator") {
				$security_id = $role->{id};
			}
		}
	}
	return ($backup_id, $security_id);
}

sub extract_security_role_id {
	my ($response) = @_;
	my $content = decode_json($response->content);
	my @data = $content->{data};
	foreach my $role (@{ $content->{data} }) {
		if ($role->{attributes}{name} =~ /security\sadministrator/i) {
			return $role->{id};
		}
	}

	return -1;
}

sub extract_principals {
	my ($response) = @_;
	my $content = decode_json($response->content);
	my @data = $content->{data};
	my (@backup_users, @backup_groups, @security_users, @security_groups);
	foreach my $access_rule (@{ $content->{data} }) {
		if ($access_rule->{relationships}{role}{data}{id} == $old_backup_admin_role_id) {
			if ($access_rule->{relationships}{userPrincipal}) {
				push @backup_users, $access_rule->{relationships}{userPrincipal}{data}{id};
			} elsif ($access_rule->{relationships}{groupPrincipal}) {
				push @backup_groups, $access_rule->{relationships}{groupPrincipal}{data}{id};
			}
		} elsif ($access_rule->{relationships}{role}{data}{id} == $old_security_admin_role_id) {
			if ($access_rule->{relationships}{userPrincipal}) {
				push @security_users, $access_rule->{relationships}{userPrincipal}{data}{id};
			} elsif ($access_rule->{relationships}{groupPrincipal}) {
				push @security_groups, $access_rule->{relationships}{groupPrincipal}{data}{id};
			}
		}
	}
	return (\@backup_users, \@backup_groups, \@security_users, \@security_groups);
}

sub remove_duplicates {
	my ($backup_principals_ref, $security_principals_ref) = @_;
	my @backup_principals = @{$backup_principals_ref};
	my @security_principals = @{$security_principals_ref};
	my @filtered_security_principals = grep !${ { map { $_, 1 } @backup_principals } }{ $_ }, @security_principals;
	return \@filtered_security_principals;
}

sub generate_user_principal_resource_identifier_objects {
	my (@principals) = @_;
	my @data;
	foreach my $principal (@principals) {
		my %identifier = (type => 'userPrincipal', id => $principal);
		push @data, \%identifier;
	}
	my %objects = (data => \@data);
	return \%objects;
}

sub generate_group_principal_resource_identifier_objects {
	my (@principals) = @_;
	my @data;
	foreach my $principal (@principals) {
		my %identifier = (type => 'groupPrincipal', id => $principal);
		push @data, \%identifier;
	}
	my %objects = (data => \@data);
	return \%objects;
}

sub generate_access_control_operation_resource_identifier_objects {
	my (@operations) = @_;
	my @data;
	foreach my $operation (@operations) {
		my %identifier = (type => 'accessControlOperation', id => $operation);
		push @data, \%identifier;
	}
	my %objects = (data => \@data);
	return \%objects;
}

sub generate_access_definition_object {
	my ($role_id, $managed_object, $operations_ref) = @_;
	my @operations = @{$operations_ref};
	my %object = (
		data => {
			type => "accessDefinition",
			attributes => {
				propagation => "OBJECT_AND_CHILDREN"
			},
			relationships => {
				role => {
					data => {
						type => "accessControlRole",
						id => "$role_id"
					}
				},
				operations => generate_access_control_operation_resource_identifier_objects(@operations),
				managed_object => {
					data => {
						type => "managedObject",
						id => "$managed_object"
					}
				}
			}
		}
	);
	return \%object;
}


__END__

=head1 NAME

rbac_user_migration.pl - migrate pre-8.3 RBAC admin roles

=head1 SYNOPSIS

B<rbac_user_migration> [--debug] [--hostname master_server] [--username user] [--password secret] [--domain_type type] [--domain_name name] [--token JWT] [--help] [--man]

=head1 DESCRIPTION

B<rbac_user_migration> takes pre-8.3 RBAC admin roles and migrates them to the new RBAC framework.

Backup admins are assigned to the default Administrator role.  Security admins are assigned to a new Security Administrator role created by this script.

An access definition is created for the new Security Administrator role using a suggested list of managed objects and operations.  This list can be modified to suit your environment before running the script.

Most configuration options can either be set in the script itself or passed as command line parameters.

For more detailed information on RBAC please see the NetBackup Security & Encryption guide.

To get the latest version of this script please check out the NetBackup API Code Samples repo on GitHub at L<https://github.com/VeritasOS/netbackup-api-code-samples>.

=head1 DEPENDENCIES

This script requires these other non-core modules:

=over 4

=item LWP::Protocol::https

=item LWP::UserAgent

=item Net::SSLeay

=back

=head1 OPTIONS

=over 4

=item B<-h, --help>

Print a brief summary of the options to B<rbac_user_migration> and exit.

=item B<-m, --man>

Print the full manual page for B<rbac_user_migration> and exit.

=item B<-d, --debug>

Prints the full HTTP response object when an API call fails.  Useful for debugging script execution problems.

=item B<--host, --hostname>

The hostname of the master server to run script against.  This script can be run from any system as long as there is network connectivity to the master server specified.  Defaults to 'localhost' if not specified.

=item B<--user, --username>

The API user to authenticate with on the master server.  Required if token is not provided.

=item B<--pass, --password>

The password to authenticate with on the master server.  Required if token is not provided.

=item B<--domain_type>

The domain type to authenticate with on the master server.

=item B<--domain_name>

The domain name to authenticate with on the master server.

=item B<--token>

The JWT or API key value to use instead of authenticating and creating a new user session.  Required if username and password are not provided.

=back

=head1 EXAMPLES

rbac_user_migration.pl --host nbumaster.domain.com --user dennis --pass secret --domain_type unixpwd

rbac_user_migration.pl --host nbumaster.domain.com --user bill --pass secret --domain_type NT --domain_name DOMAIN

rbac_user_migration.pl --host nbumaster.domain.com --token Iojwei38djasdf893n-23ds

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Veritas Technologies LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
