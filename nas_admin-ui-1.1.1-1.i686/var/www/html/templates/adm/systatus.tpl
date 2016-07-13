<div ID='DomStatus'><div>

<script type="text/javascript">

WORDS = <{$words}>;
Ext.ns('TCode.Status');
TCode.Status.Nic = <{$nic}>;

TCode.Status.Detail = function(title, content) {
    content = content || [];
    
    var self = this;
    
    var tpl = new Ext.XTemplate(
        '<table width="500px">',
            '<tpl for=".">',
                '<tr height="24">',
                    '<td NOWRAP class="notepad" width="150px">{key}:</td>',
                    '<td NOWRAP class="notepad {css}">{value}</td>',
                '</tr>',
            '</tpl>',
        '</table>'
    );
    
    store = new Ext.data.JsonStore({
        fields: [ 'key', 'value', 'css' ]
    });
    store.loadData(content);
    self.store = store;
    
    var config = {
        title: title,
        autoHeight: true,
        bodyStyle: 'background: transparent;',
        items: new Ext.DataView({
            store: store,
            tpl: tpl,
            autoHeight: true,
            multiSelect: true,
            overClass: 'x-view-over',
            itemSelector: 'div.thumb-wrap',
            emptyText: 'No images to display'
        })
    }
    
    TCode.Status.Detail.superclass.constructor.call(self, config);
}
Ext.extend(TCode.Status.Detail, Ext.Panel);

TCode.Status.Container = function() {
    var self = this;
    
    var ajax = new TCode.ux.Ajax('setstatus', ['update']);
    var monitor = {
        scope: self,
        interval: 10000,
        run: monitorStatus
    };
    
    var config = {
        autoWidth: true,
        renderTo: 'DomStatus',
        plain: true,
        activeItem: 0,
        layoutOnTabChange: true,
        border: false,
        bodyStyle: 'background: transparent;',
        style: 'margin: 10px;',
        autoHeight: true,
        listeners: {
            render: onRender,
            beforedestroy: onDestroy
        }
    }
    
    function onRender() {
        Ext.TaskMgr.start(monitor);
    }
    
    function onDestroy() {
        Ext.TaskMgr.stop(monitor);
    }
    
    function monitorStatus() {
        ajax.update(onUpdate);
    }
    
    function modifyData(data) {
        for( var i = 0 ; i < data.length ; ++i ) {
            var rs = data[i];
            var key = rs['key'];
            if( WORDS[key] ) {
                rs['key'] = WORDS[key];
            } else if( TCode.Status.Nic[key] ) {
                rs['key'] = TCode.Status.Nic[key];
            } else if( (match = key.match(/(.*_fan) ?(.*)/)) ) {
                rs['key'] = WORDS[match[1]] + match[2];
            } else if( (match = key.match(/(.*_temp) ?(.*)/)) ) {
                rs['key'] = WORDS[match[1]] + match[2];
            }
            if( WORDS[rs['value']] ) {
                rs['value'] = WORDS[rs['value']];
            }
        }
    }
    
    function onUpdate(data) {
        if( self.items.length == 0 ) {
            for( var i = 0 ; i < data.length ; ++i ) {
                if ('<{$monitor_flag}>'=='0' && i>0 ) {
                    continue;
                } else {
                    modifyData(data[i]['value']);
                    var title = WORDS[data[i]['key']] ? WORDS[data[i]['key']] : data[i]['key'];
                    self.add(new TCode.Status.Detail(title, data[i]['value']));
                }
            }
            self.setActiveTab(0);
        } else {
            for( var i = 0 ; i < data.length ; ++i ) {
                modifyData(data[i]['value']);
                self.items.get(i).store.loadData(data[i]['value']);
            }
        }
    }
    
    TCode.Status.Container.superclass.constructor.call(self, config);
}
Ext.extend(TCode.Status.Container, Ext.TabPanel);

Ext.onReady(function(){
    TCode.desktop.Group.addComponent(new TCode.Status.Container());
})
</script>
