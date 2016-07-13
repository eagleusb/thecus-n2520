<script type="text/javascript">

Monitors = <{$monitors}>;

Highcharts.setOptions({
    global: {
        useUTC: false
    }
});

Ext.namespace('TCode.Status');
TCode.Status.Nic = <{$nic}>;

WORDS = <{$words}>;

TCode.Status.Default = {
    locked: false,
    layouts: [
        {
            mode: 'Graphic',
            monitors: {CPU:true, Memory:true}
        },
        {
            mode: 'Graphic',
            monitors: {Network:true}
        },
        {
            mode: 'OnlyDetail',
            monitors: {Samba:true, AFP:true, FTP:true, NFS:true}
        },
        {
            mode: 'OnlyDetail',
            monitors: {Fan:true, Temperature:true}
        }
    ]
};
TCode.Status.Save = <{$save}> || TCode.Status.Default;
//this function is sync the attribute of layout submenu(Monitors) and graph(TCode.Status.Save).
(function(){
    var func=function(layout_id){
        for (var prop in TCode.Status.Save.layouts[layout_id].monitors){
            if (typeof(Monitors[prop]) == "undefined" ){
                (TCode.Status.Save.layouts[layout_id].monitors[prop])? TCode.Status.Save.layouts[layout_id].monitors[prop] = false: null;
            }
        }
    }
    for (var i = 0; i < TCode.Status.Save.layouts.length; i++){
        func(i);
    }
}());

