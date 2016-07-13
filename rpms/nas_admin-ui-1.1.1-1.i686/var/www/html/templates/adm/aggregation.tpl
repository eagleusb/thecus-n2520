<div id='DomAggrContainer'/>
<script type='text/javascript'>
Ext.namespace('TCode.Aggr');

WORDS = <{$words}>;

TCode.Aggr.Interfaces = <{$interfaces}>;

TCode.Aggr.Links = <{$links}>;

TCode.Aggr.Flags = <{$flags}>;
TCode.Aggr.HasHA = TCode.Aggr.Flags.ha == '1';

Ext.ux.AddTabButton = (function() {
    function onTabPanelRender() {
        this.addEvents('addTab');
        this.addTab = this.itemTpl.insertBefore(
            this.edge,
            {
                iconCls: 'addtab',
                tooltip: 'aaaa',
                text: '&nbsp;&nbsp;&nbsp;&nbsp;'
            },
            true
        );
        
        this.addTab.addClassOnOver('x-tab-strip-over addtab-over');
        
        this.addTab.on({
            mousedown: stopEvent,
            click: onAddTabClick,
            scope: this
        });
    }

    function createScrollers() {
        this.scrollerWidth = (this.scrollRightWidth = this.scrollRight.getWidth()) + this.scrollLeft.getWidth();
    }

    function autoScrollTabs() {
        var scrollersVisible = (this.scrollLeft && this.scrollLeft.isVisible()),
            pos = this.tabPosition == 'top' ? 'header' : 'footer';
        if (scrollersVisible) {
            if (this.addTab.dom.parentNode === this.strip.dom) {
                if (this.addTabWrap) {
                    this.addTabWrap.show();
                } else {
                    this.addTabWrap = this[pos].createChild({
                        cls: 'x-tab-strip-wrap',
                        style: {
                            position: 'absolute',
                            right: (this.scrollRightWidth + 1) + 'px',
                            top: 0,
                            width: '35px',
                            margin: 0
                        }, cn: {
                            tag: 'ul',
                            cls: 'x-tab-strip x-tab-strip-' + this.tabPosition,
                            style: {
                                width: 'auto'
                            }
                        }
                    });
                    this.addTabWrap.setVisibilityMode(Ext.Element.DISPLAY);
                    this.addTabUl = this.addTabWrap.child('ul');
                }
                this.addTabUl.dom.appendChild(this.addTab.dom);
                this.addTab.setStyle('float', 'none');
            }
            this.stripWrap.setWidth(this[pos].getWidth(true) - (this.scrollerWidth + 31));
            this.stripWrap.setStyle('margin-right', (this.scrollRightWidth + 31) + 'px');
        } else {
            if ((this.addTab.dom.parentNode !== this.strip.dom)) {
                var notEnoughSpace = (((this[pos].getWidth(true) - this.edge.getOffsetsTo(this.stripWrap)[0])) < 33)
                this.addTabWrap.hide();
                this.addTab.setStyle('float', '');
                this.strip.dom.insertBefore(this.addTab.dom, this.edge.dom);
                this.stripWrap.setWidth(this.stripWrap.getWidth() + 31);
                if (notEnoughSpace) {
                    this.autoScrollTabs();
                }
            }
        }
    }

    function autoSizeTabs() {
        this.addTab.child('.x-tab-strip-inner').setStyle('width', '35px');
    }

    function stopEvent(e) {
        e.stopEvent();
    }

    function onAddTabClick() {
        this.fireEvent('addTab');
    }

    return {
        init: function(tp) {
            if (tp instanceof Ext.TabPanel) {
                tp.onRender = tp.onRender.createSequence(onTabPanelRender);
                tp.createScrollers = tp.createScrollers.createSequence(createScrollers);
                tp.autoScrollTabs = tp.autoScrollTabs.createSequence(autoScrollTabs);
                tp.autoSizeTabs = tp.autoSizeTabs.createSequence(autoSizeTabs);
            }
        }
    };
})();

TCode.Aggr.DDZone = Ext.extend(Ext.dd.DropZone, {
    constructor: function(grid, config) {
        this.grid = grid;
        TCode.Aggr.DDZone.superclass.constructor.call(this, grid.view.scroller.dom, config);
    },
    onContainerOver: function(dd, e, data) {
        return dd.grid !== this.grid ? this.dropAllowed : this.dropNotAllowed;
    },
    onContainerDrop: function(dd, e, data) {
        if(dd.grid !== this.grid) {
            this.grid.store.add(data.selections);
            Ext.each(data.selections, function(r) {
                dd.grid.store.remove(r);
            });
            dd.grid.store.sort('id', 'ASC');
            this.grid.store.sort('id', 'ASC');
            
            this.grid.fireEvent('dataChange');
            return true;
        }
        else {
            return false;
        }
    }
});

