#!/usr/bin/perl

# Snapshot Management Plugin Configuration

=head1 NAME
snapshot_plugin_conf.pl

=head1 SYNOPSIS
[SNAPSHOT SERVER CONFIGURATION]
The script, if specified, configures snapshot server in NetBackup before pulling up any plugin from snapshot server.

[IMPORT PLUGINS]
The script imports configured plugins from specified snapshot server. The script requires snapshot server name,
snapshot server username and password to import plugins. This import operation will not affect existing plugin configuration.

[ASSET DISCOVERY]
Once the plugins are imported in NetBackup, the script can go furthur to start asset discovery, if specified.

[SUPPORT]
The script supports importing only following cloud plugins:
    - Amazon Cloud, Google Cloud, Microsoft Azure  

=head1 USAGE
1. Import cloud plugins
snapshot_plugin_conf.pl -import_plugins -snapshot_server <snapshot_server_name> -user <user_name> -password <password>

2. Import plugins and start asset discovery
snapshot_plugin_conf.pl -import_plugins -snapshot_server <snapshot_server_name> -user <user_name> -password <password> -discover_cloud_assets

=cut

# ADD ALL LIBRARIES IN INC PATH
use lib ".";

# IMPORT REQUIRED CUSTOM PACKAGES
use restclient;
use errcode;
use utility;
use constants;

use Getopt::Long qw(:config no_auto_abbrev);
use JSON;
use Data::Dumper;
use Term::ReadKey;
use Try::Tiny;
use Time::HiRes qw(time);
use IPC::Run3;

# COMMAND CONSTANTS
my $GET_PLUGINS_NAME            = "import_plugins";
my $ADD_COMMAND_NAME            = "add";
my $SNAPSHOT_SERVER_NAME        = "snapshot_server";
my $SERVER_USER_NAME            = "user";
my $SERVER_PASSWORD_NAME        = "password";
my $ENABLE_DISCOVERY            = "discover_cloud_assets";
my $HELP_COMMAND_NAME           = "help";

# EXTERNAL FUNCTIONS
my $get_nb_path     = \&utility::get_nb_path;
my $is_windows      = \&utility::is_windows;
my $build_string    = \&utility::build_string;

# CLI COMMANDS
my $getPluginsCommand = 0;
my $helpCommand = 0;
my $discoverCommand = 0;

# CLI PARAMETERS
my $snapshotServer;
my $userName;
my $password;

###################################################
# Print Command Usage
###################################################
sub printUsage {
    print "\n\nUsage:\n";
    print "\tperl snapshot_plugin_conf <command> [options..]\n";
    print "\nCommands Supported:\n";
    print "\n\t-$GET_PLUGINS_NAME\n";
    print "\t   Import configured plugins from specified snapshot server\n";
    print "\nOptions Supported:\n";
    print "\n\t-$SNAPSHOT_SERVER_NAME  <snapshot_server_name>\n\t   Snapshot server name\n";
    print "\n\t-$SERVER_USER_NAME  <user_name>\n\t   Username of snapshot server\n";
    print "\n\t-$SERVER_PASSWORD_NAME  <password>\n\t   Password of snapshot server\n";
    print "\n\t-$ENABLE_DISCOVERY\n\t   Enable cloud asset discovery after plugin configuration\n";
    print "\n\t-$HELP_COMMAND_NAME\n\t   Show this help\n";
}

###################################################
# Read CLI Parameters
###################################################
sub read_cli_parameters {
    GetOptions ("$GET_PLUGINS_NAME"             => \$getPluginsCommand,
                "$ADD_COMMAND_NAME"             => \$addCommand,
                "$SNAPSHOT_SERVER_NAME=s"       => \$snapshotServer,
                "$SERVER_USER_NAME=s"           => \$userName,
                "$SERVER_PASSWORD_NAME=s"       => \$password,
                "$ENABLE_DISCOVERY"             => \$discoverCommand,
                "$HELP_COMMAND_NAME"            => \$helpCommand,
        ) or failureExit ($errcode::EC_NO_ARGUMENT_SPECIFIED);
}

