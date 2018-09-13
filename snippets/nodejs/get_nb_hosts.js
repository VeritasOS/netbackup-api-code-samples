var netbackup = require("./netbackup-module/netbackup.js");
// including stdio just for creating help
var stdio = require('stdio');
var parms = stdio.getopt({
    'nbmaster'    : { key: 'n', args: 1, description: 'Master server name', mandatory: true },
    'port'        : { key: 'pr', args: 1, default: '1556', description: 'Port number' },
    'username'    : { key: 'u', args: 1, description: 'User name', mandatory: true },
    'password'    : { key: 'p', args: 1, description: 'Password of a user', mandatory: true },
    'domainname'  : { key: 'd', args: 1, default: '', description: 'Domain name (empty by default)' },
    'domaintype'  : { key: 't', args: 1, default: '', description: 'Domain type (empty by default)' },
    'verbose'     : { key: 'v', args: 1, description: 'Verbose statements' }
});

var contentType = "application/vnd.netbackup+json;version=1.0";
var jwt;
var verbose;

function main() {
    verbose = (parms.verbose === undefined) ? false: true;
    
    netbackup.printOnConsole('\nMaking call to login API...', verbose);
    netbackup.loginWithUser(parms.nbmaster, parms.port, parms.username, parms.password, 
        parms.domainname, parms.domaintype, contentType, verbose, loginResponse);
}

function loginResponse(data) {
    if (typeof data.errorCode != 'undefined') {
        console.info("\nError:\n " + JSON.stringify(data, null, 4));
    } else {
        netbackup.printOnConsole('\nLogin completed!', verbose);
        jwt = data.token;
        netbackup.printOnConsole('\nJWT token : ' + jwt, verbose);
        
        netbackup.getHostDetails(parms.nbmaster, parms.port, jwt, contentType, verbose, hostsListResponse);
    }
}

function hostsListResponse(data) {
    if (typeof data.errorCode != 'undefined') {
        console.info("\nError:\n " + JSON.stringify(data, null, 4));
    } else {
        console.info("\nHosts:\n " + JSON.stringify(data, null, 4));
        netbackup.printOnConsole('\nDone!!!');
    }
}

main();
