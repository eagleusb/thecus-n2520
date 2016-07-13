<div id="HA"></div>
<div id='ha_network' style="padding:10px;text-align:center" class="x-hidden">
    <div style="float:left;">
        <div id="active_name"></div>
        <div id="active_ip" style="height: 14px;width:100px"></div>
        <div id="active_img" class="ha_network_1"></div>
        <div id="active_rebuild_img" style="margin-top:-30"  class="x-hidden"><img src="/theme/images/icons/rebuild_icon.png"/><br><span style="color:green;" id="active_rebuild_text"></span></div>
    </div>
    <div style="float:left;margin-top:40px;">
        <div style="margin-bottom:10px;" id="hb_txt"></div>
        <div id="hearbeat_img" class="ha_network_hb_1"></div>
    </div>
    <div style="float:left;">
        <div id="standby_name"></div>
        <div id="standby_ip" style="height: 14px;width:100px"></div>
        <div id="standby_img" class="ha_network_0"></div>
        <div id="standby_rebuild_img" style="margin-top:-30"  class="x-hidden"><img src="/theme/images/icons/rebuild_icon.png"/><br><span style="color:green;" id="standby_rebuild_text"></span></div>
    </div>
</div>
<form name="rebootform" id="rebootform">
    <input type=hidden name="action" id="action" value="reboot">
</form>
<script language="javascript">
Ext.namespace("TCode.HA");
var WORDS = <{$words}>;
var HV = <{$hv_enable}>;
TCode.HA.Procedures = <{$procedures}>;

TCode.HA.Data = {
    HA_ROLE_Name: [WORDS.active, WORDS.standby],
    HA_CUR_ROLE_Name : [WORDS.active_short, WORDS.standby_short],
    HA_ERROR: false,
    g_priority:'',
    g_pageLimit:10,
    tpl_table: "<table ><tr><td>{0}:</td><td nowrap='nowrap'>{1}</td></tr><tr><td>{2}:</td><td nowrap='nowrap'>{3}<br>{4}</td></tr></table>",
    tpl_hb_table: "<table width='200' ><tr><td nowrap='nowrap'>{0}:</td><td nowrap='nowrap'>{1}</td></tr><tr><td nowrap='nowrap'>{2}:</td><td nowrap='nowrap'>{3}</td></tr><tr><td nowrap='nowrap'>{4}:</td><td nowrap='nowrap'>{5}</td></tr></table>"
};
Ext.applyIf(TCode.HA.Data, <{$data}>);

Ext.override(Ext.form.Field, { 
    hideItem: function(){ 
        if (this.getForm(this)) {
            this.getForm(this).addClass('x-hide-' + this.hideMode);
            this.setVisible(false);
        }
    }, 
    showItem: function(){ 
        if (this.getForm(this)) {
            this.getForm(this).removeClass('x-hide-' + this.hideMode); 
            this.setVisible(true);
        }
    }, 
    setFieldLabel: function(text) { 
        if (this.getForm(this)) {
            var label = this.getForm(this).first('label.x-form-item-label'); 
            label.update(text); 
        }
    },
    getForm: function() {
        return this.el.findParent('.x-form-item', 3, true);
    }
});


TCode.HA.Ajax = function(listeners) {
    var self = this;
    var es = listeners || {};
    var events = {};
    /**
     * Invoke by Ext.data.Connection when success event.
     * 
     * @inner
     * @param {Object} response
     * @param {Object} opts
     */
    function onSuccess(response, opts) {
        try {
            var result = Ext.decode(response.responseText);
            self.fireEvent.apply(self, result);
            var e = result.shift();
            if( typeof es[e] == 'function' ) {
                es[e].apply(self, result);
            }
        } catch(err) {
        }
    }
    
    /**
     * Invoke by Ext.data.Connection when failure event.
     * TODO: handler this when ajax timeout or http connection lose.
     * @inner
     * @param {Object} response
     * @param {Object} opts
     */
    function onFailure(response, opts) {
    }
    
    /**
     * Make ajax request to getmain rule.
     * 
     * @inner
     * @param {String} remote procedure
     * @param {Object} params
     */
    function getRequest(action, params) {
        self.request({
            url: 'getmain.php',
            params: {
                fun: 'ha',
                action: action,
                params: Ext.encode(params)
            },
            success: onSuccess,
            failure: onFailure
        })
    }
    
    /**
     * Make ajax request to setmain rule.
     * 
     * @inner
     * @param {String} remote procedure
     * @param {Object} params
     */
    function setRequest(action, params) {
        self.request({
            url: 'setmain.php',
            params: {
                fun: 'setha',
                action: action,
                params: Ext.encode(params)
            },
            success: onSuccess,
            failure: onFailure
        })
    }
    
    /**
     * Generate procedures
     * 
     * @name Ajax#event:TCode.HA.Procedure
     */
    var rpc = 'function {0}(){{1}etRequest(\'{2}\', Array.prototype.slice.call(arguments));}';
    for( var i = 0 ; i < TCode.HA.Procedures.length ; ++i ) {
        var method = TCode.HA.Procedures[i];
        var type = /^set.*$/.test(method) ? 's' : 'g';
        eval(String.format(rpc, method, type, method));
        this[method] = eval(method);
        events[method] = true;
    }
    this.addEvents(events);
    delete events;
    
    TCode.HA.Ajax.superclass.constructor.call(this);
}
Ext.extend(TCode.HA.Ajax, Ext.data.Connection);


