'use strict';

function Torrent() {
    events.EventEmitter.call(this);

    var self = this;
    
    var bt = require('quartz');
    
    bt.connect({
        auth_required: true,
        username: 'admin:',
        password: 'admin'
        },
        function(err){
            if (err) info(err);
        }
    );
    
    var btList = {};
    
    function list() {
        bt.query(
            'torrent-get',
            {
                fields: [
                    'id',
                    'name',
                    'status',
                    'percentDone',
                    'rateDownload',
                    'downloadDir',
                    'peers'
                ]
            },
            function(err, res, body) {
                if (err) {
                    info(err);
                } else {
                    btList = countAvailability(body.arguments.torrents);
                    self.emit('update', btList);
                }
            });
    }
    var task = setInterval(list, 30000);
    
    list();
    
    self.destroy = function () {
        clearInterval(task);
    }
    
    
    function TorrentList(){
        var fn;
        
        if (typeof arguments[0] === 'function'){
            fn = arguments[0];
        } else {
            info("Error! Without any callback function");
            return false;
        }
        
        fn(btList);
    }
    self.TorrentList = TorrentList;
    
    function countAvailability(torrents){
        for (var i = 0 ; i < torrents.length ; ++i){
            torrents[i].rateDownload = Math.floor(torrents[i].rateDownload/102)/10;
            var max = torrents[i].percentDone;
            for (var j = 0 ; j < torrents[i].peers.length ; ++j){
                if (torrents[i].peers[j].progress > max){
                    max = torrents[i].peers[j].progress;
                    if (max == 1){
                        break;
                    }
                }
            }
            torrents[i].availability = max;
        }
        return torrents;
    }

    function TorrentStart(){
        var id, fn, btname;
        
        if (typeof arguments[0] === 'number' && typeof arguments[1] === 'function'){
            id = arguments[0];
            fn = arguments[1];
        } else {
            info("Parameter type error!");
            return false;
        }
        
        function onResult(err, res, body) {
            if (err) {
                fn(false);
            } else {
                fn(true);
                insertLogBT(btname, 'INFO', 'BT START');
            }
        }
        
        btname = getNameById(id);
        if (!btname) {
            fn(false);
        } else {
            bt.query(
                'torrent-start',
                {
                    ids: [id],
                },
                onResult
            );
        }
    }
    self.TorrentStart = TorrentStart;

    function TorrentStop(){
        var id, fn, btname;
        
        if (typeof arguments[0] === 'number' && typeof arguments[1] === 'function'){
            id = arguments[0];
            fn = arguments[1];
        } else {
            info("Parameter type error!");
            return false;
        }
        
        function onResult(err, res, body) {
            if (err) {
                fn(false);
            } else {
                fn(true);
                insertLogBT(btname, 'INFO', 'BT STOP');
            }
        }
        
        btname = getNameById(id);
        if (!btname) {
            fn(false);
        } else {
            bt.query(
                'torrent-stop',
                {
                    ids: [id],
                },
                onResult
            );
        }
    }
    self.TorrentStop = TorrentStop;

    function TorrentRemove(){
        var id, fn, btname;
        
        if (typeof arguments[0] === 'number' && typeof arguments[1] === 'function'){
            id = arguments[0];
            fn = arguments[1];
        } else {
            info("Parameter type error!");
            return false;
        }
        
        function onResult(err, res, body) {
            if (err) {
                fn(false);
            } else {
                fn(true);
                list();
                insertLogBT(btname, 'INFO', 'BT REMOVE');
            }
        }
        
        btname = getNameById(id);
        if (!btname) {
            fn(false);
        } else {
            bt.query(
                'torrent-remove',
                {
                    ids: [id],
                    'delete-local-data': false
                },
                onResult
            );
        }
    }
    self.TorrentRemove = TorrentRemove;

    
    Nasd.Webd.addUploadHandler('torrent-file', function (tmp, name) {
        var fs = require('fs');
        
        function onResult(err, res, body) {
            if (err) {
            } else {
                list();
                if (body.arguments['torrent-added']){
                    insertLogBT(body.arguments['torrent-added'].name, 'INFO', 'BT ADD');
                } else {
                    insertLogBT(body.result, 'WARNING', 'BT ADD');
                }
            }
            fs.unlinkSync(tmp);
            list();
        }
        
        bt.query(
            'torrent-add',
            {
                filename: tmp
            },
            onResult
        );
    });
    
    function getNameById(id){
        var name = '';
        for (var i = 0 ; i < btList.length ; ++i){
            if (btList[i].id == id){
                return btList[i].name;
            }
        }
    }
    
    function insertLogBT(event, level, action){
        Nasd.History.insertLog({
            $conn: 'BT',
            $user: 'root',
            $sip: '',
            $name: '',
            $size: '',
            $event: event,
            $tmp: '',
            $level: level,
            $type: '',
            $action: action
        });
    }
    
    self._async_method = {
        list: TorrentList,
        start: TorrentStart,
        stop: TorrentStop,
        remove: TorrentRemove
    };

    self._event = [
        'update',
    ];
}

inherits(Torrent, events.EventEmitter);

module.exports = new Torrent();