TCode.Status.Graphic = Ext.extend(Ext.Panel, {
    autoEl: {
        tag: 'div'
    },
    listeners: {
        resize: function(panel, w, h) {
            if( w && h ) {
                this.chart.setSize(w, h);
            }
        },
        render: function() {
            this.chart = new Highcharts.Chart({
                chart: {
                    renderTo: this.id,
                    reflow: false,
                    animation: false,
                    showAxes: true
                },
                title: {
                    text: null
                },
                credits: {
                    enabled: false
                },
                tooltip: {
                    shared: true,
                    crosshairs: true,
                    formatter: function() {
                        var time = new Date(this.x);
                        var s = String.format('<b>{0}: {1}</b><br>', WORDS.time, time.format('H:i:s'));
                        //var s = '<b>{0}: '+ time.format('H:i:s') +'</b><br/>';
                        
                        $.each(this.points, function(i, point) {
                            if( /^CPU$/.test(point.series.name) || /^Memory$/.test(point.series.name) ) {
                                s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + ' %</span><br/>';
                            } else if( /.*_FAN.*/.test(point.series.name) ) {
                                s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + ' RPM</span><br/>';
                            } else if( /.*(WAN|LAN|LINK).*/.test(point.series.name) ) {
                                s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + ' MB/s</span><br/>';
                            } else if( /.* TEMP.*/.test(point.series.name) ) {
                                s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + ' °C / ' + Math.floor(point.y * (9/5) + 32) + ' °F</span><br/>';
                            } else {
                                s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + '</span><br/>';
                            }
                        });
                        
                        return s;
                    }
                },
                legend: {
                    borderWidth: 0
                },
                plotOptions: {
                    series: {
                        pointPadding: 1,
                        groupPadding: 1,
                        borderWidth: 1,
                        shadow: false,
                        marker: {
                            enabled: false
                        }
                    },
                    area: {
                        zIndex: 1
                    },
                    column: {
                        zIndex: 2,
                        stacking: 'normal'
                    },
                    spline: {
                        zIndex: 3
                    }
                },
                xAxis: {
                    type: 'datetime',
                    tickPixelInterval: 150,
                    labels: {
                        y: 20
                    }
                },
                yAxis: [
                    {
                        min: 0,
                        labels: {
                            formatter: function() {
                                return this.value + ' %'
                            }
                        },
                        title: {
                            text: ''
                        }
                    },
                    {
                        min: 0,
                        allowDecimals: false,
                        labels: {
                            formatter: function() {
                                this.value = Math.floor(this.value/100);
                                return  (this.value / 10) + 'K RPM'
                            }
                        },
                        title: {
                            text: ''
                        }
                    },
                    {
                        min: 0,
                        labels: {
                            formatter: function() {
                                return this.value + ' °C / ' + (this.value * (9/5) + 32) + ' °F'
                            }
                        },
                        title: {
                            text: ''
                        }
                    },
                    {
                        min: 0,
                        labels: {
                            formatter: function() {
                                return this.value + ' MB'
                            }
                        },
                        title: {
                            text: ''
                        }
                    },
                    {
                        min: 0,
                        allowDecimals: false,
                        title: {
                            text: ''
                        }
                    }
                ]
            });
            
            this.monitors = TCode.Status.Save.layouts[this.si].monitors || TCode.Status.Default[this.si].monitors;
            for(var id in this.monitors) {
                this.addSeries(id);
            }
        },
        beforeDestroy: function() {
            if( this.chart ) {
                this.chart.destroy();
                delete this.chart;
            }
        }
    },
    initData: function() {
        var data = [];
        var now = (new Date).getTime();
        for( var i = 0 ; i < 18 ; i++ ) {
            data.push({
                x: now + (i - 17) * 10000,
                y: 100
            });
        }
        delete tmp;
        return data;
    },
    addSeries: function(name) {
        this.sf = this.sf || 1;
        this.st = this.st || 1;
        if( !( name && Monitors[name] ) ) return;
        for(var i = 0 ; i < Monitors[name].series.length ; i++ ) {
            var id = Monitors[name].series[i];
            var tmp;
            if( /^(g?eth|bond).*$/.test(id) ) {
                tmp = TCode.Status.Nic[id];
            } else  if ( /^(.*)_FAN(.*)$/.test(id) ) {
                tmp = id.match(/^(.*)_FAN(.*)$/);
                if( tmp[1] == 'CPU' ) {
                    tmp = WORDS.cpu_fan;
                } else {
                    tmp = WORDS.sys_fan + this.sf++;
                }
            } else  if ( /^(.*)_TEMP(.*)$/.test(id) ) {
                tmp = id.match(/^(.*)_TEMP(.*)$/);
                if( tmp[1] == 'CPU' ) {
                    tmp = WORDS.cpu_temp;
                } else {
                    tmp = WORDS.sys_temp + this.st++;
                }
            } else {
                tmp = WORDS[id.toLowerCase()] || id;
            }
            if( !this.chart.get(id) ) {
                this.chart.addSeries({
                    id: id,
                    name: tmp,
                    type: Monitors[name].type,
                    yAxis: Monitors[name].yaxis
                });
            }
        }
    },
    delSeries: function(name) {
        if( !( name && Monitors[name] ) ) return;
        for(var i = 0 ; i < Monitors[name].series.length ; i++ ) {
            var id = Monitors[name].series[i];
            var series = this.chart.get(id);
            if( series ) {
                series.remove();
            }
            delete series;
            delete id;
        }
    },
    update: function(data) {
        var now = (new Date()).getTime();
        for( var id in data ) {
            var series = this.chart.get(id);
            if( series ) {
                series.addPoint([now, data[id]], true, series.data.length == 18);
            }
        }
        delete now;
        delete data;
    }
});
TCode.Status.Detail = Ext.extend(Ext.grid.GridPanel, {
    initComponent: function() {
        this.monitors = TCode.Status.Save.layouts[this.si].monitors || TCode.Status.Default[this.si].monitors;
        
        this.store = new Ext.data.GroupingStore({
            reader: new Ext.data.ArrayReader(
                {id: 'g'},
                [ 'g', 'rs1', 'rs2', 'rs3' ]
            ),
            sortInfo:{field: 'g', direction: "ASC"},
            groupField: 'g'
        });
        
        this.columns = [
            {header: 'g', dataIndex: 'g'},
            {header: 'rs1'},
            {header: 'rs2'},
            {header: 'rs3'}
        ];
        
        this.view = new Ext.grid.GroupingView({
            autoFill: true,
            forceFit: true,
            startCollapsed: true,
            showGroupName: false,
            enableNoGroups: false,
            hideGroupedColumn: true,
            enableGroupingMenu: false,
            enableRowBody: true,
            groupTextTpl: '{[WORDS[values.text.toLowerCase()] || values.text]} ({[values.rs.length]})'
        });
        
        this.hideHeaders = true;
        
        TCode.Status.Detail.superclass.initComponent.call(this);
    },
    addMonitor: function(name) {
        this.monitors = this.monitors || {};
        this.monitors[name] = true;
    },
    delMonitor: function(name) {
        this.monitors = this.monitors || {};
        delete this.monitors[name];
    },
    update: function(data) {
        var sf = 1;
        var st = 1;
        for( var i = 0 ; i < data.length ; i++ ) {
            var id = data[i][1];
            if( /^(g?eth|bond).*$/.test(id) ) {
                data[i][1] = TCode.Status.Nic[id];
            } else  if ( /^(.*)_FAN(.*)$/.test(id) ) {
                data[i][1] = id.match(/^(.*)_FAN(.*)$/);
                if( data[i][1][1] == 'CPU' ) {
                    data[i][1] = WORDS.cpu_fan;
                } else {
                    data[i][1] = WORDS.sys_fan + sf++;
                }
            } else  if ( /^(.*)_TEMP(.*)$/.test(id) ) {
                data[i][1] = id.match(/^(.*)_TEMP(.*)$/);
                if( data[i][1][1] == 'CPU' ) {
                    data[i][1] = WORDS.cpu_temp;
                } else {
                    data[i][1] = WORDS.sys_temp + st++;
                }
                var temp = Number(data[i][2].match(/[0-9]*/)[0]);
                data[i][2] = String.format('{0} °C / {1} °F', temp, Math.floor(temp * (9/5) + 32));
            } else {
                data[i][1] = WORDS[id.toLowerCase()] || id;
            }
        }
        this.monitors = this.monitors || {};
        var store = this.getStore();
        store.loadData(data, false);
        store.filterBy(function(record){
            return this.monitors[record.data['g']];
        }, this);
        delete store;
        delete data;
    }
});
TCode.Status.DropSource = Ext.extend(Ext.dd.DragSource, {
    afterDragDrop: function(target, e, id) {
        if( this.id == target.id ) return;
        
        /**
         * Sawp source and target elements.
         */
        
        var sEl = Ext.get(this.id),
            dEl = Ext.get(target.id);
        
        var sp = sEl.prev(),
            spp = sEl.parent(),
            dp = dEl.prev(),
            dpp = dEl.parent();
        
        sp == null ? spp.insertFirst(dEl) : dEl.insertAfter(sp);
        dp == null ? dpp.insertFirst(sEl) : sEl.insertAfter(dp);
    }
});
TCode.Status.Menu = Ext.extend(Ext.menu.Menu, {
    constructor: function(monitors, handler, scope) {
        this.items = [];
        for( var m in Monitors ) {
            this.items.push({
                scope: scope,
                id: m,
                text: WORDS[m.toLowerCase()] || m,
                checked: monitors[m] ? true : false,
                handler: handler
            });
        }
        
        TCode.Status.Menu.superclass.constructor.call(this);
    }
});
TCode.Status.Widget = Ext.extend(Ext.Panel, {
    constructor: function(config) {
        var configure = TCode.Status.Save.layouts[config.si] || {};
        this.mode = configure.mode || '';
        this.monitors = configure.monitors || {};
        
        var s = TCode.desktop.Group.body.getSize();
        var config = config || {};
        Ext.applyIf(config, {
            frame: true,
            border: false,
            layout: 'card',
            width: s.width / 2,
            height: (s.height - 28)/2,
            activeItem: this.mode == 'Graphic' ? 0 : 1
        });
        
        TCode.Status.Widget.superclass.constructor.call(this, config);
        
        delete config;
        delete s;
        delete configure;
    },
    initComponent: function() {
        this.tbar = new Ext.Toolbar({
            disabled: TCode.Status.Save.locked,
            items: [
                {
                    xtype: 'button',
                    iconCls: 'GraphicBtn',
                    text: WORDS.graphic_mode,
                    scope: this,
                    disabled: /Graphic|OnlyDetail/.test(this.mode),
                    handler: function() {
                        this.getTopToolbar().items.get(0).disable();
                        this.getTopToolbar().items.get(1).enable();
                        this.mode = 'Graphic';
                        this.layout.setActiveItem(0);
                        this.items.get(0).show();
                    }
                },
                {
                    xtype: 'button',
                    iconCls: 'DetailBtn',
                    text: WORDS.detail_mode,
                    scope: this,
                    disabled: /.*Detail/.test(this.mode),
                    handler: function() {
                        this.getTopToolbar().items.get(0).enable();
                        this.getTopToolbar().items.get(1).disable();
                        this.mode = 'Detail';
                        this.layout.setActiveItem(1);
                        this.items.get(1).show();
                    }
                },
                '-',
                {
                    text: WORDS.monitors,
                    iconCls: 'MonitorBtn',
                    menu: new TCode.Status.Menu(this.monitors, this.setMonitor, this)
                }
            ]
        });
        
        this.items = [
            new TCode.Status.Graphic({
                hidden: this.mode != 'Graphic',
                si: this.si
            }),
            new TCode.Status.Detail({
                hidden: this.mode != 'Detail',
                si: this.si
            })
        ];
        
        TCode.Status.Widget.superclass.initComponent.call(this);
    },
    listeners: {
        render: function() {
            new TCode.Status.DropSource(this.id, { group: 'dd' });
            new Ext.dd.DDTarget(this.id, 'dd');
            
            Ext.getCmp('SysContainer').on('updated', this.update, this);
        },
        beforeDestroy: function() {
            this.ownerCt.un('bodyresize', this.resize, this);
        }
    },
    getConfigure: function() {
        return {
            mode: this.mode,
            monitor: this.monitors
        }
    },
    setMonitor: function(c) {
        if( !c.checked ) {
            this.monitors[c.id] = true;
            this.items.get(0).addSeries(c.id);
            this.items.get(1).addMonitor(c.id);
        } else {
            delete this.monitors[c.id];
            this.items.get(0).delSeries(c.id);
            this.items.get(1).delMonitor(c.id);
        }
    },
    update: function(data) {
        if( this.mode == 'Graphic' ){
            this.items.get(0).update(data.series);
        } else {
            this.items.get(1).update(data.gdata);
        }
        
        delete data;
    }
});

