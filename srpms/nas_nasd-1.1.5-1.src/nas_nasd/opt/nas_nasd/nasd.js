#!/usr/bin/env node

'use strict';
require('./global');

process.on('uncaughtException', function (e) {
    error(e.stack);
});

var fs = require('fs'),
    path = require('path'),
    zlib = require('zlib');

var express = require('express'),
    MemoryStore = express.session.MemoryStore,
    sessionStore = new MemoryStore(),
    site = express(),
    http = require('http').createServer(site),
    io = require('socket.io').listen(http),
    bio = io.sockets.socket();

/**
<b style="color: #f00">SINGLETON</b>

Webd will startup on global.PORT and publish global.PUBLIC_PATH folder,
tihs also use express library to handle a website and will share site port with socket.io.
For more express api and details, please following <a href="http://expressjs.com/">express</a> framework.


Nas website use <a href="http://jade-lang.com/">Jade engine</a> to render template views in global.VIEWS_PATH folder.
Each connection will auto create a new session and use global.SECRET encryption key to encrypt it.

The Webd only publish a single object in Nasd. Don't attempt to inherit or new this.

<b>Example:</b>
<pre><code>
info(Nasd.Webd);
</code></pre>

@uses events
@uses express
@extend events.EventEmitter
@class Webd
*/
function Webd() {
    events.EventEmitter.call(this);
    
    var me = this;
    
    site.set('port', PORT);
    site.set('views', VIEWS_PATH);
    site.set('view engine', 'jade');
    site.use(express.favicon());
    //site.use(express.logger('dev'));
    site.use(express.bodyParser());
    site.use(express.methodOverride());
    site.use(express.cookieParser(SECRET));
    site.use(express.session({
        store: sessionStore
    }));
    site.use(express.static(PUBLIC_PATH));
    site.use(express.errorHandler());
    site.use(site.router);
    
    site.get('/', function (req, res) {
        res.redirect('/nas');
    });
    
    site.get('/nas', function (req, res) {
        req.session.auth = {uid: 0, gid: 0};
        res.render('head', {
            title: 'Nas'
        });
    });
    
    site.get('/nas/css', function (req, res) {
        req.session.auth = {uid: 0, gid: 0};
        res.setHeader('Content-Type', 'text/css; charset=utf-8');
        res.setHeader('Content-Encoding', 'deflate');
        res.end(cssContent);
    });
    
    
    //content += fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/socket.io.js'), 'utf8');
    //content += fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/rpc.js'), 'utf8');
    //content += fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/base.js'), 'utf8');
    var content = {};
    
    // ext-all.css
    zlib.deflate(
        fs.readFileSync(path.join(PUBLIC_PATH, 'stylesheets/com.sencha/ext-all.css'), 'utf8'),
        function (err, buffer) {
            content['extcss'] = buffer;
        }
    );
    site.get('/nas/css', function (req, res) {
        res.setHeader('Content-Type', 'text/css; charset=utf-8');
        res.setHeader('Content-Encoding', 'deflate');
        res.end(content['extcss']);
    });
    
    // ext-all.js
    zlib.deflate(
        fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.sencha/ext-all.js'), 'utf8'),
        function (err, buffer) {
            content['extjss'] = buffer;
        }
    );
    site.get('/nas/extjs', function (req, res) {
        res.setHeader('Content-Type', 'text/javascript; charset=utf-8');
        res.setHeader('Content-Encoding', 'deflate');
        res.end(content['extjss']);
    });
    
    site.get('/nas/i18n', function (req, res) {
        req.session.auth = {uid: 0, gid: 0};
        res.setHeader('Content-Type', 'text/javascript; charset=utf-8');
        res.setHeader('Content-Encoding', 'deflate');
        res.end(content['i18n']);
    });
    
    zlib.deflate(
        fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/socket.io.js'), 'utf8') +
        fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/rpc.js'), 'utf8'),
        function (err, buffer) {
            content['rpc'] = buffer;
        }
    );
    site.get('/nas/rpc', function (req, res) {
        res.setHeader('Content-Type', 'text/javascript; charset=utf-8');
        //res.setHeader('Content-Encoding', 'deflate');
        //res.setHeader('Access-Control-Allow-Origin', '*');
        //res.end(content['rpc']);
        
        res.end(
            fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/socket.io.js'), 'utf8') +
            fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/rpc.js'), 'utf8')
        );
    });
    
    site.get('/nas/rpc/service', function (req, res) {
        res.end('alert("service");');
    });
    
    site.get('/nas/core', function (req, res) {
        req.session.auth = {uid: 0, gid: 0};
        res.setHeader('Content-Type', 'text/javascript; charset=utf-8');
        res.setHeader('Content-Encoding', 'deflate');
        res.end(content['core']);
    });
    
    site.get('/session', function (req, res) {
        req.session.auth = {uid: 0, gid: 0};
        res.setHeader('Content-Type', 'application/json; charset=utf-8');
        res.end(util.format('%s(\'%s\')', req.query.callback, req.sessionID));
    });
    
    var upload = {};
    site.post('/upload', function(req, res) {
        for (var key in req.files) {
            if (upload[key]) {
                if (upload[key](req.files[key].path, req.files[key].name)) {
                    fs.unlinkSync(req.files[key].path);
                }
            } else {
                fs.unlinkSync(req.files[key].path);
            }
        }
        res.end();
    });
    
    me.addUploadHandler = function(key, fn) {
        upload[key] = fn;
    }
    
    me.addPath = function (path, fn) {
        site.get(path, fn);
    }
    
    http.listen(PORT);
}
inherits(Webd, events.EventEmitter);

