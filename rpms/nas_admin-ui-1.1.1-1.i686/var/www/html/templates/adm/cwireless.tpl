<script type="text/javascript">
Ext.ns('TCode.CWireless');

TCode.CWireless.Words = <{$WORDS}>;

TCode.CWireless.APStoreProxy = function(c) {
    var me = this,
        ajax = c.ajax;
    
    me.load = function(params, reader, callback, scope, arg) {
        if(this.fireEvent("beforeload", this, params) !== false) {
            Ext.apply(params, {
                catagory: self.catagory,
                level: self.level
            });
            Ext.applyIf(params,{
                start: 0,
                limit: 50
            })
            ajax.rescan_AP_list(function (data) {
                var result = reader.readRecords(data);
                me.fireEvent("load", me, ajax, arg);
                callback.call(scope, result, arg, true);
            });
        } else {
            callback.call(scope||this, null, arg, false);
        }
    }
    
    TCode.CWireless.APStoreProxy.superclass.constructor.call(me, c);
}
Ext.extend(TCode.CWireless.APStoreProxy, Ext.data.HttpProxy);

TCode.CWireless.APList = function (c) {
    var me = this,
        ui = {},
        sm,
        ajax = c.ajax;
    
    var store = new Ext.data.JsonStore({
        autoLoad: true,
        fields: ['essid', 'signal', 'keys', 'ap_hwaddr'],
        proxy: new TCode.CWireless.APStoreProxy({
            ajax: c.ajax
        })
    });
    
    c = Ext.apply(c || {}, {
        title: TCode.CWireless.Words.title_list,
        frame: false,
        border: false,
        store: store,
        viewConfig: {
            autoFill: true,
            forceFit: true
        },
        loadMask: {
            msg: TCode.CWireless.Words.scanning
        },
        columns: [
            new Ext.grid.RowNumberer(),
            new Ext.grid.CheckboxSelectionModel(),
            {
                header: TCode.CWireless.Words.ssid,
                dataIndex: 'essid',
                width: 200
            },
            {
                header: TCode.CWireless.Words.signal,
                dataIndex: 'signal',
                width: 50
            },
            {
                header: TCode.CWireless.Words.encryption,
                dataIndex: 'keys',
                width: 100
            }
        ],
        sm: new Ext.grid.RowSelectionModel({
            singleSelect: true
        }),
        tbar: [
            {
                cname: 'scan_btn',
                text: TCode.CWireless.Words.scan,
                handler: onScanButtonEvent,
                listeners: {
                    render: onToolbarRender
                }
            },
            '-',
            {
                cname: 'connect_btn',
                text: TCode.CWireless.Words.connect,
                handler: onConnect,
                listeners: {
                    render: onToolbarRender
                }
            },
            '-'
        ]
    });
    
    TCode.CWireless.APList.superclass.constructor.call(me, c);
    
    me.on('render', onRender);
    me.on('beforedestroy', onDestroy);
    
    function onRender() {
        sm = me.getSelectionModel();
    }
    
    function onDestroy() {
        me.un('render', onRender);
        me.un('beforedestroy', onDestroy);
        me = null;
        ui = null;
        ajax = null;
    }
    
    function onConnect() {
        var rs = sm.getSelected();
        
        if (!rs) {
            Ext.Msg.show({
                title: TCode.CWireless.Words.warning,
                msg: TCode.CWireless.Words.warn_msg,
                buttons: Ext.Msg.OK
            });
            return;
        }
        
        if (rs.data.keys === '--') {
            // no passwd
            ajax.dconnect_to_AP(rs.data.essid, '', rs.data.ap_hwaddr);
            showConnecting();
        } else {
            Ext.Msg.show({
                title: TCode.CWireless.Words.passwd_title,
                msg: TCode.CWireless.Words.passwd_msg,
                prompt: true,
                buttons: Ext.Msg.OKCANCEL,
                fn: onConfirmPassword.bind(
                    me,
                    rs.data.essid,
                    rs.data.keys,
                    rs.data.ap_hwaddr
                )
            });
        }
        
        rs = null;
    }
    
    function getCheckConnectResult(data) {
        if (data.state === '9') {
            cwirelessMk.hide();
            clearTimeout(CC);
            Ext.Msg.show({
                title: TCode.CWireless.Words.connect_msg_title,
                msg: TCode.CWireless.Words.connect_ok,
                buttons: Ext.Msg.OK
            });
            return;
        }
        
        if (data.state === '99') {
            cwirelessMk.hide();
            clearTimeout(CC);
            Ext.Msg.show({
                title: TCode.CWireless.Words.connect_msg_title,
                msg: TCode.CWireless.Words.connect_fail,
                buttons: Ext.Msg.OK
            });
            return;
        }
        
    }
    
    function checkConnect() {
        ajax.check_connect(getCheckConnectResult);
        CC = setTimeout(checkConnect, 5000);
    }
    
    function showConnecting() {
            cwirelessMk = new Ext.LoadMask(main_cwireless, {  
                msg: TCode.CWireless.Words.connecting,  
                removeMask  : true
            });  
            cwirelessMk .show();
        setTimeout(checkConnect, 5000);
    }
    
    function onConfirmPassword(essid, keys, ap_hwaddr, answer, password) {
        if (answer === 'ok' && password !== '') {
            // TODO: check password format for encryption type
            ajax.dconnect_to_AP(essid, password, ap_hwaddr);
//            me.fireEvent('ap_connecting');
            showConnecting();
        }
        essid = null;
        ap_hwaddr = null;
        answer = null;
        password = null;
    }
    
    function onToolbarRender(ct) {
        ui[ct.cname] = ct;
    }
    
    function onScanButtonEvent() {
        store.load();
    }
}
Ext.extend(TCode.CWireless.APList, Ext.grid.GridPanel);
Ext.reg('TCode.CWireless.APList', TCode.CWireless.APList);