TCode.Status.History = Ext.extend(Ext.Window, {
    title: WORDS.history,
    height: 400,
    width: 600,
    id: 'SysHistory',
    resizable: false,
    modal: true,
    border: false,
    format: '48',
    initComponent: function() {
        this.ajax = {
            url: 'getmain.php',
            params: {
                fun: 'monitor',
                action: 'history'
            },
            scope: this,
            success: this.success,
            failure: this.failure
        };
        
        this.tbar = [
            {
                xtype: 'button',
                text : WORDS.last12months,
                scope: this,
                handler: this.queryLast12Months
            },
            {
                xtype: 'button',
                text : WORDS.last30days,
                scope: this,
                handler: this.queryLast30Days
            },
            {
                xtype: 'button',
                text : WORDS.last48hours,
                scope: this,
                handler: this.queryLast48Hours
            },
            '->',
            {
                xtype: 'button',
                text : WORDS.reset_history,
                scope: this,
                handler: this.resetData
            }
        ];
        
        this.items = [
            {
                id: 'SysHistoryGraphic',
                autoEl: {
                    tag: 'div'
                },
                parent: this,
                listeners: {
                    render: this.initGraphic
                }
            }
        ];
        
        TCode.Status.History.superclass.initComponent.call(this);
    },
    initGraphic: function() {
        this.parent.chart = new Highcharts.Chart({
            chart: {
                renderTo: 'SysHistoryGraphic',
                reflow: false,
                animation: true,
                showAxes: true,
                width: 588,
                height: 345
            },
            title: {
                text: null
            },
            credits: {
                enabled: false
            },
            tooltip: {
                shared: true,
                crosshairs: true,
                formatter: function() {
                    var time = (new Date(this.x).toUTCString()).match(/^.*, (.*) (.*) .* (.*):.*$/);
                    time[2] = time[2].toLowerCase();
                    var s;
                    switch(Ext.getCmp('SysHistory').format) {
                    case '12':
                        s = String.format('<b>{0}: {1}</b><br/>', WORDS.month, WORDS[time[2]]);
                        break;
                    case '30':
                        s = String.format('<b>{0}: {1}/{2}</b><br/>', WORDS.date, WORDS[time[2]], Number(time[1]));
                        break;
                    case '48':
                        s = String.format('<b>{0}: {1}/{2} {3}</b><br/>', WORDS.time, WORDS[time[2]], Number(time[1]), time[3]);
                        break;
                    }
                    
                    $.each(this.points, function(i, point) {
                        if( /^CPU$/.test(point.series.name) || /^MEM$/.test(point.series.name) ) {
                            s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + ' %</span><br/>';
                        } else if( /.*_FAN.*/.test(point.series.name) ) {
                            s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + ' RPM</span><br/>';
                        } else if( /.*(WAN|LAN|LINK).*/.test(point.series.name) ) {
                            s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + ' MB/s</span><br/>';
                        } else if( /.* TEMP.*/.test(point.series.name) ) {
                            s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + ' °C / ' + Math.floor(point.y * (9/5) + 32) + ' °F</span><br/>';
                        } else {
                            s += '<span style="color:' + point.series.color + ';">' + point.series.name + ': ' + point.y + '</span><br/>';
                        }
                    });
                    
                    return s;
                }
            },
            legend: {
                borderWidth: 0
            },
            plotOptions: {
                column: {
                    zIndex: 1
                },
                spline: {
                    zIndex: 2
                }
            },
            xAxis: {
                type: 'datetime',
                labels: {
                    formatter: function() {
                        var time = (new Date(this.value).toUTCString()).match(/^.*, (.*) (.*) .* (.*):.*$/);
                        time[2] = time[2].toLowerCase();
                        switch(Ext.getCmp('SysHistory').format) {
                        case '12':
                            return WORDS[time[2]];
                        case '30':
                            return WORDS[time[2]] + '/' + Number(time[1]);
                        case '48':
                            return time[3];
                        }
                    }
                }
            },
            yAxis: [
                {
                    min: 0,
                    labels: {
                        formatter: function() {
                            return this.value + ' %'
                        }
                    },
                    title: {
                        text: ''
                    }
                },
                {
                    min: 0,
                    opposite: true,
                    labels: {
                        formatter: function() {
                            return this.value + ' MB/s'
                        }
                    },
                    title: {
                        text: ''
                    }
                }
            ]
        });
        
        this.parent.makeUpdateAjax();
    },
    onShow: function() {
        TCode.Status.History.superclass.call(this);
        this.makeUpdateAjax();
    },
    queryLast12Months: function() {
        this.format = '12';
        this.ajax.url = 'getmain.php';
        this.ajax.params.fun = 'monitor';
        this.ajax.params.params = 'm';
        Ext.Ajax.request(this.ajax);
    },
    queryLast30Days: function() {
        this.format = '30';
        this.ajax.url = 'getmain.php';
        this.ajax.params.fun = 'monitor';
        this.ajax.params.params = 'd';
        Ext.Ajax.request(this.ajax);
    },
    queryLast48Hours: function() {
        this.format = '48';
        this.ajax.url = 'getmain.php';
        this.ajax.params.fun = 'monitor';
        this.ajax.params.params = 'h';
        Ext.Ajax.request(this.ajax);
    },
    resetData: function() {
        Ext.Msg.show({
            title: WORDS.attention,
            msg: WORDS.reset_message,
            minWidth: 300,
            buttons: Ext.MessageBox.YESNO,
            scope: this,
            fn: function(btn) {
                if( btn == 'yes' ) {
                    this.ajax.url = 'setmain.php';
                    this.ajax.params.fun = 'setmonitor';
                    this.ajax.params.params = 'reset';
                    Ext.Ajax.request(this.ajax);
                }
            }
        })
    },
    makeUpdateAjax: function() {
        Ext.Ajax.request(this.ajax);
    },
    success: function(response, opts) {
        while( this.chart.series.length > 0 ) {
            this.chart.series[0].remove();
        }
        
        if( response.responseText == '' ) {
            return;
        }
        
        var data = Ext.decode(response.responseText);
        
        for( var k in data ){
            var tmp;
            if( /^(g?eth.*|bond.*)_[tr]x$/.test(k) ) {
                tmp = k.match(/^(g?eth.*|bond.*)_([tr]x)$/);
                tmp = TCode.Status.Nic[tmp[1]] + ' ' + tmp[2];
            } else {
                tmp = k;
            }
            this.chart.addSeries({
                yAxis: k == "CPU" || k == "MEM" ? 0 : 1,
                type: 'spline',
                name: tmp,
                data: data[k]
            });
        }
        
        delete data;
        delete response;
        delete opts;
    },
    failure: function(response, opts) {
    }
});

