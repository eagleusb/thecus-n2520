<div id='Domupnp_port_management'/> 

<script type='text/javascript'>
/**
 * @look up the floder infomation(filename, size, fileNumber)
 * @kenny wu 
 * @Frank Yu 
 */

/**
 *debug modle: the invented set
 */

var status= <{$status}>;

Ext.namespace('TCode.upnp_port_management');

WORDS= <{$words}>;

TCode.upnp_port_management.Information= <{$information}>;
TCode.upnp_port_management.Mapping= <{$mapping}>;

/**
 * @namespace TCode.upnp_port_management
 * @extends Ext.Panel
 * @class InfoPanel
 */
TCode.upnp_port_management.InfoPanel= function(){
    var self= this;
    
    var fakeLabel= 'border: 0px; background: transparent;';
    var fakeLabelWidth= 400;
    
    var config= {
        title: WORDS.information,
        autoHeight: true,
        labelWidth: 150,
        //width: 700,
        items: [
            {
                xtype: 'textfield',
                fieldLabel: WORDS.friendly_name,
                readOnly: true,
                style: fakeLabel,
                width: fakeLabelWidth
            },
            {
                xtype: 'textfield',
                fieldLabel: WORDS.manufacturer_URL,
                readOnly: true,
                style: fakeLabel,
                width: fakeLabelWidth
            },
            {
                xtype: 'textfield',
                fieldLabel: WORDS.model_number,
                readOnly: true,
                style: fakeLabel,
                width: fakeLabelWidth
            },
            {
                xtype: 'textfield',
                fieldLabel: WORDS.model_URL,
                readOnly: true,
                style: fakeLabel,
                width: fakeLabelWidth
            },
            {
                xtype: 'textfield',
                fieldLabel: WORDS.model_description,
                readOnly: true,
                style: fakeLabel,
                width: fakeLabelWidth
            },
            {
                xtype: 'textfield',
                fieldLabel: WORDS.UDN,
                readOnly: true,
                style: fakeLabel,
                width: fakeLabelWidth
            }
        ]
    }
    
    /**
     * @public
     * @param {Array} data
     */
    function setInformation(data){
        var len= self.items.length;
        for(var i = 0 ; i < len ; ++i){
            var label = self.items.get(i);
            label.setValue(data[i] || '');
        }
    }
    this.setInformation = setInformation;
    
    TCode.upnp_port_management.InfoPanel.superclass.constructor.call(this, config);
}

Ext.extend(TCode.upnp_port_management.InfoPanel, Ext.form.FieldSet);

/**
 * @class ListPanel
 * @namespace TCode.upnp_port_management
 * @extends Ext.grid.GridPanel
 */