TCode.CWireless.LabelField = function (c) {
    var me = this;
    
    Ext.util.CSS.createStyleSheet([
        '.cwireless-label {',
            'padding: 3px 0px 0px 22px;',
        '}'
    ].join(''));
    
    c = c || {};
    Ext.apply(c, {
        autoEl: {
            html: c.value || '&nbsp;'
        }
    });
    
    me.onRender = function(ct, position){
        Ext.form.Field.superclass.onRender.call(this, ct, position);
        
        if(!this.el){
            var cfg = this.getAutoCreate();
            if(!cfg.name){
                cfg.name = this.name || this.id;
            }
            this.el = ct.createChild(cfg, position);
        }
        
        if(this.readOnly){
            this.el.dom.readOnly = true;
        }
        
        if(this.tabIndex !== undefined){
            this.el.dom.setAttribute('tabIndex', this.tabIndex);
        }
        
        this.el.addClass('cwireless-label');
    }
    
    me.initValue = function () {
    }
    
    me.setValue = function (val) {
        me.el.dom.innerHTML = val;
    }
    
    TCode.CWireless.LabelField.superclass.constructor.call(me, c);
}
Ext.extend(TCode.CWireless.LabelField, Ext.form.Field);
Ext.reg('TCode.CWireless.LabelField', TCode.CWireless.LabelField);

