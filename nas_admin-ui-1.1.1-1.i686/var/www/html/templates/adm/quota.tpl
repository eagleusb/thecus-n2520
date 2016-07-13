<div id="DomQuota"/>
<script type="text/javascript">

if(Ext.isIE){
  win_height = 450;
  desc_height = 90;
}else{
  win_height = 460;
  desc_height = 100;
} 

Ext.ns('TCode.Quota');

WORDS = Ext.decode('<{$words}>');

Ext.apply(WORDS, {
    
});

GWORDS = Ext.decode('<{$gwords}>');

TCode.Quota.Configure = Ext.decode('<{$configure}>');

/**
 * @namespace TCode.Quota
 * @extends Ext.FormPanel
 */
TCode.Quota.Service = function() {
    var self = this;
    var container;
    var confirmChange = true;
    var quotaEnabled = TCode.Quota.Configure.quotaEnabled == '1';
    
    var config = {
        id: 'QuotaService',
        frame: false,
        autoWidth: 'true',
        border: false,
        items: [
            {
                xtype: 'radiogroup',
                id: 'QuotaServiceEnable',
                fieldLabel: WORDS.usr_quota,
                labelStyle: 'width:25%',
                width: 350,
                items: [
                    {
                        boxLabel: '<{$gwords.enable}>',
                        name: 'QuotaServiceEnable',
                        inputValue: '1',
                        checked: quotaEnabled
                    },
                    {
                        boxLabel: '<{$gwords.disable}>',
                        name: 'QuotaServiceEnable',
                        inputValue: '0',
                        checked: !quotaEnabled
                    }
                ],
                listeners: {
                    change: change
                }
            }
        ],
        listeners: {
            render: render
        }
    }
    
    function change(group, newValue, oldValue) {
        if( confirmChange ) {
            Ext.Msg.show({
                title: WORDS.usr_quota,
                closable: false,
                msg: WORDS.confirm_reboot,
                buttons: Ext.Msg.YESNO,
                minWidth: 300,
                scope: self,
                fn: changeConfirm
            });
            confirmChange = false;
        }
    }
    
    function changeConfirm(btn) {
        var enabled = self.items.get(0).getValue();
        if( btn == 'yes' ) {
            container.makeAjax('set', 'setService', enabled);
        } else {
            self.items.get(0).setValue(quotaEnabled);
        }
        confirmChange = true;
    }
    
    function render() {
        container = Ext.getCmp('QuotaContainer');
        makeAjax = container.makeAjax;
    }
    
    var makeAjax = Ext.emptyFn;
    
    TCode.Quota.Service.superclass.constructor.call(this, config);
};

Ext.extend(TCode.Quota.Service, Ext.FormPanel);


/**
 * @namespace TCode.Quota
 * @extends Ext.grid.GridPanel
 */