var jsContent;
var cssContent;
var i18nContent;

/**
<b style="color: #f00">SINGLETON</b>

Rpcd is a service loader and repeator. It will load sub modules (under global.SERVICE_PATH folder) and give those a common namespace 'Nasd'.

Any service maybe offer client side invokable methods, javascript sources, images, i18n words and css.
Following Node.js definition, a service (sub module) must contain 'package.json' file. Rpcd can read some extension tags to handle service.

<b>'package.json' Example:</b>
<pre><code>
{
    "main": "index",         // service entery: Node.js will try to find index.js, index.node and index/package.json ...
    "name": "Explorer",      // service name
    "rpc": true,             // optional: if this service offer remote invokable methods
    "dependencies": [        // optional: if this service have some dependency
         "Webd"
    ],
    "resource": true,        // optional: if this service have other media files
    "js": [                  // optional: those javascript resources will be merged with other services.
        "ui.explorer.js",
        "ui.popmenu.js"
     ],
     "css": [                // optional: those css resources will be merged with other services.
         "ui.explorer.css"
     ],
     "i18n": [               // optional: define words file
         "en"
     ]
}
</code></pre>

<b>All of "js", "css" and "i18n" resources in services will be merged and compressed on dependency.
If possibly, those contents will keep in system memory to reduce the request times and time.</b>

When Rpcd startup, it will try to find out all installed services in globa.SERVICE_PATH folder.
The Rpcd will use the name tag in the package.json file to require each service and add into Nasd scope.

<b>Example:</b>
<pre><code>

'use strict';
function Explorer() {
    events.EventEmitter.call(this);
    
    // 'this' is not always safe, because javascript can invoke a function via apply() or call().
    var me = this;

    // 'list' is an Explorer's private method
    function list(path) {
        return [1, 2, 3, 'test'];
    }

    // make a public method and also named 'list'
    me.list = list;

    // publish a 'list' remote invokable method
    me._method = {
        list: list
    };

    // make a public only method
    me.destroy = function () {
        info('Each service can provide this method to free some resources');
    }

    // regist a callback function when Nasd.Explorer emit 'discoveried' event.
    Nasd.Rpcd.on('discoveried', function () {
        info('Success to listen an event.');
    });
}
inherits(Explorer, events.EventEmitter);
module.exports = new Explorer();
</code></pre>

<pre><code>
// Other service can access Explorer in below
use strict';
var data = Nasd.Explorer.list('');
info(data.join());
</code></pre>

<pre><code>
&lt;script type="text/javascript"&gt;
'use strict';
// invoke remote method 'Explorer.list' and give a callback function to receive result.
Nasd.Explorer.list('', function(data) {
    alert('We get result from remote Explorer.list method.');
    alert(data.join());
});
&lt;/script&gt;
</code></pre>

@uses events
@uses socket.io
@extend events.Event.Emitter
@class Rpcd
*/
function Rpcd() {
    events.EventEmitter.call(this);
    
    var parse = require('cookie').parse,
        parseSignedCookies = require('connect').utils.parseSignedCookies;
    
    var me = this,
        watch = {},
        localRpc = {},
        remoteRpc = {};
    
    module.paths.push(SERVICE_PATH);
    
    function fireClientEvent(service, event) {
        var args = Array.prototype.slice.call(arguments, 0);
        args.unshift('$event');
        try {
            bio.broadcast.emit.apply(bio, args);
        } catch (e) {}
    }
    
    /**
    Service module in global.SERVICE_PATH folder will be monitored.
    Any chnage will trigger this method to reload service module.
    
    @private
    @method loadModule
    @param {String} modName service name (module) in the global.SERVICE_PATH.
    @param {String} serviceName service name
    @param {Boolean} rpc module provide remote procedure or not
    */
    function loadModule(modName, serviceName, rpc) {
        try {
            if (Nasd[serviceName] ) {
                if (typeof Nasd[serviceName].removeAllListeners === 'function') {
                    Nasd[serviceName].removeAllListeners();
                }
                if( typeof Nasd[serviceName].destroy === 'function') {
                    Nasd[serviceName].destroy();
                }
            }
            delete Nasd[serviceName];
            
            delete remoteRpc[serviceName];
            
            if (rpc) {
                remoteRpc[serviceName] = {
                    _method: [],
                    _async_method: []
                };
            }
            
            var service = Nasd[serviceName] = require(modName);
            
            if (rpc && service._event) {
                remoteRpc[serviceName]._event = [].concat(service._event);
                for (var i = 0 ; i < service._event.length ; ++i) {
                    var event = service._event[i];
                    service.on(event, fireClientEvent.bind(me, serviceName, event));
                }
            }
            
            if (rpc && service._method) {
                //remoteRpc[serviceName]._method = [];
                for (var name in service._method) {
                    remoteRpc[serviceName]._method.push(name);
                }
            }
            if (rpc && service._async_method) {
                //remoteRpc[serviceName]._async_method = [];
                for (var name in service._async_method) {
                    remoteRpc[serviceName]._async_method.push(name);
                }
            }
        } catch (e) {
            error(e.stack);
            delete remoteRpc[serviceName];
        }
    }
    
    /**
    The watchModule will trigger automaticlly when service source code had changed.
    
    @private
    @method watchModule
    @param {String} modName service module folder name
    @param {String} modPath service module full path
    @param {String} serviceName service name
    @param {Boolean} rpc module provide remote procedure or not
    @param {Object} curr
    @param {Object} prev
    */
    function watchModule(modName, modPath, serviceName, rpc, curr, prev) {
        if (+curr.mtime && +prev.mtime) {
            var cacheName = require.resolve(modName);
            delete require.cache[cacheName];
            loadModule(modName, serviceName, rpc);
            me.emit('reloaded');
        }
    }
    
    /**
    Evenytime RpcDispitcher is created and service module is found. We need handle it source change event.
    And try to update rpc mapper for web client.
    
    @private
    @method watchFolder
    @param {String} modName service module folder name
    @param {String} modPath service module full path
    @param {Object} module package
    */
    function watchFolder(modName, modPath, pkg) {
        var stats = fs.statSync(modPath);
        if(stats.isDirectory()) {
            fs.watch(
                modPath,
                {interval: 1000},
                watchModule.bind(null, modName, modPath, pkg.name || modName, (pkg && pkg.rpc ? pkg.rpc : false))
            );
            var dir = fs.readdirSync(modPath);
            while(dir.length > 0) {
                watchFolder(modName, path.join(modPath, dir.shift()), pkg);
            }
        } else {
            fs.watchFile(
                modPath,
                {interval: 1000},
                watchModule.bind(null, modName, modPath, pkg.name || modName, (pkg && pkg.rpc ? pkg.rpc : false))
            );
        }
    }
    
    /**
    Read service module package information. Rpcd take case some properties.
    <pre>
    dependencies {Object}
    resource {Boolean}
    rpc {Boolean}
    js [String]
    css [String]
    i18n [String] international message file, ex: en.json, tw.json, ...
    </pre>
    
    @private
    @method readPackageInfo
    @param {String} modPath
    @return {Object} package json information
    */
    function readPackageInfo(modPath) {
        try {
            var file = path.join(modPath, 'package.json');
            var json = fs.readFileSync(file, 'utf8');
            var pkg = JSON.parse(json);
            
            pkg.path = modPath;
            pkg.js = pkg.js || [];
            pkg.css = pkg.css || [];
            pkg.rpc = pkg.rpc || false;
            pkg.i18n = pkg.i18n || [];
            pkg.dependencies = pkg.dependencies || {};
            
        } catch (e) {}
        return pkg;
    }
    
    var serviceMods = [];
    function dependHandler(pkg) {
        var mod = pkg.name;
        var pilot = -1;
        // find out the last depend module index
        for (var k in pkg.dependencies) {
            for (var i = serviceMods.length - 1 ; i >= 0 ; --i) {
                if (serviceMods[i].name === k) {
                    if (i > pilot) {
                        pilot = i;
                    }
                    break;
                }
            }
        }
        
        // find out the first module depend on current module
        for (++pilot ; pilot < serviceMods.length ; ++pilot) {
            if (serviceMods[pilot].dependencies[mod]) {
                pilot = pilot - 1 > 0 ? --pilot : 0;
                break;
            }
        }
        
        if (pilot === -1) {
            serviceMods.push(pkg);
        } else {
            var tmp = serviceMods.splice(pilot, serviceMods.length);
            serviceMods.push(pkg)
            serviceMods = serviceMods.concat(tmp);
        }
    }
    
    //var jsContent;
    function jsHandler() {
        var content  = fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.sencha/ext-all.js'), 'utf8');
            content += fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/socket.io.js'), 'utf8');
            content += fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/rpc.js'), 'utf8');
            content += fs.readFileSync(path.join(PUBLIC_PATH, 'javascripts/com.thecus/base.js'), 'utf8');
        for (var i = 0 ; i < serviceMods.length ; ++i) {
            var pkg = serviceMods[i],
                js = pkg.js;
            for (var j = 0 ; j < js.length ; ++j) {
                try {
                    var src = path.join(pkg.path, 'js', js[j]);
                    content += fs.readFileSync(src, 'utf8');
                } catch (e) {}
            }
        }
        zlib.deflate(content, function (err, buffer) {
            jsContent = buffer;
        });
    }
    
    function cssHandler() {
        var content = fs.readFileSync(path.join(PUBLIC_PATH, 'stylesheets/com.sencha/ext-all.css'), 'utf8');
        for (var i = 0 ; i < serviceMods.length ; ++i) {
            var pkg = serviceMods[i],
                css = pkg.css;
            for (var j = 0 ; j < css.length ; ++j) {
                try {
                    var src = path.join(pkg.path, 'css', css[j]);
                    content += fs.readFileSync(src, 'utf8');
                } catch (e) {}
            }
        }
        zlib.deflate(content, function (err, buffer) {
            cssContent = buffer;
        });
    }
    
    function resourceHandler() {
        
    }
    
    function i18nHandler() {
        var content = {};
        for (var i = 0 ; i < serviceMods.length ; ++i) {
            var pkg = serviceMods[i],
                i18n = pkg.i18n;
            for (var j = 0 ; j < i18n.length ; ++j) {
                try {
                    var src = path.join(pkg.path, 'i18n', i18n[j] + '.json');
                    var json = fs.readFileSync(src, 'utf8');
                    content[i18n[j]] = content[i18n[j]] || {};
                    content[i18n[j]][pkg.name] = JSON.parse(json);
                } catch (e) {
                    error(e.stack);
                }
            }
        }
        
        content = 'var i18n = ' + JSON.stringify(content);
        
        zlib.deflate(content, function (err, buffer) {
            i18nContent = buffer;
        });
    }
    
    function watchReloadModule() {
        
    }
    
    function watchHandler() {
        
    }
    
    var depend = [];
    function discovery() {
        var dir = fs.readdirSync(SERVICE_PATH);
        for( var i = 0 ; i < dir.length ; ++i ) {
            var modName = dir[i];
            var modPath = path.join(SERVICE_PATH, modName);
            var stats = fs.statSync(modPath);
            
            if(!stats.isDirectory()) {
                continue;
            }
            
            var pkg = readPackageInfo(modPath);
            if (pkg) {
                dependHandler(pkg);
            }
            
            watch[modName] = [];
            watchFolder(modName, modPath, pkg);
            
            loadModule(modName, pkg.name || modName, (pkg && pkg.rpc ? pkg.rpc : false));
        }
        me.emit('discoveried');
        jsHandler();
        cssHandler();
        i18nHandler();
    }
    me.discovery = discovery;
    
    
    /**
    This method will trigged when client side had a remote procedure call.
    
    @private
    @method invoker
    @param {Object} invoker client side caller arguments
    */
    function invoke(invoker) {
        var argv = Array.prototype.slice.call(arguments, 1),
            service = invoker[0],
            method = invoker[1],
            fn = argv.pop();
        
        if (typeof fn !== 'function') {
            argv.push(fn);
            fn = undefined;
        }
        
        if (!Nasd[service]) {
            throw new Error('Service or method not found');
            return;
        }
        
        try {
            if (Nasd[service]._method && Nasd[service]._method[method]) {
                if (!fn) {
                    Nasd[service]._method[method].apply(Nasd[service], argv);
                } else {
                    fn(Nasd[service]._method[method].apply(Nasd[service], argv));
                }
            }
            
            if (Nasd[service]._async_method && Nasd[service]._async_method[method]) {
                if (!fn) {
                    Nasd[service]._async_method[method].apply(Nasd[service], argv);
                } else {
                    argv.push(fn);
                    Nasd[service]._async_method[method].apply(Nasd[service], argv);
                }
            }
        } catch (e) { error(e.stack); }
    }
    
    function auth(id, pwd, fn) {
        var socket = this,
            vaild = Nasd.System.auth(id, pwd);
        if (vaild) {
            socket.on('invoke', invoke);
            socket.emit('services', remoteRpc);
        }
        
        if (typeof fn === 'function') {
            fn(vaild);
        }
    }
    
    /**
    Handle socket.io client's connection events.
    
    @private
    @method onSockIOConnection
    @param {Socket} socket socket.io client connection
    */
    function onSockIOConnection(socket) {
        socket.on('auth', auth);
    }
    
    /**
    Socket.io customer authorization method.
    
    @private
    @method onAuthorization
    @param {Object} data socker.io client connection header data
    @param {Function} callback
     */
    function onAuthorization(data, callback) {
        var cookies = parse(data.headers.cookie);
        data.cookies = parseSignedCookies(cookies, SECRET);
        var sid = data.cookies['connect.sid'];
        callback(null, true);
    }
    
    /**
    Implement unix socket invoker to handle remote procedure call.
    Everything is like RPC over HTTP.
    */
    var UNIX_SOCK = '/var/run/nasd.sock';
    try {
        fs.unlinkSync(UNIX_SOCK);
    } catch(e) {}
    
    var net = require('net'),
        sock;
    
    function callback(c, id) {
        var params = Array.prototype.slice.call(arguments);
        params.splice(0, 2);
        c.write(
            JSON.stringify({
                id: id,
                params: params
            }),
            'utf8'
        );
    }
    
    sock = net.createServer(function (c) {
        c.setEncoding('utf8');
        c.on('data', function (req) {
            try {
                req = JSON.parse(req);
                
                if (req.fn) {
                    req.fn = callback.bind(me, c, req.id);
                }
                
                invoke.apply(
                    me,
                    [].concat(
                        [[req.service, req.method]],
                        req.params,
                        req.fn
                    )
                );
            } catch(e) {info(e.stack)}
        });
        c.write(JSON.stringify(remoteRpc), 'utf8');
    });
    
    sock.listen(UNIX_SOCK);
    
    io.set('log level', 0);
    io.set('authorization', onAuthorization)
    io.sockets.on('connection', onSockIOConnection);
    
    me.un = me.removeListener;
}
inherits(Rpcd, events.EventEmitter);

/**
Nasd will contain all servers and RPC dispatcher.

@class Nasd
*/
global.Nasd = {};

/**
Webd

@property Webd
@type Webd
*/
Nasd.Webd = new Webd();

/**
Rpcd

@property Rpcd
@type Rpcd
*/
Nasd.Rpcd = new Rpcd();
Nasd.Rpcd.discovery();

/**
Mnid

@property Mnid
@type Mnid
*/
Nasd.Mnid = require('./mnid');
Nasd.Mnid.start();
