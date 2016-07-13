<fieldset class="x-fieldset" style="margin: 10px;">
    <legend class="legend"><{$words.sdrb_title}></legend>
    <center>
        <div id="firmware_title"><{$words.sdrb_description}></div>
        <form name="rebootform" id="rebootform">
            <input type=hidden name="action" id="action" value="notset">
        </form> 
        <div id="mainDiv1" style="display:none;padding: 10px 20px;"></div>
        <div id="mainDiv2" style="display:none;padding: 10px 20px;"><{$gwords.running}><div>
    </center>
</fieldset>

<script type="text/javascript">

function ExtDestroy(){
    Ext.destroy(
        Ext.getCmp('reboot_win')
    );
}
var type = "";
Ext.onReady(function(){
    function does(action){
        type = action;
        document.getElementById('action').value = type;
        var sure = '';
        var sureha = '';
        if(action == 'shutdown'){
            sure = "<{$words.shutdown_prompt}>";
        }
        else{
            sure = "<{$words.reboot_prompt}>";
        }

        <{if $ha_role_current == '1'}>
            sureha = "<br> <{$words.ha_standby_checkreboot}>";
        <{/if}>
       
       //enable .... ha role is check in db
       <{if $startup == '5' ||  $startup == '22' }> 
            if(Ext.getCmp('standby_reboot')){
                Ext.getCmp('standby_reboot').setDisabled(true);
            }
            <{if $ha_role == '0' && $ha_enable == '1' && $together=='1' || $ha_role_current =='0' && $raid_damaged=='0' }>
                HASyncReboot();
                return;
            <{/if}>
            <{if $ha_role == '0' && $ha_enable == '1'}>
                reboot_win.show();
                Ext.getCmp('reboot_info').el.dom.innerHTML ="<BR>"+sure+"<BR><BR>";
            <{else}>
                Ext.Msg.confirm(action, sure+sureha, function(btn){
                    if (btn == 'yes'){
                        processAjax('setmain.php?fun=setreboot',onLoadForm,rebootform);
                    }
                });
            <{/if}>
       // ha role is check /tmp/ha_role
       <{else}>
            if(action == "reboot" && "<{$fw_upgraded}>" == '1' && "<{$ha_role_current}>" == "1"){
                Ext.Msg.alert("<{$words.sdrb_title}>","<{$words.wait_activereboot}>");
            }else if("<{$ha_role_current}>" == '0'){
                reboot_win.show();
                Ext.getCmp('reboot_info').el.dom.innerHTML ="<BR>"+sure+"<BR><BR>";
            }else{
                Ext.Msg.confirm(action, sure+sureha, function(btn){
                    if (btn == 'yes'){
                        processAjax('setmain.php?fun=setreboot',onLoadForm,rebootform);
                    }
                });
            }
       <{/if}>
       
    }
    var reboot_win = new Ext.Window(
        {
            id:"reboot_win",
            title:"<{$words.sdrb_title}>",
            buttonAlign:"center",
            layout:"border",
            border:false,
            resizable:false,
            modal:true,
            closable:false,
            width:400,
            height:180,
            bodyStyle:"padding:200px;background-color:#c3d2e6",
            defaults:{
                bodyStyle:"background-color:#c3d2e6"
            },
            items:[
                {
                    region:"west",
                    style:"padding:0 10 0 0",
                    html:'<img src="/theme/images/default/window/icon-question.gif" />'
                },
                {
                    region:"center",
                    items:[
                        {
                            xtype:"label",
                            id:"reboot_info"
                        }
                        <{if $ha_role == '0' && $ha_enable == '1' && $together=='1' || $ha_role_current =='0' && $raid_damaged=='0' }>,
                        {
                            xtype:"checkbox",
                            checked:true,
                            id:"standby_reboot",
                            boxLabel:"<span style='font-weight:bolder'><{$words.action_together}></span>"
                        }
                        <{/if}>
                    ]
                }
            ],
            listeners:{
                beforerender: function(obj){
                    if(!Ext.isIE){
                        obj.bodyStyle="padding:10px;background-color:#c3d2e6";
                    }
                }
            },
            buttons:[
                {
                    text:"Yes",
                    handler: function() {
                        reboot_win.hide();
                        if(Ext.getCmp('standby_reboot') && Ext.getCmp('standby_reboot').checked) {
                            HASyncReboot();
                        } else {
                            processAjax('setmain.php?fun=setreboot',onLoadForm,rebootform);
                        }
                    }
                },
                {
                    text:"No",
                    handler: function() {
                        reboot_win.hide();
                    }
                }
            ]
        }
    );
    
    var rebootpanel1 = new Ext.FormPanel(
        {
            id:'reboot-panel1',
            renderTo: 'mainDiv1',
            buttonAlign: 'left',
            items: [{}],
            buttons : [{
                    text : '<{$gwords.shutdown}>',
                    disabled : false,
                    handler : function() {
                        does('shutdown');
                    }
                },{
                    text : '<{$gwords.reboot}>',
                    disabled : false,
                    handler : function() {
                        does('reboot');
                    }
                }]
        }
    );
    
    function HASyncReboot() {
        processAjax('setmain.php?fun=setreboot',function(){
            if(this.req.responseText=='0'){
                booting_win.show();
                Ext.getCmp('boottext').el.dom.innerHTML = "<{$gwords.wait_sys}>";
                processAjax('getmain.php?fun=nasstatus',onloadSysConfig);
            }else{
                onLoadForm.apply(this, arguments);
            }
        },"action=ha_reboot&type="+type);
    }

    <{if $lock == '1'}>
        Ext.get("mainDiv1").enableDisplayMode('none');
        Ext.get("mainDiv1").hide();
        Ext.get("mainDiv2").enableDisplayMode('inline');
        Ext.get("mainDiv2").show();
    <{else}>
        Ext.get("mainDiv1").enableDisplayMode('inline');
        Ext.get("mainDiv1").show();
        Ext.get("mainDiv2").enableDisplayMode('none');
        Ext.get("mainDiv2").hide();
    <{/if}>
    
    <{if $index_ac!=""}>
        <{if $index_ac=="shutdown" }>
            does('shutdown');
        <{else}>
            does('reboot');
        <{/if}>
    <{/if}>

});
</script>
