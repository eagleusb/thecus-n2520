<div id="DLNAform"></div> 
<style type="text/css" media="all">
.x-btn td.x-btn-left, .x-btn td.x-btn-right {padding: 0; font-size: 1px; line-height: 1px;}
.x-btn td.x-btn-center {padding:0 5px; vertical-align: middle;}
</style>

<script language="javascript"> 
var oginalDLNA_status = '<{$DLNA_Status}>';
var dynamicDLNA_status = '<{$DLNA_Status}>';

if (oginalDLNA_status=='1')
{
    oginalDLNA_status=true;
    dynamicDLNA_status=true;
}
else
{
    oginalDLNA_status=false;
    dynamicDLNA_status=false;
}

function ExtDestroy(){ 
    Ext.destroy(
        Ext.getCmp('firstGridDropTarget'),
        Ext.getCmp('destGridDropTarget')
    );  
}

var folderData = <{$folderStore}>;

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
    
//this can immediately update the data of the grid's store
function returnDLNAData(){
    var request = eval('('+this.req.responseText+')');

    returnDLNA = request.folderData;
    
    //read the new data of module, put data into the array. 
    if (returnDLNA.length > 0)
    {
       var folderData2 = new Array();
       folderData2 = returnDLNA.split(",");
        
       var folderData3 = new Array();
       for (i=0; i<(folderData2.length/4); i++)
       {
           folderData3[i] = new Array(folderData2[i*4], folderData2[i*4+1], folderData2[i*4+2], folderData2[i*4+3]);
           //alert(folderData2[i*3]);
       }

       store.loadData(folderData3);
    }        
    else
        store.loadData('');
    
    folderData = folderData3;
    msg('<{$words.DLNA_title}>', request.msgStr);
};


    
Ext.state.Manager.setProvider(new Ext.state.CookieProvider());
  
// create the data store
var store = new Ext.data.SimpleStore({
    fields: [
       {name: 'existFolder', type: 'bool'},
       {name: 'folderName', type: 'string'},
       {name: 'sharedFolder', type: 'string'},
       {name: 'sharedID', type: 'string'}
    ]
});
store.loadData(folderData);

Ext.grid.CheckColumn = function(config){
    Ext.apply(this, config);
    if(!this.id){
        this.id = Ext.id();
    }
    this.renderer = this.renderer.createDelegate(this);
};

function rescan(folderName, sharedID){
    myMask.hide();

    if ((oginalDLNA_status == true) && (dynamicDLNA_status == true))
    {           
        var fp=Ext.getCmp("fpDLNA");
        var targetphp = "setmain.php?fun=setDLNA&folder=" + encodeURI(folderName) + "&folderAction=2" + "&sharedID=" + sharedID;
        processAjax(targetphp,returnDLNAData,fp.getForm().getValues(true));
    }
}             
    
Ext.grid.CheckColumn.prototype ={
    init : function(grid){
        this.grid = grid;
        this.grid.on('render', function(){
            var view = this.grid.getView();
            view.mainBody.on('mousedown', this.onMouseDown, this);
        }, this);
    },

    onMouseDown : function(e, t){
        if(t.className && t.className.indexOf('x-grid3-cc-'+this.id) != -1){

            e.stopEvent();

            var index = this.grid.getView().findRowIndex(t);

            var record = this.grid.store.getAt(index);
            //record.set(this.dataIndex, !record.data[this.dataIndex]);
            
            if ((oginalDLNA_status == true) && (dynamicDLNA_status == true))
            {           
                var fp=Ext.getCmp("fpDLNA");
               //when we click the checkbox, the status of the checkbox should be different with the store 
                if (!record.get('existFolder'))
                {
                    var targetphp = "setmain.php?fun=setDLNA&folder=" + encodeURI(record.get('sharedFolder')) + "&folderAction=1";
                    processAjax(targetphp,returnDLNAData,fp.getForm().getValues(true));
                }
                else
                {
                    var targetphp = "setmain.php?fun=setDLNA&folder=" + encodeURI(record.get('sharedFolder')) + "&folderAction=0" + "&sharedID=" + record.get('sharedID');
                    processAjax(targetphp,returnDLNAData,fp.getForm().getValues(true));
                }

            }
        }
    },

    renderer : function(v, p, record){
        p.css += ' x-grid3-check-col-td'; 
        return '<div class="x-grid3-check-col'+(v?'-on':'')+' x-grid3-cc-'+this.id+'"></div>';
    }
};

    // custom column plugin example
    var checkColumn = new Ext.grid.CheckColumn({
       header: "",
       dataIndex: 'existFolder',
       width: 20
    });

    // create the Grid
    var grid = new Ext.grid.GridPanel({
        store: store,
        //name: 'xxxDLNAgrid',
        //id: 'xxxDLNAgrid',   
        //disabled: true,
        hideHeaders : false, 
        hideable: true, 
        width:660,
        height:390,
        trackMouseOver:false,
        disableSelection:true,
        enableHdMenu: false, 
        loadMask: true,        
        columns: [
            checkColumn,
            {id:'folderName',header: '<{$words.share_me}>', hidden:false, width: 160, sortable: false, dataIndex: 'folderName'},
            {id:'sharedFolder', header: "", hidden:true, width: 160, sortable: false, dataIndex: 'sharedFolder'},
            {id:'sharedID',header: "sharedID", hidden:true, width: 160, sortable: false, dataIndex: 'sharedID'},
            {header: '<{$gwords.action}>', hidden:false, dataIndex: '', id: 'info', width: 100, renderer:  function(c,f,g) {
				var id = "_" +g.data['folderName']; 
				var xid = id + "_";

                if (g.data['existFolder'] == true)
                {
                    return String.format('<a href="javascript:void(0);" onclick="javascript:myMask.show();rescan(\'{0}\',\'{1}\');"><img src="<{$urlimg}>/default/grid/refresh.gif" align="absmiddle">&nbsp;{2}</a>',g.data['sharedFolder'], g.data['sharedID'], '<{$gwords.rescan}>');                
                }
                
			}}            
        ],
        //stripeRows: true,
        autoExpandColumn: 'folderName',
        height:350,
        width:400,
        //frame:true,
        plugins:checkColumn,
        iconCls:'icon-grid',
        title:''
    });

    var media_server_radiogroup = new Ext.form.RadioGroup({
        xtype: 'radiogroup',
        width:200,
        fieldLabel: '<{$words.media_server}>',
        //hideLabel: true,
        //listeners: {change:{fn:function(){alert('radio changed');}}},
        items: [
            {boxLabel: '<{$gwords.enable}>', name: '_server', inputValue: '1' <{if $DLNA_Status == '1'}>, checked:true <{/if}>},
            {boxLabel: '<{$gwords.disable}>', name: '_server', inputValue: '0' <{if $DLNA_Status == '0'}>, checked:true <{/if}>}
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
        });
    };

