<{include file="adm/header.tpl"}>
<body >
<div id="north" >
    <table width="1004" border="0" height="100%" cellspacing="0" cellpadding="0"  style="background-image:url(/theme/images/index/header.jpg);background-repeat: no-repeat;">
      <tr >
        <td width="100%" valign="bottom"></td> 
        <td align="right" valign="bottom" nowrap="nowrap"  > 
        </td>
        <td align="left" valign="bottom"  > 
        </td> 
      </tr>
    </table> 
</div>
 

 

<div id="south" >  
 <div style="position:absolute;right:6px;bottom:12px;" class="white_w12"><{$FWPRODUCER}> <{$FWTYPE}> V<{$FW_VERSION}></div>  
</div>    


<input type='hidden' name='currentpage' id='currentpage' value='' />
</body>
<{include file="adm/footer.tpl"}>
<script type="text/javascript" src="<{$urlextjs}>adapter/ext/ext-base.js"></script>
<script type="text/javascript" src="<{$urlextjs}>ext-all.js"></script>
<script type="text/javascript" src="<{$urlextjs}>MessageBox.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urlextjs}>LoadMask.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>main.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>net.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>FileUploadField.js?<{$randValue}>" ></script>
<script type="text/javascript"> 
var wait_msg='<{$gwords.wait_msg}>';

Ext.onReady(function(){
Ext.Updater.defaults.loadScript = true;
var detailEl;
   Ext.Msg.alert('', '');
   Ext.Msg.hide();   
      var treemenu = new Ext.Viewport({
        layout: 'border',
        monitorResize: true,
        defaults: {
            monitorResize: true
        },
        listeners:{
            'resize':function(){return;
                if(document.body.clientWidth < 800){
                    this.setWidth(800);
                } else {
                    this.setWidth('100%');
                }
            }
        },
        items: [
            {
                el: 'north',
                id: 'north_header',
                region:'north',
                xtype: 'container',
                height: 100,
                cls: 't-ctl',
                items: [
                    {
                        xtype: 'toolbar',
                        frame: false,
                        cls: 't-ctl-bar'
                    },
                    {
                        xtype: 'toolbar',
                        frame: false,
                        height: 40,
                        border: false,
                        cls: 't-nav-bar',
                        items: [
                            {
                                xtype: 'box',
                                cls: 't-nav-home',
                                disabled: true,
                                autoEl: {
                                    tag: 'div',
                                    html: '<div></div>'
                                }
                            }
                        ]
                    }
                ]
            },
            {
                region: 'center',
                layout: 'border',
                frame: false,
                border: false,
                defaults: {
                    monitorResize: true
                },
                items: {
                    id: 'content-panel',
                    region: 'center',
                    autoScroll: true,
                    border: false,
                    frame: false,
                    layout: 'fit',
                    defaults: {
                        monitorResize: true
                    },
                    items: {
                        id: 'content',
                        xtype: 'panel'
                    }
                }
            },
            {
                xtype: 'toolbar',
                region:'south',
                split:false,
                layout: 'anchor',
                cls: 't-status',
                height: 40
            }
        ]
    });
      function doResize(){
        var i = (Ext.getBody().getWidth()-1004)/2;
        if(i<0)i=0;
        //treemenu.el.setStyle('margin-left', i+'px');
      }
      Ext.EventManager.onWindowResize(function(){ 
          treemenu.setHeight(Ext.lib.Dom.getViewportHeight());
          treemenu.doLayout();
          doResize();
      })
      doResize();
       
     
});

window.onload  = function(){
	myMask = new Ext.LoadMask(document.getElementById('content-panel'), {msg:"<{$gwords.wait_msg}>..."});
	mainMask = new Ext.LoadMask(Ext.getBody(),{msg:"<{$gwords.wait_msg}>..."});
	processUpdater('getmain.php?fun=fsck_ui','');
}
            

</script>


