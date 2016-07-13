<style>
.x-form-file-wrap {
    position: relative;
    height: 22px;
}

.x-form-file-wrap .x-form-file {
    position: absolute;
    right: 0;
    -moz-opacity: 0;
    filter:alpha(opacity: 0);
    opacity: 0;
    z-index: 2;
    height: 22px;
}

.x-form-file-wrap .x-form-file-btn {
    position: absolute;
    right: 0;
    z-index: 1;
}
    
.x-form-file-wrap .x-form-file-text {
    position: absolute;
    left: 0;
    z-index: 3;
    color: #777;
}
    
.upload-icon {
    background: url('<{$urlimg}>icons/fam/image_add.png') no-repeat 0 0 !important;
}

#fi-button-msg {
    border: 2px solid #ccc;
    padding: 5px 10px;
    background: #eee;
    margin: 5px;
    float: left;
}

</style>

<div id="DomUpgrade"></div>

<script type="text/javascript">
    
/**
 * This ClassUpgradeHelp can handle some picture or descrpation for each step.
 * 
 * @extends {Ext.Panel}
 */
ClassUpgradeHelp = Ext.extend(Ext.Panel, {
    id: 'UpgradeHelp',
    region: 'west',
    width: 150,
    border: false,
    cls: 'x-panel',
    html: '<img src="/theme/images/index/upgrade/firmwareUpgrade.png">',
    
    /**
     * Override Ext.Panel.initComponent
     * 
     * @override
     */
    initComponent: function() {
        ClassUpgradeHelp.superclass.initComponent.call(this);
    },
    
    /**
     * Setup an image source. (Not Implement!)
     * 
     * @param {string} src This image file will be display in help content.
     */
    setImage: function(src) {
    },
    
    /**
     * Steup help description for each upgrade procedure.
     * 
     * @param {string} html This description will be display as HTML format in help content.
     */
    setHelp: function(html) {
    }
});

/**
 *  This is an abstract class for each upgrade procedure.
 * 
 *  @extends {Ext.Panel}
 */
