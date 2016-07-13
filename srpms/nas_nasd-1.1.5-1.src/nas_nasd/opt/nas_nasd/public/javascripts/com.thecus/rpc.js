'use strict';

var Nasd = function (url) {
    var socket = io.connect(url),
        Nasd = {};
    
    Nasd.auth = socket.emit.bind(socket, 'auth');

    Nasd.on = socket.on.bind(socket);
    Nasd.removeListener = socket.removeListener.bind(socket);
    
    socket.on('services', function (services) {
        for (var name in services) {
            var service = services[name];
            var method = service._method;
            
            Nasd[name] = {
                on: socket.on.bind(Nasd[name]),
                once: socket.once.bind(Nasd[name]),
                emit: socket.$emit.bind(Nasd[name])
            };
            Nasd[name].emit.apply = socket.$emit.apply;
            
            for (var m in method) {
                Nasd[name][method[m]] = socket.emit.bind(socket, 'invoke', [name, method[m]]);
            }
            var method = service._async_method;
            for (var m in method) {
                Nasd[name][method[m]] = socket.emit.bind(socket, 'invoke', [name, method[m]]);
            }
        }
    });
    
    socket.on('$event', function (service) {
        var args = Array.prototype.slice.call(arguments, 1);
        Nasd[service].emit.apply(Nasd[service], args);
    });
    
    return Nasd;
};

