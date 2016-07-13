'use strict';

function Network() {
    events.EventEmitter.call(this);
    
    var SERVICE_INFO = {
        'ftp': '/var/tmp/monitor/FTP_User_Info',
        'afp': '/var/tmp/monitor/AFP_User_Info',
        'nfs': '/var/tmp/monitor/NFS_User_Info',
        'smb': '/var/tmp/monitor/Samba_User_Info'
    };
    
    var me = this,
        fs = require('fs'),
        curentList = {};
    
    function onRefreshTimer() {
        for (var service in SERVICE_INFO) {
            delete curentList[service];
            curentList[service] = [];
            try {
                var data = fs.readFileSync(SERVICE_INFO[service], 'utf8');
                data = data.split('\n');
                data.shift();
                for (var i = 0 ; i < data.length ; ++i) {
                    data[i] = data[i].match(/^([^,]*),([^,]*),(.*)/);
                    if (!data[i]) {
                        continue;
                    }
                    curentList[service].push({
                        ip: data[i][1],
                        user: data[i][2],
                        folder: data[i][3]
                    });
                }
            } catch(e) {}
        }
    }
    
    function getWhoList() {
        return curentList;
    }
    me.getWhoList = getWhoList;
    
    me._method = {
        whoList : getWhoList
    }
    
    onRefreshTimer();
    setInterval(onRefreshTimer, 30000);
}
inherits(Network, events.EventEmitter);

module.exports = new Network();
