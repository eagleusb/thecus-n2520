if (!Function.prototype.bind) {
    Function.prototype.bind = function (oThis) {
        if (typeof this !== "function") {
            throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
        }
 
        var aArgs = Array.prototype.slice.call(arguments, 1), 
            fToBind = this, 
            fNOP = function () {},
            fBound = function () {
                return fToBind.apply(
                    this instanceof fNOP && oThis
                    ? this
                    : oThis,
                    aArgs.concat(Array.prototype.slice.call(arguments))
                );
            };
        fNOP.prototype = this.prototype;
        fBound.prototype = new fNOP();
        return fBound;
    };
}

Ext.ns('TCode.ux');
/**
 * All procedures in the server side will be mapped into Ajax automatically.
 * 
 * @class TCode.ux.Ajax
 * @namespace TCode.ux
 * @extends Ext.data.Connection
 * @constructor
 * @param {String[]} procedures Server side methods
 * @param {Object} [listeners] Procedure call back function list
 */
TCode.ux.Ajax = function(rc, ms) {
    var self = this,
        rc = rc || '',
        ms = ms || [],
        events = {};
    
    /**
     * Generate log window to display execption message
     *
     * @inner
     * @param {String} title
     * @param {String} content
     */
    function assert(title, content) {
        new Ext.Window({
            autoScroll: true,
            title: title,
            autoWidth: true,
            autoHeight: true,
            modal: true,
            bodyStyle: 'padding: 5px; min-width: 480px; max-width: 800px; max-height: 600px',
            html: content
        }).show();
    }
    
    /**
     * Invoke by Ext.data.Connection when success event.
     * 
     * @inner
     * @param {Object} response
     * @param {Object} opts
     */
    function onSuccess(response, opts) {
        try {
            var result = Ext.decode(response.responseText);
        } catch( err ) {
            if( self.debug == true ) {
                assert('<div style="background:#00C000"><b>PHP Response</b></div>', response.responseText);
            } else {
                throw err;
            }
        }
        
        try {
            self.fireEvent.apply(self, result);
            if( opts.fn ) {
                result.shift();
                opts.fn.apply(self, result);
            }
        } catch(err) {
            if( self.debug == true ) {
                var msg = String.format('<div style="background:#FF7F80"><b>Error Type {0}:</b> {1}</div>', err.type, err.message);
                    msg += err.stack.replace(/\n/g, '<br/>');
                assert('<div style="background:#00C000"><b>Javascript</b></div>', msg);
            } else {
                throw err;
            }
        }
    }
    
    /**
     * Invoke by Ext.data.Connection when failure event.
     * TODO: handler this when ajax timeout or http connection lose.
     * @inner
     * @param {Object} response
     * @param {Object} opts
     */
    function onFailure(response, opts) {
    }
    
    /**
     * Make ajax request to setmain rule.
     * 
     * @inner
     * @param {String} remote procedure
     * @param {Object} params
     */
    function makeRequest(action, params) {
        if( typeof params[params.length - 1] == 'function' ) {
            var fn = params.pop();
        }
        self.request({
            url: 'setmain.php',
            params: {
                fun: rc,
                action: action,
                params: Ext.encode(params)
            },
            timeout: self.timeout || 30000,
            success: onSuccess,
            failure: onFailure,
            fn: fn
        })
    }
    
    /**
     * Generate procedures
     * 
     * @name Ajax#event:TCode.HV.Procedure
     */
    var rpc = 'function {0}(){makeRequest(\'{0}\', Array.prototype.slice.call(arguments));}';
    for( var i = 0 ; i < ms.length ; ++i ) {
        var method = ms[i];
        eval(String.format(rpc, method));
        this[method] = eval(method);
        events[method] = true;
    }
    this.addEvents(events);
    delete events;
    
    Ext.data.Connection.superclass.constructor.call(this);
}

Ext.extend(TCode.ux.Ajax, Ext.data.Connection);