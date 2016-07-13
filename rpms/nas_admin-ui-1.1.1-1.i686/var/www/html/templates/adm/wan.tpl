<div id='DomNetworkContainer'/>

<script type='text/javascript'>

WORDS = <{$words}>;

Ext.namespace('TCode.Network');

TCode.Network.Flags = <{$flags}>;
TCode.Network.HasHA = TCode.Network.Flags.ha == '1';

TCode.Network.ConfHost = <{$host}>;

TCode.Network.ConfDNS = <{$dns}>;

TCode.Network.ConfEthernets = <{$ethernets}>;

TCode.Network.Failed = function(obj) {
    Ext.Msg.alert('[' + obj.fieldLabel + ']', WORDS.invalid );
}

TCode.Network.SameIP = function(obj) {
    Ext.Msg.alert('[' + obj.fieldLabel + ']', WORDS.same_ip );
}

TCode.Network.UiHost = Ext.extend(Ext.form.FieldSet, {
    constructor: function() {
        this.checkDefaultConfig();
        var _host = this._host;
        
        var allDisabled = TCode.Network.HasHA;
        
        var config = {
            id: 'NetHost',
            tag: 'host',
            layout: 'column',
            border: false,
            autoHeight: true,
            title: WORDS.host_setting,
            defaults: {
                layout: 'form',
                border: false,
                xtype: 'panel',
                bodyStyle: 'padding:0 18px 0 0'
            },
            items: [
                {
                    columnWidth: 0.5,
                    items: [
                        {
                            xtype: 'textfield',
                            id: 'NetHostName',
                            width: '90%',
                            fieldLabel: WORDS.hostname,
                            fieldClass: '',
                            disabledClass: 'fakeLabel',
                            vtype: 'Hostname',
                            value: _host.name,
                            disabled: allDisabled,
                            allowBlank: false & allDisabled,
                            style: allDisabled ? 'border: 0px' : ''
                        },
                        {
                            xtype: 'textfield',
                            id: 'NetHostWins1',
                            width: '90%',
                            fieldLabel: WORDS.wins + ' 1',
                            fieldClass: '',
                            disabledClass: 'fakeLabel',
                            vtype: 'WINS',
                            value: _host.wins[0],
                            disabled: allDisabled,
                            style: allDisabled ? 'border: 0px' : ''
                        }
                    ]
                },
                {
                    columnWidth: 0.5,
                    items: [
                        {
                            xtype: 'textfield',
                            id: 'NetHostDomain',
                            width: '90%',
                            fieldLabel: WORDS.domain_name,
                            fieldClass: '',
                            disabledClass: 'fakeLabel',
                            value: '<{$wan_domainname}>',
                            vtype: 'Domain',
                            value: _host.domain,
                            disabled: allDisabled,
                            style: allDisabled ? 'border: 0px' : ''
                        },
                        {
                            xtype: 'textfield',
                            id: 'NetHostWins2',
                            width: '90%',
                            fieldLabel: WORDS.wins + ' 2',
                            fieldClass: '',
                            disabledClass: 'fakeLabel',
                            vtype: 'WINS',
                            value: _host.wins[1],
                            disabled: allDisabled,
                            style: allDisabled ? 'border: 0px' : ''
                        }
                    ]
                }
            ]
        }
        
        TCode.Network.UiHost.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            this.host = {
                name: Ext.getCmp('NetHostName'),
                domain: Ext.getCmp('NetHostDomain'),
                wins: [
                    Ext.getCmp('NetHostWins1'),
                    Ext.getCmp('NetHostWins2')
                ]
            }
        }
    },
    checkDefaultConfig: function() {
        this._host = TCode.Network.ConfHost;
        
        Ext.applyIf(this._host, {
            name: '',
            domain: '',
            wins: [ '', '' ]
        });
        
        this.defaultConfigure = Ext.encode(this._host);
    },
    validate: function(obj) {
        if( !obj.isValid() ) {
            TCode.Network.Failed(obj);
            return false;
        }
        
        return true;
    },
    saveConfigure: function() {
        with( this ) {
            if( validate( host.name ) == false ) return false;
            if( validate( host.domain ) == false ) return false;
            if( validate( host.wins[0] ) == false ) return false;
            if( validate( host.wins[1] ) == false ) return false;
            
            _host.name = host.name.getValue();
            _host.domain = host.domain.getValue();
            delete _host.wins;
            _host.wins = [];
            
            if( host.wins[0].getValue() != "" ) {
                _host.wins.push( host.wins[0].getValue() );
            }
            if( host.wins[1].getValue() != "" ) {
                _host.wins.push( host.wins[1].getValue() );
            }
            
            if( defaultConfigure != Ext.encode(_host) ) {
                return _host;
            } else {
                return;
            }
        }
    }
});

