'use strict';

Ext.onReady(function () {
    //new Nas.desktop.Container();
    new Nas.desktop.Login();
});

Ext.define('Nas.desktop.Container', {
    extend: 'Ext.container.Viewport',
    constructor: function () {
        var self = this;
        
        var config = {
            layout: 'card',
            frame: false,
            border: false,
            autoScroll: false,
            activeItem: 0,
            items: [
                {
                    xtype: 'Nas.desktop.Workspace'
                }
            ]
        };
        
        self.superclass.constructor.call(self, config);
    }
});

Ext.define('Nas.desktop.Login', {
    extend: 'Ext.window.Window',
    alias: 'widget.Nas.desktop.Login',
    constructor: function() {
        var self = this;
        
        var config = {
            plain: true,
            resizable: false,
            draggable: false,
            closable: false,
            frame: false,
            border: false,
            shadow: false,
            defaults: {
                listeners: {
                    boxready: addVariableLink
                }
            },
            items: [
                {
                    xtype: 'textfield',
                    fieldLabel: 'Account',
                    variable: 'account'
                },
                {
                    xtype: 'textfield',
                    fieldLabel: 'Password',
                    inputType: 'password',
                    variable: 'password'
                }
            ],
            buttons: [
                {
                    text: 'Login',
                    handler: authAccountPassword
                }
            ]
        };
        
        self.superclass.constructor.call(self, config);
        
        var ui = {};
        function addVariableLink(ct) {
            ui[ct.initialConfig.variable] = ct;
        }
        
        function authAccountPassword() {
            Nasd.auth(
                ui.account.getValue(),
                ui.password.getValue(),
                onNasdAuthResult
            );
        }
        
        function onNasdAuthResult(success) {
            if (success) {
                new Nas.desktop.Container();
                self.close();
            } else {
                ui.password.reset();
            }
        }
        
        self.show();
    }
});

Ext.define('Nas.desktop.Workspace', {
    extend: 'Ext.panel.Panel',
    alias: 'widget.Nas.desktop.Workspace',
    constructor: function() {
        var self = this;
        
        var config = {
            defaults: {
                listeners: {
                    boxready: addVariableLink
                }
            },
            dockedItems: {
                xtype: 'toolbar',
                dock: 'top',
                variable: 'taskbar',
                items: [
                    {
                        text: 'Start',
                        handler: onClickStart
                    },
                    '-',
                    '->',
                    '-',
                    {
                        text: 'Noti'
                    }
                ],
                listeners: {
                    boxready: addVariableLink
                }
            }
        };
        
        self.superclass.constructor.call(self, config);
        
        var ui = {};
        function addVariableLink(ct) {
            ui[ct.initialConfig.variable] = ct;
        }
        
        function onClickStart() {
            Nas.desktop.SystemMenu.show();
            Nas.desktop.SystemMenu.alignTo(ui.taskbar.el, 'bl-tl?');
        }
    }
});

Ext.define('Nas.desktop.SystemMenu', {
    singleton: true,
    extend: 'Ext.window.Window',
    alias: 'widget.Nas.desktop.SystemMenu',
    constructor: function() {
        var self = this;
        console.info(window.location);
        var config = {
            width: 400,
            height: 500,
            plain: true,
            resizable: false,
            draggable: false,
            closable: false,
            frame: false,
            border: false,
            shadow: false,
            listeners: {
                deactivate: onDeactivate
            }
        };
        
        self.superclass.constructor.call(self, config);
        
        function onDeactivate() {
            self.hide();
        }
    }
});
