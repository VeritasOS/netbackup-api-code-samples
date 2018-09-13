var netbackup = require("./netbackup-module/netbackup.js");
// including stdio just for creating help
var stdio = require('stdio');
var parms = stdio.getopt({
    'nbmaster'    : { key: 'n', args: 1, description: 'Master server name', mandatory: true },
    'port'        : { key: 'pr', args: 1, default: '1556', description: 'Port number' },
    'verbose'     : { key: 'v', args: 1, description: 'Verbose statements' }
});

var contentType = "application/vnd.netbackup+json;version=1.0";
var verbose;

function main() {
    verbose = (parms.verbose === undefined) ? false: true;
    
    netbackup.printOnConsole('\nDeploying CA certificate...', verbose);
    netbackup.getCACertificate(parms.nbmaster, parms.port, contentType, verbose);

}

main();
