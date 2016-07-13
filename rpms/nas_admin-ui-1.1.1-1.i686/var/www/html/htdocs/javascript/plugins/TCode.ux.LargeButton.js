Ext.ns('TCode.ux');

TCode.ux.LargeButton = function(config) {
    var self = this;

    this.onRender = function(ct, position){
        if(!this.template){
            this.template = new Ext.Template(
                '<div class="x-panel" style="width: {3};">',
                    '<div class="x-panel-tl">',
                        '<div class="x-panel-tr">',
                            '<div class="x-panel-tc"></div>',
                        '</div>',
                    '</div>',
                    '<div class="x-panel-bwrap">',
                        '<div class="x-panel-ml">',
                            '<div class="x-panel-mr">',
                                '<div class="x-panel-mc">',
                                    '<div class="x-panel-body" style="nowrap">',
                                        '<table border="0" cellpadding="0" cellspacing="0" class="x-btn-wrap ux-large-button" height="{4}">',
                                            '<tbody>',
                                                '<td align="center" width="1%"><img src="{0}"></td>',
                                                '<td align="{1}" style="padding-left:10px;">',
                                                    '<em unselectable="on"><button type="button"><pre style="white-space:normal;word-wrap:break-word;text-align:{1};">{2}</pre></button></em>',
                                                '</td>',
                                            '</tbody>',
                                        '</table>',
                                    '</div>',
                                '</div>',
                            '</div>',
                        '</div>',
                        '<div class="x-panel-bl x-panel-nofooter">',
                            '<div class="x-panel-br">',
                                '<div class="x-panel-bc"></div>',
                            '</div>',
                        '</div>',
                    '</div>',
                '</div>'
            );
        }
        var btn, targs = [this.icon || '', this.textAlign || 'center', this.text || '&#160;', this.width || '100%', this.height || 'auto'];

        if(position){
            btn = this.template.insertBefore(position, targs, true);
        }else{
            btn = this.template.append(ct, targs, true);
        }
        var btnEl = btn.child(this.buttonSelector);
        btnEl.on('focus', this.onFocus, this);
        btnEl.on('blur', this.onBlur, this);
        
        this.initButtonEl(btn, btnEl);
        
        Ext.ButtonToggleMgr.register(this);
    }
    
    this.initButtonEl = function(btn, btnEl){
        this.el = btn;
        
        if(this.tabIndex !== undefined){
            btnEl.dom.tabIndex = this.tabIndex;
        }
        
        if(this.tooltip){
            if(typeof this.tooltip == 'object'){
                Ext.QuickTips.register(Ext.apply({
                      target: this.id
                }, this.tooltip));
            } else {
                this.el.dom[this.tooltipType] = this.tooltip;
            }
        }
        
        if( Ext.isIE ) {
            var el = this.el.child('.ux-large-button');
            el.addClassOnOver("ux-large-button-hover");
            el.addClassOnClick("ux-large-button-active");
        }
        
        if(this.menu){
            this.menu.on("show", this.onMenuShow, this);
            this.menu.on("hide", this.onMenuHide, this);
        }

        if(this.id){
            this.el.dom.id = this.el.id = this.id;
        }

        if(this.repeat){
            var repeater = new Ext.util.ClickRepeater(btn,
                typeof this.repeat == "object" ? this.repeat : {}
            );
            repeater.on("click", this.onClick,  this);
        }
        
        btn.on(this.clickEvent, this.onClick, this);
    }
    
    this.afterRender = function() {
        Ext.Button.superclass.afterRender.call(this);
    }
    
    this.setSize = function(width, height) {
        if(width) {
            this.el.setStyle('width', width);
            if( Ext.isIE ) {
                var img = this.el.child('img');
                var btn = this.el.child('button');
                var pre = this.el.child('pre');
                width = width - img.getWidth() - 20;
                btn.setWidth(width);
                pre.setWidth(width);
            }
        }
        if(height) {
            this.el.setStyle('height', height);
        }
    }
    
    this.getSize = function() {
        return this.el.getSize();
    }
    
    this.setIcon = function(src) {
        if( typeof src == "string" ) {
            this.el.child('img').dom.src = src;
        }
    }
    
    this.setText = function(text) {
        this.text = text;
        if(this.el){
            this.el.child("button").update(text);
        }
    }
    
    Ext.Button.superclass.constructor.call(this, config);
}

Ext.extend(TCode.ux.LargeButton, Ext.Button);

Ext.reg('LargeButton', TCode.ux.LargeButton);