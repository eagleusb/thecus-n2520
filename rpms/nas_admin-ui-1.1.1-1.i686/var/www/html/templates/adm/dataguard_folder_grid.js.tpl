TCode.DataGuard.FolderGrid = function(config) {
    var self = this,
        dev = '',
        model = '',
        mode = 'radio',
        chooseRoot = false,
        enterSubfolder = true,
        ajax = TCode.DataGuard.Ajax,
        base = '/raid0/data',
        currentPath = [''],
        boxs = [],
        choose = {},
        chooseUuid = {},
        devFilter = {},
        gridIndex = '0',
        selected = {};
        
    config = config || {};
    
    config = Ext.apply(config, {
        hideHeaders: true,
        disableSelection: true,
        height: 310,
        viewConfig: {
            autoFill: true,
            forceFit: true
        },
        store: new Ext.data.JsonStore({
            fields: ['dev', 'model', 'uuid', 'type', 'path', 'name']
        }),
        columns: [
            {
                header: WORDS['folder_name'],
                dataIndex: 'name',
                renderer: nameColumnRenderer
            }
        ],
        tbar: [
            config.title || '',
            '->',
            {
                xtype: 'checkbox',
                boxLabel: 'Select All',
                listeners: {
                    check: onSelectAll
                }
            },
            ' '
        ]
    });
    delete config.title;
    
    function nameColumnRenderer(value, dom, r, row, gridIndex, store) {
        if( value == '..' ) {
            var path = (r.data.abs_path == "") ? "/" : r.data.abs_path;
            path = r.data.path.replace(/</g, '&lt;');
            return String.format('<div ext:qtip="{0}" class="parent" style="background:no-repeat;text-indent:25px;line-height:25px;">{1}</div>', path, WORDS['parent_folder']);
        }
        
        var domId = Ext.id();
        createFolder.defer(
            1,
            self,
            [domId, self.id + "_Path", r.data]
        );
        return String.format('<div id="{0}"/>', domId);
    }
    
    function createFolder(dom, id, data) {
        var label = data.name || data.model;
        label = label.replace(/</g, '&lt;');
        var checked = (dev == '') ? choose[data.dev+':'+label] : choose[label];
        new Ext.Template(
            '<table>',
                '<tbody>',
                    '<tr>',
                        '<td style="width:30px"><div id="{0}_img" style="margin-left:5px;"></td>',
                        '<td nowrap><div id="{0}_box"></td>',
                    '</tr>',
                '</tbody>',
            '</table>'
        ).append(dom, [dom], true);
        
        new Ext.BoxComponent({
            xtype: 'box',
            renderTo: dom + "_img",
            autoEl: {
                tag: 'img',
                src: '../theme/images/index/dataguard/' + data.type +'.png'
            }
        });
        
        var box = (mode == 'radio') ? Ext.form.Radio : Ext.form.Checkbox;
        if(currentPath.join('') == '' && !chooseRoot){
            var box = Ext.form.Label;
        }
        
        var field = new box({
            data: data,
            renderTo: dom + "_box",
            boxLabel: Ext.util.Format.ellipsis(label, 15),
            name: 'item' + gridIndex,
            html: label,
            autoHeight: true,
            path: label,
            checked: checked,
            listeners: {
                render: onItemRender,
                check: onItemChoose
            }
        });
        
        if( currentPath == '' && !chooseRoot) {
            label = field.el;
        } else {
            label = field.wrap.child('label');
        }
        
        label.data = data;
        if(enterSubfolder){
            label.on('click', onLabelDblClick);
        }
        
        Ext.QuickTips.register({
            target: label.id,
            text: data.name.replace(/</g, '&lt;') || data.model
        })
        
        if( selected[label] ) {
            onItemChoose(field, true);
        }
    }
    
    function onItemRender(checkbox) {
        boxs.push(checkbox);
    }
    
    function onSelectAll(checkbox, checked) {
        for( var i = 0 ; i < boxs.length ; ++i ) {
            boxs[i].setValue(checked);
        }
    }
    
    function onLabelDblClick() {
        dev = this.data.dev;
        model = this.data.model;
        currentPath = this.data.path.split('/');
        
        delete selected;
        selected = {};
        
        delete choose;
        choose = {};
        
        load();
        
        delete chooseUuid;
        chooseUuid = {};
    }
    
    function onItemChoose(field, checked) {
        var folder = field.data.name || field.data.model;
        var uuid = field.data.uuid;
        model = field.data.model;
        if( dev == '' ) {
            folder = String.format('{0}:{1}',field.data.dev, folder );
        }
        
        if( checked == true ) {
            choose[folder] = true;
            chooseUuid[folder] = uuid;
        } else {
            delete choose[folder];
            delete chooseUuid[folder];
        }
        
        self.fireEvent('selected', dev, model, choose_uuid_array(dev), currentPath.join('/'), choose_array());
    }
    
    function onChangePath(grid, index, e) {
        if(enterSubfolder){
            var rs = self.store.getAt(index);
            dev = rs.data.dev;
            model = rs.data.model;
            currentPath = rs.data.path.split('/');
            
            delete selected;
            selected = {};
            
            load();
            
            delete choose;
            choose = {};
            
            delete chooseUuid;
            chooseUuid = {};
        }
    }

    function load() {
        if( mode == 'radio' || ( !chooseRoot && currentPath.join('') == '' )){
            self.topToolbar.items.get(2).hide();
        }else{
            self.topToolbar.items.get(2).show();
        }
        
        for( var i = 0 ; i < boxs.length ; ++i ) {
            boxs[i].destroy();
        }
        boxs.splice(0, boxs.length);
        self.topToolbar.items.get(2).setValue(false);
        self.store.removeAll();

        ajax.ListFolder(dev, currentPath.join('/'), axListFolder);
        self.fireEvent('selected', dev, model, choose_uuid_array(dev), currentPath.join('/'), choose_array());
    }
    
    function choose_uuid_array(d) {
        var tmp = [];
        for(var c in chooseUuid ) {
            tmp.push(chooseUuid[c]);
        }
        
        if( d == '' ){
            tmp = tmp.join("/");
            return tmp;
        }else{
            return tmp[0];
        }
        
    }
    
    function choose_array() {
        var tmp = [];
        for(var c in choose ) {
            tmp.push(c);
        }
        tmp = tmp.join("/");
        return tmp;
    }
    this.getSelected = choose_array;
    
    function getPath() {
        return currentPath.join('/');
    }
    self.getPath = getPath;
    
    function getDevice() {
        return dev;
    }
    self.getDevice = getDevice;
    
    function getModel() {
        return model;
    }
    self.getModel = getModel;
    
    self.loadPath = function( device, path, oldModel, selectRoot, toSubfolder, multi, devDisplay, s, u, i) {
        chooseRoot = selectRoot;
        enterSubfolder = toSubfolder;
        devFilter = devDisplay;
        gridIndex = i;
        model = oldModel;
        
        self.on('rowclick', onChangePath);
        
        s = s || [];
        if( s.length == 1 && s[0] == '' ) {
            delete s;
            s = [];
        }
        delete choose;
        choose = {};
        for( var i = 0 ; i < s.length ; ++i ) {
            choose[s[i]] = true;
        }
        
        u = u || [];
        if( u.length == 1 && u[0] == '' ) {
            delete u;
            u = [];
        }
        delete chooseUuid;
        chooseUuid = {};
        for( var i = 0 ; i < u.length ; ++i ) {
            chooseUuid[s[i]] = u[i];
        }
        
        dev = device;
        
        path = path || '/';
        if( path == '/') {
            delete currentPath ;
            currentPath = [''];
        } else {
            currentPath = path.split('/');
        }
        if( multi == true ) {
            mode = 'checkbox';
        } else {
            mode = 'radio';
        }
        load();
    }
    
    function axListFolder(code, list) {
        var filter = [];
        for( i = 0 ; i < list.length ; ++i ) {
            if( list[i].name == '..' ){
                filter.push(list[i]);
                continue;
            }
            
            if( /^e?md[0-9]*$/.test(list[i].dev) ) {
                if( devFilter['raid'] ) {
                    filter.push(list[i]);
                }
            } else if( /^stack_/.test(list[i].dev) ){
                if( devFilter['stack'] ) {
                    filter.push(list[i]);
                }
            }else  if ( /^iscsi_/.test(list[i].dev) ) {
                if( devFilter['iscsi'] ) {
                    filter.push(list[i]);
                }
            } else {
                if( devFilter['external'] ) {
                    if(gridIndex == 1){
                        if(!/^sr/.test(list[i].dev)){
                            filter.push(list[i]);
                        }
                    }else{
                        filter.push(list[i]);
                    }
                }
            }
        }
        self.store.loadData(filter);
    }
    
    Ext.grid.GridPanel.superclass.constructor.call(self, config);
    
    self.addEvents(['selected']);
}
Ext.extend(TCode.DataGuard.FolderGrid, Ext.grid.GridPanel);