TCode.Quota.SyncPanel = function() {
    var self = this;
    
    var container;
    
    var data = TCode.Quota.Configure.RaidSync;
    
    var header = '<input id=DomSelectAll type="checkbox" onclick="Ext.getCmp(\'QuotaSyncPanel\').selectAll();">';
    
    var config = {
        id: 'QuotaSyncPanel',
        title: WORDS.synchronize,
        bodyStyle: 'padding: 0px',
        frame: true,
        store: new Ext.data.JsonStore({
            fields: [ 'type', 'name', 'supp', 'sync', 'fs', 'estimation' ],
            data: data
        }),
        columns: [
            {
                header: header,
                dataIndex: 'sync',
                sortable: false,
                width: 30,
                menuDisabled: true,
                renderer: syncColumnRender1
            },
            { 
                header: WORDS.volume,
                dataIndex: 'name',
                sortable: false,
                menuDisabled: true
            },
            { 
                header: WORDS.filesystem,
                dataIndex: 'fs',
                sortable: false,
                menuDisabled: true
            },
            {
                header: WORDS.synchronized,
                dataIndex: 'sync',
                width: 100,
                sortable: true,
                menuDisabled: true,
                renderer: syncColumnRender2
            },
            {
                header: WORDS.estimation,
                dataIndex: 'estimation',
                width: 250,
                sortable: true,
                menuDisabled: true,
                renderer: estimationColumnRender
            }
        ],
        buttons: [
            {
                id: 'QuotaSyncButton',
                text: WORDS.sync,
                disabled: true,
                scope: self,
                handler: syncConfirm
            }
        ],
        listeners: {
            render: render
        }
    }
    
    function syncColumnRender1(value, metadata, record, rowIndex, colIndex, store) {
        if( !record.data['supp'] ) {
            return;
        }
        
        var id = 'QuotaSyncPanelCheck' + rowIndex;
        if( !record.data['sync'] ) {
            Ext.getCmp('QuotaSyncButton').setDisabled(false);
            return '<input id=' + id + ' type="checkbox" checked onclick="Ext.getCmp(\'QuotaSyncPanel\').selectCheck();">';
        } else {
            return '<input id=' + id + ' type="checkbox" onclick="Ext.getCmp(\'QuotaSyncPanel\').selectCheck();">';
        }
    }
    
    function syncColumnRender2(value, metadata, record, rowIndex, colIndex, store) {
        if( record.data['supp'] == true ) {
            return record.data['sync'] ? WORDS.finished : WORDS.never_sync;
        } else {
            return WORDS.unsupported;
        }
    }
    
    function estimationColumnRender(value, metadata, record, rowIndex, colIndex, store) {
        if( record.data['estimation'] == -1 ) {
            return WORDS.unsupported;
        }
        
        if( record.data['estimation'] == 0 ) {
            return WORDS.depend;
        }
        
        return record.data['estimation'];
    }
    
    function syncConfirm() {
        var len = self.store.totalLength;
        var confirm = false;
        
        for( var i = 0 ; i < len ; ++i ) {
            var box = Ext.get('QuotaSyncPanelCheck' + i);
            if( box && box.dom.checked == true ) {
                confirm = box.dom.checked;
                break;
            }
        }
        
        if( confirm == true ) {
            Ext.Msg.show({
                title: WORDS.usr_quota,
                closable: false,
                modal: false,
                msg: WORDS.sync_help,
                minWidth: 300,
                buttons: Ext.Msg.YESNO,
                fn: checkConfirm
            });
        }
    }
    
    function checkConfirm(btn) {
        if( btn == 'yes' ) {
            self.buttons[0].setDisabled(true);
            
            Ext.get('DomSelectAll').dom.checked = false;
            
            var store = self.store;
            var len = store.totalLength;
            var conf = [];
            for( var i = 0 ; i < len ; ++i ) {
                var box = Ext.get('QuotaSyncPanelCheck' + i);
                if( box && box.dom.checked ) {
                    box.dom.checked = false;
                    var record = store.getAt(i);
                    var index = conf.length;
                    conf[index] = {
                        'type': record.get('type'),
                        'name': record.get('name')
                    }
                }
            }
            container.setRefresh(true);
            makeAjax('set', 'setSync', conf);
        } else {
            makeAjax('set', 'setPrompt', false);
        }
    }
    self.checkConfirm = checkConfirm;
    
    function selectAll(force) {
        var checked = Ext.get('DomSelectAll').dom.checked;
        if( force == true ) {
            checked = true;
        }
        var len = self.store.totalLength;
        for( var i = 0 ; i < len ; ++i ) {
            var box = Ext.get('QuotaSyncPanelCheck' + i);
            if( box ) {
                box.dom.checked = checked;
            }
        }
        
        if( checked ) {
            self.buttons[0].setDisabled(false);
        } else{
            self.buttons[0].setDisabled(true);
        }
    }
    self.selectAll = selectAll;
    
    function selectCheck() {
        var checked = null;
        var len = self.store.totalLength;
        
        self.buttons[0].setDisabled(true);
        for( var i = 0 ; i < len ; ++i ) {
            var box = Ext.get('QuotaSyncPanelCheck' + i);
            if( box ) {
                if( box.dom.checked == true ) {
                    self.buttons[0].setDisabled(false);
                    break;
                }
            }
        }
        
        for( var i = 0 ; i < len ; ++i ) {
            var box = Ext.get('QuotaSyncPanelCheck' + i);
            if( box ) {
                if( checked == null ) {
                    checked = box.dom.checked;
                } else {
                    if( checked != box.dom.checked ) {
                        return;
                    }
                }
            }
        }
        
        Ext.get('DomSelectAll').dom.checked = checked;
    }
    self.selectCheck = selectCheck;
    
    var makeAjax = Ext.emptyFn;
    
    function applySearch() {
    }
    self.applySearch = applySearch;
    
    function update(data) {
        self.store.loadData(data);
    }
    self.update = update;
    
    function render() {
        container = Ext.getCmp('QuotaContainer');
        makeAjax = container.makeAjax;
    }
    
    TCode.Quota.SyncPanel.superclass.constructor.call(self, config);
};

