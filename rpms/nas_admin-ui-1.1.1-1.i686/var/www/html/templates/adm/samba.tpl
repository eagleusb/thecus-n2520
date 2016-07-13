<script type="text/javascript"> 

function redirect_reboot(){
	 setCurrentPage('reboot');
	 processUpdater('getmain.php','fun=reboot');
}
Ext.onReady(function(){
/**
 * number vtype
 */
Ext.form.VTypes["numberVal"] = /^\d+$/;
Ext.form.VTypes["number"]=function(v){
         return Ext.form.VTypes["numberVal"].test(v);
}
Ext.form.VTypes["numberMask"]=/[0-9]/;

          
function handle_apply(){   
   processAjax('<{$set_url}>',onLoadForm,formpanel.getForm().getValues(true));   
}

/*var split = new Ext.SplitBar("elementToDrag", "elementToSize", Ext.SplitBar.HORIZONTAL, Ext.SplitBar.LEFT);
split.setAdapter(new Ext.SplitBar.AbsoluteLayoutAdapter("container"));
split.minSize = 100;
split.maxSize = 600;
split.animate = true;
*/
var recycle_radiogroup= new Ext.form.RadioGroup({
  xtype: 'radiogroup',
  fieldLabel: '<{$awords.smb_recycle}>',
  id:'rdo_recycle',
  width:350,
  items: [{boxLabel: "<{$gwords.enable}>", name: 'advance_smb_recycle',inputValue:'1' <{if $smb_recycle=='1' }> ,checked:true <{/if}>},
          {boxLabel: "<{$gwords.disable}>", name: 'advance_smb_recycle',inputValue:'0' <{if $smb_recycle=='0' }> ,checked:true <{/if}>}]
});             
var formpanel = TCode.desktop.Group.addComponent({
        xtype: 'form',
        id:'formpanel',  
        renderTo:'div_samba',
        items: [{
            xtype:'fieldset', 
            title: '<{$twords.tree_samba}>',
            autoHeight:true,
            autoWidth:true,
            defaultType: 'textfield',
            collapsed: false,
            labelWidth:240,
            defaults:{width:350},
            items :[{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$words.smb_service}>',
                      id:'rdo_share',
                      items: [{boxLabel: '<{$gwords.enable}>', name: '_nic1_cifs',inputValue:'1' <{if $cifs=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.disable}>', name: '_nic1_cifs',inputValue:'0' <{if $cifs=='0' }> ,checked:true <{/if}>}]
                  }<{if $NAS_DB_KEY==1}>,{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.cifs_filecache}>',
                      id:'rdo_cifs',
                      items: [{boxLabel: '<{$gwords.enable}>', name: '_nic1_filecache',inputValue:'1' <{if $httpd_nic1_filecache=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.disable}>', name: '_nic1_filecache',inputValue:'0' <{if $httpd_nic1_filecache=='0' }> ,checked:true <{/if}>}]
                  }<{/if}> ,{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_restrict_anonymous}>',
                      id:'rdo_domain',
                      items: [{boxLabel: '<{$gwords.enable}>', name: 'advance_smb_restrict_anonymous',inputValue:'1' <{if $smb_restrict_anonymous=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.disable}>', name: 'advance_smb_restrict_anonymous',inputValue:'0' <{if $smb_restrict_anonymous=='0' }> ,checked:true <{/if}>}]
                  },{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_localmaster}>',
                      id:'rdo_local',
                      items: [{boxLabel: '<{$awords.smb_localmaster_enable}>', name: 'smb_localmaster',inputValue:'1' <{if $smb_localmaster=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$awords.smb_localmaster_disable}>', name: 'smb_localmaster',inputValue:'0' <{if $smb_localmaster=='0' }> ,checked:true <{/if}>}]
                  },{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_trusted}>',
                      id:'rdo_trusted',
                      items: [{boxLabel: '<{$gwords.yes}>', name: 'smb_trusted',inputValue:'1' <{if $smb_trusted=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.no}>', name: 'smb_trusted',inputValue:'0' <{if $smb_trusted=='0' }> ,checked:true <{/if}>}]
                  }<{if $hide_receivefile_size==1}>,{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_receivefile_size}>',
                      id:'rdo_receivefile_size',
                      items: [{boxLabel: '<{$gwords.yes}>', name: 'smb_receivefile_size',inputValue:'1' <{if $smb_receivefile_size=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.no}>', name: 'smb_receivefile_size',inputValue:'0' <{if $smb_receivefile_size=='0' }> ,checked:true <{/if}>}]
                  }<{/if}>,{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_blocksize}>',
                      id:'rdo_blocksize',
                      items: [{boxLabel: '4096', name: 'smb_blocksize',inputValue:'1' <{if $smb_blocksize=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '1024', name: 'smb_blocksize',inputValue:'0' <{if $smb_blocksize=='0' }> ,checked:true <{/if}>}]
                  }<{if $NAS_DB_KEY==1}>,{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_signing}>',
                      id:'rdo_sign',
                      items: [{boxLabel: '<{$awords.smb_signing_auto}>', name: 'smb_signing',inputValue:'1' <{if $smb_signing=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$awords.smb_signing_mandatory}>', name: 'smb_signing',inputValue:'2' <{if $smb_signing=='2' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.disable}>', name: 'smb_signing',inputValue:'0' <{if $smb_signing=='0' }> ,checked:true <{/if}>}]
                  }<{/if}> ,{
                     xtype:'hidden',
                     id:'o_nic1_cifs',
                     name:'o_nic1_cifs' ,
                     value:'<{$cifs}>'
                  },{
                     xtype:'hidden',
                     id:'o_nic1_filecache',
                     name:'o_nic1_filecache' ,
                     value:'<{$httpd_nic1_filecache}>'
                  },{
                     xtype:'hidden',
                     id:'o_advance_smb_restrict_anonymous',
                     name:'o_advance_smb_restrict_anonymous' ,
                     value:'<{$smb_restrict_anonymous}>'
                  },{
                     xtype:'hidden',
                     id:'o_smb_localmaster',
                     name:'o_smb_localmaster' ,
                     value:'<{$smb_localmaster}>'
                  },{
                     xtype:'hidden',
                     id:'o_smb_blocksize',
                     name:'o_smb_blocksize' ,
                     value:'<{$smb_blocksize}>'
                  },{
                     xtype:'hidden',
                     id:'o_smb_signing',
                     name:'o_smb_signing' ,
                     value:'<{$smb_signing}>'
                  },{
                     xtype:'hidden',
                     id:'o_smb_trusted',
                     name:'o_smb_trusted' ,
                     value:'<{$smb_trusted}>'
                  }]
          },{
            xtype:'fieldset', 
            title: '<{$awords.mac_samba_title}>',
            autoHeight:true,
            autoWidth:true,
            defaultType: 'textfield',
            collapsed: false,
            labelWidth:240,
            defaults:{width:350},
            items :[{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_roundup}>',
                      id:'rdo_roundup',
                      items: [{boxLabel: '<{$gwords.enable}>', name: 'smb_roundup',inputValue:'1'<{if $smb_roundup=='1'}> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.disable}>', name: 'smb_roundup',inputValue:'0' <{if $smb_roundup=='0'}> ,checked:true <{/if}>}]
                  },{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_unix}>',
                      id:'rdo_unix',
                      items: [{boxLabel: '<{$gwords.enable}>', name: 'smb_unix',inputValue:'1'<{if $smb_unix=='1'}> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.disable}>', name: 'smb_unix',inputValue:'0' <{if $smb_unix=='0'}> ,checked:true <{/if}>}]
                  },{
                      xtype: 'radiogroup',
                      fieldLabel: '<{$awords.smb_veto}>',
                      id:'rdo_veto',
                      items: [{boxLabel: '<{$gwords.enable}>', name: 'smb_veto',inputValue:'1' <{if $smb_veto=='1' }> ,checked:true <{/if}>},
                              {boxLabel: '<{$gwords.disable}>', name: 'smb_veto',inputValue:'0' <{if $smb_veto=='0' }> ,checked:true <{/if}>}]
                  },{
                     xtype:'hidden',
                     id:'o_smb_unix',
                     name:'o_smb_unix' ,
                     value:'<{$smb_unix}>'
                  },{
                     xtype:'hidden',
                     id:'o_smb_roundup',
                     name:'o_smb_roundup' ,
                     value:'<{$smb_roundup}>'
                  },{
                     xtype:'hidden',
                     id:'o_smb_veto',
                     name:'o_smb_veto' ,
                     value:'<{$smb_veto}>'
                  }]
          },{
             xtype:'fieldset',
             title: '<{$awords.recycle_bin_title}>',
             autoHeight:true,
             autoWidth:true,
             collapsed: false,
             labelWidth:240,
             items :[{
                       layout:'form',
                       items:[
                                recycle_radiogroup
                             ]
                     },
                     { layout : 'column',
                                items:[{
                                       // columnWidth : .4,
                                        layout : "form",
                                        style:'padding-top:2px;padding-bottom:10px;width:310px;',
                                        items : [{
                                                   xtype: "numberfield",
                                                   name: "_daysago",
                                                   id: "_daysago",
                                                   width: "50",
                                                   fieldLabel: "<{$awords.smb_recycle_delete_data}>",
                                                   value: '<{$smb_dataago}>',
                                                   vtype:'number',
                                                   maxLength:5
                                                }]   
                                        }
                                        ,
                                        {
                                          //  columnWidth : .1,
                                            style:'padding-top:4px;padding-bottom:10px;width:50px',
                                            layout : "form",
                                            items : [{
                                                      xtype : "label",
                                                      id:'recycle_days',
                                                      style:' margin-left:10px;',
                                                      text : "<{$awords.smb_recycle_days}>",
                                                      width : 30
                                                    }]
                                        },
                                        {
                                          //  columnWidth : .5,
                                            style:'padding-top:4px;padding-bottom:10px;',
                                            layout : "form",
                                            items : [{
                                                      xtype : "label",
                                                      id:'recycle_days',
                                                      style:' margin-left:10px;',
                                                      text : "<{$awords.smb_recycle_remark}>",
                                                      width : 300
                                                    }]
                                        }
                                      ]
                     },
                     {
                          layout:'form',
                          items:[{
                                    xtype: 'radiogroup',
                                    fieldLabel:"<{$awords.smb_recycle_display}>",
                                    id:'rdo_recycle_display',
                                    width:350,
                                    items: [{boxLabel: "<{$gwords.enable}>", name: 'recycle_display',inputValue:'1'<{if $recycle_display=='1'}> ,checked:true <{/if}>},
                                             {boxLabel: "<{$gwords.disable}>", name: 'recycle_display',inputValue:'0' <{if $recycle_display=='0'}> ,checked:true <{/if}>}]
                                }]                  
                     },
                     { layout : 'column',
                                items:[{
                                       // columnWidth : .4,
                                        layout : "form",
                                        style:'padding-top:2px;padding-bottom:10px;width:310px;',
                                        items : [{
                                                   xtype: "numberfield",
                                                   name: "_maxsize",
                                                   id: "_maxsize",
                                                   width: "50",
                                                   fieldLabel: "<{$awords.smb_recycle_maxsize}>",
                                                   value: '<{$smb_maxsize}>',
                                                   vtype:'number',
                                                   maxLength:5
                                                }]   
                                        }
                                        ,
                                        {
                                          //  columnWidth : .1,
                                            style:'padding-top:4px;padding-bottom:10px;width:50px',
                                            layout : "form",
                                            items : [{
                                                      xtype : "label",
                                                      id:'recycle_GB',
                                                      style:' margin-left:10px;',
                                                      text : "<{$awords.smb_recycle_maxsizeunit}>",
                                                      width : 30
                                                    }]
                                        },
                                        {
                                          //  columnWidth : .5,
                                            style:'padding-top:4px;padding-bottom:10px;',
                                            layout : "form",
                                            items : [{
                                                      xtype : "label",
                                                      id:'recycle_remarkdata',
                                                      style:' margin-left:10px;',
                                                      text : "<{$awords.smb_recycle_remark_maxsize}>",
                                                      width : 300
                                                    }]
                                        }
                                      ]
                     } 
		     ,{
                          xtype:'hidden',
                          id:'o_advance_smb_recycle',
                          name:'o_advance_smb_recycle',
                          value:'<{$smb_recycle}>'
                     },{
                          xtype:'hidden',
                          id:'o_smb_dataago',
                          name:'o_smb_dataago',
                          value:'<{$smb_dataago}>'
                     },{
                          xtype:'hidden',
                          id:'o_recycle_display',
                          name:'o_recycle_display',
                          value:'<{$recycle_display}>'
                     },{
                          xtype:'hidden',
                          id:'o_smb_maxsize',
                          name:'o_smb_maxsize',
                          value:'<{$smb_maxsize}>'
                        }
                  ]
                                            
          },<{if $wan_ipv6_literal != "" }> {
          	  xtype:'fieldset',
                  //title: '<{$gwords.description}>',
                  title: 'Samba/IPv6 Literal Address (For Windows access IPv6 samba)',
                  autoHeight: true,
                  items: [{
                      html:'\\\\<{$wan_ipv6_literal}>.ipv6-literal.net'
                  }]
          },<{/if}> {
                  buttonAlign:'left' , 
                  buttons:[{ text: '<{$gwords.apply}>',handler:handle_apply}]}]
          }
            );
          recycle_radiogroup.on('change',function(RadioGroup,newValue)
          {
               if (newValue == '1'){
                                    Ext.getCmp("_daysago").setDisabled(false);
				    Ext.getCmp("_maxsize").setDisabled(false);
               }else{
                                    Ext.getCmp("_daysago").setDisabled(true);
                                    Ext.getCmp("_maxsize").setDisabled(true);
               }                     
          });
          if("<{$smb_recycle}>" == '1'){
                 Ext.getCmp("_daysago").setDisabled(false);
		 Ext.getCmp("_maxsize").setDisabled(false);
          }else{
                 Ext.getCmp("_daysago").setDisabled(true);
                 Ext.getCmp("_maxsize").setDisabled(true); 
          }        
    });
</script>  
<div id="div_samba"></div> 