var ajax = new TCode.HA.Ajax({
    setPrimary: ajaxSetSetting,
    setSecondary: ajaxSetSetting,
    setDisable: ajaxSetDisable,
    setTruncateLog: ajaxSetTruncateLog,
    getNetwork:ajaxGetNetwork,
    getIfaceIP: ajaxGetIfaceIP,
    isHaRaidDamaged:ajaxIsHaRaidDamaged
});

/**
* update ha status , every 2 sec (monitor)
*/
var task = {
    run: function(){
        ajax.getNetwork();
    },
    interval: 2000 //2 second
}
var runner = new Ext.util.TaskRunner();

function ajaxIsHaRaidDamaged(damaged, ready){
    if(ready != true){
        ajax.setDisable('0');
    }else{
        Ext.Msg.show({
            title: WORDS.ha,
            msg: WORDS.confirm_distogether + '<br><br>' + WORDS.confirm_reboot,
            icon: Ext.Msg.QUESTION,
            buttons: Ext.Msg.YESNOCANCEL,
            fn: function(btn) {
                if( btn != 'yes' && btn != 'no' ) {
                    return;
                }
                var together = (btn == 'yes') ? "1": "0";
                ajax.setDisable(together);
            }
        });
    }
}

function ajaxGetIfaceIP(ipv4, ipv6){
    Ext.getCmp('primary_ipv4').setValue(ipv4);
    Ext.getCmp('primary_ipv6').setValue(ipv6);
}

TCode.HA.Neteotk = {
    active_img: Ext.getDom('active_img'),
    hearbeat_img: Ext.getDom('hearbeat_img'),
    standby_img: Ext.getDom('standby_img'),
    active_rebuild_img: Ext.getDom('active_rebuild_img'),
    standby_rebuild_img: Ext.getDom('standby_rebuild_img')
}

function ajaxGetNetwork(primary, heartbeat, secondary, rebuild){
    if( TCode.HA.Neteotk.active_img.className != 'ha_network_'+primary ) {
        TCode.HA.Neteotk.active_img.className = 'ha_network_'+primary;
    }
    if( TCode.HA.Neteotk.hearbeat_img.className != 'ha_network_hb_'+heartbeat ) {
        TCode.HA.Neteotk.hearbeat_img.className = 'ha_network_hb_'+heartbeat;
    }
    if( TCode.HA.Neteotk.standby_img.className != 'ha_network_'+secondary ) {
        TCode.HA.Neteotk.standby_img.className = 'ha_network_'+secondary;
    }
    if( TCode.HA.Neteotk.active_rebuild_img.className != 'x-hidden' ) {
        TCode.HA.Neteotk.active_rebuild_img.className = 'x-hidden';
    }
    if( TCode.HA.Neteotk.standby_rebuild_img.className != 'x-hidden' ) {
        TCode.HA.Neteotk.standby_rebuild_img.className = 'x-hidden';
    }
    if(rebuild != ""){
        if(rebuild=='0'){
            //primary
            TCode.HA.Neteotk.active_rebuild_img.className='';
        }else{
            //secondary
            TCode.HA.Neteotk.standby_rebuild_img.className='';
        }
    }
    raidgridStore.load();
}

function ajaxSetTruncateLog(){
    LogStore.load({params:{start:0, limit:TCode.HA.Data.g_pageLimit, init:1}});
}
function ajaxSetSetting(success, errormsg){
    if(success == true){
        booting_win.show();
        Ext.getCmp('boottext').el.dom.innerHTML = WORDS.wait_sys;
        processAjax('getmain.php?fun=nasstatus',onloadSysConfig);
    }else{
        Ext.MessageBox.show({
            title: WORDS.ha,
            msg: errormsg,
            width:400,
            closable:false,
            icon:Ext.MessageBox.INFO,
            buttons:Ext.MessageBox.OK
        });
    }
}

function HASyncReboot() {
    processAjax('setmain.php?fun=setreboot',function(){
        if(this.req.responseText=='0'){
            processAjax('getmain.php?fun=nasstatus',onloadSysConfig);
        }else{
            onLoadForm.apply(this, arguments);
        }
    },"action=ha_reboot&type=reboot");
}

function ajaxSetDisable(success, together){
    //success
    if(success == true){
        if( together == '1' ) {
            HASyncReboot();
        } else {
            processAjax('setmain.php?fun=setreboot',onLoadForm,rebootform);
        }
    }else{
    //fail
        Ext.MessageBox.show({
            title: WORDS.ha,
            msg: WORDS.error_disable_together,
            width:400,
            closable:false,
            icon:Ext.MessageBox.ERROR,
            buttons:Ext.MessageBox.OK
        });
    }
}


function getIconText(msg){
    return '<img style="margin-left:10px" src="/theme/images/icons/question.png" qtip="'+msg+'">';
}