Ext.extend(TCode.Quota.SyncPanel, Ext.grid.GridPanel);

/**
 * @namespace TCode.Quota
 * @extends Ext.Panel
 */
TCode.Quota.User = function() {
    var self = this;
    
    var container;
    var ui;
    var isSave = false;
    
    var config = {
        layout: 'column',
        bodyStyle: 'padding: 0px',
        frame: true,
        items: [
            {
                xtype: 'editorgrid',
                bodyStyle: 'padding: 0px',
                frame: true,
                autoscroll: true,
                trackMouseOver: true,
                disableSelection: false,
                loadMask: true,
                clicksToEdit: 1,
                columnWidth: .5,
                height: 355,
                store: new Ext.data.JsonStore({
                    fields: ['name', 'quotasize']
                }),
                columns: [
                    {
                        header: '<{$gwords.name}>',
                        dataIndex: 'name',
                        width: 150,
                        sortable: true,
                        menuDisabled: true
                    },
                    {
                        header: '<span style="font-weight: bold" >'+WORDS.quota+'(GB)</span>',
                        dataIndex: 'quotasize',
                        width: 120,
                        sortable: true,
                        menuDisabled: true,
                        renderer: userRenderer,
                        editor: new Ext.form.NumberField({
                            allowBlank: false,
                            allowNegative: false,
                            allowDecimals:false,
                            maxValue: 1048576, /* 1024 TB */
                            baseChars: '0123456789',
                            validationDelay: 1,
                            vtype: 'alphanum'
                        })
                    }
                ],
                tbar: [
                    {
                        xtype: 'textfield',
                        fieldLabel: '',
                        maxLength: 150,
                        hideLabel: true
                    },
                    {
                        text: '<{$gwords.search}>',
                        iconCls: 'option',
                        scope: self,
                        handler: self.applySearch
                    }
                ],
                buttons: [
                    {
                        text: '<{$gwords.apply}>',
                        scope: self,
                        handler: self.applyChange
                    }
                ],
                listeners: {
                    rowclick: self.rowClick
                }
            },
            {
                xtype: 'grid',
                bodyStyle: 'padding: 0px',
                frame: true,
                autoscroll: true,
                trackMouseOver: true,
                disableSelection: true,
                loadMask: true,
                columnWidth: .5,
                height: 355,
                store: new Ext.data.JsonStore({
                    fields: ['name', 'fs', 'quotalimit', 'quotasize']
                }),
                columns: [
                    {
                        header: WORDS.volume,
                        dataIndex: 'name',
                        width: 60,
                        sortable: true,
                        menuDisabled: true
                    },
                    { 
                        header: WORDS.filesystem,
                        dataIndex: 'fs',
                        width: 60,
                        sortable: false,
                        menuDisabled: true
                    },
                    {
                        header: WORDS.quota+' (GB)',
                        dataIndex: 'quotalimit',
                        width: 90,
                        sortable: true,
                        menuDisabled: true,
                        renderer: limitRenderer
                    },
                    {
                        header: WORDS.quotasize+' (GB)',
                        dataIndex: 'quotasize',
                        width: 90,
                        sortable: true,
                        menuDisabled: true,
                        renderer: sizeRenderer
                    }
                ],
                tbar: [
                    {
                        hideMode: 'visibility',
                        hidden: true
                    }
                ],
                buttons: [
                    {
                        hideMode: 'visibility',
                        hidden: true
                    }
                ]
            }
        ],
        listeners: {
            render: render
        }
    }
    
    Ext.apply(config, arguments[0]);
    
    function userRenderer(value, metadata, record, rowIndex, colIndex, store) {
        var integer = Math.floor(value);
        var decimal = (value - integer) != 0;
        
        if( decimal ) {
            return value.toFixed(2);
        }
        
        return value;
    }
    
    function limitRenderer(value, metadata, record, rowIndex, colIndex, store) {
        var limit = record.get('quotalimit');
        
        if( value == 'Unsupported' ) {
            return value;
        }
        
        var integer = Math.floor(value);
        var decimal = (value - integer) != 0;
        
        decimal === true ? value = value.toFixed(2) : value ;
        
        return value;
    }
    
    function sizeRenderer(value, metadata, record, rowIndex, colIndex, store) {
        var limit = record.get('quotalimit');
        
        if( value == '' ) {
            return value;
        }
        
        var integer = Math.floor(value);
        var decimal = (value - integer) != 0;
        
        ( value >= limit && limit != 0 ) ? style = '<div style="color:red">{0}</div>' : style = '{0}';
        decimal === true ? value = value.toFixed(2) : value ;
        
        return String.format(style, value);
    }
    
    function render() {
        container = Ext.getCmp('QuotaContainer');
        makeAjax = container.makeAjax;
        
        ui = {
            userGrid: self.items.get(0),
            infoGrid: self.items.get(1)
        }
    }
    
    function setUserInfo(data) {
        ui.infoGrid.store.rejectChanges();
        ui.infoGrid.store.removeAll();
        ui.infoGrid.store.loadData(data);
        
        if( isSave == true ) {
            Ext.Msg.show({
                title: WORDS.usr_quota,
                msg: WORDS.quota_set,
                buttons: Ext.Msg.OK,
                minWidth: 300
            });
        }
        
        isSave = false;
    }
    self.setUserInfo = setUserInfo;
    
    function setUser(data) {
        ui.userGrid.store.rejectChanges();
        ui.userGrid.store.removeAll();
        ui.userGrid.store.loadData(data);
    }
    self.setUser = setUser;
    
    function applyUserModify() {
        isSave = true;
        
        ui.userGrid.store.commitChanges();
        
        var record = ui.userGrid.store.getAt(self.rowIndex);
        self.limit = record.data['quotasize'];
        
        if( self instanceof TCode.Quota.LocalUser ) {
            makeAjax('get', 'getLocalUserInfo', record.data['name']);
        } else {
            makeAjax('get', 'getAdUserInfo', record.data['name']);
        }
    }
    self.applyUserModify = applyUserModify;
    
    self.makeAjax = Ext.emptyFn;
    
    TCode.Quota.User.superclass.constructor.call(self, config);
};

