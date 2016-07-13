<div id="upnpform"></div>

<script language="javascript">

Ext.onReady(function(){

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'upnp'});

    var upnp_radiogroup = new Ext.form.RadioGroup({
                xtype: 'radiogroup'
                ,columns: 2
                ,fieldLabel: '<{$words.upnp}>'
                //,listeners: {change:{fn:function(){alert('radio changed');}}}
                ,items: [
                    {boxLabel: '<{$gwords.enable}>', name: '_upnp', inputValue: 1 <{if $upnp_enabled =="1"}>, checked:true <{/if}>}
                    ,{boxLabel: '<{$gwords.disable}>', name: '_upnp', inputValue: 0 <{if $upnp_enabled =="0" || $upnp_enabled ==""}>, checked:true <{/if}>}
                ]
    });

    var fp = new Ext.FormPanel({
        frame: false
        ,labelWidth: 110
        //,width: 600
        ,autoWidth: 'true'
        ,renderTo:'upnpform'
        ,style: 'margin: 10px;'
        
        ,items: [
            { layout: 'column'
              ,border: false
              ,defaults: { columnWidth: '.5' ,border: false }
            }
            ,prefix
            ,{ /*====================================================================
                * upnp
                *====================================================================*/
                xtype:'fieldset'
                ,title: '<{$words.upnp_title}>'
                ,autoHeight: true
                ,layout: 'form'
                ,buttonAlign: 'left'
                ,items: [
                    upnp_radiogroup
            	    ,{
	    	        xtype: 'textarea'
	    	        ,width: '240'
	    	        ,id: '_desp'
	    	        ,name: '_desp'
	    	        ,maxLength:250 
	    	        ,fieldLabel: '<{$gwords.description}>'
	    	        ,value: '<{$upnp_desp}>'
	    	    }
	    	]//items.fieldset
	    	
                ,buttons: [{
                        text: '<{$gwords.apply}>'
                        ,handler: function(){
                            if(fp.getForm().isValid()){
                                Ext.Msg.confirm('<{$words.upnp}>',"<{$gwords.confirm}>",function(btn){
                                    if(btn=='yes'){
                                        upnp_flag=0;
                                        if (Ext.getDom("_desp").disabled){
                           	            upnp_flag=1;
                           	            Ext.getDom("_desp").disabled=false;
                                        }
                                        processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                                        if (upnp_flag ==1 )
                           	            Ext.getDom("_desp").disabled=true;
                                }})//Msg.confirm
	    		        //     Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+ 
            		        //                    fp.getForm().getValues(true).replace(/&/g,', '));
                            }//isValid
                        }//handler
                }]//buttons
        }]//items.FormPanel
    });
    
    if(<{$upnp_enabled}>=='0')
    	Ext.getDom("_desp").disabled=true;
    upnp_radiogroup.on('change',function(RadioGroup,newValue){
    	if (newValue == '1')
    		Ext.getDom("_desp").disabled=false;
    	else
    		Ext.getDom("_desp").disabled=true;
    });
});

</script>