var advanceForm = new Ext.form.FormPanel({
    border:false,
    frame:true,
    defaultType:'textfield',
    autoHeight:true,
    items:[
        { fieldLabel:WORDS.thresholds_keep , name:'ha_keepalive',vtype:'NaturalNumbers',   allowBlank:false, blankText:WORDS.blanktext, listeners:{ render: function(_name){ Ext.DomHelper.insertHtml('afterEnd', _name.el.dom, getIconText(WORDS.thresholds_between));}}},
        { fieldLabel:WORDS.thresholds_dead , name:'ha_deadtime',vtype:'NaturalNumbers',    allowBlank:false, blankText:WORDS.blanktext, listeners:{ render: function(_name){ Ext.DomHelper.insertHtml('afterEnd', _name.el.dom, getIconText(WORDS.thresholds_declare));}}},
        { fieldLabel:WORDS.thresholds_warn, name:'ha_warntime',vtype:'NaturalNumbers',     allowBlank:false, blankText:WORDS.blanktext, listeners:{ render: function(_name){ Ext.DomHelper.insertHtml('afterEnd', _name.el.dom, getIconText(WORDS.thresholds_issuing));}}},
        { fieldLabel:WORDS.thresholds_init, name:'ha_initdead',vtype:'NaturalNumbers',     allowBlank:false, blankText:WORDS.blanktext, listeners:{ render: function(_name){ Ext.DomHelper.insertHtml('afterEnd', _name.el.dom, getIconText(WORDS.thresholds_firstdead));}}},
        { fieldLabel:WORDS.udp_port, name:'ha_udpport' ,vtype:'Port',allowBlank:false, blankText:WORDS.blanktext, listeners:{ render: function(_name){ Ext.DomHelper.insertHtml('afterEnd', _name.el.dom, getIconText(WORDS.communication));}}}
    ]
});
/**
 * Advance options window
 * @private
 */
var advanceWindow = new Ext.Window({
    title:WORDS.advance_options,
    width:400,
    height:220,
    closeAction:'hide',
    modal:true,
    border:false,
    items:[
        advanceForm
    ],
    buttons:[
        {text:'OK', handler:function(){
            advanceWindow.hide();
        }}
    ]
});
advanceWindow.show();
advanceWindow.hide();