Ext.extend(TCode.Quota.User, Ext.Panel);

/**
 * @namespace TCode.Quota
 * @extends TCode.Quota.User
 */
TCode.Quota.LocalUser = function() {
    var self = this;
    
    var config = {
        id: 'QuotaLocalUser',
        title: WORDS.localUser
    }
    
    function rowClick(grid, rowIndex, e) {
        var userGrid = self.items.get(0);
        var infoGrid = self.items.get(1);
        
        infoGrid.store.removeAll();
        self.rowIndex = rowIndex;
        var record = userGrid.store.getAt(rowIndex);
        self.limit = record.data['quotasize'];
        
        makeAjax('get', 'getLocalUserInfo', record.data['name']);
    }
    self.rowClick = rowClick;
    
    function applySearch() {
        var userGrid = self.items.get(0);
        var infoGrid = self.items.get(1);
        var name = userGrid.topToolbar.items.get(0).getValue();
        userGrid.store.removeAll();
        infoGrid.store.removeAll();
        
        makeAjax('get', 'getLocalUser', name);
    }
    self.applySearch = applySearch;
    
    function applyChange() {
        var store = self.items.get(0).store;
        var records = store.getModifiedRecords();
        var modifies = [];
        for( i = 0 ; i < records.length ; i++ ) {
            modifies.push(records[i].data);
        }
        
        makeAjax('set', 'setLocalUserQuota', modifies);
    }
    self.applyChange = applyChange;
    
    TCode.Quota.LocalUser.superclass.constructor.call(self, config);
};