###################################################
# Restart Discovery Frameword
# Discover assets for newly added plugins
###################################################
sub restartDiscovery {

    print "Restarting NetBackup Discovery framework";
    my $nbdisco_start = $get_nb_path->(@constants::NB_DISCO_PATH);
    my $nbdisco_term  = [$get_nb_path->(@constants::NB_DISCO_PATH), $constants::NBDISCO_TERMINATE];
    if (-f $nbdisco_start ) {
        if ($is_windows->()) {
            run3 ["taskkill", "/IM", "nbdisco.exe", "/F", "/T"], \undef, \undef, \undef;
        }
        for (my $count = 0; $count < $constants::RESTART_DISCOVERY_CNT; $count++) {
            if ($is_windows->()) {
                require Win32::Service;
                Win32::Service->import();
                Win32::Service::StopService('', "NetBackup Discovery Framework");
                Win32::Service::StartService('', "NetBackup Discovery Framework");
            } else {
                run3 $nbdisco_term;
                run3 $nbdisco_start;
            }
            print ".";
            $| = 1;
            sleep $constants::RESTART_DISCOVERY_SLP_INT;
        }
        print "\nNetBackup Discovery Framework Restarted.\n";
    } else {
        print "\nWARN! Unable to restart NetBackup Discovery framework.\n";
    }

}

###################################################
# Failure Point
# Print related error message and exit
###################################################
sub failureExit {
    $cnt = scalar(@_);
    $status = -1;
    $msg = "Program terminated with unknown error.";

    print "\n";
    if ($cnt >= 1) {
        $status = @_[0];
        $errmsg = $errcode::EC_ERROR_MSG[$status];
        $msg = (($errmsg) ? $build_string->("$errmsg", @_[1..$cnt]) : "No error message.");
        $msg = "EXIT STATUS: $status - " . $msg;
    }
    print $msg . "\n";
    exit $status;
}

###################################################
# Add specified snapshot server in NetBackup configuration
###################################################
sub add_snapshot_server {
    print "Configuring snapshot server: $snapshotServer\n";
    my $tpc_add = [$get_nb_path->(@constants::NB_TPC_PATH) , $constants::TPC_ADD_ARG, $constants::TPC_CP_SERVER_ARG,
        $snapshotServer, $constants::TPC_CP_SERVER_USR_ID_ARG, $userName];
    run3 $tpc_add;

    if ( $@ || $? ) {
        print "WARN! Configuring snapshot server failed. Continuing to get plugins...\n";
    } else {
        print "Configured snapshot server successfully.\n";
    }
}

###################################################
# Perform login to snapshot server
###################################################
sub login_snapshot_server {
    local $response;
    print "Logging into snapshot server: $snapshotServer\n";
    $response = restclient::rest_request("POST", $snapshotServer, $constants::SNAP_SERVER_BASE_URL . $constants::SNAP_SERVER_LOGIN_URL, 
        "", "{\"email\":\"$userName\",\"password\":\"$password\"}");
    if (not defined $response) {
        return undef;
    }
    print "--->Login successful.\n\n";
    return $response->{ 'accessToken' };
}

###################################################
# Get offhost agent from snapshot server
###################################################
sub get_offhost_agent {
    local $agent_id;
    local $response;
    print "Getting off-host agent.\n";
    $response = restclient::rest_request("GET", $snapshotServer, $constants::SNAP_SERVER_BASE_URL . $constants::SNAP_SERVER_AGENTS_URL,
        "authToken=$token", "");
    if (not defined $response) {
        return undef;
    }
    
    foreach my $agent( @$response ) {
        if ( $agent-> { 'status' } eq "online" && $agent-> { 'onHost' } eq 0 ) {
           $agent_id = $agent-> { 'agentid' };
           break;
        }
    }
    if (!$agent_id) {
       return "";
    }
    print "--->Fetched off-host agent ID: $agent_id\n\n";
    return $agent_id;
}

###################################################
# Import configured plugins
###################################################
sub import_plugins_from_snap_server {
    local @conf_plugins;
    local $response;

    print "Fetching configured plugins from the snapshot server: $snapshotServer\n";
    foreach my $plugin_name ( @constants::SUPPORTED_PLUGINS ) {
        print "--->Fetching $plugin_name plugin details\n";
        $response = restclient::rest_request("GET", $snapshotServer, $constants::SNAP_SERVER_BASE_URL . $constants::SNAP_SERVER_AGENTS_URL . 
                "/$agent_id" . $build_string->($constants::SNAP_SERVER_PLUGINS_URL, $plugin_name), "authToken=$token", "");
        if (not defined $response) {
            print "WARN! Unable to get configured $plugin_name plugins\n";
        }
        foreach my $plugin (@$response) {
            $plugin->{'type'} = $plugin_name;
            push @conf_plugins, $plugin;
        }
        print "------->Found " . scalar (@$response) . " plugins\n";
    }
    print "Fetched configured plugins successfully.\n\n";
    return @conf_plugins;
}

