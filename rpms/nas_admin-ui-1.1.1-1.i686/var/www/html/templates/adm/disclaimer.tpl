<{include file="adm/header.tpl"}>
<script type="text/javascript" src="<{$urlextjs}>adapter/ext/ext-base.js"></script>
<script type="text/javascript" src="<{$urlextjs}>ext-all.js"></script>
<script>

Ext.onReady(function(){
    var FormPanel_disclaimer = new Ext.FormPanel({
        frame: true,
        labelAlign:'left',
        labelWidth:180,
        buttonAlign:'left',
        height:270, 
        style:'height:300px',
        items:[{ 
            xtype: 'textarea',
            id:'disclaimer_msg',
            fieldLabel:"<{$gwords.disclaimer_title}>",
            readOnly:true,
            hideLabel:true,
            anchor: '100% 80%',
            value:"<{$disclaimer_content}>"
        },{ 
            xtype:'checkbox',
            name:'disclaimer_enabled',
            id:'disclaimer_enabled',
            value:'1',
            hideLabel:true,
            <{if $disclaimer_enabled=="1"}>
            checked:true,
            <{/if}>
            boxLabel:"<{$gwords.agree}>"
        },{
                    xtype:'button',
            id:'apply_btn',
            text:"<{$gwords.ok}>",
            hideLabel:true,
            minWidth:80,
            handler:function(){
                location.href='/adm/setmain.php?fun=setdisclaimer&disclaimer_enabled='+Ext.getCmp("disclaimer_enabled").getValue();
            }
        }]
    }); 
    var Window_disclaimer = new Ext.Window({
        closable:false,
        closeAction:'hide', 
        width: 500, 
        height:300,
        draggable:false,
        autoScroll:false,
        modal: true,
        resizable:false,
        title:"<{$gwords.disclaimer_title}>",
        items: FormPanel_disclaimer
    }).show();
})
</script>