<script type="text/javascript">
Ext.ns('TCode');

TCode.ModuleLogin = function (c) {
    var me = this,
        items = [],
        status = {},
        ajax = new TCode.ux.Ajax('setui_fun', <{$METHODS}>),
        word = <{$WORDS}>;
    
    var store = new Ext.data.JsonStore({
        fields: ['module', 'status']
    });
    
    c = Ext.apply(c || {}, {
        frame: false,
        disabled: true,
        hideHeaders: true,
        cls: 'TCode-ModuleLogin-Panel',
        disableSelection: true,
        viewConfig: {
            autoFill: true,
            forceFit: true
        },
        columns: [
            {
                dataIndex: 'module',
                width: 60
            },
            {
                dataIndex: 'status',
                width: 40,
                renderer: moduleStatusRender
            }
        ],
        store: store,
        buttons: [
            {
                text: word['apply'],
                handler: onApply
            }
        ],
        listeners: {
            render: onPanelReady,
            beforedestroy: onPnaelDestroy
        }
    });
    
    TCode.ModuleLogin.superclass.constructor.call(me, c);
    
    function onPanelReady() {
        ajax.on('getModuleStatus', onGetModuleStatus);
        ajax.getModuleStatus();
    }
    
    function onPnaelDestroy() {
        destroyItems();
        ajax.un('getModuleStatus', onGetModuleStatus);
        ajax = null;
        word = null;
        store = null;
        delete TCode.ModuleLogin;
    }
    
    function onGetModuleStatus(modules) {
        destroyItems();
        
        if (modules.length > 0) {
            me.setDisabled(false);
        }
        
        store.loadData(modules);
        modules = null;
    }
    
    function destroyItems() {
        while (items.length > 0) {
            (items.pop()).destroy();
        }
    }
    
    function moduleStatusRender(val, dom, rs) {
        var id = Ext.id();
        setTimeout(moduleStatusDeferRender.bind(me, id, rs), 100);
        return String.format('<div id="{0}"/>', id);
    }
    
    function moduleStatusDeferRender(id, rs) {
        items.push(new Ext.form.RadioGroup({
            renderTo: id,
            items: [
                {
                    name: id,
                    boxLabel: word['enable'],
                    checked: rs.data.status === true,
                    inputValue: 1
                },
                {
                    name: id,
                    boxLabel: word['disable'],
                    checked: rs.data.status === false,
                    inputValue: 0
                }
            ],
            listeners: {
                change: onModuleStatusChange.bind(me, rs.data.module)
            }
        }));
    }
    
    function onModuleStatusChange(module, _, val) {
        status[module] = (!!+val);
    }
    
    function onApply() {
        Ext.Msg.confirm(word['ui_fun'], word['confirm'], onConfirm);
    }
    
    function onConfirm(answer) {
        if (answer !== 'yes') {
            return;
        }
        ajax.setModuleStatus(status, onSetModuleStatus);
    }
    
    function onSetModuleStatus(result) {
        if (result) {
            status = {};
            Ext.Msg.alert(word['ui_fun'], word['ui_fun_success']);
        } else {
            ajax.getModuleStatus();
            Ext.Msg.alert(word['ui_fun'], word['setting_confirm']);
        }
    }
}
Ext.extend(TCode.ModuleLogin, Ext.grid.GridPanel);
Ext.reg('TCode.ModuleLogin', TCode.ModuleLogin);

Ext.onReady(function () {
    TCode.desktop.Group.add({
        xtype: 'TCode.ModuleLogin'
    });
});
</script>
