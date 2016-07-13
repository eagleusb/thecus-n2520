<fieldset class="x-fieldset" style="margin: 10px;"><legend class="legend"><{$words.facdf_title}></legend>
<center>
<div class="step_desp"><{$words.facdf_description}></div>
<div id="mainDiv1" style="display:none;padding: 10px 20px;">
</div>
<div id="mainDiv2" style="display:none;padding: 0px 0px;">
<table>
    <tr>
        <td><{$words.defaultSuccess}></td>
    </tr>
    <tr>
        <td><{$gwords.ip}> : <{$default_ip}></td>
    </tr>
    <tr>
        <td><{$gwords.password}> : admin</td>
    </tr>
</table>
</div>
</center>
</fieldset>

<script type="text/javascript">
var defaultIP="<{$default_ip}>";
var lan_interface="<{$interface}>";
	
function doSubmit(){
	Ext.Msg.confirm("<{$words.settingTitle}>", "<{$words.warning}>", function(btn){
	    if (btn == 'yes'){
	        clearTimeout(monitor);
            processAjax('setmain.php?fun=setfacdf',onLoadForm);
	        Ext.get("mainDiv1").enableDisplayMode('none');
    		Ext.get("mainDiv1").hide();
		Ext.get("mainDiv2").enableDisplayMode('inline');
		Ext.get("mainDiv2").show();
	    }
	});
}

var stateIP
if (defaultIP === "DHCP") {
	//stateIP = "<{$words.desc2}>";
	stateIP = '<{$words.default_ip}>' + " " + lan_interface.toUpperCase() + " " + defaultIP;
}else{
	stateIP = '<{$words.default_ip}>' + " " + lan_interface.toUpperCase() + " " + defaultIP;
}

 var desc = String.format(
		'<p align="left">{0}</p><br><li>{1}</li><li>{2}</li><li>{3}</li>',
        '<{$words.desc1}>',
		stateIP,
		'<{$words.desc3}>',
		'<{$words.desc4}>'
    );

Ext.onReady(function(){

    var rebootpanel1 = new Ext.FormPanel({
 	id:'facdfform',
 	renderTo: Ext.get(mainDiv1),
 	buttonAlign: 'left',
	items: [{
				xtype:'label',
				html: desc
		   }],
        buttons : [{
						text : '<{$gwords.apply}>',
						disabled : false,
						handler : function() {
							doSubmit();
						}
	              }]
    });

	Ext.get("mainDiv1").enableDisplayMode('inline');
    Ext.get("mainDiv1").show();
    Ext.get("mainDiv2").enableDisplayMode('none');
    Ext.get("mainDiv2").hide();
});
</script>

