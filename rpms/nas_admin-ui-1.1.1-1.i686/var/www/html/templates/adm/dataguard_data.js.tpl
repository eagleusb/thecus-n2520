TCode.DataGuard.TaskProxy = function() {
    TCode.DataGuard.TaskProxy.superclass.constructor(this);
    
    var self = this,
        store,
        monitorTasks = [],
        monitor = {
            scope: this,
            interval: 10000,
            run: monitorStatus
        };
    
    function startMonitor(){
        Ext.TaskMgr.start(monitor);
    }
    self.startMonitor = startMonitor;
    
    function abort() {
        TCode.DataGuard.Ajax.abort();
        if( monitor.taskStartTime ) {
            Ext.TaskMgr.stop(monitor);
            delete monitor.taskStartTime;
        }
    }
    self.abort = abort;

    self.load = function(params, reader, callback, scope, arg){
        store = scope;
        self.fireEvent('beforeload', self);
        TCode.DataGuard.Ajax.ListTask(axListTask);
    }
    function axListTask(code, tasks) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        self.fireEvent("load", this, tasks);
        if( store ) {
            monitorTasks.splice(0, monitorTasks.length);
            for( var i = 0 ; i < tasks.length ; ++i ) {
                var tid = tasks[i]['tid'],
                    sts = Number(tasks[i]['status']);
                if( sts == 1 || sts == 2 || sts == 400 || sts == 401 ) {
                    monitorTasks.push(tid);
                }
            }
            if( monitorTasks.length == 0 ) {
                abort();
            } else {
                startMonitor();
            }
            store.loadData(tasks);
        }
        return null;
    }
    
    self.create = function(data) {
        abort();
        TCode.DataGuard.Ajax.CreateTask(data, axCreateTask);
    }
    function axCreateTask(code) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        TCode.DataGuard.Wizard.close();
        TCode.DataGuard.Ajax.ListTask(axListTask);
        return null;
    }
    
    self.modify = function(data) {
        abort();
        data.status = '';
        TCode.DataGuard.Ajax.ModifyTask(data, axModifyTask);
    }
    function axModifyTask(code) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        TCode.DataGuard.Wizard.close();
        TCode.DataGuard.Ajax.ListTask(axListTask);
        return null;
    }
    
    self.remove = function(data) {
        abort();
        TCode.DataGuard.Ajax.RemoveTask(data.tid, axRemoveTask);
    }
    function axRemoveTask(code) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        TCode.DataGuard.Ajax.ListTask(axListTask);
        return null;
    }
    
    self.start = function(data) {
        abort();
        TCode.DataGuard.Ajax.StartTask(data.tid, axStartTask);
    }
    function axStartTask(code, status) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        TCode.DataGuard.Ajax.ListTask(axListTask);
        return null;
    }
    
    self.stop = function(data) {
        abort();
        TCode.DataGuard.Ajax.StopTask(data.tid, axStopTask);
    }
    function axStopTask(code) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        TCode.DataGuard.Ajax.ListTask(axListTask);
        return null;
    }
    
    self.restore = function(data) {
        abort();
        TCode.DataGuard.Ajax.RestoreTask(data.tid, axRestoreTask);
    }
    function axRestoreTask(code) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        TCode.DataGuard.Ajax.ListTask(axListTask);
        return null;
    }
    
    function monitorStatus() {
        TCode.DataGuard.Ajax.MonitorTask(monitorTasks, axMonitorTask);
    }
    function axMonitorTask(code, status) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        
        monitorTasks.splice(0, monitorTasks.length);
        for( var i = 0 ; i < status.length ; ++i ) {
            var tid = status[i][0],
                s = status[i][1],
                sts = Number(s[0]),
                idx = store.find('tid', tid);
            if( idx != -1 ) {
                var rs = store.getAt(idx);
            }
            
            if( sts == 1 || sts == 2 || sts == 400 || sts == 401 ) {
                monitorTasks.push(tid);
            }
            
            if( rs ) {
                rs.beginEdit();
                rs.set('status', sts);
                if( sts == 1 || sts == 2 || sts == 400 || sts == 401 ) {
                    rs.detail = {
                        process: s[1] || '',
                        percent: s[2] || ''
                    };
                } else {
                    //delete rs.detail
                    abort();
                    TCode.DataGuard.Ajax.ListTask(axListTask);
                    return;
                }
                rs.endEdit();
                rs.commit();
            }
        }
        if( monitorTasks.length == 0 ) {
            abort();
        }
        return null;
    }
}
Ext.extend(TCode.DataGuard.TaskProxy, Ext.data.DataProxy);

TCode.DataGuard.TaskStructure = [
    {name: 'tid'},
    {name: 'task_name'},
    {name: 'back_type'},
    {name: 'act_type'},
    {name: 'last_time'},
    {name: 'status'},
    {name: 'opts'}
]

TCode.DataGuard.TaskStore = new Ext.data.GroupingStore({
    autoLoad: true,
    proxy: new TCode.DataGuard.TaskProxy(),
    reader: new Ext.data.JsonReader({},TCode.DataGuard.TaskStructure),
    sortInfo: {
        field: 'act_type',
        direction: 'ASC'
    },
    groupField: 'act_type',
    create: function(rs) {
        this.proxy.create(rs.data);
    },
    modify: function(rs) {
        this.proxy.modify(rs.data);
    },
    remove: function(rs) {
        this.proxy.remove(rs.data);
    },
    start: function(rs) {
        this.proxy.start(rs.data);
    },
    stop: function(rs) {
        this.proxy.stop(rs.data);
    },
    restore: function(rs) {
        this.proxy.restore(rs.data);
    }
})

TCode.DataGuard.TaskRecord = Ext.data.Record.create(TCode.DataGuard.TaskStructure);

TCode.DataGuard.FolderProxy = function() {
    TCode.DataGuard.FolderProxy.superclass.constructor(this);
    
    var self = this,
        log = false,
        store;
    
    //function axListFolder(code, path, folders) {
    function axListFolder(code, folders) {
        /*
        if( log == false && path != "" ) {
            path = path.match(/^(.*)\/(.*)\/?/i);
            path = path[1];
            folders.unshift(["..", path]);
        }
        */
        if( folders.length == 1 && folders[0].items) {
            self.fireEvent("load", this, folders[0].items);
            if( store ) {
                store.loadData(folders[0].items);
            }
        } else {
            self.fireEvent("load", this, folders);
            if( store ) {
                store.loadData(folders);
            }
        }
    }
    this.load = function(params, reader, callback, scope, arg){
        arg = arg || {};
        log = arg.log ? true : false;
        store = scope;
        self.fireEvent('beforeload', self);
        TCode.DataGuard.Ajax.ListFolder(arg.type, arg.path, axListFolder);
    }
    this.listFolder = function(path) {
        self.fireEvent('beforeload', self);
        TCode.DataGuard.Ajax.ListFolder(path);
    }
}
Ext.extend(TCode.DataGuard.FolderProxy, Ext.data.DataProxy);
