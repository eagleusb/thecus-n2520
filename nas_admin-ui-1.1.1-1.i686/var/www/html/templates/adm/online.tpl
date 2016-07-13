<div id='online_option'></div>
<br>
<div id="list" style="visibility:hidden;position:absolute;">
	<fieldset class="x-fieldset"><legend class="legend"><{$words.online_list}></legend>
  	<div id='news_list'></div>
	</fieldset>
</div>

<script type="text/javascript">
var type="<{$type}>",news_file;
var page_limit=<{$limit}>;
var online_des="<b><{$words.online_describe}></b><br><br>";
var option_des="<{$words.option_describe}><br>";
var tpl=new Ext.Template(online_des,option_des);

function ExtDestroy(){ 
 Ext.destroy(
            Ext.getCmp('store'),
            Ext.getCmp('pagingBar'),
            Ext.getCmp('tbar'),
            Ext.getCmp('news'),
            Ext.getCmp('grid'), 
            Ext.getCmp('plimit')
            );  
}


/*
* show news date and it's level .
* @param value - news date
* @returns none.
*/ 
function news_date(value,cellmata,record,rowIndex){
	str='<div id="date'+rowIndex+'">';
  switch(record.data['flag']){
    case "0":
    	str+='<span style="color:red">'+value+'</span>';
    	break;
    case "1":
    	str+='<span style="color:black">'+value+'</span>';
    	break;
    default:
    	str+='<span style="color:red">'+value+'</span>';
    	break;
  }
  str+='</div>';
  return str;
}

/*
* show news data and it's level .
* @param value - news data
* @returns none.
*/
function news_data(value,cellmata,record,rowIndex){
  var data_length=<{$news_length}>;
  var data_index=data_length;
  var row=Math.floor((value.length-1) / data_length)+1;
  var i,str,val='\'';//='String.format(\''
  var data_start=0;
  var news_val;

  value=value.replace(/\n/,'');
  new_val=value;
  
  str='<div id="msg'+rowIndex+'">';
  switch(record.data['flag']){
    case "0":
      str+='<span style="color:red">'+value+'</span>';
      break;
    case "1":
      str+='<span style="color:black">'+value+'</span>';
      break;
    default:
    	str+='<span style="color:red">'+value+'</span>';
      break;
  }
  str+='</div>';
  return str;
}

/*
* top bar handle , change news data show according to top bar element .
* @param value - top bar object
* @returns none.
*/
function info_data(value){
  store.load({params:{start:0, limit:page_limit, info_type:value.id}});    
  //tbar2.items.item('truncate').setText(truncates[value.id]);
  //tbar2.items.item('download').setText(downloads[value.id]);
  pagingBar.paramNames={start:'start', limit:'limit', info_type:value.id};
  info_type=value.id;
  news_file=value.tooltip;
}
 
/*
* top bar handle , download news file .
* @param value - top bar object
* @returns none.
*/ 
function download_news(value){
  window.open('/adm/getmain.php?fun=d_news&download_flag=1&info_type='+info_type+'&news_file='+news_file);
 // processAjax('getmain.php?fun=news&info_type='+info_type+"?news_file="+news_file+"?download_flag=1",ondownload());  
}
  
  
/*
* top bar handle , clear news file .
* @param value - top bar object
* @returns none.
*/ 
function truncate_news(value){
  Ext.Msg.confirm("<{$words.log_title}>","<{$gwords.confirm}>",function(btn){
  if(btn=='yes') 
  {
    store.load({params:{start:0, limit:page_limit, info_type:info_type , news_file:news_file , truncate_flag:1}});
  }})
}

// news data .
var store = new Ext.data.JsonStore({
  root: 'topics',
  totalProperty: 'totalcount',
  remoteSort: true,
  url:'<{$url}>',
  fields: ['flag','postdate','msg','download_url']
});
 
store.setDefaultSort('postdate', 'DESC');
      

//page toolbar
var pagingBar = new Ext.PagingToolbar({
  pageSize: page_limit,
  store: store,
  displayInfo: true,
  displayMsg: '<{$words.page_range}> {0} - {1} <{$gwords.page2}> {2}',
  emptyMsg: "<{$words.no_logs}>",
  beforePageText:"<{$gwords.page1}>",
  afterPageText:"<{$gwords.page2}> {0} <{$gwords.page3}> "
});

//top bar:all, info, warn, error
var tbar =new Ext.Toolbar({
  id:'bar',
  items :[{
           id:'all',
           text:'<{$gwords.all}>',
           tooltip:'all',
           iconCls:'add',
           handler:info_data
         }, '-',{
           id:'fw',
           text:'<{$gwords.firmware}>',
           tooltip:'information',
           iconCls:'info',
           handler:info_data
         }, '-', {
           id:'module',
           text:'<{$gwords.module}>',
           iconCls:'info',
           tooltip:'information',
           handler:info_data
         }/*,'-',{
           id:'error',
           text:'<{$gwords.error}>',
           iconCls:'error',
           tooltip:'error',
           handler:info_data
         }*/]
});

