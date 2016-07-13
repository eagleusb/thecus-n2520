<!DOCTYPE html>
<html>
    <head>
        <title></title>
        <meta http-equiv="X-UA-Compatible" content="IE=EmulateIE7">
        <meta http-equiv="X-UA-Compatible" content="chrome=1"/>
        <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
        <link rel="stylesheet" type="text/css" href="/theme/css/ext-all.css" />
    </head>
    <body></body>
</html>
<script type="text/javascript" src="/extjs/adapter/ext/ext-base.js"></script>
<script type="text/javascript" src="/extjs/ext-all.js"></script>
<script type="text/javascript">

String.prototype.capitalize = function () {
    return this.replace(
        /^./,
        function(m){ return m.toUpperCase() }
    );
}

Ext.onReady(function () {
    var MODULE = {
        piczza: '/modules/Piczza/www/index.php',
        webdisk: '/modules/WebDisk/www/index.php'
    };
    
    var module = String.prototype.toLowerCase.call('<?=$_GET['module'];?>');
    
    document.title = module.capitalize();
    
    new Ext.Viewport({
        renderTo: Ext.getBody()
    });
    
    var form = {},
        loginWindow = new Ext.Window({
            shadow: false,
            closable: false,
            draggable: false,
            resizable: false,
            border: false,
            plain: true,
            layout: 'form',
            autoWidth: true,
            autoHeight: true,
            frame: false,
            defaults: {
                listeners: {
                    render: ctRender
                }
            },
            items: [
                {
                    cid: 'username',
                    xtype: 'textfield',
                    fieldLabel: 'User ID'
                },
                {
                    cid: 'password',
                    xtype: 'textfield',
                    fieldLabel: 'Password',
                    inputType: 'password'
                }
            ],
            buttons: [
                {
                    text: 'Login',
                    handler: onLoginCheck
                }
            ]
        });
    
    if (MODULE[module]) {
        loginWindow.show();
    }
    
    function ctRender(ct) {
        form[ct.cid] = ct;
    }
    
    function onLoginCheck() {
        loginWindow.hide();
        Ext.Ajax.request({
            url: '/adm/login.php',
            params: {
                username: form.username.getValue(),
                pwd: form.password.getValue(),
            },
            success: onLoginCheckSuccess,
            failure: onLoginCheckFailure
        });
    }
    
    function onLoginCheckSuccess(response) {
        try {
            var result = JSON.parse(response.responseText);
            if (result.success) {
                if (typeof standby === 'function'){
                    standby(module);
                }
                fullscreen();
                window.location = MODULE[module];
            } else {
                loginWindow.show();
                Ext.MessageBox.alert(
                    result.errormsg.title,
                    result.errormsg.msg
                );
            }
        } catch(e) {window.location.reload();}
    }
    
    function onLoginCheckFailure() {
        window.location.reload()
    }
});
</script>