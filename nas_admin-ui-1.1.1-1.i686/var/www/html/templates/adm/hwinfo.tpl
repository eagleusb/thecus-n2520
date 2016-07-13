<div id='DomHWInfo'></div>

<script type="text/javascript">
WORDS = <{$words}>;
Ext.ns('TCode.Hardware');
TCode.Hardware.Info = <{$info}>;

TCode.Hardware.Detail = function(title, content) {
    content = content || [];
    
    var self = this;
    
    var tpl = new Ext.XTemplate(
        '<table class="" width="500px">',
            '<tpl for=".">',
                '<tr height="24">',
                    '<td NOWRAP class="notepad" width="150px">{[WORDS[values.key] || values.key]}:</td>',
                    '<td NOWRAP class="notepad">{value}</td>',
                '</tr>',
            '</tpl>',
        '</table>'
    );
    
    var store = new Ext.data.JsonStore({
        fields: [ 'key', 'value' ]
    });
    
    store.loadData(content);
    
    var config = {
        title: WORDS[title],
        style: 'padding: 2px',
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
    
    TCode.Hardware.Detail.superclass.constructor.call(self, config);
}
Ext.extend(TCode.Hardware.Detail, Ext.Panel);

TCode.Hardware.Container = function() {
    var self = this;
    var items = [];
    
    for( var cataggroy in TCode.Hardware.Info ) {
        var content = TCode.Hardware.Info[cataggroy];
        items.push(new TCode.Hardware.Detail(cataggroy, content));
    }
    
    var config = {
        renderTo: 'DomHWInfo',
        plain: true,
        activeItem: 0,
        layoutOnTabChange: true,
        bodyStyle: 'background: transparent;',
        style: 'margin: 10px;',
        border: false,
        items: items
    }
    
    TCode.Hardware.Container.superclass.constructor.call(self, config);
}
Ext.extend(TCode.Hardware.Container, Ext.TabPanel);
    
Ext.onReady(function(){
    new TCode.Hardware.Container();
});
</script>
