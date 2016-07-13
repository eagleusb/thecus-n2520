<div id='DomHV' />
<script type='text/javascript'>
/**
 * Huge Volume Wording. Those wording will generate and change from server.
 * 
 * @type Object
 */
WORDS = <{$words}>;

/**
 * The global namesapce of Huge Volume is TCode.HV
 */
Ext.namespace('TCode.HV');

/**
 * Server side procedures
 *
 * @static
 * @namespace TCode.HV
 * @type String[]
 */
TCode.HV.Procedures = <{$procedures}>;
TCode.HV.ClientLimit = <{$hv_clients}>;
TCode.HV.Service = <{$service}>;
TCode.HV.Nic10G = <{$nic_10G}>;
TCode.HV.HA = <{$ha_enable}>;
TCode.HV.MasterOnOff = <{$master_on_off}>;
TCode.HV.ClientOnOff = <{$client_on_off}>;

/**
 * Stripe will be used in RAID wizard.
 * 
 * @static
 * @namespace TCode.HV
 * @type Array
 */
TCode.HV.Stripe = [
    ['32','32'],
    ['64','64'],
    ['128','128'],
    ['256','256'],
    ['512','512'],
    ['1024','1024'],
    ['2048','2048'],
    ['4096','4096']
]

/**
 * FileSystem will be used in RAID wizard.
 * 
 * @static
 * @namespace TCode.HV
 * @type String[][]
 */
TCode.HV.FileSystem = [
    ['ext3', 'EXT3' ],
    ['ext4', 'EXT4' ],
    ['xfs',  'XFS' ],
    ['zfs',  'ZFS' ]
]

/**
 * RaidStruct will be used in RAID wizard.
 * 
 * @static
 * @namespace TCode.HV
 * @type String[]
 */
TCode.HV.RaidStruct = [
    'md_num',
    'raid_id',
    'raid_level',
    'raid_fs',
    'raid_status',
    'raid_disk',
    'total_capacity',
    'data_capacity',
    'usb_capacity',
    'iscsi_capacity',
    'data_partition',
    'unused',
    'encrypt'
]

TCode.HV.Ajax = new TCode.ux.Ajax('sethv', TCode.HV.Procedures);
TCode.HV.Ajax.timeout = 100000;

/**
 * Extend from Highcharts library.
 * Display pie chart to figure out RAID/Volume/Connection usage.
 * 
 * @class PieChart
 * @namespace TCode.HV
 * @extends Highcharts.Chart
 * @constructor
 * @param {String} div Html div object's id
 * @param {Boolean} [legend=false] Show the data legend or not
 */
TCode.HV.PieChart = function(div, legend) {
    var self = this;
    
    legend = legend || false;
    
    var config = {
        chart: {
            renderTo: div,
            height: 115,
            marginRight: 0,
            marginTop: 0,
            marginLeft: 0,
            marginBottom: 0,
            spacingTop: 0,
            spacingLeft: 0,
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false,
            backgroundColor: null
        },
        colors: [
            '#A00000',
            '#008000',
            '#0000A0'
        ],
        title: {
            text: '',
            margin: 0,
            x: 0,
            y: 0
        },
        credits: {
            enabled: false
        },
        legend: {
            x: 45,
            borderWidth: 0,
            layout: 'vertical',
            verticalAlign: 'middle'
        },
        tooltip: {
            formatter: tipFormatter
        },
        plotOptions: {
            pie: {
                center: [
                   '25%',
                   '50%'
                ],
                size: 90,
                cursor: 'pointer',
                allowPointSelect: true,
                showInLegend: legend,
                dataLabels: {
                    enabled: false
                }
            }
        },
        series: [{
            type: 'pie'
        }]
    }
    
    /**
     * Tooltip formatter when mouse over event.
     * 
     * @inner
     */
    function tipFormatter() {
        return String.format(
            '<b>{0}</b> {1}%',
            this.point.name,
            this.percentage.toFixed(1)
        );
    }
    
    /**
     * Change/Display pie chart.
     * Each percentage of key in data will be auto compute.
     * 
     * @public
     * @param {Array} data Format as key and value like ['Used', 15].
     */
    function setUsage(data) {
        data = data || [];
        if( data.length == 0) {
            self.series[0].setData(data, false);
        } else {
            self.series[0].show();
            self.series[0].setData(data, true);
        }
    }
    this.setUsage = setUsage;
    
    TCode.HV.PieChart.superclass.constructor.call(this, config);
}

Ext.extend(TCode.HV.PieChart, Highcharts.Chart);

/**
 * Provide times and chunk size to test the data access speed of volumes.
 * 
 * @class Speed
 * @namespace TCode.HV
 * @extends Ext.Window
 * @constructor
 * @param {Object} conf Use to override default configure
 */
TCode.HV.Speed = function(listeners) {
    var self = this;
    
    var size,
        times,
        progrs,
        targets,
        loading = 0;
    
    var ajax = TCode.HV.Ajax;
    
    var task = {
        run: ajax.getTestStage,
        interval: 5000
    }
    
    var config = {
        modal: true,
        autoHeight: true,
        closable: false,
        title: WORDS.test_speed,
        layout: 'form',
        border: false,
        items: [
            {
                xtype: 'combo',
                mode: 'local',
                editable: false,
                triggerAction: 'all',
                selectOnFocus: true,
                displayField: 'k',
                valueField: 'v',
                listWidth: 70,
                value: 128,
                fieldLabel: WORDS.dd_size,
                store: new Ext.data.SimpleStore({
                    fields: [ 'k', 'v' ],
                    data: [
                        [ '128 MB', 128 ],
                        [ '256 MB', 256 ],
                        [ '512 MB', 512 ],
                        [ '1024 MB', 1024 ]
                    ]
                })
            },
            {
                xtype: 'combo',
                mode: 'local',
                editable: false,
                triggerAction: 'all',
                selectOnFocus: true,
                displayField: 'k',
                valueField: 'v',
                listWidth: 50,
                value: 2,
                fieldLabel: WORDS.times,
                store: new Ext.data.SimpleStore({
                    fields: [ 'k', 'v' ],
                    data: [
                        [ '2', 2 ],
                        [ '4', 4 ],
                        [ '6', 6 ],
                        [ '8', 8 ],
                        [ '10', 10 ]
                    ]
                })
            },
            {
                xtype: 'progress',
                fieldLabel: WORDS.percentage,
                value: 0
            }
        ],
        buttons: [
            {
                text: WORDS.start,
                handler: onStart
            },
            {
                text: WORDS.cancel,
                handler: onCancel
            }
        ],
        listeners: {
            render: onRender,
            show: onShow
        }
    }
    
    Ext.applyIf(config.listeners, listeners);
    
    function onRender() {
        size = self.items.get(0);
        times = self.items.get(1);
        progrs = self.items.get(2);
    }
    
    function onShow() {
        size.setDisabled(false);
        times.setDisabled(false);
        self.buttons[0].setDisabled(false);
        progrs.updateProgress();
        progrs.updateText('');
    }
    
    /**
     * @name Speed#start
     * @event
     * @param {Number} size
     * @param {Number} times
     */
    function onStart() {
        ajax.setTest(
            Number(size.getValue()),
            Number(times.getValue()),
            targets,
            ajaxSetTest
        );
    }
    
    function setTestingTarget(volumes) {
        targets = volumes;
    }
    this.setTestingTarget = setTestingTarget;
    
    function getTestingStage() {
        Ext.TaskMgr.start(task);
    }
    this.getTestingStage = getTestingStage;
    
    /**
     * Invoke by cancel button.
     * 
     * @inner
     */
    function onCancel() {
        if( task.taskRunTime ) {
            Ext.TaskMgr.stop(task);
            ajax.setTestCancel(ajaxSetTestCancel);
        } else {
            self.hide();
        }
    }
    
    /**
     * Call back when ajax.setTest() success
     * 
     * @inner
     * @param {Boolean} testing
     */
    function ajaxSetTest(testing) {
        if( testing ) {
            size.setDisabled(true);
            times.setDisabled(true);
            self.buttons[0].setDisabled(true);
            getTestingStage();
        }
    }
    
    /**
     * call back when ajax.getTestStage() success
     *
     * @inner
     * @param {Number} status
     * @param {Array[][]} volumes
     */
    function ajaxGetTestStage(s, t, vs, f) {
        if( vs != f ) {
            size.setValue(s);
            size.setDisabled(true);
            times.setValue(t);
            times.setDisabled(true);
            self.buttons[0].setDisabled(true);
            
            if( loading == 0 ) {
                progrs.updateProgress(Number(f/vs), String.format('{0} {1}/{2}', WORDS.tested, f, vs));
            } else if( loading == 1 ) {
                progrs.updateProgress(Number(f/vs), String.format('> {0} {1}/{2} <', WORDS.tested, f, vs));
            } else {
                progrs.updateProgress(Number(f/vs), String.format('>> {0} {1}/{2} <<', WORDS.tested, f, vs));
                loading = -1;
            }
            loading += 1;
        } else {
            if( task.taskRunTime ) {
                Ext.TaskMgr.stop(task);
                delete task.taskRunTime;
                delete task.taskStartTime;
            }
            self.hide();
        }
    }
    
    /**
     * Call back when ajax.ajaxSetCancel() success
     * 
     * @inner
     */
    function ajaxSetTestCancel() {
        self.hide();
    }
    
    TCode.HV.Speed.superclass.constructor.call(this, config);
}

