// =============================================================
// @module netbackup
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This file contains modules to call NetBackup APIs.
// =============================================================

var fs = require('fs');
var https = require('https');
var pem = require('pem');
var stdio = require('stdio');

var exportedMethod = {};

// To disable certificate/ssl verification, uncomment following line
// process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

var CA_CERT_PATH
    = isWindows() ? "C:\\temp\\cacert.pem" : "\temp\cacert.pem";

exportedMethod.getCACertificate = function (server, port, contentType, verbose) {
    var getCAURI = "/netbackup/security/cacert";

    var optionsForCACert = {
        method: "GET",
        hostname: server,
        port: port,
        path: getCAURI,
        rejectUnauthorized: false // To avoid an error, because the cert is unauthorized
    };

    if (fs.existsSync(CA_CERT_PATH)) {
        stdio.question('CA certificate is already present, Do you want to override certificate? ', ['y', 'n'], function (err, answer) {
            if (answer === 'y') {
                deployCACertificate(optionsForCACert, verbose);
            } else {
                return;
            }
        });
    } else {
        deployCACertificate(optionsForCACert, verbose);
    }
} // End of Get CA Certificate API

exportedMethod.loginWithUser = function (server, port, username, password, domainname, domaintype, contentType, verbose, returnedRes) {

    if (!fs.existsSync(CA_CERT_PATH)) {
        var error = {errorCode:404, errorMessage:'Login Failed: CA certificate is not present. Please run get_ca_cert.js.'};
        returnedRes(error);
        return;
    }

    var loginURI = "/netbackup/login";

    // create the JSON object
    loginPayload = JSON.stringify({
        "userName": username,
        "password": password,
        "domainName": domainname,
        "domainType": domaintype
    });
    printOnConsole('\nLogin payload: ' + loginPayload, verbose);
   
    var optionForLoginURI = {
        method: 'POST',
        host: server,
        port: port,
        path: loginURI,
        ca: [fs.readFileSync(CA_CERT_PATH, { encoding: 'utf-8' })],
        rejectUnauthorized: true,
        requestCert: true,
        agent: false,
        "headers": {
            'content-type': contentType,
            'Content-Length': loginPayload.length
        }
    };

    printOnConsole('\nWaiting for Login request to complete...', verbose);
    performRequest(optionForLoginURI, loginPayload, verbose, returnedRes);

}  // End of Login API

exportedMethod.getHostDetails = function (server, port, jwt, contentType, verbose, returnedRes) {
    var hostsListURI = "/netbackup/config/hosts/hostmappings";

    if (!fs.existsSync(CA_CERT_PATH)) {
        var error = {errorCode:404, errorMessage:'Get Host List Failed: CA certificate is not present. Please run get_ca_cert.js.'};
        returnedRes(error);
        return;
    }

    var optionForHostsListURI = {
        method: 'GET',
        host: server,
        port: port,
        path: hostsListURI,
        ca: [fs.readFileSync(CA_CERT_PATH, { encoding: 'utf-8' })],
        rejectUnauthorized: true,
        requestCert: true,
        agent: false,
        "headers": {
            'content-type': contentType,
            'authorization': jwt
        }
    };

    printOnConsole("\nFetching hosts...", verbose);
    performRequest(optionForHostsListURI, null, verbose, returnedRes);

} // END of getHostDetails

exportedMethod.getNBImages = function (server, port, jwt, contentType, verbose, returnedRes) {
    var hostsListURI = "/netbackup/catalog/images";

    if (!fs.existsSync(CA_CERT_PATH)) {
        var error = {errorCode:404, errorMessage:'Get NB Images Failed: CA certificate is not present. Please run get_ca_cert.js.'};
        returnedRes(error);
        return;
    }

    var optionForHostsListURI = {
        method: 'GET',
        host: server,
        port: port,
        path: hostsListURI,
        ca: [fs.readFileSync(CA_CERT_PATH, { encoding: 'utf-8' })],
        rejectUnauthorized: true,
        requestCert: true,
        agent: false,
        "headers": {
            'content-type': contentType,
            'authorization': jwt
        }
    };
    printOnConsole("\nFetching NB Images...", verbose);
    performRequest(optionForHostsListURI, null, verbose, returnedRes);

} // END of getNBImages

exportedMethod.printOnConsole = function (stmt, verbose) {
    printOnConsole(stmt, verbose);
}

function deployCACertificate(option, verbose) {
    printOnConsole("Deploying CA Certificate...", verbose);
    performRequest(option, null, verbose, saveCACertificate);
}

function saveCACertificate(data) {
    var answer = pem.getFingerprint(data.webRootCert, 'sha1', function (err, result) {
        console.info(result.fingerprint);
        stdio.question('Do you want to trust this fingerprint? ', ['y', 'n'], function (err, answer) {
            if (answer === 'y') {
                fs.writeFileSync(CA_CERT_PATH, data.webRootCert);
                console.info("CA Certificate is saved successfully.");
            } else {
                console.info("CA Certificate operation failed.");
           }
        });
    } );
}

function performRequest(option, payload, verbose, returnedRes) {
    var req = https.request(option, function (response) {
        printOnConsole('\nStatusCode: ' + response.statusCode, verbose);
        response.setEncoding('utf-8');
        var data;
        response.on('data', function (resBody) {
            printOnConsole("\nRaw response body: " + resBody, verbose);
            data = JSON.parse(resBody);
        });
        response.on('end', function () {
            returnedRes(data);
        });
    });

    if(payload !=null) {
        req.write(payload);
    }
    req.end();
    req.on('error', function (errorData) {
        console.info('Error ocuured : \n');
        console.error(errorData);
    });
}

function isWindows(){
    if (/^win/i.test(process.platform)) {
        return true;
    } else {
        return false;
    }
}

function printOnConsole(stmt, verbose) {
    if (verbose) {
        console.info(stmt);
    }
}

module.exports = exportedMethod;