TCode.Status.Container = Ext.extend(Ext.FormPanel, {
    constructor: function(config) {
        config = config || {};
        
        Ext.applyIf(config, {
            border: false,
            layout: 'column',
            autoScroll: false
        });
        
        delete hs;
        delete cs;
        
        TCode.Status.Container.superclass.constructor.call(this, config);
        
        this.addEvents('updated');
    },
    initComponent: function() {
        this.tbar = [
            {
                xtype: 'button',
                iconCls: 'SaveBtn',
                text: WORDS.save_layout,
                scope: this,
                handler: this.save
            },
            {
                text: WORDS.reset_layout,
                iconCls: 'ResetBtn',
                scope: this,
                disabled: TCode.Status.Save.locked,
                handler: this.reset
            },
            '-',
            {
                xtype: 'checkbox',
                checked: '<{$saveHistory}>' == '1',
                disabled: '<{$hasRaid}>' != '1',
                scope: this,
                width: 'auto',
                handler: this.saveHistory
            },
            {
                text: WORDS.history,
                iconCls: 'HistoryBtn',
                scope: this,    
                disabled: '<{$saveHistory}>' != '1' || '<{$hasHistory}>' != '1',
                handler: this.history
            },
            '-',
            {
                id: 'SysLock',
                iconCls: TCode.Status.Save.locked ? 'LockBtn' : 'UnLockBtn',
                text: WORDS.lock_layout,
                scope: this,
                handler: this.locked
            },
            '->',
            {
                xtype: 'label',
                text: WORDS.UPTime + ': '
            },
            {
                id: 'SysUptime',
                xtype: 'label'
            }
        ]
        
        this.items = [
            {
                columnWidth: .5,
                autoHeight: true,
                items: [
                    new TCode.Status.Widget({id:'Widget0', si: 0}),
                    new TCode.Status.Widget({id:'Widget2', si: 2})
                ]
            },
            {
                columnWidth: .5,
                autoHeight: true,
                items: [
                    new TCode.Status.Widget({id:'Widget1', si: 1}),
                    new TCode.Status.Widget({id:'Widget3', si: 3})
                ]
            }
        ];
        
        TCode.Status.Container.superclass.initComponent.call(this);
    },
    listeners: {
        render: function() {
            this.autoRefresh(10000);
        },
        afterLayout: function() {
            
        },
        beforedestroy: function() {
            this.autoRefresh(0);
            
            delete TCode.Status;
            delete WORDS;
        }
    },
    delayResize: function(c) {
        clearTimeout(this.delay || 0);
        this.delay = setTimeout(function(c){
            c = c || Ext.getCmp('SysContainer');
            c.resize();
        }, 100, this);
    },
    autoRefresh: function(time) {
        time = time || 0;
        this.task = this.task || {};
        
        if( this.task.taskStartTime ) {
            Ext.TaskMgr.stop(this.task);
        }
        
        if( typeof(time) == 'number' && time > 0 ) {
            this.task = {
                scope: this,
                interval: time,
                run: this.makeUpdateAjax
            }
            
            Ext.TaskMgr.start(this.task);
        }
    },
    makeUpdateAjax: function() {
        var ajax = {
            url: 'getmain.php',
            params: {
                fun: 'monitor',
                action: 'update'
            },
            scope: this,
            success: this.success,
            failure: this.failure
        }
        
        Ext.Ajax.request(ajax);
        
        delete ajax;
    },
    success: function(response, opts) {
        var data = Ext.decode(response.responseText);
        
        this.fireEvent('updated', data);
        
        data.uptime['Days'] = data.uptime['Days'] > 1 ? data.uptime['Days'] + ' <{$gwords.days}>' : data.uptime['Days'] + ' <{$gwords.day}>';
        data.uptime['Hours'] = data.uptime['Hours'] > 1 ? data.uptime['Hours'] + ' <{$gwords.hours}>' : data.uptime['Hours'] + ' <{$gwords.hour}>';
        data.uptime['Min'] = data.uptime['Min'] > 1 ? data.uptime['Min'] + ' <{$gwords.minutes}>' : data.uptime['Min'] + ' <{$gwords.minute}>';
        
        var uptime = '　' + data.uptime['Days'] + ' ' + data.uptime['Hours'] + ' ' + data.uptime['Min'];
        Ext.getCmp('SysUptime').setText(uptime);
        
        delete data;
    },
    failure: function(response, opts) {
    },
    makeSaveAjax: function() {
        var ajax = {
            url: 'setmain.php',
            params: {
                fun: 'setmonitor',
                action: 'save',
                layout: Ext.util.JSON.encode(TCode.Status.Save)
            },
            scope: this,
            success: this.saveSuccess,
            failure: this.saveFailure
        }
        
        Ext.Ajax.request(ajax);
        
        delete ajax;
    },
    saveSuccess: function(response, opts) {
        Ext.Msg.alert(WORDS.save_layout_title,WORDS.save_success);
    },
    saveFailure: function(response, opts) {
    },
    save: function() {
        var col = [
            this.items.get(0),
            this.items.get(1)
        ];
        
        var ws = [
            Ext.getCmp(col[0].body.dom.childNodes[0].id),
            Ext.getCmp(col[1].body.dom.childNodes[0].id),
            Ext.getCmp(col[0].body.dom.childNodes[1].id),
            Ext.getCmp(col[1].body.dom.childNodes[1].id)
        ];
        
        for(var i = 0 ; i < ws.length ; i++ ) {
            delete TCode.Status.Save.layouts[i].mode;
            TCode.Status.Save.layouts[i].mode = ws[i].mode;
            delete TCode.Status.Save.layouts[i].monitors;
            TCode.Status.Save.layouts[i].monitors = ws[i].monitors;
        }
        
        delete ws;
        delete col;
        
        this.makeSaveAjax();
    },
    locked: function() {
        TCode.Status.Save.locked = !TCode.Status.Save.locked;
        var b = TCode.Status.Save.locked;
        
        if(b) {
            Ext.getCmp('SysLock').setIconClass('LockBtn');
        } else {
            Ext.getCmp('SysLock').setIconClass('UnLockBtn');
        }
        
        for(var i = 0 ; i < 4 ; ++i) {
            with(Ext.getCmp('Widget'+i)){
                getTopToolbar().setDisabled(b)
                getTopToolbar().items.get(0).setDisabled(b || mode == 'Graphic')
                getTopToolbar().items.get(1).setDisabled(b || mode == 'Detail')
            }
        }
        
        with(this.getTopToolbar().items) {
            get(1).setDisabled(b)
        };
        
        b ? Ext.dd.DragDropMgr.lock() : Ext.dd.DragDropMgr.unlock();
        delete b;
    },
    reset: function() {
        Ext.Msg.show({
            title:WORDS.reset_layout_title,
            msg: WORDS.reset_confirm,
            buttons: Ext.Msg.YESNO,
            scope: this,
            fn: this.confirmReset,
            animEl: 'elId',
            icon: Ext.MessageBox.QUESTION
         });
    },
    confirmReset: function(confirm) {
        if( confirm == "yes" ) {
            var ajax = {
                url: 'setmain.php',
                params: {
                    fun: 'setmonitor',
                    action: 'reset'
                },
                scope: this,
                success: this.resetSuccess,
                failure: this.resetFailure
            };
            
            Ext.Ajax.request(ajax);
            
            delete ajax;
        }
    },
    resetSuccess: function() {
        processUpdater('getmain.php', 'fun=monitor');
    },
    resetFailure: function() {
        
    },
    saveHistory: function(checkbox, value) {
        if( value == true ) {
            Ext.Msg.confirm(WORDS.attention, WORDS.save_history, this.confirmHistory, this);
        } else {
            var ajax = {
                url: 'setmain.php',
                params: {
                    fun: 'setmonitor',
                    action: 'saveHistory',
                    params: '0'
                }
            };
            
            Ext.Ajax.request(ajax);
            with(this.getTopToolbar().items) {
                get(4).setDisabled(true)
            };
        }
    },
    confirmHistory: function(btn) {
        var check;
        if( btn == 'yes') {
            check = true;
            var ajax = {
                url: 'setmain.php',
                params: {
                    fun: 'setmonitor',
                    action: 'saveHistory',
                    params: '1'
                }
            };
            
            Ext.Ajax.request(ajax);
        } else {
            check = false;
        }
        with(this.getTopToolbar().items) {
            get(3).setValue(check)
            get(4).setDisabled(!check)
        };
    },
    history: function() {
        (new TCode.Status.History).show();
    }
});
Ext.reg('TCode.Status.Container', TCode.Status.Container);

/**
 * Initial global enviroment.
 */
Ext.onReady(function(){
    Ext.QuickTips.init();
    
    TCode.desktop.Group.addComponent({xtype: 'TCode.Status.Container', id: 'SysContainer'});
    
    if(TCode.Status.Save.locked)
        Ext.dd.DragDropMgr.lock();
});
</script>
