# ERROR HANDLING FOR CLOUD WORKSPACE

package errcode;

our $EC_NO_SNAPSHOT_SERVER       = 1;
our $EC_NO_USER_NAME             = 2;
our $EC_NO_SERVER_PASSWORD       = 3;
our $EC_NO_ARGUMENT_SPECIFIED    = 4;
our $EC_REST_REQUEST             = 5;
our $EC_NO_ONLINE_AGENT          = 6;
our $EC_CONF_FILE_OPEN_FAILED    = 7;

our @EC_ERROR_MSG = (
	"",
	"`snapshot_server` parameter must be specified.",
	"`user` parameter must be specified.",
	"`password` parameter must be specified.",
	"Required arguments must be specified.",
	"HTTPS request to snapshot server failed.",
	"Found no online off-host agent.",
	"Unable to open plugin configuration file."
);