Ext.extend(TCode.Quota.LocalUser, TCode.Quota.User);

/**
 * @namespace TCode.Quota
 * @extends TCode.Quota.User
 */
TCode.Quota.AdUser = function() {
    var self = this;
    
    var config = {
        id: 'QuotaAdUser',
        title: WORDS.adUser
    }
    
    function adUserResync() {
        makeAjax('get', 'adUserResync');
    }
    self.adUserResync = adUserResync;
    
    function rowClick(grid, rowIndex, e) {
        var userGrid = self.items.get(0);
        var infoGrid = self.items.get(1);
        
        infoGrid.store.removeAll();
        self.rowIndex = rowIndex;
        var record = userGrid.store.getAt(rowIndex);
        self.limit = record.data['quotasize'];
        
        makeAjax('get', 'getAdUserInfo', record.data['name']);
    }
    self.rowClick = rowClick;
    
    function applySearch() {
        var userGrid = self.items.get(0);
        var infoGrid = self.items.get(1);
        var name = userGrid.topToolbar.items.get(0).getValue();
        userGrid.store.removeAll();
        infoGrid.store.removeAll();
        
        makeAjax('get', 'getAdUser', name);
    }
    self.applySearch = applySearch;
    
    function applyChange() {
        var store = self.items.get(0).store;
        var records = store.getModifiedRecords();
        var modifies = [];
        for( i = 0 ; i < records.length ; i++ ) {
            modifies.push(records[i].data);
        }
        
        makeAjax('set', 'setAdUserQuota', modifies);
    }
    self.applyChange = applyChange;
    
    TCode.Quota.AdUser.superclass.constructor.call(self, config);
};

Ext.extend(TCode.Quota.AdUser, TCode.Quota.User);

/**
 * @namespace TCode.Quota
 * @extends Ext.TabPanel
 */
TCode.Quota.TabPanel = function() {
    var self = this;
    
    var unserviced = (TCode.Quota.Configure.quotaEnabled == '0');
    
    var items = [
        new TCode.Quota.SyncPanel(),
        new TCode.Quota.LocalUser()
    ]
    
    if( TCode.Quota.Configure.ad_show == '1' ) {
        items.push( new TCode.Quota.AdUser() );
    }
    
    var config = {
        id: 'QuotaTabPanel',
        autoTabs: true,
        activeTab: 0,
        border: true,
        disabled: unserviced,
        bodyStyle: 'padding: 0px;',
        style: 'z-index: 400',
        height : 400,
        layoutOnTabChange: true,
        autoScroll:true,
        frame: false,
        border: false,
        items: items,
        listeners: {
            tabchange: tabchange
        }
    }
    
    function tabchange() {
        var panel = self.activeTab;
        if( panel.applySearch )
            panel.applySearch();
    }
    
    TCode.Quota.TabPanel.superclass.constructor.call( self, config );
}