AbstractClassUpgradeContext = Ext.extend(Ext.Panel, {
    bodyStyle: 'background-color: #D5E2F2; padding: 2px',
    border: false,
    hideMode: 'offsets',
    defaults: {
        style: 'margin: 10px; padding: 0px;'
    },
    
    /**
     * Override Ext.Panel.initComponent
     * 
     * @override
     */
    initComponent: function() {
        AbstractClassUpgradeContext.superclass.initComponent.call(this);
    },
    
    onShow: function() {
        AbstractClassUpgradeContext.superclass.onShow.call(this);
        Ext.getCmp('UpgradeSaveLog').setDisabled(false);
        Ext.getCmp('UpgradeSaveLog').hide();
        Ext.getCmp('UpgradeNext').setDisabled(false);
        Ext.getCmp('UpgradeNext').show();
        Ext.getCmp('UpgradeCancel').setDisabled(false);
        Ext.getCmp('UpgradeCancel').show();
        Ext.getCmp('UpgradeReboot').setDisabled(false);
        Ext.getCmp('UpgradeReboot').show();
    },
    
    /**
     * Make a async http request to server.
     * 
     * @param {string} url A cgi-bin or program path on the server side.
     * @param {string} action A procedure of cgi-bin or program.
     * @param {object} params The procedure's arguments of cgi-bin or program.
     */
    makeAjaxRequest: function(url, action, params) {
        var controller = Ext.getCmp('UpgradeWindow');
        controller.makeAjaxRequest.call(controller, url, action, params);
    },
    
    /**
     * Abstact callback method, to handle http response message and data.
     * 
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        
    }
});

/**
 *  This class will query and show all firmwares are match NAS model.
 *  And control NAS to download a firmware from internet.
 * 
 *  @extends {AbstractClassUpgradeContext}
 */
ClassUpgradeBrowse = Ext.extend(AbstractClassUpgradeContext, {
    id: 'UpgradeBrowse',
    border: false,
    
    /**
     * Override AbstractClassUpgradeContext.initComponent to build GUI.
     * The ClassUpgradeBrowse contains a data grid to handle online search result
     * and a textarea to show release note.
     * 
     * @override 
     */
    initComponent: function() {
        this.items = [
            {
                id: 'UpgradeBrowseGrid',
                xtype: 'grid',
                width: 420,
                height: 150,
                style: 'margin-left: 8px',
                tbar: [
                    '->',
                    {
                        xtype: 'button',
                        style: 'font-size: 24px',
                        text: '<{$words.browse_refresh}>',
                        scope: this,
                        handler: this.onlineBroswe
                    }
                ],
                columns: [
                    {
                        xtype: 'gridcolumn',
                        dataIndex: 'model',
                        header: '<{$words.browse_model}>',
                        sortable: true,
                        width: 150,
                        editable: false
                    },
                    {
                        xtype: 'gridcolumn',
                        dataIndex: 'version',
                        header: '<{$words.browse_version}>',
                        sortable: true,
                        width: 150,
                        editable: false
                    },
                    {
                        xtype: 'gridcolumn',
                        dataIndex: 'date',
                        header: '<{$words.browse_date}>',
                        sortable: true,
                        width: 150,
                        editable: false
                    }
                ],
                store: new Ext.data.JsonStore({
                    url: 'query.php',
                    fields: [
                        {
                            name: 'model',
                            type: 'string'
                        },
                        {
                            name: 'version',
                            type: 'string'
                        },
                        {
                            name: 'date',
                            type: 'date'
                        },
                        {
                            name: 'url',
                            type: 'string'
                        }
                    ]
                }),
                listeners: {
                    'cellclick': this.cellclick,
                    'celldblclick': this.celldblclick
                }
            },
            {
                xtype: 'fieldset',
                title: '<{$words.release_note}>',
                border: false,
                height: 195,
                style: 'margin-top: 10px; padding-top: 0px;',
                items: [
                    {
                        id: 'UpgradeBrowseReleaseNote',
                        xtype: 'textarea',
                        anchor: '100%',
                        height: 155,
                        width: '100%',
                        hideLabel: true
                    }
                ]
            }
        ];
        
        ClassUpgradeBrowse.superclass.initComponent.call(this);
    },
    
    cellclick: function(grid, row, col, e ) {
        var record = grid.getStore().getAt(row);
        var url = record.get('url');
        Ext.getCmp('UpgradeBrowseReleaseNote').setValue(url);
    },
    
    celldblclick: function(grid, row, col, e ) {
        var record = grid.getStore().getAt(row);
        var url = record.get('url');
        Ext.getCmp('UpgradeBrowse').makeAjaxRequest('setmain.php?fun=setupdfw', 'setDownload', url);
    },
    
    /**
     * Query all firmwares in Thecus server side which are matched this NAS model.
     */
    onlineBroswe: function() {
        //var rom = 'http://www.thecus.com/Downloads/FW/N5500_N7700_N8800/1U4600_N4200series_N5500_N7700Pseries_N8800Pseries_FW_5.00.04.bin';
        //this.makeAjaxRequest('setmain.php?fun=setupdfw', 'setDownload', rom);
        Ext.getCmp('UpgradeBrowseGrid').store.reload();
    },
    
    /**
     * Callback method, to handle response message from UpgradeWindow.
     * 
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        Ext.getCmp('UpgradeSaveLog').hide();
        Ext.getCmp('UpgradeNext').hide();
        Ext.getCmp('UpgradeCancel').show();
        Ext.getCmp('UpgradeReboot').hide();
    }
});

/**
 *  This class will upload firmware file from browser to NAS.
 * 
 *  @extends {AbstractClassUpgradeContext}
 */
ClassUpgradeUpload = Ext.extend(AbstractClassUpgradeContext, {
    id: 'UpgradeUpload',
    border: false,
    task: {
        
    },
    
    /**
     * Override AbstractClassUpgradeContext.initComponent to build GUI.
     * The ClassUpgradeUpload contains a progress bar to handle upload percentage.
     * 
     * @override 
     */
    initComponent: function() {
        this.items = [
            {
                xtype: 'label',
                html: '<br><br>'
            },
            {
                layout: 'table',
                layoutConfig: {
                    columns: 1
                },
                bodyStyle: 'background-color: #D5E2F2;',
                autoHeight: true,
                border: false,
                items: [
                    {
                        xtype: 'label',
                        html: '<b><{$words.upload}><b>'
                    },
                    {
                        id: 'UpgradeUploading',
                        xtype: 'progress',
                        width: 410,
                        value: 1
                    }
                ]
            },
            {
                xtype: 'panel',
                bodyStyle: 'background-color: transparent; margin: 10px; padding: 0px;',
                border: false,
                html: '<{$words.upload_help}>'
            }
        ];
        
        ClassUpgradeUpload.superclass.initComponent.call(this);
    },
    
    /**
     * Override AbstractClassUpgradeContext.onShow to fix buf of progress bar on Ext 2.x.
     * 
     * @override
     */
    onShow: function() {
        ClassUpgradeUpload.superclass.onShow.call(this);
        
        /**
         * The following program block can fix ProgressBar problem on ext(2.x) card layout.
         */
        //var bar = Ext.getCmp('UpgradeUploading');
        //var size = bar.getSize();
        //bar.setWidth(size.width);
    },
    
    /**
     * ClassUpgradeUpload contain an timer (task). It must be stoped before panel hide, close or destory.
     */
    stopUpdate: function() {
        if( this.task.taskStartTime ) {
            Ext.TaskMgr.stop(this.task);
        }
    },
    
    /**
     * Before panel is hidden, make sure task timer is stop.
     * 
     * @override
     */
    onHide: function() {
        this.stopUpdate();
        ClassUpgradeUpload.superclass.onHide.call(this);
    },
    
    /**
     * Before panel is destory, make sure task timer is stop.
     * 
     * @override
     */
    onDestroy: function() {
        this.stopUpdate();
        ClassUpgradeUpload.superclass.onDestroy.call(this);
    },
    
    /**
     * Callback method, to handle response message from UpgradeWindow.
     * 
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        Ext.getCmp('UpgradeSaveLog').hide();
        Ext.getCmp('UpgradeNext').hide();
        Ext.getCmp('UpgradeCancel').hide();
        Ext.getCmp('UpgradeReboot').hide();
        
        var form = Ext.getCmp('Upgrade');
        form.getForm().submit({
            scope: Ext.getCmp('UpgradeWindow'),
            url: 'setmain.php?fun=setupdfw',
            params: {
                'action': 'setUpload'
            },
            success: Ext.getCmp('UpgradeWindow').fileUploadSuccess,
            failure: Ext.getCmp('UpgradeWindow').fileUploadFailure
        });
        
        this.loadMask = new Ext.LoadMask(this.body, {
            msg: '<{$words.uploading}>'
        });
        this.loadMask.show();
        
        /*
        var bar = new Ext.getCmp('UpgradeUploading');
        bar.wait({
            interval: 100,
            duration: 5000,
            increment: 25,
            scope: this,
            fn: function(){
            }
        });
        */
    }
});

/**
 *  This class will display firmware download percentage of NAS.
 * 
 *  @extends {AbstractClassUpgradeContext}
 */
ClassUpgradeDownload = Ext.extend(AbstractClassUpgradeContext, {
    id: 'UpgradeDownload',
    border: false,
    
    /**
     * Override AbstractClassUpgradeContext.initComponent to build GUI.
     * The ClassUpgradeDownload contains a progress bar to handle download percentage.
     * 
     * @override 
     */
    initComponent: function() {
        this.task = {
            scope: this,
            interval: 5000, // Query download rate every 5 second
            run: this.doRequest
        };
        this.items = [
            {
                xtype: 'label',
                html: '<br><br>'
            },
            {
                layout: 'table',
                layoutConfig: {
                    columns: 1
                },
                bodyStyle: 'background-color: #D5E2F2;',
                autoHeight: true,
                border: false,
                items: [
                    {
                        xtype: 'label',
                        html: '<b><{$words.download}><b>'
                    },
                    {
                        id: 'UpgradeDownloading',
                        xtype: 'progress',
                        width: 410,
                        text: '0%',
                        value: 0
                    }
                ]
            },
            {
                xtype: 'panel',
                bodyStyle: 'background-color: transparent; margin: 10px; padding: 0px;',
                border: false,
                html: '<{$words.download_help}>'
            }
        ];
        ClassUpgradeDownload.superclass.initComponent.call(this);
    },
    
    /**
     * Override AbstractClassUpgradeContext.onShow to fix buf of progress bar on Ext 2.x.
     * 
     * @override
     */
    onShow: function() {
        ClassUpgradeDownload.superclass.onShow.call(this);
        
        /**
         * The following program block can fix ProgressBar problem on ext(2.x) card layout.
         */
        var bar = Ext.getCmp('UpgradeDownloading');
        var size = bar.getSize();
        bar.setWidth(size.width);
    },
    
    /**
     * ClassUpgradeUpload contain an timer (task). It must be stoped before panel hide, close or destory.
     */
    stopUpdate: function() {
        if( this.task.taskStartTime ) {
            Ext.TaskMgr.stop(this.task);
        }
    },
    
    /**
     * Before panel is hidden, make sure task timer is stop.
     * 
     * @override
     */
    onHide: function() {
        this.stopUpdate();
        ClassUpgradeDownload.superclass.onHide.call(this);
    },
    
    /**
     * Before panel is destory, make sure task timer is stop.
     * 
     * @override
     */
    onDestroy: function() {
        this.stopUpdate();
        ClassUpgradeDownload.superclass.onDestroy.call(this);
    },
    
    /**
     * Make a download percentage monitor message to NAS per 3 seconds.
     * If the response is still downloading, UpgradeWindow will give a callback event to doProgress.
     */
    doRequest: function() {
        this.makeAjaxRequest.call(this, 'getmain.php?fun=updfw', 'getDownloadRate');
    },
    
    /**
     * Callback method, to handle response message from UpgradeWindow.
     * 
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        if( !this.task.taskStartTime ) {
            Ext.getCmp('UpgradeSaveLog').hide();
            Ext.getCmp('UpgradeNext').hide();
            Ext.getCmp('UpgradeCancel').show();
            Ext.getCmp('UpgradeReboot').hide();
            Ext.TaskMgr.start(this.task);
        } else {
            var bar = Ext.getCmp('UpgradeDownloading');
            bar.updateProgress(progress.rate/100.0, progress.rate + '%');
        }
    }
});

/**
 *  This class will display disclaim and waiting user to 'agree' it.
 * 
 *  @extends {AbstractClassUpgradeContext}
 */
ClassUpgradeDisclaim = Ext.extend(AbstractClassUpgradeContext, {
    id: 'UpgradeDisclaim',
    border: false,
    layout: 'fit',
    
    /**
     * Override AbstractClassUpgradeContext.initComponent to build GUI.
     * The ClassUpgradeDisclaim contains a disclaim and accept checkbox.
     * Only user choose 'agree' checkbox can continue to upgrade firmware.
     * 
     * @override 
     */
    initComponent: function() {
        this.items = [
            {
                xtype: 'label',
                html: '<br><br><b><{$words.disclaim}></b>'
            }
        ];
        /*
        this.items = [
            {
                xtype: 'textarea',
                style: "margin: 0px",
                value: '<{$words.disclaim}>'
            }
        ];
        this.bbar = [
            {
                id: 'UpgradeAgreeDisclaim',
                xtype: 'checkbox',
                boxLabel: '<{$words.agree}>',
                scope: this,
                handler: this.agreeDisclaim
            }
        ];
        */
        ClassUpgradeDisclaim.superclass.initComponent.call(this);
    },
    
    /**
     * Handle 'next' button when panel is showed.
     * 
     * @override
     */
    onShow: function() {
        ClassUpgradeDisclaim.superclass.onShow.call(this);
        Ext.getCmp('UpgradeNext').addListener('click', this.setDisclaim, this);
    },
    
    /**
     * Free handle 'next' button when panel is hidden.
     * 
     * @override
     */
    onHide: function() {
        Ext.getCmp('UpgradeNext').removeListener('click', this.setDisclaim, this);
        ClassUpgradeDisclaim.superclass.onHide.call(this);
    },
    
    /**
     * Just only user choose 'agree' the 'next' also can be clicked.
     */
    agreeDisclaim: function() {
        Ext.getCmp('UpgradeNext').setDisabled(!Ext.getCmp('UpgradeAgreeDisclaim').getValue());  
    },
    
    /**
     * Make sure user agree disclaim and continue upgrade procedure.
     */
    setDisclaim: function() {
        //Ext.getCmp('UpgradeAgreeDisclaim').setDisabled(true);
        Ext.getCmp('UpgradeNext').setDisabled(true);
        Ext.getCmp('UpgradeCancel').setDisabled(true);
        this.makeAjaxRequest.call(this, 'setmain.php?fun=setupdfw', 'setDisclaim', true);
        this.loadMask = new Ext.LoadMask(this.body, {
            msg: '<{$words.extracting}>'
        });
        this.loadMask.show();
        //Ext.getCmp('UpgradeWindow').showPage('UpgradeExtract');
    },
    
    /**
     * If UpgradeWindow receive a disclaim request. This callback medthod will be triggered.
     * 
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        //Ext.getCmp('UpgradeAgreeDisclaim').setDisabled(false);
        Ext.getCmp('UpgradeSaveLog').hide();
        //Ext.getCmp('UpgradeNext').setDisabled(true);
        Ext.getCmp('UpgradeReboot').hide();
        
        if( progress.status == 'status_extracting' ) {
            Ext.getCmp('UpgradeNext').setDisabled(true);
            Ext.getCmp('UpgradeCancel').setDisabled(true);
            setTimeout(this.waitExtract, 5000);
            
            if( !this.loadMask ) {
                this.loadMask = new Ext.LoadMask(this.body, {
                    msg: '<{$words.extracting}>'
                });
                this.loadMask.show();
            }
        }
    },
    
    /**
     * If receive a extracting response. This method will make a checking request.
     */
    waitExtract: function() {
        Ext.getCmp('UpgradeDisclaim').makeAjaxRequest.call(this, 'setmain.php?fun=setupdfw', 'setDisclaim');
    }
});


/**
 *  This class will show the source firmware details and wait for user to start upgrade procedure.
 * 
 *  @extends {AbstractClassUpgradeContext}
 */
ClassUpgradeConfirm = Ext.extend(AbstractClassUpgradeContext, {
    id: 'UpgradeConfirm',
    border: false,
    layout: 'fit',
    
    /**
     * Override AbstractClassUpgradeContext.initComponent to build GUI.
     * The ClassUpgradeConfrim contains NAS system version, source firmware version, checksum and release note.
     * 
     * @override 
     */
    initComponent: function() {
        this.items = [
            {
                layout: 'table',
                layoutConfig: {
                    columns: 1
                },
                hideLabel: true,
                autoHeight: true,
                border: false,
                style: 'margin: 5px; padding: 5px;',
                bodyStyle: 'background-color: #D5E2F2;',
                items: [
                    {
                        xtype: 'label',
                        html: '<br><b><{$words.confirm_title}></b>'
                    },
                    {
                        layout: 'table',
                        layoutConfig: {
                            columns: 2
                        },
                        border: false,
                        bodyStyle: 'background-color: #D5E2F2;',
                        items: [
                            {
                                xtype: 'label',
                                text: '<{$words.confirm_sys_version}>',
                                colspan: 1
                            },
                            {
                                id: 'UpgradeSystemVersion',
                                xtype: 'label',
                                text: '',
                                colspan: 1
                            },
                            {
                                xtype: 'label',
                                text: '<{$words.confirm_src_version}>',
                                colspan: 1
                            },
                            {
                                id: 'UpgradeSourceVersion',
                                xtype: 'label',
                                text: '',
                                colspan: 1
                            },
                            {
                                xtype: 'label',
                                text: '<{$words.confirm_src_checksum}>',
                                colspan: 1
                            },
                            {
                                id: 'UpgradeSourceChecksum',
                                xtype: 'label',
                                text: '',
                                colspan: 1
                            }
                        ]
                    }
                ]
            },
            {
                id: 'UpgradeSourceReadmeField',
                xtype: 'fieldset',
                title: '<{$words.release_note}>',
                height: 240,
                border: false,
                items: [
                    {
                        id: 'UpgradeSourceReadme',
                        xtype: 'textarea',
                        width: '100%',
                        height: 200,
                        hideLabel: true
                    }
                ]
            }
        ];
        
        ClassUpgradeConfirm.superclass.initComponent.call(this);
    },
    
    /**
     * Handle 'next' button when panel is showed.
     * 
     * @override
     */
    onShow: function() {
        ClassUpgradeConfirm.superclass.onShow.call(this);
        Ext.getCmp('UpgradeNext').addListener('click', this.setUpgrade, this);
    },
    
    /**
     * Free handle 'next' button when panel is hidden.
     * 
     * @override
     */
    onHide: function() {
        Ext.getCmp('UpgradeNext').removeListener('click', this.setUpgrade, this);
        ClassUpgradeConfirm.superclass.onHide.call(this);
    },
    
    /**
     * Starting upgrade procedure.
     */
    setUpgrade: function() {
        if( Ext.getCmp('UpgradeBackupDom') ) {
            this.makeAjaxRequest.call(this, 'setmain.php?fun=setupdfw', 'setUpgrade', Ext.getCmp('UpgradeBackupDom').getValue() ? '1' : '0');
        } else {
            this.makeAjaxRequest.call(this, 'setmain.php?fun=setupdfw', 'setUpgrade' );
        }
         
    },
    
    /**
     * If UpgradeWindow receive a disclaim request. This callback medthod will be triggered.
     * 
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        Ext.getCmp('UpgradeSaveLog').hide();
        Ext.getCmp('UpgradeReboot').hide();
        
        if( progress.info ) {
            Ext.getCmp('UpgradeSystemVersion').setText(progress.info.system);
            Ext.getCmp('UpgradeSourceVersion').setText(progress.info.source);
            Ext.getCmp('UpgradeSourceChecksum').setText(progress.info.md5);
        
            if( progress.info.readme == '' ) {
                Ext.getCmp('UpgradeSourceReadmeField').hide();
            } else {
                Ext.getCmp('UpgradeSourceReadme').setValue(progress.info.readme);
            }
        }
    }
});

/**
 *  This class will show the upgrading step as possible.
 * 
 *  @extends {AbstractClassUpgradeContext}
 */
ClassUpgradeUpgrade = Ext.extend(AbstractClassUpgradeContext, {
    id: 'UpgradeUpgrade',
    border: false,
    
    /**
     * Override AbstractClassUpgradeContext.initComponent to build GUI.
     * The ClassUpgradeUpgrade contains upgrading progress bar, result textarea.
     * 
     * @override 
     */
    initComponent: function() {
        this.task = {
            scope: this,
            interval: 5000,
            run: this.doRequest
        };
        this.items = [
            {
                xtype: 'label',
                html: '<br><br>'
            },
            {
                xtype: 'fieldset',
                title: '<{$words.upgrade}>',
                autoHeight: true,
                border: false,
                items: [
                    {
                        id: 'UpgradeUpgrading',
                        xtype: 'progress',
                        width: 410,
                        text: '',
                        value: 1
                    }
                ]
            },
            {
                id: 'UpgradeUpgradStep',
                xtype: 'textarea',
                readOnly: true,
                autoScroll: true,
                width: 414,
                height: 180,
                style: 'margin-left: 11px; margin-bottom:10px'
            },
            {
                xtype: 'label',
                html: '<center><{$words.upgrade_help}></center>'
            }
        ];
        ClassUpgradeUpgrade.superclass.initComponent.call(this);
    },
    
    /**
     * ClassUpgradeUpload contain an timer (task). It must be stoped before panel hide, close or destory.
     */
    stopUpdate: function() {
        if( this.task.taskStartTime ) {
            Ext.TaskMgr.stop(this.task);
        }
    },
    
    /**
     * Override AbstractClassUpgradeContext.onShow to fix buf of progress bar on Ext 2.x.
     * 
     * @override
     */
    onShow: function() {
        ClassUpgradeUpgrade.superclass.onShow.call(this);
        /**
         * The following program block can fix ProgressBar problem on ext(2.x) card layout.
         */
        var bar = Ext.getCmp('UpgradeUpgrading');
        var size = bar.getSize();
        bar.setWidth(size.width);
    },
    
    /**
     * Before panel is destory, make sure task timer is stop.
     * 
     * @override
     */
    onDestroy: function() {
        this.stopUpdate();
        ClassUpgradeUpgrade.superclass.onDestroy.call(this);
    },
    
    /**
     * Before panel is hidden, make sure task timer is stop.
     * 
     * @override
     */
    onHide: function() {
        this.stopUpdate();
        ClassUpgradeUpgrade.superclass.onHide.call(this);
    },
    
    /**
     * Make a upgrading percentage monitor message to NAS per 2 seconds.
     * If the response is still upgrading, UpgradeWindow will give a callback event to doProgress.
     */
    doRequest: function() {
        this.makeAjaxRequest.call(this, 'getmain.php?fun=updfw', 'getUpgradeRate');
    },
    
    /**
     * If UpgradeWindow receive a disclaim request. This callback medthod will be triggered.
     * 
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        if( !this.task.taskStartTime ) {
            Ext.getCmp('UpgradeSaveLog').hide();
            Ext.getCmp('UpgradeNext').hide();
            Ext.getCmp('UpgradeCancel').hide();
            Ext.getCmp('UpgradeReboot').hide();
            if( progress.show ) {
                Ext.getCmp('UpgradeUpgrading').updateProgress(0, '');
            } else {
                this.loadMask = new Ext.LoadMask(this.body, {
                    msg: '<{$words.upgrade_upgrading}>'
                });
                this.loadMask.show();
            }
            Ext.TaskMgr.start(this.task);
        } else {
            if( progress.progress ) {
                Ext.getCmp('UpgradeWindow').data = progress.progress;
                var lines = progress.progress.split(/\n/);
                var msg = '';
                var last = '';
                for( var i in lines ) {
                    if( typeof(lines[i]) == 'string' && lines[i] != '' ) {
                        var fields = lines[i].split('|');
                        var steps = fields[1].split('/');
                        
                        var bar = Ext.getCmp('UpgradeUpgrading');
                        bar.updateProgress(steps[0]/steps[1], steps[0] + '/' + steps[1]);
                        
                        if( last != fields[2] ) {
                            msg += fields[2] + '\n';
                            last = fields[2];
                        }
                    }
                }
                Ext.getCmp('UpgradeUpgradStep').setValue(msg);
            }
        }
    }
});

/**
 *  This class will show the firmware upgrading result.
 * 
 *  @extends {AbstractClassUpgradeContext}
 */
ClassUpgradeResult = Ext.extend(AbstractClassUpgradeContext, {
    id: 'UpgradeResult',
    border: false,
    
    /**
     * Override AbstractClassUpgradeContext.initComponent to build GUI.
     * The ClassUpgradeResult will display all message contain error and execption.
     * 
     * @override 
     */
    initComponent: function() {
        this.items = [
            {
                xtype: 'label',
                html: '<br><br>'
            },
            {
                xtype: 'fieldset',
                autoHeight: true,
                border: false,
                items: [
                    {
                        id: 'UpgradeResultTitle',
                        xtype: 'label',
                        style: 'font-weight:bold;'
                    },
                    {
                        id: 'UpgradeResultHelp',
                        xtype: 'panel',
                        bodyStyle: 'background-color: transparent; margin: 0px; padding: 0px;',
                        border: false,
                        html: ' '
                    },
                    {
                        xtype: 'fieldset',
                        title: ' ',
                        autoHeight: true,
                        border: false,
                        items: [
                            {
                                id: 'UpgradeResultLog',
                                hidden: true,
                                xtype: 'textarea',
                                hideLabel: true,
                                width: '100%',
                                height: 180
                            }
                        ]
                    },
                    {
                        id: 'UpgradeCongratulation',
                        hidden: true,
                        xtype: 'label',
                        html: '<center><img src="/theme/images/index/upgrade/Congratulation.png"></center>',
                        hideLabel: true,
                        width: '100%'
                    }
                ]
            }
        ];
        ClassUpgradeResult.superclass.initComponent.call(this);
    },
    
    /**
     * If UpgradeWindow receive a disclaim request. This callback medthod will be triggered.
     * this.makeAjaxRequest('setmain.php?fun=setupdfw', 'setCancel');
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        Ext.getCmp('UpgradeSaveLog').hide();
        Ext.getCmp('UpgradeNext').hide();
        
        var title = Ext.getCmp('UpgradeWindow').words[progress.status] || Ext.getCmp('UpgradeWindow').words['unknow'];
        Ext.getCmp('UpgradeResultTitle').setText(title);
        
        var help = Ext.getCmp('UpgradeWindow').words[progress.status + '_help'] || Ext.getCmp('UpgradeWindow').words['unknow'];
        Ext.getCmp('UpgradeResultHelp').body.update(help);
        
        if( progress.status == 'status_upgraded') {
            Ext.getCmp('UpgradeCongratulation').show();
        }
        
        if( progress.status == 'status_upgraded' || progress.status == 'status_upgradewrong' ) {
            Ext.getCmp('UpgradeCancel').hide();
            Ext.getCmp('UpgradeReboot').show();
            //Ext.getCmp('UpgradeResultLog').hide();
        } else {
            var data = progress.progress || Ext.getCmp('UpgradeWindow').data;
            
            if( data ) {
                Ext.getCmp('UpgradeResultLog').show();
                Ext.getCmp('UpgradeResultLog').setValue(data);
            }
            Ext.getCmp('UpgradeCancel').show();
            Ext.getCmp('UpgradeReboot').hide();
        }
    }
});

/**
 *  This class is a container.
 * 
 *  @extends {Ext.Panel}
 */
ClassUpgradeContentContainer = Ext.extend(Ext.Panel, {
    id: 'UpgradeContent',
    region: 'center',
    layout: 'card',
    activeItem: 'UpgradeBrowse',
    border: false,
    
    /**
     * Override Ext.Panel.initComponent to build GUI.
     * The ClassUpgradeContentContainer contains many sub panels.
     * 
     * @override 
     */
    initComponent: function() {
        this.items = [
            new ClassUpgradeBrowse(),
            new ClassUpgradeUpload(),
            new ClassUpgradeDownload(),
            new ClassUpgradeDisclaim(),
            new ClassUpgradeConfirm(),
            new ClassUpgradeUpgrade(),
            new ClassUpgradeResult()
        ];
        ClassUpgradeContentContainer.superclass.initComponent.call(this);
    },
    
     /**
     * If UpgradeWindow receive a disclaim request. This callback medthod will be triggered.
     * 
     * @pararm {object} progress Contain all response messages and data.
     */
    doProgress: function(progress) {
        if( progress ) {
            page = this.items.get(progress.step) || this.items.get('UpgradeResult');
        } else {
            page = this.items.get('UpgradeBrowse');
        }
        this.layout.setActiveItem(page);
        page.doProgress.call(page, progress);
    },
    
     /**
     * This method will show target page of step.
     * 
     * @pararm {string} page The page is sub panel's id.
     */
    changePage: function(page) {
        var panel = this.items.get(page) || this.items.get('UpgradeBrowse');
        this.layout.setActiveItem(panel);
        panel.doProgress.call(panel);
    }
});


/**
 *  This class is a container and message manager.
 * 
 *  @extends {Ext.Window}
 */
ClassUpgradeWindow = Ext.extend(Ext.Window, {
    title: '<{$words.window}>',
    height: 400,
    width: 600,
    layout: 'border',
    id: 'UpgradeWindow',
    closable: false,
    resizable: false,
    modal: true,
    autoScroll: true,
    border: false,
    data: null,
    words: Ext.decode('<{$words|@json_encode}>'),
    
    /**
     * Override Ext.Window.initComponent to build GUI.
     * The ClassUpgradeWindow will contain help, sub container and four buttons.
     * 
     * @override 
     */
    initComponent: function() {
        this.url = 'getmain.php?fun=updfw';
        this.params = {
            'action': 'getProgress'
        };
        this.scope = this;
        this.items = [
            new ClassUpgradeHelp(),
            new ClassUpgradeContentContainer()
        ];
        this.bbar = [
            '->',
            {
                id: 'UpgradeSaveLog',
                xtype: 'button',
                text: '<{$words.save_log}>',
                scope: this,
                handler: this.saveAs
            },
            {
                id: 'UpgradeNext',
                xtype: 'button',
                text: '<{$words.next}>'
            },
            {
                id: 'UpgradeCancel',
                xtype: 'button',
                text: '<{$words.cancel}>',
                scope: this,
                handler: this.cancel
            },
            {
                id: 'UpgradeReboot',
                xtype: 'button',
                text: '<{$words.reboot}>',
                scope: this,
                handler: this.reboot
            }
        ];
        ClassUpgradeWindow.superclass.initComponent.call(this);
    },
    
    cancel: function() {
        this.makeAjaxRequest('setmain.php?fun=setupdfw', 'setCancel');
    },
    
    reboot: function() {
        this.close();
        this.makeAjaxRequest('setmain.php?fun=setupdfw', 'setCancel');
        setTimeout("processUpdater('getmain.php','fun=reboot')",1000);
    },
    
    /**
     * Invoke container to change display page.
     * 
     * @param {string} page Container will change correct panel to page.
     */
    showPage: function(page) {
        this.show();
        var UpgradeContent = this.items.map.UpgradeContent;
        UpgradeContent.changePage(page);
    },
    
    /**
     * UpgradeWindow can make http request with Ext.Ajax.
     * If server receive and feeback some data.
     * The 'success' method will be auto invoked.
     * Otherwide 'failed' method will be invoked.
     * 
     * @param {string} url The cgi-bin or program uri in the internet.
     * @param {string} action The remote method name.
     * @param {object} params The remote method's arguments. 
     */
    makeAjaxRequest: function(url, action, params) {
        this.url = url || 'getmain.php?fun=updfw';
        this.timeout = 300000;
        this.params = {
            'action':   action || 'getProgress',
            'params':   params
        }
        Ext.Ajax.request(this);
    },
    
    /**
     * This method will be auto invoked when server side feeback some data.
     * 
     * @param {string} response
     * @param {string} opts
     */
    success: function(response, opts) {
        try {
            var progress = Ext.decode(response.responseText);
            var UpgradeContent = this.items.map.UpgradeContent;
            
            if( progress.step == 'UpgradeResult' && progress.status == 'status_cancel' ) {
                this.close();
                return;
            }
            
            if( progress.step != 'UpgradeBrowse') {
                var moduleWindow = Ext.getCmp('newmod_win');
                if( moduleWindow && moduleWindow.rendered ) {
                    moduleWindow.hide();
                }
                
                
                if( Window_log && Window_log.rendered ) {
                    Window_log.hide();
                }
                
                this.show();
                UpgradeContent.doProgress.call(UpgradeContent, progress);
            }
        } catch( err ) {
            
        }
            
    },
    
    /**
     * This method will be auto invoked when server side feeback some data.
     * 
     * @param {string} response
     * @param {string} opts
     */
    failure: function(response, opts) {
        var progress = {
            'step': 'UpgradeResult',
            'status': 'status_uploadfail'
        }
        
        this.show();
        var UpgradeContent = this.items.map.UpgradeContent;
        UpgradeContent.doProgress.call(UpgradeContent, progress);
    },
    
    /**
     * This method will be auto invokded when upload file success.
     * 
     * @param {string} form
     * @param {string} action
     */
    fileUploadSuccess: function(form, action) {
        var progress = (Ext.decode(action.response.responseText)).msg;
        
        var UpgradeContent = this.items.map.UpgradeContent;
        UpgradeContent.doProgress.call(UpgradeContent, progress);
    },
    
    /**
     * This method will be auto invokded when upload file connection fail.
     * 
     * @param {string} form
     * @param {string} action
     */
    fileUploadFailure: function(form, action) {
        var progress = {
            'step': 'UpgradeResult',
            'status': 'status_uploadfail'
        }
        
        UpgradeContent.doProgress.call(UpgradeContent, progress);
    }
});


/**
 *  This class used to handle upload file.
 * 
 *  @extends {Ext.FormPanel}
 */
ClassUpgrade = Ext.extend(Ext.FormPanel, {
    id: 'Upgrade',
    layout: 'form',
    fileUpload: true,
    autoWidth : true,
    autoHeight: true,
    bodyStyle: 'background: transparent;',
    style: 'margin: 10px;',
    border: false,
    labelWidth: 100,
    buttonAlign: 'left',
    renderTo: 'DomUpgrade',
    defaults: {
        anchor: '90%',
        allowBlank: false,
        msgTarget: 'side'
    },
    listeners: {
        beforedestroy: function() {
            Ext.get('content').getUpdateManager().un('beforeupdate', this.destroy, this );
            if( Ext.getCmp('UpgradeWindow') ) {
                Ext.getCmp('UpgradeWindow').destroy();
            }
        }
    },
    
    /**
     * Override Ext.FormPanel.initComponent to build GUI.
     * The ClassUpgrade will a fileuploadfield and two buttons (apply, broswe).
     * 
     * @override 
     */
    initComponent: function() {
        this.items = [
            {
                id: 'UpgradeUploadFile',
                xtype: 'fileuploadfield',
                emptyText: '<{$words.select_fw}>',
                fieldLabel: '<{$words.updfw_firmware}>',
                buttonCfg: {
                    text: '',
                    iconCls: 'upload-icon'
                }
            }
            <{if $backupDom >= 0 }>
            ,
            {
                xtype: 'panel',
                layout: 'table', 
                items: [
                    {
                        id: 'UpgradeBackupDom',
                        xtype: 'checkbox',
                        checked: '<{$backupDom}>' == '1',
                        boxLabel: '<{$words.backupdom_desc}>'
                    }
                ]
            }
            <{/if}>
        ];
        this.buttons = [
            {
                text: '<{$gwords.apply}>',
                scope: this,
                handler: this.doFileUpload
            }
            <{if $isOEM == '0' && $go == '1'}>
            ,
            {
                text: '<{$words.browse}>',
                scope: this,
                handler: this.doOnlineBrowse
            }
            <{/if}>
        ];
        ClassUpgrade.superclass.initComponent.call(this);
        (new ClassUpgradeWindow()).makeAjaxRequest();
    },
    
    /**
     * Start upload firmware file to NAS.
     */
    doFileUpload: function() {
        if( this.getForm().isValid() ){
            (Ext.getCmp('UpgradeWindow') || new ClassUpgradeWindow()).showPage('UpgradeUpload');
        }
    },
    
    /**
     * Start to browsing firmwares from internet.
     */
    doOnlineBrowse : function() {
        (Ext.getCmp('UpgradeWindow') || new ClassUpgradeWindow()).showPage('UpgradeBrowse');
    }
});

Ext.onReady(function(){
    Ext.QuickTips.init();
    var upgrade = new ClassUpgrade();
    Ext.get('content').getUpdateManager().on('beforeupdate', upgrade.destroy, upgrade);
});

</script>