TCode.HA.Setting = function(){
    var self = this;
    
    /**
     * Primary text field
     * @private
     */
    var primaryFormPanel = new Ext.Panel({
        bodyStyle:'padding:0px',
        layout:'form',
        items:[
            {
                xtype:'radiogroup',
                fieldLabel:WORDS.auto_fail_back,
                width:350,
                items:[
                    { boxLabel:WORDS.off,    name:'ha_auto_failback',    inputValue:0},
                    { boxLabel:WORDS.on,    name:'ha_auto_failback',   inputValue:1,listeners:{
                        render: function(_name){
                            Ext.DomHelper.insertHtml('afterEnd', _name.el.next().dom, getIconText(WORDS.auto_fail_back_desc));
                        }
                    }}
                ]
            },
            { xtype:'textfield', fieldLabel:WORDS.v_hostname, name:'ha_virtual_name', vtype:'HaHostname', allowBlank:false, blankText:WORDS.blanktext},
            { xtype:'textfield', fieldLabel:WORDS.sec_hostname, name:'ha_standy_name', vtype:'Hostname', allowBlank:false, blankText:WORDS.blanktext},
            {
                xtype:'tabpanel',
                plain:true,
                activeTab:0,
                border:false,
                items:[
                    {
                        layout:'form',
                        title:WORDS.virtual_ip,
                        autoHeight:true,
                        frame:true,
                        items:[
                            {
                                xtype:'combo',
                                fieldLabel:WORDS.interface,
                                valueField:'id',
                                displayField:'name',
                                triggerAction:'all',
                                mode:'local',
                                typeAhead:true,
                                hiddenName:'ha_virtual_ip_iface',
                                selectOnFocus:true,
                                listWidth:200,
                                editable: false,
                                allowBlank: false,
                                listeners:{
                                    select: function(combo, record, index){
                                        var iface = TCode.HA.Data.Iface[index];
                                        if(iface.ipv4_setup == '1' || iface.ipv6_setup == '1' ){
                                            Ext.MessageBox.show({
                                                title: WORDS.ha,
                                                msg: WORDS.ha_dhcp_warning,
                                                width:400,
                                                closable:false,
                                                icon:Ext.MessageBox.WARNING,
                                                buttons:Ext.MessageBox.OK
                                            });
                                            //TCode.HA.Data.HA_ERROR = true;
                                            //return false;
                                        }
                                        TCode.HA.Data.HA_ERROR = false;
                                        Ext.getCmp('primary_ipv4').setValue(iface.ipv4);
                                        
                                        if(iface.ipv6_enable == '1'){
                                            Ext.getCmp('primary_ipv6').setValue(iface.ipv6);
                                        }else{
                                            Ext.getCmp('primary_ipv6').setValue('');
                                        }
                                    }
                                },
                                store: new Ext.data.JsonStore({
                                    fields:['id','name'],
                                    data:TCode.HA.Data.Iface
                                })
                            },
                            { xtype:'textfield', fieldLabel:WORDS.indicator_ip, name:'ha_indicator_ip_ipv4', allowBlank:false, vtype:'IPv4',listeners:{
                                    render: function(_name){
                                        Ext.DomHelper.insertHtml('afterEnd', _name.el.dom, getIconText(WORDS.desc_indicator_ip));
                                    }
                                }},
                            {
                                layout:'column',
                                bodyStyle:'margin:0px;padding:0px',
                                width:700,
                                items:[
                                    {
                                        xtype:'fieldset',
                                        title:'IPv4',
                                        layout:'form',
                                        autoHeight:true,
                                        columnWidth:.5,
                                        style:'margin-right:30px;padding:10px',
                                        items:[
                                            { xtype:'textfield', fieldLabel:WORDS.virtual_ip, name:'ha_virtual_ip_ipv4', vtype:'IPv4', allowBlank:false, blankText:WORDS.blanktext},
                                            { xtype:'textfield', fieldLabel:WORDS.primary_ip, name:'ha_primary_ip_ipv4', vtype:'IPv4',readOnly:true, cls:'fakeLabel',style:'border:0px', id:'primary_ipv4'},
                                            { xtype:'textfield', fieldLabel:WORDS.secondary_ip, name:'ha_standby_ip_ipv4', vtype:'IPv4', allowBlank:false, blankText:WORDS.blanktext}
                                        ]   
                                    },{
                                        xtype:'fieldset',
                                        title:'IPv6',
                                        layout:'form',
                                        autoHeight:true,
                                        columnWidth:.5,
                                        style:'padding:10px',
                                        items:[
                                            { xtype:'textfield', fieldLabel:WORDS.virtual_ip, name:'ha_virtual_ip_ipv6', vtype:'IPv6'},
                                            { xtype:'textfield', fieldLabel:WORDS.primary_ip, name:'ha_primary_ip_ipv6', vtype:'IPv6',readOnly:true, cls:'fakeLabel',style:'border:0px', id:'primary_ipv6'},
                                            { xtype:'textfield', fieldLabel:WORDS.secondary_ip, name:'ha_standby_ip_ipv6', vtype:'IPv6'}
                                        ]
                                    }
                                ]
                            }
                        ]
                    },{
                        layout:'form',
                        title:WORDS.hearbeat,
                        autoHeight:true,
                        name:'hb',
                        frame:true,
                        items:[
                            {
                                xtype:'combo',
                                fieldLabel:WORDS.interface,
                                valueField:'id',
                                displayField:'name',
                                triggerAction:'all',
                                mode:'local',
                                listWidth:200,
                                typeAhead:true,
                                name:'ha_heartbeat',
                                hiddenName:'ha_heartbeat',
                                selectOnFocus:true,
                                editable: false,
                                allowBlank: false,
                                store: new Ext.data.JsonStore({
                                    fields:['id','name'],
                                    data:TCode.HA.Data.hb_Iface
                                })
                            },
                            { xtype:'textfield', fieldLabel:'IPv4 '+WORDS.primary_ip, name:'ha_primary_ip3', vtype:'IPv4', allowBlank:false, blankText:WORDS.blanktext},
                            { xtype:'textfield', fieldLabel:'IPv4 '+WORDS.secondary_ip, name:'ha_standy_ip3', vtype:'IPv4', allowBlank:false, blankText:WORDS.blanktext}
                        ]
                    }
                ]
            }
        ]
    });
    
    /**
     * Secondary text field
     * @private
     */
    var secondaryFormPanel = new Ext.Panel({
        bodyStyle:'padding:0px',
        layout:'form',
        items:[
            {
                xtype:'textfield',
                fieldLabel:WORDS.detect_acip,
                vtype:'IPv4',
                name:'detect_ip'
            }
        ]
    });
    
    var config = {
        id:'tabSetting',
        title:WORDS.setting,
        frame:true,
        autoHeight:true,
        labelWidth:160,
        buttonAlign:'left',
        url:'getmain.php?fun=setha',
        buttons:[
            {text:WORDS.advance_options+'...', handler:onAdvanceClick},
            {text:'Apply',scope:this, handler:onApply}
        ],
        items:[
            {
                fieldLabel:WORDS.ha,
                xtype:'radiogroup',
                id:'ha_enable',
                width:350,
                items:[
                    { boxLabel:WORDS.enable,     name:'ha_enable', inputValue:1},
                    { boxLabel:WORDS.disable,    name:'ha_enable', inputValue:0}
                ],
                listeners:{
                    change: onChangeEnable
                }
            },{
                fieldLabel:WORDS.role,
                xtype:'radiogroup',
                width:350,
                items:[
                    { boxLabel:WORDS.active,    name:'ha_role',    inputValue:0},
                    { boxLabel:WORDS.standby,    name:'ha_role',   inputValue:1}
                ],
                listeners:{
                    change: onChangeRole
                }
            },
            primaryFormPanel,
            secondaryFormPanel
        ],
        listeners:{
            show:onShow
        }
    }
    
    function primarySubmit(){
        
        var v = this.getForm().getValues();
        
        //hearbeat
        var formItems = this.items.get(2).items.get(3).items.get(1).items;
        for(var i=0; i<formItems.getCount();i++){
            eval('v.'+ formItems.get(i).name +'="'+ formItems.get(i).getValue()+'"');
        }
        
        //advance value
        Ext.applyIf(v,advanceForm.getForm().getValues());
        
        //general value
        var f = this.getForm();
        var iface = f.findField('ha_virtual_ip_iface').getValue();
        var bond_eth = '';
        if(iface.indexOf(",")>=0){
            var bondAry = iface.split(",");
            iface = bondAry[0];
            bond_eth = ','+bondAry[1];
            v.ha_virtual_ip_iface = iface;
        }
        Ext.applyIf(v, {
            'ha_virtual_ip': iface +","+f.findField('ha_virtual_ip_ipv4').getValue()+","+f.findField('ha_virtual_ip_ipv6').getValue()+bond_eth,
            'ha_primary_ip1': iface +","+f.findField('ha_primary_ip_ipv4').getValue()+","+f.findField('ha_primary_ip_ipv6').getValue()+bond_eth,
            'ha_standy_ip1': iface +","+f.findField('ha_standby_ip_ipv4').getValue()+","+f.findField('ha_standby_ip_ipv6').getValue()+bond_eth,
            'ha_indicator_ip': iface +","+f.findField('ha_indicator_ip_ipv4').getValue()+","+bond_eth/*+f.findField('ha_indicator_ip_ipv6'),*/
        });
        
        ajax.setPrimary(v);
    }
    
    
    function onApply(){
        var ha = this.items.get(0).getValue();
        var role = this.items.get(1).getValue();
        
        if(TCode.HA.Data.HA_ERROR == true){
            return false;
        }
        //disable ha
        if(ha == '0'){
            if(TCode.HA.Data.current_role_value  == '0' ){
                ajax.isHaRaidDamaged();
            }else{
                Ext.MessageBox.show({
                    title: WORDS.ha,
                    msg: WORDS.confirm_reboot,
                    width:400,
                    closable: false,
                    icon:Ext.MessageBox.QUESTION,
                    buttons:Ext.Msg.YESNO,
                    fn:function(btn) {
                        if( btn == 'yes' ) {
                            ajax.setDisable('0');
                        }
                    }
                });
            }
        }else{
        //enable ha
            //primary role
            if(role == '0'){
                //validate
                this.getForm().findField('detect_ip').setDisabled(true);
                if(this.getForm().isValid() === false){
                    return false;
                }
                if(checkExistsHARaid.apply(this, [role]) === false){
                primarySubmit.apply(this, arguments);
                }
            }else{
            //secondary role
                var detect = this.getForm().findField('detect_ip');
                if(detect.getValue() == '' || detect.isValid() === false){
                    return false;
                }
                if(checkExistsHARaid.apply(this, [role]) === false){
                ajax.setSecondary(this.getForm().findField("detect_ip").getValue());
                }
            }
        }
    }
    
    
    function checkExistsHARaid(role){
        //check current RAID isn't HA RAID
        if(TCode.HA.Data.exists_ha_raid == '1'){
            Ext.MessageBox.show({
                title: WORDS.ha,
                msg: WORDS.harecovery,
                width:400,
                closable:false,
                icon:Ext.MessageBox.QUESTION,
                buttons:{yes:WORDS.btn_harecovery, no:WORDS.btn_continue},
                fn:function(result){
                    if(result == 'yes'){
                        //go to recovery ha
                        processUpdater('getmain.php','fun=raid&recover_show=1');
                        return false;
                    }else{
                        if(role=='0'){
                            primarySubmit.apply(self, arguments);
                        }else{
                            ajax.setSecondary(self.getForm().findField("detect_ip").getValue());
                        }
                    }
                }
            });
            return true;
        }else{
            return false;
        }
    }
    
    // open advance window
    function onAdvanceClick(){
        advanceWindow.show();
    }
    
    function onShow(){
        //disable
        if(TCode.HA.Data.ha_enable == '0'){
            onChangeEnable.apply(this,[null, '0']);
        }
        setButtonDisplay(TCode.HA.Data.current_role);
    }
    
    function setButtonDisplay(isEnable){
        if(isEnable !=''){
            self.buttons[1].setDisabled(true);
        }else{
            self.buttons[1].setDisabled(false);
        }
    }
    
    // change enable radio button
    function onChangeEnable(radio, value){
        //disable ha
        if(value == 0){
            self.items.get(1).hideItem();
            self.buttons[0].setVisible(false);
            self.buttons[1].setText('Apply');
            primaryFormPanel.setVisible(false);
            secondaryFormPanel.setVisible(false);
            self.buttons[1].setDisabled(false);
        }else{
        //enable ha
            self.items.get(1).showItem();
            self.items.get(1).setDisabled( TCode.HA.Data.ha_enable == '1' );
            self.items.get(1).setValue(TCode.HA.Data.ha_role);
            onChangeRole.apply(self,[{},TCode.HA.Data.ha_role]);
            setButtonDisplay(TCode.HA.Data.current_role);
        }
    }
    
    // change role radio button
    function onChangeRole(radio, value){
        //show primary
        if(value == 0){
            self.buttons[0].setVisible(true);
            self.buttons[1].setText('Apply');
            primaryFormPanel.setVisible(true);
            secondaryFormPanel.setVisible(false);
        
        //show secondary
        }else{
            if(self.getForm().findField('detect_ip')){
                self.getForm().findField('detect_ip').setDisabled(false);
            }
            self.buttons[0].setVisible(false);
            self.buttons[1].setText('Detect');
            primaryFormPanel.setVisible(false);
            if(TCode.HA.Data.current_role ==''){
                secondaryFormPanel.setVisible(true);
            }
        }
    }
    TCode.HA.Setting.superclass.constructor.call(this, config);
}