TCode.Network.UiDNS = Ext.extend(Ext.form.FieldSet, {
    constructor: function() {
        this.checkDefaultConfig();
        
        var _dns = this._dns;
        var data = _dns[_dns.setup];
        
        var allDisabled = false;
        
        var style = 'border: 0px';
        
        var disabled = (_dns.setup == 'auto');
        
        var config = {
            id: 'NetDNS',
            tag: 'dns',
            layout: 'column',
            border: false,
            autoHeight: true,
            title: WORDS.dns_setting,
            defaults: {
                border: false,
                xtype: 'panel',
                bodyStyle: 'padding:0 18px 0 0'
            },
            items: [
                {
                    layout: 'form',
                    columnWidth: 1,
                    items: [
                        {
                            xtype: 'radiogroup',
                            id: 'NetDNSSetup',
                            fieldLabel: WORDS.setup,
                            disabled: TCode.Network.HasHA,
                            columns: 1,
                            scope: this,
                            disabled: allDisabled,
                            items: [
                                {
                                    xtype: 'radio',
                                    name: 'NetDNSSetupGroup',
                                    inputValue: 'manual',
                                    checked: _dns.setup == "manual",
                                    boxLabel: WORDS.manual
                                },
                                {
                                    xtype: 'radio',
                                    name: 'NetDNSSetupGroup',
                                    inputValue: 'auto',
                                    checked: _dns.setup == "auto",
                                    disabled: TCode.Network.ConfEthernets.eth0.v4.setup == 'manual' || TCode.Network.ConfEthernets.eth0.linking != '',
                                    boxLabel: WORDS.auto + ' ' + WORDS.wan_only
                                }
                            ],
                            listeners: {
                                change: function(obj, value) {
                                    this.scope.changeDNSSetup(value == 'manual');
                                }
                            }
                        }
                    ]
                },
                {
                    layout: 'form',
                    columnWidth: 0.5,
                    items: [
                        {
                            xtype: 'textfield',
                            id: 'NetDNS1',
                            width: '90%',
                            fieldLabel: WORDS.dns + ' 1',
                            vtype: 'IP',
                            disabled: disabled || allDisabled,
                            disabledClass: 'fakeLabel',
                            value: data[0],
                            style: style
                        },
                        {
                            xtype: 'textfield',
                            id: 'NetDNS2',
                            width: '90%',
                            fieldLabel: WORDS.dns + ' 2',
                            vtype: 'IP',
                            disabled: disabled || allDisabled,
                            disabledClass: 'fakeLabel',
                            value: data[1],
                            style: style
                        },
                        {
                            xtype: 'textfield',
                            id: 'NetDNS3',
                            width: '90%',
                            fieldLabel: WORDS.dns + ' 3',
                            vtype: 'IP',
                            disabled: disabled || allDisabled,
                            disabledClass: 'fakeLabel',
                            value: data[2],
                            style: style
                        }
                    ]
                }
            ]
        }
        
        TCode.Network.UiDNS.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            this.dns = {
                setup: Ext.getCmp('NetDNSSetup'),
                manual: [
                    Ext.getCmp('NetDNS1'),
                    Ext.getCmp('NetDNS2'),
                    Ext.getCmp('NetDNS3')
                ]
            }
        }
    },
    checkDefaultConfig: function() {
        this._dns = TCode.Network.ConfDNS;
        
        Ext.applyIf(this._dns, {
            setup: 'manual',
            manual: [],
            auto: []
        });
        
        this.defaultConfigure = Ext.encode({
            setup: this._dns.setup,
            manual: this._dns.manual
        });
    },
    changeDNSSetup: function(enabled) {
        with(this) {
            if( enabled == true ) {
                var data = _dns.manual;
            } else {
                var data = _dns.auto;
            }
            for( var i = 0 ; i < 3 ; ++i ) {
                dns.manual[i].setDisabled(!enabled);
                dns.manual[i].setValue(data[i]);
            }
        }
    },
    validate: function(obj) {
        if( !obj.isValid() ) {
            TCode.Network.Failed(obj);
            return false;
        }
        
        return true;
    },
    saveConfigure: function() {
        with(this) {
            if( validate( dns.manual[0] ) == false ) return false;
            if( validate( dns.manual[1] ) == false ) return false;
            if( validate( dns.manual[2] ) == false ) return false;
            
            _dns.setup = dns.setup.getValue();
            delete _dns.manual;
            
            _dns.manual = [];
            if( dns.manual[0].getValue() != "" ) {
                _dns.manual.push( dns.manual[0].getValue() );
            }
            if( dns.manual[1].getValue() != "" ) {
                _dns.manual.push( dns.manual[1].getValue() );
            }
            if( dns.manual[2].getValue() != "" ) {
                _dns.manual.push( dns.manual[2].getValue() );
            }
            
            var configure = {
                setup: _dns.setup,
                manual: _dns.manual
            };
            
            if( defaultConfigure != Ext.encode(configure) ) {
                return configure;
            } else {
                return;
            }
        }
    }
});

