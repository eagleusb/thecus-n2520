<script type="text/javascript">
Ext.ns('TCode.Log');

WORDS = <{$words}>;
SERVICES=<{$services}>;
TCode.Log.Ajax = new TCode.ux.Ajax('setlog', <{$procs}>);
TCode.Log.Config = <{$config}>;

TCode.Log.AjaxProxy = function(config) {
    var self = this;
    var ajax = TCode.Log.Ajax;
    
    self.catagory = 'sys';
    self.level = 'all';
    
    self.load = function(params, reader, callback, scope, arg){
        if(this.fireEvent("beforeload", this, params) !== false) {
            Ext.apply(params, {
                catagory: self.catagory,
                level: self.level
            });
            Ext.applyIf(params,{
                start: 0,
                limit: 50
            })
            ajax.query(params, function(data){
                var result = reader.readRecords(data);
                self.fireEvent("load", self, ajax, arg);
                callback.call(scope, result, arg, true);
            });
        } else {
            callback.call(scope||this, null, arg, false);
        }
    }
    
    TCode.Log.AjaxProxy.superclass.constructor.call(self, config);
}
Ext.extend(TCode.Log.AjaxProxy, Ext.data.HttpProxy);

TCode.Log.Container = function(c) {
    var self = this;
    
    var ajax = TCode.Log.Ajax;
    var proxy = new TCode.Log.AjaxProxy();
    
    var monitor = {
        scope: this,
        interval: 0,
        run: onRefresh
    };
    
    var store = new Ext.data.JsonStore({
        autoLoad: true,
        root: 'data',
        totalProperty: 'total',
        fields: ['time', 'user', 'ip', 'event', 'level', 'size', 'computer' , 'filetype' , 'action' ],
        proxy: proxy
    });
    
    var services = [
        {Name: WORDS['catagory_sys'], Value: 'sys'},
        {Name: WORDS['catagory_ftp'], Value: 'ftp'},
        {Name: WORDS['catagory_smb'], Value: 'samba'},
        {Name: WORDS['catagory_ssh'], Value: 'ssh'},
        {Name: WORDS['catagory_afp'], Value: 'afp'}
    ];

    if (SERVICES['iscsi_limit'] != '0') {
        services.push(
            {Name: WORDS['catagory_isc'], Value: 'iscsi'}
        );
    }
    
    var catagory = new Ext.data.JsonStore({
        fields: ['Name', 'Value'],
        data: services
    });
    
    var head = {
        // Total percentage must be 1 for each service
        //'Time', 'Computer', 'User', 'IP', 'Action', 'File Type', 'Event', 'File Size'
        sys:    [.2, .0, .0, .0, .0, .0, .8, .0],
        ftp:    [.2, .0, .1, .1, .1, .1, .3, .1],
        samba:  [.1, .1, .1, .1, .1, .1, .3, .1],
        ssh:    [.2, .0, .2, .2, .0, .0, .4, .0],
        afp:    [.2, .0, .2, .2, .0, .0, .4, .0],
        iscsi:  [.2, .0, .2, .2, .0, .0, .4, .0]
    }
    
    var level = new Ext.data.JsonStore({
        fields: ['Name', 'Value'],
        data: [
            {Name: WORDS['lv_all'], Value: 'all'},
            {Name: WORDS['lv_inf'], Value: 'info'},
            {Name: WORDS['lv_wrn'], Value: 'warning'},
            {Name: WORDS['lv_err'], Value: 'error'}
        ]
    });
    
    var refresh = new Ext.data.JsonStore({
        fields: ['Name', 'Value'],
        data: [
            {Name: WORDS['refresh_00s'], Value: '0'},
            {Name: WORDS['refresh_10s'], Value: '10'},
            {Name: WORDS['refresh_20s'], Value: '20'},
            {Name: WORDS['refresh_60s'], Value: '60'}
        ]
    });
    
    var recordLimit = new Ext.data.JsonStore({
        fields: ['Name', 'Value'],
        data: [
            {Name: WORDS['rs_limit_10000'], Value: '10000'},
            {Name: WORDS['rs_limit_30000'], Value: '30000'},
            {Name: WORDS['rs_limit_50000'], Value: '50000'}
        ]
    });
    
    var recordRole = new Ext.data.JsonStore({
        fields: ['Name', 'Value'],
        data: [
            {Name: WORDS['role_delete'], Value: 'drop'},
            {Name: WORDS['role_export'], Value: 'save'}
        ]
    });
    
    var pageLimit = new Ext.data.JsonStore({
        fields: ['Name', 'Value'],
        data: [
            {Name: WORDS['page_limit_050'], Value: '50'},
            {Name: WORDS['page_limit_100'], Value: '100'},
            {Name: WORDS['page_limit_200'], Value: '200'},
            {Name: WORDS['page_limit_500'], Value: '500'}
        ]
    });
    
    var config = Ext.apply(c || {}, {
        frame: false,
        viewConfig: {
            autoFill: true,
            forceFit: true
        },
        columns: [
            //'時間', '電腦名稱', '使用者', 'IP', '動作', '類型', '事件' 
            {header: WORDS['head_time'], dataIndex: 'time', renderer: colorRenderer},
            {header: WORDS['head_computer'], dataIndex: 'computer', hidden: true, renderer: colorRenderer},
            {header: WORDS['head_user'], dataIndex: 'user', hidden: true, renderer: colorRenderer},
            {header: WORDS['head_ip'], dataIndex: 'ip', hidden: true, renderer: colorRenderer},
            {header: WORDS['head_action'], dataIndex: 'action', hidden: true, renderer: colorActionRenderer},
            {header: WORDS['head_filetype'], dataIndex: 'filetype', hidden: true, renderer: colorFiletypeRenderer},
            {header: WORDS['head_event'], dataIndex: 'event', renderer: colorRenderer},
            {header: WORDS['head_filesize'], dataIndex: 'size', hidden: true, renderer: colorRenderer} 
        ],
        store: store,
        tbar: [
            {
                xtype: 'combo',
                store: recordLimit,
                displayField: 'Name',
                valueField: 'Value',
                value: TCode.Log.Config[0],
                allowBlank: false,
                editable: false,
                forceSelection: true,
                triggerAction: 'all',
                mode: 'local',
                width: 80
            },
            {
                xtype: 'label',
                text: WORDS['records']
            },
            {
                xtype: 'combo',
                store: recordRole,
                displayField: 'Name',
                valueField: 'Value',
                value: TCode.Log.Config[1],
                allowBlank: false,
                editable: false,
                forceSelection: true,
                triggerAction: 'all',
                mode: 'local',
                width: 80
            },
            {
                text: WORDS['apply'],
                iconCls: 'edit',
                handler: onApply
            },
            '-',
            {
                xtype: 'label',
                text: WORDS['display']
            },
            {
                xtype: 'combo',
                store: catagory,
                displayField: 'Name',
                valueField: 'Value',
                value: 'sys',
                allowBlank: false,
                editable: false,
                forceSelection: true,
                triggerAction: 'all',
                mode: 'local',
                width: 80,
                listeners: {
                    select: onCatagoryChange
                }
            },
            {
                xtype: 'label',
                text: WORDS['level']
            },
            {
                xtype: 'combo',
                store: level,
                displayField: 'Name',
                valueField: 'Value',
                value: 'all',
                allowBlank: false,
                editable: false,
                forceSelection: true,
                triggerAction: 'all',
                mode: 'local',
                width: 80,
                listeners: {
                    select: onLevelChange
                }
            },
            {
                text: WORDS['export'],
                iconCls: 'SaveBtn',
                handler: onDownload
            },
            {
                text: WORDS['delete'],
                iconCls: 'remove',
                style: 'padding-right: 10px;',
                handler: onDelete
            },
            '-',
            '->',
            {
                xtype: 'label',
                text: WORDS['auto_refresh']
            },
            {
                xtype: 'combo',
                store: refresh,
                displayField: 'Name',
                valueField: 'Value',
                value: '0',
                allowBlank: false,
                editable: false,
                forceSelection: true,
                triggerAction: 'all',
                mode: 'local',
                width: 80,
                listeners: {
                    select: onRefreshChange
                }
            }
        ],
        bbar: new Ext.PagingToolbar({
            pageSize: 50,
            store: store,
            displayInfo: true,
            displayMsg: WORDS['display_msg'],
            emptyMsg: WORDS['empty_msg'],
            beforePageText: '',
            afterPageText: WORDS['after_page'],
            items: [
                {
                    xtype: 'label',
                    text: WORDS['page_size']
                },
                {
                    xtype: 'combo',
                    store: pageLimit,
                    displayField: 'Name',
                    valueField: 'Value',
                    value: '50',
                    allowBlank: false,
                    editable: false,
                    forceSelection: true,
                    triggerAction: 'all',
                    mode: 'local',
                    width: 80,
                    listeners: {
                        select: onLineChange
                    }
                }
            ]
        }),
        listeners: {
            render: onRender//,
            //beforedestroy: onDestroy
        }
    });
    
    function onRender() {
        //Ext.get('content').getUpdateManager().on('beforeupdate', self.destroy, self );
        //Ext.getCmp('content-panel').on('bodyresize', onResize, self);
        //
        //var content = Ext.getCmp('content-panel');
        //onResize(content, content.el.getWidth(), content.el.getHeight());
        
        gridColumnResize('sys');
    }
    
    //function onDestroy() {
    //    Ext.get('content').getUpdateManager().un('beforeupdate', self.destroy, self );
    //    Ext.getCmp('content-panel').un('bodyresize', onResize, self);
    //    ajax.abort();
    //    stopMonitor();
    //    delete TCode.Log;
    //}
    //
    //function onResize(content, w, h) {
    //    self.setSize(w - 42, h - 78);
    //}
    
    function colorRenderer(value, metaData, record) {
        switch(record.data.level) {
        case 'warning':
            metaData.attr = 'style="color: blue;"';
            break;
        case 'error':
            metaData.attr = 'style="color: red;"';
            break;
        }
        return value;
    }
    
    function colorActionRenderer(value, metaData, record) {
        return colorRenderer(WORDS["act_" + value.toLowerCase()], metaData, record);
    }
    
    function colorFiletypeRenderer(value, metaData, record) {
        return colorRenderer(WORDS["ftype_" + value.toLowerCase()], metaData, record);
    }
    
    function onCatagoryChange(combo, rs) {
        gridColumnResize(rs.get('Value'));
    }
    
    function gridColumnResize(catagory) {
        proxy.catagory = catagory;
        self.store.removeAll();
        var vw = self.view.lastViewWidth;
        for( var i = 0 ; i < head[catagory].length ; ++i ) {
            var w = head[catagory][i];
            self.colModel.setHidden(i, w === 0);
            self.colModel.setColumnWidth(i, w * vw);
        }
        self.view.fitColumns();
        self.bottomToolbar.changePage(1);
    }
    
    function onLevelChange(combo, rs) {
        proxy.level = rs.get('Value');
        self.bottomToolbar.changePage(1);
    }
    
    function onRefreshChange(combo, rs) {
        var time = Number(rs.get('Value')) * 1000;
        stopMonitor();
        monitor.interval = time;
        if( time > 0 ) {
            Ext.TaskMgr.start(monitor);
        }
    }
    
    function stopMonitor() {
        if( monitor.taskStartTime ) {
            Ext.TaskMgr.stop(monitor);
            delete monitor.taskStartTime;
        }
    }
    
    function onLineChange(combo, rs) {
        var limit = Number(rs.get('Value'));
        self.bottomToolbar.pageSize = limit;
        self.bottomToolbar.changePage(1);
    }
    
    function onRefresh() {
        self.bottomToolbar.changePage(1);
    }
    
    function onDownload() {
        var params = {};
        with(self.topToolbar.items) {
            Ext.apply(params, {
                catagory: get(6).getValue(),
                level: get(8).getValue()
            });
        }
        window.open('setmain.php?fun=setlog&action=download&params=' + Ext.encode(params), '_blank');
    }
    
    function onDelete() {
        var params = {};
        var msg;
        with(self.topToolbar.items) {
            msg = String.format(
                WORDS['delete_attention'],
                get(6).getRawValue(),
                get(8).getRawValue()
            );
            Ext.apply(params, {
                catagory: get(6).getValue(),
                level: get(8).getValue()
            });
        }
        
        Ext.Msg.show({
            title: WORDS['attention'],
            msg: msg,
            buttons: Ext.Msg.YESNO,
            icon: Ext.Msg.WARNING,
            fn: function(ans) {
                if( ans == 'yes' ) {
                    ajax.remove(params, onRefresh);
                }
            }
        });
    }
    
    function onApply() {
        var msg;
        var params = {};
        with(self.topToolbar.items) {
            msg = String.format(
                WORDS['role_attention'],
                get(0).getRawValue(),
                get(2).getRawValue()
            );
            Ext.apply(params, {
                size_items: get(0).getValue(),
                role: get(2).getValue()
            });
        }
        
        Ext.Msg.show({
            title: WORDS['attention'],
            msg: msg,
            buttons: Ext.Msg.YESNO,
            icon: Ext.Msg.WARNING,
            fn: function(ans) {
                if( ans == 'yes' ) {
                    ajax.changeRole(params, onRefresh);
                }
            }
        });
    }
    
    TCode.Log.Container.superclass.constructor.call(self, config);
}
Ext.extend(TCode.Log.Container, Ext.grid.GridPanel);

Ext.onReady(function(){
    Ext.MessageBox.minWidth = 400;
    Ext.QuickTips.init();
    TCode.desktop.Group.addComponent(new TCode.Log.Container());
})
</script>