Ext.extend(TCode.HA.Setting, Ext.form.FormPanel, {
    setInit: function(data){
        var self = this;
        
        //advance options
        advanceForm.getForm().findField("ha_keepalive").setValue(data.ha_keepalive);
        advanceForm.getForm().findField("ha_deadtime").setValue(data.ha_deadtime);
        advanceForm.getForm().findField("ha_warntime").setValue(data.ha_warntime);
        advanceForm.getForm().findField("ha_initdead").setValue(data.ha_initdead);
        advanceForm.getForm().findField("ha_udpport").setValue(data.ha_udpport);
        
        this.items.get(0).setValue(data.ha_enable);
        this.items.get(1).setDisabled( data.ha_enable == '1' );
        this.items.get(1).setValue(data.ha_role);
        this.items.get(1).fireEvent('change',this.items.get(1),data.ha_role);
//        this.items.get(0).fireEvent('change',this.items.get(0),data.HA);
        
        //panel
        with(this.items.get(2).items){
            get(0).setValue(data.ha_auto_failback);
            get(1).setValue(data.ha_virtual_name);
            get(2).setValue(data.ha_standy_name);
            
            // tabpanel virtual
            with(get(3).items.get(0).items){
                get(0).setValue(data.ha_virtual_ip_iface);
                get(1).setValue(data.ha_indicator_ip_ipv4);
                
                //ipv4
                with(get(2).items.get(0).items){
                    get(0).setValue(data.ha_virtual_ip_ipv4);
                    get(1).setValue(data.ha_primary_ip_ipv4);
                    get(2).setValue(data.ha_standby_ip_ipv4);
                }
                
                //ipv6
                with(get(2).items.get(1).items){
                    get(0).setValue(data.ha_virtual_ip_ipv6);
                    get(1).setValue(data.ha_primary_ip_ipv6);
                    get(2).setValue(data.ha_standby_ip_ipv6);
                }
            }
        
            //tabpanel heartbeat
            with(get(3).items.get(1).items){
                get(0).setValue(data.ha_heartbeat);
                get(1).setValue(data.ha_primary_ip3);
                get(2).setValue(data.ha_standy_ip3);
            }
        }
    }
});

