<{include file="adm/header.tpl"}>
<head>
    <link rel="shortcut icon" href="/theme/images/icons/browser.ico">
</head>

<div id="loading-mask" ></div>
<div id="loading"></div>
<!-- ** new module install window **-->
<div id="newmod-win" class="x-hidden"> 
    <div class="x-window-header"><{$mwords.title}></div>
    <div id="newmod-panel">  
        <div class="newmod_left">
            <img src='/theme/images/index/guide/install_guide.png'  /> 
        </div> 
        
        <div id="newmod-form-cd" class="newmod_form" style="display:none">  
            <img src="/theme/images/index/guide/fromCD.png" style="float:right"/><br><{$mwords.fromcd}><br> 
        </div>  
                
        <div id="newmod-form-detect" class="newmod_form" style="display:none">  
            <div align="center">
                <br><br>
                <img src="/theme/images/index/guide/fromInternet.png" /><br>
                <{$mwords.detect_internet}>
            </div>
        </div> 
        
        <div id="newmod-form-install" class="newmod_form" style="display:none">  
            <div id="newmod-form-install-list"></div>
            <{$mwords.install_info}>
        </div> 
        
        <div id="newmod-form-fail" class="newmod_form" style="display:none">   
            <{$mwords.detect_fail}>
        </div> 

        <div id="newmod-form-loading" class="newmod_form" style="display:none">  
            <div align="center">
                <br>
                <img src="/theme/images/index/guide/fromInternet.png" /><br><br>
                <div id="pbarInstall"></div>
                <span class="status" id="pbarInstalltext"></span>  
            </div> 
        </div> 
        
        <div id="newmod-form-success" class="newmod_form" style="display:none">   
            <{$mwords.success}>
        </div> 
        
        <div style="float:left;margin-left:15px" id="remind"><label><input type="checkbox" id="no_remind" /> <{$mwords.noremind}></label></div>
        <div style="clear:both"></div>
    </div> 
</div>

<div id="north"></div>
 
<!-- ** Manual Menu **-->
<div id="manual_menu" class="hidden" >
    <div id="manual_left">
        <div id="tab_global"  class="tab_gray" ><{$gwords.help_index}></div>
        <div id="tab_special" class="tab_white" ></div>
    </div>
    <div id="manual_right">
         <div id="manual_title">
            <table width="100%"><tr><td align="left"><span ><{$gwords.help}></span></td>
            <td align="right"><img id="manual_close" src="<{$urlimg}>/index/close.png" style="cursor:pointer"></td></tr></table>
            <div id="manual_search"><img src="/theme/images/index/tm_search.png" style="float:left;padding:0 20"/><input type="text" id="manual_txt" onkeyup="Manual.searchManual(this.value)" /></div>
        </div> 
        <div id="manual_content">
            <input type="hidden" name="tmp_link" id="tmp_link" value="" />
            <iframe src="/adm/manual.php" id="iframe_manual" frameborder="0"></iframe>
        </div> 
    </div> 
</div>

<input type='hidden' name='currentpage' id='currentpage' value='' />
<input type="hidden" id="ffKeyTrap">

<script type="text/javascript" src="<{$urlextjs}>adapter/ext/ext-base.js"></script>
<script type="text/javascript" src="<{$urlextjs}>ext-all.js"></script>
<script type="text/javascript" src="<{$urlextjs}>bubble.js"></script>
<script type="text/javascript" src="<{$urljs}>jquery.js"></script>
<script type="text/javascript" src="<{$urljs}>highcharts.js"></script>
<script type="text/javascript" src="<{$urljs}>plugins/TCode.ux.LargeButton.js"></script>
<script type="text/javascript" src="<{$urljs}>plugins/ip_utility.js"></script>
<script type="text/javascript" src="<{$urljs}>plugins/TCode.ux.Ajax.js"></script>
<script type="text/javascript" src="<{$urljs}>plugins/TCode.ux.Disk.js"></script>
<{include file="adm/vtype.tpl"}>
<script type="text/javascript">
<{$var_js}>
Ext.ns('TCode.ux');
TCode.ux.WORDS = <{$uxs}>;
var treeobj = <{$treeview_obj}>;
var treelog = <{$treelog}>;
var treenews = <{$treenews}>;
var treeraid = <{$treeraid}>;
var treedisks = <{$treedisks}>;
var treesystatus = <{$treesystatus}>;
var treeups = <{$treeups}>; 
var treereboot = <{$treereboot}>;
var treeshutdown = <{$treeshutdown}>;
var treeadmpwd = <{$treeadmpwd}>;
var role_tmp="<{$role_tmp}>";
var wait_msg='<{$gwords.wait_msg}>'; 
var logo_link='<{$logo_link}>';