TCode.Aggr.DDGrid = Ext.extend(Ext.grid.GridPanel, {
    constructor: function() {
        var config = {
            width: 350,
            height: 200,
            border: false,
            frame: true,
            enableDragDrop: true,
            autoExpandColumn: '1',
            viewConfig: {
                autoFill: true,
                forceFit: false
            },
            columns: [
                {
                    header: WORDS.name,
                    fixed: true,
                    hideable: false,
                    menuDisabled: true,
                    dataIndex: 'name'
                },
                {
                    header: WORDS.speed,
                    fixed: true,
                    hideable: false,
                    menuDisabled: true,
                    dataIndex: 'speed'
                }
            ],
            store: new Ext.data.SimpleStore({
                fields: ['id', 'name', 'speed']
            })
        }
        
        this.addEvents('dataChange');
        
        TCode.Aggr.DDGrid.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            this.dz = new TCode.Aggr.DDZone(this, {ddGroup:this.ddGroup || 'GridDD'});
        }
    }
});

TCode.Aggr.Bonding = Ext.extend(Ext.Panel, {
    constructor: function() {
        var config = {
            buttonAlign: 'left',
            autoHeight: true,
            collapsed: true
        };
        
        this.items = [
            {
                layout: 'column',
                items: [
                    {
                        xtype: 'box',
                        autoEl: {
                            tag: 'span',
                            html: WORDS.available
                        },
                        width: 350,
                        style: 'text-align: center;'
                    },
                    {
                        xtype: 'box',
                        width: 36,
                         autoEl: {
                            tag: 'div',
                            html: '&#160'
                        }
                    },
                    {
                        xtype: 'box',
                        autoEl: {
                            tag: 'span',
                            html: WORDS.linking
                        },
                        width: 350,
                        style: 'text-align: center;'
                    }
                ]
            },
            {
                layout: 'column',
                items: [
                    new TCode.Aggr.DDGrid(),
                    {
                        width: 36,
                        bodyStyle: 'margin:69px 1px 0; border: 0px; padding-left: 5px',
                        items: [
                            {
                                xtype: 'button',
                                iconCls: 'move-to-right',
                                border: false,
                                scope: this,
                                handler: this.moveRecordToRight
                            },
                            {
                                xtype: 'button',
                                iconCls: 'move-to-left',
                                style: 'margin-top: 10px;',
                                scope: this,
                                handler: this.moveRecordToLeft
                            }
                        ]
                    },
                    new TCode.Aggr.DDGrid()
                ]
            }
        ];
        
        this.buttons = [
            {
                text: WORDS.link,
                scope: this,
                handler: function() {
                    this.fireEvent('bondInterface', this.getAvailable(), this.getBonding(), this.device);
                    delete this.device;
                }
            },
            {
                text: WORDS.cancel,
                scope: this,
                handler: function() {
                    this.fireEvent('bondCancel');
                }
            }
        ];
        
        this.addEvents('bondInterface');
        this.addEvents('bondCancel');
        
        TCode.Aggr.Bonding.superclass.constructor.call(this, config);
        
    },
    listeners: {
        render: function() {
            this.ui = {
                bond: this.buttons[0],
                cancel: this.buttons[1],
                available: this.items.get(1).items.get(0),
                bonding: this.items.get(1).items.get(2)
            };
            
            this.ui.bonding.on('dataChange', this.checkSameType, this );
            this.ui.available.on('dataChange', this.checkSameType, this );
        },
        expand: function() {
            this.sort();
        }
    },
    sort: function() {
        with( this.ui ) {
            available.store.sort('id', 'ASC');
            bonding.store.sort('id', 'ASC');
        }
    },
    setDevices: function(available, bonding) {
        if( Ext.isArray(available) ) {
            this.ui.available.store.loadData(available);
        } else {
            this.ui.available.store.removeAll();
        }
        
        if( Ext.isArray(bonding) ) {
            this.ui.bonding.store.loadData(bonding);
        } else {
            this.ui.bonding.store.removeAll();
        }
        
        this.sort();
        this.checkSameType();
    },
    moveRecordToRight: function() {
        with( this.ui ) {
            bonding.store.add(available.selModel.getSelections());
            available.selModel.each(function(r){
                this.grid.store.remove(r);
            });
        }
        this.sort();
        this.checkSameType();
    },
    moveRecordToLeft: function() {
        with( this.ui ) {
            available.store.add(bonding.selModel.getSelections());
            bonding.selModel.each(function(r){
                this.grid.store.remove(r);
            });
        }
        this.sort();
        this.checkSameType();
    },
    checkSameType: function() {
        var speed;
        with( this.ui.bonding ) {
            var data = store.getRange(0, store.data.length);
        }
        with( this.ui ) {
            if( data.length < 2 ) {
                return bond.setDisabled(true);
            }
            for( var i = 0 ; i < data.length ; ++i ) {
                speed = speed || data[i].data.speed;
                if( speed != data[i].data.speed ) {
                    return bond.setDisabled(true);
                }
            }
            bond.setDisabled(false);
        }
    },
    getAvailable: function() {
        var data = [];
        this.ui.available.selModel.selectAll();
        var devices = this.ui.available.selModel.getSelections();
        for( var i = 0 ; i < devices.length ; ++i ) {
            data.push(devices[i].data.id);
        }
        return data;
    },
    getBonding: function() {
        var data = [];
        this.ui.bonding.selModel.selectAll();
        var devices = this.ui.bonding.selModel.getSelections();
        for( var i = 0 ; i < devices.length ; ++i ) {
            data.push(devices[i].data.id);
        }
        return data;
    },
    setDevice: function(id) {
        this.device = id;
    }
});