Ext.onReady(function(){
    Ext.QuickTips.init();

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';
    
    var MS_enable = new Ext.form.Hidden({id: 'ms_enable', name: 'ms_enable', value: '0'});

    var fp = new Ext.FormPanel({
        //frame: true,
        labelWidth: 150,
        id: 'fpDLNA',
        width: 'auto',
        renderTo:'DLNAform',
        style: 'margin: 10px;',
        
        items: [{
            layout: 'column',
            border: false,
            defaults: {
                columnWidth: '.5',
                border: false
            }
            },
            MS_enable,
        {
            xtype:'fieldset',
            title: '<{$words.DLNA_title}>',
            autoHeight: true,
            buttonAlign: 'left',
            layout: 'form',
            items: [
                media_server_radiogroup,
                {
                    xtype: 'button',
                    text: '<{$gwords.apply}>',
                    handler: function(){
                        if(fp.getForm().isValid()){
                            //if the radio change, then the button can be used 
                            if (oginalDLNA_status != dynamicDLNA_status)
                            {                            
                                MS_enable.setValue('1');
                            
                                Ext.Msg.confirm('<{$words.DLNA_title}>',"<{$gwords.confirm}>",function(btn){
                                    if(btn=='yes'){
                                        oginalDLNA_status = !oginalDLNA_status;
                                        
                                        if (dynamicDLNA_status==0)
                                            processAjax('<{$form_action"}>',returnDLNAData,fp.getForm().getValues(true));
                                        else  if (dynamicDLNA_status==1)
                                            processAjax('<{$form_action"}>',returnDLNAData,fp.getForm().getValues(true));

                                        MS_enable.setValue('0');

                                        if (oginalDLNA_status)
                                        {
                                            //alert(oginalDLNA_status);
                                            var btnArray=Ext.DomQuery.select("[class='x-btn-text btn_fresh']");

                                            Ext.each(btnArray, function(obj) {
                                                obj.disabled = false;
                                            });

                                        }
                     			    }
                                })
                            } 
                            else
                                msg('<{$words.DLNA_title}>', '<{$gwords.setting_confirm}>');             
                        }
                    }                  
                }]    
        },
        {
            xtype:'fieldset',
            title: '<{$words.share_me}>',
            id: 'DLNAField',
            name: 'DLNAField',
            autoHeight: true,
            layout: 'form',
            items: [
                grid
            ]
        }]
    });  

	media_server_radiogroup.on('change',function(RadioGroup,newValue){
        dynamicDLNA_status = !dynamicDLNA_status;

	    if (oginalDLNA_status == true)
	    {
            var btnArray=Ext.DomQuery.select("[class='x-btn-text btn_fresh']");

            if (newValue == '1')
            {
                //set DLNAField disabled to false, but buttons still can be click
                //we must use Ext.DomQuery.select to enable each button
                //Ext.getDom("DLNAField").disabled=false;

                Ext.each(btnArray, function(obj) {
                    obj.disabled = false;
                });
	   		}
            else
            {
                //set DLNAField disabled to true, but buttons still can be click
                //we must use Ext.DomQuery.select to disable each button
		  	    //Ext.getDom("DLNAField").disabled=true;

                Ext.each(btnArray, function(obj) {
                    obj.disabled = true;
                });
	   		}
	   	}
    });
});

</script>