// log data .
var Store_log = new Ext.data.JsonStore({
  root: 'topics', 
  url: '/adm/getmain.php?fun=indexnews' ,
  fields: ['postdate','title','logid']
 , listeners:{
    load:function(value,records, opt){ 
        var hidden = true;
        for( i = 0 ; i < records.length ; ++i ) {
            if(records[i].data.logid){
                hidden = false;
                break;
            }
        }
        if(records.length>0){
            GridPanel_log.getColumnModel().setHidden(2, hidden);
            if(hidden) {
                GridPanel_log.getColumnModel().setColumnWidth(1,460);
            } else {
                GridPanel_log.getColumnModel().setColumnWidth(1,410);
            }
            Window_log.show();
        }
    }
  }
}); 

var GridPanel_log = new Ext.grid.GridPanel({ 
   store: Store_log, 
    width: 600,  
    columns:[{
         id: 'date', 
         header: "<{$gwords.time}>",
         dataIndex: 'postdate',
         width: 140,  
         sortable: true
       },{
         id: 'log', 
         header: "<{$gwords.description}>",
         dataIndex: 'title',
         width: 410, 
         sortable: true
      },{
         id: 'logicon', 
         header: "<{$gwords.help}>",  
          width: 40 ,
         dataIndex: 'logid',
          renderer:  function(logid,obj,thisobj) {
            if(logid){ 
                return String.format('<a href="javascript:void(0);" onmousedown="Manual.showMenu();Manual.set(2,\'{0}\');"><img src=\"/theme/images/index/header_icon/gotohelp.png\" style="float:left" /></a>',logid);
            
            }
          } 
      }]
       
});

