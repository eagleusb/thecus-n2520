<style>
    .x-form-file-wrap {
	    position: relative;
	    height: 22px;
	}
	.x-form-file-wrap .x-form-file {
		position: absolute;
		right: 0;
		-moz-opacity: 0;
		filter:alpha(opacity: 0);
		opacity: 0;
		z-index: 2;
	    height: 22px;
	}
	.x-form-file-wrap .x-form-file-btn {
		position: absolute;
		right: 0;
		z-index: 1;
	}
	.x-form-file-wrap .x-form-file-text {
	    position: absolute;
	    left: 0;
	    z-index: 3;
	    color: #777;
	}
    .upload-icon {
        background: url('<{$urlimg}>icons/fam/image_add.png') no-repeat 0 0 !important;
        }

    #fi-button-msg {
        border: 2px solid #ccc;
        padding: 5px 10px;
        background: #eee;
        margin: 5px;
        float: left;
    }
</style>

<div id="httpform"/>

<script language="javascript">
Ext.form.FileUploadField = Ext.extend(Ext.form.TextField,  {
    /**
     * @cfg {String} buttonText The button text to display on the upload button (defaults to
     * 'Browse...').  Note that if you supply a value for {@link #buttonCfg}, the buttonCfg.text
     * value will be used instead if available.
     */
    buttonText: 'Browse...',
    /**
     * @cfg {Boolean} buttonOnly True to display the file upload field as a button with no visible
     * text field (defaults to false).  If true, all inherited TextField members will still be available.
     */
    buttonOnly: false,
    /**
     * @cfg {Number} buttonOffset The number of pixels of space reserved between the button and the text field
     * (defaults to 3).  Note that this only applies if {@link #buttonOnly} = false.
     */
    buttonOffset: 3,
    /**
     * @cfg {Object} buttonCfg A standard {@link Ext.Button} config object.
     */

    // private
    readOnly: true,

    /**
     * @hide
     * @method autoSize
     */
    autoSize: Ext.emptyFn,

    // private
    initComponent: function(){
        Ext.form.FileUploadField.superclass.initComponent.call(this);

        this.addEvents(
            /**
             * @event fileselected
             * Fires when the underlying file input field's value has changed from the user
             * selecting a new file from the system file selection dialog.
             * @param {Ext.form.FileUploadField} this
             * @param {String} value The file value returned by the underlying file input field
             */
            'fileselected'
        );
    },

    // private
    onRender : function(ct, position){
        Ext.form.FileUploadField.superclass.onRender.call(this, ct, position);

        this.wrap = this.el.wrap({cls:'x-form-field-wrap x-form-file-wrap'});
        this.el.addClass('x-form-file-text');
        this.el.dom.removeAttribute('name');

        this.fileInput = this.wrap.createChild({
            id: this.getFileInputId(),
            name: this.name||this.getId(),
            cls: 'x-form-file',
            tag: 'input',
            type: 'file',
            size: 1
        });

        var btnCfg = Ext.applyIf(this.buttonCfg || {}, {
            text: this.buttonText
        });
        this.button = new Ext.Button(Ext.apply(btnCfg, {
            renderTo: this.wrap,
            cls: 'x-form-file-btn' + (btnCfg.iconCls ? ' x-btn-icon' : '')
        }));

        if(this.buttonOnly){
            this.el.hide();
            this.wrap.setWidth(this.button.getEl().getWidth());
        }

        this.fileInput.on('change', function(){
            var v = this.fileInput.dom.value;
            this.setValue(v);
            this.fireEvent('fileselected', this, v);
        }, this);
    },

    // private
    getFileInputId: function(){
        return this.id+'-file';
    },

    // private
    onResize : function(w, h){
        Ext.form.FileUploadField.superclass.onResize.call(this, w, h);

        this.wrap.setWidth(w);

        if(!this.buttonOnly){
            var w = this.wrap.getWidth() - this.button.getEl().getWidth() - this.buttonOffset;
            this.el.setWidth(w);
        }
    },

	 onDisable: function(){
         Ext.form.FileUploadField.superclass.onDisable.call(this);
         this.doDisable(true);
     },

     onEnable: function(){
         Ext.form.FileUploadField.superclass.onEnable.call(this);
         this.doDisable(false);

     },

     // private
     doDisable: function(disabled){
         this.fileInput.dom.disabled = disabled;
         this.button.setDisabled(disabled);
     },

    // private
    preFocus : Ext.emptyFn,

    // private
    getResizeEl : function(){
        return this.wrap;
    },

    // private
    getPositionEl : function(){
        return this.wrap;
    },

    // private
    alignErrorIcon : function(){
        this.errorIcon.alignTo(this.wrap, 'tl-tr', [2, 0]);
    }

});
Ext.reg('fileuploadfield', Ext.form.FileUploadField);

function displayMsg(message){
 //   var msg = document.getElementById('mainDiv2');
 //   msg.innerHTML = message;
 //   Ext.get("mainDiv2").enableDisplayMode('inline');
 //   Ext.get("mainDiv2").show();

}

