<div id='DOMDataGuard'/>
<script type='text/javascript'>

Ext.ns('TCode.DataGuard');
WORDS = <{$Words}>;
MINES = <{$Mines}>;
TCode.DataGuard.iScsi = <{$iSCSI}>;
TCode.DataGuard.Ajax = new TCode.ux.Ajax('setdataguard', <{$Procs}>);
TCode.DataGuard.Ajax.timeout = 100000;

TCode.DataGuard.Error = {
    alert: function(code, data) {
        code = code.toString(16).toUpperCase();
        code = code.length == 8 ? '0x' + code : '0x0' + code;
        if( WORDS[code] ) {
            Ext.MessageBox.alert(WORDS['attention'], WORDS[code]);
        } else {
            var content = String.format('{0}({1})', WORDS['unknow'], code);
            Ext.MessageBox.alert(WORDS['attention'], content);
        }
    },
    format: function(code, data) {
        code = code.toString(16).toUpperCase();
        code = code.length == 8 ? '0x' + code : '0x0' + code;
        if( WORDS[code] ) {
            return WORDS[code];
        } else {
            return String.format('{0}({1})', WORDS['unknow'], code);
        }
    }
}

<{include file="adm/dataguard_data.js.tpl"}>
<{include file="adm/dataguard_folder_grid.js.tpl"}>
<{include file="adm/dataguard_wizard.js.tpl"}>
<{include file="adm/dataguard_main.js.tpl"}>

</script>
