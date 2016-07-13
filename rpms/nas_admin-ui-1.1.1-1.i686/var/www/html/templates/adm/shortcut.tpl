<div id="DOMDesktop"></div>
<script type="text/javascript">
Ext.ns('TCode.desktop');
WORDS = <{$words}>;

TCode.desktop.Group = function(categroup) {
    var self = this,
        pre, next,
        catename = {},
        categroup = categroup || [],
        _ghost = self.ghost,
        menu = new Ext.menu.Menu({
            cls: 't-menu',
            items: [
                {
                    text: WORDS.add_shortcut,
                    icon: '/theme/images/shortcut/sc_add.png',
                    handler: onAdd
                }
            ]
        }),
        config = {
            width: 800,
            height: 555,
            plain: true,
            shadow: false,
            border: false,
            activeItem: 0,
            layout: 'card',
            resizable: false,
            cls: 't-group-win',
            closeAction: 'hide',
            defaults: {
                frame: false,
                border: false
            },
            items: [
                {
                    xtype: 'dataview',
                    multiSelect: false,
                    cls: 'shortcut-group-view',
                    autoScroll: true,
                    store: new Ext.data.JsonStore({fields:[],data:categroup}),
                    itemSelector: 'div.scitem_small',
                    tpl: new Ext.XTemplate(
                        '{[this.groupRender()]}',
                        {groupRender: groupRender}
                    ),
                    listeners: {
                        contextmenu: onContextmenu,
                        click: onClick
                    }
                },
                {
                    xtype: 'panel',
                    layout: 'fit',
                    autoScroll: true,
                    listeners: {
                        render: onAppPanelRener
                    }
                }
            ],
            listeners: {
                render: onWindowRender,
                move: onMove
            }
        };
    
    self.current;
    
    function onWindowRender() {
        pre = new Ext.BoxComponent({
            renderTo: self.header.id,
            disabled: true,
            cls: 'shortcut-pre-btn',
            autoEl: {
                tag: 'div'
            },
            listeners: {
                render: function (ct) {
                    ct.el.on('click', function () {
                        pre.setDisabled(true);
                        next.setDisabled(!self.current);
                        popupGroup(categroup[0].catename);
                    });
                }
            }
        });
        next = new Ext.BoxComponent({
            renderTo: self.header.id,
            disabled: true,
            cls: 'shortcut-next-btn',
            autoEl: {
                tag: 'div'
            },
            listeners: {
                render: function (ct) {
                    ct.el.on('click', function () {
                        pre.setDisabled(false);
                        next.setDisabled(true);
                        self.layout.setActiveItem(1);
                        self.setTitle(self.current.treename);
                    });
                }
            }
        });
    }
    
    function groupRender() {
        var html = [];
        
        for (var i = 1 ; i < categroup.length ; ++i) {
            var group = categroup[i];
            html.push('<table class="scitem_small_group" bg="', i % 2 == 0 ? 'gray' : 'normal', '">');
            html.push(
                '<tr><td class="scitem_small_group_title">', group.catename, '</td></tr>'
            );
            html.push(
                '<tr style="margin: 0px 8px 10px 8px;"><td>'
            );
            for (var j = 0 ; j < group.detail.length ; ++j) {
                var detail = group.detail[j];
                var img;
                if (/^t\/base/.test(detail.img)) {
                    img = '/theme/images/' + detail.img;
                } else {
                    img = '/theme/images/shortcut/80x80/' + detail.img + '.png';
                }
                catename[detail.fun] = detail.treename;
                html.push(
                    '<div id="', detail.treeid, '" class="scitem_small" group="' , i, '" index="' , j, '">',
                        '<img src="', img, '"  oncontextmenu="return false;"/>',
                        '<div>', detail.treename.replace(/ +/g, '<br>'), '</div>',
                    '</div>'
                );
            }
            html.push('</td></tr>');
            html.push('</table>');
        }
        
        return html.join('');
    }
    
    var app_panel, app_updater;
    config.items.push();
    
    function onAppPanelRener(ct) {
        app_panel = ct;
        app_updater = ct.getUpdater();
        app_updater.on('update', onAppUpdate);
        // Override processSuccess method, if the NAS system response is not HTML context.
        app_updater.processSuccess = function(response) {
            try {
                var request = JSON.parse(response.responseText);
                if (!request.show) {
                    if (!request.fn  || request.fn === "") {
                        return;
                    }
                    eval(request.fn);
                    //return;
                };
                if(request.icon=='ProgressBar'){
                    progress_bar(request.topic,request.message,request.interval,request.duration,request.button,request.fn,request.ifshutdown);
                }else{
                    mag_box(request.topic,request.message,request.icon,request.button,request.fn,request.prompt);
                }
                return;
            } catch(e) {/* Is not show mesage box request, so continue */}

            this.transaction = null;
            if(response.argument.form && response.argument.reset){
                try{ // put in try/catch since some older FF releases had problems with this
                    response.argument.form.reset();
                }catch(e){}
            }
            if(this.loadScripts){
                this.renderer.render(this.el, response, this,
                    this.updateComplete.createDelegate(this, [response]));
            }else{
                this.renderer.render(this.el, response, this);
                this.updateComplete(response);
            }
        }
    }
    
    function onAppUpdate() {
        self.center();
    }
    
    function onClick(view, index, node, e) {
        var group = node.getAttribute('group'),
            index = node.getAttribute('index');
        
        var meta = categroup[group].detail[index];
        
        if (meta.type === 'group') {
            return popupGroup(meta.catename);
        }
        if (/^modules_/.test(meta.fun)){
            var url = meta.fun.split('_');
            window.open([
                window.location.origin,
                '/',
                'adm/getmain.php?module=',
                url[1]
            ].join(''));
            self.hide();
        }else{
            self.current = meta;
            TreeMenu.setCurrentPage(
                false,
                meta.fun,
                meta.treeid,
                meta.treename,
                meta.cateid,
                meta.catename
            );
        }
    }
    
    function onContextmenu(view, index, node, e) {
        var group = node.getAttribute('group'),
            index = node.getAttribute('index');
        
        var meta = categroup[group].detail[index];
        
        if (meta.type !== 'group') {
            menu.meta = meta;
            menu.show(node, 'c?');
        }
        
        e.preventDefault();
    }
    
    function onAdd() {
        processAjax("setmain.php?fun=setshortcut",showShortCutMenu_action,"ac=add&treeid="+this.parentMenu.meta.treeid,false);
        self.hide();
    }
    
    function onMove(window, x, y) {
        var selfSize = self.getSize(),
            bodySize = Ext.getBody().getSize(),
            xx = x < 0 ? 0 : x,
            yy = y < 0 ? 0 : y;
        
        xx = xx + selfSize.width > bodySize.width ? bodySize.width - selfSize.width : xx;
        yy = yy + selfSize.height > bodySize.height ? bodySize.height - selfSize.height : yy;
        
        if( (xx != x) || (yy != y) ) {
            self.el.moveTo(xx, yy, true);
        }
    }
    
    function popupGroup() {
        pre.setDisabled(true);
        next.setDisabled(!self.current);
        
        self.layout.setActiveItem(0);
        self.setTitle(categroup[0].catename);
        self.center();
        self.show(Ext.getBody());
    }
    self.popupGroup = popupGroup;
    
    TCode.desktop.Group.superclass.constructor.call(self, config);
    
    self.show();
    self.hide();
    
    self.ghost = function() {
        return _ghost.call(self, config.cls);
    }
    
    self.processUpdater = function (url, fun) {
        if (app_panel.items.length > 0) {
            app_panel.remove(0);
        }

        if (fun.indexOf('modules_') != -1){
            var func = fun.substr(fun.indexOf('modules_')+8,fun.length);
            window.open("/adm/getmain.php?module=" + func);
        }else{
            app_updater.update({
                  timeout:180,
                  url: url,
                  scripts: true,
                  callback: after_processUpdater,
                  params: fun
            });
            self.center();
            self.layout.setActiveItem(app_panel);
            self.setTitle(catename[fun.match(/fun=([^&#]*)/)[1]]);

            pre.setDisabled(false);
            next.setDisabled(true);

            self.page = fun.match(/fun=([^&#]*)/)[1];
            self.show(Ext.getBody());
        }
    }
    
    self.add = function(obj) {
        self.layout.setActiveItem(app_panel);
        
        app_panel.remove(app_panel.items.get(0));
        var ct = app_panel.add(obj);
        
        app_panel.doLayout();
        
        self.center();
        self.show(Ext.getBody());
        return ct;
    }
    
    self.addComponent = function (c) {
        while (app_panel.items.length > 0) {
            app_panel.remove(app_panel.items.get(0));
        }
        var ct = app_panel.add(c);
        app_panel.doLayout();
        self.layout.setActiveItem(app_panel);
        return ct;
    }
    
    TCode.desktop.Group = self;
}
Ext.extend(TCode.desktop.Group, Ext.Window);

TCode.desktop.Container = function() {
    var self = this,
        _cateid = -1,
        current_drag = false,
        ddgroup = {},
        categroup = <{$group}>,
        clen = categroup.length,
        apps = [],
        sclists = <{$sclists}>,
        list = [],
        icons = [
            't/base/group_systemInfo.png',
            't/base/group_systemSetup.png',
            't/base/group_systemNetwork.png',
            't/base/group_DiskStorage.png',
            't/base/group_systemUsers.png',
            't/base/group_networkServicew.png',
            't/base/group_app.png',
            '',
            't/base/group_backup.png',
            't/base/group_externalDevice.png'
        ],
        menu = new Ext.menu.Menu({
            cls: 't-menu',
            items: [
                {
                    text: WORDS.del_shortcut,
                    icon: '/theme/images/shortcut/sc_del.png',
                    handler: onRemove
                }
            ]
        });
    
    
    var ggroup = {
        cateid: '-1',
        type: 'ggroup',
        catename: 'Control Panel',
        treename: 'Control Panel',
        detail: [],
        img: 'ggroup_controlPanel',
        treeid: '-1',
        count: 0,
        value: 'tree_control_panel'
    };
    
    for( var i = 0 ; i < clen ; ++i ) {
        var g = categroup[i];
            g.type = 'group';
            g.treename = g.catename;
        var detail = g.detail,
            dlen = detail.length;
            g.img = icons[g.treeid - 1];
        for( var j = 0 ; j < dlen ; ++j ) {
            var app = detail[j];
                app.type = 'app';
                app.catename = g.catename;
            apps.push(app);
        }
        ggroup.detail.push(g);
    }
    
    ggroup.count = ggroup.detail.length;
    categroup.unshift(ggroup);
    
    var group_win = new TCode.desktop.Group(categroup);
    TCode.desktop.Group = group_win;
    
    list = categroup.concat(sclists);
    
    var config = {
        renderTo: 'DOMDesktop',
        layout: 'fit',
        height: Ext.getCmp('content-panel').el.getHeight(),
        items: {
            autoScroll: true,
            items: {
                xtype: 'dataview',
                store: new Ext.data.JsonStore({
                    fields: ['cateid', 'catename', 'status', 'treeid', 'treename', 'type', 'value', 'fun', 'img'],
                    data: list
                }),
                tpl: new Ext.XTemplate(
                    '{[this.itemRender(values)]}',
                    {itemRender: itemRender}
                ),
                autoHeight: true,
                multiSelect: false,
                itemSelector: 'div.scitem',
                listeners: {
                    contextmenu: onContextmenu
                }
            },
            listeners: {
                render: appRender
            }
        },
        listeners: {
            render: onRender
        }
    }
    
    function onRender() {
        Ext.get('content').getUpdateManager().on('beforeupdate', onDestroy, self );
        Ext.getCmp('content-panel').on('bodyresize', onResize, self);
        
        var content = Ext.getCmp('content-panel');
        onResize(content, content.el.getWidth(), content.el.getHeight());
    }
    
    function onDestroy() {
        Ext.get('content').getUpdateManager().un('beforeupdate', onDestroy, self );
        Ext.getCmp('content-panel').un('bodyresize', onResize, self);
        group_win.close();
        delete group_win;
        delete TCode.desktop;
    }
    
    function onResize(content, w, h) {
        self.setSize(w, h);
    }
    
    function itemRender(data) {
        var html = [];
        
        for (var i = 0 ; i < data.length ; ++i) {
            if (/group/.test(data[i].type)) {
                continue;
            }
            html.push(
                '<div id="', data[i].treeid, '" index="', i, '" class="scitem">',
                    '<img src="/theme/images/shortcut/80x80/', data[i].img, '.png" oncontextmenu="return false;"/><br>',
                    data[i].treename,
                '</div>'
            );
        }
        
        return html.join('');
    }
    
    function appRender() {
        for(var i = 0 ; i < list.length ; ++i ) {
            dd.defer(500, self, [list[i]]);
        }
    }
    
    function dd(app) {
        if (!Ext.get(app.treeid)) {
            return;
        }
        Ext.get(app.treeid).metadata = app;
        if( app.type === 'group' ) {
            Ext.get(app.treeid).on('click', onMouseUp);
            return;
        }
        
        ddgroup[app.treeid] = new Ext.dd.DragSource(app.treeid, { group: 'dd' });
        new Ext.dd.DDTarget(app.treeid, 'dd');
        ddgroup[app.treeid].afterDragDrop = afterDragDrop;
        ddgroup[app.treeid].afterDragOut = afterDragOut;
        ddgroup[app.treeid].onMouseDown = onMouseDown;
        ddgroup[app.treeid].onMouseUp = onMouseUp;
    }
    
    function onMouseDown(event) {
        current_drag = false;
    }
    
    function onMouseUp(event) {
        var meta = Ext.get(this.id).metadata;
        if( meta.fun === undefined ) {
            group_win.popupGroup(meta.catename);
            return;
        }
        if(!current_drag){
            group_win.current = meta;
            TreeMenu.setCurrentPage(
                false,
                meta.fun,
                meta.treeid,
                meta.treename,
                meta.cateid,
                meta.catename
            );
        }
    }
    
    function afterDragDrop(target, e, id) {
        var destEl = Ext.get(id),
            srcEl = Ext.get(this.getEl()),
            tt = destEl.getXY(),
            ss = srcEl.getXY(), 
            animCfgObj = {
                easing: 'elasticOut',
                duration : 1
            },
            source_treeid = srcEl.dom.id,
            target_treeid = destEl.dom.id,
            param = "ac=sort&source_treeid="+source_treeid+"&target_treeid="+target_treeid;
            
        processAjax("setmain.php?fun=setshortcut", TreeMenu.NavigatorIndex, param, false);
    
        current_drag = true; 
        srcEl.moveTo(tt[0],tt[1],animCfgObj);
        destEl.moveTo(ss[0],ss[1],animCfgObj);
    }
    
    function afterDragOut(){
        current_drag = true;
    }
    
    function onContextmenu(view, index, node, e) {
        index = +node.getAttribute('index');
        menu.meta = view.store.getAt(index).data;
        if( menu.meta.type === '') {
            menu.show(node, 'c?');
        }
        e.preventDefault();
    }
    
    function onRemove() {
        processAjax("setmain.php?fun=setshortcut",showShortCutMenu_action,"ac=remove&treeid="+this.parentMenu.meta.treeid,false);
        group_win.close();
    }
    
    var current = window.location.href.match(/current=([^&#]*)/);
    if (current) {
        processUpdater('getmain.php', 'fun=' + current[1]);
    }
    
    TCode.desktop.Container.superclass.constructor.call(self, config);
}
Ext.extend(TCode.desktop.Container, Ext.Panel);

Ext.onReady(function() {
    new TCode.desktop.Container();
});


</script>
