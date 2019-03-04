# CONSTANTS PACKAGE

package constants;

# REST REQUEST CONSTANTS
our $APPLICATION_HEADER_JSON        = "application/json";
our $SNAP_SERVER_BASE_URL           = "/cloudpoint/api/v3";
our $SNAP_SERVER_LOGIN_URL          = "/idm/login";
our $SNAP_SERVER_AGENTS_URL         = "/agents";
our $SNAP_SERVER_PLUGINS_URL        = "/plugins/#1/configs";

# OTHER CONSTANTS
our @WIN_PLATFORMS                  = ("MSWin32", "cygwin", "dos", "os2", "msys");
our @SUPPORTED_PLUGINS              = ("aws", "azure", "gcp");
our $RESTART_DISCOVERY_CNT          = 3;
our $RESTART_DISCOVERY_SLP_INT      = 10;

# NetBackup DIRECTORY CONSTANTS
our @PATH_SEP                       = ('\\', '/');
our @NB_BASE_PATH                   = ('/usr/openv', 'C:\\Program Files\\Veritas');
our @NB_VAR_GLOBAL_PATH             = (@NB_BASE_PATH[0] . '/var/global', @NB_BASE_PATH[1] . '\\NetBackup');
our @NB_VOLMGR_PATH                 = (@NB_BASE_PATH[0] . '/volmgr/bin', @NB_BASE_PATH[1] . '\\volmgr\\bin');
our @NB_BIN_PATH                    = (@NB_BASE_PATH[0] . '/netbackup/bin', @NB_BASE_PATH[1] . '\\Netbackup\\bin');
our @NB_TPC_PATH                    = (@NB_BASE_PATH[0] . '/volmgr/bin/tpconfig', @NB_BASE_PATH[1] . '\\volmgr\\bin\\tpconfig');
our @NB_DISCO_PATH                  = (@NB_BASE_PATH[0] . '/netbackup/bin/nbdisco', @NB_BASE_PATH[1] . '\\Netbackup\\bin\\nbdisco');
our @CONF_FILE_PATH                 = (@NB_VAR_GLOBAL_PATH[0] . '/CloudPoint_plugin.conf', @NB_VAR_GLOBAL_PATH[0] . '\\CloudPoint_plugin.conf');

# NBDISCO COMMAND ARGUMENTS
our $NBDISCO_TERMINATE              = "-terminate";

# CLOUDPOINT CONF CONSTANTS
our $CONF_PLUGIN_DATA_JSON          = "{\"Plugin_ID\":\"#1\",\"Plugin_Type\":\"#2\",\"Config_ID\":\"#3\",\"Plugin_Category\":\"#4\",\"Disabled\": false}";

# TPCONFIG COMMAND ARGUMENTS
our $TPC_ADD_ARG                    = "-add";
our $TPC_CP_SERVER_ARG              = "-cloudpoint_server";
our $TPC_CP_SERVER_USR_ID_ARG       = "-cloudpoint_server_user_id";