Ext.extend(TCode.HV.Speed, Ext.Window);

/**
 * DropOrder allow user to select and change data index in a grid.
 * Only ctrl/command(mac)/shift + mouse(right click) to select record when grid
 * is on single click to edit.
 * 
 * @class DropOrder
 * @namespace TCode.HV
 * @extends Ext.dd.DropTarget
 * @constructor
 * @param {Ext.grid.GridPanel|Ext.grid.EditorGridPanel} grid
 */
TCode.HV.DropOrder = function(grid) {
    var config = {
        ddGroup: 'dd',
        copy: false,
        notifyDrop: onNotifyDrop
    }
    
    var index;
    
    /**
     * @inner
     * @override
     * @param {Ext.dd.DragSource} dd
     * @param {Event} e
     * @param {Object} data
     */
    function onNotifyDrop(dd, e, data) {
        var ds = grid.store;
        var rows = grid.selModel.getSelections();
        if( dd.getDragData(e) ) {
            var cindex = dd.getDragData(e).rowIndex;
            if (typeof(cindex) != "undefined" ) {
                for (var i = 0; i <  rows.length ; ++i ) {
                    ds.remove(ds.getById(rows[i].id));
                }
                ds.insert(cindex,data.selections);
                grid.selModel.clearSelections();
            }
        }
        
        index = 1;
        ds.each(reOrder, ds);
        grid.getView().refresh();
    }
    
    /**
     * Change the index value of record
     * 
     * @inner
     * @param {Ext.data.Record} r
     */
    function reOrder(r) {
        r.beginEdit();
        r.set('index', index++);
        r.commit();
    }
    
    TCode.HV.DropOrder.superclass.constructor.call(this, grid.container, config);
}

Ext.extend(TCode.HV.DropOrder, Ext.dd.DropTarget);

/**
 * Managment is the master mode of Huge Volume.
 * Each master use one or more volumes to assemble RAID.
 * All volumes are iSCSI devices from localhost or TCP/IP networking host.
 * 
 * @class Managment
 * @namespace TCode.HV
 * @extends Ext.Panel
 * @constructor
 * @param {Object} conf Use to override default configure
 */
