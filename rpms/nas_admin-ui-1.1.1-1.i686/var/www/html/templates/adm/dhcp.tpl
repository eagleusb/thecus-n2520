<div id='DomDHCP'/>
<script language="javascript">
Ext.namespace('TCode.DHCP');

WORDS = <{$words}>;

TCode.DHCP.Flags = <{$flags}>;
TCode.DHCP.HasHA = TCode.DHCP.Flags.ha == '1';

TCode.DHCP.Configure = <{$configure}>;

TCode.DHCP.Ethernet = Ext.extend(Ext.Panel, {
    constructor: function(eth) {
        this.checkDefaultConfig(eth);
        var _eth = this._eth;
        
        var allDisabled = this.allDisabled;
        var dhcpd = this.dhcpd;
        var radvdd = this.radvdd;
        
        var config = {
            id: 'DHCP_' + eth,
            title: _eth.name,
            layout: 'form',
            autoHeight: true
        };
        
        this.items = [
            {
                xtype: 'textfield',
                fieldLabel: WORDS.status,
                readOnly: true,
                cls: 'fakeLabel',
                style: 'border: 0px; color: green;',
                value: function() {
                    if( _eth.vip != '' ) {
                        return WORDS.ha_lock;
                    }
                    
                    if( _eth.linking != '' ) {
                        return _eth.linking.toUpperCase();
                    }
                    
                    if( _eth.heartbeat != '' ) {
                        return WORDS.heartbeat;
                    }
                    
                    return WORDS.normal;
                }()
            },
            {
                id: 'NetIPNote_' + eth,
                xtype: 'textfield',
                width: '90%',
                fieldLabel: WORDS.note,
                maxLength: 50,
                value: _eth.note,
                disabled: true,
                disabledClass: 'fakeLabel',
                style: 'border: 0px;'
            },
            {
                layout: 'column',
                bodyStyle: 'padding: 0px',
                columns: 2,
                items: [
                    {
                        xtype: 'fieldset',
                        title: WORDS.ipv4,
                        height: 300,
                        style: 'margin: 0px 5px 0px 0px; padding: 5px',
                        columnWidth: 0.5,
                        items: [
                            {
                                xtype: 'textfield',
                                fieldLabel: WORDS.enable,
                                readOnly: true,
                                cls: 'fakeLabel',
                                style: 'border: 0px;',
                                value: _eth.v4.enable ? WORDS.enabled : WORDS.disabled
                            },
                            {
                                xtype: 'textfield',
                                fieldLabel: WORDS.setup,
                                readOnly: true,
                                cls: 'fakeLabel',
                                style: 'border: 0px;',
                                value: WORDS[_eth.v4.setup]
                            },
                            {
                                xtype: 'textfield',
                                fieldLabel: WORDS.ip,
                                readOnly: true,
                                cls: 'fakeLabel',
                                style: 'border: 0px;',
                                value: _eth.v4.ip
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                fieldLabel: WORDS.netmask,
                                cls: 'fakeLabel',
                                disabled: true,
                                value: _eth.v4.mask,
                                style: 'border: 0px'
                            },
                            {
                                xtype: dhcpd ? 'checkbox' : 'textfield',
                                id: 'DHCPIPv4Enable_' + eth,
                                fieldLabel: WORDS.dhcp_service,
                                value: WORDS.not_allow,
                                cls: 'fakeLabel',
                                style: 'border: 0px',
                                checked: _eth.v4.dhcp.enable,
                                disabled: !dhcpd,
                                scope: this,
                                listeners: {
                                    check: function() {
                                        this.scope.changeEnable(this.checked, 'dhcp');
                                    }
                                }
                            },
                            {
                                hidden: !dhcpd,
                                layout: 'form',
                                items: [
                                    {
                                        xtype: 'textfield',
                                        id: 'DHCPIPv4Low_' + eth,
                                        width: '90%',
                                        fieldLabel: WORDS.startip,
                                        cls: !_eth.v4.dhcp.enable ? 'fakeLabel' : '',
                                        allowBlank: !_eth.v4.dhcp.enable,
                                        disabled: !_eth.v4.enable || !_eth.v4.dhcp.enable || _eth.v4.setup == 'auto',
                                        value: dhcpd ? _eth.v4.dhcp.low : '',
                                        vtype: 'IPv4',
                                        style: 'border: 0px'
                                    },
                                    {
                                        xtype: 'textfield',
                                        id: 'DHCPIPv4High_' + eth,
                                        width: '90%',
                                        fieldLabel: WORDS.endip,
                                        cls: !_eth.v4.dhcp.enable ? 'fakeLabel' : '',
                                        allowBlank: !_eth.v4.dhcp.enable,
                                        disabled: !_eth.v4.enable || !_eth.v4.dhcp.enable || _eth.v4.setup == 'auto',
                                        value: dhcpd ? _eth.v4.dhcp.high : '',
                                        vtype: 'IPv4',
                                        style: 'border: 0px'
                                    },
                                    {
                                        xtype: 'textfield',
                                        id: 'DHCPIPv4Gateway_' + eth,
                                        width: '90%',
                                        fieldLabel: WORDS.default_gateway,
                                        cls: !_eth.v4.dhcp.enable ? 'fakeLabel' : '',
                                        allowBlank: true,
                                        disabled: !_eth.v4.enable || !_eth.v4.dhcp.enable || _eth.v4.setup == 'auto',
                                        value: dhcpd ? _eth.v4.dhcp.gateway : '',
                                        vtype: 'IPv4',
                                        style: 'border: 0px'
                                    },
                                    {
                                        xtype: 'textfield',
                                        id: 'DHCPIPv4DNS1_' + eth,
                                        width: '90%',
                                        fieldLabel: WORDS.dns + ' 1',
                                        cls: !_eth.v4.dhcp.enable ? 'fakeLabel' : '',
                                        allowBlank: true,
                                        disabled: !_eth.v4.enable || !_eth.v4.dhcp.enable || _eth.v4.setup == 'auto',
                                        value: dhcpd ? _eth.v4.dhcp.dns1 : '',
                                        vtype: 'IPv4',
                                        style: 'border: 0px'
                                    },
                                    {
                                        xtype: 'textfield',
                                        id: 'DHCPIPv4DNS2_' + eth,
                                        width: '90%',
                                        fieldLabel: WORDS.dns + ' 2',
                                        cls: !_eth.v4.dhcp.enable ? 'fakeLabel' : '',
                                        allowBlank: true,
                                        disabled: !_eth.v4.enable || !_eth.v4.dhcp.enable || _eth.v4.setup == 'auto',
                                        value: dhcpd ? _eth.v4.dhcp.dns2 : '',
                                        vtype: 'IPv4',
                                        style: 'border: 0px'
                                    },
                                    {
                                        xtype: 'textfield',
                                        id: 'DHCPIPv4DNS3_' + eth,
                                        width: '90%',
                                        fieldLabel: WORDS.dns + ' 3',
                                        cls: !_eth.v4.dhcp.enable ? 'fakeLabel' : '',
                                        allowBlank: true,
                                        disabled: !_eth.v4.enable || !_eth.v4.dhcp.enable || _eth.v4.setup == 'auto',
                                        value: dhcpd ? _eth.v4.dhcp.dns3 : '',
                                        vtype: 'IPv4',
                                        style: 'border: 0px'
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        xtype: 'fieldset',
                        id: 'DHCPIPv6_' + eth,
                        title: WORDS.ipv6,
                        height: 300,
                        style: 'margin: 0px 0px 0px 5px; padding: 5px',
                        columnWidth: 0.5,
                        items: [
                            {
                                xtype: 'textfield',
                                fieldLabel: WORDS.enable,
                                readOnly: true,
                                cls: 'fakeLabel',
                                style: 'border: 0px;',
                                value: _eth.v6.enable ? WORDS.enabled : WORDS.disabled
                            },
                            {
                                xtype: 'textfield',
                                fieldLabel: WORDS.setup,
                                readOnly: true,
                                cls: 'fakeLabel',
                                style: 'border: 0px;',
                                value: WORDS[_eth.v6.setup]
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                fieldLabel: WORDS.ip,
                                readOnly: true,
                                cls: 'fakeLabel',
                                style: 'border: 0px;',
                                value: _eth.v6.ip,
                                listeners : { 
                                    render : function(field) {
                                        Ext.QuickTips.register({
                                            target : field.el,
                                            text : _eth.v6.ip
                                        })
                                    }
                                }
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                fieldLabel: WORDS.prefix_length,
                                cls: 'fakeLabel',
                                disabled: true,
                                value: _eth.v6.len,
                                style: 'border: 0px'
                            },
                            {
                                xtype: radvdd ? 'checkbox' : 'textfield',
                                id: 'DHCPIPv6Enable_' + eth,
                                fieldLabel: WORDS.radvd_service,
                                value: WORDS.not_allow,
                                cls: 'fakeLabel',
                                style: 'border: 0px',
                                checked: _eth.v6.radvd.enable,
                                disabled: !radvdd,
                                scope: this,
                                listeners: {
                                    check: function() {
                                        this.scope.changeEnable(this.checked, 'radvd');
                                    }
                                }
                            },
                            {
                                hidden: !radvdd,
                                layout: 'form',
                                items: [
                                    {
                                        xtype: 'textfield',
                                        id: 'DHCPIPv6Prefix_' + eth,
                                        width: '90%',
                                        fieldLabel: WORDS.prefix,
                                        cls: !_eth.v6.radvd.enable ? 'fakeLabel' : '',
                                        allowBlank: !_eth.v6.radvd.enable,
                                        disabled: !_eth.v6.enable || !_eth.v6.radvd.enable || _eth.v6.setup == 'auto',
                                        value: _eth.v6.radvd.prefix,
                                        vtype: 'IPv6Prefix',
                                        style: !_eth.v6.radvd.enable ? 'border: 0px' : ''
                                    },
                                    {
                                        xtype: 'textfield',
                                        id: 'DHCPIPv6Length_' + eth,
                                        width: '90%',
                                        fieldLabel: WORDS.prefix_length,
                                        allowBlank: !_eth.v6.radvd.enable,
                                        vtype: 'IPv6Length',
                                        cls: 'fakeLabel',
                                        disabled: true,
                                        value: '64',
                                        style: 'border: 0px'
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        ];
        
        TCode.DHCP.Ethernet.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            this.dhcp = {
                enable: Ext.getCmp('DHCPIPv4Enable_' + this.eth),
                low: Ext.getCmp('DHCPIPv4Low_' + this.eth),
                high: Ext.getCmp('DHCPIPv4High_' + this.eth),
                gateway: Ext.getCmp('DHCPIPv4Gateway_' + this.eth),
                dns1: Ext.getCmp('DHCPIPv4DNS1_' + this.eth),
                dns2: Ext.getCmp('DHCPIPv4DNS2_' + this.eth),
                dns3: Ext.getCmp('DHCPIPv4DNS3_' + this.eth)
            }
            
            this.radvd = {
                enable: Ext.getCmp('DHCPIPv6Enable_' + this.eth),
                prefix: Ext.getCmp('DHCPIPv6Prefix_' + this.eth),
                length: Ext.getCmp('DHCPIPv6Length_' + this.eth)
            }
        }
    },
    checkDefaultConfig: function(eth) {
        this.eth = eth;
        this._eth = TCode.DHCP.Configure[eth];
        var _eth = this._eth;
        _eth.vip = _eth.vip || '';
        
        Ext.applyIf(_eth.v4.dhcp, {
            dns1: '',
            dns2: '',
            dns3: ''
        })
        
        var allDisabled = false;
        if( _eth.heartbeat != '' || _eth.linking != '' || _eth.vip != '' ) {
            allDisabled = true;
        }
        
        var dhcpd = false;
        if( _eth.v4.enable && (_eth.v4.setup == 'manual') && !allDisabled ) {
            dhcpd = true;
        }
        
        var radvdd = false;
        if( _eth.v6.enable && (_eth.v6.setup == 'manual') && !allDisabled ) {
            radvdd = true;
        }
        
        this.allDisabled = allDisabled;
        this.dhcpd = dhcpd;
        this.radvdd = radvdd;
        
        if( !dhcpd ) {
            for( var k in _eth.v4.dhcp ) {
                _eth.v4.dhcp[k] = '';
            }
            _eth.v4.dhcp.enable = WORDS.not_allow;
        }
        
        if( !radvdd ) {
            for( var k in _eth.v6.radvd ) {
                if( k != 'length' ) {
                    _eth.v6.radvd[k] = '';
                } else {
                    _eth.v6.radvd[k] = '64'; // IPv6 Limitation ?
                }
            }
            _eth.v6.radvd.enable = WORDS.not_allow;
        }
        
        var _configure = {
            v4: {
                dhcp: _eth.v4.dhcp
            },
            v6: {
                radvd: _eth.v6.radvd
            }
        }
        
        this.defaultConfigure = Ext.encode(_configure);
        delete _configure;
    },
    changeEnable: function(checked, service) {
        for( var id in this[service] ) {
            var obj = this[service][id];
            if( id != 'enable' ) {
                if( !checked ) {
                    obj.addClass('fakeLabel');
                } else {
                    obj.removeClass('fakeLabel');
                }
                obj.setDisabled(!checked);
                if( !/dns*/.test(id) && !/gateway*/.test(id) ) {
                    obj.allowBlank = !checked;
                }
                obj.validate();
            }
        }
    },
    validate: function() {
        for( var id in this.dhcp ) {
            if( !this.dhcp[id].isValid() )
                return this.dhcp[id];
        }
        
        for( var id in this.radvd ) {
            if( !this.radvd[id].isValid() )
                return this.radvd[id];
        }
        
        if( this.dhcp.enable.getValue() == true ) {
            var low = this.dhcp.low.getValue();
            var high = this.dhcp.high.getValue();
            var gateway = this.dhcp.gateway.getValue();
            
            if( !ipv4check(this._eth.v4.ip, this._eth.v4.mask, low) ) {
                var msg = low,
                    label = WORDS.startip;
            }
            
            if( !ipv4check(this._eth.v4.ip, this._eth.v4.mask, high) ) {
                var msg = high,
                    label = WORDS.endip;
            }
            
            if( gateway != '' && !ipv4check(this._eth.v4.ip, this._eth.v4.mask, gateway) ) {
                var msg = gateway,
                    label = WORDS.default_gateway;
            }
            
            if( msg ) {
                msg = String.format(
                    WORDS.ip_range_error,
                    label,
                    msg,
                    this._eth.v4.ip,
                    this._eth.v4.mask
                );
                Ext.Msg.alert(WORDS.attention, msg);
                return 'err';
            }
            
            low = low.split('.');
            high = high.split('.');
            for(var i = 0 ; i < 4 ; ++i ) {
                if( Number(low[i]) > Number(high[i]) ) {
                    this.dhcp.low.setValue(high.join('.'));
                    this.dhcp.high.setValue(low.join('.'));
                }
            }
        }
        
        return;
    },
    saveConfigure: function() {
        if( !this.dhcpd && !this.radvdd ) {
            return;
        }
        var obj = this.validate();
        if( obj ) {
            if( typeof obj != 'string') {
                Ext.Msg.alert('[' + obj.fieldLabel + ']', WORDS.invalid );
            }
            return false;
        }
        this._eth.v4.dns = [];
        for( var id in this.dhcp ) {
            var obj = this.dhcp[id];
            this._eth.v4.dhcp[id] = obj.getValue();
            if( id == "enable" ) {
                if( this._eth.v4.dhcp[id] == WORDS.not_allow ) {
                    this._eth.v4.dhcp[id] = '0';
                }
            }
        }
        
        for( var id in this.radvd ) {
            var obj = this.radvd[id];
            this._eth.v6.radvd[id] = obj.getValue();
            if( id == "enable" ) {
                if( this._eth.v6.radvd[id] == WORDS.not_allow ) {
                    this._eth.v6.radvd[id] = '0';
                }
            }
        }
        
        var configure = {
            v4: {
                dhcp: this._eth.v4.dhcp
            },
            v6: {
                radvd: this._eth.v6.radvd
            }
        }
        
        if( this.defaultConfigure != Ext.encode(configure) ) {
            this.defaultConfigure = Ext.encode(configure);
            return configure;
        }
    }
});

TCode.DHCP.UiContainer = Ext.extend(Ext.Panel, {
    constructor: function() {
        var config = {
            id: 'DHCPContainer',
            renderTo: 'DomDHCP',
            buttonAlign: 'left',
            style: 'margin: 10px;'
        };
        
        this.items = new Ext.TabPanel({
            deferredRender: false,
            bodyStyle: 'background: transparent; padding: 5px;',
            activeTab: 0,
            autoHeight: true,
            enableTabScroll: true,
            layoutOnTabChange: true,
            plain: true,
            items: this.makeEthernet()
        });
            
        
        this.buttons = [
            {
                text: WORDS.apply,
                scope: this,
                handler: this.saveConfigure
            }
        ];
        
        TCode.DHCP.UiContainer.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            Ext.get('content').getUpdateManager().on('beforeupdate', this.destroy, this );
            
            var msg = '';
            if( TCode.DHCP.HasHA ) {
                msg += WORDS.detect_ha;
            }
            
            if( TCode.DHCP.Flags.reboot == '1' ) {
                if( msg != '' ) {
                    msg += '<br><br>';
                }
                msg += WORDS.detect_reboot;
            }
            
            if( msg != '' ) {
                if( TCode.DHCP.Flags.reboot == '0' ) {
                    Ext.Msg.alert(WORDS.attention, msg );
                } else {
                    Ext.Msg.show({
                        title: WORDS.attention,
                        msg: msg,
                        buttons: Ext.Msg.OK,
                        fn: function(){
                            processUpdater('getmain.php','fun=reboot');
                        }
                    });
                }
            }
        },
        beforedestroy: function() {
            Ext.get('content').getUpdateManager().un('beforeupdate', this.destroy, this );
            delete WORDS;
            delete TCode.DHCP;
        }
    },
    makeEthernet: function() {
        var items = [];
        for( var eth in TCode.DHCP.Configure ) {
            items.push(new TCode.DHCP.Ethernet(eth));
        }
        return items;
    },
    saveConfigure: function() {
        var configure;
        var map = this.items.get(0).items.map;
        for( var id in map ) {
            var obj = map[id];
            var _configure = obj.saveConfigure();
            if( _configure == false ) {
                this.items.get(0).activate(obj);
                return;
            }
            if( _configure ) {
                configure = configure || {};
                configure[obj.eth] = _configure;
            }
        }
        
        if( configure ) {
            this.makeSaveRequest(Ext.encode(configure));
        } else {
            Ext.Msg.alert(WORDS.save_title, WORDS.nochange);
        }
    },
    makeSaveRequest: function(conf) {
        var ajax = {
            url: 'setmain.php',
            params: {
                fun: 'setdhcp',
                action: 'save',
                params: conf
            },
            scope: this,
            success: this.requestSuccess
        };
        
        Ext.Ajax.request(ajax);
        
        delete ajax;
    },
    requestSuccess: function(response, opts) {
        var result = Ext.decode(response.responseText);
        
        switch(result.code) {
        case '0':
            Ext.Msg.alert(WORDS.save_title, WORDS.save_success );
            break;
        case '1':
            Ext.Msg.alert(WORDS.save_title, WORDS.save_failure );
            break;
        case '2':
            Ext.Msg.alert(WORDS.save_title, WORDS.save_lock );
            break;
        case '3':
            result.data = result.data || [];
            for( var i = 0 ; i < result.data.length ; ++i ) {
                result.data[i] = result.data[i].join(': ');
            }
            Ext.Msg.alert(WORDS.save_title, WORDS.ip_collision + '<br><br>' + result.data.join('<br>') );
            break;
        }
    }
});

Ext.onReady(function() {
    Ext.MessageBox.minWidth = 300;
    Ext.QuickTips.init();
    new TCode.DHCP.UiContainer();
});
</script>