TCode.HA.DataProxy = function(config) {
    var self = this;
    var data = '';
    self.loadResponse = function(o, success, response){
        delete self.activeRequest;
        if(!success){
            self.fireEvent("loadexception", this, o, response);
            o.request.callback.call(o.request.scope, null, o.request.arg, false);
            return;
        }
        if( data == response.responseText ) {
            return;
        }
        data = response.responseText;
        var result;
        try {
            result = o.reader.read(response);
        }catch(e){
            self.fireEvent("loadexception", this, o, response, e);
            o.request.callback.call(o.request.scope, null, o.request.arg, false);
            return;
        }
        self.fireEvent("load", this, o, o.request.arg);
        o.request.callback.call(o.request.scope, result, o.request.arg, true);
    }
    self.addEvents(['nochange']);
    TCode.HA.DataProxy.superclass.constructor.call(self, config);
}
Ext.extend(TCode.HA.DataProxy, Ext.data.HttpProxy);


TCode.HA.Status = function(){
    var self = this;

    var logStore = new Ext.data.JsonStore({
        root: 'logs',
        totalProperty: 'totalCount',
        remoteSort: true,
        fields: ['priority','datetime','desc'],
        proxy: new Ext.data.HttpProxy({
            url: '/adm/getmain.php?fun=ha&ac=getLog'
        })
    });
 
    raidgridStore = new Ext.data.GroupingStore({
        reader: new Ext.data.JsonReader({
            fields: ["raidid", "type","md","recovery", "finish","speed", "capacity", "status"]
        }),
        sortInfo:{field: 'type', direction: "ASC"},
        groupField:'raidid',
        proxy: new TCode.HA.DataProxy({
            url: '/adm/getmain.php?fun=ha&ac=getRaidStatus'
        })
    });
    
    var loggrid ={
        id:'HALogGridPanel',
        xtype:'grid',
        store: logStore,
        title:WORDS.log,
        frame:true,
        width:650,
        height:250,  
        trackMouseOver:true,
        disableSelection:true,
        columns: [
            {header: WORDS.grade, dataIndex: 'priority', width:50},
            {header: WORDS.time,  dataIndex: 'datetime', width:150},
            {header: WORDS.detail, dataIndex: 'desc',width:450}
        ],
        viewConfig: {
            forceFit: true,
            getRowClass: getLogRowClass
        },
        tbar:[{
                text:WORDS.choose_grade,
                iconCls: 'list',
                menu:[
                    { id:'all',text:WORDS.all,        tooltip:WORDS.tip_all, iconCls:'add',       handler:onPriorityClick}, '-',
                    { id:'info',text:WORDS.info,  tooltip:WORDS.tip_info,iconCls:'info',      handler:onPriorityClick}, '-',
                    { id:'warn',text:WORDS.warn,  tooltip:WORDS.tip_warn,iconCls:'warning',   handler:onPriorityClick}, '-',
                    { id:'error',text:WORDS.error, tooltip:WORDS.tip_error,iconCls:'error',    handler:onPriorityClick}
                ]
             },'-',{
                id:'truncate',
                text:WORDS.truncate_all,
                iconCls:'remove',
                handler:onTruncateLogClick
             },'-',"<{$lwords.number_of_lines_per_page}>",{
                xtype:'textfield',
                value:'10',
                width:40,
                vtype:'NaturalNumbers',
                enableKeyEvents:true,
                listeners:{
                    specialkey:onSpecialKeyup
                }
        }],
        bbar:  new Ext.PagingToolbar({
            pageSize: TCode.HA.Data.g_pageLimit,
            store: logStore,
            displayInfo: true,
            displayMsg: WORDS.page_range+" {0} - {1} "+WORDS.page2+" {2}",
            emptyMsg: WORDS.empty_log,
            beforePageText:WORDS.page1,
            afterPageText:WORDS.page2+" {0} "+WORDS.page3,
            onClick:onPageKeyup
        })
    };
    
    var raidgrid = {
        xtype:'grid',
        store:raidgridStore,
        autoHeight: true,
        frame:true,
        collapsible: false,
        animCollapse: false,
        autoScroll:true,
        width:650,
        title:WORDS.raid_status,
        id:'RAIDStatusGridPanel',
        columns: [
            {header: WORDS.raid_status_raid,  dataIndex: 'raidid'},
            {header: WORDS.raid_status_type, dataIndex: 'type'},
            {header: WORDS.device,  renderer: function(v,cellmata,record){
                if( v[0] == null || v[1] == null ) {
                    return;
                }
                var raidid= record.data["raidid"];
                var type = record.data["type"];
                var amsg = WORDS.active+"("+raidid+"-"+type+")";
                var bmsg = WORDS.standby+"("+raidid+"-"+type+")";
                return "<img src='/theme/images/icons/md"+v[0]+".png' alt='"+amsg+"' title='"+amsg+"' />&nbsp;&nbsp;<img src='/theme/images/icons/md"+v[1]+".png' alt='"+bmsg+"' title='"+bmsg+"'  />";
            }},
            {header: WORDS.raid_status_recovery, dataIndex: 'recovery'},
            {header: WORDS.raid_status_finish,  dataIndex: 'finish'},
            {header: WORDS.raid_status_speed,  dataIndex: 'speed'},
            {header: WORDS.raid_status_capacity,  dataIndex: 'capacity'},
            {header: WORDS.raid_status_state,  dataIndex: 'status'}
        ],	
        view: new Ext.grid.GroupingView({
            forceFit:true,
            groupTextTpl: '{text}'
        })
    };
    
    var config = {
        id:'tabStatus',
        title:WORDS.status,
        frame:true,
        autoHeight:true,
        items:[{
                style:'padding-bottom:20px;',
                items:[{
                        xtype:'label',
                        style:'font-weight:bolder',
                        html:"<b>"+WORDS.current_role+":</b>&nbsp;&nbsp;&nbsp;<span id='roletxt' ></span>"
                }]
            },{
                items:[{
                        xtype:'label',
                        style:'font-weight:bolder',
                        text:WORDS.network_status+":"
                }]
            },
            { style:'padding-bottom:20px;', contentEl:'ha_network' },
            { style:'padding-bottom:20px;', items:[raidgrid]},
            { items:[loggrid]}
        ],
        listeners:{
            render:onRender,
            show:onShow
        }
    }
    
    function onShow(){
        Ext.getDom('roletxt').innerHTML = TCode.HA.Data.HA_CUR_ROLE_Name[TCode.HA.Data.current_role_value];
    }
    
    function onRender(){
        if( TCode.HA.Data.current_role_value === '1' ){
            self.items.get(3).hide();
        }
        raidgridStore.load();
        logStore.setDefaultSort('datetime', 'desc');
        logStore.load({params:{start:0, limit:TCode.HA.Data.g_pageLimit, init:1}});
//        runner.start(task);
    }
    

    function onPriorityClick(value){
        logStore.load({params:{start:0, limit:TCode.HA.Data.g_pageLimit, priority:value.id, init:1}});
        loggrid.bbar.paramNames={start:'start', limit:'limit', priority:value.id};
        TCode.HA.Data.g_priority = value.id;
    }
    
    function onTruncateLogClick(value){
         Ext.Msg.confirm(WORDS.ha,WORDS.confirm_remove,function(btn){
            if(btn=='yes'){
                ajax.setTruncateLog();
            }
        });
    }
    
    function onPageKeyup(which){
        if(which == 'refresh'){
            logStore.load({params:{start:0, limit:TCode.HA.Data.g_pageLimit, init:1, priority:TCode.HA.Data.g_priority}});
            return;
        }
        this.constructor.prototype.onClick.apply(this, arguments);
    }
    
    function onSpecialKeyup(obj){
        TCode.HA.Data.g_pageLimit = eval(Math.floor(obj.getValue()));
        if(isFinite(TCode.HA.Data.g_pageLimit) && TCode.HA.Data.g_pageLimit > 0){
            loggrid.bbar.pageSize = TCode.HA.Data.g_pageLimit;
            logStore.load({params:{start:0, limit:TCode.HA.Data.g_pageLimit, priority:TCode.HA.Data.g_priority, init:1}});
        }
    }

    function getLogRowClass(row, index){
        switch(row.data.priority){
            case 'warn':
                return 'ha_row_warn'; 
            case 'error':
                return 'ha_row_error'; 
            default:
                return '';
        }
    }       
    TCode.HA.Status.superclass.constructor.call(this, config);
}
Ext.extend(TCode.HA.Status, Ext.Panel);


