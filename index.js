const http = require('http');
const express = require("express");
const RED = require("node-red");
const path = require('path');

// Create an Express app
var app = express();

// Add a simple route for static content served from 'public'
app.use("/", express.static("public"));

// Create a server
var server = http.createServer(app);

// Create the settings object - see default settings.js file for other options
var settings = {
    flowFile: 'flows.json',
    uiPort: process.env.PORT || 80,
    httpAdminRoot: '/ide',
    httpNodeRoot: '/api',
    functionGlobalContext: {},
    get userDir() {
        return path.resolve(__dirname, './')
    },
    logging: {
        console: {
            level: "info",
            metrics: true,
        }
    },
    externalModules: {
        autoInstall: false, 
        palette: {
            allowInstall: false,
            allowUpdate: false,
            allowUpload: false
        }
    },
    disableEditor: true,
    functionExternalModules: true,
    debugMaxLength: 1000,
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    runtimeState: {        
        enabled: false,
        ui: false,
    },
    diagnostics: {
        enabled: true,
        ui: true,
    },
};

// Initialise the runtime with a server and settings
RED.init(server, settings);

// Serve the editor UI from /red
app.use(settings.httpAdminRoot, RED.httpAdmin);

// Serve the http nodes UI from /api
app.use(settings.httpNodeRoot, RED.httpNode);

server.listen(80);

// Start the runtime
RED.start();