<div id="Container"></div>

<script type="text/javascript">

Ext.namespace("TCode.HWCtrl");

var gpio = <{$gpio}>;

TCode.HWCtrl = {
    init: function(){
        Ext.QuickTips.init();
        Ext.form.Field.prototype.msgTarget = 'side';
        var fieldset = new Ext.form.FieldSet({
            title:"<{$words.title}>",
            width:300,
            autoHeight:true,
            buttonAlign:'left',
            buttons:[
                {text:"<{$gwords.apply}>", type:'submit', handler: function(){
                    Ext.getCmp('form').form.submit({
                        url:'/adm/setmain.php?fun=sethwctrl',
                        success:function(res){
                            Ext.Msg.show({
                                title:"<{$words.title}>",
                                msg:"<{$words.success}>",
                                icon:Ext.MessageBox.INFO,
                                buttons:Ext.MessageBox.OK
                            })
                        }
                    });
                }}
            ]
        });
        var form = new Ext.form.FormPanel({
            id:'form',
            renderTo:'Container',
            style: 'margin: 10px;',
            items:[fieldset],
            width:300,
            height:330
        });
        
        for(var i=0; i<gpio.length; i++){
           var radio = new Ext.form.RadioGroup({
                fieldLabel:"<{$words.gpio}>"+gpio[i].id,
                items:[
                    {boxLabel:"<{$words.input}>", inputValue:0 , name:'gpio'+(i+1)},
                    {boxLabel:"<{$words.output}>", inputValue:1, name:'gpio'+(i+1)}
                ]
            });
            radio.setValue(gpio[i].define);
            fieldset.add(radio);
        }
        form.doLayout();
    }
}

Ext.onReady(TCode.HWCtrl.init, TCode.HWCtrl);
</script>