###################################################
# Read plugins configured in NetBackup
###################################################
sub read_configured_netbackup_plugins {
    local $content_hash = decode_json("[]");

    if (-f $get_nb_path->(@constants::CONF_FILE_PATH)) {
        {
            local $/;
            open(FILE, $get_nb_path->(@constants::CONF_FILE_PATH)) or failureExit ($errcode::EC_CONF_FILE_OPEN_FAILED);
            try {
                $content_hash = decode_json(<FILE>);
            }
            catch {
                $content_hash = decode_json("[]");
                print "--->NetBackup plugin data is corrupt. It will be overwritten.\n";
            };
            close FILE;
        }
    } else {
        return undef;
    }
    return $content_hash;
}

###################################################
# Update imported plugins into existing plugin array
###################################################
sub update_imported_plugins {
    
    # Read arguments
    $content_hash = @_[0];      # Existing plugins
    @conf_plugins = @{ @_[1] }; # Imported plugins

    local $added_plugins = 0;
    local $conf_server_exists = 0;

    foreach my $conf_plugin (@conf_plugins) {
        $plugin_data = $build_string->($constants::CONF_PLUGIN_DATA_JSON, $conf_plugin-> {'type'} . "_" . time, $conf_plugin-> {'type'}, $conf_plugin-> {'configId'}, 'Cloud');
        foreach my $server_conf (@$content_hash) {
            if (exists $server_conf-> { $snapshotServer } ) {
               $conf_server_exists = 1;
               $conf_server_plugin_exists = 0;

               # Check for duplicate configuration identifier
               foreach my $server_conf_plugin (@ {$server_conf-> { $snapshotServer}} ) {
                   if ($server_conf_plugin-> { 'Config_ID' } eq $conf_plugin-> {'configId'}) {
                       $conf_server_plugin_exists = 1;
                       break;
                   }
               }

               if (!$conf_server_plugin_exists) {
                  push @ {$server_conf-> { $snapshotServer}} , decode_json($plugin_data);
                  $added_plugins++;
               }
               break;
            }
        }

        # Add server name in conf data
        if (!$conf_server_exists) {
            push @$content_hash, decode_json("{\"$snapshotServer\":[$plugin_data]}");
            $added_plugins++;
        }
    }
    return $added_plugins;
}

###################################################
# Fetch configured cloud plugins on specified 
# snapshot server and populate them in NetBackup
###################################################
sub getAndConfigPlugins {

    # Validate required paramters
    if (!$snapshotServer) {
        failureExit ($errcode::EC_NO_SNAPSHOT_SERVER);
    }

    if (!$userName) {
        failureExit ($errcode::EC_NO_USER_NAME);
    }

    if (!$password) {
        failureExit ($errcode::EC_NO_SERVER_PASSWORD);
    }

    # Check if user wants to add snapshot server before pulling out plugins
    if (length($addCommand)) {
        add_snapshot_server();
    }

    # Login to snapshot server
    local $token = login_snapshot_server();
    if (not defined $token) {
        failureExit($errcode::EC_REST_REQUEST);
    }

    # Get offhost agent
    local $agent_id = get_offhost_agent();

    if (not defined $agent_id) {
        failureExit($errcode::EC_REST_REQUEST);
    } elsif (!$agent_id) {
        failureExit($errcode::EC_NO_ONLINE_AGENT);
    }

    # Get configured plugins using the offhost agent
    local @conf_plugins = import_plugins_from_snap_server();

    print "Loading NetBackup configured plugin data...\n";
    local $content_hash = read_configured_netbackup_plugins();
    if (not defined $content_hash) {
        print "--->WARN! Unable to read configured plugin data.\n";
    } else {
        print "NetBackup plugin data loaded successfully.\n";
    }

    local $added_plugins = update_imported_plugins($content_hash, \@conf_plugins);

    if (!$added_plugins) {
        print "No new plugins found to configure in NetBackup.\n";
        if ($discoverCommand) {
            print "Nothing to discover.\n"
        }
        exit;
    }

    $JSON = JSON->new->utf8->pretty(1);

    open (FILE, '>', $get_nb_path->(@constants::CONF_FILE_PATH)) or failureExit ($errcode::EC_CONF_FILE_OPEN_FAILED);
        print FILE $JSON->encode($content_hash); 
    close FILE;

    print "Added $added_plugins plugins in NetBackup successfully.\n";

    if ($discoverCommand) {
        restartDiscovery();
    }
}

###################################################
# Program Start Point
# The script will read cli parameters first
###################################################
read_cli_parameters();

if ($helpCommand) {
    printUsage();
}
elsif ($getPluginsCommand) {
    getAndConfigPlugins();
}
else {
    printUsage();
}

