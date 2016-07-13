
Ext.ns('TCode.ux');

Ext.override(Ext.ToolTip, {
    onTargetOver : function(e){
        if(this.disabled){
            return;
        }
        this.clearTimer('hide');
        this.mouseTarget = e.getTarget();
        this.targetXY = e.getXY();
        this.delayShow();
    }
});

TCode.ux.Disk = function(c) {
    var self = this;
    var listDisk = null;
    
    var ajax = new TCode.ux.Ajax(
        'disks',
        ['listAll']
    );
    
    var words = TCode.ux.WORDS;
    
    // Check default configure
    c = Ext.applyIf(c, {
        spare: false,
        hot_spare: false,
        used: false,
        disableSelection: true,
        width: 700,
        height: 320,
        frame: true
    });
    
    // Grid columns
    var gridColumns = [
        {dataIndex: 'product_no', header: words.product_no},
        {dataIndex: 'product_name', header: words.product_name, hidden: true},
        {dataIndex: 'total_tray', hidden: true},
        {dataIndex: 'column', hidden: true},
        {dataIndex: 'rotation', hidden: true},
        {dataIndex: 'ignore', hidden: true},
        // Disk detail information
        {dataIndex: 'disk_no', header: words.disk_slot, width: 40, renderer: onDiskRenderer},
        {dataIndex: 'tray_no', hidden: true},
        {dataIndex: 'disk_name', header: words.model},
        {dataIndex: 'Serial', hidden: true},
        {dataIndex: 'size', header: words.capacity},
        {dataIndex: 'link', header: words.linkrate, hidden: true},
        {dataIndex: 'fw', header: words.fw, hidden: (c.used || c.spare || c.hot_spare)},
        {dataIndex: 'status', header: words.badblock, renderer: onStatusRenderer},
        {dataIndex: 'partition_no', hidden: true}
    ];
    
    if( c.used ) {
        gridColumns.push({
            dataIndex: 'used',
            header: words.used,
            width: 40,
            renderer: c.used ? usedBoxRenderer : undefined
        });
    }
    
    if( c.spare ) {
        gridColumns.push({
            dataIndex: 'spare',
            header: words.spare,
            width: 40,
            renderer: c.spare ? spareBoxRenderer : undefined
        });
    }
    
    if( c.hot_spare ) {
        gridColumns.push({
            dataIndex: 'hot_spare',
            header: words.hot_spare,
            width: 40,
            renderer: c.hot_spare ? hotBoxRenderer : undefined
        });
    }
    // Constant model info columns
    var modelFields = 6;
    
    var recordFields = [];
    var displayFields = [];
    for( var i = 0 ; i < gridColumns.length ; ++i ) {
        recordFields.push(gridColumns[i].dataIndex);
        if( gridColumns[i].header ) {
            displayFields.push(gridColumns[i]);
        }
     }
    
    // Make store
    var groupStore = new Ext.data.GroupingStore({
        groupField: 'product_no',
        sortInfo: {
            field: 'product_no',
            direction: "ASC"
        },
        reader: new Ext.data.ArrayReader(
            {}, // Non-used
            new Ext.data.Record.create(recordFields)
        )
    });
    
    var grid = {
        xtype: 'grid',
        frame: true,
        loadMask: true,
        maskDisabled: true,
        collapsible: true,
        animCollapse: false,
        store: groupStore,
        columns: displayFields,
        disableSelection: c.disableSelection,
        view: new Ext.grid.GroupingView({
            forceFit: true,
            hideGroupedColumn: true,
            groupTextTpl: '{[values.rs[0].data["product_name"]]} {[values.rs[0].data["product_no"] > 0 ? " - " + values.rs[0].data["product_no"] : ""]} ({[values.rs.length > 1 ? values.rs.length + "' + words.disks +'" : values.rs.length + "' + words.disk + '"]})'
        }),
        listeners: {
            render: onGridRender
        }
    };
    
    if( !c.disableSelection ) {
        Ext.apply(grid, {
            sm: new Ext.grid.RowSelectionModel({
                singleSelect: true
            })
        });
    }
    
    // Make configure
    var config = {
        id: c.id,
        renderTo: c.renderTo,
        layout: 'card',
        width: c.width,
        height: c.height,
        frame: c.frame,
        activeItem: 0,
        tbar: c.tbar,
        items: grid,
        listeners: c.listeners
    }
    
    function onGridRender() {
        grid = self.items.get(0);
        var tip = new Ext.ToolTip({
            title: 'Disks',
            target: grid.getView().el,
            grid: grid,
            tpl: new Ext.XTemplate(
                '<div style="border:#eeeeee solid 2px">',
                    '<tpl for="numbers">',
                        '<div class="disk_rotation_{parent.rotation} disk_xtray_{.}">&nbsp;</div>',
                        '<tpl if="xindex % parent.column == 0"><div style="clear:both"></div></tpl>',
                    '</tpl>',
                '</div>'
            ),
            listeners: {
                'beforeshow': onBeforeShowTip
            }
        });
        grid.selModel.on('rowselect', onRowSelect);
        grid.selModel.on('rowdeselect', onRowDeSelect);
    }
    
    var allocate = {
        used: {},
        spare: {},
        hot_spare: {}
    }
    var boxGroup = ['used', 'spare', 'hot_spare'];
    function onChecked(checkbox, checked) {
        if( checked == false ) {
            delete allocate[checkbox.type][checkbox.record.data.tray_no];
        } else {
            allocate[checkbox.type][checkbox.record.data.tray_no] = checkbox.record;
            for( var i = 0 ; i < boxGroup.length ; ++i ) {
                var id = checkbox.group + boxGroup[i];
                if( id != checkbox.id ) {
                    var box = Ext.getCmp(id);
                    if( box ) {
                        box.setValue(false);
                    }
                }
            }
        }
        self.fireEvent('diskAllocate', allocate);
    }
    
    function CheckboxGroup(id, record, type) {
        if( Number(record.data[type]) ) {
            allocate[type][record.data.tray_no] = record;
        }
        new Ext.form.Checkbox({
            id: id,
            renderTo: id,
            group: String.format('{0}_{1}_',self.id, record.data.tray_no),
            type: type,
            record: record,
            checked: Number(record.data[type] || 0),
            listeners: {
                check: onChecked
            }
        });
    }
    
    function onDiskRenderer(value, metadata, record, rowIndex, colIndex, store) {
        var loc = Number(record.get('product_no'));
        var pos = record.get('disk_no');
        return loc == 0 ? pos : 'J' + loc + '-' + pos;
    }
    
    function onStatusRenderer(value, metadata, record, rowIndex, colIndex, store) {
        var bad = record.data.status.bad == 0 ? '' : String.format('<font class="x-stop-text">{0}({1})</font>', words.disk_error, record.data.status.bad);
        var progress = String.format('{0} {1}%', words.disk_scanning, record.data.status.progress);
        switch(record.data.status.state){
        case 1:
            if( record.data.status.bad == 0 ) {
                return progress;
            } else {
                return String.format('{0} - {1}', bad, progress);
            }
        case 0: 
        case 2: return bad;
        }
    }
    
    function usedBoxRenderer(value, metadata, record, rowIndex, colIndex, store) {
        if( record.data.status.state == 1 ) {
            return '';
        }
        metadata.css = '';
        var type = 'used';
        var id = String.format('{0}_{1}_{2}',self.id, record.data.tray_no, type);
        if ( record.data.used != 1 ) {
            CheckboxGroup.defer(1, self, [id, record, type]);
        }
        return String.format('<div id="{0}"/>', id);
    }
    
    function spareBoxRenderer(value, metadata, record, rowIndex, colIndex, store) {
        if( record.data.status.state == 1 ) {
            return '';
        }
        metadata.css = '';
        var type = 'spare';
        var id = String.format('{0}_{1}_{2}',self.id, record.data.tray_no, type);
        if ( record.data.used != 1 ) {
            CheckboxGroup.defer(1, self, [id, record, type]);
        }
        return String.format('<div id="{0}"/>', id);
    }
    
    function hotBoxRenderer(value, metadata, record, rowIndex, colIndex, store) {
        if( record.data.status.state == 1 ) {
            return '';
        }
        metadata.css = '';
        var type = 'hot_spare';
        var id = String.format('{0}_{1}_{2}',self.id, record.data.tray_no, type);
        if ( record.data.used != 1 ) {
            CheckboxGroup.defer(1, self, [id, record, type]);
        }
        return String.format('<div id="{0}"/>', id);
    }
    
    function onBeforeShowTip(tip){
        var index = tip.grid.getView().findRowIndex(tip.mouseTarget);
        var record = tip.grid.getStore().getAt(index);
        if( Ext.isEmpty(record) === false ) {
            var numbers = [];
            var total = Number(record.data['total_tray']);
            var ignore = record.data['ignore'] || 999;
            total = ignore != 999 ? total + 1 : total;
            var buff = total / Number(record.data['column']);
            for( var i = 1 ; i <= buff ; i++ ){
                for( var j = i, a = 1; a <= Number(record.data['column']) ; j += buff, a++ ){
                    var disk_no = record.data['disk_no'];
                    if ( disk_no >= ignore ) {
                        disk_no += 1;
                    }

                    switch(record.data['rotation']){
                        case 'H', 'VR':
                            numbers.push( disk_no == j ? 1 : 0 );
                            break;
                        case 'V':
                            numbers.push( total + 1 - Number(disk_no) == j ? 1 : 0 );
                            break;
                    }
                }
            }
            var html = this.tpl.apply({
                numbers: numbers,
                column: record.data['column'],
                rotation: record.data['rotation']
            });
            tip.html = words.loading;
            tip.setTitle(words.position);
            if(tip.body){
                tip.body.update(html);
            }
        }
    }
    
    function onRowSelect(selModel, rowIndex, rs) {
        self.fireEvent('diskSelect', rs);
    }
    
    function onRowDeSelect(selModel, rowIndex, rs) {
        self.fireEvent('diskUnSelect', rs);
    }
    
    function loadData(data) {
        delete allocate.used;
        allocate.used = {};
        
        delete allocate.spare;
        allocate.spare = {};
        
        delete allocate.hot_spare;
        allocate.hot_spare = {};
        
        var store = [];
        for( var i = j = 0 ; i < data.length ; ++i ){
            var r = data[i];
            var model = [];
            // Model info processor
            for( j = 0 ; j < modelFields ; ++j ){
                var f = recordFields[j];
                model.push(r[f]);
            }
            // Disk info processor
            for( k = 0 ; k < r.disks.length ; ++k ) {
                var rs = Ext.clone([], model);
                for( j = modelFields ; j < recordFields.length ; ++j ){
                    var f = recordFields[j];
                    if ( r.disks[k]['raid_id'] != listDisk ) {
                        if ( c.used && ( Number(r.disks[k]['used'] ) || Number(r.disks[k]['spare']) || Number(r.disks[k]['hot_spare']) ) ) {
                            continue;
                        }
                        if ( c.spare && ( Number(r.disks[k]['used']) || Number(r.disks[k]['hot_spare']) ) ) {
                            continue;
                        }
                        if ( c.hot_spare && ( Number(r.disks[k]['used']) || Number(r.disks[k]['spare']) ) ) {
                            continue;
                        }
                    }
                    if ( f == 'size' && typeof r.disks[k][f] == 'string' ) {
                        rs.push(r.disks[k][f].toUpperCase());
                    } else {
                        rs.push(r.disks[k][f]);
                    }
                }
                if( rs.length > modelFields ) {
                    store.push(rs);
                }
            }
        }
        
        groupStore.loadData(store);
        delete store;
        
        self.fireEvent('diskLoaded');
    }
    
    self.load = function(data) {
        if( data ) {
            return loadData(data);
        }
        var grid = self.items.get(0);
        grid.setDisabled(true);
        ajax.listAll(function(data) {
            loadData(data);
            grid.setDisabled(false);
        });
    }
    
    self.listRaidDisk = function(id) {
        listDisk = id;
    }
    
    self.getDiskSelected = function() {
        return grid.selModel.getSelected();
    }
    
    self.getAllocate = function() {
        return allocate;
    }
    
    self.addEvents( 'diskLoaded', 'diskSelect', 'diskUnSelect', 'diskAllocate' );
    
    TCode.ux.Disk.superclass.constructor.call(self, config);
}
Ext.extend(TCode.ux.Disk, Ext.Panel);

Ext.reg('disk', TCode.ux.Disk);