TCode.Network.UiIP = Ext.extend(Ext.Panel, {
    constructor: function(eth) {
        this.checkDefaultConfig(eth);
        
        var _eth = this._eth;
        var allDisabled = false;
        if( _eth.heartbeat != '' || _eth.linking != '' || _eth.bonding || _eth.vip != '') {
            allDisabled = true;
        }
        
        var config = {
            id: 'NetIP_' + eth,
            title: _eth.name,
            autoHeight: true,
            bodyStyle: 'background: transparent;',
            lock: false,
            layout: 'column',
            items: [
                {
                    layout: 'form',
                    columnWidth: 0.5,
                    items: [
                        {
                            xtype: 'textfield',
                            id: 'NetIPLinking_' + eth,
                            width: '90%',
                            fieldLabel: WORDS.using_status,
                            value: function(eth) {
                                if( _eth.vip != '' ) {
                                    return WORDS.ha_lock;
                                }
                                
                                _eth.linking = _eth.linking || '';
                                if( _eth.linking != '') {
                                    return _eth.linking.toUpperCase();
                                }
                                
                                if( _eth.heartbeat != '' ) {
                                    return WORDS.heartbeat;
                                }
                                
                                if( _eth.bonding.length > 0 ) {
                                    var val = [];
                                    for( var i = 0 ; i < _eth.bonding.length ; ++i) {
                                        var eth = _eth.bonding[i];
                                        val.push(TCode.Network.ConfEthernets[eth].name);
                                    }
                                    return val.join(', ');
                                }
                                
                                return WORDS.normal;
                            }(eth),
                            cls: 'fakeLabel',
                            style: 'border: 0px; color: green;',
                            readOnly: true
                        },
                        {
                            xtype: 'textfield',
                            id: 'NetIPMac_' + eth,
                            fieldLabel: WORDS.mac,
                            value: _eth.mac,
                            cls: 'fakeLabel',
                            style: 'border: 0px',
                            readOnly: true
                        },
                        {
                            xtype: 'combo',
                            id: 'NetIPJumbo_' + eth,
                            fieldLabel: WORDS.jumbo_frame,
                            style: _eth.bonding ? 'border: 0px; background: transparent;' : '',
                            readOnly: _eth.bonding,
                            hideTrigger: _eth.bonding,
                            mode: 'local',
                            triggerAction: 'all',
                            selectOnFocus: true,
                            displayField: 'v',
                            valueField: 'v',
                            listWidth: 60,
                            minValue: 1500,
                            maxValue: _eth.jumbo.allow[_eth.jumbo.allow.length-1],
                            store: this.makeJumboCombo(_eth.jumbo.allow),
                            value: _eth.jumbo.selected || 1500,
                            allowBlank: _eth.linking != '' || _eth.heartbeat != '' || _eth.bonding,
                            vtype: 'NaturalNumbers',
                            listeners: {
                                render: function() {
                                    Ext.DomHelper.insertAfter(
                                        this.trigger,
                                        '<span style="padding-left:20px">'+WORDS.bytes+'</span>'
                                    );
                                },
                                blur: function() {
                                    var value = this.getRawValue();
                                    if( Number(this.minValue) > Number(value) ) {
                                        this.setValue(this.minValue);
                                    } else if( Number(this.maxValue) < Number(value) ) {
                                        this.setValue(this.maxValue);
                                    } else {
                                        this.setValue(value);
                                    }
                                }
                            }
                        },
                        {
                            xtype: 'fieldset',
                            id: 'NetIPv4_' + eth,
                            title: WORDS.ipv4,
                            autoHeight: true,
                            bodyStyle: 'height: 180px;',
                            items: [
                                {
                                    xtype: 'checkbox',
                                    id: 'NetIPv4Enable_' + eth,
                                    fieldLabel: WORDS.enable,
                                    checked: true,
                                    scope: this,
                                    listeners: {
                                        check: function() {
                                            this.scope.changeIPEnable('v4', this.checked);
                                        }
                                    }
                                },
                                {
                                    xtype: 'radiogroup',
                                    id: 'NetIPv4Setup_' + eth,
                                    fieldLabel: WORDS.setup,
                                    scope: this,
                                    columns: 1,
                                    items: [
                                        {
                                            xtype: 'radio',
                                            name: 'NetIPv4SetupGroup_' + eth,
                                            inputValue: 'manual',
                                            fieldClass: '',
                                            checked: _eth.v4.setup == "manual",
                                            boxLabel: WORDS.manual
                                        },
                                        {
                                            xtype: 'radio',
                                            name: 'NetIPv4SetupGroup_' + eth,
                                            inputValue: 'auto',
                                            fieldClass: '',
                                            checked: _eth.v4.setup == "auto",
                                            boxLabel: WORDS.auto
                                        }
                                    ],
                                    listeners: {
                                        render: function() {
                                            while( (el = this.el.child('div.x-panel-body') ) ) {
                                                el.removeClass('x-panel-body');
                                            }
                                            while( (el = this.el.child('div.x-form-radio-wrap') ) ) {
                                                el.removeClass('x-form-radio-wrap');
                                            }
                                        },
                                        change: function(obj, value) {
                                            this.scope.changeIPSetup('v4', value == 'manual');
                                        }
                                    }
                                },
                                {
                                    xtype: 'textfield',
                                    id: 'NetIPv4IP_' + eth,
                                    vtype: 'IPv4',
                                    width: '90%',
                                    height: 20,
                                    fieldClass: '',
                                    disabledClass: 'fakeLabel',
                                    fieldLabel: WORDS.ip,
                                    allowBlank: _eth.v4.setup == 'auto' || _eth.linking != '' || _eth.heartbeat != '' || _eth.bonding,
                                    value: _eth.v4[_eth.v4.setup].ip,
                                    style: 'border: 0px;'
                                },
                                {
                                    xtype: 'textfield',
                                    id: 'NetIPv4Mask_' + eth,
                                    vtype: 'IPv4Netmask',
                                    width: '90%',
                                    height: 20,
                                    fieldClass: '',
                                    disabledClass: 'fakeLabel',
                                    fieldLabel: WORDS.netmask,
                                    allowBlank: _eth.v4.setup == 'auto' || _eth.linking != '' || _eth.heartbeat != '' || _eth.bonding,
                                    value: _eth.v4[_eth.v4.setup].mask,
                                    style: 'border: 0px;'
                                },
                                {
                                    xtype: 'textfield',
                                    id: 'NetIPv4Gateway_' + eth,
                                    vtype: 'IPv4Gateway',
                                    width: '90%',
                                    height: 20,
                                    fieldClass: '',
                                    disabledClass: 'fakeLabel',
                                    allowBlank: true,
                                    fieldLabel: WORDS.gateway,
                                    value: _eth.v4[_eth.v4.setup].gateway,
                                    style: 'border: 0px;'
                                }
                            ]
                        }
                    ]
                },
                {
                    layout: 'form',
                    columnWidth: 0.5,
                    items: [
                        {
                            xtype: 'textfield',
                            id: 'NetIPSpeed_' + eth,
                            fieldLabel: WORDS.device_speed,
                            value: _eth.speed,
                            cls: 'fakeLabel',
                            style: 'border: 0px',
                            readOnly: true
                            
                        },
                        {
                            xtype: 'textfield',
                            id: 'NetIPConnected_' + eth,
                            fieldLabel: WORDS.link_detect,
                            hidden: _eth.bonding,
                            value: _eth.connected ? WORDS.connected : WORDS.disconnected,
                            cls: 'fakeLabel',
                            style: 'border: 0px',
                            readOnly: true
                        },
                        {
                            xtype: 'combo',
                            fieldLabel: WORDS.config_8023ad,
                            style: 'border: 0px; background: transparent;',
                            readOnly: true,
                            value: _eth.bonding ? _eth.mode : '',
                            mode: 'local',
                            triggerAction: 'all',
                            selectOnFocus: true,
                            displayField: 'k',
                            valueField: 'v',
                            hideLabel: !_eth.bonding,
                            hideTrigger: true,
                            store: new Ext.data.SimpleStore({
                                fields: ['v', 'k'],
                                data: [
                                    ['lbrr', WORDS.mode_8023_lbrr],
                                    ['actbkp', WORDS.mode_8023_actbkp],
                                    ['lbxor', WORDS.mode_8023_lbxor],
                                    ['bcast', WORDS.mode_8023_bcast],
                                    ['8023ad', WORDS.mode_8023_8023ad],
                                    ['bltlb', WORDS.mode_8023_lbtlb],
                                    ['blalb', WORDS.mode_8023_lbalb]
                                ]
                            })
                        },
                        {
                            xtype: 'fieldset',
                            id: 'NetIPv6_' + eth,
                            title: WORDS.ipv6,
                            autoHeight: true,
                            bodyStyle: 'height: 180px;',
                            items: [
                                {
                                    xtype: 'checkbox',
                                    id: 'NetIPv6Enable_' + eth,
                                    fieldLabel: WORDS.enable,
                                    checked: _eth.v6.enable,
                                    scope: this,
                                    listeners: {
                                        check: function(obj, checked) {
                                            this.scope.changeIPEnable('v6', checked);
                                        }
                                    }
                                },
                                {
                                    xtype: 'radiogroup',
                                    id: 'NetIPv6Setup_' + eth,
                                    fieldLabel: WORDS.setup,
                                    scope: this,
                                    columns: 1,
                                    items: [
                                        {
                                            xtype: 'radio',
                                            name: 'NetIPv6SetupGroup_' + eth,
                                            inputValue: 'manual',
                                            checked: _eth.v6.setup == "manual",
                                            boxLabel: WORDS.manual
                                        },
                                        {
                                            xtype: 'radio',
                                            name: 'NetIPv6SetupGroup_' + eth,
                                            inputValue: 'auto',
                                            checked: _eth.v6.setup == "auto",
                                            boxLabel: WORDS.auto
                                        }
                                    ],
                                    listeners: {
                                        render: function() {
                                            while( (el = this.el.child('div.x-panel-body') ) ) {
                                                el.removeClass('x-panel-body');
                                            }
                                            while( (el = this.el.child('div.x-form-radio-wrap') ) ) {
                                                el.removeClass('x-form-radio-wrap');
                                            }
                                        },
                                        change: function(obj, value) {
                                            this.scope.changeIPSetup('v6', value == 'manual');
                                        }
                                    }
                                },
                                {
                                    xtype: 'textfield',
                                    id: 'NetIPv6Prefix_' + eth,
                                    vtype: 'IPv6',
                                    width: '90%',
                                    height: 20,
                                    cls: _eth.v6.setup == 'auto' ? 'fakeLabel' : '',
                                    fieldClass: '',
                                    disabledClass: 'fakeLabel',
                                    fieldLabel: WORDS.ip,
                                    allowBlank: _eth.v6.setup == 'auto' || _eth.linking != '' || _eth.heartbeat != '' || _eth.bonding,
                                    value: _eth.v6[_eth.v6.setup].prefix,
                                    style: 'border: 0px;'
                                },
                                {
                                    xtype: 'textfield',
                                    id: 'NetIPv6Length_' + eth,
                                    vtype: 'IPv6Length',
                                    width: '90%',
                                    height: 20,
                                    cls: _eth.v6.setup == 'auto' ? 'fakeLabel' : '',
                                    fieldClass: '',
                                    disabledClass: 'fakeLabel',
                                    fieldLabel: WORDS.prefix_length,
                                    allowBlank: _eth.v6.setup == 'auto' || _eth.linking != '' || _eth.heartbeat != '' || _eth.bonding,
                                    value: _eth.v6[_eth.v6.setup].length,
                                    style: 'border: 0px;'
                                },
                                {
                                    xtype: 'textfield',
                                    id: 'NetIPv6Gateway_' + eth,
                                    vtype: 'IPv6Gateway',
                                    width: '90%',
                                    height: 20,
                                    cls: _eth.v6.setup == 'auto' ? 'fakeLabel' : '',
                                    fieldClass: '',
                                    disabledClass: 'fakeLabel',
                                    allowBlank: true,
                                    fieldLabel: WORDS.gateway,
                                    value: _eth.v6[_eth.v6.setup].gateway,
                                    style: 'border: 0px;'
                                }
                            ]
                        }
                    ]
                },
                {
                    xtype: 'panel',
                    layout: 'form',
                    columnWidth: 1,
                    items: {
                        id: 'NetIPNote_' + eth,
                        xtype: 'textfield',
                        width: 220,
                        layout: 'form',
                        fieldLabel: WORDS.note,
                        maxLength: 12,
                        vtype: 'AliasName',
                        value: _eth.note,
                        disabled: allDisabled,
                        disabledClass: 'fakeLabel',
                        style: 'border: 0px;'
                    }
                }
            ]
        }
        
        TCode.Network.UiIP.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            this.ip = {
                jumbo: Ext.getCmp('NetIPJumbo_' + this.eth),
                v4: {
                    enable: Ext.getCmp('NetIPv4Enable_' + this.eth),
                    setup: Ext.getCmp('NetIPv4Setup_' + this.eth),
                    ip: Ext.getCmp('NetIPv4IP_' + this.eth),
                    mask: Ext.getCmp('NetIPv4Mask_' + this.eth),
                    gateway: Ext.getCmp('NetIPv4Gateway_' + this.eth)
                },
                v6: {
                    enable: Ext.getCmp('NetIPv6Enable_' + this.eth),
                    setup: Ext.getCmp('NetIPv6Setup_' + this.eth),
                    prefix: Ext.getCmp('NetIPv6Prefix_' + this.eth),
                    length: Ext.getCmp('NetIPv6Length_' + this.eth),
                    gateway: Ext.getCmp('NetIPv6Gateway_' + this.eth)
                },
                note: Ext.getCmp('NetIPNote_' + this.eth)
            }
            
            var allDisabled = false;
            if( this._eth.heartbeat != '' || this._eth.linking != '' || this._eth.bonding || this._eth.vip != '' ) {
                allDisabled = true;
            }
            
            with( this.ip ) {
                if( !/bond.*/.test(this.eth) ) {
                    jumbo.setDisabled(allDisabled);
                }
                v4.enable.setDisabled(allDisabled || true);
                v4.setup.setDisabled(allDisabled || !this._eth.v4.enable);
                v4.ip.setDisabled(allDisabled || !this._eth.v4.enable || this._eth.v4.setup == 'auto');
                v4.mask.setDisabled(allDisabled || !this._eth.v4.enable || this._eth.v4.setup == 'auto');
                v4.gateway.setDisabled(allDisabled || !this._eth.v4.enable || this._eth.v4.setup == 'auto');
                v6.enable.setDisabled(allDisabled);
                v6.setup.setDisabled(allDisabled || !this._eth.v6.enable);
                v6.prefix.setDisabled(allDisabled || !this._eth.v6.enable || this._eth.v6.setup == 'auto');
                v6.length.setDisabled(allDisabled || !this._eth.v6.enable || this._eth.v6.setup == 'auto');
                v6.gateway.setDisabled(allDisabled || !this._eth.v6.enable || this._eth.v6.setup == 'auto');
            }
        }
    },
    checkDefaultConfig: function(eth) {
        this.eth = eth;
        this._eth = TCode.Network.ConfEthernets[eth];
        
        Ext.applyIf(this._eth, {
            name: eth,
            heartbeat: '',
            linking: '',
            vip: '',
            speed: '',
            mac: '',
            bonding: [],
            connected: false,
            mode: 'lbrr',
            note: '',
            jumbo: {
                allow: ['1500'],
                selected: '1500'
            },
            v4: {
                enable: true,
                setup: 'auto',
                manual: {
                    ip: '',
                    mask: '',
                    gateway: ''
                },
                auto: {
                    ip: '',
                    mask: '',
                    gateway: ''
                }
            },
            v6: {
                enable: false,
                setup: 'auto',
                manual: {
                    prefix: '',
                    length: '',
                    gateway: ''
                },
                auto: {
                    prefix: '',
                    length: '',
                    gateway: ''
                }
            }
        });
        
        this.defaultConfigure = Ext.encode({
            note: this._eth.note,
            gateway: this._eth.gateway,
            jumbo: {
                selected: this._eth.jumbo.selected
            },
            v4: {
                enable: this._eth.v4.enable,
                setup: this._eth.v4.setup,
                manual: this._eth.v4.manual
            },
            v6: {
                enable: this._eth.v6.enable,
                setup: this._eth.v6.setup,
                manual: this._eth.v6.manual
            }
        });
    },
    loadJumboData: function(data) {
        data = data || [];
        var _data = [];
        for( var i = 0 ; i < data.length ; ++i ) {
            var v = data[i];
            var k = v == '1500' ? WORDS.disable : v + ' ' + WORDS.bytes;
            _data.push([v, k]);
        }
        return _data;
    },
    makeJumboCombo: function(data) {
        return new Ext.data.SimpleStore({
            fields: ['v', 'k'],
            data: this.loadJumboData(data)
        });
    },
    changeIPEnable: function(ver, enabled) {
        var setable = this.ip[ver].setup.getValue() == 'manual';
        for(var id in this.ip[ver] ) {
            switch(id) {
            case 'enable':
                break;
            case 'setup':
                this.ip[ver][id].setDisabled(!enabled);
                break;
            default:
                this.ip[ver][id].setDisabled(!(enabled && setable));
                if( !/.*gateway.*/.test(id) ) {
                    this.ip[ver][id].allowBlank = !setable;
                }
                this.ip[ver][id].validate();
            }
        }
    },
    changeIPSetup: function(ver, setable) {
        var setup = this.ip[ver].setup.getValue();
        var setable = (setup == 'manual');
        for(var id in this.ip[ver] ) {
            switch(id) {
            case 'enable':
            case 'setup':
                break;
            default:
                this.ip[ver][id].setValue(this._eth[ver][setup][id]);
                this.ip[ver][id].setDisabled(!setable);
                if( !/.*gateway.*/.test(id) ) {
                    this.ip[ver][id].allowBlank = !setable;
                }
                this.ip[ver][id].validate();
            }
        }
        
        if( this.eth == "eth0" ) {
            if( setup == 'manual' ) {
                Ext.getCmp('NetDNSSetup').setValue('manual');
                Ext.getCmp('NetDNSSetup').items.get(1).setDisabled(true);
            } else {
                Ext.getCmp('NetDNSSetup').items.get(1).setDisabled(false);
            }
        }
    },
    validate: function() {
        var version = ['v4', 'v6'];
        
        for( var i = 0 ; i < version.length ; ++i ) {
            var ver = version[i];
            for( var id in this.ip[ver] ) {
                var obj = this.ip[ver][id];
                if( !obj.isValid() ) {
                    return obj;
                }
            }
        }
        
        if( !this.ip.note.isValid() ) {
            return this.ip.note;
        }
        
        with( this.ip ) {
            var _eth = this._eth;
            if( _eth.heartbeat != '' || _eth.linking != '' || _eth.bonding || _eth.vip != '' ) {
                return;
            }
            if( v4.setup.getValue() == 'manual' && v4.gateway.getValue() != '') {
                var v = ipv4check(
                    v4.ip.getValue(),
                    v4.mask.getValue(),
                    v4.gateway.getValue()
                );
                
                if( v != true ) {
                    var msg = String.format(
                        WORDS.gateway_range_error,
                        v4.gateway.getValue(),
                        v4.ip.getValue(),
                        v4.mask.getValue()
                    );
                    Ext.Msg.alert(WORDS.attention, msg);
                    return 'err';
                }
            }
            
            if( v6.setup.getValue() == 'manual' & v6.gateway.getValue() != '' ) {
                var ip1 = ipv6Extend(
                    v6.prefix.getValue(),
                    Number(v6.length.getValue())
                );
                var ip2 = ipv6Extend(
                    v6.gateway.getValue(),
                    Number(v6.length.getValue())
                );
                
                if( ip1.join() != ip2.join() ) {
                    var msg = String.format(
                        WORDS.gateway_range_error,
                        v6.gateway.getValue(),
                        v6.prefix.getValue(),
                        v6.length.getValue()
                    );
                    Ext.Msg.alert(WORDS.attention, msg);
                    return 'err';
                }
            }
        }
        
        return;
    },
    saveConfigure: function() {
        var obj = this.validate();
        if( obj ) {
            if( typeof obj != 'string') {
                TCode.Network.Failed(obj);
            }
            return false;
        }
        
        with(this) {
            _eth.jumbo.selected = ip.jumbo.getRawValue();
            _eth.note = ip.note.getValue();
            _eth.v4.enable = ip.v4.enable.getValue();
            _eth.v4.setup = ip.v4.setup.getValue();
            if( _eth.v4.setup == 'manual' ) {
                _eth.v4.manual.ip = ip.v4.ip.getValue();
                _eth.v4.manual.mask = ip.v4.mask.getValue();
                _eth.v4.manual.gateway = ip.v4.gateway.getValue();
            }
            _eth.v6.enable = ip.v6.enable.getValue();
            _eth.v6.setup = ip.v6.setup.getValue();
            if( _eth.v6.setup == 'manual' ) {
                _eth.v6.manual.prefix = ip.v6.prefix.getValue();
                _eth.v6.manual.length = ip.v6.length.getValue();
                _eth.v6.manual.gateway = ip.v6.gateway.getValue();
            }
            
            var configure = {
                gateway: _eth.gateway,
                note: _eth.note,
                jumbo: {
                    selected: _eth.jumbo.selected
                },
                v4: {
                    enable: _eth.v4.enable,
                    setup: _eth.v4.setup,
                    manual: _eth.v4.manual
                },
                v6: {
                    enable: _eth.v6.enable,
                    setup: _eth.v6.setup,
                    manual: _eth.v6.manual
                }
            };
            
            if( defaultConfigure != Ext.encode(configure) ) {
                return configure;
            } else {
                return;
            }
        }
    }
});