TCode.HV.Managment = function(conf) {
    var self = this;
    
    var mode = null,
        use_hv_clients = 0,
        raid_md,
        raid_id_safe = false,
        mask,
        resume_mask,
        raidInfo,
        dropOrder,
        chart = [];
    
    var ajax = TCode.HV.Ajax;
    
    var task = {
        run: monitorGetManagment,
        interval: 5000
    }
    
    var speed = new TCode.HV.Speed({
        hide: onTestFinish
    });
    
    var info = {
        layout: 'column',
        items: [
            {
                layout: 'form',
                width: 300,
                items: [
                    {
                        xtype: 'textfield',
                        fieldLabel: WORDS.raid_id,
                        allowBlank: false,
                        vtype: 'RaidID',
                        disabled: true,
                        listeners: {
                            blur: onRaidIDBlur
                        }
                    },
                    {
                        xtype: 'combo',
                        mode: 'local',
                        editable: false,
                        triggerAction: 'all',
                        displayField: 'k',
                        valueField: 'v',
                        listWidth: 100,
                        value: '64',
                        disabled: true,
                        fieldLabel: WORDS.stripe_size,
                        store: new Ext.data.SimpleStore({
                            fields: [ 'v', 'k' ],
                            data: TCode.HV.Stripe
                        })
                    },
                    {
                        xtype: 'combo',
                        mode: 'local',
                        editable: false,
                        triggerAction: 'all',
                        displayField: 'k',
                        valueField: 'v',
                        listWidth: 100,
                        value: 'xfs',
                        disabled: true,
                        fieldLabel: WORDS.file_system,
                        store: new Ext.data.SimpleStore({
                            fields: [ 'v', 'k' ],
                            data: [['xfs', 'XFS']]
                        })
                    },
                    {
                        xtype: 'textfield',
                        fieldLabel: WORDS.raid_status,
                        readOnly: true,
                        fieldClass: 'fakeLabel',
                        style: 'border: 0px solid #69858F;'
                    },
                    {
                        xtype: 'textfield',
                        fieldLabel: WORDS.capacity,
                        readOnly: true,
                        fieldClass: 'fakeLabel',
                        style: 'border: 0px solid #69858F;'
                    }
                ]
            },
            {
                xtype: 'box',
                autoEl: {
                    id: 'DomHVChart1',
                    tag: 'div',
                    style: 'width: 200px;'
                }
            },
            {
                xtype: 'box',
                autoEl: {
                    id: 'DomHVChart2',
                    tag: 'div',
                    style: 'width: 200px;'
                },
                listeners: {
                    render: onChartDivRender
                }
            }
        ]
    }
    
    var gridStore = new Ext.data.SimpleStore({
        pruneModifiedRecords: true,
        fields: [
            { name: 'device' },
            { name: 'ipv4' },
            { name: 'hostname' },
            { name: 'raid_id' },
            { name: 'level' },
            { name: 'capacity' },
            { name: 'spare' },
            { name: 'status' },
            { name: 'speed' },
            { name: 'index' }
        ]
    })
    
    var gridColumes = [
        new Ext.grid.RowNumberer(),
        {
            header: WORDS.ipv4,
            dataIndex: 'ipv4'
        },
        {
            header: WORDS.hostname,
            dataIndex: 'hostname'
        },
        {
            header: WORDS.raid_id,
            dataIndex: 'raid_id'
        },
        {
            header: WORDS.level,
            dataIndex: 'level'
        },
        {
            header: WORDS.capacity,
            dataIndex: 'capacity'
        },
        {
            header: WORDS.spare,
            dataIndex: 'spare',
            renderer: spareRenderer
        },
        {
            header: WORDS.status,
            dataIndex: 'status',
            renderer: statusRenderer
        },
        {
            header: WORDS.speed,
            hidden: true,
            dataIndex: 'speed'
        }
    ]
    
    var gridToolbar = [
        new Ext.Button({
            text: WORDS.refresh,
            iconCls: 'refresh',
            tooltip: WORDS.refresh_tip,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.create,
            iconCls: 'add',
            disabled: true,
            tooltip: WORDS.raid_create_tip,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.expand,
            iconCls: 'raid_expand',
            disabled: true,
            tooltip: WORDS.raid_expand_tip,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.remove,
            iconCls: 'remove',
            disabled: true,
            tooltip: WORDS.raid_remove_tip,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.suspend,
            iconCls: 'pause',
            disabled: true,
            tooltip: WORDS.suspend_tip,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.resume,
            iconCls: 'resume',
            disabled: true,
            tooltip: WORDS.resume_tip,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.test_speed,
            iconCls: 'speed',
            disabled: true,
            hidden: true,
            tooltip: WORDS.speed_tip,
            handler: onButton
        })
    ]
    
    var buttons = [
        new Ext.Button({
            text: WORDS.apply,
            disabled: true,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.cancel,
            disabled: true,
            handler: onButton
        })
    ]
    
    var grid = {
        xtype: 'grid',
        width: 680,
        height: 300,
        frame: true,
        ddGroup: 'dd',
        enableDragDrop: true,
        style: 'margin: 5px',
        viewConfig: {
            autoFill: true,
            forceFit: true
        },
        selModel: new Ext.grid.RowSelectionModel({
            singleSelect : false
        }),
        store: gridStore,
        columns: gridColumes,
        tbar: gridToolbar,
        buttonAlign: 'left',
        buttons: buttons,
        listeners: {
            render: onGridRender,
            click: onGridClick
        }
    }
    
    var descTpl = new Ext.XTemplate('<tpl for="ol"><li>{li}</tpl>');
    var descVaules = {
        ol: [
            { li: String.format(WORDS.master_desc1, TCode.HV.ClientLimit) },
            { li: WORDS.master_desc2 },
            { li: WORDS.master_desc3 }
        ]
    }
    
    var note = {
        xtype: 'fieldset',
        title: WORDS.description,
        style: 'margin: 5px',
        autoHeight: true,
        items: {
            xtype: 'box',
            autoEl: {
                tag: 'ol',
                style: 'list-style-position: inside; list-style-type: decimal;',
                html: descTpl.apply(descVaules)
            }
        }
    }
    
    var config = {
        layout: 'form',
        title: WORDS.managment_title,
        frame: true,
        style: 'background: transparent;',
        bodyStyle: 'margin-top: 5px; padding: 0px;',
        autoHeight: true,
        items: [
            info,
            grid,
            note
        ],
        listeners: {
            render: onRender,
            beforedestroy: onDestroy,
            activate: onActivate,
            show: onShow,
            hide: onHide
        }
    }
    
    Ext.applyIf(config, conf);

    function monitorGetManagment() {
        ajax.getManagment(ajaxGetManagment);
    }
        
    /**
     * Invoke by Ext.Panel when html dom objects is rendered.
     * 
     * @inner
     */
    function onRender() {
        grid = self.items.get(1);
        gridStore = grid.store;
        grid.selModel.lock;
        
        var panel = self.items.get(0);
        with(panel.items.get(0)) {
            raidInfo = [
                items.get(0),
                items.get(1),
                items.get(2),
                items.get(3),
                items.get(4)
            ]
        }
    }
    
    /**
     * Invoke by Ext.Panel when this object is destroied.
     * 
     * @inner
     */
    function onDestroy() {
        speed.destroy();
        delete speed;
        
        if( chart[0] )
            chart[0].destroy();
        if( chart[1])
            chart[1].destroy();
        delete chart;
        
        ajax.abort();
        Ext.destroy(ajax);
        delete ajax;
    }
    
    /**
     * Initial/Reset panel controller to default.
     * Invoke by Ext.Panel when Ext.TabPanel's tab is changed.
     * 
     * @inner
     */
    function onActivate() {
        grid.selModel.lock();
        dropOrder.lock();
        lockInfo(true);
        setInfo();
        hideSpeedColumn(true);
        setCreateExpandShow();
        setRemoveShow();
        setSuspendResumeShow();
        setTestShow();
        setButtonShow(false);
        gridStore.removeAll();
        ajax.getManagment(ajaxGetManagment);
        mask.show();
    }
    
    /**
     * Initial/Reset panel controller to default.
     * Invoke by Ext.Panel when Ext.TabPanel's tab is changed.
     * 
     * @inner
     */
    function onShow() {
        ajax.getManagment(ajaxGetManagment);
        if( mask )
            mask.show();
    }
    
    function onDeactivate() {
        ajax.abort();
        if( task.taskStartTime ) {
            Ext.TaskMgr.stop(task);
            delete task.taskRunTime;
            delete task.taskStartTime;
        }
        mask.hide();
    }
    
    /**
     * Create pie chart objects.
     * 
     * @inner
     */
    function onChartDivRender() {
        chart[0] = new TCode.HV.PieChart('DomHVChart1', true);
    }
    
    /**
     * Create load mask on grid.
     * 
     * @inner
     */
    function onGridRender(grid) {
        dropOrder = new TCode.HV.DropOrder(grid);
        dropOrder.lock();
        mask = new Ext.LoadMask(self.body, {msg: WORDS.processing});
        mask.show();
        resume_mask = new Ext.LoadMask(grid.body, {msg: WORDS.processing});
    }
    
    /**
     * Invoke by Ext.Panel when Ext.TabPanel's tab is changed.
     * 
     * @inner
     */
    function onHide() {
        ajax.abort();
        if( task.taskStartTime ) {
            Ext.TaskMgr.stop(task);
            delete task.taskRunTime;
            delete task.taskStartTime;
        }
        mask.hide();
    }
    
    /**
     * Invoke by Ext.form.textfiled blur event.
     * 
     * @inner
     * @param {Ext.form.textfield} field
     */
    function onRaidIDBlur(field) {
        var id = field.getValue();
        if( id != "" ) {
            mask.show();
            ajax.check_raidid(id, ajaxCheckRaidID);
        }
    }
    
    /**
     * Mapping the spare value to currect wording.
     * 
     * @inner
     * @param {Boolean} value
     */
    function spareRenderer(value) {
        if( value.length == 0 ) {
            return WORDS.na;
        } else {
            return value.join(',');
        }
    }
    
    /**               
      * Mapping the status value to currect wording.
      *                   
      * @inner
      * @param {String} value     
      */                         
    function statusRenderer(value) {
        var re = value.match(/([^: ]*)[^\d]*(\d{0,3}.?\d?)%?/);
        switch(re[1]) {               
            case 'Building':               
                return String.format(WORDS.building, re[2]);
            case 'Recovering':              
                return String.format(WORDS.recovering, re[2]);
            case 'Healthy':                   
                return WORDS.healthy; 
            case 'Degrade':        
                return WORDS.degrade;     
            default:                  
                return value;       
        }                        
    }
    
    /**
     * Detect grid is on RAID mode or Volumes mode.
     * 
     * @inner
     */
    function onGridClick() {
        if( grid.selModel.isLocked() == false ) {
            if( grid.selModel.hasSelection() == true ) {
                if( raid_id_safe == true || mode == 2 ) {
                    buttons[0].setDisabled(false);
                }
                setTestShow(WORDS.test_speed);
            } else {
                buttons[0].setDisabled(true);
                setTestShow();
            }
        }
    }
    
    /**
     * Change RAID information to read only or not.
     * 
     * @inner
     * @param {Boolean} lock True to lock and False to unlock
     */
    function lockInfo(lock) {
        lock = lock;
        for( var i = 0 ; i < 3 ; ++i ) {
            raidInfo[i].setDisabled(lock);
        }
    }
    
    /**
     * Chnage RAID information
     * 
     * @inner
     * @param {Array} info
     */
    function setInfo(info) {
        info = info || [];
        for( var i = 0 ; i < 5 ; ++i ) {
            raidInfo[i].setValue(info[i] || '');
        }
    }
    
    /**
     * Show/Hide speed field in the grid.
     * 
     * @inner
     * @param {Boolean} hide True to hide and False to show
     */
    function hideSpeedColumn(hide) {
        grid.colModel.setHidden(8, hide);
    }
    
    /**
     * Change create/expand RAID controller
     * 
     * @inner
     * @param {String} [show=null] Create or Expand wording
     */
    function setCreateExpandShow(show) {
        show = show || null;
        switch(show) {
        case null:
            gridToolbar[1].setDisabled(true);
            gridToolbar[2].setDisabled(true);
            break;
        case WORDS.create:
            gridToolbar[1].setDisabled(false);
            gridToolbar[2].setDisabled(true);
            break;
        case WORDS.expand:
            gridToolbar[1].setDisabled(true);
            gridToolbar[2].setDisabled(false);
            break;
        }
    }
    
    /**
     * Change remove RAID controller
     * 
     * @inner
     * @param {String} [show=undefined] Remove wording
     */
    function setRemoveShow(show) {
        if( show == WORDS.remove ) {
            gridToolbar[3].setDisabled(false);
        } else {
            gridToolbar[3].setDisabled(true);
        }
    }
    
    /**
     * Change Suspend/Resume service controller
     * 
     * @inner
     * @param {String} [show=null] Suspend/Resume wording
     */
    function setSuspendResumeShow(show) {
        show = show || null;
        switch(show) {
        case null:
            gridToolbar[4].setDisabled(true);
            gridToolbar[5].setDisabled(true);
            break;
        case WORDS.suspend:
            gridToolbar[4].setDisabled(false);
            gridToolbar[5].setDisabled(true);
            break;
        case WORDS.resume:
            gridToolbar[4].setDisabled(true);
            gridToolbar[5].setDisabled(false);
            break;
        }
    }
    
    /**
     * Change test speed controller
     * 
     * @inner
     * @param {String} [show=undefined] Test wording
     */
    function setTestShow(show) {
        if( show == WORDS.test_speed ) {
            gridToolbar[6].setDisabled(false);
        } else {
            gridToolbar[6].setDisabled(true);
        }
    }
    
    /**
     * Change apply/cancel buttons show or hide
     * 
     * @inner
     * @param {Boolean} [show=false]
     */
    function setButtonShow(show) {
        if( show == true ) {
            //buttons[0].show();
            buttons[1].setDisabled(false);
        } else {
            buttons[0].setDisabled(true);
            buttons[1].setDisabled(true);
        }
    }
    
    /**
     * Resorting grid data index
     * 
     * @inner
     * @param {Ext.data.Record} ra
     * @param {Ext.data.Record} rb
     * @returns {Boolean} ra.data.index > rb.data.index
     */
    function byVolumeIndex(ra, rb) {
        return ra.data.index > rb.data.index;
    }
    
    /**
     * Get user selection record and sort them by index.
     * 
     * @inner
     * @returns {Ext.data.Record[]} All records are selected by user
     */
    function getGridSelections() {
        var rs = grid.selModel.getSelections();
        rs.sort(byVolumeIndex);
        return rs;
    }
    
    function onTestFinish() {
        if( mode != null ) {
            gridStore.removeAll();
            buttons[0].setDisabled(true);
            setTestShow();
            ajax.getAvaiableVolume(ajaxGetAvaiableVolume);
        }
    }
    
    /**
     * Call back when some button is clicked.
     *
     * @inner
     * @param {String} btn
     */
    function onButton(btn) {
        switch(btn.text) {
            case WORDS.refresh:
                if( grid.selModel.isLocked() ) {
                    ajax.getManagment(ajaxGetManagment);
                } else {
                    buttons[0].setDisabled(true);
                    ajax.getAvaiableVolume(ajaxGetAvaiableVolume);
                }
                setTestShow();
                mask.show();
                break;
            case WORDS.create:
                raid_id_safe = false;
                if( mode == null ) {
                    mode = 1;
                }
                if( gridStore.totalLength == 0 ) {
                    setInfo(['','64','xfs','','','','']);
                    lockInfo(false);
                }
            case WORDS.expand:
                if( mode == null ) {
                    mode = 2;
                }
                grid.selModel.unlock();
                dropOrder.unlock();
                hideSpeedColumn(true);
                setCreateExpandShow();
                setRemoveShow();
                setSuspendResumeShow();
                setTestShow();
                setButtonShow(true);
                gridStore.removeAll();
                
                ajax.getAvaiableVolume(ajaxGetAvaiableVolume);
                mask.show();
                break;
            case WORDS.remove:
                Ext.Msg.prompt(
                    WORDS.attention,
                    WORDS.remove_confirm,
                    onRemoveConfirm
                );
                break;
            case WORDS.suspend:
                ajax.setSuspend(raid_md, ajaxSetSuspend);
                mask.show();
                break;
            case WORDS.resume:
                ajax.setResume(ajaxSetResume);
                break;
            case WORDS.test_speed:
                var rs =  getGridSelections();
                if( rs.length == 0 ) {
                    setTestShow();
                } else {
                    var volumes = [];
                    for( var i = 0 ; i < rs.length ; ++i ) {
                        volumes.push([rs[i].data.device, rs[i].data.ipv4, rs[i].data.raid_id]);
                    }
                    speed.setTestingTarget(volumes);
                    speed.show();
                    setTestShow();
                }
                break;
            case WORDS.apply:
                if( raidInfo[0].isValid() == false ) return;
                var rid = raidInfo[0].getValue();
                var stripe = raidInfo[1].getValue();
                var fs = raidInfo[2].getValue();
                var rs =  getGridSelections();
                var volumes = [];
                for( var i = 0 ; i < rs.length ; ++i ) {
                    volumes.push([rs[i].data.device, rs[i].data.ipv4, rs[i].data.raid_id]);
                }
                
                if( mode == 1 ) {
                    ajax.setRaid(rid, stripe, fs, volumes, ajaxSetRaidExpand);
                } else {
                    if( volumes.length + use_hv_clients > TCode.HV.ClientLimit ) {
                        Ext.Msg.show({
                            title: WORDS.attention,
                            msg: String.format(WORDS.expand_limit, TCode.HV.ClientLimit),
                            buttons: Ext.MessageBox.OK,
                            icon: Ext.MessageBox.INFO
                        });
                        return;
                    } else {
                        ajax.setExpand(raid_md, volumes, ajaxSetRaidExpand);
                    }
                }
            case WORDS.cancel:
                mask.show();
                mode = null;
                lockInfo(true);
                grid.selModel.lock();
                dropOrder.lock();
                hideSpeedColumn(true);
                setCreateExpandShow();
                setRemoveShow();
                setSuspendResumeShow();
                setTestShow();
                setButtonShow(false);
                gridStore.removeAll();
                if( btn.text == WORDS.cancel ) {
                    ajax.getManagment(ajaxGetManagment);
                }
                break;
        }
    }
    
    /**
     * Call back when confirm window has event
     *
     * @inner
     * @param {String} btn
     */
    function onRemoveConfirm(btn, value) {
        if( btn == 'ok' && value == 'Yes' ) {
            mask.show();
            ajax.setRaidRemove(raid_md, ajaxSetRaidRemove);
        }
    }
    
    /**
     * Give selection records index
     *
     * @inner
     * @param {Array} volumes
     */
    function makeVolumeIndex(volumes) {
        for( var i = 0 ; i < volumes.length ; ++i ) {
            volumes[i][9] = i+1;
        }
    }
    
    /**
     * Call back when ajax.checkRaidID() success
     *
     * @inner
     * @param {Boolean} exists
     */
    function ajaxCheckRaidID(exists) {
        mask.hide();
        if( exists == true ) {
            raid_id_safe = false;
            buttons[0].setDisabled(true);
            Ext.Msg.show({
                title: WORDS.attention,
                msg: String.format(WORDS.id_duplicate, raidInfo[0].getValue()),
                buttons: Ext.MessageBox.OK,
                icon: Ext.MessageBox.INFO
            });
        } else {
            raid_id_safe = true;
            var rs =  getGridSelections();
            if( rs.length > 0 ) {
                buttons[0].setDisabled(false);
            }
        }
    }
    
    /**
     * Call back when ajax.getManagment() success
     *
     * @inner
     * @param {Array} info
     * @param {Number} md
     * @param {Array} volumes
     * @param {Number} monitor 0: nothing, 1: monitor raid, 2: monitor testing
     * @param {Boolean} suspend True: Deamon is run, False: Deamon is stoped
     */
    function ajaxGetManagment(info, md, volumes, monitor, suspend) {
        grid.selModel.lock();
        dropOrder.lock();
        lockInfo(true);
        setInfo();
        hideSpeedColumn(true);
        setCreateExpandShow();
        setRemoveShow();
        setSuspendResumeShow();
        setTestShow();
        setButtonShow(false);
        gridStore.removeAll();
        
        mask.hide();
        raid_md = md;
        makeVolumeIndex(volumes);
        
        if( info[0] == null) {
            chart[0].setUsage();
        } else {
            chart[0].setUsage([
                [WORDS.used, info[5]],
                [WORDS.unused, (info[4] - info[5])]
            ]);
            
            info[4] += ' GB';
        }
        
        setInfo(info);
        
        gridStore.loadData(volumes);
        
        use_hv_clients = volumes.length;
        
        if( volumes.length == 0 ) {
            Ext.getCmp('HvMasterBtn').setIcon('/theme/images/index/hv/hv_mainOff.png');
            setCreateExpandShow(WORDS.create);
        } else {
            Ext.getCmp('HvMasterBtn').setIcon('/theme/images/index/hv/hv_mainOn.png');
            if( info[3] == 'Healthy' && volumes.length < TCode.HV.ClientLimit) {
                setCreateExpandShow(WORDS.expand);
            }
            setRemoveShow(WORDS.remove);
        }
        
        if( suspend ) {
            setCreateExpandShow();
            setSuspendResumeShow(WORDS.resume);
        } else {
            setSuspendResumeShow(WORDS.suspend);
        }
        
        switch(monitor) {
        case 0:
            if( task.taskStartTime ) {
                Ext.TaskMgr.stop(task);
                delete task.taskRunTime;
                delete task.taskStartTime;
                delete task.run;
                mask.hide();
                resume_mask.hide();
            }
            break;
        case 1:
            if( !task.taskStartTime ) {
                task.run = monitorGetManagment;
                Ext.TaskMgr.start(task);
            }
            mask.show();
            break;
        case 2:
            speed.show();
            speed.getTestingStage();
            break;
        case 3:
            task.run = monitorGetManagment;
            Ext.TaskMgr.start(task);
            resume_mask.show();
            break;
        }
    }
    
    /**
     * Call back when ajax.getAvaiableVolume() success
     *
     * @inner
     * @param {Array[][]} volumes
     */
    function ajaxGetAvaiableVolume(volumes) {
        makeVolumeIndex(volumes);
        gridStore.loadData(volumes);
        mask.hide();
    }
    
    /**
     * Call back when ajax.setRaidExpand() success
     * 
     * @inner
     * @param {Boolean} success
     */
    function ajaxSetRaidExpand(success) {
        if( success == false ) {
            // add alert
            Ext.Msg.alert(
                WORDS.attention,
                WORDS.create_expand_fail
            );
            mask.hide();
        } else {
            ajax.getManagment(ajaxGetManagment);
        }
    }
    
    /**
     * Call back when ajax.setSuspend() success
     * 
     * @inner
     * @param {Boolean} success
     */
    function ajaxSetSuspend(success) {
        if( success == true ) {
            ajax.getManagment(ajaxGetManagment);
            mask.hide();
        } else {
            setSuspendResumeShow(WORDS.suspend);
        }
    }
    
    /**
     * Call back when ajax.setResume() success
     * 
     * @inner
     * @param {Boolean} success
     */
    function ajaxSetResume(success) {
        ajax.getManagment(ajaxGetManagment);
    }
    
    /**
     * Call back when ajax.setRaidRemove() success
     * 
     * @inner
     * @param {} success
     */
    function ajaxSetRaidRemove(success) {
        ajax.getManagment(ajaxGetManagment);
    }
    
    TCode.HV.Managment.superclass.constructor.call(this, config);
}