function redirect_reboot(){
	setCurrentPage('reboot');
	processUpdater('getmain.php','fun=reboot');
}

Ext.onReady(function(){
    Ext.QuickTips.init();
    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var prefix = new Ext.form.Hidden({id: 'prefix', name: 'prefix', value: 'httpd'});

    var http_radiogroup = new Ext.form.RadioGroup({
                xtype: 'radiogroup'
                ,width:400
                ,fieldLabel: '<{$words.http_sharing}>'
                //,listeners: {change:{fn:function(){alert('radio changed');}}}
                ,items: [
                    {boxLabel: '<{$gwords.enable}>', name: '_http', inputValue: 1 <{if $http_enabled =="1"}>, checked:true <{/if}>}
                    ,{boxLabel: '<{$gwords.disable}>', name: '_http', inputValue: 0 <{if $http_enabled =="0" || $http_enabled ==""}>, checked:true <{/if}>}
                ]
    });

    var ssl_radiogroup = new Ext.form.RadioGroup({
                xtype: 'radiogroup'
                ,width:400
                ,fieldLabel: '<{$words.http_sharing}>'
                //,listeners: {change:{fn:function(){alert('radio changed');}}}
                ,items: [
                    {boxLabel: '<{$gwords.enable}>', name: '_ssl', inputValue: 1 <{if $ssl_enabled =="1"}>, checked:true <{/if}>}
                    ,{boxLabel: '<{$gwords.disable}>', name: '_ssl', inputValue: 0 <{if $ssl_enabled =="0" || $ssl_enabled ==""}>, checked:true <{/if}>}
                ]
    });
    
    var msg = function(title, msg){
        Ext.Msg.show({
            title: title,
            msg: msg,
            minWidth: 200,
            modal: true,
            icon: Ext.Msg.INFO,
            buttons: Ext.Msg.OK
        })
    };

    var fp = new Ext.FormPanel({
        frame: false
        ,labelWidth: 180
        //,width: 830
        ,fileUpload: 'true'
        ,renderTo:'httpform'
        ,style: 'margin: 10px;'
        ,buttonAlign: 'left'
        
        ,items: [
            {
                layout: 'column'
                ,border: false
                ,defaults: { columnWidth: '.5', border: false }
            }
            ,prefix
            ,{  /*====================================================================
                 * http
                 *====================================================================*/
                xtype:'fieldset'
                ,title: '<{$words.http_title}>'
                ,autoHeight: true
                ,items: [
                    http_radiogroup
                    ,{
	                xtype: 'textfield'
	                ,id: '_port'
	                ,name: '_port'
	                ,fieldLabel: '<{$gwords.port}>'
	                ,value: '<{$http_port}>'
	                ,maxLength:5
	            }
	        ]//items.fieldset
            }
            ,{  /*====================================================================
                 * SSL
                 *====================================================================*/
                xtype:'fieldset'
                ,title: '<{$words.ssl_title}>'
                ,autoHeight: true
                ,items: [
                    ssl_radiogroup
                    ,{
	                xtype: 'textfield'
	                ,id: '_sport'
	                ,name: '_sport'
	                ,fieldLabel: '<{$gwords.port}>'
	                ,value: '<{$ssl_port}>'
	                ,maxLength:5
				},{
					/*====================================================================
					 * SSLCertificateFile
					 *====================================================================*/
					xtype: 'fileuploadfield'
					,id: '_crt'
					,name: '_crt'
					,emptyText: '<{$words.choose_file_prompt}>'
					,fieldLabel: '<{$words.ssl_crt}>'
					,autoWidth: true
					,buttonCfg: {
						text: '   ',
						iconCls: 'upload-icon'
					}
				},{
					/*====================================================================
					 * SSLCertificateKeyFile
					 *====================================================================*/
					xtype: 'fileuploadfield'
					,id: '_key'
					,name: '_key'
					,emptyText: '<{$words.choose_file_prompt}>'
					,fieldLabel: '<{$words.ssl_crtkey}>'
					,autoWidth: true
					,buttonCfg: {
						text: '   ',
						iconCls: 'upload-icon'
					}
				},{
					/*====================================================================
					 * SSLCACertificateFile
					 *====================================================================*/
					xtype: 'fileuploadfield'
					,id: '_cacrt'
					,name: '_cacrt'
					,emptyText: '<{$words.choose_file_prompt}>'
					,fieldLabel: '<{$words.ssl_cacrt}>'
					,autoWidth: true
					,buttonCfg: {
						text: '   ',
						iconCls: 'upload-icon'
					}
				},{
					html:'&nbsp;<span style="color:red"><{$ssl_log}></span>'
				},{
					xtype:'hidden',
					id:'_certificate',
					name:'_certificate'
  				}
				]//items.fieldset
        	}
    	]//items.FormPanel
        
        ,buttons: [{
                text: '<{$gwords.apply}>'
                ,handler: function(){
                    if(fp.getForm().isValid()){
                        Ext.Msg.confirm('<{$words.http_title}>',"<{$gwords.confirm}>",function(btn){
                            if(btn=='yes'){
                                http_flag=0;
                                ssl_flag=0;
                                if (Ext.getDom("_port").disabled){
	                           	    http_flag=1;
	                           	    Ext.getDom("_port").disabled=false;
                                }
                                if (Ext.getDom("_sport").disabled){
	                           	    ssl_flag=1;
	                           	    Ext.getDom("_sport").disabled=false;
									Ext.getCmp("_crt").setDisabled(false);
									Ext.getCmp("_cacrt").setDisabled(false);
									Ext.getCmp("_key").setDisabled(false);
                                }

                                if(Ext.getCmp("_crt").getValue()=="" && Ext.getCmp("_cacrt").getValue()=="" && Ext.getCmp("_key").getValue()==""){
                                	Ext.getCmp("_certificate").setValue("0");
									processAjax('<{$form_action}>',onLoadForm,fp.getForm().getValues(true));
                                }else if(Ext.getCmp("_crt").getValue()!="" && Ext.getCmp("_cacrt").getValue()!="" && Ext.getCmp("_key").getValue()!=""){
									Ext.getCmp("_certificate").setValue("1");
									fp.getForm().submit({
										url: '<{$form_action}>',
										params: fp.getForm().getValues(false),
										success: function(fp, o){
											Ext.Msg.show({
											       title: "<{$words.http_title}>",
											       msg: o.result.msg,
											       buttons: Ext.MessageBox.OK,
											       icon: Ext.MessageBox.INFO,
											       closable: false,
											       fn: function() {
											       		processUpdater('getmain.php','fun=reboot');
											       }
											});
										},
										failure: function(fp, o){
											mag_box("<{$words.http_title}>", o.result.msg, "ERROR", "OK", null, false);
										}
									});
                                }else{
									msg('<{$words.http_title}>', '<{$words.ssl_upcrt_fail}>');
                                					return;
								}

                                if (http_flag ==1 )
                           	    	Ext.getDom("_port").disabled=true;
                                if (ssl_flag ==1 ){
                           	    	Ext.getDom("_sport").disabled=true;
									Ext.getCmp("_crt").setDisabled(true);
									Ext.getCmp("_cacrt").setDisabled(true);
									Ext.getCmp("_key").setDisabled(true);
								}
                        }})//Msg.confirm
	                //Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+ 
                        //               fp.getForm().getValues(true).replace(/&/g,', '));
                    }//isValid
                }//handler
        },{
                text: '<{$words.ssl_restore}>'
                ,handler: function(){
                    if(fp.getForm().isValid()){
                        Ext.Msg.confirm('<{$words.http_title}>',"<{$gwords.confirm}>",function(btn){
                            if(btn=='yes'){
				                processAjax('<{$form_action}>',onLoadForm,"&_restore=1");
                        }})//Msg.confirm
	                //Ext.Msg.alert('Submitted Values', 'The following will be sent to the server: <br />'+
                        //               fp.getForm().getValues(true).replace(/&/g,', '));
                    }//isValid
                }//handler
        }]//buttons
    });
    
    var fp2 = new Ext.FormPanel({
        frame: false
        ,labelWidth: 110
        //,width: 600
        ,fileUpload: 'true'
        ,autoWidth: 'true'
        ,renderTo:'httpform'
        ,bodyStyle: 'padding:0 10px 0;'
        ,items: [
            {
                layout: 'column'
                ,border: false
                ,defaults: { columnWidth: '.5', border: false }
            }
            ,{  /*====================================================================
                 * Description
                 *====================================================================*/
                xtype:'fieldset'
                ,title: '<{$gwords.description}>'
                ,autoHeight: true
                ,items: [
                    {
						html:'&nbsp;<{$words.ssl_description}>'
	            	}
				]//items.fieldset
			}
	        
		]

    });
    
    if(<{$http_enabled}>=='0')
    	Ext.getDom("_port").disabled=true;
    	
    if(<{$ssl_enabled}>=='0'){
    	Ext.getDom("_sport").disabled=true;
		Ext.getCmp("_crt").setDisabled(true);
		Ext.getCmp("_cacrt").setDisabled(true);
		Ext.getCmp("_key").setDisabled(true);
	}
    	
    http_radiogroup.on('change',function(RadioGroup,newValue){
    	if (newValue == '1')
    		Ext.getDom("_port").disabled=false;
    	else
    		Ext.getDom("_port").disabled=true;
    });
    
    ssl_radiogroup.on('change',function(RadioGroup,newValue){
    	if (newValue == '1'){
    		Ext.getDom("_sport").disabled=false;
			Ext.getCmp("_crt").setDisabled(false);
			Ext.getCmp("_cacrt").setDisabled(false);
			Ext.getCmp("_key").setDisabled(false);
      	}
    	else{
    		Ext.getDom("_sport").disabled=true;
			Ext.getCmp("_crt").setDisabled(true);
			Ext.getCmp("_cacrt").setDisabled(true);
			Ext.getCmp("_key").setDisabled(true);
		}
    });
});

</script>
