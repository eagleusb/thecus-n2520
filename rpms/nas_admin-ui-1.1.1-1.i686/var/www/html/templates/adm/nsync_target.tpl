<script type="text/javascript"> 
function handle_apply(){   
   processAjax('<{$set_url}>',onLoadForm,formpanel.getForm().getValues(true));   
}  
//Ext.onReady(function(){
	var rsync_share_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        fieldLabel: 'Rsync Target Server ',
        width:180,
        //id:'rsync_share',
        items: [{boxLabel: '<{$gwords.enable}>', name: '_rsync_enable',inputValue:'1' <{if $nsync_target_rsync_enable=='1'}> ,checked:true <{/if}>},
                {boxLabel: '<{$gwords.disable}>', name: '_rsync_enable',inputValue:'0' <{if $nsync_target_rsync_enable=='0'}> ,checked:true <{/if}>}
               ]
	}); 
 
    var formpanel = new Ext.FormPanel({ 
        id:'formpanel',  
        renderTo:'div_samba',
        items: [{
            xtype:'fieldset', 
            title: '<{$words.nsync_target_title}>',
            autoHeight:true,
            autoWidth:true,
            //defaultType: 'textfield',
            collapsed: false,
            labelWidth:150,
            //defaults:{width:150},
            items :[{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$words.nsync_target_server}>',
                      width:180,
                      id:'rdo_share',
                      items: [{boxLabel: '<{$gwords.enable}>', name: '_enable',inputValue:'1' <{if $nsync_target_enable=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.disable}>', name: '_enable',inputValue:'0' <{if $nsync_target_enable=='0' }> ,checked:true <{/if}>}]
                  }]
          }],
                  buttons:[{ text: '<{$gwords.apply}>',handler:handle_apply}],
                  buttonAlign:'left'
    });

//});

</script>  
<div id="div_samba"></div> 

