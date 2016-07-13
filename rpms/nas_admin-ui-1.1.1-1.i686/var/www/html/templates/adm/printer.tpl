<div id="printerform"></div>

<script language="javascript">

GWORDS = <{$gwords}>;
WORDS = <{$words}>;
PRINTER_INFO = <{$printer_info}>;


function UpdateData(){
    var request = eval("("+replaceStr(this.req.responseText)+")");  
    Ext.getCmp('_manufact').getEl().dom.innerHTML= WORDS[request.manufact] || request.manufact;
    Ext.getCmp('_model').getEl().dom.innerHTML= WORDS[request.model] || request.model;
    Ext.getCmp('_status').getEl().dom.innerHTML= WORDS[request.status] || request.status;
    
    if (request.btnDisabled){
        removeBtn.disable(); 
        restartBtn.disable(); 
    }else{
        removeBtn.enable(); 
        restartBtn.enable(); 
    }
    
    if(TCode.desktop.Group.page=='printer'){   
        systatus_refresh = setTimeout("processAjax('getmain.php?fun=printer&update=1', UpdateData)",5000);
    }else{
        clearTimeout(systatus_refresh);
    }
}

var removeBtn = new Ext.Button({
    id:'_removeBtn',
    name:'_removeBtn',
    disabled: '<{$btnDisabled}>',
    text: GWORDS.remove,
    handler: function(){
        Ext.Msg.confirm(GWORDS.remove, GWORDS.confirm, function(btn){
                if(btn=='yes'){
                processAjax('<{$form_action."&act=remove"}>',onLoadForm);
            }
        })              
    }
})

var restartBtn = new Ext.Button({
    id:'_restartBtn',
    name:'_restartBtn',
    disabled: '<{$btnDisabled}>',
    text: GWORDS.restart,
    handler: function(){
        Ext.Msg.confirm(WORDS.restart_title, GWORDS.confirm, function(btn){
            if(btn=='yes'){
                processAjax('<{$form_action."&act=restart"}>',onLoadForm);
            }
        })              
    }
})

var tp = new Ext.TabPanel({
    activeTab: '0',
    id:'_printerlist',
    width:550,
    height:210,
    plain: true,
    deferredRender:false,
    items:[{
        title: WORDS.printer+" 1",
        id:'_printer1',
        cls:'panelbg',
        items:[{
            layout: 'column',
            autoHeight:true,
            defaults:{
                layout:'form',
                border:false,
                xtype:'panel',
                bodyStyle:'margin:10px 0;'
            },
            items:[{
                columnWidth:0.5,
                defaults: {height:25},
                items:[{
                    xtype: 'box',
                    autoEl: {cn: GWORDS.producer+":"}
                },{
                    xtype: 'box',
                    autoEl: {cn: GWORDS.model+":"}
                },{
                    xtype: 'box',
                    autoEl: {cn: GWORDS.status+":"}
                },{
                    xtype: 'box',
                    autoEl: {cn: WORDS.printer_queue+":"}
                },{
                    xtype: 'box',
                    autoEl: {cn: ''}
                },{
                    xtype: 'box',
                    autoEl: {cn: WORDS.service+":"}
                }]
            },{
                columnWidth:0.5,
                defaults: {height:25},
                items:[{
                    xtype: 'box',
                    name:'_manufact',
                    id:'_manufact',
                    autoEl: {cn: WORDS[PRINTER_INFO.manufact] || PRINTER_INFO.manufact}
                },{
                    xtype: 'box',
                    name:'_model',
                    id:'_model',
                    autoEl: {cn: WORDS[PRINTER_INFO.model] || PRINTER_INFO.model}
                },{
                    xtype: 'box',
                    name:'_status',
                    id:'_status',
                    autoEl: {cn: WORDS[PRINTER_INFO.status] || PRINTER_INFO.status}
                },
                removeBtn,
                {
                    xtype: 'box',
                    autoEl: {cn: ''}
                },
                restartBtn         
                ]
            }]
        }]
    }]
});

Ext.onReady(function(){
    Ext.QuickTips.init();
    Ext.form.Field.prototype.msgTarget = 'side';
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'adminpwd'});
    
    var fs = new Ext.form.FieldSet({
        renderTo:'printerform',
        title: WORDS.printer_Info,
        autoHeight: true,
        style: 'margin: 10px;',
        items: tp
    });

    if(TCode.desktop.Group.page === 'printer'){   
        systatus_refresh = setTimeout("processAjax('getmain.php?fun=printer&update=1', UpdateData)",5000);
    }else{
        clearTimeout(systatus_refresh);
    }
});

</script>