Ext.extend(TCode.HV.Managment, Ext.Panel);

/**
 * Provider is the slave mode of Huge Volume.
 * This mode can create multi volumes(iSCSI block RAID) and assign target (master).
 *
 * @class Provider
 * @namespace TCode.HV
 * @extends Ext.Panel
 * @constructor
 * @param {Object} conf Use to override default configure
 */
TCode.HV.Provider = function(conf) {
    var self = this;
    
    var eths,
        mask,
        unused_disks = 0,
        vs = [];
    
    var ajax = TCode.HV.Ajax;
    
    var task = {
        run: monitorGetProvider,
        interval: 5000
    }
    
    var gridStore = new Ext.data.SimpleStore({
        pruneModifiedRecords: true,
        fields: [
            { name: 'raid' },
            { name: 'level' },
            { name: 'capacity' },
            { name: 'spare' },
            { name: 'status' },
            { name: 'interface' },
            { name: 'target' },
            { name: 'conn_status' },
            { name: 'md' },
            { name: 'tray' }
        ]
    })
    
    var comboStore = new Ext.data.SimpleStore({
        pruneModifiedRecords: true,
        fields: ['v', 'ip', 'mask', 'k']
    })
    
    var gridColumes = [
        new Ext.grid.RowNumberer(),
        {
            header: WORDS.raid_id,
            width: 60,
            dataIndex: 'raid'
        },
        {
            header: WORDS.level,
            width: 40,
            dataIndex: 'level'
        },
        {
            header: WORDS.tray,
            width: 40,
            dataIndex: 'tray'
        },
        {
            header: WORDS.capacity,
            dataIndex: 'capacity'
        },
        {
            header: WORDS.spare,
            dataIndex: 'spare',
            width: 50,
            renderer: spareRenderer
        },
        {
            header: WORDS.status,
            dataIndex: 'status',
            renderer: statusRenderer
        },
        {
            header: WORDS.interface,
            dataIndex: 'interface',
            renderer: interfaceRenderer,
            editor: new Ext.form.ComboBox({
                xtype: 'combo',
                store: comboStore,
                listWidth: 200,
                editable: false,
                displayField: 'k',
                valueField: 'v',
                typeAhead: false,
                triggerAction: 'all',
                allowBlank: false,
                mode: 'local',
                lazyRender: true
            })
        },
        {
            header: WORDS.target,
            dataIndex: 'target',
            editor: new Ext.form.TextField(),
            renderer: targetRenderer
        },
        {
            header: WORDS.conn_status,
            dataIndex: 'conn_status',
            renderer: connectionRenderer
        }
    ]
    
    var apply = new Ext.Button({
        text: WORDS.apply,
        disabled: true,
        handler: onButton
    })
    
    var gridToolbar = [
        new Ext.Button({
            text: WORDS.create,
            iconCls: 'add',
            tooltip: WORDS.volume_create_tip,
            disabled: true,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.remove,
            iconCls: 'remove',
            tooltip: WORDS.volume_remove_tip,
            disabled: true,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.refresh,
            iconCls: 'refresh',
            tooltip: WORDS.refresh_tip,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.disconnect,
            iconCls: 'disconnect',
            tooltip: WORDS.reconnect_tip,
            disabled: true,
            handler: onButton
        }),
        new Ext.Button({
            text: WORDS.reconnect,
            iconCls: 'connect',
            tooltip: WORDS.reconnect_tip,
            disabled: true,
            handler: onButton
        })
    ]
    
    var grid = {
        xtype: 'editorgrid',
        width: 680,
        autoWidth: true,
        height: 300,
        frame: true,
        clicksToEdit: 1,
        buttonAlign: 'left',
        style: 'margin: 5px',
        viewConfig: {
            autoFill: true,
            forceFit: true
        },
        selModel: new Ext.grid.RowSelectionModel({
            singleSelect: false,
            listeners: {
                selectionchange: rowSelectionchange
            }
        }),
        store: gridStore,
        columns: gridColumes,
        tbar: gridToolbar,
        buttons: [ apply ]
        
    }
    
    var descTpl = new Ext.XTemplate('<tpl for="ol"><li>{li}</tpl>');
    var descVaules = {
        ol: [
            { li: WORDS.slave_desc1 }
        ]
    }
    
    var note = {
        xtype: 'fieldset',
        title: WORDS.description,
        style: 'margin: 5px',
        autoHeight: true,
        items: {
            xtype: 'box',
            autoEl: {
                tag: 'ol',
                style: 'list-style-position: inside; list-style-type: decimal;',
                html: descTpl.apply(descVaules)
            }
        }
    }
    
    var config = {
        layout: 'form',
        width: 700,
        autoHeight: true,
        bodyStyle: 'padding: 0px;',
        title: WORDS.provider_title,
        frame: true,
        items: [
            grid,
            note
        ],
        listeners: {
            render: onRender,
            beforedestroy: onDestroy,
            show: onShow,
            hide: onHide
        }
    }
    
    Ext.applyIf(config, conf);
    
    function monitorGetProvider() {
       ajax.getProvider(ajaxGetProvider);
    }

    /**
     * Invoke by Ext.Panel when html dom objects is rendered.
     * 
     * @inner
     */
    function onRender() {
        grid = self.items.get(0);
        mask = new Ext.LoadMask(self.body, {msg: WORDS.processing});
    }
    
    /**
     * Invoke by Ext.Panel before html dom objects is destroied.
     * 
     * @inner
     */
    function onDestroy() {
        ajax.abort();
        Ext.destroy(ajax);
        delete ajax;
    }
    
    /**
     * Initial/Reset panel controller to default.
     * Invoke by Ext.Panel when Ext.TabPanel's tab is changed.
     * 
     * @inner
     */
    function onShow() {
        ajax.getProvider(ajaxGetProvider);
        mask.show();
    }
    
    /**
     * Invoke by Ext.Panel when Ext.TabPanel's tab is changed.
     * 
     * @inner
     */
    function onHide() {
        if( task.taskStartTime ) {
            Ext.TaskMgr.stop(task);
            delete task.taskRunTime;
            delete task.taskStartTime;
        }
        mask.hide();
    }
    
    /**
     * Mapping the spare value to currect wording.
     * 
     * @inner
     * @param {Boolean} value
     */
    function spareRenderer(value) {
        if( value.length == 0 ) {
            return WORDS.na;
        } else {
            return value.join(',');
        }
    }
    
    /**
     * Mapping the status value to currect wording.
     * 
     * @inner
     * @param {String} value
     */
    function statusRenderer(value) {
        var re = value.match(/([^: ]*)[^\d]*(\d{0,3}.?\d?)%?/);
        switch(re[1]) {
        case 'Building':
            return String.format(WORDS.building, re[2]);
        case 'Recovering':
            return String.format(WORDS.recovering, re[2]);
        case 'Healthy':
            return WORDS.healthy;
        case 'Degrade':
            return WORDS.degrade;
        default:
            return value;
        }
    }
    
    /**
     * Mapping the connection value to currect wording.
     * 
     * @inner
     * @param {Number} value 0: No target, 1: Volume busy, 2: Target connect, 3: Target disconnect
     */
    function connectionRenderer(value) {
        switch(value) {
        case 1: return WORDS.not_ready;
        case 2: return WORDS.connected;
        case 3: return WORDS.disconnected;
        case 0: 
        default: return WORDS.unused;
        }
    }
    
    /**
     * Mapping the network interface to currect value and wording.
     * 
     * @inner
     * @param {String} v
     * @param {Object} obj
     * @param {Ext.data.Record} rs
     * @param {Number} index
     */
    function interfaceRenderer(v, obj, rs, index) {
        eths[0] = eths[0] || ['','',''];
        v = v || eths[0][0];
        
        var ip = -1;
        for( var i = 0 ; i < eths.length ; ++i ) {
            if( eths[i][0] == v ) {
                ip = i;
            }
        }
        
        if( ip == -1 ) {
            ip = 0;
            v = eths[0][0];
        }
        rs.set('interface', v);
        if( rs.get('target') != '' ) {
            var viald = ipv4check(eths[ip][1], eths[ip][2], rs.get('target'));
            if( viald == false ) {
                rs.set('target', eths[ip][1]);
            }
        }
        
        if( gridStore.getModifiedRecords().length > 0 ) {
            apply.setDisabled(false);
        } else {
            apply.setDisabled(true);
        }
        
        return eths[ip][1];
    }
    
    /**
     * Mapping the network interface to currect target IP.
     * 
     * @inner
     * @param {String} v
     * @param {Object} obj
     * @param {Ext.data.Record} rs
     * @param {Number} index
     */
    function targetRenderer(v, obj, rs, index) {
        if( v == '' ) {
            return WORDS.target_alert;
        } else {
            var ip = 0;
            for( var i = 0 ; i < eths.length ; ++i ) {
                if( ipv4check(eths[i][1], eths[i][2], v) ) {
                    if( rs.get('interface') == eths[i][0] )
                        return v;
                }
            }
        }
    }
    
    /**
     * Monitor the data grid has selection or not.
     *
     * @inner
     * @param {Ext.grid.RowSelectionModel} selModel
     */
    function rowSelectionchange(selModel) {
        if( selModel.hasSelection() ) {
            gridToolbar[1].setDisabled(false);
            gridToolbar[3].setDisabled(false);
        } else {
            gridToolbar[1].setDisabled(true);
            gridToolbar[3].setDisabled(true);
        }
    }
    
    /**
     * Handle all button click event.
     *
     * @inner
     * @param {String} btn
     */
    function onButton(btn) {
        switch(btn.text){
        case WORDS.refresh:
            ajax.getVolume(ajaxGetVolume);
            mask.show();
            break;
        case WORDS.create:
            TCode.HV.RaidWizard(function() {
                mask.show();
                ajax.getProvider(ajaxGetProvider);
            });
            break;
        case WORDS.remove:
            vs.splice(0, vs.length);
            var rs = grid.selModel.getSelections();
            for( var i = 0 ; i < rs.length ; ++i ) {
                var status = rs[i].get('conn_status');
                if( status == 1 || status == 2 ) {
                    vs.splice(0, vs.length);
                    Ext.Msg.alert(
                        WORDS.attention,
                        WORDS.remove_fail
                    );
                    return;
                } else {
                    vs.push([
                        rs[i].data.md,
                        rs[i].data.interface,
                        rs[i].data.target,
                        rs[i].data.tray
                    ]);
                }
            }
            
            Ext.Msg.prompt(
                WORDS.attention,
                WORDS.remove_confirm,
                onConfirmRemove
            );
            break;
        case WORDS.disconnect:
            vs.splice(0, vs.length);
            var rs = grid.selModel.getSelections();
            for( var i = 0 ; i < rs.length ; ++i ) {
                vs.push([
                    rs[i].data.md,
                    rs[i].data.interface,
                    rs[i].data.target,
                    rs[i].data.tray
                ]);
            }
            mask.show();
            ajax.disconnect(vs, ajaxDisconnect);
            break;
        case WORDS.reconnect:
            vs.splice(0, vs.length);
            var rs = grid.selModel.getSelections();
            for( var i = 0 ; i < rs.length ; ++i ) {
                vs.push([
                    rs[i].data.md,
                    rs[i].data.interface,
                    rs[i].data.target,
                    rs[i].data.tray
                ]);
            }
            mask.show();
            ajax.reconnect(vs, ajaxReconnect);
            break;
        case WORDS.apply:
            vs.splice(0, vs.length);
            var rs = gridStore.getModifiedRecords();
            for( var i = 0 ; i < rs.length ; ++i ) {
                var status = rs[i].get('conn_status');
                if( status == 1 || status == 2 ) {
                    rs[i].reject();
                    Ext.Msg.alert(
                        WORDS.attention,
                        WORDS.target_fail
                    );
                    return;
                } else {
                    vs.push([
                        rs[i].data.md,
                        rs[i].data.interface,
                        rs[i].data.target,
                        rs[i].data.tray
                    ]);
                }
            }
            ajax.setTarget(vs, ajaxSetTarget);
            apply.setDisabled(true);
            mask.show();
            break;
        }
    }
    
    /**
     * Check the grid has data or not.
     *
     * @inner
     */
    function checkVolumes() {
        if( gridStore.data.length == 0 ) {
            gridToolbar[4].setDisabled(true);
            Ext.getCmp('HvClientBtn').setIcon('/theme/images/index/hv/hv_subOff.png');
        } else {
            gridToolbar[4].setDisabled(false);
            Ext.getCmp('HvClientBtn').setIcon('/theme/images/index/hv/hv_subOn.png');
        }
    }
    
    /**
     * Double check user want to remove volume(s)
     *
     * @inner
     * @param {String} btn
     * @param {String} value
     */
    function onConfirmRemove(btn, value) {
        if( btn == 'ok' && value == 'Yes' ) {
            mask.show();
            ajax.setVolumeRemove(vs, ajaxSetVolumeRemove);
            vs.splice(0, vs.length);
        }
    }
    
    /**
     * Call back when ajax.getProvider() success
     *
     * @inner
     * @param {Array[][]} volumes
     * @param {Array[]} _eths
     * @param {Boolean} monitor
     */
    function ajaxGetProvider(volumes, _eths, unused_disks, monitor) {
        mask.hide();
        eths = _eths;
        
        for(var i = 0 ; i < eths.length ; ++i ) {
            eths[i][3] = eths[i][1] + '/' + eths[i][2];
        }
        gridStore.loadData(volumes);
        comboStore.loadData(eths);
        
        var enabled = (unused_disks >= 3) && ( gridStore.data.length == 0 );
        gridToolbar[0].setDisabled(!enabled);
        
        checkVolumes();
        
        if( monitor == true ) {
            if( !task.taskStartTime ) {
                Ext.TaskMgr.start(task);
            }
            mask.show();
        } else {
            if( task.taskStartTime ) {
                Ext.TaskMgr.stop(task);
                delete task.taskRunTime;
                delete task.taskStartTime;
            }
        }
    }
    
    /**
     * Call back when ajax.setTarget() success
     *
     * @inner
     * @param {Boolean} success
     * @param {String[]} ip
     */
    function ajaxSetTarget(success, ip) {
        if( success == true ) {
            ajax.getVolume(ajaxGetVolume);
        } else {
            mask.hide();
            Ext.Msg.show({
                title: WORDS.attention,
                msg: String.format('{0}</br>{1}', WORDS.ip_conn_fail, ip.join('</br>') ),
                buttons: Ext.MessageBox.OK,
                icon: Ext.MessageBox.INFO,
                fn: ajax.getVolume
            });
        }
    }
    
    /**
     * Call back when ajax.getVolume() success
     *
     * @inner
     * @param {Array[][]} volumes
     */
    function ajaxGetVolume(volumes) {
        mask.hide();
        gridStore.loadData(volumes);
        apply.setDisabled(true);
        checkVolumes();
    }
    
    function ajaxDisconnect(connections) {
        if( connections > 0 ) {
            Ext.Msg.show({
                title: WORDS.attention,
                icon: Ext.Msg.WARNING,
                buttons: Ext.Msg.OK,
                msg: WORDS.interrupt_fail
            });
        }
        ajax.getVolume(ajaxGetVolume);
    }
    
    function ajaxReconnect() {
        ajax.getVolume(ajaxGetVolume);
    }
    
    /**
     * Call back when ajax.setVolumeRemove() success
     *
     * @inner
     * @param {Boolean} success
     */
    function ajaxSetVolumeRemove(success) {
        ajax.getProvider(ajaxGetProvider);
    }
    
    TCode.HV.Provider.superclass.constructor.call(this, config);
}