TCode.upnp_port_management.ListPanel= function(){
    var self= this;
    
    var protocol= [
        'TCP',
        'UDP',
        'TCP/UDP'
    ]
    
    var unprotocol= {
        'TCP': 1,
        'UDP': 2,
        'TCP/UDP': 3
    }
    
    var ajax= {
        url: null,
        params: {
            fun: null,
            action: null, 
            params: null
        },
        scope: self,
        success: success,
        failure: failure
    }
    
    var ajaxData;
    
    var config= {
        height:300,
        frame: true,
        title: WORDS.title,
        //width: 700,
        columns: [
            {
                header: WORDS.local_setting,
                hidden: true,
                menuDisabled: true,
                dataIndex: 'host'
            },
            {
                header: WORDS.port,
                dataIndex: 'port',
                menuDisabled: true
            },
            {
                header: WORDS.protocol,
                dataIndex: 'protocol',
                menuDisabled: true
            },
            {
                header: WORDS.description,
                dataIndex: 'description',
                menuDisabled: true
            },
            {
                header: 'status',
                dataIndex: 'status',
                menuDisabled: true
            }
        ],
        viewConfig: new Ext.grid.GroupingView({
            forceFit: true,
            groupTextTpl: String.format(
                '{[values.gvalue == true ? "{0}" : "{1}"]}',
                WORDS.local_setting,
                WORDS.none_localSetting
            )
        }),
        sm: new Ext.grid.RowSelectionModel({
            singleSelect: true
        }),
        store: new Ext.data.GroupingStore({
            reader: new Ext.data.ArrayReader(
                {
                    id: 0
                },
                [
                    {
                        name: 'host',
                        mapping: 1
                    },
                    {
                        name: 'ori',
                        mapping: 2
                    },
                    {
                        name: 'port',
                        mapping: 3
                    },
                    {
                        name: 'protocol',
                        mapping: 4
                    },
                    {
                        name: 'description',
                        mapping: 5
                    },
                    {
                        name: 'status',
                        mapping: 6
                    }
                ]
            ),
            sortInfo: {
                field: 'port',
                direction: "ASC"
            },
            groupField: 'host'
        }),
        tbar: [
            {
                id: 'tbarRefresh',
                text: WORDS.refresh,
                iconCls: 'refresh',
                handler: btnRefresh
            },
            {
                id: 'tbarAdd',
                text: WORDS.add_rule,
                disabled: true,
                iconCls: 'add',
                handler: btnAdd
            },
            {
                id: 'tbarModify',
                text: WORDS.modify_rule,
                disabled: true,
                iconCls: 'edit',
                handler: btnModify
            },
            '-',
            {
                id: 'tbarReset',
                text: 'Reset',
                iconCls: 'restore',
                disabled: false,
                handler: btnReset
            },
            '-',
            '->',
            {
                id: 'tbarRemove',
                text: WORDS.remove,
                disabled: true,
                iconCls: 'remove',
                handler: btnRemove
            }
        ],
        listeners: {
            render: render,
            cellclick: cellclick,
            celldblclick : celldblclick 
        }
    }
    
    this.addEvents({
        'eRuleAdd': true,
        'eRuleUpdate': true,
        'eRuleCancel': true,
        'infoUpdate': true
    });
    
    function render(){
        if(status != 1)Ext.getCmp('tbarAdd').setDisabled(false);
        if(status == 1)Ext.Msg.alert(WORDS.title,WORDS.noupnp);
    }
    
    function cellclick(){
        
        var selects_jugle = self.getSelections();
        
        if(selects_jugle[0].get('host') != 0){
            if(selects_jugle.length>0){
                Ext.getCmp('tbarRemove').setDisabled(false);
                Ext.getCmp('tbarModify').setDisabled(false);
            }else{
                Ext.getCmp('tbarModify').setDisabled(true);
                Ext.getCmp('tbarRemove').setDisabled(true);
            }
        }else{
            Ext.getCmp('tbarModify').setDisabled(true);
            Ext.getCmp('tbarRemove').setDisabled(true);
        }
        
        if(selects_jugle.length>1)Ext.getCmp('tbarModify').setDisabled(true);
    }
    
    function celldblclick(){
        var selects= self.getSelections();
        if(selects[0].get('host') != 0)btnModify();
    }
    
    function btnRefresh(){
        makeRequest('get', 'refresh' );
    }
    
    function btnReset(){
        makeRequest('get', 'reset' );
    }
    
    function btnAdd(){
        self.fireEvent('eRuleAdd');
        self.collapse();
    }
    
    function btnModify(){
        var selects= self.getSelections();

        var port= String(selects[0].get('port')).match(/([0-9]*)-?([0-9]*)/i);

        var rule= {
            'port': port,
            'proto': selects[0].get('protocol'),
            'desc': selects[0].get('description')
        };
        
        self.fireEvent('eRuleUpdate', rule);
        self.collapse();
    }
    
    function btnRemove(){
        confirm();
    }
    
    function confirm(){
        Ext.Msg.confirm(WORDS.title, "<{$gwords.confirm}>", function(btn){
            if(btn == 'yes'){
                self.store.commitChanges();
                var rs= self.selModel.getSelections();
                
                var data= [];
                for(var i= 0 ; i < rs.length ; ++i){
                    if(rs[i].get('host') == true){
                        if(rs[i].get('ori') != ''){
                            data.push([
                                rs[i].get('ori'),
                                rs[i].get('port'),
                                unprotocol[rs[i].get('protocol')],
                                rs[i].get('description')
                            ]);
                        }
                        rs[i].reject();
                        self.store.remove(rs[i]);
                    }
                }
                self.selModel.clearSelections();
                
                if(data.length > 0){
                    makeRequest('set', 'remove', Ext.encode(data));
                }
            }else{
            }
        })
    }
    
    function addRule(rule){
        self.expand();
    }
    this.addRule= addRule;

    function ModifyRule(rule){
        self.expand();
    }
    this.ModifyRule= ModifyRule;
    
    function ruleCancel(){
        self.expand();
    }
    this.ruleCancel= ruleCancel;

    function ruleAdd(rule){
        if( validateDuplicate(rule, -1)){
            self.expand();
            return;
        }
        
        ajaxData= [[
            '',
            rule.port[0],
            rule.proto,
            rule.desc
        ]]
        
        makeRequest('set', 'save', Ext.encode(ajaxData));

        self.expand();
    }
    this.ruleAdd= ruleAdd;

    function ruleUpdate(rule, backup){

        var rowID = self.store.find('port', backup.port[0]);

        if(validateDuplicate(rule, rowID)){
            self.expand();
        } else{

            if(String(rule.proto).match(/[0-9]/)){
                self.store.getAt(rowID).set('protocol', protocol[rule.proto - 1]);

            } else {
                self.store.getAt(rowID).set('protocol', rule.proto);
            }
            
            self.store.getAt(rowID).set('ori', backup.port[0]);
            self.store.getAt(rowID).set('port', rule.port[0]);
            self.store.getAt(rowID).set('description', rule.desc);
        }

        save();
        self.expand();
    }
    this.ruleUpdate= ruleUpdate;

    function success(response){
        mainMask.hide();
        var result = Ext.decode(response.responseText);

        Ext.getCmp('tbarModify').setDisabled(true);
        Ext.getCmp('tbarRemove').setDisabled(true);
        
        switch(result.status){
            case '1':
                Ext.Msg.alert(WORDS.title,WORDS.noupnp);
                self.fireEvent('infoUpdate', result.info);
                refreshData(result.data);
                Ext.getCmp('tbarAdd').setDisabled(true);
                break;
            
            case '2':
                switch(result.code){
                    case 'reset':
                        self.fireEvent('infoUpdate', result.info);
                        refreshData(result.data);
                        Ext.getCmp('tbarAdd').setDisabled(false);
                        break;
                    case 'refresh':
                        self.fireEvent('infoUpdate', result.info);
                        refreshData(result.data);
                        Ext.getCmp('tbarAdd').setDisabled(false);
                        break;
                    case 'save':

                        if( typeof(ajaxData) == 'object' &&  ajaxData != null){

                            self.store.add(new Ext.data.Record({
                                host: '1',
                                ori: ajaxData[0][1],
                                port: ajaxData[0][1],
                                protocol: protocol[ ajaxData[0][2] - 1 ],
                                description: ajaxData[0][3]
                                })
                            );
                            ajaxData= null;
                        }
                        break;
                    case 'remove':
                }
                break;
            
            case '3':
                Ext.Msg.alert(WORDS.title, WORDS.set_failure);
                break;
        }
    }
    
    function failure(response){
        var result= Ext.decode(response.responseText);
        Ext.Msg.alert(WORDS.title, WORDS.save_failure);
    }

    function makeRequest(api, action, params){
        var fun= (api == 'get' ? 'upnp_port_management' : 'setupnp_port_management');
        api= (api == 'get' ? 'getmain.php' : 'setmain.php');
        ajax.url= api;
        ajax.params.fun= fun;
        ajax.params.action= action;
        delete ajax.params.params;
        if(params)
            ajax.params.params= params;
        
        mainMask.show();
        Ext.Ajax.request(ajax);
    }

    //function refreshData(data){
    //    console.info(data);
    //    var _data= [];
    //    for(var i= 0 ; i < data.length ; ++i){
    //        _data.push([
    //            i,
    //            data[i][0],
    //            data[i][1],
    //            data[i][1],
    //            protocol[data[i][2] - 1],
    //            data[i][3]
    //        ]);
    //    }
    //    self.store.rejectChanges();
    //    self.store.removeAll();
    //    self.store.loadData(_data);
    //}
    //this.refreshData = refreshData;
    
    function save(){
        var rs= self.store.getModifiedRecords();
        var data= [];

        for(var i= 0 ; i < rs.length ; ++i){
            if(rs[i].get('host') == true){
                
                data.push([
                    String(rs[i].get('ori')),
                    rs[i].get('port'),
                    unprotocol[rs[i].get('protocol')],
                    rs[i].get('description')
                ]);
                
                rs[i].set('ori', rs[i].get('port'));
            }
        }
        
        self.store.commitChanges();

        if(data.length > 0){
            makeRequest('set', 'save', Ext.encode(data));
        }
    }

    function refreshData(data){
        var _data= [];
        for(var i= 0 ; i < data.length ; ++i){
            _data.push([
                i,
                data[i][0],
                data[i][1],
                data[i][1],
                protocol[data[i][2] - 1],
                data[i][3],
                data[i][4]
            ]);
        }
        self.store.rejectChanges();
        self.store.removeAll();
        self.store.loadData(_data);
    }
    this.refreshData= refreshData;
    
    function validateDuplicate(rule, index){
        var port1= rule.port;
        var duplicate= false;
        var len= self.store.data.length;
        
        for( var i= 0 ; i < len ; ++i ) {
            if(i != index){
                var record= self.store.getAt(i);
            
                var port2= String(record.data.port).match(/([0-9]*)-?([0-9]*)/i);
                port2[1]= Number(port2[1]);
                port2[2]= port2[2] == '' ? port2[1] : Number(port2[2]);
                if(port2[1] > port2[2]){
                    port2[1]^= port2[2];
                    port2[2]^= port2[1];
                    port2[1]^= port2[2];
                }
                if((port1[1] <= port2[2] && port1[1] >= port2[1]) || (port1[2] <= port2[2] && port1[2] >= port2[1])){
                    var msg = String.format(WORDS.overlap, port2[0], port1[0]);
                    Ext.Msg.alert(WORDS.title, msg);
                    return true;
                }
            }
        }
        
        return false;
    }
    
    TCode.upnp_port_management.ListPanel.superclass.constructor.call(this, config);
}