TCode.CWireless.APStatus = function (c) {
    var me = this,
        ui = {},
        ajax = c.ajax;
    
    c = Ext.apply(c || {}, {
        frame: false,
        layout: 'anchor',
        bodyStyle: 'padding: 5px;',
        defaults: {
            anchor: '100% 40%',
            labelAlign: 'right',
            labelWidth: 100,
            defaults: {
                listeners: {
                    render: onComponentRender
                }
            }
        },
        items: [
            {
                id: 'wifi_information',
                xtype: 'fieldset',
                title: TCode.CWireless.Words.title_wifi_info,
                items: [
                    {
                        xtype: 'TCode.CWireless.LabelField',
                        cname: 'status',
                        fieldLabel: TCode.CWireless.Words.wifi_state,
                        value: TCode.CWireless.Words.detecting
                    },
                    {
                        xtype: 'TCode.CWireless.LabelField',
                        cname: 'ssid',
                        fieldLabel: TCode.CWireless.Words.ssid
                    },
                    {
                        xtype: 'TCode.CWireless.LabelField',
                        cname: 'host',
                        fieldLabel: TCode.CWireless.Words.wifi_ip
                    },
                    {
                        xtype: 'TCode.CWireless.LabelField',
                        cname: 'ap_host',
                        fieldLabel: TCode.CWireless.Words.ap_ip
                    },
                    {
                        xtype: 'button',
                        cname: 'disconnect_btn',
                        style: 'padding: 10px 100px;',
                        text: TCode.CWireless.Words.disconnect,
                        hidden: true,
                        handler: onDisconnect
                    },
                    {
                        xtype: 'label',
                        text: TCode.CWireless.Words.disconnecting,
                        style: 'padding: 10px 100px;',
                        cname: 'discon_lb',
                        hidden: true
                    }
                ]
            },
            {
                xtype: 'fieldset',
                title: TCode.CWireless.Words.title_adapter_info,
                items: [
                    {
                        xtype: 'TCode.CWireless.LabelField',
                        cname: 'type',
                        fieldLabel: TCode.CWireless.Words.adapter_proto
                        
                    },
                    {
                        xtype: 'TCode.CWireless.LabelField',
                        cname: 'mac_address',
                        fieldLabel: TCode.CWireless.Words.adapter_mac
                    }
                ]
            }
        ]
    });
    
    TCode.CWireless.APStatus.superclass.constructor.call(me, c);

    me.on('render', onStatusRender);
    me.on('beforedestroy', onDestroy);
    
    function onDestroy() {
        me.un('render', onStatusRender);
        me.nn('beforedestroy', onDestroy);
        me = null;
        ui = null;
        ajax = null;
    }
    
    function onStatusRender() {
        ajax.get_device_info(onGetDevInfo);
        if (TCode.desktop.Group.page === 'cwireless') {
            setTimeout(onStatusRender, 10000);
        }
    }
    
    function onDisconnect() {
        ajax.disconnect();
        ui['discon_lb'].show();
        setTimeout(onStatusRender, 10000);
    }
    
    function onComponentRender(ct) {
        if (ct && ct.cname) {
            ui[ct.cname] = ct;
        }
    }
    
    function onGetDevInfo(data) {
        if (data.state === 'connected'){
            ui['status'].setValue(TCode.CWireless.Words.connected);  //Multi Languge?
            ui['disconnect_btn'].show();
            ui['disconnect_btn'].enable();
        }else{
            ui['status'].setValue(TCode.CWireless.Words.disconnected);
            ui['discon_lb'].hide();
            ui['disconnect_btn'].hide();
        };
        
        if (data.essid != ''){
            ui['ssid'].setValue(data.essid);  //Multi Languge?
        }else{
            ui['ssid'].setValue('N/A');
        };
        
        ui['mac_address'].setValue(data.dev_hwaddr);
        ui['host'].setValue(data.ipv4);
        ui['ap_host'].setValue(data.apip);
        ui['type'].setValue(data.type);
    }

    me.startMonitor = function () {
        //console.info('我要開始監測了');
    }
}
Ext.extend(TCode.CWireless.APStatus, Ext.Panel);
Ext.reg('TCode.CWireless.APStatus', TCode.CWireless.APStatus);


TCode.CWireless.Container = function (c) {
    var me = this,
        ajax = new TCode.ux.Ajax('setcwireless', <{$METHODS}>);
    var ap = {};
    
    c = Ext.apply(c || {}, {
        frame: false,
	id: 'main_cwireless',
        border: true,
        layout: 'column',
        defaults: {
            style: 'float: left;',
            ajax: ajax,
            height: 540
        },
        items: [
            {
                cname: 'status',
                xtype: 'TCode.CWireless.APStatus',
                columnWidth: 0.4,
                listeners: {
                    render: onComponentRender
                }
            },
            {
                cname: 'list',
                xtype: 'TCode.CWireless.APList',
                columnWidth: 0.6,
                listeners: {
                    render: onComponentRender,
                    ap_connecting: onApConnecting
                }
            }
        ]
    });
    
    TCode.CWireless.Container.superclass.constructor.call(me, c);
    
    me.on('beforedestroy', onDestroyContainer);
    
    
    
    function onComponentRender(ct) {
        ap[ct.cname] = ct;
    }
    
    function onDestroyContainer() {
        me.un('beforedestroy', onDestroyContainer);
        ajax.abort();
        ajax = null;
        delete TCode.CWireless;
    }
    
    function onApConnecting() {
        ap.status.startMonitor();
    }
}
Ext.extend(TCode.CWireless.Container, Ext.Panel);
Ext.reg('TCode.CWireless.Container', TCode.CWireless.Container);

Ext.onReady(function () {
    TCode.desktop.Group.add({
        xtype: 'TCode.CWireless.Container'
    });

});

</script>