Ext.extend(TCode.HV.Provider, Ext.Panel);

/**
 * Show RAID wizard and monitor finish status to invkoe fn.
 *
 * @namespace TCode.HV
 * @function RaidWizard
 * @param {Function} fn
 */
TCode.HV.RaidWizard = function(fn) {
    chunk_store = new Ext.data.SimpleStore({
        fields: ['value', 'display'],
        data: TCode.HV.Stripe
    });
    
    file_system_store = new Ext.data.SimpleStore({
        fields: ['value', 'display'],
        data: [['hv', 'VE']]
    });
    
    raid_store = new Ext.data.JsonStore({
        storeId:'raid_store',
        root:'raid_list',
        idProperty: 'md_num',
        fields:TCode.HV.RaidStruct,
        autoLoad: true,
        url: 'getmain.php',
        baseParams: {
            fun: 'raid',
            action: 'getraidlist'
        }
    });
    
    reloadUI2_time = 0;
    
    reloadUI2 = Ext.emptyFn;
    
    runCreateRaidWizard("create", true);
    
    var wizard = Ext.WindowMgr.getActive()
    wizard.on('hide', onVolumeCreate);
    
    function onVolumeCreate() {
        wizard.un('hide', onVolumeCreate);
        wizard.destroy();
        delete wizard;
        fn();
    }
}

