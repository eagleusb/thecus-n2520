<script language="javascript">

Ext.reg('sliderfield', Ext.form.SliderField); 

Ext.onReady(function(){

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'ftp'});

    var ftp_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup'
        ,width:400
        ,fieldLabel: "<{$words.ftpd}>"
        //,listeners: {change:{fn:function(){alert('radio changed');}}}
        ,items: [
            {boxLabel: '<{$gwords.enable}>', name: '_ftp', inputValue: 1 <{if $ftp_enabled =="1"}>, checked:true <{/if}>}
            ,{boxLabel: '<{$gwords.disable}>', name: '_ftp', inputValue: 0 <{if $ftp_enabled =="0" || $ftp_enabled ==""}>, checked:true <{/if}>}
        ]
    });
    
    var ssl_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup'
        ,width:400
        ,fieldLabel: "<{$words.ftpd_ssl}>"
        //,listeners: {change:{fn:function(){alert('radio changed');}}}
        ,items: [
            {boxLabel: '<{$gwords.enable}>', name: '_ssl', inputValue: 2 <{if $ftp_ssl =="2"}>, checked:true <{/if}>}
            ,{boxLabel: '<{$gwords.disable}>', name: '_ssl', inputValue: 0 <{if $ftp_ssl =="0" || $ftp_ssl ==""}>, checked:true <{/if}>}
        ]
    });

    var encode_store = new Ext.data.SimpleStore({
	fields: <{$ftp_encode_fields}>
	,data: <{$ftp_encode_data}>
    });

    var encode_combo = new Ext.form.ComboBox({
        xtype: 'combo'
        ,name: '_encode'
        ,id: '_encode'
        ,hiddenName: '_encode_selected'
        ,fieldLabel: "<{$words.ftpd_encode}>"
        ,mode: 'local'
        ,store: encode_store
        ,displayField: 'display'
        ,valueField: 'value'
        ,readOnly: true
        ,typeAhead: true
        ,selectOnFocus:true
        ,triggerAction: 'all'
    });

    var anon_store = new Ext.data.SimpleStore({
	fields: <{$ftp_anon_fields}>
	,data: <{$ftp_anon_data}>
    });

    var anon_combo = new Ext.form.ComboBox({
        xtype: 'combo'
        ,name: '_anon'
        ,id: '_anon'
        ,hiddenName: '_anon_selected'
        ,fieldLabel: "<{$words.ftpd_anonymous}>"
        ,mode: 'local'
        ,store: anon_store
        ,displayField: 'display'
        ,valueField: 'value'
                ,readOnly: true
        ,typeAhead: true
        ,selectOnFocus:true
        ,triggerAction: 'all'
    });
    
    var rename_cbox = new Ext.form.Checkbox({
	id: '_rename'
	,name: '_rename'
	<{if $ftp_rename == "1"}>,checked: true<{/if}>
	,fieldLabel: "<{$words.auto_rename}>"
    });    
    
    var tip = new Ext.ux.SliderTip({
	getText: function(slider){
		if (slider.getValue() == 0)
			return String.format('<b>Unlimited</b>');
		else
          	      	return String.format('<b>{0}MB/s</b>', slider.getValue());
        }
    });    
    
    var bandwidth_upload_silder = new Ext.form.SliderField({
            	xtype: 'sliderfield'
                ,name: '_bandwidth_upload'
                ,id: '_bandwidth_upload'
            	,width: 214
            	,increment: 1
            	,minValue: '0'
            	,maxValue: 32
            	,setMsg:'MB/s'
            	,setZero:'Unlimited'
                ,fieldLabel: "<{$words.ftpd_upload_bw}>"
		,value: <{$ftp_bandwidth_upload}>
		,plugins: tip
    });

    var bandwidth_download_silder = new Ext.form.SliderField({
            	xtype: 'sliderfield'
                ,name: '_bandwidth_download'
                ,id: '_bandwidth_download'
		,width: 214
		,increment: 1
		,minValue: '0'
		,maxValue: 32
		,setMsg:'MB/s'
            	,setZero:'Unlimited'
                ,fieldLabel: "<{$words.ftpd_download_bw}>"
		,value: <{$ftp_bandwidth_download}>
		,plugins: tip
    });

    function ftp_status(st){
    	if (st == '1'){
    	    ssl_radiogroup.enable();
	        Ext.getDom("_port").disabled=false;
	        Ext.getDom("_passive_ip").disabled=false;
	        Ext.getDom("_range_begin").disabled=false;
	        Ext.getDom("_range_end").disabled=false;
            encode_combo.enable();
    	    anon_combo.enable();
    	    rename_cbox.enable();
    	    bandwidth_upload_silder.enable();
    	    bandwidth_download_silder.enable();
    	}else if (st == '0'){
    	    ssl_radiogroup.disable();
	        Ext.getDom("_port").disabled=true;
	        Ext.getDom("_passive_ip").disabled=true;
	        Ext.getDom("_range_begin").disabled=true;
	        Ext.getDom("_range_end").disabled=true;
    	    encode_combo.disable();
    	    anon_combo.disable();
    	    rename_cbox.disable();
    	    bandwidth_upload_silder.disable();
    	    bandwidth_download_silder.disable();
    	}
    };
    
    var fp = TCode.desktop.Group.addComponent({
		xtype: 'form',
        frame: false,
        labelWidth: 250,
        bodyStyle: 'padding:0 10px 0;',
        hideMode: 'offsets',
                
        items: [{
            layout: 'column',
            border: false,
            defaults: {
                columnWidth: '0.5',
                border: false
            }
            },prefix,{
            
            /*====================================================================
             * FTP
             *====================================================================*/
                                               
            xtype:'fieldset',
            title: '<{$words.ftpd_title}>',
            autoHeight: true,
            layout: 'form',
            buttonAlign: 'left',
            items: [
            ftp_radiogroup,
            ssl_radiogroup,
            {
                xtype: 'textfield',
                name: '_port',
                id: '_port',
                fieldLabel: '<{$gwords.port}>',
                value: '<{$ftp_port}>',
                maxLength:5,
                width:80
            },
                    {
                        layout:'column',
                        //width: 800,
                        // defaults for columns
                        defaults:{
                            layout:'form',
                            border:false,
                            xtype:'panel',
                            bodyStyle:'padding:0 18px 0 0'
                        },
                        items:[{
                            columnWidth: 0.5,
                            items:[{
                                xtype: 'textfield',
                                name: '_passive_ip',
								                     id: '_passive_ip',
								                     fieldLabel: '<{$words.ftpd_passive_ip}>',
								                     value: '<{$ftp_passive_ip}>',
								                     width:80
                            }]
                        },
                        {
						            columnWidth: 0.5,
						          items:[{
							                 xtype:'box',
							                 autoEl:{cn:'<span style="color:red">( <{$words.passive_ip_description}> )</span>'}
						                }]
					            }]
				            },
				            {
					          layout:'column',
                                //width: 800,
					         // defaults for columns
					         defaults:{
						        layout:'form',
						        border:false,
						        xtype:'panel',
						        bodyStyle:'padding:0 18px 0 0'
					         },
					        items:[{
						              columnWidth: 0.5,
						       items:[{
							              xtype: 'textfield',
                                name: '_range_begin',
                                id: '_range_begin',
                                hideLabel: false,
                                fieldLabel: "<{$words.ftp_port_range}>",
                                labelSeparator: ':',
                                maxLength:5,
                                width:80,
                                value: <{$ftp_port_range_begin}>
                            }]
                        },
                        {
                            columnWidth: 0.09,
                            items:[{
                                xtype: 'box'
                                ,height: 25
                                ,autoEl: {cn:'~'}
                            }]
                        },
                        {
                            columnWidth: 0.3,
                            items:[{
                                xtype: 'textfield',
                                name: '_range_end',
                                id: '_range_end',
                                hideLabel: true,
                                fieldLabel: "",
                                labelSeparator: ':',
                                maxLength:5,
                                width:80,
                                value: <{$ftp_port_range_end}>
                            }]
                        }]
                    },
            encode_combo,
            anon_combo,
            rename_cbox,
            bandwidth_upload_silder,
            bandwidth_download_silder

            ],//items
	    buttons: [{
                text: '<{$gwords.apply}>',
                handler: function(){
                    if(fp.getForm().isValid()){
			Ext.Msg.confirm('<{$words.ftpd}>',"<{$gwords.confirm}>",function(btn){
			    if(btn=='yes'){
				ftp_flag=0;
  	                            if (Ext.getDom("_port").disabled){
				        ftp_flag=1;
					ftp_status(1);
				    }
				    processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
				    //Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+ 
				    //fp.getForm().getValues(true).replace(/&/g,', '));
				    if (ftp_flag == 1 ) ftp_status(0);
			}
      })
		    }
		}
	    }]
        }]
    });
    
    encode_combo.setValue('<{$ftp_encode}>');
    encode_combo.on('expand', function( comboBox ){
      if (!window.ActiveXObject){
        comboBox.list.setWidth( 'auto' );
        comboBox.innerList.setWidth( 'auto' );
      }
    }, this, { single: true });
  
    anon_combo.setValue('<{$ftp_anon}>');
    anon_combo.on('expand', function( comboBox ){
      comboBox.list.setWidth( 140 );
      comboBox.innerList.setWidth( 140 );
    }, this, { single: true });
    
    ftp_status(<{$ftp_enabled}>);
    
    ftp_radiogroup.on('change',function(RadioGroup,newValue){
    	ftp_status(newValue);
    });

});


</script>