Ext.extend(TCode.upnp_port_management.ListPanel, Ext.grid.GridPanel);



/**
 * @namespace TCode.upnp_port_management
 * @extends Ext.Panel
 * @class EditorPanel
 */
TCode.upnp_port_management.EditorPanel= function(){
    var self= this;
    var ui;
    var action= '';
    var backup;
    
    var config= {
        layout: 'form',
        frame: true,
        //width: 700,
        collapsed: true,
        autoHeight: true,
        buttonAlign: 'left',
        items: [
            {
                xtype: 'textfield',
                fieldLabel: WORDS.begin,
                allowBlank: false,
                vtype: 'Port'
            },
            {
                xtype: 'textfield',
                fieldLabel: WORDS.end,
                allowBlank: false,
                vtype: 'Port'
            },
            {
                xtype: 'combo',
                mode: 'local',
                fieldLabel: WORDS.protocol,
                allowBlank: false,
                forceSelection: true,
                triggerAction: 'all',
                selectOnFocus: true,
                displayField: 'k',
                valueField: 'v',
                editable: false,
                value: 1,
                store: new Ext.data.SimpleStore({
                    fields: ['k', 'v'],
                    data: [
                        ['TCP', 1],
                        ['UDP', 2],
                        ['TCP/UDP', 3]
                    ]
                })
            },
            {
                xtype: 'textfield',
                fieldLabel: WORDS.description
            }
        ],
        buttons: [
            {
                text: WORDS.apply,
                handler: btnApply
            },
            {
                text: WORDS.cancel,
                handler: btnCancel
            }
        ],
        listeners: {
            render: render
        }
    }
    
    this.addEvents({
        'eRuleAdd': true,
        'eRuleUpdate': true,
        'eRuleCancel': true
    });
    
    function render(){
        ui= {
            'begin': self.items.get(0),
            'end': self.items.get(1),
            'proto': self.items.get(2),
            'desc': self.items.get(3)
        }
    }
    
    function validate(){
        for(var id in ui){
            var obj= ui[id];
            if(obj.validate() != true){
                Ext.Msg.show({
                    'title': WORDS.title,
                    'msg': WORDS.input_error,
                    'buttons': Ext.MessageBox.OK
                });
                return false;
            }
        }
        
        var begin= Number(ui.begin.getValue());
        var end= Number(ui.end.getValue());
        
        if(begin> end){
            begin^= end;
            end^= begin;
            begin^= end;
        }
        
        if((end - begin + 1) > 100){
            Ext.Msg.show({
                'title': WORDS.title,
                'msg': WORDS.port_range_over,
                'buttons': Ext.MessageBox.OK
            });
            return false;
        }
        
        return{
            'port': [
                begin + '-' + end,
                begin,
                end
            ],
            'proto': ui.proto.getValue(),
            'desc': ui.desc.getValue()
        }
    }
    
    function btnApply(){
        var rule= validate();
        if(rule == false){
            return;
        }
        self.collapse();
        if(action == 'add'){
            self.fireEvent('eRuleAdd', rule);
        } else {
            self.fireEvent('eRuleUpdate', rule, backup);
        }
    }
    
    function btnCancel(){
        self.collapse();
        self.fireEvent('eRuleCancel');
    }
    
    function ruleAdd(){
        action= 'add';
        with(ui){
            begin.setValue('80');
            end.setValue('80');
            proto.setValue(1);
            desc.setValue('');
        }
        self.expand();
    }
    this.ruleAdd= ruleAdd;
    
    function ruleUpdate(rule){
        action= 'update';
        backup= rule;
        Ext.applyIf(rule, {
            'port': [
                '',
                '',     // Port Begin
                ''      // Port End
            ],
            'proto': 1,
            'desc': ''
        });
        with(ui){
            begin.setValue(rule.port[1]);
            end.setValue(rule.port[2]);
            proto.setValue(rule.proto);
            desc.setValue(rule.desc);
        }
        
        self.expand();
    }
    this.ruleUpdate= ruleUpdate;
    
    TCode.upnp_port_management.EditorPanel.superclass.constructor.call(this, config);
}

