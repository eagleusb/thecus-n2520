<div id="hsdpaform"></div>
<script language="javascript">

Ext.onReady(function(){

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'hsdpa'});


    var fp = new Ext.FormPanel({
        frame: false,
        labelWidth: 110,
        //width: 600,
        autoWidth: 'true',
        renderTo:'hsdpaform',
        style: 'margin: 10px;',
        
        items: [{
            layout: 'column',
            border: false,
            defaults: {
                columnWidth: '.5',
                border: false
            }
            },prefix,{
            
            /*====================================================================
             * hsdpa
             *====================================================================*/
                                               
            xtype:'fieldset',
            title: '<{$words.hsdpa_title}>',
            autoHeight: true,
            layout: 'form',
            buttonAlign: 'left',
            items: [
           {
                xtype: 'textfield',
                name: '_dial',
                id: '_dial',
                fieldLabel: '<{$words.hsdpa_dial}>',
                value: '<{$hsdpa_dial}>'
            },{
                xtype: 'textfield',
                name: '_apn',
                id: '_apn',
                fieldLabel: '<{$words.hsdpa_apn}>',
                value: '<{$hsdpa_apn}>'
            }],
            buttons: [{
                text: '<{$gwords.apply}>',
                handler: function(){
                    if(fp.getForm().isValid()){
		        Ext.Msg.confirm('<{$words.hsdpa}>',"<{$gwords.confirm}>",function(btn){
				if(btn=='yes'){
					processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));

			}})
                    }
                }
            }]
        }]
    });
    



    
});


</script>