Ext.extend( TCode.Quota.TabPanel, Ext.TabPanel );

/**
 * @namespace TCode.Quota
 * @extends Ext.Panel
 */
TCode.Quota.Container = function() {
    var self = this;
    
    var ui;
    
    var refresh = false;
    var runner = new Ext.util.TaskRunner();
    
    var action = '';
    
    var updater = Ext.get('content').getUpdateManager();
    
    var desc = String.format(
        '<li>{0}</li><li>{1}</li>',
        WORDS.quota_hint,
        WORDS.quota_hint2
    );
    
    var desc_style = 'list-style: disc;margin-left: 10px;padding-left: 10px;text-indent: 0px;';
    
    var config = {
        style: 'margin: 10px;',
        id: 'QuotaContainer',
        renderTo: 'DomQuota',
        items: [
            new TCode.Quota.Service(),
            new TCode.Quota.TabPanel(),
            new Ext.form.FieldSet({
                title: '<{$gwords.description}>',
                autoHeight: true,
                items: {
                    xtype: 'box',
                    autoEl: {
                        tag: 'ul',
                        style: desc_style,
                        html: desc
                    }
                }
            })
        ],
        listeners: {
            render: render,
            beforedestroy: beforedestroy
        }
    }
    
    var actions = {
        // Service
        serviceReboot: serviceReboot,
        serviceEnabled: serviceEnabled,
        serviceDisabled: serviceDisabled,
        // Status
        serviceUnSync: serviceUnSync,
        serviceSyncing: serviceSyncing,
        serviceCanceling: serviceCanceling,
        //Sync Panel
        raidSynchronize: raidSynchronize,
        // Local User Events
        localUser: localUser,
        localUserInfo: localUserInfo,
        localUserModified: localUserModified,
        // AD User Evnets
        adUser: adUser,
        adUserInfo: adUserInfo,
        adUserModified: adUserModified,
        adUserResynced: adUserResynced
    }
    
    function render() {
        updater.on('beforeupdate', self.destroy, self );
        
        ui = {
            service: Ext.getCmp('QuotaService'),
            tabpanel: Ext.getCmp('QuotaTabPanel'),
            sync: Ext.getCmp('QuotaSyncPanel'),
            local: Ext.getCmp('QuotaLocalUser'),
            ad: Ext.getCmp('QuotaAdUser')
        }
        
        var status = TCode.Quota.Configure.status;
        doFunction(status.action);
    }
    
    function beforedestroy() {
        runner.stopAll();
        Ext.Msg.hide();
        updater.un('beforeupdate', self.destroy, self );
    }
    
    function setRefresh(val) {
        refresh = val;
    }
    self.setRefresh = setRefresh;
    
    function serviceEnabled() {
        ui.tabpanel.setDisabled(false);
    }
    
    function serviceDisabled() {
        ui.tabpanel.setDisabled(true);
    }
    
    function serviceReboot() {
        self.items.get(0).setDisabled(true);
        self.items.get(1).setDisabled(true);
        Ext.Msg.show({
            title: WORDS.usr_quota,
            closable: false,
            modal: false,
            msg: WORDS.reboot,
            buttons: Ext.Msg.OK,
            minWidth: 300,
            fn: reboot
        });
    }
    
    function serviceUnSync() {
        self.items.get(0).setDisabled(true);
        self.items.get(1).setDisabled(true);
        Ext.Msg.show({
            title: WORDS.usr_quota,
            closable: false,
            modal: false,
            msg: WORDS.sync_help,
            minWidth: 300,
            buttons: Ext.Msg.YESNO,
            fn: serviceNoSync
        });
    }
    
    function serviceNoSync(btn) {
        if( btn == 'yes' ) {
            var obj = Ext.getCmp('QuotaSyncPanel');
            obj.selectCheck();
            obj.checkConfirm('yes');
            
            refresh = true;
        } else {
            makeAjax('set', 'setPrompt', false);
            self.items.get(0).setDisabled(false);
            self.items.get(1).setDisabled(false);
        }
    }
    
    function serviceSyncing() {
        self.items.get(0).setDisabled(true);
        self.items.get(1).setDisabled(true);
        
        Ext.Msg.show({
            title: WORDS.usr_quota,
            closable: false,
            modal: false,
            msg: WORDS.cnaceling_help,
            buttons: Ext.Msg.CANCEL,
            minWidth: 300,
            wait: true,
            waitConfig: {
                interval: 500
            },
            fn: serviceSyncCancel
        });
        
        runner.stopAll();
        
        var task = {
            run: function(){
                makeAjax('get', 'getAction');
            },
            interval: 3000
        }
        
        runner.start(task);
    }
    
    function serviceSyncCancel() {
        makeAjax('set', 'serviceSyncCancel');
    }
    
    function serviceCanceling() {
        self.items.get(0).setDisabled(true);
        self.items.get(1).setDisabled(true);
        Ext.Msg.show({
            title: WORDS.usr_quota,
            closable: false,
            modal: false,
            msg: WORDS.canceling,
            wait: true,
            waitConfig: {
                interval: 500
            }
        });
        
        runner.stopAll();
        
        var task = {
            run: function(){
                makeAjax('get', 'getAction');
            },
            interval: 3000
        }
        
        runner.start(task);
    }
    
    function raidSynchronize(data) {
        ui.sync.update(data);
    }
    
    function localUserInfo(data) {
        ui.local.setUserInfo(data);
        action = '';
    }
    
    function localUser(data) {
        ui.local.setUser(data);
        action = '';
    }
    
    function localUserModified() {
        ui.local.applyUserModify();
        action = '';
    }
    
    function adUserInfo(data) {
        ui.ad.setUserInfo(data);
        action = '';
    }
    
    function adUser(data) {
        ui.ad.setUser(data);
        action = '';
    }
    
    function adUserModified() {
        ui.ad.applyUserModify();
        action = '';
    }
    
    function adUserResynced(data) {
        ui.ad.updateUserList(data);
        action = '';
    }
    
    function reboot() {
        setCurrentPage('reboot');
        processUpdater('getmain.php', 'fun=reboot');
    }
    
    function ajaxSuccess(response, options) {
        response = Ext.util.JSON.decode(response.responseText);
        if( typeof response.action == 'string' )
            doFunction(response.action, response.result);
    }
    
    function doFunction(act, result) {
        var fn = actions[act];
        if( fn ) {
            if( action != act ) {
                action = act;
                Ext.Msg.hide();
                fn( result );
            }
        } else {
            Ext.Msg.hide();
            runner.stopAll();
            
            var unserviced;
            
            if( typeof obj == 'object' ) {
                unserviced = (obj.getValue() == '0');
            } else {
                unserviced = (TCode.Quota.Configure.quotaEnabled == '0');
            }
            
            self.items.get(0).setDisabled(false);
            self.items.get(1).setDisabled(unserviced);
            
            action = '';
            if( refresh == true ) {
                makeAjax('get', 'getSync');
                refresh = false;
            }
        }
    }
    
    function makeAjax(url, action, params) {
        fun = ( url == 'set' ) ? 'setquota' : 'quota';
        url = ( url == 'set' ) ? 'setmain.php' : 'getmain.php';
        Ext.Ajax.request({
            url: url,
            params: {
                fun: fun,
                action: action,
                scope: self,
                params: Ext.encode(params)
            },
            success: ajaxSuccess
        });
    }
    
    self.makeAjax = makeAjax;
    
    TCode.Quota.Container.superclass.constructor.call(self, config);
}

Ext.extend(TCode.Quota.Container, Ext.Panel);

Ext.onReady(function(){
    Ext.QuickTips.init();
    new TCode.Quota.Container();
});

</script>
