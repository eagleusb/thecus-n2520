<{include file="adm/header.tpl"}>
<script type="text/javascript" src="<{$urlextjs}>adapter/ext/ext-base.js"></script>
<script type="text/javascript" src="<{$urlextjs}>ext-all.js"></script>
<script>

Ext.onReady(function(){
    function redirecturl(){
        location.href='/adm/logout.php';
    }
    Ext.Msg.alert('<{$gwords.info}>','<{$gwords.permission_warning}>',redirecturl);
})
</script>