TCode.HA.Container = function(){
    var self = this;
    var ha_setting =  new TCode.HA.Setting();
    var ha_status =  new TCode.HA.Status();
    
    var config = {
        renderTo:'HA',
        border:false,
        deferredRender:false,
        plain:true,
        style: 'margin: 10px;',
        defaults:{autoScroll:true},
        activeTab:TCode.HA.Data.ha_tab,
        width:'auto',
        items:[
            ha_status,
            ha_setting
        ],
        listeners:{
            render:onRender,
            beforedestroy: onDestroy,
            tabchange:onTabchange
        }
    };
    
    function onRender(){
        Ext.get('content').getUpdateManager().on('beforeupdate', self.destroy, self);
        ha_setting.setInit(TCode.HA.Data);
        
        Ext.getDom('active_name').innerHTML = TCode.HA.Data.HA_ROLE_Name[0];
        Ext.getDom('standby_name').innerHTML = TCode.HA.Data.HA_ROLE_Name[1];
        
        //enable
        if(TCode.HA.Data.ha_enable == '1'){
            ha_status.setDisabled(false);
        }else{
            ha_status.setDisabled(true);
        }
        
    }
    
    function onTabchange(main, tab){
        if(tab.id == 'tabStatus'){
            runner.start(task);
        }else{
            runner.stop(task);
        }
    }
    
    function onDestroy(){
        runner.stopAll();
        Ext.get('content').getUpdateManager().un('beforeupdate', self.destroy, self);
        delete TCode.HA;
    };
    
    TCode.HA.Container.superclass.constructor.call(this, config);
}
Ext.extend(TCode.HA.Container, Ext.TabPanel);