Ext.extend(TCode.upnp_port_management.EditorPanel, Ext.Panel);

/**
 * @namespace TCode.upnp_port_management
 * @extends Ext.Panel
 * @class Container
 */
TCode.upnp_port_management.Container= function(){
    var self= this;
    
    var ui;
    
    var config= {
        renderTo: 'Domupnp_port_management',
        style: 'margin: 10px;',
        autoHeight: true,
        items: [
            new TCode.upnp_port_management.InfoPanel(),
            new TCode.upnp_port_management.ListPanel(),
            new TCode.upnp_port_management.EditorPanel()
        ],
        listeners: {
            render: render,
            beforedestroy: beforedestroy
        }
    }
    
    function render(){
        Ext.getCmp('content').getUpdater().on(
            'beforedestroy',
            self.destroy,
            self
        );
        
        ui= {
            Info: self.items.get(0),
            List: self.items.get(1),
            Editor: self.items.get(2)
        }
        
        with(ui){
            List.on('eRuleAdd', Editor.ruleAdd);
            List.on('eRuleUpdate', Editor.ruleUpdate);
            List.on('infoUpdate', Info.setInformation);
            Editor.on('eRuleAdd', List.ruleAdd);
            Editor.on('eRuleUpdate', List.ruleUpdate);
            Editor.on('eRuleCancel', List.ruleCancel);
            
            Info.setInformation(TCode.upnp_port_management.Information);
            List.refreshData(TCode.upnp_port_management.Mapping);
        }
    }
    
    function beforedestroy(){
        Ext.getCmp('content').getUpdater().un(
            'beforedestroy',
            self.destroy,
            self
        );
    }
    
    TCode.upnp_port_management.Container.superclass.constructor.call(this, config);
}

Ext.extend(TCode.upnp_port_management.Container, Ext.Panel);

Ext.onReady(function(){

    Ext.QuickTips.init();
    Ext.MessageBox.minWidth= 200;
    new TCode.upnp_port_management.Container();
});

</script>