TCode.Aggr.Interface = Ext.extend(Ext.Panel, {
    constructor: function(eth, device, writable) {
        this.checkDefaultConfig(eth, device);
        
        var _eth = this._eth;
        
        var status = WORDS.normal;
        if( _eth.vip != '' ) {
            status = WORDS.ha_lock;
        }
        
        if( _eth.linking != '' ) {
            status = _eth.linking.toUpperCase();
        }
        
        if( _eth.heartbeat != '' ) {
            status = WORDS.heartbeat;
        }
        
        var ha_bond = false;
        if( _eth.bonding.length > 0 ) {
            var val = [];
            for( var i = 0 ; i < _eth.bonding.length ; ++i) {
                var eth = _eth.bonding[i];
                if( _eth.vip != '' ) {
                    ha_bond = true;
                }
                val.push(TCode.Aggr.Interfaces[eth].name);
            }
            if( _eth.vip != '' ) {
                status = String.format('{0}, {1}', WORDS.ha_lock, val.join(', '));
            } else {
                status =  val.join(', ');
            }
        }
        
        this.writable = writable;
        
        var config = {
            title: _eth.name,
            autoHeight: true,
            bodyStyle: 'background: transparent;',
            layout: 'column',
            closable: writable
        };
        
        if( !writable )
            config.id = eth;
        
        if( ha_bond ) {
            config.closable = false;
            writable = false;
        }
        
        this.items = [
            {
                layout: 'form',
                columnWidth: 0.5,
                items: [
                    {
                        layout: 'column',
                        bodyStyle: 'padding-left: 0px;',
                        items: [
                            {
                                layout: 'form',
                                columnWidth: 0.9,
                                bodyStyle: 'padding-left: 0px;',
                                items: {
                                    xtype: 'textfield',
                                    fieldLabel: WORDS.status,
                                    width: '98%',
                                    style: 'border: 0px; background: transparent; color: green',
                                    readOnly: true,
                                    value: status,
                                    listeners: {
                                        render: function() {
                                            this.el.hover(function(){
                                                if( this.tip ) {
                                                    return;
                                                }
                                                this.tip = new Ext.ToolTip({
                                                    target: this.el,
                                                    html: this.value.replace(/,/g, '<br>')
                                                });
                                            },function(){
                                                delete this.tip;
                                            }, this);
                                        }
                                    }
                                }
                            },
                            {
                                layout: 'form',
                                columnWidth: 0.1,
                                bodyStyle: 'padding: 0px;',
                                hidden: !writable,
                                items: {
                                    xtype: 'button',
                                    iconCls: 'x-btn-text edit',
                                    scope: this,
                                    handler: function() {
                                        this.ownerCt.ownerCt.changeBonding(this.id);
                                    }
                                }
                            }
                        ]
                    },
                    {
                        xtype: !writable ? 'textfield' : 'combo',
                        fieldLabel: WORDS.jumbo_frame,
                        style: !writable ? 'border: 0px; background: transparent;' : '',
                        readOnly: !writable,
                        value: _eth.jumbo.selected,
                        triggerAction: 'all',
                        selectOnFocus: true,
                        mode: 'local',
                        displayField: 'v',
                        valueField: 'v',
                        listWidth: 60,
                        minValue: 1500,
                        hideTrigger: !writable,
                        store: function(scope) {
                            var data = scope.makeJumboValue(writable);
                            var len = data.length;
                            var min = Number(data[0][1]);
                            var max = Number(data[len-1][1]);
                            return new Ext.data.SimpleStore({
                                fields: ['k', 'v'],
                                data: data,
                                min: min,
                                max: max
                            });
                        }(this),
                        listeners: {
                            render: function() {
                                if( this.trigger ) {
                                    Ext.DomHelper.insertAfter(
                                        this.trigger,
                                        '<span style="padding-left:20px">'+WORDS.bytes+'</span>'
                                    );
                                } else {
                                    this.setValue(this.value + ' ' + WORDS.bytes);
                                }
                            },
                            blur: function() {
                                var min = this.store.min;
                                var max = this.store.max;
                                
                                var value = this.getRawValue();
                                if( Number(min) > Number(value) ) {
                                    this.setValue(min);
                                } else if( Number(max) < Number(value) ) {
                                    this.setValue(max);
                                } else {
                                    this.setValue(value);
                                }
                            }
                        }
                    },
                    {
                        xtype: 'fieldset',
                        title: !writable ? WORDS.ipv4 + ' ' + WORDS.original: WORDS.ipv4,
                        autoHeight: true,
                        items: [
                            {
                                xtype: writable ? 'checkbox' : 'textfield',
                                fieldLabel: WORDS.enable,
                                value: _eth.v4.enable ? WORDS.enabled : WORDS.disabled,
                                checked: _eth.v4.enable,
                                readOnly: !writable,
                                disabled: writable,
                                style: !writable ? 'border: 0px; background: transparent;' : ''
                            },
                            {
                                xtype: 'textfield',
                                value: _eth.v4.setup == 'manual' ? WORDS.manual : WORDS.auto,
                                readOnly: true,
                                fieldLabel: WORDS.setup,
                                style: 'border: 0px; background: transparent;'
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                disabled: !writable,
                                fieldLabel: WORDS.ip,
                                value: _eth.v4.ip,
                                vtype: 'IPv4',
                                allowBlank: !writable,
                                disabledClass: 'fakeLabel',
                                style: 'border: 0px;'
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                disabled: !writable,
                                fieldLabel: WORDS.netmask,
                                value: _eth.v4.mask,
                                vtype: 'IPv4Netmask',
                                allowBlank: !writable,
                                disabledClass: 'fakeLabel',
                                style: 'border: 0px;'
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                disabled: !writable,
                                fieldLabel: WORDS.gateway,
                                value: _eth.v4.gateway,
                                vtype: 'IPv4Gateway',
                                allowBlank: true,
                                disabledClass: 'fakeLabel',
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
                        fieldLabel: WORDS.speed,
                        value: _eth.speed,
                        style: 'border: 0px; background: transparent;',
                        readOnly: true,
                        hideLabel: writable || ha_bond
                    },
                    {
                        xtype: 'combo',
                        fieldLabel: WORDS.config_8023ad,
                        style: !writable ? 'border: 0px; background: transparent;' : '',
                        readOnly: !writable || ha_bond,
                        value: !writable && !ha_bond ? '': _eth.mode,
                        mode: 'local',
                        triggerAction: 'all',
                        selectOnFocus: true,
                        displayField: 'k',
                        valueField: 'v',
                        hideLabel: !writable && !ha_bond,
                        hideTrigger: !writable || ha_bond,
                        listWidth: 100,
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
                        title: !writable ? WORDS.ipv6 + WORDS.original: WORDS.ipv6,
                        autoHeight: true,
                        items: [
                            {
                                xtype: writable ? 'checkbox' : 'textfield',
                                fieldLabel: WORDS.enable,
                                value: _eth.v6.enable ? WORDS.enabled : WORDS.disabled,
                                checked: _eth.v6.enable,
                                style: !writable ? 'border: 0px; background: transparent;' : '',
                                readOnly: !writable,
                                scope: this,
                                listeners: {
                                    check: function(checkbox, checked) {
                                        this.scope.changeIPv6Setup(checked);
                                    }
                                }
                            },
                            {
                                xtype: 'textfield',
                                value: _eth.v6.setup == 'manual' ? WORDS.manual : WORDS.auto,
                                style: 'border: 0px; background: transparent;',
                                readOnly: true,
                                fieldLabel: WORDS.setup
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                disabled: !writable || !_eth.v6.enable,
                                fieldLabel: WORDS.ip,
                                value: _eth.v6.prefix,
                                vtype: 'IPv6',
                                allowBlank: !writable || !_eth.v6.enable,
                                disabledClass: 'fakeLabel',
                                style: 'border: 0px;'
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                disabled: !writable || !_eth.v6.enable,
                                fieldLabel: WORDS.prefix_length,
                                value: _eth.v6.length,
                                vtype: 'IPv6Length',
                                allowBlank: !writable || !_eth.v6.enable,
                                disabledClass: 'fakeLabel',
                                style: 'border: 0px;'
                            },
                            {
                                xtype: 'textfield',
                                width: '90%',
                                disabled: !writable || !_eth.v6.enable,
                                fieldLabel: WORDS.gateway,
                                value: _eth.v6.gateway,
                                vtype: 'IPv6Gateway',
                                allowBlank: true,
                                disabledClass: 'fakeLabel',
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
                    xtype: 'textfield',
                    width: 220,
                    layout: 'form',
                    fieldLabel: WORDS.note,
                    maxLength: 12,
                    vtype: 'AliasName',
                    value: _eth.note,
                    disabled: !writable,
                    disabledClass: 'fakeLabel',
                    style: 'border: 0px;'
                }
            }
        ];
        
        TCode.Aggr.Interface.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            this.ui = {
                linking: this.items.get(0).items.get(0).items.get(0).items.get(0),
                modify: this.items.get(0).items.get(0).items.get(1).items.get(0),
                jumbo: this.items.get(0).items.get(1),
                v4: {
                    enable: this.items.get(0).items.get(2).items.get(0),
                    setup: this.items.get(0).items.get(2).items.get(1),
                    ip: this.items.get(0).items.get(2).items.get(2),
                    mask: this.items.get(0).items.get(2).items.get(3),
                    gateway: this.items.get(0).items.get(2).items.get(4)
                },
                speed: this.items.get(1).items.get(0),
                mode: this.items.get(1).items.get(1),
                v6: {
                    enable: this.items.get(1).items.get(2).items.get(0),
                    setup: this.items.get(1).items.get(2).items.get(1),
                    prefix: this.items.get(1).items.get(2).items.get(2),
                    length: this.items.get(1).items.get(2).items.get(3),
                    gateway: this.items.get(1).items.get(2).items.get(4)
                },
                note: this.items.get(2).items.get(0)
            }
        },
        beforedestroy: function() {
        }
    },
    checkDefaultConfig: function(eth, config) {
        this.eth = eth;
        this._eth = config;
        
        Ext.applyIf(this._eth, {
            linking: '',
            vip: '',
            bonding: [],
            heartbeat: '',
            speed: '',
            name: '',
            mode: 'lbrr',
            node: '',
            jumbo: {
                allow: [1500],
                selected: '1500'
            },
            v4: {
                enable: true,
                setup: 'manual',
                ip: '',
                mask: '',
                gateway: ''
            },
            v6: {
                enable: false,
                setup: 'manual',
                ip: '',
                prefix: '',
                gateway: ''
            }
        });
    },
    getLinkingList: function() {
        if( this._eth.linking != '' )
            return this._eth.linking;
        
        var value = [];
        for( var i = 0 ; i < this._eth.bonding.length ; ++i ) {
            var id = this._eth.bonding[i];
            value.push(TCode.Aggr.Interfaces[id].name);
        }
        return value.join(', ');
    },
    setLinkingValue: function(name) {
        this._eth.linking = name;
        this.ui.linking.setValue(name);
    },
    getLinkingValue: function() {
        return this._eth.linking;
    },
    setBondingValue: function(list) {
        delete this._eth.bonding;
        this._eth.bonding = [];
        
        Ext.apply(this._eth.bonding, list);
        
        var value = [];
        for( var i = 0 ; i < list.length ; ++i ) {
            var id = list[i];
            value.push(TCode.Aggr.Interfaces[id].name);
        }
        this.ui.linking.setValue(value.join(', '));
    },
    getBondingValue: function() {
        return this._eth.bonding;
    },
    makeJumboValue: function(){
        var allowList;
        if( this.writable ) {
            var bondList = this._eth.bonding;
            for( var i = 0 ; i < bondList.length ; ++i ) {
                var eth = TCode.Aggr.Interfaces[ bondList[i] ];
                allowList = allowList || eth.jumbo.allow;
                if( eth.jumbo.allow.length < allowList.length ) {
                    allowList = eth.jumbo.allow;
                }
            }
        } else {
            allowList = this._eth.jumbo.allow;
        }
        
        var data = [];
        for( var i = 0 ; i < allowList.length ; ++i ) {
            data.push([
                allowList[i] == '1500' ? WORDS.disabled : allowList[i] + ' ' + WORDS.bytes,
                allowList[i]
            ]);
        }
        return data;
    },
    setName: function(name) {
        this.eth = name;
        this.setTitle(name);
    },
    changeIPv6Setup: function(setable) {
        var ui = {
            prefix: this.ui.v6.prefix,
            length: this.ui.v6.length,
            gateway: this.ui.v6.gateway
        }
        for( var id in ui ) {
            ui[id].setDisabled(!setable);
            if( setable ) {
                ui[id].addClass('x-form-text');
                ui[id].addClass('x-form-field');
            } else {
                ui[id].removeClass('x-form-text');
                ui[id].removeClass('x-form-field');
            }
            if( id != 'gateway' ) {
                ui[id].allowBlank = !setable;
            }
            ui[id].validate();
        }
    },
    getIP: function() {
        var enable = this.ui.v4.enable.getValue();
        var v4 = (enable == true) || (enable == WORDS.enabled) ? this.ui.v4.ip.getValue() : '';
            enable = this.ui.v6.enable.getValue();
            v4 = (v4 == '0.0.0.0') ? '' : v4;
        var v6 = enable == true || enable == WORDS.enabled ? this.ui.v6.prefix.getValue() : '';
        
        return {
            v4: v4,
            v6: v6
        }
    },
    saveConfigure: function() {
        var check = [
            this.ui.v4.ip,
            this.ui.v4.mask,
            this.ui.v4.gateway,
            this.ui.v6.prefix,
            this.ui.v6.length,
            this.ui.v6.gateway,
            this.ui.note
        ]
        
        for( var i = 0 ; i < check.length ; ++i ) {
            if( !check[i].isValid() ) {
                Ext.Msg.alert('[' + check[i].fieldLabel + ']', WORDS.invalid );
                return 'err';
            }
        }
        
        if( this.ui.v4.gateway.getValue() != '' ) {
            var v = ipv4check(
                this.ui.v4.ip.getValue(),
                this.ui.v4.mask.getValue(),
                this.ui.v4.gateway.getValue()
            );
            
            if( v != true ) {
                var msg = String.format(
                    WORDS.gateway_range_error,
                    this.ui.v4.gateway.getValue(),
                    this.ui.v4.ip.getValue(),
                    this.ui.v4.mask.getValue()
                );
                Ext.Msg.alert(WORDS.attention, msg);
                return 'err';
            }
        }
        
        if( this.ui.v6.gateway.getValue() != '' ) {
            var len = Number(this.ui.v6.length.getValue());
            var ip1 = ipv6Extend(
                this.ui.v6.prefix.getValue(),
                len
            );
            var ip2 = ipv6Extend(
                this.ui.v6.gateway.getValue(),
                len
            );
            
            if( ip1.join() != ip2.join() ) {
                var msg = String.format(
                    WORDS.gateway_range_error,
                    this.ui.v6.gateway.getValue(),
                    this.ui.v6.prefix.getValue(),
                    len
                );
                Ext.Msg.alert(WORDS.attention, msg);
                return 'err';
            }
        }
        
        var v6Enable = this.ui.v6.enable.getValue();
        if( v6Enable === true || v6Enable == WORDS.enabled ) {
            v6Enable = true;
        } else {
            v6Enable = false;
        }
        
        return {
            bonding: this._eth.bonding,
            mode: this.ui.mode.getValue(),
            note: this.ui.note.getValue(),
            jumbo: {
                selected: this.ui.jumbo.getRawValue()
            },
            v4: {
                enable: true,
                ip: this.ui.v4.ip.getValue(),
                mask: this.ui.v4.mask.getValue(),
                gateway: this.ui.v4.gateway.getValue()
            },
            v6: {
                enable: v6Enable,
                prefix: this.ui.v6.prefix.getValue(),
                length: this.ui.v6.length.getValue(),
                gateway: this.ui.v6.gateway.getValue()
            }
        }
    }
});

TCode.Aggr.Gateway = Ext.extend(Ext.Panel, {
    constructor: function() {
        var config = {
            tag: 'gateway',
            layout: 'form'
        };
        
        this.items = new Ext.form.ComboBox({
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
        
        TCode.Aggr.Gateway.superclass.constructor.call(this, config);
    },
    makeGatewayCombo: function() {
        var gateway = [];
        gateway.push(['', WORDS.none]);
        for(var eth in TCode.Aggr.Interfaces ) {
            var _eth = TCode.Aggr.Interfaces[eth];
            if( _eth.linking == '' && _eth.heartbeat == '' ) {
                gateway.push([eth, _eth.name]);
            }
        }
        
        for(var i = 0 ; i < TCode.Aggr.Links.length ; ++i ) {
            var eth = 'bond' + i;
            var _eth = TCode.Aggr.Links[i];
            if( _eth.linking == '' && _eth.heartbeat == '' ) {
                gateway.push([eth, _eth.name]);
            }
        }
        
        
        return new Ext.data.SimpleStore({
            fields: ['v', 'k'],
            data: gateway
        });
    },
    changeGatewayCombo: function(data) {
        var value1 = '',
            value2 = this.items.get(0).getValue();
            
        for( var i = 0 ; i < data.length ; ++i ) {
            if( value2 == data[i][0] ) {
                value1 = value2;
            }
        }
        
        this.items.get(0).setValue(value1);
        
        this.items.get(0).store.loadData(data);
    },
    saveConfigure: function() {
        return this.items.get(0).getValue();
    }
});

/**
 * @namespace TCode.Aggr
 * @extends Ext.TabPanel
 */
TCode.Aggr.InterfacePanel = Ext.extend(Ext.TabPanel, {
    constructor: function() {
        var config = {
            id: 'AggrEthernet',
            tag: 'ethernets',
            plain: true,
            enableTabScroll: true,
            deferredRender: false,
            layoutOnTabChange: true,
            style: 'margin-bottom: 10px;',
            bodyStyle: 'background: transparent; padding: 5px;',
            activeItem: 0
        };
        
        this.plugins = [
            Ext.ux.AddTabButton
        ];
        
        this.items = [];
        this.interfaces = 0;
        for( var eth in TCode.Aggr.Interfaces ) {
            this.items.push(new TCode.Aggr.Interface(
                eth,
                TCode.Aggr.Interfaces[eth],
                false
            ));
            
            if( !/LINK*/.test(eth) ) {
                this.interfaces++;
            }
        }
        
        for( this.links = 0 ; this.links < TCode.Aggr.Links.length ; ++this.links ) {
            TCode.Aggr.Links[this.links].name = 'LINK' + (this.links + 1);
            this.items.push(new TCode.Aggr.Interface(
                'LINK' + (this.links + 1),
                TCode.Aggr.Links[this.links],
                true
            ));
        }
        
        TCode.Aggr.InterfacePanel.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            this.autoScrollTabs();
        },
        remove: function(container, device) {
            var bonding = device._eth.bonding;
            for( var i = 0 ; i < bonding.length ; ++i ) {
                var eth = bonding[i];
                Ext.getCmp(eth).setLinkingValue('');
            }
            
            this.links--;
            for( var i = this.interfaces ; i < this.items.length ; ++i ) {
                this.items.get(i).setName('LINK' + (i - this.interfaces + 1));
                var bonding = this.items.get(i)._eth.bonding;
                for( var j = 0 ; j < bonding.length ; ++j ) {
                    var id = bonding[j];
                    Ext.getCmp(id).setLinkingValue('LINK' + (i - this.interfaces + 1));
                }
            }
        }
    },
    addInterface: function(bonding) {
        this.add(new TCode.Aggr.Interface(
            'LINK' + (this.links + 1),
            {
                name: 'LINK' + (this.links + 1),
                bonding: bonding
            },
            true
        )).show();
        
        this.links++;
    },
    saveConfigure: function() {
        var data = [];
        var ips = {};
        for( var i = 0 ; i < this.items.length ; ++i ) {
            var device = this.items.get(i);
            if( /LINK.*/.test(device.title) ) {
                var configure = device.saveConfigure();
                if( configure == 'err' ) {
                    this.activate(device);
                    return 'err';
                } else {
                    data.push(configure);
                }
            }
            
            var linking = device.getLinkingValue() != '';
            if( !linking ) {
                var ip = device.getIP();
                if( ip.v4 != '' ) {
                    var v4 = ipv4fix(ip.v4);
                    if( ips[v4] ) {
                        var msg = String.format(
                            WORDS.same_ip,
                            v4
                        );
                        Ext.Msg.alert(WORDS.attention, msg);
                        this.activate(device);
                        return 'err';
                    }
                    if( v4 != 0 && v4 != "0.0.0.0" )
                        ips[v4] = true;
                }
                
                if( ip.v6 != '' ) {
                    var v6 = ipv6Extend(ip.v6).join('.');
                    if( ips[v6] ) {
                        var msg = String.format(
                            WORDS.same_ip,
                            ip.v6
                        );
                        Ext.Msg.alert(WORDS.attention, msg);
                        this.activate(device);
                        return 'err';
                    }
                    if( v6.lenhth > 0 )
                        ips[v6] = true;
                }
            }
        }
        
        return data;
    }
});

TCode.Aggr.Container = Ext.extend(Ext.FormPanel, {
    constructor: function() {
        var config = {
            renderTo: 'DomAggrContainer',
            style: 'margin: 10px;',
            buttonAlign: 'left'
        }
        
        this.items = [
            new TCode.Aggr.Bonding(),
            new TCode.Aggr.InterfacePanel(),
            {
                layout: 'form',
                buttonAlign: 'left',
                items: new TCode.Aggr.Gateway(),
                buttons: [
                    {
                        text: WORDS.apply,
                        scope: this,
                        handler: this.saveConfigure
                    }
                ]
            },
            {
                xtype: 'fieldset',
                title: WORDS.description,
                autoHeight: true,
                items: {
                    xtype: 'label',
                    text: WORDS.apply_note
                }
            }
        ]
        
        TCode.Aggr.Container.superclass.constructor.call(this, config);
    },
    listeners: {
        render: function() {
            Ext.get('content').getUpdateManager().on('beforeupdate', this.destroy, this );
            this.ui = {
                bond: this.items.get(0),
                panel: this.items.get(1),
                panel2: this.items.get(2),
                gateway: this.items.get(2).items.get(0)
            }
            
            this.ui.bond.on('bondInterface', this.bondInterface, this);
            this.ui.bond.on('bondCancel', this.hideBondControllor, this);
            this.ui.panel.on('addTab', this.showBondControllor, this);
            this.ui.panel.on('remove', this.changeDefaultGateway, this);
            
            Ext.get('content').getUpdateManager().on('beforeupdate', this.destroy, this );
            
            var msg = '';
            if( TCode.Aggr.HasHA ) {
                msg += WORDS.detect_ha;
            }
            
            if( TCode.Aggr.Flags.reboot == '1' ) {
                if( msg != '' ) {
                    msg += '<br><br>';
                }
                msg += WORDS.detect_reboot;
            }
            if( msg != '' ) {
                if( TCode.Aggr.Flags.reboot == '0' ) {
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
            delete TCode.Aggr;
        }
    },
    getAvailable: function() {
        var panel = this.ui.panel;
        var data = [];
        for( var i = 0 ; i < panel.items.length ; ++i ) {
            var eth = panel.items.get(i).eth;
            if( /^LINK*/.test(eth) ) {
                break;
            }
            var _eth = panel.items.get(i)._eth;
            
            if( _eth.linking == '' && _eth.heartbeat == '' && _eth.vip == '' ) {
                data.push([
                    panel.items.get(i).id,
                    _eth.name,
                    (/^eth*/i).test(eth) ? '1G' : '10G'
                ]);
            }
        }
        
        return data;
    },
    getBonding: function(list) {
        var data = [];
        for( var i = 0 ; i < list.length ; ++i ) {
            var eth = list[i];
            var _eth = TCode.Aggr.Interfaces[eth];
            
            data.push([
                list[i],
                _eth.name,
                (/^eth*/i).test(eth) ? '1G' : '10G'
            ]);
        }
        return data;
    },
    showBondControllor: function() {
        this.ui.bond.setDevices(this.getAvailable());
        this.ui.bond.sort();
        
        this.ui.bond.expand();
        this.ui.panel.hide();
        this.ui.panel2.hide();
    },
    hideBondControllor: function() {
        this.ui.bond.collapse();
        this.ui.panel.show();
        this.ui.panel2.show();
    },
    bondInterface: function(available, bonding, id) {
        if( id ) {
            name = Ext.getCmp(id).eth;
        } else {
            name = 'LINK' + (this.ui.panel.links + 1);
        }
        
        this.hideBondControllor();
        
        for( var i = 0 ; i < available.length ; ++i ) {
            with( Ext.getCmp(available[i]) ) {
                setLinkingValue('');
            }
        }
        
        var list = [];
        for( var i = 0 ; i < bonding.length ; ++i ) {
            with( Ext.getCmp(bonding[i]) ) {
                setLinkingValue(name);
                list.push(eth);
                if( eth == 'eth0' ) {
                    Ext.Msg.alert(
                        WORDS.attention,
                        WORDS.dns_note
                    )
                }
            }
        }
        
        if( id ) {
            Ext.getCmp(id).setBondingValue(list);
        } else {
            this.ui.panel.addInterface(list);
        }
        
        this.changeDefaultGateway();
    },
    changeBonding: function(id) {
        var list = Ext.getCmp(id)._eth.bonding;
        this.ui.bond.setDevices(this.getAvailable(), this.getBonding(list));
        this.ui.bond.sort();
        
        this.ui.bond.setDevice(id);
        this.ui.bond.expand();
        this.ui.panel.hide();
        this.ui.panel2.hide();
    },
    changeDefaultGateway: function() {
        var gateway = [['', WORDS.none]];
        available = this.getAvailable();
        for( var i = 0 ; i < available.length ; ++i ) {
            var eth = available[i][0];
            var name = available[i][1];
            gateway.push([eth, name]);
        }
        
        for( var i = 0 ; i < this.ui.panel.links ; ++i ) {
            gateway.push(['bond' + i, 'LINK' + (i + 1)]);
        }
        
        this.ui.gateway.changeGatewayCombo(gateway);
    },
    saveConfigure: function() {
        var bonds = this.ui.panel.saveConfigure();
        if( bonds == 'err' ) {
            return;
        }
        this.makeSaveRequest(Ext.encode({
            bonds: bonds,
            gateway: this.ui.gateway.saveConfigure()
        }));
    },
    makeSaveRequest: function(conf) {
        var ajax = {
            url: 'setmain.php',
            params: {
                fun: 'setaggregation',
                action: 'save',
                params: conf
            },
            scope: this,
            success: this.requestSuccess
        };
        
        Ext.Ajax.request(ajax);
    },
    requestSuccess: function(response, opts) {
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
    new TCode.Aggr.Container();
});

</script>
