<script type="text/javascript">

WORDS = <{$words}>;
Ext.ns('TCode.General');

TCode.General.DiskFail = <{$fail_disk_flag}>;
TCode.General.DiskFailStr = <{$fail_disk}>;
TCode.General.Device = <{$device}>;

TCode.General.Detail = function(content) {
    content = content || [];
    
    var self = this;
    var title = '';
    
    var tpl = new Ext.XTemplate(
        '<table>',
            '<tpl for=".">',
                '<tr height="24">',
                    '<td NOWRAP width="150px">{key}:</td>',
                    '<td NOWRAP>{value}</td>',
                '</tr>',
            '</tpl>',
        '</table>'
    );
    
    var store = new Ext.data.JsonStore({
        fields: [ 'key', 'value' ]
    });
    
    for( var i = 0 ; i < content.length ; ++i ) {
        if( content[i]['key'] == 'product_no' ) {
            title = content[i]['value'];
        }
        if( content[i]['key'] == 'position' ) {
            title = String.format('{0} - {1}',title, content[i]['value']);
        }
        content[i]['key'] = WORDS[content[i]['key']];
    }
    
    store.loadData(content);
    
    var config = {
        title: title,
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
    
    TCode.General.Detail.superclass.constructor.call(self, config);
}
Ext.extend(TCode.General.Detail, Ext.Panel);

TCode.General.Container = function() {
    var self = this;
    var items = [];
    
    for( var i = 0 ; i < TCode.General.Device.length ; ++i ) {
        var device = TCode.General.Device[i];
        items.push(new TCode.General.Detail(device));
    }
    
    var config = {
        autoWidth: true,
        autoHeight: true,
        plain: true,
        activeItem: 0,
        layoutOnTabChange: true,
        border: false,
        bodyStyle: 'background: transparent;',
        style: 'margin: 10px;',
        items: items
    }
    
    TCode.General.Container.superclass.constructor.call(self, config);
}
Ext.extend(TCode.General.Container, Ext.TabPanel);

Ext.onReady(function(){
    if( TCode.General.DiskFail ) {
        Ext.Msg.show({
            title: WORDS['words.step_title'],
            msg: String.format(
                '{0}<br>{1}{2}<br>{3} {4}<br>{5}',
                WORDS['damage_error'],
                WORDS['damage_msg1'],
                WORDS['damage_word'],
                TCode.General.DiskFailStr,
                WORDS['damage_fail'],
                WORDS['damage_msg2']
            ),
            buttons: Ext.Msg.OK,
            icon: Ext.MessageBox.ERROR,
            fn: function( btn ){
                if( btn == 'ok' ){
                    setCurrentPage('reboot');
                    processUpdater("getmain.php","fun=reboot");
                }
            }
        });
    } else {
        TCode.desktop.Group.addComponent(new TCode.General.Container());
    }
})
</script>
