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

<div id="mainDiv1"></div>

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

Ext.onReady(function(){

    Ext.QuickTips.init();

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

    var fp2 = new Ext.FormPanel({
        renderTo: 'mainDiv1',
        fileUpload: true,
        autoWidth : true,
        autoHeight: true,
        buttonAlign: 'left',
		style: 'backgroud-color: transparent; margin: 10px;',
        labelWidth: 50,
        defaults: {
            anchor: '95%',
            allowBlank: false,
            msgTarget: 'side'
        },
        items: [
			{
	            xtype: 'fileuploadfield',
	            id: 'form-file',
	            emptyText: '<{$words.choose_file_prompt}>',
	            blankText:"<{$gwords.filerequire}>",
	            fieldLabel: '<{$gwords.upload}>',
	            name: 'config-path',
	            buttonCfg: {
	                text: '   ',
	                iconCls: 'upload-icon'
	            }
	        }
		],
        buttons: [{
            text: '<{$gwords.upload}>',
            handler: function(){
                if(fp2.getForm().isValid()){
	                fp2.getForm().submit({
	                    url: 'setmain.php?fun=setconf&action_do=Upload',
	                    waitMsg: 'Uploading your config...',
	                    success: function(fp2, o){
	                        msg('<{$words.conf_title}>', o.result.msg);
	                        displayMsg(o.result.msg);
	                        setTimeout("processUpdater('getmain.php','fun=reboot')",5000);
	                    },
	                    failure: function(fp2, o){
	                        msg('<{$words.conf_title}>', o.result.msg);
	                        displayMsg(o.result.msg);
	                    }
	                })
                }
            }
        },
        {
			//download button
            text: '<{$gwords.download}>',
			handler: function(){
			    window.open('../adm/getmain.php?fun=d_conf&action_do=Download');
			}
		}        
        ]
    })

});


</script>