/**
 * The major UI container of Huge Volume.
 *
 * @class Container
 * @namespace TCode.HV
 * @extends Ext.Panel
 * @constructor
 */
TCode.HV.Container = function() {
    var self = this;
    
    var ajax = TCode.HV.Ajax;
    
    var style = 'background: transparent';
    
    var config = {
        renderTo: 'DomHV',
        width: 700,
        labelWidth: 150,
        autoHeight: true,
        style: 'margin: 10px;',
        items: [
            {
                layout: 'form',
                items: [
                    {
                        xtype: 'radiogroup',
                        fieldLabel: WORDS['hv_service'],
                        items: [
                            {
                                name: 've_service',
                                boxLabel: WORDS['enable'],
                                inputValue: 'on',
                                checked: TCode.HV.Service == '1'
                            },
                            {
                                name: 've_service',
                                boxLabel: WORDS['disable'],
                                inputValue: 'off',
                                checked: TCode.HV.Service == '0'
                            },
                            {
                                xtype: 'button',
                                text: WORDS['apply'],
                                setSize: Ext.emptyFn,
                                handler: onApply
                            }
                        ]
                    }
                ]
            },
            {
                layout: 'column',
                style: 'margin-bottom: 5px',
                disabled: TCode.HV.Service == '0',
                items: [
                    {
                        id: 'HvMasterBtn',
                        xtype: 'LargeButton',
                        icon: TCode.HV.MasterOnOff == '1' ? '/theme/images/index/hv/hv_mainOn.png' : '/theme/images/index/hv/hv_mainOff.png',
                        text: String.format('<h2>{0}</h2><br>{1}', WORDS.master_text, WORDS.master_text_help),
                        height: 100,
                        columnWidth: .5,
                        handler: function() {
                            self.items.get(2).layout.setActiveItem(0);
                        }
                    },
                    {
                        id: 'HvClientBtn',
                        xtype: 'LargeButton',
                        icon: TCode.HV.ClientOnOff == '1' ? '/theme/images/index/hv/hv_subOn.png' : '/theme/images/index/hv/hv_subOff.png',
                        text: String.format('<h2>{0}</h2><br>{1}', WORDS.slave_text, WORDS.slave_text_help),
                        height: 100,
                        columnWidth: .5,
                        handler: function() {
                            self.items.get(2).layout.setActiveItem(1);
                        }
                    }
                ]
            },
            {
                //xtype: 'tabpanel',
                layout: 'card',
                activeItem: 0,
                layoutOnTabChange: true,
                bodyStyle: style,
                disabled: TCode.HV.Service == '0',
                items: [
                    new TCode.HV.Managment(),
                    new TCode.HV.Provider()
                ]
            }
        ],
        listeners: {
            render: onRender,
            beforedestroy: onDestroy
        }
    }
    
    /**
     * Ext.Panel callback function for render evnet.
     * 
     * @inner
     */
    function onRender() {
        Ext.get('content').getUpdateManager().on(
            'beforeupdate',
            self.destroy,
            self
        );
    }
    
    /**
     * Ext.Panel callback function for beforedestroy evnet.
     * 
     * @inner
     */
    function onDestroy() {
        Ext.get('content').getUpdateManager().un(
            'beforeupdate',
            self.destroy,
            self
        );
        
        delete TCode.HV;
    }
    
    function onApply() {
        var mode = self.items.get(0).items.get(0).getValue();
        ajax.setVolumeExpansion(mode, onSetVolumeExpansion);
        myMask.show();
    }
    
    function enable(value) {
        if( value ) {
            self.items.get(1).setDisabled(false);
            self.items.get(2).setDisabled(false);
        } else {
            self.items.get(1).setDisabled(true);
            self.items.get(2).setDisabled(true);
        }
    }
    
    function onSetVolumeExpansion(success) {
        myMask.hide();
        var mode = self.items.get(0).items.get(0).getValue();
        if( success ) {
            TCode.HV.Service = mode == 'on' ? '1' : '0';
        }
        enable(TCode.HV.Service == '1');
    }
    
    TCode.HV.Container.superclass.constructor.call(this, config);
}

