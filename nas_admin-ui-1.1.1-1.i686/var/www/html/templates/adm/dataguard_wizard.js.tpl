TCode.DataGuard.WizardPanelBase = Ext.extend(Ext.Panel, {
    pool: {
        rs: null
    },
    constructor: function(config) {
        TCode.DataGuard.WizardPanelBase.superclass.constructor.call(this, config);
        this.addEvents(['steps', 'btns', 'next', 'finish']);
    },
    getConfig: function() {
        return this.pool.rs;
    },
    setConfig: function(c) {
        if( this.pool.rs ) {
            delete this.pool.rs;
        }
        this.pool.rs = c;
    },
    previous: function() {
        return true;
    },
    next: function() {
        return true;
    },
    finish: function() {
        return true;
    },
    cancel: function() {
        return true;
    },
    displayLabelItem: function(el, show){
        if(show){
            el.enable().show();
            el.getEl().up('.x-form-item').setDisplayed(true); // show label
        }else{
            el.disable().hide();
            el.getEl().up('.x-form-item').setDisplayed(false); // hide label
        }
    }
})

TCode.DataGuard.BackupTypePanel = function(c) {
    var self = this;
    var s3 = <{$amazon_s3}>;
    if (s3 == 0){
       s3 = true;
    }else{
       s3 = false;
    }

    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGBackupTypeStep',
        autoScroll: true,
        bodyStyle: 'padding: 5px',
        defaults: {
            style: 'margin-bottom: 10px'
        },
        items: [
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_remote.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_remote_backup_title'], WORDS['fun_remote_backup_abstract']),
                textAlign: 'left',
                dtype: 'remote',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_local.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_backup_title'], WORDS['fun_local_backup_abstract']),
                textAlign: 'left',
                dtype: 'local',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/amazon_s3.png',
                text: String.format('<h1>Amazon S3</h1><br/>{0}', WORDS['fun_s3_backup_abstract']),
                textAlign: 'left',
                dtype: 's3',
                handler: onButton,
                hidden: s3
            } 
        ]
    });
    
    function onShow() {
        self.fireEvent('btns', {0:['h'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', null, null);
    }
    
    function onButton(btn, e) {
        if( self.pool.rs['act_type'] != btn.dtype ){
            delete self.pool.rs.opts;
            self.pool.rs['opts'] = {}; 
        }
        
        switch(btn.dtype){
            case 'remote':
                self.pool.rs['act_type'] = btn.dtype;
                self.fireEvent('next', 'DGRemoteBackupTypeStep');
                break;
                
            case 'local':
                self.pool.rs['act_type'] = btn.dtype;
                self.fireEvent('next', 'DGLocalBackupTypeStep');
                break;
            
            case 's3':
                self.pool.rs['act_type'] = btn.dtype;
                self.fireEvent('next', 'DGRemoteTestStep');
                break;
        }
    }
    
    TCode.DataGuard.BackupTypePanel.superclass.constructor.call(self, config);
    
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.BackupTypePanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.LocalBackupTypePanel = function(c) {
    var self = this,
        runningType = [],
        nextStep = '';

    c = c || {};
    var config = Ext.apply(c, {
        id: 'DGLocalBackupTypeStep',
        //autoScroll: true,
        autoHeight: true,
        bodyStyle: 'padding: 5px',
        layout: 'table',
        layoutConfig: {
            columns: 1
        },
        defaults: {
            style: 'margin-bottom: 10px',
            textAlign: 'left'
        },
        items: [
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_import.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_import_title'], WORDS['fun_local_import_abstract']),
                dtype: 'import',
                textAlign: 'left',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_copy.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_copy_title'], WORDS['fun_local_copy_abstract']),
                dtype: 'copy',
                textAlign: 'left',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_realtime.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_realtime_title'], WORDS['fun_local_realtime_abstract']),
                dtype: 'realtime',
                textAlign: 'left',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_schedule.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_schedule_title'], WORDS['fun_local_schedule_abstract']),
                dtype: 'schedule',
                textAlign: 'left',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_iscsi_backup.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_iscsi_title'], WORDS['fun_local_iscsi_abstract']),
                hidden: TCode.DataGuard.iScsi === 0,
                dtype: 'iscsi',
                textAlign: 'left',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_iscsi_import.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_iscsi_import_title'], WORDS['fun_local_iscsi_import_abstract']),
                hidden: TCode.DataGuard.iScsi === 0,
                dtype: 'import_iscsi',
                textAlign: 'left',
                handler: onButton
            }
        ]
    });

    function checkRunningType(){
        var checkItems = [
            self.items.get(0),
            self.items.get(1),
            self.items.get(4),
            self.items.get(5)
        ];
        
        var l = checkItems.length;
        
        runningType = getRunningLBackType();
        
        for ( var i = 0 ; i < l ; i++ ) {
            if ( i != 2 ) {
                if ( runningType.indexOf(checkItems[i].dtype) == '-1' ) {
                    checkItems[i].enable();
                } else {
                    checkItems[i].disable();
                }
            }
        }
    }
    
    function getRunningLBackType(){
        runningType = [];
        TCode.DataGuard.TaskStore.each(function(r) {
            if ( r.data.act_type == 'local' ) {
                if ( r.data.status == 1 || r.data.status == 2 || r.data.status == 400 || r.data.status == 402 ) {
                    runningType.push(r.data.back_type);
                }
            }
        });
        return runningType;
    }
    
    function onShow(){
        checkRunningType();
        self.navigator = WORDS['fun_local_backup_title'];
        self.fireEvent('btns', {0:['s'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', 'DGBackupTypeStep', null);
    }
    
    function onButton(btn, e) {
        if( self.pool.rs['back_type'] != btn.dtype ){
            Ext.apply(self.pool.rs, {
                task_name: ''
            });
            
            Ext.apply(self.pool.rs.opts, {
                permission: 'private',
                create_sfolder: '1',
                sync_type: 'incremental',
                acl: '0',
                symbolic_link: '0',
                log_folder: '',
                filesize_enable: '0',
                min_size: '',
                min_unit: 'gb',
                max_size: '',
                max_unit: 'gb',
                include_enable: '0',
                exclude_enable: '0',
                schedule_enable: '0',
                schedule_hr: '00',
                schedule_min: '00',
                schedule_type: 'daily',
                schedule_date: '00',
                schedule_week: '01',
                src_dev: '',
                src_path: '',
                src_model: '',
                src_folder: '',
                dest_dev: '',
                dest_path: '',
                dest_model: '',
                dest_folder: ''
            });
        }
        
        if(btn.dtype == 'import'){
            self.pool.rs.opts['device_type'] = '2';
            nextStep = 'DGTaskFolderStep';
        }else{
            nextStep = 'DGTaskFolderTypeStep';
        }
        
        if(btn.dtype == 'iscsi'){
            self.pool.rs.opts['iscsi_act'] = '0'; // 0:iSCSI backup/ 1:iSCSI restore
        }
        
        self.pool.rs['back_type'] = btn.dtype;
        self.fireEvent('next', nextStep);
    }
    
    TCode.DataGuard.LocalBackupTypePanel.superclass.constructor.call(self, config);
    
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.LocalBackupTypePanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.TaskFolderTypePanel = function(c) {
    var self = this,
        opts = {},
        itemText = [];
    
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGTaskFolderTypeStep',
        autoScroll: true,
        bodyStyle: 'padding: 5px',
        defaults: {
            style: 'margin-bottom: 10px'
        },
        items: [
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_rr.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_rr_title'], WORDS['fun_local_rr_abstract']),
                dtype: 'rr',
                textAlign: 'left',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_re.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_re_title'], WORDS['fun_local_re_abstract']),
                dtype: 're',
                textAlign: 'left',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_er.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['fun_local_er_title'], WORDS['fun_local_er_abstract']),
                dtype: 'er',
                textAlign: 'left',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_ir.png',
                text: WORDS['fun_local_ir_title'],
                dtype: 'ir',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_ie.png',
                text: WORDS['fun_local_ie_title'],
                dtype: 'ie',
                handler: onButton
            }
        ]
    });
    
    function onButton(btn, e) {
        if(opts['devices'] != btn.dtype){
            Ext.apply(self.pool.rs.opts, {
                src_dev: '',
                src_path: '',
                src_model: '',
                src_folder: '',
                dest_dev: '',
                dest_path: '',
                dest_model: '',
                dest_folder: ''
            });
        }
        
        switch(btn.dtype){
            case 'rr':
                opts['device_type'] = '0';
                break;
            case 're':
                opts['device_type'] = '1';
                break;
            case 'er':
                opts['device_type'] = '2';
                break;
            case 'ir':
                opts['device_type'] = '0';
                break;
            case 'ie':
                opts['device_type'] = '1';
                break;
        }
        opts['devices'] = btn.dtype;
        self.fireEvent('next', 'DGTaskFolderStep');
    }
    
    function loadLBtn(arr){
        for(var i=0; i<self.items.length; i++){
            if( arr.indexOf(i) >= 0 ){
                self.items.get(i).show();
            }else{
                self.items.get(i).hide();
            }
        }
    }
    
    function setItemText(){
        if( self.pool.rs['back_type'].indexOf('import') != -1 ){
            self.items.get(0).setText(WORDS['fun_local_rr_title2']);
            self.items.get(2).setText(WORDS['fun_local_er_title2']);
            self.items.get(3).setText(WORDS['fun_local_ir_title2']);
        //}else{
        //    self.items.get(0).setText(WORDS['fun_local_rr_title']);
        //    self.items.get(2).setText(WORDS['fun_local_er_title']);
        //    self.items.get(3).setText(WORDS['fun_local_ir_title']);
        }
    }
    
    function onRender(){
        itemText[0] = self.items.get(0).getText();
        itemText[2] = self.items.get(2).getText();
        itemText[3] = self.items.get(3).getText();
    }
    
    function onShow(){
        opts = self.pool.rs['opts'];
        setItemText();

        switch(self.pool.rs['back_type']){
            case 'import':
                self.navigator = WORDS['fun_local_import_title'];
                var enabledLargeBtn = [];
                break;
            
            case 'copy':
                self.navigator = WORDS['fun_local_copy_title'];
                var enabledLargeBtn = [0, 1, 2];
                break;
            
            case 'realtime':
                self.navigator = WORDS['fun_local_realtime_title'];
                var enabledLargeBtn = [0, 1];
                break;
            
            case 'schedule':
                self.navigator = WORDS['fun_local_schedule_title'];
                var enabledLargeBtn = [0, 1];
                break;
            
            case 'iscsi':
                self.navigator = WORDS['fun_local_iscsi_title'];
                var enabledLargeBtn = [3, 4];
                break;
            
            case 'import_iscsi':
                self.navigator = WORDS['fun_local_iscsi_import_title'];
                var enabledLargeBtn = [0, 2];
                break;
        }
        loadLBtn(enabledLargeBtn);
        
        self.fireEvent('btns', {0:['s'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', 'DGLocalBackupTypeStep', null);
    }
    
    TCode.DataGuard.TaskFolderTypePanel.superclass.constructor.call(self, config);
    
    self.on('render', onRender);
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.TaskFolderTypePanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.TaskFolderPanel = function(c) {
    var self = this,
        opts = {},
        preStep = null,
        chooseRoot = [],
        enterSubfolder = [],
        multi = [],
        devFilter = [],
        selecteItems = [],
        folderCountLimit = 300,
        currentFolderCount = 0,
        ajax = TCode.DataGuard.Ajax,
        src = {},
        dest = {},
        grid;
        
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGTaskFolderStep',
        layout: 'column',
        autoScroll: false,
        defaults: {
            frame: true,
            border: true,
            height: 330,
            columnWidth: .5,
            style: 'padding: 5px;'
        },
        items: [
            new TCode.DataGuard.FolderGrid({
                title: WORDS['source'],
                autoScroll: true,
                mode: 'checkbox',
                listeners: {
                    selected: onSourceSelected
                }
            }),
            new TCode.DataGuard.FolderGrid({
                title: WORDS['target'],
                autoScroll: true,
                listeners: {
                    selected: onTargetSelected
                }
            }),
            {
                xtype: 'label',
                autoHeight: true,
                style: 'color:red;clear:both;float:left;margin-left:5px;',
                columnWidth: 1,
                text: ' '
            },
            {
                xtype: 'label',
                autoHeight: true,
                style: 'color:blue;float:right;text-align:right;margin-right:7px;padding-bottom:0;',
                columnWidth: 1,
                text: ' '
            }
        ]
    });
    
    function axShowFolderCount(code,count){
        currentFolderCount = count;
    }
    
    function onRender() {
        grid = [
            self.items.get(0),
            self.items.get(1)
        ];
    }
    
    function onSourceSelected(dev, model, uuid, path, selected){
        opts['src_dev'] = dev;
        opts['src_model'] = model;
        opts['src_uuid'] = uuid;
        opts['src_path'] = path;
        opts['src_folder'] = selected;
        
        selecteItems['source'] = {
            'dev': dev,
            'model': model,
            'uuid': uuid,
            'path': path,
            'folder': selected
        };
        checkSelected();
    }
    
    function onTargetSelected(dev, model, uuid, path, selected){
        opts['dest_dev'] = dev;
        opts['dest_model'] = model;
        opts['dest_uuid'] = uuid;
        opts['dest_path'] = path;
        opts['dest_folder'] = selected;
        
        selecteItems['target'] = {
            'dev': dev,
            'model': model,
            'uuid': uuid,
            'path': path,
            'folder': selected
        };
        checkSelected();
    }
    
    function setMsg(msg){
        self.items.get(2).setText(msg);
    }
    
    function folderCount(){
        if(opts['dest_folder']){
            var n = currentFolderCount;
            
            if(opts['src_folder'] != ''){
                n += (opts['src_folder'].split('/')).length;
            }
            
            Ext.apply(self.items.get(3).getEl().dom.style, {
                color: function(){
                    return (n > folderCountLimit) ? 'red' : 'blue';
                }()
            });
            
            var taget_name = (opts['dest_folder'].split(':'))[1];
            //var text = String.format('Total share folder count : {0}', n);
            //self.items.get(3).setText(text);
        }else{
            self.items.get(3).setText('');
        }
        
        var msg ='';
        if(n > folderCountLimit){
            msg = WORDS['foldercount_over_limit'];
        }else if( opts['src_folder'] == '' ){
            msg = WORDS['source_no_select'];
        }else if( opts['dest_folder'] == '' ){
            msg = WORDS['target_no_select'];
        }
        if(msg != ''){
            self.fireEvent('btns', {1:['h']});
        }else{
            self.fireEvent('btns', {1:['s']});
        }
        setMsg(msg);
    }
    
    function checkSelected(){
        if( selecteItems['source']['folder'] && selecteItems['target']['folder']){
            self.fireEvent('steps', preStep, 'DGOptionStep');
            self.fireEvent('btns', {1:['s']});
        }else{
            self.fireEvent('steps', preStep, null);
            self.fireEvent('btns', {1:['h']});
        }
        
        if(self.pool.rs['back_type'] == 'import'){
            folderCount();
        }else{
            self.items.get(3).setText('');
        }
    }
    
    function checkDuplicated(){
        setMsg('');
        var sItems = selecteItems['source']['folder'].split('/');
        var tItems = selecteItems['target']['folder'].split('/');
        var sFullPath ='';
        var tFullPath = '';
        
        for(var i=0, l=sItems.length; i < l; i++){
            if( selecteItems['source']['path'] == selecteItems['target']['path'] ){
                if( tItems[0] == sItems[i] ){
                    setMsg(WORDS['duplicate_msg_01']);
                    return false;
                }
            }else{
                tFullPath = selecteItems['target']['path'] + '/' + tItems[0];
                sFullPath = selecteItems['source']['path'] + '/' + sItems[i];
                if( tFullPath.indexOf(sFullPath) == '0'){
                    setMsg(WORDS['duplicate_msg_02']);
                    return false;
                }
                if( sFullPath.indexOf(tFullPath) == '0'){
                    setMsg(WORDS['duplicate_msg_03']);
                    return false;
                }
            }
        }
        
        return true;
    }
    
    function axCheckContainPath(code, result){
        setMsg('');
        if(code == 0){
            if( self.pool.rs['back_type'] == 'import_iscsi' && result['iscsi_exist'] == 1){
                setMsg(WORDS['no_import_folder']);
                Ext.Msg.alert(WORDS['attention'], WORDS['no_import_folder']);
                return;
            }
            
            if(result['err_folder']){
                setMsg(WORDS['folder_name_error_msg']);
                Ext.Msg.alert(WORDS['attention'], WORDS['folder_name_error'] + '<br/>' + WORDS['folder_name_error_list'] + result['err_folder'].join(','));
                return;
            }
            
            self.fireEvent('next', 'DGOptionStep');
        }else{
            TCode.DataGuard.Error.alert(code)
        }
    }
    
    function axRassembleDevInfo(code, result){
        if( code == 0 ){
            opts['src_dev'] = result.src['dev'] || '';
            opts['src_path'] = result.src['path'] || '/';
            opts['src_uuid'] = result.src['uuid'] || '';
            opts['src_folder'] = result.src['folder'] || '';
            opts['src_model'] = result.src['model'] || '';
            opts['dest_dev'] = result.dest['dev'] || '';
            opts['dest_path'] = result.dest['path'] || '/';
            opts['dest_uuid'] = result.dest['uuid'] || '';
            opts['dest_folder'] = result.dest['folder'] || '';
            opts['dest_model'] = result.dest['model'] || '';
            
            selecteItems = {
                source: {
                    'dev': opts['src_dev'],
                    'model': opts['src_model'],
                    'uuid': opts['src_uuid'],
                    'path': opts['src_path'],
                    'folder': opts['src_folder']
                },
                target: {
                    'dev': opts['dest_dev'],
                    'model': opts['dest_model'],
                    'uuid': opts['dest_uuid'],
                    'path': opts['dest_path'],
                    'folder': opts['dest_folder']
                }
            };
            
            grid[0].loadPath(opts['src_dev'], opts['src_path'], opts['src_model'], chooseRoot[0], enterSubfolder[0], multi[0], devFilter[0], opts['src_folder'].split('/'), opts['src_uuid'].split('/'), '0');
            grid[1].loadPath(opts['dest_dev'], opts['dest_path'], opts['dest_model'], chooseRoot[1], enterSubfolder[1], multi[1], devFilter[1], opts['dest_folder'].split('/'), opts['dest_uuid'].split('/'), '1');
            
            if( opts['src_folder'] == '' || opts['dest_folder'] == '' ){
                self.fireEvent('btns', {1:['h'], 2:['h'], 3:['s'], 4:['h']});
            }else{
                self.fireEvent('btns', {1:['s'], 2:['h'], 3:['s'], 4:['h']});
            }
        }else{
            Ext.MessageBox.alert(WORDS['attention'], WORDS['0x08002011']);
        }
    }
    
    function next(){
        var passed = checkDuplicated();
        
        if( passed == true ){
            src = {
                dev: opts['src_dev'],
                uuid: opts['src_uuid'],
                path: opts['src_path'],
                model: opts['src_model'],
                folder: opts['src_folder']
            };
            dest = {
                dev: opts['dest_dev'],
                uuid: opts['dest_uuid'],
                path: opts['dest_path'],
                model: opts['dest_model'],
                folder: opts['dest_folder']
            };
            
            ajax.CheckContainPath(
                src,
                dest,
                self.pool.rs['back_type'],
                opts['iscsi_act'] || 0,
                opts['device_type'],
                self.pool.rs['task_name'],
                opts['create_sfolder'] || 0,
                self.pool.rs['tid'],
                axCheckContainPath
            );
        }
        
        return false;
    }
    self.next = next;
    
    function onShow(){
        self.navigator = ' ';
        opts = self.pool.rs['opts'];
        ajax.GetFolderCount(axShowFolderCount);
        setMsg('');
        
        opts['src_dev'] = opts['src_dev'] || '';
        opts['src_path'] = opts['src_path'] || '';
        opts['src_uuid'] = opts['src_uuid'] || '';
        opts['src_folder'] = opts['src_folder'] || '';
        opts['dest_dev'] = opts['dest_dev'] || '';
        opts['dest_path'] = opts['dest_path'] || '';
        opts['dest_uuid'] = opts['dest_uuid'] || '';
        opts['dest_folder'] = opts['dest_folder'] || '';
        
        selecteItems = {
            source: {
                'dev': opts['src_dev'],
                'model': opts['src_model'],
                'uuid': opts['src_uuid'],
                'path': opts['src_path'],
                'folder': opts['src_folder']
            },
            target: {
                'dev': opts['dest_dev'],
                'model': opts['dest_model'],
                'uuid': opts['dest_uuid'],
                'path': opts['dest_path'],
                'folder': opts['dest_folder']
            }
        };
        
        switch( self.pool.rs['back_type'] ){
            case 'import':
                self.navigator = WORDS['fun_local_import_title'];
                chooseRoot = [false, true];
                enterSubfolder = [true, false];
                multi = [true, false];
                devFilter = [
                    {
                        'raid': false,
                        'iscsi': false,
                        'external': true,
                        'stack': false
                    },
                    {
                        'raid': true,
                        'iscsi': false,
                        'external': false,
                        'stack': false
                    }
                ];
                break;
                
            case 'copy':
                switch(opts['devices']){
                    case 'rr':
                        chooseRoot = [false, false];
                        enterSubfolder = [true, true];
                        multi = [true, false];
                        devFilter = [
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            },
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            }
                        ];
                        break;
                    case 're':
                        chooseRoot = [false, true];
                        enterSubfolder = [true, true];
                        multi = [true, false];
                        devFilter = [
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            },
                            {
                                'raid': false,
                                'iscsi': false,
                                'external': true,
                                'stack': false
                            }
                        ];
                        break;
                    case 'er':
                        chooseRoot = [true, false];
                        enterSubfolder = [true, true];
                        multi = [true, false];
                        devFilter = [
                            {
                                'raid': false,
                                'iscsi': false,
                                'external': true,
                                'stack': false
                            },
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            }
                        ];
                        break;
                }
                break;
            
            case 'realtime':
                switch(opts['devices']){
                    case 'rr':
                        chooseRoot = [false, false];
                        enterSubfolder = [true, true];
                        multi = [false, false];
                        devFilter = [
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            },
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            }
                        ];
                        break;
                    case 're':
                        chooseRoot = [false, true];
                        enterSubfolder = [true, true];
                        multi = [false, false];
                        devFilter = [
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            },
                            {
                                'raid': false,
                                'iscsi': false,
                                'external': true,
                                'stack': false
                            }
                        ];
                        break;
                }
                break;
            
            case 'schedule':
                switch(opts['devices']){
                    case 'rr':
                        chooseRoot = [false, false];
                        enterSubfolder = [true, true];
                        multi = [true, false];
                        devFilter = [
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            },
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            }
                        ];
                        break;
                    case 're':
                        chooseRoot = [false, true];
                        enterSubfolder = [true, true];
                        multi = [true, false];
                        devFilter = [
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            },
                            {
                                'raid': false,
                                'iscsi': false,
                                'external': true,
                                'stack': false
                            }
                        ];
                        break;
                }
                break;
            
            case 'iscsi':
                switch(opts['devices']){
                    case 'ir':
                        chooseRoot = [true, false];
                        enterSubfolder = [false, true];
                        multi = [false, false];
                        devFilter = [
                            {
                                'raid': false,
                                'iscsi': true,
                                'external': false,
                                'stack': false
                            },
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            }
                        ];
                        break;
                    case 'ie':
                        chooseRoot = [true, true];
                        enterSubfolder = [false, true];
                        multi = [false, false];
                        devFilter = [
                            {
                                'raid': false,
                                'iscsi': true,
                                'external': false,
                                'stack': false
                            },
                            {
                                'raid': false,
                                'iscsi': false,
                                'external': true,
                                'stack': false
                            }
                        ];
                        break;
                }
                break;
            
            case 'import_iscsi':
                switch(opts['devices']){
                    case 'rr':
                        chooseRoot = [false, true];
                        enterSubfolder = [true, false];
                        multi = [false, false];
                        devFilter = [
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': true
                            },
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': false
                            }
                        ];
                        break;
                    case 'er':
                        chooseRoot = [true, true];
                        enterSubfolder = [true, false];
                        multi = [false, false];
                        devFilter = [
                            {
                                'raid': false,
                                'iscsi': false,
                                'external': true,
                                'stack': false
                            },
                            {
                                'raid': true,
                                'iscsi': false,
                                'external': false,
                                'stack': false
                            }
                        ];
                        break;
                }
                break;
        }
        
        switch(self.pool.rs['opts']['devices']){
            case 'rr':
                self.navigator = WORDS['fun_local_rr_navigator'];
                break;
            case 're':
                self.navigator = WORDS['fun_local_re_navigator'];
                break;
            case 'er':
                self.navigator = WORDS['fun_local_er_navigator'];
                break;
            case 'ir':
                self.navigator = WORDS['fun_local_ir_navigator'];
                break;
            case 'ie':
                self.navigator = WORDS['fun_local_ie_navigator'];
                break;
        }
        
        preStep = (self.pool.rs['back_type'] == 'import') ? 'DGLocalBackupTypeStep' : 'DGTaskFolderTypeStep';
        self.fireEvent('steps', preStep, 'DGOptionStep');
        
        if(self.pool.rs['tid'] != 0){
            ajax.RassembleDevInfo(selecteItems['source'], selecteItems['target'], self.pool.rs['tid'], axRassembleDevInfo);
            self.fireEvent('btns', {0:['h']});
        }else{
            grid[0].loadPath(opts['src_dev'], opts['src_path'] || '/', opts['src_model'], chooseRoot[0], enterSubfolder[0], multi[0], devFilter[0], opts['src_folder'].split('/'), opts['src_uuid'].split('/'), '0');
            grid[1].loadPath(opts['dest_dev'], opts['dest_path'] || '/', opts['dest_model'], chooseRoot[1], enterSubfolder[1], multi[1], devFilter[1], opts['dest_folder'].split('/'), opts['dest_uuid'].split('/'), '1');
            
            if( opts['src_folder'] == '' || opts['dest_folder'] == '' ){
                self.fireEvent('btns', {1:['h'], 2:['h'], 3:['s'], 4:['h']});
            }else{
                self.fireEvent('btns', {1:['s'], 2:['h'], 3:['s'], 4:['h']});
            }
            self.fireEvent('btns', {0:['s']});
        }
    }
    
    TCode.DataGuard.TaskFolderPanel.superclass.constructor.call(self, config);
    
    self.on('render', onRender);
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.TaskFolderPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.DuplicateFolderPanel = function(c) {
    var self = this,
        ajax = TCode.DataGuard.Ajax,
        src ={},
        dest = {},
        noTaskNameBackType = ['import', 'copy', 'import_iscsi'],
        opts = {},
        rs = {};
        
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGDuplicateFolderStep',
        defaults: {
            style: 'padding: 5px;',
            autoHeight: true
        },
        items: [
            {
                xtype: 'fieldset',
                title:  WORDS['announce'],
                html: new Ext.Template(
                    '<ul style="list-style-type:decimal;list-style-position:outside;padding-left:2em;line-height:1.6em;">',
                        '<li>' + WORDS['announce_line1'] + '</li>',
                        /*'<li>' + WORDS['announce_line2'] + '</li>',*/ // remove point 2
                        '<li>' + WORDS['announce_line3'] + '</li>',
                        '<li>' + WORDS['announce_line4'] + '</li>',
                        '<li>' + WORDS['announce_line5'] + '</li>',
                    '</ul>'
                )
            },
            {
                xtype: 'fieldset',
                hidden: true,
                title:  WORDS['found_duplicate'],
                items: [{}]
            },
            {
                xtype: 'fieldset',
                title: WORDS['main_target_path'] + ' ' + WORDS['in_use'],
                hidden: true,
                items: [{
                    xtype: 'label',
                    text: ''
                }]
            },
            {
                xtype: 'fieldset',
                title: WORDS['dup_folder_list'],
                hidden: true,
                html: WORDS['target_rename'],
                items: [{}]
            },
            {
                layout: 'table',
                layoutConfig: {
                    columns: 2
                },
                items: [
                    {
                        xtype: 'checkbox',
                        key: 'force_copy',
                        boxLabel: WORDS['accept'],
                        listeners: {
                            check: onConfirm
                        }
                    }
                ]
                
            }
        ]
    });
    
    function removeAllItems(e) {
        e.items.each(function(childItem){ e.remove(childItem);}, e);
    }
    
    function axCheckContainPath(code, result){
        removeAllItems(self.items.get(1));
        removeAllItems(self.items.get(3));
        
        if( code == 0){
            if( result['same'] != '' ){
                self.items.get(2).items.get(0).setText( String.format('{0}( {1}:{2})', WORDS['target_dup_desp'], WORDS['task_name'], result['same'].join()) );
                self.items.get(2).show();
            }else{
                self.items.get(2).hide();
            }
            
            if( result['dup'] ){
                for(var i=0, l=result['dup'].length; i<l; i++){
                    var tmp = new Ext.form.Label({
                        text : result['dup'][i],
                        style: 'display:block;',
                        autoHeight: true
                    });
                    self.items.get(1).add(tmp);
                }
                self.items.get(1).doLayout();
                self.items.get(1).show();
            }else{
                self.items.get(1).hide();
            }
            
            if( result['rename'] ){
                for(var i=0, l=result['rename'].length; i<l; i++){
                    var tmp = new Ext.form.Label({
                        text : String.format( '{0}:{1} {2}:{3}' ,WORDS['origin_folder'], result['rename'][i][0], WORDS['rename_folder'], result['rename'][i][1]),
                        style: 'display:block;',
                        autoHeight: true
                    });
                    self.items.get(3).add(tmp);
                }
                self.items.get(3).doLayout();
                self.items.get(3).show();
            }else{
                self.items.get(3).hide();
            }
        }else{
            TCode.DataGuard.Error.alert(code)
        }
    }
    
    function onConfirm(e){
        if(e.checked){
            self.pool.rs.opts['force'] = 1;
            self.fireEvent('btns', {0:['s'], 1:['h'], 2:['s'], 3:['s'], 4:['h']});
            self.fireEvent('steps', 'DGOptionStep', null);
        }else{
            self.pool.rs.opts['force'] = 0;
            self.fireEvent('btns', {0:['s'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
            self.fireEvent('steps', 'DGOptionStep', null);
        }
    }
    
    function onShow(){
        self.navigator = ' ';
        self.items.get(1).hide();
        self.items.get(2).hide();
        self.items.get(3).hide();
        self.items.get(4).items.get(0).reset();
        opts = self.pool.rs['opts'];
        rs = self.pool.rs;
        
        src = {
            dev: opts['src_dev'],
            uuid: opts['src_uuid'],
            path: opts['src_path'],
            model: opts['src_model'],
            folder: opts['src_folder']
        };
        dest = {
            dev: opts['dest_dev'],
            uuid: opts['dest_uuid'],
            path: opts['dest_path'],
            model: opts['dest_model'],
            folder: opts['dest_folder']
        };

        ajax.CheckContainPath(
            src,
            dest,
            rs['back_type'],
            opts['iscsi_act'] || 0,
            opts['device_type'],
            rs['task_name'],
            opts['create_sfolder'] || 0,
            rs['tid'],
            axCheckContainPath
        );
        
        self.fireEvent('btns', {0:['s'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', 'DGOptionStep', null);
    }
    
    function getExistTask() {
        var store = TCode.DataGuard.TaskStore;
        var index = store.find('task_name', self.pool.rs['back_type']);
        var record = store.getAt(index);
        return record;
    }
    
    function finish() {
        if(self.pool.rs.opts['force'] == 1){
            var backType = self.pool.rs['back_type'];
            
            if( noTaskNameBackType.indexOf(backType) != -1 ){
                var record = getExistTask(backType);
                if( typeof record == 'undefined' ) {
                    return true;
                } else {
                    var status = record.data.status;
                    if(status == 1 || status == 2 || status == 400 || status == 401){
                        Ext.MessageBox.alert(WORDS['attention'], WORDS['0x08001007']);
                    }else{
                        Ext.getCmp('finish').setDisabled(true);
                        TCode.DataGuard.Ajax.RemoveTask(record.data.tid, function(code){
                            if(code == 0){
                                TCode.DataGuard.Wizard.finish();
                            }else{
                                Ext.getCmp('finish').setDisabled(false);
                                TCode.DataGuard.Error.alert(code)
                            }
                        });
                    }
                    return false;
                }
            }else{
                return true;
            }
        }
    }
    self.finish = finish;
    
    TCode.DataGuard.DuplicateFolderPanel.superclass.constructor.call(self, config);
    
    this.on('show', onShow);
}
Ext.extend(TCode.DataGuard.DuplicateFolderPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.OptionPanel = function(c) {
    var self = this,
        ui = {},
        opts = {},
        fileTypeFilters = {},
        invalidMsg = '',
        finishAction = false,
        ajax = TCode.DataGuard.Ajax,
        otherFileTypeTxt = WORDS['file_type_tip'],
        basePath = '/raid0/data',
        actOpts = {
            'import': ['permission', 'log_folder'],
            'copy': ['acl', 'sync_type', 'log_folder'],
            'realtime': ['log_folder', 'task_name', 'symbolic_link', 'sync_type'],
            'schedule': ['acl', 'log_folder', 'task_name', 'sync_type', 'create_sfolder'],
            'iscsi': ['log_folder', 'task_name'],
            'import_iscsi': ['log_folder']
        },
        scheduleOpts = ['schedule_hr', 'schedule_min', 'schedule_type', 'schedule_date', 'schedule_week'],
        noTaskNameBackType = ['import', 'copy', 'import_iscsi'],
        filterOpts = [
            'filesize_enable',
            'include_enable',
            'exclude_enable',
            'min_size',
            'min_unit',
            'max_size',
            'max_unit',
            'include_doc',
            'include_photo',
            'include_video',
            'include_music',
            'include_other',
            'include_other_txt',
            'exclude_doc',
            'exclude_photo',
            'exclude_video',
            'exclude_music',
            'exclude_other',
            'exclude_other_txt'
        ],
        listeners = {
            render: mapObjKey,
            change: dataChange
        };
    
    
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGOptionStep',
        labelWidth: 120,
        layout: 'form',
        autoScroll: true,
        autoHeight: true,
        defaults: {
            listeners: listeners
        },
        items: [
            {
                xtype: 'textfield',
                key: 'task_name',
                allowBlank: false,
                fieldLabel: WORDS['task_name'],
                vtype: 'AliasName'
            },
            {
                xtype: 'radiogroup',
                key: 'permission',
                fieldLabel: WORDS['opts_set_public'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'permission'
                },
                items: [
                    {
                        inputValue: 'private',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: 'public',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'create_sfolder',
                fieldLabel: WORDS['opts_create_subfolder'],
                width: '100%',
                columns: 2,
                defaults: {
                    name: 'create_sfolder',
                    autoHeight: true
                },
                items: [
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_create_subfolder_on'],
                        checked: true
                    },
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_create_subfolder_off']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'sync_type',
                fieldLabel: WORDS['opts_sync_type'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'sync'
                },
                items: [
                    {
                        inputValue: 'incremental',
                        boxLabel: WORDS['opts_incremental_sync'],
                        checked: true
                    },
                    {
                        inputValue: 'sync',
                        boxLabel: WORDS['opts_sync_sync']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'acl',
                fieldLabel: WORDS['opts_acl'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'acl'
                },
                items: [
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'symbolic_link',
                fieldLabel: WORDS['opts_backup_symbolic_link'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'symbolic_link'
                },
                items: [
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                xtype: 'combo',
                key: 'log_folder',
                fieldLabel: WORDS['opts_log_folder'],
                readOnly: true,
                editable: false,
                allowBlank: false,
                displayField: 'name',
                valueField: 'name',
                typeAhead: false,
                triggerAction: 'all',
                mode: 'local',
                value: '',
                listWidth: 150,
                forceSelection: true,
                selectOnFocus:true,
                store: new Ext.data.SimpleStore({
                    fields: ['name']
                })
            },
            {
                xtype: 'fieldset',
                title: WORDS['opts_filter'],
                width: 435,
                autoHeight: true,
                defaults: {
                    hideLabel: true
                },
                items: [
                    {
                        xtype: 'checkbox',
                        boxLabel: String.format(
                            '{0} <img ext:qtip="{1}" src="{2}"></img>',
                            WORDS['opts_filter_file_size'],
                            WORDS['filter_and'],
                            '/theme/images/icons/fam/icon-question.gif'
                        ),
                        key: 'filesize_enable',
                        listeners: {
                            render: mapObjKey,
                            check: onFileSizeFilt
                        }
                    },
                    {
                        layout:'table',
                        style:'margin-left: 20px',
                        defaults: {
                            disabled: true,
                            listeners: listeners
                        },
                        items: [
                            {
                                xtype: 'numberfield',
                                key: 'min_size',
                                allowDecimals: false,
                                allowNegative: false,
                                width: 50
                            },
                            {
                                xtype: 'combo',
                                listWidth: 40,
                                key: 'min_unit',
                                editable: false,
                                displayField: 'k',
                                valueField: 'v',
                                typeAhead: false,
                                triggerAction: 'all',
                                allowBlank: false,
                                mode: 'local',
                                value: 'gb',
                                store: new Ext.data.SimpleStore({
                                    fields: ['k', 'v'],
                                    data: [['GB','gb'], ['MB','mb'], ['KB','kb']]
                                })
                            },
                            {
                                xtype: 'box',
                                autoEl: {
                                    tag: 'center',
                                    style: 'width: 20px',
                                    html: '~'
                                }
                            },
                            {
                                xtype: 'numberfield',
                                key: 'max_size',
                                allowDecimals: false,
                                allowNegative: false,
                                width: 50
                            },
                            {
                                xtype: 'combo',
                                listWidth: 40,
                                key: 'max_unit',
                                editable: false,
                                displayField: 'k',
                                valueField: 'v',
                                typeAhead: false,
                                triggerAction: 'all',
                                allowBlank: false,
                                mode: 'local',
                                value: 'gb',
                                store: new Ext.data.SimpleStore({
                                    fields: ['k', 'v'],
                                    data: [['GB','gb'], ['MB','mb'], ['KB','kb']]
                                })
                            }
                        ]
                    },
                    {
                        xtype: 'checkbox',
                        width: 150,
                        boxLabel: WORDS['opts_filter_include_type'],
                        key: 'include_enable',
                        listeners: {
                            render: mapObjKey,
                            check: onIncludeFilt
                        }
                    },
                    {
                        xtype: 'panel',
                        layout: 'column',
                        style:'margin-left: 20px',
                        items: [
                            {
                                xtype: 'checkboxgroup',
                                disabled: true,
                                columns: [90, 90, 90, 90],
                                defaults: {
                                    listeners: {
                                        render: mapObjKey,
                                        check: onFileTypesCheck
                                    }
                                },
                                items: [
                                    {
                                        boxLabel: (function() {
                                            if ( Ext.isIE ) {
                                                return '<span ext:qtip="'+ MINES['doc'] +'" ext:qalign="bl?">Document</span>';
                                            } else {
                                                return '<span ext:qtip="'+ MINES['doc'] +'" ext:qalign="bl?" ext:qwidth="auto" ext:qheight="auto">Document</span>';
                                            }
                                        })(),
                                        key: 'include_doc'
                                    },
                                    {
                                        boxLabel: (function() {
                                            if ( Ext.isIE ) {
                                                return '<span ext:qtip="'+ MINES['photo'] +'" ext:qalign="bl?">Picture</span>';
                                            } else {
                                                return '<span ext:qtip="'+ MINES['photo'] +'" ext:qalign="bl?" ext:qwidth="auto" ext:qheight="auto">Picture</span>';
                                            }
                                        })(),
                                        key: 'include_photo'
                                    },
                                    {
                                        boxLabel: (function() {
                                            if ( Ext.isIE ) {
                                                return '<span ext:qtip="'+ MINES['video'] +'" ext:qalign="bl?">Video</span>';
                                            } else {
                                                return '<span ext:qtip="'+ MINES['video'] +'" ext:qalign="bl?" ext:qwidth="auto" ext:qheight="auto">Video</span>';
                                            }
                                        })(),
                                        key: 'include_video'
                                    },
                                    {
                                        boxLabel: (function() {
                                            if ( Ext.isIE ) {
                                                return '<span ext:qtip="'+ MINES['music'] +'" ext:qalign="bl?" >Music</span>';
                                            } else {
                                                return '<span ext:qtip="'+ MINES['music'] +'" ext:qalign="bl?" ext:qwidth="auto" ext:qheight="auto">Music</span>';
                                            }
                                        })(),
                                        key: 'include_music'
                                    }
                                ]
                            },
                            {
                                layout: 'column',
                                defaults: {
                                    disabled: true,
                                    listeners: {
                                        render: mapObjKey,
                                        check: onFileTypesCheck,
                                        change: dataChange
                                    }
                                },
                                items: [
                                    {
                                        xtype: 'checkbox',
                                        boxLabel: '<span ext:qtip="' + otherFileTypeTxt + '" ext:qalign="bl?">Other</span>',
                                        key: 'include_other'
                                    },
                                    {
                                        xtype: 'textfield',
                                        key: 'include_other_txt',
                                        style: 'margin-left:5px;',
                                        vtype: 'FileFilter',
                                        width: 270
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        xtype: 'checkbox',
                        width: 150,
                        boxLabel: WORDS['opts_filter_exclude_type'],
                        key: 'exclude_enable',
                        listeners: {
                            render: mapObjKey,
                            check: onExcludeFilt
                        }
                    },
                    {
                        xtype: 'panel',
                        layout: 'column',
                        style:'margin-left: 20px',
                        items: [
                            {
                                xtype: 'checkboxgroup',
                                disabled: true,
                                columns: [90, 90, 90, 90],
                                defaults: {
                                    listeners: {
                                        render: mapObjKey,
                                        check: onFileTypesCheck
                                    }
                                },
                                items: [
                                    {
                                        boxLabel: (function() {
                                            if ( Ext.isIE ) {
                                                return '<span ext:qtip="'+ MINES['doc'] +'" ext:qalign="bl?">Document</span>';
                                            } else {
                                                return '<span ext:qtip="'+ MINES['doc'] +'" ext:qalign="bl?" ext:qwidth="auto" ext:qheight="auto">Document</span>';
                                            }
                                        })(),
                                        key: 'exclude_doc'
                                    },
                                    {
                                        boxLabel: (function() {
                                            if ( Ext.isIE ) {
                                                return '<span ext:qtip="'+ MINES['photo'] +'" ext:qalign="bl?">Picture</span>';
                                            } else {
                                                return '<span ext:qtip="'+ MINES['photo'] +'" ext:qalign="bl?" ext:qwidth="auto" ext:qheight="auto">Picture</span>';
                                            }
                                        })(),
                                        key: 'exclude_photo'
                                    },
                                    {
                                        boxLabel: (function() {
                                            if ( Ext.isIE ) {
                                                return '<span ext:qtip="'+ MINES['video'] +'" ext:qalign="bl?">Video</span>';
                                            } else {
                                                return '<span ext:qtip="'+ MINES['video'] +'" ext:qalign="bl?" ext:qwidth="auto" ext:qheight="auto">Video</span>';
                                            }
                                        })(),
                                        key: 'exclude_video'
                                    },
                                    {
                                        boxLabel: (function() {
                                            if ( Ext.isIE ) {
                                                return '<span ext:qtip="'+ MINES['music'] +'" ext:qalign="bl?" >Music</span>';
                                            } else {
                                                return '<span ext:qtip="'+ MINES['music'] +'" ext:qalign="bl?" ext:qwidth="auto" ext:qheight="auto">Music</span>';
                                            }
                                        })(),
                                        key: 'exclude_music'
                                    }
                                ]
                            },
                            {
                                layout: 'column',
                                defaults: {
                                    disabled: true,
                                    listeners: {
                                        render: mapObjKey,
                                        check: onFileTypesCheck,
                                        change: dataChange
                                    }
                                },
                                items: [
                                    {
                                        xtype: 'checkbox',
                                        boxLabel: '<span ext:qtip="' + otherFileTypeTxt + '" ext:qalign="bl?">Other</span>',
                                        key: 'exclude_other'
                                    },
                                    {
                                        xtype: 'textfield',
                                        key: 'exclude_other_txt',
                                        style: 'margin-left:5px;',
                                        vtype: 'FileFilter',
                                        width: 270
                                    }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                xtype: 'fieldset',
                checkboxToggle:true,
                collapsed: true,
                title: WORDS['opts_schedule_enable'],
                autoHeight: true,
                hideBorders: true,
                listeners:{
                    expand: onEnableSchedule,
                    collapse: onDisableSchedule
                },
                items: [
                    {
                        layout: 'table',
                        items: [
                            {
                                xtype: 'box',
                                width: 115,
                                autoEl: {
                                    style: 'width: 100px',
                                    html: WORDS['time'] + ':'
                                }
                            },
                            {
                                xtype: 'combo',
                                displayField: 'hour',
                                listWidth: 40,
                                editable: false,
                                valueField: 'hour',
                                typeAhead: false,
                                triggerAction: 'all',
                                allowBlank: false,
                                listeners: listeners,
                                mode: 'local',
                                key: 'schedule_hr',
                                value: '00',
                                store: new Ext.data.SimpleStore({
                                    fields: ['hour'],
                                    data:  function(){
                                        var hour = [];
                                        for( var i = 0 ; i < 24 ; i++ ) {
                                            i = i.toString();
                                            if(i.length == '1'){
                                                i = '0'+i;
                                            }
                                            hour.push([i]);
                                        }
                                        return hour;
                                    }()
                                })
                            },
                            {
                                xtype: 'box',
                                autoEl: {
                                    tag: 'center',
                                    style: 'width: 20px',
                                    html: ':'
                                }
                            },
                            {
                                xtype: 'combo',
                                listWidth: 40,
                                editable: false,
                                displayField: 'mintue',
                                valueField: 'mintue',
                                typeAhead: false,
                                triggerAction: 'all',
                                listeners: listeners,
                                allowBlank: false,
                                mode: 'local',
                                key: 'schedule_min',
                                value: '00',
                                store: new Ext.data.SimpleStore({
                                    fields: ['mintue'],
                                    data:  function(){
                                        var mintue = [];
                                        for( var i = 0 ; i < 60 ; i++ ) {
                                            i = i.toString();
                                            if(i.length == '1'){
                                                i = '0'+i;
                                            }
                                            mintue.push([i]);
                                        }
                                        return mintue;
                                    }()
                                })
                            }
                        ]
                    },
                    {
                        layout: 'table',
                        items: [
                            {
                                xtype: 'box',
                                width: 115,
                                autoEl: {
                                    style: 'width: 100px',
                                    html: WORDS['schedule'] + ':'
                                }
                            },
                            {
                                xtype: 'radiogroup',
                                key: 'schedule_type',
                                listeners: listeners,
                                width: '100%',
                                columns: [100, 100, 100],
                                defaults: {
                                    name: 'scheduleType'
                                },
                                items: [
                                    {
                                        inputValue: 'monthly',
                                        boxLabel: WORDS['monthly']
                                    },
                                    {
                                        inputValue: 'weekly',
                                        boxLabel: WORDS['weekly']
                                    },
                                    {
                                        inputValue: 'daily',
                                        boxLabel: WORDS['daily'],
                                        checked: true
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        layout: 'table',
                        style: 'margin-left:115px;',
                        items:[
                            {
                                xtype: 'combo',
                                typeAhead: false,
                                hideLabel: true,
                                editable: false,
                                disabled: true,
                                triggerAction: 'all',
                                allowBlank: false,
                                displayField: 'dates',
                                valueField: 'dates',
                                mode: 'local',
                                key: 'schedule_date',
                                listeners: listeners,
                                value: '01',
                                store: new Ext.data.SimpleStore({
                                    fields: ['dates'],
                                    data: function(){
                                        var dates = [];
                                        for( i = 1 ; i <= 31 ; i++ ) {
                                            i = i.toString();
                                            if(i.length == '1'){
                                                i = '0'+i;
                                            }
                                            dates.push([i]);
                                        }
                                        return dates;
                                    }()
                                })
                            },
                            {
                                width: 50
                            },
                            {
                                xtype: 'combo',
                                typeAhead: false,
                                hideLabel: true,
                                editable: false,
                                disabled: true,
                                triggerAction: 'all',
                                allowBlank: false,
                                displayField: 'k',
                                valueField: 'v',
                                mode: 'local',
                                key: 'schedule_week',
                                listeners: listeners,
                                value: '01',
                                store: new Ext.data.SimpleStore({
                                    fields: ['k', 'v'],
                                    data: [
                                        [WORDS['Monday'], '01'],
                                        [WORDS['Tuesday'], '02'],
                                        [WORDS['Wednesday'], '03'],
                                        [WORDS['Thursday'], '04'],
                                        [WORDS['Friday'], '05'],
                                        [WORDS['Saturday'], '06'],
                                        [WORDS['Sunday'], '00']
                                    ]
                                })
                            }
                        ]
                    }
                ]
            },
            {
                xtype: 'label',
                style: 'color:blue;',
                hidden: true,
                text: WORDS['disable_schedule_notice']
            }
        ]
    });
    
    function onEnableSchedule(){
        if( self.pool.rs ) {
            opts['schedule_enable'] = '1';
            self.items.get(self.items.length-1).hide();
        }
    }
    
    function onDisableSchedule(){
        if( self.pool.rs ) {
            opts['schedule_enable'] = '0';
            self.items.get(self.items.length-1).show();
        }
    }
    
    function onFileSizeFilt(cb, checked){
        var filterItem = self.items.get(7).items.get(1);
        if(checked){
            opts['filesize_enable'] = '1';
            for(var i=0, l=filterItem.items.length; i < l ; i++){
                filterItem.items.get(i).enable();
            }
        }else{
            opts['filesize_enable'] = '0';
            for(var i=0, l=filterItem.items.length; i < l ; i++){
                filterItem.items.get(i).disable();
            }
        }
    }
    
    function onIncludeFilt(cb, checked){
        if ( checked ) {
            opts['include_enable'] = '1';
            self.items.get(7).items.get(3).items.get(0).enable();
            self.items.get(7).items.get(3).items.get(1).items.get(0).enable();
            if ( self.items.get(7).items.get(3).items.get(1).items.get(0).getValue() ) {
                self.items.get(7).items.get(3).items.get(1).items.get(1).enable();
            }
        } else {
            opts['include_enable'] = '0';
            self.items.get(7).items.get(3).items.get(0).disable();
            self.items.get(7).items.get(3).items.get(1).items.get(0).disable();
            self.items.get(7).items.get(3).items.get(1).items.get(1).disable();
        }
    }
    
    function onExcludeFilt(cb, checked){
        if ( checked ) {
            opts['exclude_enable'] = '1';
            self.items.get(7).items.get(5).items.get(0).enable();
            self.items.get(7).items.get(5).items.get(1).items.get(0).enable();
            if ( self.items.get(7).items.get(5).items.get(1).items.get(0).getValue() ) {
                self.items.get(7).items.get(5).items.get(1).items.get(1).enable();
            }
        } else {
            opts['exclude_enable'] = '0';
            self.items.get(7).items.get(5).items.get(0).disable();
            self.items.get(7).items.get(5).items.get(1).items.get(0).disable();
            self.items.get(7).items.get(5).items.get(1).items.get(1).disable();
        }
    }
    
    function onFileTypesCheck(cb, checked){
        var key = cb.key;
        var tmp = key.split('_');
        var filterType = tmp[0];
        var fileType = tmp[1];
        
        if ( checked && fileType != 'other' ) {
            filterType = (filterType == 'include') ? 'exclude' : 'include';
            ui[filterType + '_' + fileType].setValue(false);
        }
        
        if ( fileType == 'other' ) {
            filterType = ( filterType == 'include' ) ? 'include' : 'exclude';
            if ( checked ) {
                ui[filterType + '_other_txt'].setDisabled(false);
            } else {
                ui[filterType + '_other_txt'].setDisabled(true);
            }
        }
        
        opts[key] = Number(checked).toString();
    }
    
    function mapObjKey(ct) {
        if(ct.hasOwnProperty('key')) {
            ui[ct.key] = ct;
            
            if( ct.key == 'include_other_txt' || ct.key == 'exclude_other_txt' ){
                Ext.QuickTips.register({
                    target: ct,
                    text: otherFileTypeTxt
                })
            }
        }
    }
    
    function dataChange(ct, newValue, oldValue) {
        var key = ct.key;
        
        if( !ct.validate() ){
            return;
        }
        
        switch(key){
            case 'task_name':
                ajax.CheckTaskName(self.pool.rs.tid, newValue, axCheckTaskName);
                self.pool.rs[key] = newValue;
                break;
                
            case 'schedule_type':
                onChangeScheduleType(newValue)
                opts[key] = newValue;
                break;
                
            default:
                opts[key] = newValue;
        }
    }
    
    function axCheckTaskName(code, legal) {
        if( legal == false ) {
            Ext.MessageBox.alert(WORDS['attention'], WORDS['task_name_existed']);
        } else {
            if( finishAction ) {
                self.fireEvent('next', 'DGDuplicateFolderStep');
            }
        }
    }
    
    function saveBackupTime() {
        switch(opts['schedule_type']){
            case 'daily':
                opts['scheduled_date'] = '*';
                opts['scheduled_month'] = '*';
                opts['scheduled_week'] = '*';
                break;
            case 'weekly':
                opts['scheduled_date'] = '*';
                opts['scheduled_month'] = '*';
                opts['scheduled_week'] = ui['schedule_week'].getValue().toString();
                break;
            case 'monthly':
                opts['scheduled_date'] = ui['schedule_date'].getValue().toString();
                opts['scheduled_month'] = '*';
                opts['scheduled_week'] = '*';
                break;
            
        }
        var schedule_time_array = [
            ui['schedule_min'].getValue(),
            ui['schedule_hr'].getValue(),
            opts['scheduled_date'],
            opts['scheduled_month'],
            opts['scheduled_week']
        ];
        opts['backup_time'] = schedule_time_array.join(",");
    }
    
    function saveFileSize(){
        finishAction = false;
        var minBytes = getLimitSize('min');
        var maxBytes = getLimitSize('max');
        
        if(minBytes > maxBytes){
            opts['minisize'] = '';
            opts['maxisize'] = '';
            Ext.MessageBox.alert(WORDS['attention'], WORDS['opts_filter_file_size_error']);
        }else{
            opts['minisize'] = minBytes;
            opts['maxisize'] = maxBytes;
            
            finishAction = true;
        }
    }
    
    function getLimitSize(t){
        var size, unit, bytes;
        
        switch (t){
            case 'min':
                size = ui['min_size'].getValue();
                unit = ui['min_unit'].getValue();
                break;
            
            case 'max':
                size = ui['max_size'].getValue();
                unit = ui['max_unit'].getValue();
                break;
        }
        
        switch(unit){
            case 'kb':
                size = size*1024;
                break;
            case 'mb':
                size = size*1024*1024;
                break;
            case 'gb':
                size = size*1024*1024*1024;
                break;
        }
        
        return size ? size : '';
    }
    
    function onChangeScheduleType(v){
        switch(v){
            case 'weekly':
                ui['schedule_week'].enable();
                ui['schedule_date'].disable();
                break;
            
            case 'monthly':
                ui['schedule_week'].disable();
                ui['schedule_date'].enable();
                break;
            
            case 'daily':
                ui['schedule_week'].disable();
                ui['schedule_date'].disable();
                break;
        }
    }
    
    function loadOption() {
        var rs = self.pool.rs;
        
        Ext.applyIf(rs, {
            task_name: '',
            back_type: ''
        });
        
        Ext.applyIf(rs.opts, {
            permission: '0',
            force: '0',
            sync_type: 'incremental',
            acl: '0',
            symbolic_link: '0',
            log_folder: '',
            create_sfolder: '1',
            min_size: '',
            min_unit: 'gb',
            max_size: '',
            max_unit: 'gb',
            schedule_enable: '0',
            schedule_hr: '00',
            schedule_min: '00',
            schedule_type: 'daily',
            schedule_date: '00',
            schedule_week: '01',
            filesize_enable: '0',
            include_enable: '0',
            exclude_enable: '0',
            include_doc: '0',
            include_photo: '0',
            include_video: '0',
            include_music: '0',
            include_other: '0',
            include_other_txt: '',
            exclude_doc: '0',
            exclude_photo: '0',
            exclude_video: '0',
            exclude_music: '0',
            exclude_other: '0',
            exclude_other_txt: ''
        });

        for( var key in ui){
            var v = rs[key] || opts[key];
            ui[key].setValue(v);
            
            if(scheduleOpts.indexOf(key) == '-1' && filterOpts.indexOf(key) == '-1'){
                if( actOpts[rs.back_type].indexOf(key) != -1 ){
                    self.displayLabelItem(ui[key], true);
                }else{
                    self.displayLabelItem(ui[key], false);
                }
            }
        }
        
        if (rs['tid'] != '0'){
            ui['task_name'].disable();
        }else{
            ui['task_name'].enable();
        }
        
        if (opts['device_type'] == '0' && rs['back_type'] != 'realtime' && rs['back_type'].indexOf('iscsi') == -1){
            self.displayLabelItem(ui['acl'], true);
        }else{
            self.displayLabelItem(ui['acl'], false);
        }
        
        if (self.pool.rs['back_type'] == 'realtime'){
            self.items.get(7).show();
        }else{
            self.items.get(7).hide();
        }
        
        if (self.pool.rs['back_type'] == 'schedule'){
            self.items.get(8).show().enable();
            
            if(opts['schedule_enable'] == 0){
                self.items.get(8).collapse();
                self.items.get(9).show();
            }else{
                self.items.get(8).expand();
                self.items.get(9).hide();
            }
        }else{
            self.items.get(8).hide();
            self.items.get(9).hide();
        }
        
        if (noTaskNameBackType.indexOf(rs['back_type']) != '-1'){
            ui['task_name'].setValue(rs['back_type']);
            rs['task_name'] = rs['back_type'];
        }
    }

    function saveOption() {
        for(var i = 0 ; i < ui.length ; ++i ) {
            var key = ui[i].key;
            var value = ui[i].getValue();
            opts[key] = value;
        }
        
        self.pool.rs['opts'] = opts;
    }
    
    function onShow(){
        self.navigator = ' ';
        finishAction = false;
        opts = self.pool.rs['opts'];
        loadOption();
        ajax.ListLogFolder(axListLogFolder);
        
        self.fireEvent('btns', {0:['s'], 1:['s'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', 'DGTaskFolderStep', 'DGDuplicateFolderStep');
    }
    
    function validate(){
        invalidMsg = '';
        for( var key in ui ) {
            if( !ui[key].validate() ) {
                ui[key].markInvalid();
                invalidMsg = ui[key].fieldLabel;
                return invalidMsg;
            }
        }
        return;
    }
    
    function next() {
        if( !validate() ){
            finishAction = true;
            opts['log_folder'] = ui['log_folder'].getValue();
            opts['min_unit'] = ui['min_unit'].getValue();
            opts['max_unit'] = ui['max_unit'].getValue();
            
            switch(self.pool.rs['back_type']){
                case 'schedule':
                    saveBackupTime();
                    break;
                    
                case 'realtime':
                    if ( ui['filesize_enable'].getValue() ) {
                        saveFileSize();
                    }
                    break;
            }
            
            if( noTaskNameBackType.indexOf(self.pool.rs['back_type']) == -1 ){
                ajax.CheckTaskName(
                    self.pool.rs.tid,
                    self.pool.rs.task_name,
                    axCheckTaskName
                );
                return false;
            }else{
                return true;
            }
        }else{
            Ext.MessageBox.alert(WORDS['attention'], '"' +invalidMsg + '" ' + WORDS['opts_invalid']);
            return false;
        }
    }
    self.next = next;
    
    function axListLogFolder(code, list) {
        ui.log_folder.store.loadData(list);
        if(!opts['log_folder']){
            ui.log_folder.setValue(list[0][0]);
        }
    }
    
    TCode.DataGuard.OptionPanel.superclass.constructor.call(self, config);

    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.OptionPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.RemoteBackupTypePanel = function(c) {
    var self = this;
    c = c || {};
    var config = Ext.apply(c, {
        id: 'DGRemoteBackupTypeStep',
        autoScroll: true,
        bodyStyle: 'padding: 5px',
        autoHeight: true,
        layout: 'column',
        columns: 1,
        defaults: {
            columnWidth: 1,
            style: 'margin-bottom: 10px'
        },
        items: [
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/type_normal.png',
                text: String.format('<h1>{0}</h1><br/>{1}<span style="color:red;">{2}</span>', WORDS['remote_full'], WORDS['remote_full_notice'], WORDS['remote_full_notice2']),
                textAlign: 'left',
                dtype: 'full',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/type_schedule.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['remote_custom'], WORDS['remote_custom_abstract']),
                textAlign: 'left',
                dtype: 'custom',
                handler: onButton
            },
            {
                xtype: 'LargeButton',
                icon: '/theme/images/index/dataguard/icon_iscsi.png',
                text: String.format('<h1>{0}</h1><br/>{1}', WORDS['remote_iscsi'], WORDS['remote_iscsi_abstract']),
                hidden: TCode.DataGuard.iScsi === 0,
                textAlign: 'left',
                dtype: 'iscsi',
                handler: onButton
            }
        ]
    });
    
    function onShow(){      
        self.navigator = WORDS['fun_remote_backup_title']; 
        self.fireEvent('btns', {0:['s','e'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', 'DGBackupTypeStep', null);
    }
    
    function onButton(btn, e) {
        if(self.pool.rs.opts['remote_back_type'] != btn.dtype){
            Ext.apply(self.pool.rs.opts, {
                src_dev: '',
                src_path: '',
                src_folder: '',
                src_model: ''
            });
            
            Ext.apply(self.pool.rs, {
                task_name: '',
                back_type: 'realtime'
            });
            
            Ext.apply(self.pool.rs.opts, {
                compress: '0',
                backup_conf: '0',
                sparse: '0',
                sync_type: 'sync',
                partial: '0',
                acl: '0',
                log_folder: '',
                schedule_hr: '00',
                schedule_min: '00',
                schedule_type: 'daily',
                schedule_date: '00',
                schedule_week: '01'
            });
        }
        
        self.pool.rs.opts['remote_back_type'] = btn.dtype;
        
        self.fireEvent('next', 'DGRemoteTestStep');
    }
    
    TCode.DataGuard.RemoteBackupTypePanel.superclass.constructor.call(self, config);
    
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.RemoteBackupTypePanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.RemoteOptionPanel = function(c) {
    var self = this,
        ui = {},
        opts = {},
        finishAction = false,
        basePath = '/raid0/data',
        ajax = TCode.DataGuard.Ajax,
        listeners = {
            render: mapObjKey,
            change: dataChange
        };
        
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGRemoteOptionStep',
        layout: 'form',
        labelWidth: 120,
        autoScroll: true,
        defaults: {
            listeners: listeners
        },
        items: [
            {
                xtype: 'textfield',
                key: 'task_name',
                iscsi: 1,
                s3: 1,
                allowBlank: false,
                fieldLabel: WORDS['task_name'],
                vtype: 'AliasName'
            },
            {
                xtype: 'radiogroup',
                key: 'back_type',
                iscsi: 0,
                s3: 0,
                fieldLabel: WORDS['back_type'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'back_type'
                },
                items: [
                    {
                        inputValue: 'realtime',
                        boxLabel: WORDS['realtime']
                    },
                    {
                        inputValue: 'schedule',
                        boxLabel: WORDS['schedule']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'sync_type',
                iscsi: 0,
                s3: 1,
                fieldLabel: WORDS['opts_sync_type'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'sync_type'
                },
                items: [
                    {
                        inputValue: 'sync',
                        boxLabel: WORDS['opts_sync_sync'],
                        checked: true
                    },
                    {
                        inputValue: 'incremental',
                        boxLabel: WORDS['opts_incremental_sync']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'compress',
                iscsi: 0,
                s3: 0,
                fieldLabel: WORDS['opts_compress'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'compress'
                },
                items: [
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'backup_conf',
                iscsi: 0,
                s3: 0,
                fieldLabel: WORDS['opts_backup_conf'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'backup_conf'
                },
                items: [
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'partial',
                iscsi: 0,
                s3: 0,
                fieldLabel: WORDS['opts_partial'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'partial'
                },
                items: [
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'inplace',
                iscsi: 0,
                s3: 0,
                fieldLabel: WORDS['opts_inplace'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'inplace'
                },
                items: [
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_enable']
                    }
                ],
                listeners: {
                    change: function(radiogroup, radio) {
                                if (radio == 1) {
                                    ui['sparse'].setValue(false);
                                    ui['sparse'].disable();
                                    ui['partial'].setValue(false);
                                    ui['partial'].disable();
                                }else{
                                    ui['sparse'].enable();
                                    ui['partial'].enable();
                                }
                            }
                }
            },
            {
                xtype: 'radiogroup',
                key: 'sparse',
                iscsi: 0,
                s3: 0,
                fieldLabel: WORDS['opts_sparse'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'sparse'
                },
                items: [
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'acl',
                iscsi: 0,
                s3: 0,
                fieldLabel: WORDS['opts_acl'],
                width: '100%',
                columns: [150, 150],
                defaults: {
                    name: 'acl'
                },
                items: [
                    {
                        inputValue: '0',
                        boxLabel: WORDS['opts_disable'],
                        checked: true
                    },
                    {
                        inputValue: '1',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                xtype: 'combo',
                key: 'log_folder',
                iscsi: 1,
                s3: 1,
                fieldLabel: WORDS['opts_log_folder'],
                readOnly: true,
                editable: false,
                allowBlank: false,
                displayField: 'name',
                valueField: 'name',
                typeAhead: false,
                triggerAction: 'all',
                mode: 'local',
                listWidth: 150,
                forceSelection: true,
                selectOnFocus:true,
                store: new Ext.data.SimpleStore({
                    fields: ['name']
                })
            },
            {
                layout: 'column',
                items: [
                    {
                        xtype: 'label',
                        width: 125,
                        text: WORDS['speed_limit'] + ':'
                    },
                    {
                        xtype: 'textfield',
                        key: 'speed_limit_KB',
                        listeners: listeners,
                        width: 50,
                        allowBlank: false,
                        value: 0,
                        fieldLabel: WORDS['speed_limit'],
                        vtype: 'Numbers'
                    },
                    {
                        xtype: 'label',
                        text: 'KB/Sec' + WORDS['speed_limit_notice']
                    }
                ]
            },
            {
                layout: 'column',
                items: [
                    {
                        xtype: 'label',
                        width: 125,
                        text: WORDS['timeout'] + ':'
                    },
                    {
                        xtype: 'textfield',
                        key: 'timeout',
                        listeners: listeners,
                        width: 50,
                        allowBlank: false,
                        value: 600,
                        fieldLabel: WORDS['timeout'],
                        vtype: 'Numbers'
                    },
                    {
                        xtype: 'label',
                        text: 'Sec'
                    }
                ]
            },
            {
                xtype: 'fieldset',
                checkboxToggle:true,
                collapsed: true,
                title: WORDS['opts_schedule_enable'],
                autoHeight: true,
                hideBorders: true,
                listeners:{
                    expand: onEnableSchedule,
                    collapse: onDisableSchedule
                },
                items: [
                    {
                        layout: 'table',
                        items: [
                            {
                                xtype: 'box',
                                width: 115,
                                autoEl: {
                                    style: 'width: 100px',
                                    html: WORDS['time'] + ':'
                                }
                            },
                            {
                                xtype: 'combo',
                                displayField: 'hour',
                                listWidth: 40,
                                editable: false,
                                valueField: 'hour',
                                typeAhead: false,
                                triggerAction: 'all',
                                allowBlank: false,
                                listeners: listeners,
                                mode: 'local',
                                key: 'schedule_hr',
                                value: '00',
                                store: new Ext.data.SimpleStore({
                                    fields: ['hour'],
                                    data:  function(){
                                        var hour = [];
                                        for( var i = 0 ; i < 24 ; i++ ) {
                                            i = i.toString();
                                            if(i.length == '1'){
                                                i = '0'+i;
                                            }
                                            hour.push([i]);
                                        }
                                        return hour;
                                    }()
                                })
                            },
                            {
                                xtype: 'box',
                                autoEl: {
                                    tag: 'center',
                                    style: 'width: 20px',
                                    html: ':'
                                }
                            },
                            {
                                xtype: 'combo',
                                listWidth: 40,
                                editable: false,
                                displayField: 'mintue',
                                valueField: 'mintue',
                                typeAhead: false,
                                triggerAction: 'all',
                                listeners: listeners,
                                allowBlank: false,
                                mode: 'local',
                                key: 'schedule_min',
                                value: '00',
                                store: new Ext.data.SimpleStore({
                                    fields: ['mintue'],
                                    data:  function(){
                                        var mintue = [];
                                        for( var i = 0 ; i < 60 ; i++ ) {
                                            i = i.toString();
                                            if(i.length == '1'){
                                                i = '0'+i;
                                            }
                                            mintue.push([i]);
                                        }
                                        return mintue;
                                    }()
                                })
                            }
                        ]
                    },
                    {
                        layout: 'table',
                        items: [
                            {
                                xtype: 'box',
                                width: 115,
                                autoEl: {
                                    style: 'width: 100px',
                                    html: WORDS['schedule'] + ':'
                                }
                            },
                            {
                                xtype: 'radiogroup',
                                key: 'schedule_type',
                                listeners: listeners,
                                width: '100%',
                                columns: [100, 100, 100],
                                defaults: {
                                    name: 'schedule_type'
                                },
                                items: [
                                    {
                                        inputValue: 'monthly',
                                        boxLabel: WORDS['monthly']
                                    },
                                    {
                                        inputValue: 'weekly',
                                        boxLabel: WORDS['weekly']
                                    },
                                    {
                                        inputValue: 'daily',
                                        boxLabel: WORDS['daily']
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        layout: 'table',
                        style: 'margin-left:115px;',
                        items:[
                            {
                                xtype: 'combo',
                                typeAhead: false,
                                hideLabel: true,
                                editable: false,
                                disabled: true,
                                triggerAction: 'all',
                                allowBlank: false,
                                displayField: 'dates',
                                valueField: 'dates',
                                mode: 'local',
                                key: 'schedule_date',
                                listeners: listeners,
                                value: '01',
                                store: new Ext.data.SimpleStore({
                                    fields: ['dates'],
                                    data: function(){
                                        var dates = [];
                                        for( i = 1 ; i <= 31 ; i++ ) {
                                            i = i.toString();
                                            if(i.length == '1'){
                                                i = '0'+i;
                                            }
                                            dates.push([i]);
                                        }
                                        return dates;
                                    }()
                                })
                            },
                            {
                                width: 50
                            },
                            {
                                xtype: 'combo',
                                typeAhead: false,
                                hideLabel: true,
                                editable: false,
                                disabled: true,
                                triggerAction: 'all',
                                allowBlank: false,
                                displayField: 'k',
                                valueField: 'v',
                                mode: 'local',
                                key: 'schedule_week',
                                listeners: listeners,
                                value: '01',
                                store: new Ext.data.SimpleStore({
                                    fields: ['k', 'v'],
                                    data: [
                                        [WORDS['Monday'], '01'],
                                        [WORDS['Tuesday'], '02'],
                                        [WORDS['Wednesday'], '03'],
                                        [WORDS['Thursday'], '04'],
                                        [WORDS['Friday'], '05'],
                                        [WORDS['Saturday'], '06'],
                                        [WORDS['Sunday'], '00']
                                    ]
                                })
                            }
                        ]
                    }
                ]
            },
            {
                xtype: 'label',
                style: 'color:blue;',
                hidden: true,
                text: WORDS['disable_schedule_notice']
            }
        ]
    });
    
    
    
    function onEnableSchedule(){
        if( self.pool.rs ) {
            opts['schedule_enable'] = '1';
            self.items.get(13).hide();
        }
    }
    
    function onDisableSchedule(){
        if( self.pool.rs ) {
            opts['schedule_enable'] = '0';
            self.items.get(13).show();
        }
    }
    
    function mapObjKey(ct) {
        if(ct.hasOwnProperty('key')) {
            ui[ct.key] = ct;
        }
    }
    
    function dataChange(ct, newValue, oldValue) {
        var key = ct.key;
        
        if( !ct.validate() ){
            return;
        }
        
        switch(key){
            case 'task_name':
                self.pool.rs[key] = newValue;
                ajax.CheckTaskName(self.pool.rs.tid, newValue, axCheckTaskName);
                break;
            
            case 'back_type':
                onChangeBackType(newValue);
                self.pool.rs[key] = newValue;
                break;
                
            case 'schedule_type':
                onChangeScheduleType(newValue)
                self.pool.rs.opts[key] = newValue;
                break;
            
            default:
                self.pool.rs.opts[key] = newValue;
        }
    }
    
    function axCheckTaskName(code, legal) {
        if( legal == false ) {
            Ext.MessageBox.alert(WORDS['attention'], WORDS['task_name_existed']);
            Ext.getCmp('finish').setDisabled(false);
        } else {
            if( finishAction ) {
                saveBackupTime();
                self.fireEvent('finish');
            }
        }
    }
    
    function onShow(){
        var preStep = '';
        self.navigator = ' ';
        finishAction = false;
        opts = self.pool.rs['opts'];
        loadOption();
        ajax.ListLogFolder(axListLogFolder);
        
        if(self.pool.rs.act_type == 'remote' && opts.remote_back_type == 'full'){
            preStep = 'DGRemoteTestStep';
        }else{
            preStep = 'DGRemoteBackupGridStep';
        }
        
        if(self.pool.rs.act_type == 's3'){
            self.items.get(10).hide();
            self.items.get(11).hide();
        }else{
            self.items.get(10).show();
            self.items.get(11).show();
        }
        
        self.fireEvent('btns', {0:['s'], 1:['h'], 2:['s','e'], 3:['s'], 4:['h']});
        self.fireEvent('steps', preStep, null);
    }
    
    function onChangeBackType(v){
        var schedule_enable = opts['schedule_enable'];
        switch(v){
            case 'realtime':
                self.items.get(12).hide().collapse();
                self.items.get(13).hide();
                opts['schedule_enable'] = schedule_enable;
                break;
            
            case 'schedule':
                if(schedule_enable == '0'){
                    self.items.get(12).show().collapse();
                    self.items.get(13).show();
                }else{
                    self.items.get(12).show().expand();
                    self.items.get(13).hide();
                }
                break;
        }
    }
    
    function onChangeScheduleType(v){
        switch(v){
            case 'weekly':
                ui['schedule_week'].enable();
                ui['schedule_date'].disable();
                break;
            
            case 'monthly':
                ui['schedule_week'].disable();
                ui['schedule_date'].enable();
                break;
            
            case 'daily':
                ui['schedule_week'].disable();
                ui['schedule_date'].disable();
                break;
        }
    }
    
    function loadOption() {
        var rs = self.pool.rs;
        
        Ext.applyIf(rs, {
            task_name: '',
            back_type: 'realtime'
        });
        
        Ext.applyIf(rs.opts, {
            compress: '0',
            backup_conf: '0',
            sparse: '0',
            sync_type: 'sync',
            partial: '0',
            inplace: '0',
            acl: '0',
            log_folder: '',
            speed_limit_KB: 0,
            timeout: 600,
            schedule_hr: '00',
            schedule_min: '00',
            schedule_type: 'daily',
            schedule_date: '00',
            schedule_week: '01'
        });
        
        for( var key in ui){
            var v = rs[key] || opts[key];
            
            if(key == 'schedule_type'){
                onChangeScheduleType(v);
            }
            
            if(key == 'back_type'){
                onChangeBackType(v);
            }
            
            ui[key].setValue(v);
        }
        
        showHideOpts();
    }
    
    function showHideOpts(){
        var item;
        
        if( self.pool.rs['act_type'] == 's3'){
            for( var i=0; i<self.items.length; i++){
                item = self.items.get(i);
                if( typeof(item.s3) != 'undefined' && !item.s3 ){
                    item.disable().hide();
                    item.getEl().up('.x-form-item').setDisplayed(false);
                }
            }
            ui['back_type'].setValue('schedule');
            ui['back_type'].items.get(0).disable();
        }else{
            if(opts['remote_back_type'] == 'iscsi'){
                for( var i=0; i<self.items.length; i++){
                    item = self.items.get(i);
                    if( typeof(item.iscsi) != 'undefined' && !item.iscsi ){
                        item.disable().hide();
                        item.getEl().up('.x-form-item').setDisplayed(false);
                    }
                }
                ui['back_type'].setValue('schedule');
                ui['back_type'].items.get(0).disable();
            }else{
                for( var i=0; i<self.items.length; i++){
                    item = self.items.get(i);
                    if( typeof(item.iscsi) != 'undefined' ){
                        item.enable().show();
                        item.getEl().up('.x-form-item').setDisplayed(true);
                    }
                }
                ui['back_type'].items.get(0).enable();
            }
        }
    }
    
    function saveBackupTime() {
        switch(opts['schedule_type']){
            case 'daily':
                opts['scheduled_date'] = '*';
                opts['scheduled_month'] = '*';
                opts['scheduled_week'] = '*';
                break;
            case 'weekly':
                opts['scheduled_date'] = '*';
                opts['scheduled_month'] = '*';
                opts['scheduled_week'] = ui['schedule_week'].getValue().toString();
                break;
            case 'monthly':
                opts['scheduled_date'] = ui['schedule_date'].getValue().toString();
                opts['scheduled_month'] = '*';
                opts['scheduled_week'] = '*';
                break;
            
        }
        var schedule_time_array = [
            ui['schedule_min'].getValue(),
            ui['schedule_hr'].getValue(),
            opts['scheduled_date'],
            opts['scheduled_month'],
            opts['scheduled_week']
        ];
        opts['backup_time'] = schedule_time_array.join(",");
    }
    
    function validate(){
        invalidMsg = '';
        for( var key in ui ) {
            if( !ui[key].validate() ) {
                ui[key].markInvalid();
                invalidMsg = ui[key].fieldLabel;
                return invalidMsg;
            }
        }
        return;
    }
    
    function finish() {
        if( !validate() ){
            opts['log_folder'] = ui['log_folder'].getValue();
            finishAction = true;
            Ext.getCmp('finish').setDisabled(true);
            ajax.CheckTaskName(
                self.pool.rs.tid,
                self.pool.rs.task_name,
                axCheckTaskName
            );
            return false;
        }else{
            Ext.MessageBox.alert(WORDS['attention'], '"' + invalidMsg + '" ' + WORDS['opts_invalid']);
            return false;
        }
    }
    self.finish = finish;
    
    function axListLogFolder(code, list) {
        ui.log_folder.store.loadData(list);
        if(!opts['log_folder']){
            ui.log_folder.setValue(list[0][0]);
        }
    }
    
    TCode.DataGuard.RemoteOptionPanel.superclass.constructor.call(self, config);
    
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.RemoteOptionPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.RemoteTestPanel = function(c) {
    var self = this,
        ui = {},
        listeners = {
            render: mapObjKey,
            change: dataChange
        },
        opts = {},
        axStatusItem = {},
        tid,
        preStep;
    
    var ajax = TCode.DataGuard.Ajax;
    ajax.on('TestRemoteHost', axTestRemoteHost);
    
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGRemoteTestStep',
        autoHeight: true,
        layout: 'form',
        labelWidth: 120,
        defaults:{
            listeners: listeners
        },
        items: [
            {
                layout: 'table',
                width: '100%',
                columns: 2,
                items: [
                    {
                        layout: 'form',
                        labelWidth: 120,
                        defaults: {
                            listeners: listeners
                        },
                        items: {
                            key: 'ip',
                            xtype: 'textfield',
                            fieldLabel: WORDS['opts_remote_target'],
                            allowBlank: false,
                            vtype: 'NETHost'
                        }
                    },
                    {
                        layout: 'form',
                        labelWidth: 40,
                        style: 'margin-left:20px;',
                        defaults: {
                            listeners: listeners
                        },
                        items: {
                            key: 'port',
                            xtype: 'textfield',
                            allowBlank: false,
                            value: '873',
                            width: 50,
                            fieldLabel: WORDS['opts_port'],
                            vtype: 'Port'
                        }
                    }
                ]
            },
            {
                xtype: 'radiogroup',
                key: 'encryption',
                fieldLabel: WORDS['opts_ssh'],
                columns: [100, 100],
                defaults: {
                    listeners: listeners
                },
                items: [
                    {
                        inputValue: '0',
                        name: 'encryption',
                        boxLabel: WORDS['opts_disable']
                    },
                    {
                        inputValue: '1',
                        name: 'encryption',
                        boxLabel: WORDS['opts_enable']
                    }
                ]
            },
            {
                key: 'username',
                xtype: 'textfield',
                allowBlank: false,
                fieldLabel: WORDS['opts_username'],
                vtype: 'UserName'
            },
            {
                key: 'passwd',
                xtype: 'textfield',
                id: 'rsync_passwd',
                inputType:'password',
                allowBlank: false,
                fieldLabel: WORDS['opts_passwd'],
                vtype: 'RsyncPassword'
            },
            {
                layout: 'table',
                columns: 3,
                items: [
                    {
                        layout: 'form',
                        labelWidth: 120,
                        defaults: {
                            listeners: listeners
                        },
                        items: {
                            width: 70,
                            key: 'dest_folder',
                            xtype: 'textfield',
                            fieldLabel: WORDS['opts_target_folder']
                        }
                    },
                    {
                        xtype: 'box',
                        width: 20,
                        autoEl: {
                            tag: 'center',
                            html: '/'
                        }
                    },
                    {
                        layout: 'form',
                        defaults: {
                            listeners: listeners
                        },
                        items: {
                            width: 70,
                            key: 'subfolder',
                            xtype: 'textfield',
                            hideLabel: true
                        }
                    },
                    {
                        xtype: 'box',
                        autoEl: {
                            tag: 'img',
                            'class': 'red-hint',
                            src: '/theme/images/icons/fam/icon-question.gif',
                            'ext:qtip': String.format('<em>{0}</em>', WORDS['subfolder']),
                            'ext:qclass': 'red-hint'
                        }
                    }
                ]
            },
            {
                xtype: 'button',
                text: WORDS['connect_test'],
                style: 'margin-bottom:5px;',
                handler: onRemoteTest
            },
            {
                xtype: 'label',
                style: 'color:blue;',
                text: ''
            }
        ]
    });
    
    function mapObjKey(ct) {
        if(ct.hasOwnProperty('key')) {
            ui[ct.key] = ct;
        }
    }
    
    function dataChange(ct, newValue, oldValue) {
        var key = ct.key;
        if( ct.validate() ) {
            if ( newValue != oldValue ) {
                self.fireEvent('btns', {0: ['s'], 1: ['h'], 2:['h'], 3:['s'], 4:['h']});
            }
            self.pool.rs.opts[key] = newValue;
        }
        
        if(tid){
            setAxStatusText(WORDS['connect_msg_modified']);
            self.fireEvent('btns', {1:['h']});
        }
    }
    
    function onRender() {
        axStatusItem = self.items.get(self.items.length-1);
    }
    
    function setLabel(field,label){
        var el = field.el.dom.parentNode.parentNode;
        if( el.children[0].tagName.toLowerCase() === 'label' ) {
            el.children[0].innerHTML =label;
        }else if( el.parentNode.children[0].tagName.toLowerCase() === 'label' ){
            el.parentNode.children[0].innerHTML =label;
        }
    }
    
    function onShow() {
        tid = self.pool.rs.tid;
        opts = self.pool.rs['opts'];
        
        var pathItem = self.items.get(4);
        if(self.pool.rs['act_type'] == 'restoreConfig' || opts.remote_back_type == 'full'){
            pathItem.hide();
        }else{
            pathItem.show();
        }
        
        switch(self.pool.rs['act_type']){
            case 's3':
                self.navigator = WORDS['amazon_s3'];
                self.items.get(0).hide();
                self.displayLabelItem(ui['encryption'], false);
                preStep = 'DGBackupTypeStep';
                setLabel(ui['username'], 'Access Key ID' + '：');
                setLabel(ui['passwd'], ' Secret Access Key' + '：');
                setLabel(ui['dest_folder'], 'Bucket' + '：');
                Ext.apply(ui['username'], {
                    vtype: ''
                });
                Ext.apply(ui['passwd'], {
                    vtype: ''
                });
                Ext.apply(ui['dest_folder'], {
                    allowBlank: false
                });
                break;
            case 'remote':
                switch(self.pool.rs.opts['remote_back_type']){
                    case 'full':
                        self.navigator = WORDS['remote_full'];
                        break;
                    case 'custom':
                        self.navigator = WORDS['remote_custom'];
                        break;
                    case 'iscsi':
                        self.navigator = WORDS['remote_iscsi'];
                        break;
                }
                self.items.get(0).show();
                self.displayLabelItem(ui['encryption'], true);
                preStep = 'DGRemoteBackupTypeStep';
                setLabel(ui['username'], WORDS['opts_username'] + '：');
                setLabel(ui['passwd'], WORDS['opts_passwd'] + '：');
                setLabel(ui['dest_folder'], WORDS['opts_target_folder'] + '：');
                Ext.apply(ui['username'], {
                    vtype: 'UserName'}
                );
                Ext.apply(ui['passwd'], {
                    vtype: 'RsyncPassword'
                });
                Ext.apply(ui['dest_folder'], {
                    allowBlank: true
                });
                break;
        }
        
        loadOption();
        
        if(self.pool.rs['act_type'] == 'restoreConfig' || tid){
            self.fireEvent('btns', {0:['h'], 1:['h'], 2: ['h'], 3:['s'], 4:['h']});
            self.fireEvent('steps', null, null);
        }else{
            self.fireEvent('btns', {0:['s','e'], 1:['h'], 2: ['h'], 3:['s'], 4:['h']});
            self.fireEvent('steps', preStep, null);
        }
        setAxStatusText('');
    }
    
    function setAxStatusText(msg){
        axStatusItem.setText(msg);
    }
    
    function onRemoteTest() {
        setAxStatusText('');
        pattern = /^[\w\[\]\@\%\/\*]*$/
        r_passwd = Ext.getCmp('rsync_passwd').getValue()
        check_passwd = pattern.test(r_passwd)
        if(!check_passwd){
            setAxStatusText('<{$rsync_target_words.special_characters}>');
            return;
        }
        ui['dest_folder'].clearInvalid();
        if(!ui['dest_folder'].getValue() && ui['subfolder'].getValue()){
            setAxStatusText(WORDS['connect_msg_no_dest_folder']);
            ui['dest_folder'].markInvalid();
            return;
        }
        
        if( saveOption() ) {
            TCode.DataGuard.Wizard.getEl().mask(WORDS['remote_testing'], 'ext-el-mask-msg x-mask-loading');
            if( self.pool.rs['act_type'] == 's3'){
                ajax.S3ConnTest(
                    opts['dest_folder'],
                    opts['username'],
                    opts['passwd'],
                    axTestRemoteHost
                );
            }else{
                ajax.TestRemoteHost(
                    opts['ip'],
                    opts['port'],
                    opts['dest_folder'],
                    opts['username'],
                    opts['passwd'],
                    null,
                    null,
                    opts['encryption'],
                    axTestRemoteHost
                );
            }
        } else {
            setAxStatusText(WORDS['connect_msg_invalid']);
        }
    }
    
    function loadOption() {
        opts['port'] = opts['port'] || '873';
        opts['encryption'] = opts['encryption'] || '0';
        opts['ip'] = (self.pool.rs['act_type'] == 's3') ? 's3.amazon.com' : opts['ip'];
        
        for(var key in ui ) {
            ui[key].setValue(opts[key]);
        }
    }
    
    function saveOption() {
        for(var key in ui ) {
            if( ui[key].validate() ) {
                self.pool.rs.opts[key] = ui[key].getValue();
            } else {
                return false;
            }
        }        
        return true;
    }
    
    function axTestRemoteHost(code) {
        var msg = '';
        var act_type = self.pool.rs['act_type'];
        var nextStep = null;
        
        if( code == 0 ) {
            msg = WORDS['connect_msg_pass'];
            self.fireEvent('btns', {0: ['h'], 1: ['s','e'],2:['h'], 3:['s'], 4:['h']});
            switch(act_type){
                case 'remote':
                    if(opts.remote_back_type == 'full'){
                        nextStep = 'DGRemoteOptionStep';
                    }else{
                        nextStep = 'DGRemoteBackupGridStep';
                    }
                    break;
                
                case 'restoreConfig':
                    nextStep = 'DGRestoreConfigGridStep';
                    break;
                
                case 'local':
                    nextStep = 'DGBackupGridStep';
                    break;
                
                case 's3':
                    nextStep = 'DGRemoteBackupGridStep';
                    break;
            }
            self.fireEvent('steps', null, nextStep);
        } else {
            msg = TCode.DataGuard.Error.format(code);
        }
        setAxStatusText(msg);
        TCode.DataGuard.Wizard.getEl().unmask();
    }
    
    function cancel(){
        setAxStatusText('');
        return true;
    }
    self.cancel = cancel;
    
    TCode.DataGuard.RemoteTestPanel.superclass.constructor.call(self, config);
    
    self.on('render', onRender);
    self.on('show', onShow)
}
Ext.extend(TCode.DataGuard.RemoteTestPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.RemoteBackupGridPanel = function(c) {
    var self = this;
    var opts = {};
    var ui = {};
    var grid;
    var selecteItems = [];
    var chooseRoot = false,
        enterSubfolder = true,
        multi = true,
        devFilter = {
            'raid': true,
            'iscsi': false,
            'external': false
        };
    
    var ajax = TCode.DataGuard.Ajax;
    
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGRemoteBackupGridStep',
        bodyStyle: 'padding: 5px',
        autoScroll: false,
        defaults: {
            style: 'margin-bottom: 5px',
            width: 450
        },
        items: [
            {
                xtype: 'box',
                autoEl: {
                    tag: 'div',
                    html: WORDS['remote_backup_grid_notice']
                }
            },
            new TCode.DataGuard.FolderGrid({
                title: WORDS['remote_backup_grid_title'],
                frame: true,
                listeners: {
                    selected: onFolderGridSelected
                }
            }),
            {
                xtype: 'label',
                style: 'color:red;display:block;',
                text: ''
            }
        ]
    });
    
    function setMsg(msg){
        self.items.get(2).setText(msg);
    }
    
    function onRender() {
        grid = self.items.get(1);
    }
    
    function axRassembleDevInfo(code, result){
        if( code == 0 ){
            opts['src_dev'] = result.src['dev'] || '';
            opts['src_path'] = result.src['path'] || '/';
            opts['src_folder'] = result.src['folder'] || '';
            opts['src_model'] = result.src['model'] || '';
            
            grid.loadPath(opts['src_dev'], opts['src_path'], opts['src_model'], chooseRoot, enterSubfolder, multi, devFilter, opts['src_folder'].split('/'), '0');
        }else{
            Ext.MessageBox.alert(WORDS['attention'], WORDS['0x08002011']);
        }
    }
    
    function onShow() {
        self.navigator = ' ';
        setMsg('');
        opts = self.pool.rs['opts'];
        opts['src_dev'] = opts['src_dev'] || '';
        opts['src_path'] = opts['src_path'] || '/';
        opts['src_folder'] = opts['src_folder'] || '';
        
        selecteItems = {
            source: {
                'dev': opts['src_dev'],
                'model': opts['src_model'],
                'uuid': opts['src_uuid'],
                'path': opts['src_path'],
                'folder': opts['src_folder']
            }
        };
        
        if(opts['remote_back_type'] == 'iscsi'){
            chooseRoot = true;
            enterSubfolder = false;
            multi = false;
            devFilter = {
                'raid': false,
                'iscsi': true,
                'external': false
            }
        }
        
        if(self.pool.rs['tid'] != 0){
            ajax.RassembleDevInfo(selecteItems['source'], '', self.pool.rs['tid'], axRassembleDevInfo);
        }else{
            grid.loadPath(opts['src_dev'], opts['src_path'], opts['src_model'], chooseRoot, enterSubfolder, multi, devFilter, opts['src_folder'].split('/'), '0');
        }
        
        if(opts['src_folder']){
            self.fireEvent('btns', {0: ['s'], 1: ['s','e'], 2:['h'], 3:['s'], 4:['h']});
            self.fireEvent('steps', 'DGRemoteTestStep', 'DGRemoteOptionStep');
        }else{
            self.fireEvent('btns', {0: ['s'], 1: ['h'], 2:['h'], 3:['s'], 4:['h']});
            self.fireEvent('steps', 'DGRemoteTestStep', null);
        }
    }
    
    function onFolderGridSelected(dev, model, uuid, path, selected) {
        if(selected != ''){
            opts['src_dev'] = dev;
            opts['src_model'] = model;
            opts['src_uuid'] = uuid;
            opts['src_path'] = path;
            opts['src_folder'] = selected;
            
            self.fireEvent('btns', {0: ['s'], 1: ['s','e'], 2:['h'], 3:['s'], 4:['h']});
            self.fireEvent('steps', 'DGRemoteTestStep', 'DGRemoteOptionStep');
        }else{
            self.fireEvent('btns', {0: ['s'], 1: ['h'], 2:['h'], 3:['s'], 4:['h']});
            self.fireEvent('steps', 'DGRemoteTestStep', null);
        }
    }
    
    function next(){
        if(opts['dest_folder']){
            return true;
        }else{
            switch(self.pool.rs['act_type']){
                case 's3':
                    ajax.S3ConnTest(
                        null,
                        null,
                        opts['dest_folder'],
                        opts['username'],
                        opts['passwd'],
                        opts['src_uuid'],
                        opts['src_path'],
                        opts['src_folder'],
                        null,
                        axTestRemoteHost
                    );
                    break;
                case 'remote':
                    ajax.TestRemoteHost(
                        opts['ip'],
                        opts['port'],
                        opts['dest_folder'],
                        opts['username'],
                        opts['passwd'],
                        opts['src_path'],
                        opts['src_folder'],
                        opts['encryption'],
                        axTestRemoteHost
                    );
                    break;
            }
        }
    }
    self.next = next;
    
    function axTestRemoteHost(code){
        if(code == 0){
            self.fireEvent('next', 'DGRemoteOptionStep');
        }else{
            var msg = TCode.DataGuard.Error.format(code);
            setMsg(WORDS['attention'] + '! ' + msg);
        }
    }
    
    TCode.DataGuard.RemoteBackupGridPanel.superclass.constructor.call(self, config);
    
    self.on('render', onRender);
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.RemoteBackupGridPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.RestoreConfigGridPanel = function(c) {
    var self = this;
    var opts = {};
    
    var ajax = TCode.DataGuard.Ajax;
    
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGRestoreConfigGridStep',
        bodyStyle: 'padding: 5px',
        items: [
            {
                xtype: 'fieldset',
                title: WORDS['attention'],
                autoHeight: true,
                defaults: {
                    style: 'padding:5px;'
                },
                items: [
                    {
                        xtype: 'box',
                        autoEl: {
                            tag: 'div',
                            style: 'margin:5px;',
                            html: WORDS['restore_config_notice']
                        }
                    },
                    {
                        xtype: 'button',
                        text: WORDS['download'],
                        handler: function(){
                            location.href = '../adm/getmain.php?fun=d_conf&action_do=Download';
                        }
                    }
                ]
            },
            {
                xtype: 'grid',
                title: WORDS['conf_list'],
                hideHeaders: false,
                height: 240,
                width: 450,
                viewConfig: {
                    forceFit: true
                },
                sm:new Ext.grid.RowSelectionModel({
                    singleSelect:true,
                    listeners: {
                        rowselect: onRowSelect,
                        rowdeselect: onRowDeselect
                    }
                }),
                store: new Ext.data.SimpleStore({
                    fields: ['file', 'date']
                }),
                columns: [
                    {
                        header: WORDS['conf_name'],
                        dataIndex: 'file'
                    },
                    {
                        header: WORDS['conf_backup_date'],
                        dataIndex: 'date'
                    }
                ]
            }
        ]
    });
    
    function onShow() {
        opts = self.pool.rs['opts'];
        
        ajax.ListNasConfig(self.pool.rs, axListNasConfig);
        
        self.fireEvent('btns', {0:['h'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', null, null);
    }
    
    function onRowSelect(sm, rowIdx, r){
        opts.restoreConfigName = r.data.name;
        self.fireEvent('btns', {0:['h'], 1:['s','e'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', null, 'DGRestoreConfigGridStep');
    }
    
    function onRowDeselect(){
        opts.restoreConfigName = '';
        self.fireEvent('btns', {0:['h'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
        self.fireEvent('steps', null, null);
    }
    
    function next() {
        var rs = self.items.get(1).selModel.getSelected();
        if( rs ) {
            var file = rs.get('file');
            ajax.GetNasConfig(self.pool.rs, file, axGetNasConfig);
        }
        return false;
    }
    self.next = next;
    
    function axListNasConfig(code, config) {
        if( code == 0 ) {
            self.items.get(1).store.loadData(config);
        } else {
            TCode.DataGuard.Error.alert(code);
        }
    }
    
    function axGetNasConfig(code) {
        if( code == 0 ) {
            self.fireEvent('next', 'DGOrphanFolderStep');
        } else {
            TCode.DataGuard.Error.alert(code);
        }
    }
    
    TCode.DataGuard.RestoreConfigGridPanel.superclass.constructor.call(self, config);
    
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.RestoreConfigGridPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.OrphanFolderPanel = function(c) {
    var self = this,
        grid,
        raidRule,
        raidInfo,
        raidStore,
        ajax = TCode.DataGuard.Ajax;
    
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGOrphanFolderStep',
        bodyStyle: 'padding: 5px',
        defaults: {
            style: 'margin-bottom: 10px',
            width: 450
        },
        layout: 'form',
        items: [
            {
                xtype: 'fieldset',
                autoHeight: true,
                title: WORDS['folder_nonexist'],
                html: WORDS['folder_nonexist_abstract']
            },
            {
                xtype: 'editorgrid',
                hideHeaders: false,
                height: 270,
                frame: true,
                clicksToEdit: 1,
                viewConfig: {
                    forceFit: true
                },
                sm:new Ext.grid.RowSelectionModel({
                    singleSelect: true
                }),
                store: new Ext.data.SimpleStore({
                    fields: ['raid_md', 'raid_id']
                }),
                columns: [
                    {
                        header: WORDS['conf_raid_setting'],
                        dataIndex: 'raid_id'
                    },
                    {
                        header: 'RAID',
                        dataIndex: 'raid_md',
                        renderer: onImportRaid,
                        editor: new Ext.form.ComboBox({
                            store: new Ext.data.SimpleStore({
                                fields: ['raid_md', 'raid_id']
                            }),
                            listWidth: 200,
                            editable: false,
                            displayField: 'raid_id',
                            valueField: 'raid_md',
                            typeAhead: false,
                            triggerAction: 'all',
                            allowBlank: false,
                            mode: 'local',
                            lazyRender: true,
                            listeners: {
                                render: function(combo) {
                                    combo.store.loadData(raidInfo);
                                }
                            }
                        })
                    }
                ]
            },
            {
                xtype: 'box',
                style: 'margin:0;',
                autoEl: {
                    tag: 'center',
                    style: 'color:blue;',
                    html: WORDS['restore_conf_reboot']
                }
            }
        ]
    });
    
    function onRender() {
        grid = self.items.get(1);
    }
    
    function onImportRaid(v, obj, rs, row, index, store) {
        for( var i = 0 ; i < raidInfo.length ; ++i ) {
            if( Number(raidInfo[i][0]) == Number(v) ) {
                return raidInfo[i][1];
            }
        }
        return raidInfo[0][1];
    }
    
    function onShow() {
        ajax.GetRaidInfo(axGetRaidInfo);
        
        self.fireEvent('btns', {0:['s'], 1:['h'], 2:['s'], 3:['s'], 4:['h']});
        self.fireEvent('steps', 'DGRestoreConfigGridStep', null);
    }
    
    function axCheckNasConfig(code, raid) {
        if( code != 0 ) {
            return TCode.DataGuard.Error.alert(code);
        }
        if( raid.length == 0 ) {
            grid.hide();
        } else {
            grid.show();
            grid.store.loadData(raid);
        }
    }
    
    function finish() {
        var map = [];
        grid.store.each(function(rs){
            if( rs.modified ) {
                map.push([rs.data.raid_md, rs.modified.raid_md])
            } else {
                map.push([rs.data.raid_md, rs.data.raid_md])
            }
        });
        Ext.getCmp('finish').setDisabled(true);
        ajax.RestoreNasConfig(map, axRestoreNasConfig);
    }
    self.finish = finish;
    
    function axGetRaidInfo(code, info) {
        raidInfo = info;
        ajax.CheckNasConfig(axCheckNasConfig);
    }
    
    function axRestoreNasConfig(code) {
        if( code == 0 ) {
            TCode.DataGuard.Wizard.close();
            processUpdater('getmain.php','fun=reboot');
        } else {
            Ext.getCmp('finish').setDisabled(false);
            TCode.DataGuard.Error.alert(code);
        }
    }
    
    TCode.DataGuard.OrphanFolderPanel.superclass.constructor.call(self, config);
    
    self.on('render', onRender);
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.OrphanFolderPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.LogPanel = function(c) {
    var self = this,
        tid = 0,
        ui = [],
        ajax = TCode.DataGuard.Ajax;
    
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGLogStep',
        autoScroll: false,
        autoHeight: true,
        width: '100%',
        bodyStyle: 'padding: 5px',
        defaults: {
            style: 'margin-bottom: 10px',
            width: '100%'
        },
        layout: 'form',
        items: [
            {
                xtype: 'combo',
                listWidth: 250,
                editable: false,
                displayField: 'file',
                valueField: 'file',
                typeAhead: false,
                triggerAction: 'all',
                allowBlank: false,
                mode: 'local',
                fieldLabel: WORDS['log_list'],
                emptyText: WORDS['log_select_empty'],
                value: '',
                store: new Ext.data.SimpleStore({
                    fields: ['file']
                }),
                listeners: {
                    select: onSelectLog
                }
            },
            {
                xtype: 'textarea',
                height: 320,
                readOnly: true,
                hideLabel: true,
                autoScroll: true
            }
        ]
    });
    
    function onRender() {
        ui.push(self.items.get(0));
        ui.push(self.items.get(1));
    }
    
    function onShow() {
        tid = self.pool.rs.tid;
        ajax.ListLog(tid, axListLog);
        self.fireEvent('btns', {0:['h'], 1:['h'], 2:['h'], 3:['h'], 4:['s']});
        self.fireEvent('steps', null, null);
    }
    
    function onSelectLog(combo, rs, index) {
        var file = rs.data.file;
        ajax.GetLog(tid, file, axGetLog);
    }
    
    function axListLog(code, logs) {  
        if( !logs.length ){
            self.items.get(0).disable().setValue('No log files found.');
            self.items.get(1).setValue(WORDS['no_log']);
        }else{
            self.items.get(0).enable().setValue(WORDS['log_select_empty']);
            self.items.get(1).setValue('');
        }

        for( var i = 0 ; i < logs.length ; ++i ) {
            logs[i] = [logs[i]];
        }
        ui[0].store.loadData(logs);
    }
    
    function axGetLog(code, content) {
        ui[1].setValue(content);
    }
    
    function close(){
        ui[0].clearValue();
        ui[1].setValue('');
        return true;
    }
    self.close = close;
    
    TCode.DataGuard.LogPanel.superclass.constructor.call(self, config);
    
    self.on('render', onRender);
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.LogPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.ConfirmPanel = function(c) {
    var self = this,
        ajax = TCode.DataGuard.Ajax;
    
    c = Ext.apply({}, c);
    var config = Ext.apply(c, {
        id: 'DGConfirmStep',
        autoScroll: false,
        bodyStyle: 'padding: 5px',
        defaults: {
            style: 'margin-bottom: 10px'
        },
        layout: 'form',
        items: [
            {
                vtype: 'box',
                autoEl: {
                    tag: 'div',
                    html: '備份資料夾已不存在!'
                }
            }
        ]
    });
    
    function onRender() {

    }
    
    function onShow() {
        self.fireEvent('btns', {0:['h'], 1:['h'], 2:['s'], 3:['s'], 4:['h']});
        self.fireEvent('steps', null, null);
    }
    
    function finish() {
        
    }
    
    TCode.DataGuard.ConfirmPanel.superclass.constructor.call(self, config);
    
    self.finish = finish;
    self.on('render', onRender);
    self.on('show', onShow);
}
Ext.extend(TCode.DataGuard.ConfirmPanel, TCode.DataGuard.WizardPanelBase);

TCode.DataGuard.Wizard = function() {
    var self = this,
        record,
        mode,
        layout,
        preStep = null,
        nextStep = null,
        navigator = [];
    
    var defaults = {
        listeners: {
            steps: onCatchStepsEvent,
            btns: onCatchBtnsEvent,
            next: onGotoEvent,
            finish: finish
        }
    }
    
    var config = {
        layout: 'border',
        width: 640,
        height: 468,
        modal: true,
        resizable: false,
        closable: false,
        closeAction: 'hide',
        title: WORDS['winzard_title'],
        items: [
            {
                xtype: 'box',
                region: 'west',
                autoEl: {
                    tag: 'img',
                    src: '/theme/images/index/dataguard/dataguard.png',
                    width: 150,
                    height: 400
                }
            },
            {
                layout: 'card',
                region: 'center',
                activeItem: 0,
                frame: true,
                border: false,
                width: 476,
                bodyStyle: 'overflow-y: auto',
                items: [
                    new TCode.DataGuard.WizardPanelBase(defaults),
                    new TCode.DataGuard.BackupTypePanel(defaults),
                    new TCode.DataGuard.LocalBackupTypePanel(defaults),
                    new TCode.DataGuard.TaskFolderTypePanel(defaults),
                    new TCode.DataGuard.TaskFolderPanel(defaults),
                    new TCode.DataGuard.OptionPanel(defaults),
                    new TCode.DataGuard.DuplicateFolderPanel(defaults),
                    new TCode.DataGuard.RemoteBackupGridPanel(defaults),
                    new TCode.DataGuard.RemoteBackupTypePanel(defaults),
                    new TCode.DataGuard.RestoreConfigGridPanel(defaults),
                    new TCode.DataGuard.RemoteOptionPanel(defaults),
                    new TCode.DataGuard.RemoteTestPanel(defaults),
                    new TCode.DataGuard.OrphanFolderPanel(defaults),
                    new TCode.DataGuard.LogPanel(defaults),
                    new TCode.DataGuard.ConfirmPanel(defaults)
                ],
                listeners: {
                    afterlayout: function() {
                        var step = this.getLayout().activeItem.navigator;
                        var stepid = this.getLayout().activeItem.id;
                        if ( !step || step == 'DGBackupTypeStep' ) {
                            navigator.splice(0, navigator.length);
                        } else { 
                            if( navigator[navigator.length - 1] != step ) {
                                navigator.push(step);
                            }
                        }
                        
                        if ( stepid == 'DGBackupTypeStep' || stepid == 'DGLocalBackupTypeStep' || stepid == 'DGTaskFolderTypeStep' || stepid == 'DGTaskFolderStep' || stepid == 'DGRemoteBackupTypeStep' || stepid == 'DGRemoteTestStep' ) {
                            if ( navigator.length < 4 ) {
                                if ( navigator.length > 0 ) {
                                    self.setTitle(navigator.join(' > '));
                                } else {
                                    self.setTitle(WORDS['winzard_title']);
                                }
                            }
                        }
                    }
                }
            }
        ],
        buttons: [
            {
                id: 'pre',
                text: WORDS['prev'],
                btype: 'previous',
                handler: onButton
            },
            {
                id: 'next',
                text: WORDS['next'],
                btype: 'next',
                handler: onButton
            },
            {
                id: 'finish',
                text: WORDS['finish'],
                btype: 'finish',
                handler: onButton
            },
            {
                id: 'cancel',
                text: WORDS['cancel'],
                btype: 'cancel',
                handler: onButton
            },
            {
                id: 'close',
                text: WORDS['close'],
                btype: 'close',
                handler: onButton
            }
        ],
        listeners: {
            show: onShow,
            hide: onHide
        }
    }
    
    function onShow() {
        layout = self.items.get(1).layout;
        TCode.DataGuard.TaskStore.proxy.abort();
        Ext.getCmp('finish').setDisabled(false);
    }
    
    function onHide() {
        layout.setActiveItem(0);
    }
    
    function onButton(btn) {
        var action = btn.btype;
        var panel = layout.activeItem;
        if( typeof panel[action] == 'function' ) {
            if( !panel[action].call(panel) ) {
                return;
            }
        }
        
        switch(btn.btype) {
            case 'previous':
                if(preStep != null){
                    navigator.pop();
                    layout.setActiveItem(preStep);
                }
                break;
            
            case 'next':
                layout.setActiveItem(nextStep);
                break;
            
            case 'finish':
                finish();
                break;
            
            case 'cancel':
                record.reject();
                self.fireEvent('canceled', null);
                onCatchBtnsEvent({0:['h'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
                TCode.DataGuard.TaskStore.reload();
                self.hide();
                break;
            
            case 'close':
                close();
                break;
        }
    }
    
    function onCatchStepsEvent(pre, next) {
        preStep = pre;
        nextStep = next;
    }
    
    function onGotoEvent(step){
        layout.setActiveItem(step);
    }
    
    function onCatchBtnsEvent(config){
        for( key in config ) {
            var value = config[key];
            
            if(value[0] == 's'){
                self.buttons[key].show();
            }else if(value[0] == 'h'){
                self.buttons[key].hide();
            }
            
            if(value[1] == 'e'){
                self.buttons[key].setDisabled(false);
            }else if(value[1] == 'd'){
                self.buttons[key].setDisabled(true);
            }
        }
    }
    
    function create(rs){
        record = rs;
        record.beginEdit();
        mode = 'create';
        self.show();
        Ext.getCmp('DGBackupTypeStep').setConfig(record.data);
        layout.setActiveItem('DGBackupTypeStep');
    }

    function modify(rs){
        record = rs;
        record.beginEdit();
        mode = 'modify';
        self.show();
        Ext.getCmp('DGBackupTypeStep').setConfig(record.data);
        
        switch(rs.data.act_type){
            case 'remote':
                layout.setActiveItem('DGRemoteTestStep');
                break;
            case 'local':
                layout.setActiveItem('DGTaskFolderStep');
                break;
            case 's3':
                layout.setActiveItem('DGRemoteTestStep');
                break;
        }
    }
    
    function log(rs){
        record = rs;
        mode = 'log';
        self.show();
        Ext.getCmp('DGBackupTypeStep').setConfig(record.data);
        layout.setActiveItem('DGLogStep');
    }
    
    function restoreConfig(rs){
        record = rs;
        record.beginEdit();
        mode = 'restoreConfig';
        self.show();
        Ext.getCmp('DGBackupTypeStep').setConfig(record.data);
        layout.setActiveItem('DGRemoteTestStep');
    }
    
    function confirm(rs){
        record = rs;
        record.beginEdit();
        mode = 'confirm';
        self.show();
        Ext.getCmp('DGBackupTypeStep').setConfig(record.data);
        layout.setActiveItem('DGConfirmStep');
    }
    
    function finish() {
        self.fireEvent(mode, record);
        onCatchBtnsEvent({0:['s'], 1:['h'], 2:['s'], 3:['s'], 4:['h']});
        //self.hide();
    }
    
    function close() {
        onCatchBtnsEvent({0:['h'], 1:['h'], 2:['h'], 3:['s'], 4:['h']});
        self.hide();
    }
    
    Ext.Window.superclass.constructor.call(self, config);
    
    self.create = create;
    self.modify = modify;
    self.finish = finish;
    self.log = log;
    self.restoreConfig = restoreConfig;
    self.confirm = confirm;
    self.close = close;
    
    self.addEvents(['create', 'modify', 'canceled', 'restoreConfig']);
}
Ext.extend(TCode.DataGuard.Wizard, Ext.Window);

TCode.DataGuard.Wizard = new TCode.DataGuard.Wizard();