//log grid display
var news_grid = new Ext.grid.GridPanel({
	el:'news_list',
  id:'news',
  width:660,
  height:355,
  //autoHeight:true,
  store: store,
  trackMouseOver:true,
  disableSelection:true,
  loadMask: true,

 // grid columns
  columns:[{
             id: 'date', 
             header: "<{$words.publish_date}>",
             dataIndex: 'postdate',
             width: 130,
             renderer: news_date,
             menuDisabled:true,
             sortable: true
           },{
             id: 'data', 
             header: "<{$words.info_delivery}>",
             dataIndex: 'msg',
             width: 510,
             renderer: news_data,
             menuDisabled:true,
             sortable: false
          }],       
  tbar:tbar, 
  // paging bar on the bottom
  bbar: pagingBar,
  listeners:{
  	rowclick:function(gridObj,rowIndex,event){
  		var open_url=gridObj.getStore().getAt(rowIndex).get('download_url');
  		var postdate=gridObj.getStore().getAt(rowIndex).get('postdate');
  		var msg=gridObj.getStore().getAt(rowIndex).get('msg');
  		document.getElementById('date'+rowIndex).innerHTML=postdate;
  		document.getElementById('msg'+rowIndex).innerHTML=msg;
  		//alert (open_url);
  		processAjax('<{$setmain}>&postdate='+postdate,onLoadForm);
  		window.open(open_url);
  	}
  }
});

var setting_checkbox=new Ext.form.Checkbox({
	id:'_enabled',
	name:'_enabled',
	hideLabel:true,
	inputValue:'1',
	<{if $online_enabled=="1"}>
		checked:true,
	<{/if}>
	boxLabel:'<{$gwords.enable}>'
});

var hdd_checkbox=new Ext.form.Checkbox({
	id:'_send_hdd_info',
	name:'_send_hdd_info',
	hideLabel:true,
	inputValue:'1',
	<{if $online_send_hdd_info=="1"}>
		checked:true,
	<{/if}>
	boxLabel:"<{$words.online_hdd_info}>"
});

var timezone_checkbox=new Ext.form.Checkbox({
	id:'_send_timezone_info',
	name:'_send_timezone_info',
	hideLabel:true,
	inputValue:'1',
	<{if $online_send_timezone_info=="1"}>
		checked:true,
	<{/if}>
	boxLabel:"<{$twords.time_zone}>"
});

var apply_btn = new Ext.Button({
	id:'apply_btn',
	text:'<{$gwords.apply}>',
	border:false,
	handler:function(){
		//alert ("enabled= "+Ext.getDom('_enabled').checked);
		//alert ("hdd= "+Ext.getDom('_send_hdd_info').checked);
		
		//processAjax("<{$setmain}>",test,"&action=setoption&"+FormPanel_setting.getForm().getValues(true));
		processAjax("<{$setmain}>",onLoadForm,"&action=setoption&"+FormPanel_setting.getForm().getValues(true));
		//news_grid.render();
		store.load({params:{start:0, limit:page_limit}});
		if(!Ext.getDom('_enabled').checked){
			document.getElementById('list').style.visibility="hidden";
			document.getElementById('list').style.position="absolute";
		}else{
			document.getElementById('list').style.visibility="";
			document.getElementById('list').style.position="";
		}
		
		//processAjax("<{$form_action}>",gotoRaidInfo,"&action=create&"+RAIDFormPanel.getForm().getValues(true));
		//processAjax("<{$form_action}>",onLoadForm,"&action=create&"+RAIDFormPanel.getForm().getValues(true));
		//processAjax("<{$form_action}>",getlog,"&action=create&"+RAIDFormPanel.getForm().getValues(true));
	}
});

function test(){
	var request = eval('('+this.req.responseText+')');
	alert (this.req.responseText);
}

var FormPanel_setting = new Ext.FormPanel({	
	renderTo:'online_option',
	bodyStyle: 'background: transparent;',
    style: 'margin: 10px;',
	border: false,
	items:[
		setting_checkbox,
	{
		xtype:'label',
		id:'option_description',
		name:'option_description'
	},
		hdd_checkbox,
		timezone_checkbox,
		//news_grid,
		apply_btn
	]
});
tpl.append(document.getElementById('option_description'));
//#######################################
//#	render it
//#######################################
//alert ("enabled= "+Ext.getDom('_enabled').checked);
news_grid.render();
if(Ext.getDom('_enabled').checked){
	document.getElementById('list').style.visibility="";
	document.getElementById('list').style.position="";
}

//input page limit in per page
var plimit=new Ext.form.TextField({
  id:'plimit',
  width:40,
  value:page_limit,
  enableKeyEvents:true
});

plimit.on('specialkey', function(obj){        
  page_limit = eval(Math.floor(obj.getValue()));

  if(isFinite(page_limit) && page_limit > 0){
    pagingBar.pageSize =page_limit;
    store.load({params:{start:0, limit:page_limit, info_type:info_type}});
  }else{      
    Ext.Msg.alert('<{$words.log_title}>', '<{$words.page_error}>');  
    obj.setValue('');
  }  
});

//top bar 2: download, truncate, page limit input
/*
var tbar2= new Ext.Toolbar({
  renderTo:news.tbar,   
  items : [{
         id:'download',
         text:'<{$gwords.download_all_log}>',
         iconCls:'app',
         handler:download_news
       },'-',{
         id:'truncate',
         text:'<{$gwords.truncate_all}>',
         iconCls:'remove',
         handler:truncate_news
       },'-','<{$words.number_of_lines_per_page}>',
       plimit]
}); 
*/
  // trigger the data store load
store.load({params:{start:0, limit:page_limit}});
       
</script>