TCode.Network.UiEthernet = Ext.extend(Ext.TabPanel, {
    constructor: function() {
        var config = {
            id: 'NetEthernet',
            tag: 'ethernets',
            enableTabScroll: true,
            deferredRender: false,
            style: 'margin-bottom: 10px;',
            bodyStyle: 'background: transparent; padding: 5px;',
            activeItem: 0,
            plain: true
        };
        
        this.items = [];
        for( var eth in TCode.Network.ConfEthernets ) {
            this.items.push(new TCode.Network.UiIP(eth));
        }
        
        TCode.Network.UiEthernet.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            this.autoScrollTabs();
        }
    },
    saveConfigure: function() {
        var configure;
        var ips = {};
        for(var id in this.items.map ) {
            var eth = this.items.map[id].eth;
            var _configure = this.items.map[id].saveConfigure();
            if( _configure == false ) {
                this.activate(this.items.map[id]);
                return false;
            } else {
                if( this.items.map[id]._eth.linking == '' ) {
                    var v4 = ipv4fix(this.items.map[id].ip.v4.ip.getValue());
                    if( ips[v4] ) {
                        var msg = String.format(
                            WORDS.same_ip,
                            v4
                        );
                        Ext.Msg.alert(WORDS.attention, msg);
                        this.activate(this.items.map[id]);
                        return false;
                    }
                    if( v4 != 0 && v4 != "0.0.0.0" )
                        ips[v4] = true;
                    
                    var v6 = ipv6Extend(this.items.map[id].ip.v6.prefix.getValue()).join('.');
                    if( ips[v6] ) {
                        var msg = String.format(
                            WORDS.same_ip,
                            this.items.map[id].ip.v6.prefix.getValue()
                        );
                        Ext.Msg.alert(WORDS.attention, msg);
                        this.activate(this.items.map[id]);
                        return false;
                    }
                    if( v6.lenhth > 0 )
                        ips[v6] = true;
                        
                    if( _configure ) {
                        configure = configure || {};
                        configure[eth] = _configure;
                    }
                }
            }
        }
        
        if( configure ) {
            return configure;
        } else {
            return;
        }
    }
});