var Window_log = new Ext.Window({ 
    modal:true,
    closable:false, 
    width: 615, 
    height:400,   
    layout: 'fit',
    title:"<{$gwords.error}> <{$gwords.top_log}>" ,
    autoScroll : true   
    ,items: GridPanel_log,
    buttonAlign:'right',
    buttons: [{ 
                text:'Review', 
                handler: function(){
                    processAjax("getmain.php?fun=indexnews",'',"name=cleanlog",false);
                    Window_log.hide();
                }
             },{
                text: 'Close',
                handler: function(){
                    Window_log.hide();
                }
             }] 
});
<{include file="adm/init.tpl"}>
<{include file="adm/modupgrade.tpl"}>
Ext.onReady(function(){
      /**************************************************************
                                   Layout
      **************************************************************/
    var upgrade_list = <{$upgrade_list}>;
    Ext.QuickTips.init();
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
                //listeners: {
                //    render: function (ct) {
                //        ct.el.on('click', function () {
                //                window.open(logo_link, "producer");
                //            });
                //    }
                //},
                items: [
                    {
                        xtype: 'toolbar',
                        frame: false,
                        cls: 't-ctl-bar',
                        items: [
                            '->',
                            {
                                id: 'nasapp_upgrade_btn',
                                xtype :'box',
                                cls: 't-nasapp-upgrade',
                                hidden: true,
                                autoEl: {
                                    tag: 'div',
                                    'ext:qtip': '<{$words.upgradable}>'
                                },
                                listeners: {
                                    render: function (ct) {
                                        ct.el.on('click', function () {
                                            processUpdater('getmain.php', 'fun=nasapp');
                                        });
                                        for (var i = 0 ; i < upgrade_list.length ; ++i) {
                                            if (upgrade_list[i].status === 'update') {
                                                ct.show();
                                                break;
                                            }
                                        }
                                    }
                                }
                            },
                            //{
                            //    id: 'news_btn',
                            //    xtype :'box',
                            //    cls: 't-news-zero',
                            //    autoEl: {
                            //        tag: 'div',
                            //        'ext:qtip': '<{$words.tree_online}>',
                            //        onclick: 'TreeMenu.setCurrentPage(treenews[0]);'
                            //    }
                            //},
                            {
                                id: 'log_btn',
                                xtype: 'box',
                                cls: 't-log-zero',
                                autoEl: {
                                    tag: 'div',
                                    'ext:qtip': '<{$words.tree_logs}>',
                                    onclick: 'TreeMenu.setCurrentPage(treelog[0]);'
                                }
                            },
                            {
                                id: 'manual',
                                xtype: 'box',
                                cls: 't-help-btn',
                                autoEl: {
                                    tag: 'div',
                                    'ext:qtip': '<{$gwords.help}>',
                                    onclick: 'Manual.showMenu();'
                                }
                            },
                            {
                                text: 'Admin',
                                cls: 't-admin-btn',
                                menu: {
                                    xtype: 'menu',
                                    cls: 't-menu',
                                    items: [
                                        {
                                            text: '<{$gwords.change_pwd}>',
                                            handler: function() {
                                                TreeMenu.setCurrentPage(treeadmpwd[0]);
                                            }
                                        },
                                        {
                                            text: '<{$gwords.language}>',
                                            menu: {
                                                xtype: 'menu',
                                                cls: 't-menu',
                                                items: (function() {
                                                    var lang = <{$combo_lang}>;
                                                    var submenu = [];
                                                    for( var i = 0 ; i < lang.length ; ++i ) {
                                                        submenu.push({
                                                            text: lang[i][1],
                                                            metadata: lang[i][0],
                                                            handler: function() {
                                                                language_jumpMenu('<{$index_php}>', this.metadata);
                                                            }
                                                        })
                                                    }
                                                    return submenu;
                                                })()
                                            }
                                        },
                                        {
                                            text: '<{$FWPRODUCER}> <{$FWTYPE}> <{$FW_VERSION}>',
                                            disabledClass: 't-item-disabled',
                                            disabled: true
                                        },
                                        {
                                            text: '<{$gwords.logout}>',
                                            handler: doLogout
                                        }
                                    ]
                                }
                            }
                        ]
                    },
                    {
                        xtype: 'toolbar',
                        frame: false,
                        height: 40,
                        border: false,
                        cls: 't-nav-bar',
                        items: [
                            {
                                xtype: 'panel',
                                cls: 't-nav-home',
                                items: {
                                    xtype: 'box',
                                    autoEl: {
                                        tag: 'div',
                                        html: '<div class="t-nav-home-icon"/>',
                                        onclick: 'TCode.desktop.Group.popupGroup();'
                                    }
                                }
                            },
                            {
                                id: 'nav',
                                xtype: 'box',
                                cls: 't-nav-index',
                                autoEl: {
                                    tag: 'span'
                                }
                            },
                            '->',
                            {
                                id: 'searchtxt',
                                xtype: 'textfield',
                                cls: 't-search',
                                emptyText: '<{$gwords.search_string}>',
                                enableKeyEvents: true,
                                listeners: {
                                    keydown: function(field, event) {
                                        if (TreeMenu.delay_search) {
                                            clearTimeout(delay_search);
                                        }
                                        delay_search = setTimeout(function() {
                                            TreeMenu.search(field.getValue());
                                            delete TreeMenu.delay_search;
                                        }, 1000);
                                    }
                                }
                            },
                            {
                                xtype: 'box',
                                autoEl: {
                                    tag: 'span',
                                    style: 'padding-right: 10px;'
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
                height: 40,
                items: [
                    {
                        text: '<{$FWTYPE}>',
                        cls: 't-power-btn',
                        menu: {
                            xtyle: 'menu',
                            cls: 't-menu',
                            items: [
                                {
                                    text: '<{$gwords.reboot}>',
                                    cls: 't-reboot-btn',
                                    handler: function () {
                                        TreeMenu.setCurrentPage(treereboot[0]);
                                    }
                                },
                                {
                                    text: '<{$gwords.shutdown}>',
                                    cls: 't-shutdown-btn',
                                    handler: function () {
                                        TreeMenu.setCurrentPage(treeshutdown[0]);
                                    }
                                }
                            ]
                        }
                    },
                    '->',
                    {
                        xtype: 'box',
                        id: 't-raid-status',
                        cls: 't-raid-status',
                        autoEl: {
                            tag: 'div',
                            'ext:qtip': '<{$rwords.Raid_info}>',
                            'ext:trackMouse': true,
                            'ext:qalign': 'b-t?',
                            onclick: 'javascript:TreeMenu.setCurrentPage(treeraid[0]);'
                        }
                    },
                    {
                        xtype: 'box',
                        id: 't-disk-status',
                        cls: 't-disk-status',
                        autoEl: {
                            tag: 'div',
                            'ext:qtip': '<{$dwords.disk_title}>',
                            'ext:trackMouse': true,
                            'ext:qalign': 'b-t?',
                            onclick: 'javascript:TreeMenu.setCurrentPage(treedisks[0]);'
                        }
                    },
                    {
                        xtype: 'box',
                        id: 't-fan-status',
                        cls: 't-fan-status',
                        autoEl: {
                            tag: 'div',
                            'ext:qtip': '<{$gwords.fan}>',
                            'ext:trackMouse': true,
                            'ext:qalign': 'b-t?',
                            onclick: 'javascript:TreeMenu.setCurrentPage(treesystatus[0]);'
                        }
                    },
                    {
                        xtype: 'box',
                        id: 't-temp-status',
                        cls: 't-temp-status',
                        autoEl: {
                            tag: 'div',
                            'ext:qtip': '<{$gwords.temperature}>',
                            'ext:trackMouse': true,
                            'ext:qalign': 'b-t?',
                            onclick: 'javascript:TreeMenu.setCurrentPage(treesystatus[0]);'
                        }
                    },
                    {
                        xtype: 'box',
                        id: 't-net-status',
                        cls: 't-net-status',
                        autoEl: {
                            tag: 'div',
                            'ext:qtip': '<{$words.tree_network}>',
                            'ext:trackMouse': true,
                            'ext:qalign': 'b-t?'
                        }
                    },
                    {
                        xtype: 'box',
                        id: 't-ups-status',
                        cls: 't-ups-status',
                        autoEl: {
                            tag: 'div',
                            'ext:qtip': 'UPS',
                            'ext:trackMouse': true,
                            'ext:qalign': 'b-t?',
                            onclick: 'javascript:TreeMenu.setCurrentPage(treeups?treeups[0]:0);'
                        }
                    }
                ]
            }
        ]
    });

    if ("<{$run_init}>" == "0") {
        runInitWizard();
    } 
    Store_log.load({params:{name:"popuplog"}});
}); 

function doLogout(){
      Ext.Msg.confirm('<{$gwords.logout}>', "<{$words.logoutMsg}>" , function(btn){ 
                    if(btn=='yes'){
                        location.href='<{$logout_php}>'; 
                    }
      });
}

function changePageModule(id){ 
    processUpdater('<{$getmain_php}>','module='+id);
}

</script> 
<!--
    Reorder javascript source code index
!-->
<script type="text/javascript" src="<{$urlextjs}>SliderTip.js?<{$randValue}>?<{$randValue}>"></script>
<script type="text/javascript" src="<{$urlextjs}>MessageBox.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urlextjs}>LoadMask.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>net.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>treemenu.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>manual.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>shortcut.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>FileUploadField.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>ColumnNodeUI.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>wizard.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>HA.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>plugins/Ext.ux.FileManager.js?<{$randValue}>" ></script>
<script type="text/javascript" src="<{$urljs}>main.js?<{$randValue}>" ></script>