Ext.onReady(function(){
    Ext.apply(Ext.Msg, {
        minWidth: 300,
        maxWidth: 600
    });
    if( HV == 1 ) {
        return Ext.Msg.alert(
            WORDS.attention,
            WORDS.exclusive,
            function() {
                processUpdater('getmain.php','fun=hv');
            }
        );
    }
    var fail = '';
    if( TCode.HA.Data.Iface.length < 2 ) {
        fail += WORDS.nic_not_enpugh + '<br><br>';
    }
    if( TCode.HA.Data.hearetbeatable == false ) {
        fail += WORDS.none_heartbeatable + '<br><br>';
    }
    if( fail != '' ) {
        return Ext.Msg.alert(
            WORDS.attention,
            fail,
            function() {
                processUpdater('getmain.php','fun=wan');
            }
        );
    }

    Ext.QuickTips.init();
    
    Ext.getDom("hb_txt").innerHTML= WORDS.hearbeat;
    
    if(TCode.HA.Data.ha_role=='0'){
        Ext.getDom('active_name').style.fontWeight = "bold";
    }else{
        Ext.getDom('standby_name').style.fontWeight = "bold";
    }
    Ext.getDom('active_rebuild_text').innerHTML=WORDS.rebuild;
    Ext.getDom('standby_rebuild_text').innerHTML=WORDS.rebuild;
    Ext.getDom('active_img').qtip = String.format(
        TCode.HA.Data.tpl_table,
        WORDS.interface,
        TCode.HA.Data.ha_virtual_ip_iface_name,
        WORDS.ip,
        TCode.HA.Data.ha_primary_ip_ipv4,
        TCode.HA.Data.ha_primary_ip_ipv6
    );
    
    Ext.getDom('standby_img').qtip = String.format(
        TCode.HA.Data.tpl_table,
        WORDS.interface,
        TCode.HA.Data.ha_virtual_ip_iface_name,
        WORDS.ip,
        TCode.HA.Data.ha_standby_ip_ipv4,
        TCode.HA.Data.ha_standby_ip_ipv6
    );
    Ext.getDom('hearbeat_img').qtip =  Ext.getDom('hb_txt').qtip = String.format(
        TCode.HA.Data.tpl_hb_table,
        WORDS.interface,
        TCode.HA.Data.ha_heartbeat_txt,
        WORDS.tip_p_hb,
        TCode.HA.Data.ha_primary_ip3,
        WORDS.tip_s_hb,
        TCode.HA.Data.ha_standy_ip3
    );

    new TCode.HA.Container();
});
</script>
