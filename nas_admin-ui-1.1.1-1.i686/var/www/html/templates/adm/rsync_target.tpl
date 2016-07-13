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

<div id="div_rsync_target"></div> 

<script type="text/javascript"> 
var msg = function(title, msg){
    Ext.Msg.show({
        title: title,
        msg: msg,
        minWidth: 200,
        modal: true,
        icon: Ext.Msg.INFO,
        buttons: Ext.Msg.OK
    });
};

Ext.form.FileUploadField = Ext.extend(Ext.form.TextField,  {
    /**
     * @cfg {String} buttonText The button text to display on the upload button (defaults to
     * 'Browse...').  Note that if you supply a value for {@link #buttonCfg}, the buttonCfg.text
     * value will be used instead if available.
     */
    buttonText: 'Browse...',
    /**
     * @cfg {Boolean} buttonOnly True to display the fil    e upload field as a button with no visible
     * text field (defaults to false).  If true, all inherited TextField members will still be available.
     */
    buttonOnly: false,
    
    buttonHidden: false,
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

        if(this.buttonHidden){
            this.button.hide();
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

function handle_apply(){
    formpanel.getForm().submit({
        url: 'setmain.php?fun=setrsync_target',
        success:function(formpanel, o){
          msg('<{$words.rsync_target_title}>', o.result.msg);
        },
        failure:function(formpanel, o){
          msg('<{$words.rsync_target_title}>', o.result.msg);
        }
    });
}  

function diable_field(val){
  Ext.getCmp("_rsync_password").setDisabled(val);
  Ext.getCmp("_rsync_username").setDisabled(val);
  rsync_sshd_radiogroup.setDisabled(val);

  //diable_field2(val);
  if(val==true){
    diable_field2(val);
  }else{
    val = Ext.getCmp("_sshd_enable_F").getValue();
    diable_field2(val);
  }
}

function diable_field2(val){
  Ext.getCmp("sshd_ip1").setDisabled(val);
  Ext.getCmp("sshd_ip2").setDisabled(val);
  Ext.getCmp("sshd_ip3").setDisabled(val);
  Ext.getCmp("_public").setDisabled(val);
  Ext.getCmp("_public").button.setDisabled(val);
  Ext.getCmp("_private").setDisabled(val);
  Ext.getCmp("_private").button.setDisabled(val);
}

//Ext.onReady(function(){
	var rsync_share_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        fieldLabel: '<{$words.rysnc_target_label}> ',
        columns: 2,
        //id:'rsync_share',
        items: [{boxLabel: '<{$gwords.enable}>', name: '_rsync_enable',inputValue:'1' <{if $target_rsync_enable=='1'}> ,checked:true <{/if}>},
                {boxLabel: '<{$gwords.disable}>', name: '_rsync_enable',inputValue:'0' <{if $target_rsync_enable=='0'}> ,checked:true <{/if}>}
               ],
        listeners: {change:{fn:function(obj,val){
                                  if(val==0){
                                    diable_field(true);
                                  }else{
                                    diable_field(false);
                                  }
                                }
                            }
                    }
	}); 
 
	var rsync_sshd_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        fieldLabel: '<{$words.ssh_support}>',
        columns: 2,
        //id:'rsync_share',
        items: [{boxLabel: '<{$gwords.enable}>', id: '_sshd_enable_T', name: '_sshd_enable',inputValue:'1' <{if $sshd_enable=='1'}> ,checked:true <{/if}>},
                {boxLabel: '<{$gwords.disable}>', id: '_sshd_enable_F', name: '_sshd_enable',inputValue:'0' <{if $sshd_enable=='0'}> ,checked:true <{/if}>}
               ],
        listeners: {change:{fn:function(obj,val){
                                  if(val==0){
                                    diable_field2(true);
                                  }else{
                                    diable_field2(false);
                                  }
                                }
                            }
                    }
	}); 

    var formpanel = new Ext.FormPanel({ 
        id:'formpanel',
        renderTo:'div_rsync_target',
		style: 'margin: 10px;',
        fileUpload: true,
        items: [{
            xtype:'fieldset', 
            title: '<{$words.rsync_target_title}>',
            autoHeight:true,
            autoWidth:true,
            //defaultType: 'textfield',
            collapsed: false,
            labelWidth:150,
            defaults:{labelStyle:'width:200'},
            items :[
                    rsync_share_radiogroup,
                    {
                        xtype: 'textfield',
                        name: '_rsync_username',
                        id: '_rsync_username',
                        hideLabel: false,
                        fieldLabel: "<{$gwords.username}>",
                        labelSeparator: ':',
                        maxLength:64,
                        value: '<{$rsync_target_username}>',
                        vtype: 'UserName'
                    },
                    {
                        xtype: 'textfield',
                        inputType: "password",
                        name: '_rsync_password',
                        id: '_rsync_password',
                        hideLabel: false,
                        fieldLabel: "<{$gwords.password}>",
                        labelSeparator: ':',
                        maxLength:16,
                        value: '<{$rsync_target_password}>',
                        vtype: 'RsyncPassword'
                    },
                    rsync_sshd_radiogroup,
                    {
                        xtype: 'textfield',
                        name: 'sshd_ip1',
                        id: 'sshd_ip1',
                        hideLabel: false,
                        fieldLabel: "&nbsp;&nbsp;<{$words.allow_ip}> 1",
                        labelSeparator: ':',
                        maxLength:64,
                        value: '<{$sshd_ip1}>'
                    },
                    {
                        xtype: 'textfield',
                        name: 'sshd_ip2',
                        id: 'sshd_ip2',
                        hideLabel: false,
                        fieldLabel: "&nbsp;&nbsp;<{$words.allow_ip}> 2",
                        labelSeparator: ':',
                        maxLength:64,
                        value: '<{$sshd_ip2}>'
                    },
                    {
                        xtype: 'textfield',
                        name: 'sshd_ip3',
                        id: 'sshd_ip3',
                        hideLabel: false,
                        fieldLabel: "&nbsp;&nbsp;<{$words.allow_ip}> 3",
                        labelSeparator: ':',
                        maxLength:64,
                        value: '<{$sshd_ip3}>'
                    },{
                        layout: 'table',
                        layoutConfig: {
                            columns: 2
                        },
                        defaults:{
                            height: 27
                        },
                        items: [{
                            width: 203,
                            html: '&nbsp;&nbsp;<{$words.public_key}>(<{$words.optional}>): '
                        },{
                            xtype: 'fileuploadfield'
                            ,id: '_public'
                            ,name: '_public'
                            ,emptyText: '<{$words.choose_file_prompt}>'
                            ,width: 300
                            ,buttonCfg: {
                              text: '',
                              iconCls: 'upload-icon'
                            }
                        }]
                    },{
                        layout: 'table',
                        layoutConfig: {
                            columns: 2
                        },
                        defaults:{
                            height: 27
                        },
                        items: [{
                            width: 203,
                            html: '&nbsp;&nbsp;<{$words.private_key}>(<{$words.optional}>): '
                        },{
                            xtype: 'fileuploadfield'
                            ,id: '_private'
                            ,name: '_private'
                            ,emptyText: '<{$words.choose_file_prompt}>'
                            ,width: 300
                            ,buttonCfg: {
                              text: '',
                              iconCls: 'upload-icon'
                            }
                        }]
                    },{
                      xtype:'hidden',
                      id:'_certificate',
                      name:'_certificate'
                    }
                  ]
          }],
                  buttons:[{text: '<{$gwords.apply}>',
                              handler:function(){
				pattern = /^[\w\[\]\@\%\/\*]*$/
				r_passwd = Ext.getCmp('_rsync_password').getValue()
				check_passwd = pattern.test(r_passwd)
				if(!check_passwd){
				    Ext.Msg.alert('Error','<{$words.special_characters}>');
				    return;
				}
                                if(Ext.getCmp("_public").getValue()=="" && Ext.getCmp("_private").getValue()==""){
                                  Ext.getCmp("_certificate").setValue("0");
                                }else if(Ext.getCmp("_public").getValue()!="" && Ext.getCmp("_private").getValue()!=""){
                                  Ext.getCmp("_certificate").setValue("1");
                                }else{
                                  msg('<{$words.rsync_target_title}>', '<{$words.upload_fail}>');
                                  return;
                                }
                                handle_apply();
                              }
                            },{
                            text: '<{$words.restore_key}>'
                              ,handler: function(){
                                Ext.getCmp("_certificate").setValue("2");
                                handle_apply();
                              }//handler
                          },{
                            text: '<{$words.download_key}>'
                              ,handler: function(){
                                Ext.getCmp("_certificate").setValue("3");
                                handle_apply();
                              }//handler
                          }],
                  buttonAlign:'left'
    });

//});

<{if $target_rsync_enable=='0'}>
  diable_field(true);
<{/if}>

<{if $sshd_enable=='0'}>
  diable_field2(true);
<{/if}>

</script>  