TCode.Network.UiGateway = Ext.extend(Ext.Panel, {
    constructor: function() {
        var config = {
            tag: 'gateway',
            layout: 'form'
        };
        
        this.items = new Ext.form.ComboBox({
            id: 'NetGateway',
            fieldLabel: WORDS.default_gateway,
            disabled: false,
            mode: 'local',
            editable: false,
            allowBlank: true,
            forceSelection: true,
            triggerAction: 'all',
            selectOnFocus: true,
            displayField: 'k',
            valueField: 'v',
            listWidth: 100,
            autoWidth: true,
            store: this.makeGatewayCombo(),
            value: '<{$gateway}>'
        });
        
        TCode.Network.UiGateway.superclass.constructor.call(this, config);
    },
    makeGatewayCombo: function() {
        var gateway = [];
        gateway.push(['', WORDS.none]);
        for(var eth in TCode.Network.ConfEthernets ) {
            var _eth = TCode.Network.ConfEthernets[eth];
            if( _eth.linking == '' && _eth.heartbeat == '' ) {
                gateway.push([eth, _eth.name]);
            }
        }
        
        return new Ext.data.SimpleStore({
            fields: ['v', 'k'],
            data: gateway
        });
    },
    saveConfigure: function() {
        var gateway = Ext.getCmp('NetGateway').getValue();
        if( gateway == '<{$gateway}>' ) {
            return;
        } else {
            return gateway;
        }
    }
});