Ext.extend(TCode.HV.Container, Ext.Panel);

Ext.onReady(function() {
    if( TCode.HV.HA == "1" ) {
        Ext.Msg.show({
            title: WORDS.attention,
            msg: WORDS.exclusive,
            buttons: Ext.MessageBox.OK,
            icon: Ext.MessageBox.WARNING,
            closable: false,
            fn: function() {
                processUpdater('getmain.php','fun=ha');
            }
        })
        return;
    }
    
    switch( TCode.HV.Nic10G ) {
    case 0:
        Ext.QuickTips.init();
        new TCode.HV.Container();
        break;
    case 1:
        Ext.Msg.show({
            title: WORDS.attention,
            msg: WORDS.tengb_alert,
            buttons: Ext.MessageBox.OK,
            icon: Ext.MessageBox.WARNING,
            closable: false,
            fn: function() {
                processUpdater('getmain.php','fun=wan');
            }
        })
        break;
    case 2:
        Ext.Msg.show({
            title: WORDS.attention,
            msg: WORDS.tengb_error,
            buttons: Ext.MessageBox.OK,
            icon: Ext.MessageBox.WARNING,
            closable: false,
            fn: function() {
                processUpdater('getmain.php','fun=wan');
            }
        });
        break;
    }
});
</script>
