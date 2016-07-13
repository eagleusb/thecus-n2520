<div id="nfsform"></div>

<script language="javascript">

Ext.onReady(function(){

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'nfs'});

    var nfs_radiogroup = new Ext.form.RadioGroup({
                xtype: 'radiogroup',
                columns: 2,
                fieldLabel: '<{$gwords.nfs}>',
                //listeners: {change:{fn:function(){alert('radio changed');}}},
                items: [
                    {boxLabel: '<{$gwords.enable}>', name: '_nfsd', inputValue: 1 <{if $nfs_enabled =="1"}>, checked:true <{/if}>},
                    {boxLabel: '<{$gwords.disable}>', name: '_nfsd', inputValue: 0 <{if $nfs_enabled =="0" || $nfs_enabled ==""}>, checked:true <{/if}>}
                ]
    });

    var fp = new Ext.FormPanel({
        frame: false,
        labelWidth: 110,
        //width: 600,
        autoWidth: 'true',
        renderTo:'nfsform',
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
             * DHCP Server
             *====================================================================*/
            
            xtype:'fieldset',
            title: '<{$words.nfs_title}>',
            autoHeight: true,
            buttonAlign: 'left',
            items: nfs_radiogroup,
       	    buttons: [{
                text: '<{$gwords.apply}>',
                handler: function(){
	            if(fp.getForm().isValid()){
            	        Ext.Msg.confirm('<{$gwords.nfs}>',"<{$gwords.confirm}>",function(btn){
                            if(btn=='yes'){
                                processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                        }})
		        //Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+ 
		        //              fp.getForm().getValues(true).replace(/&/g,', '));
                    }
                }
            }]
        },{
            /*====================================================================
            * Description
            *====================================================================*/
            xtype:'fieldset',
            title: '<{$gwords.description}>',
            autoHeight: true,
            items: [{
                html:'<{$words.nfs_help}></br>NFS3: mount –t nfs 192.168.2.254:/<{$masterRaid}>/data/_NAS_NFS_Exports_/SAMPLE　/mnt/sample</br>NFS4: mount –t nfs4 192.168.2.254:/SAMPLE　/mnt/sample'
            }]
        }]
    });
    
});


</script>