TCode.Network.UiContainer = Ext.extend(Ext.FormPanel, {
    id: 'NetContainer',
    renderTo: 'DomNetworkContainer',
    buttonAlign: 'left',
    style: 'margin: 10px;',
    initComponent: function() {
        this.items = [
            new TCode.Network.UiHost(),
            new TCode.Network.UiDNS(),
            new TCode.Network.UiEthernet(),
            new TCode.Network.UiGateway()
        ];
        
        this.buttons = [
            {
                text: WORDS.apply,
                scope: this,
                handler: this.saveConfigure
            }
        ];
        
        TCode.Network.UiContainer.superclass.initComponent.call(this);
    },
    listeners: {
        render: function() {
            Ext.get('content').getUpdateManager().on('beforeupdate', this.destroy, this );
            var msg = '';
            if( TCode.Network.HasHA ) {
                msg += WORDS.detect_ha;
            }
            
            if( TCode.Network.Flags.reboot == '1' ) {
                if( msg != '' ) {
                    msg += '<br><br>';
                }
                msg += WORDS.detect_reboot;
            }
            
            if( TCode.Network.ConfDNS.setup == 'auto' ) {
                if( TCode.Network.ConfEthernets.eth0.v4.setup == 'manual' ||
                    TCode.Network.ConfEthernets.eth0.linking != '' ) {
                    if( msg != '' ) {
                        msg += '<br><br>';
                    }
                    msg += WORDS.dns_note;
                }
            }
            
            if( msg != '' ) {
                if( TCode.Network.Flags.reboot == '0' ) {
                    Ext.Msg.alert(WORDS.attention, msg );
                } else {
                    Ext.Msg.show({
                        title: WORDS.attention,
                        msg: msg,
                        buttons: Ext.Msg.YESNO,
                        fn: function(btn){
                            if( btn == 'yes' ) {
                                processUpdater('getmain.php','fun=reboot');
                            }
                        }
                    });
                }
            }
        },
        beforedestroy: function() {
            Ext.get('content').getUpdateManager().un('beforeupdate', this.destroy, this );
            delete WORDS;
            delete TCode.Network;
        }
    },
    saveConfigure: function() {
        var configure;
        for( var id in this.items.map ) {
            var obj = this.items.map[id];
            var _configure = obj.saveConfigure();
            if( _configure == false ) {
                return;
            }
            
            if( _configure ) {
                configure = configure || {};
                configure[obj.tag] = _configure;
            }
        }
        
        if( configure ) {
            this.makeSaveRequest(Ext.encode(configure));
        } else {
            Ext.Msg.alert(WORDS.nochange_title, WORDS.nochange);
        }
    },
    makeSaveRequest: function(conf) {
        mainMask.show();
        var ajax = {
            url: 'setmain.php',
            params: {
                fun: 'setwan',
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
        mainMask.hide();
        var result = Ext.decode(response.responseText);
        
        switch(result.code) {
        case '0':
            Ext.Msg.show({
                title: WORDS.save_title,
                msg: WORDS.save_success,
                buttons: Ext.Msg.YESNO,
                fn: function(btn){
                    if( btn == 'yes' ) {
                        processUpdater('getmain.php','fun=reboot');
                    }
                }
            });
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
    new TCode.Network.UiContainer();
});
</script>
