TCode.DataGuard.Container = function(c) {
    var self = this,
        action = '';
    
    c = Ext.apply(c || {}, {
        frame: false,
        loadMask: true,
        viewConfig: new Ext.grid.GridView({
            autoFill: true,
            forceFit: true
        }),
        view: new Ext.grid.GroupingView({
            forceFit: true,
            groupTextTpl: '{text} ({[values.rs.length]})'
        }),
        sm: new Ext.grid.RowSelectionModel({
            singleSelect: true,
            listeners: {
                rowselect: onSelected
            }
        }),
        columns: [
            {
                header: 'TID',
                dataIndex: 'tid',
                hidden: true
            },
            {
                header: WORDS['main_category'],
                dataIndex: 'act_type',
                hidden: true,
                renderer: typeColumnRenderer
            },
            {
                header: WORDS['main_task_name'],
                dataIndex: 'task_name',
                width: 100
            },
            {
                header: WORDS['main_source_path'],
                renderer: srcPathColumnRenderer
            },
            {
                header: WORDS['main_source_folder'],
                renderer: srcColumnRenderer
            },
            {
                header: WORDS['main_target_path'],
                renderer: dstPathColumnRenderer
            },
            {
                header: WORDS['main_last_time'],
                dataIndex: 'last_time',
                renderer: lastTimeColumnRenderer
            },
            {
                header: WORDS['main_back_type'],
                dataIndex: 'back_type',
                renderer: backTypeRenderer
            },
            {
                header: WORDS['main_status'],
                dataIndex: 'status',
                renderer: lastStatusColumnRenderer
            }
        ],
        store: TCode.DataGuard.TaskStore,
        tbar: [
            {
                text: WORDS['main_add'],
                iconCls: 'add',
                tooltip: WORDS['main_add_tip'],
                ttype: 'create',
                id: 'tbarCreateBtn',
                handler: onFunctionClcik
            },
            {
                text:  WORDS['main_edit'],
                iconCls: 'edit',
                tooltip:  WORDS['main_edit_tip'],
                ttype: 'modify',
                id: 'tbarModifyBtn',
                handler: onFunctionClcik
            },
            {
                text: WORDS['main_remove'],
                iconCls: 'remove',
                tooltip: WORDS['main_remove_tip'],
                ttype: 'remove',
                id: 'tbarRemoveBtn',
                handler: onFunctionClcik
            },
            {
                text: WORDS['main_start'],
                iconCls: 'resume',
                tooltip: WORDS['main_start_tip'],
                ttype: 'start',
                id: 'tbarStartBtn',
                handler: onFunctionClcik
            },
            {
                text: WORDS['main_stop'],
                iconCls: 'stop',
                tooltip: WORDS['main_stop_tip'],
                ttype: 'stop',
                id: 'tbarStopBtn',
                handler: onFunctionClcik
            },
            {
                text: WORDS['main_restore'],
                iconCls: 'restore',
                tooltip: WORDS['main_restore_tip'],
                ttype: 'restore',
                id: 'tbarRestoreBtn',
                handler: onFunctionClcik
            },
            {
                text: WORDS['main_log'],
                iconCls: 'log',
                tooltip: WORDS['main_log_tip'],
                ttype: 'log',
                id: 'tbarLogBtn',
                handler: onFunctionClcik
            },
            '-',
            '->',
            {
                text: WORDS['main_restore_conf'],
                iconCls: 'restore',
                tooltip: WORDS['main_restore_conf_tip'],
                ttype: 'restoreConfig',
                id: 'tbarRestoreConfigBtn',
                handler: onFunctionClcik
            }
        ],
        listeners: {
            render: onRender,
            beforedestroy: onDestroy
        }
    });
    
    function typeColumnRenderer(value, dom, r, index, row, store) {
        return value;
    }
    
    function backTypeRenderer(value, dom, r, index, row, store) {
        if(r.data.back_type == 'schedule' && r.data.opts.schedule_enable == '0'){
            return '';
        }else{
            if(r.data.back_type == 'schedule') {
                return String.format('{0}({1})',
                    WORDS[value],
                    WORDS[r.data.opts.schedule_type]
                );
            }
            return WORDS[value];
        }
    }
    
    function srcPathColumnRenderer(value, dom, r, index, row, store) {
        var path = '/';
        if( r.data.opts.src_dev ) {
            if( r.data.opts.src_path.search(/\/raid[0-9]+\/data/) != -1){
                path = r.data.opts.src_path.replace(/\/raid[0-9]+\/data/, '');
            } else {
                path = r.data.opts.src_path.replace(/\/stackable\/(.)+\/data/, '');
            }
            
            return String.format(
                '<div ext:qtip="{0}">{1}</div>',
                r.data.opts.src_model + path,
                r.data.opts.src_model + path
            );
        } else {
            path = r.data.opts.src_path || '';
            return String.format(
                '<div ext:qtip="{0}">{1}</div>',
                path,
                path
            );
        }
    }
    
    function srcColumnRenderer(value, dom, r, index, row, store) {
        if( r.data.opts.remote_back_type == 'full' ) {
            return '*';
        }
        if( r.data.opts && r.data.opts.src_folder ) {
            value = r.data.opts.src_folder.split('/');
            for( var i = 0 ; i < value.length ; ++i ) {
                value[i] = value[i].match(/^([^:]*):?(.*)$/);
                if( value[i][2] == '' ) {
                    value[i] = value[i][1];
                } else {
                    value[i] = value[i][2];
                }
            }
            var tip = value.join('<br>');
            return String.format('<div ext:qtip="{0}">{1}</div>', tip, value.join(', '));
        }
        return '';
    }
    
    function dstPathColumnRenderer(value, dom, r, index, row, store) {
        if(r.data.opts){
            var tmp = '';
            var path = '';
            var model = '';
            
            switch (r.data['act_type']){
                case 'local':
                    if( r.data.opts.dest_dev ) {
                        if( r.data.opts.dest_path.search(/\/raid[0-9]+\/data/) != -1){
                            path = r.data.opts.dest_path.replace(/\/raid[0-9]+\/data/, '') || '/';
                        }
                        if(r.data.opts.dest_model != ''){
                            model = r.data.opts.dest_model + '/';
                        }
                    }else{
                        path = r.data.opts.dest_path || '/';
                    }
                    
                    var folder = r.data.opts.dest_folder || '';
                    if(r.data.opts.dest_dev == ''){
                        folder = folder.split(':')[1];
                    }
                    
                    if(folder != ''){
                        if( path == '' ){
                            tmp = path + folder;
                        }else{
                            path = path.split('/');
                            tmp = (path[1]) ? path[1] + '/' + folder : folder;
                        }
                    }
                    
                    tmp = model + tmp;
                    
                    break;
                    
                case 'remote':
                    var path = r.data.opts.dest_folder || '';
                    if( r.data.opts.subfolder != '' ) {
                        path += "/" + r.data.opts.subfolder;
                    }
                    tmp = r.data.opts.ip + ':/' + path;
                    break;
                case 's3':
                    tmp = r.data.opts.dest_folder + '/' + r.data.opts.subfolder;
                    break;
            }
            
            return String.format('<div ext:qtip="{0}">{1}</div>', tmp, tmp);
        }
    }
    
    function lastTimeColumnRenderer(value, dom, r, index, row, store) {
        return value;
    }
    
    function lastStatusColumnRenderer(value, dom, r, index, row, store) {
        code = Number(value);
        if( code == 0 ) {
            return '';
        } else if( code < 1000 ) {
            //status code
            var status = 'status_' + value;
            var msg = WORDS[status] ? WORDS[status] : WORDS['unknow'];
        } else {
            //error code
            var msg = TCode.DataGuard.Error.format(code);
        }
        r.detail = r.detail || {};
        if( code == 1 || code == 400 || code == 402 ) {
            if( r.detail.percent == '' ) {
                return String.format(
                    '<div ext:qtip="{0}" style="color:#00F">{1}</div>',
                    r.detail.process,
                    msg
                );
            } else {
                var process = r.detail.process;
                if(process != undefined){
                    process = '[' + process + ']';
                }
                return String.format(
                    '<div ext:qtip="{1}{0}" style="color:#00F">{2}</div>',
                    process || '',
                    r.detail.percent || '',
                    msg
                );
            }
        } else {
            return msg;
        }
    }
    
    function onSelected(target, i, r){
        switch(r.data['act_type']){
            case 'local':
                switch( r.data['back_type'] ){
                    case 'import':
                    case 'copy':
                    case 'import_iscsi':
                        Ext.getCmp('tbarModifyBtn').disable();
                        Ext.getCmp('tbarStartBtn').disable();
                        break;
                    default:
                        Ext.getCmp('tbarModifyBtn').enable();
                        Ext.getCmp('tbarStartBtn').enable();
                }
                
                if( r.data['back_type'] == 'schedule' || r.data['back_type'] == 'iscsi' ){
                    Ext.getCmp('tbarRestoreBtn').enable();
                }else{
                    Ext.getCmp('tbarRestoreBtn').disable();
                }
                break;
            
            case 'remote':
            case 's3':
                Ext.getCmp('tbarModifyBtn').enable();
                Ext.getCmp('tbarStartBtn').enable();
                break;
        }
        
        if(r.data.status == 1 || r.data.status == 2 || r.data.status == 400 || r.data.status == 402 ){
            Ext.getCmp('tbarStopBtn').enable();
        }else{
            Ext.getCmp('tbarStopBtn').disable();
        }
    }
    
    function onRender() {
        TCode.DataGuard.Wizard.on('create', onCreate);
        TCode.DataGuard.Wizard.on('modify', onModify);
        TCode.DataGuard.Wizard.on('hide', onWizardHide);
        
        if( TCode.DataGuard.AmazonS3 == true ) {
            var rs = new TCode.DataGuard.TaskRecord({
                tid: 0,
                opts: {}
            });
            TCode.DataGuard.Wizard.create(rs);
            delete TCode.DataGuard.AmazonS3;
        }
    }
    
    function onDestroy() {
        TCode.DataGuard.TaskStore.proxy.abort();
        if( TCode.DataGuard ) {
            if( TCode.DataGuard.Wizard ) {
                TCode.DataGuard.Wizard.un('create', onCreate);
                TCode.DataGuard.Wizard.un('modify', onModify);
                //TCode.DataGuard.Wizard.destroy();
            }
            //delete TCode.DataGuard;
        }
    }
    
    function onFunctionClcik(button) {
        var rs = self.selModel.getSelected();
        if( rs ) {
            var status = Number(rs.data.status);
        } else {
            var status = 0;
        }
        
        action = button.ttype;
        switch( action ) {
        case 'modify':
        case 'remove':
        case 'start':
        case 'restore':
        case 'restoreConfig':
            if( status == 1 || status == 2 || status == 400 || status == 401 ) {
                return Ext.MessageBox.alert(WORDS['attention'], WORDS['task_running']);
            }
        }
        
        switch( action ) {
        case 'create':
            var rs = new TCode.DataGuard.TaskRecord({
                tid: 0,
                opts: {}
            });
            TCode.DataGuard.Wizard.create(rs);
            break;
        case 'modify':
            if( rs ) {
                TCode.DataGuard.Wizard.modify(rs);
            } else {
                Ext.MessageBox.alert(WORDS['attention'], WORDS['nothing_todo']);
            }
            break;
        case 'remove':
        case 'start':
        case 'stop':
        case 'restore':
            if( typeof rs == 'undefined' ) {
                return Ext.MessageBox.alert(WORDS['attention'], WORDS['nothing_todo']);
            }
            if( action != 'start' ) {
                Ext.MessageBox.confirm(WORDS['attention'], WORDS['todo_confirm'], onConfirm);
            } else {
                if(rs.data.back_type == 'iscsi'){
                    Ext.MessageBox.confirm(WORDS['attention'], WORDS['start_iscsi_confirm'], function(v){
                        if(v == 'yes'){
                            self.store[action].call(self.store, rs);
                        }
                    });
                }else{
                    if(rs.data.opts.remote_back_type == 'full'){
                        Ext.MessageBox.confirm(WORDS['attention'], WORDS['full_backup_warning'], function(v){
                            if(v == 'yes'){
                                self.store[action].call(self.store, rs);
                            }
                        });
                    }else{
                        self.store[action].call(self.store, rs);
                    }
                }
            }
            break;
        case 'log':
            if( rs ) {
                TCode.DataGuard.Wizard.log(rs);
            } else {
                Ext.MessageBox.alert(WORDS['attention'], WORDS['nothing_todo']);
            }
            break;
        case 'restoreConfig':
            var config;
            
            if( rs ) {
                config = Ext.clone({}, rs.data);
            } else {
                config = {
                    tid: 0,
                    opts: {}
                }
            }
            config.act_type = 'restoreConfig';
            
            rs = new TCode.DataGuard.TaskRecord(config);
            TCode.DataGuard.Wizard.restoreConfig(rs);
            break;
        default:
            break;
        }
    }
    
    function onCreate(rs) {
        self.store.create(rs);
    }
    
    function onConfirm(answer) {
        var rs = self.selModel.getSelected();
        if( answer == 'yes' && rs) {
            self.store[action].call(self.store, rs);
        }
    }
    
    function onWizardHide() {
        self.store.reload();
    }
    
    function onModify(rs) {
        self.store.modify(rs);
    }
    
    function onRefresh() {
        
    }
    
    Ext.grid.GridPanel.superclass.constructor.call(this, c);
}

Ext.extend(TCode.DataGuard.Container, Ext.grid.GridPanel);
Ext.reg('TCode.DataGuard.Container', TCode.DataGuard.Container);

Ext.onReady(function() {
    Ext.QuickTips.init();
    TCode.desktop.Group.addComponent({xtype: 'TCode.DataGuard.Container'});
});

