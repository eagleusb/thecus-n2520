'use strict';

/**
There is no global class in Node.js. This virtual class name is only create for yuidoc.

These objects are available in all modules.
Some of these objects aren't actually in the global scope but in the module scope - this will be noted.

The global scope contains many classes and objects.
There are serveral config, property and method bind into global scope by default.
There are more detail information can find in <a href="http://nodejs.org/api/globals.html">Global Objects</a>.

Nasd is a services handler daemon. It will not stop or kill any service depend on nasd.
So, Nasd apply some usefully extension library and method into global scope.
Those libraries can use directly without require again.

@class (global)
@static
*/

var util = require('util'),
    path = require('path'),
    events = require('events'),
    info = console.info.bind(console),
    error = console.error.bind(console);

/**
Copies all the properties of config to the specified object.
Note that if recursive merging and cloning without referencing the original objects / arrays is needed.

@method apply
@param {Object} object The receiver of the properties
@param {Object} config The source of the properties
@param {Object} [defaults] A different object that will also be applied for default values
@return {Object} returns obj
*/
function apply(object, config, defaults) {
    if (defaults) {
        apply(object, defaults);
    }
    if (object && config && typeof config === 'object') {
        var i, j, k;
        for (i in config) {
            object[i] = config[i];
        }
    }
    return object;
}

/**
Copies all the properties of config to object if they don't already exist.

@method applyIf
@param {Object} object The receiver of the properties
@param {Object} config The source of the properties
@return {Object} returns obj
*/
function applyIf(object, config) {
    var property;
    
    if (object) {
        for (property in config) {
            if (object[property] === undefined) {
                object[property] = config[property];
            }
        }
    }
    
    return object;
}

/**
Clone simple variables including array, {}-like objects, DOM nodes and Date without keeping the old reference.
A reference for the object itself is returned if it's not a direct decendant of Object. For model cloning.

@method clone
@param {Object} item The variable to clone
@return {Object} clone
*/
function clone(item) {
    var type, i, j, k, clone, key;
    if (item === null || item === undefined) {
        return item;
    }
    
    type = toString.call(item);
    
    if (type === '[object Date]') {
        return new Date(item.getTime());
    }
    
    if (type === '[object Array]') {
        i = item.length;
        clone = [];
        while (i--) {
            clone[i] = clone(item[i]);
        }
    }
    
    else if (type === '[object Object]' ) {
        clone = {};
        for (key in item) {
            clone[key] = clone(item[key]);
        }
    }
    return clone || item;
}

apply(global, {
    /**
    Nas daemon default website port 80. On linux system, use environment variable PORT to change this default port.
    
    @example
        [root]$ PORT=3000 nasd.js
    
    @static
    @final
    @property PORT
    @type {Number}
    @default 80
    */
    PORT: process.env.PORT || 80,
    
    /**
    Default session encrypt key
    
    @static
    @final
    @property SECRET
    @type {String}
    @default (new Date()).toJSON()
    */
    SECRET: (new Date()).toJSON(),
    
    /**
    Nas daemon path
    
    @static
    @final
    @property BASE_PATH
    @type {String},
    @default __dirname
    */
    BASE_PATH: __dirname,
    
    /**
    Website html template files' folder
    
    @static
    @final
    @property VIEWS_PATH
    @type {String}
    @default __dirname + '/views'
    */
    VIEWS_PATH: path.join(__dirname, '/views'),
    
    /**
    Website resources' folder
    
    @static
    @final
    @property PUBLIC_PATH
    @type {String}
    @default __dirname + '/public'
    */
    PUBLIC_PATH: path.join(__dirname, '/public'),
    
    /**
    Nas extension service's folder
    
    @static
    @final
    @property SERVICE_PATH
    @type {String}
    @default __dirname + '/serviced'
    */
    SERVICE_PATH: path.join(__dirname, '/service'),
    
    /**
    Share Node.js util library.
    Details: <a href="http://nodejs.org/api/util.html">util</a>
    
    @property util
    @type {util}
    */
    util: util,
    
    /**
    Share Node.js events library.
    Details: <a href="http://nodejs.org/api/events.html">events</a>
    
    @property events
    @type {events}
    */
    events: events,
    
    /**
    Bind Node.js global console.info
    Details: <a href="http://nodejs.org/api/stdio.html#stdio_console_log_data"></a>
    
    Prints to stdout with newline. This function can take multiple arguments in a printf()-like way
    
    @example
    <pre><code>
    console.log('count: %d', count);
    </code></pre>
    
    If formatting elements are not found in the first string then util.inspect is used on each argument. See util.format() for more information.
    
    @method info
    */
    info: info,
    
    /**
    Bind on console.error
    
    Same as {{#crossLink "(global)/info"}}{{/crossLink}} but prints to stderr.
    
    @method error
    */
    error: error,
    
    /**
    Bind on <a href="http://nodejs.org/api/util.html#util_util_format_format">util.format</a> method.
    Returns a formatted string using the first argument as a printf-like format.
    The first argument is a string that contains zero or more placeholders. Each placeholder is replaced with the converted value from its corresponding argument. Supported placeholders are:
    
    <pre>
    %s - String.
    %d - Number (both integer and float).
    %j - JSON.
    % - single percent sign ('%'). This does not consume an argument.
    </pre>
    
    If the placeholder does not have a corresponding argument, the placeholder is not replaced.
    
    @example
    <pre><code>
    format('%s:%s', 'foo'); // 'foo:%s'
    format('%s:%s', 'foo', 'bar', 'baz'); // 'foo:bar baz'
    format(1, 2, 3); // '1 2 3'
    </code></pre>
    
    @method format
    */
    format: util.format,
    
    /**
    Bind on <a href="http://nodejs.org/api/util.html#util_util_isarray_object">util.isArray</a> method.
    Returns true if the given "object" is an Array. false otherwise.
    
    @example
    <pre><code>
    isArray([])
      // true
    isArray(new Array)
      // true
    isArray({})
      // false
    </code></pre>
    
    @method isArray
    */
    isArray: util.isArray,
    
    /**
    Bind on <a href="http://nodejs.org/api/util.html#util_util_isdate_object">util.isDate</a> method.
    Returns true if the given "object" is a Date. false otherwise.
    @example
    <pre><code>
    isDate(new Date())
      // true
    isDate(Date())
      // false (without 'new' returns a String)
    isDate({})
      // false
    </code></pre>
    
    @method isDate
    */
    isDate: util.isDate,
    
    /**
    Bind on <a href="http://nodejs.org/api/util.html#util_util_error">util.isError</a> method.
    Returns true if the given "object" is an Error. false otherwise.
    @example
    <pre><code>
    isError(new Error())
      // true
    isError(new TypeError())
      // true
    isError({ name: 'Error', message: 'an error occurred' })
      // false
    </code></pre>
    
    @method isError
    */
    isError: util.isError,
    
    /**
    Bind on <a href="http://nodejs.org/api/util.html#util_util_isregexp_object">util.isRegExp</a> method.
    Returns true if the given "object" is a RegExp. false otherwise.
    @example
    <pre><code>
    isRegExp(/some regexp/)
      // true
    isRegExp(new RegExp('another regexp'))
      // true
    isRegExp({})
      // false
    </code></pre>
    
    @method isRegExp
    */
    isRegExp: util.isRegExp,
    
    /**
    Bind on <a href="http://nodejs.org/api/util.html#util_util_inherits_constructor_superconstructor">util.inherts</a> method.
    Inherit the prototype methods from one constructor into another. The prototype of constructor will be set to a new object created from superConstructor.
    As an additional convenience, superConstructor will be accessible through the constructor.super_ property.
    @example
    <pre><code>
    function MyStream() {
        events.EventEmitter.call(this);
    }
    inherits(MyStream, events.EventEmitter);
    MyStream.prototype.write = function(data) {
        this.emit("data", data);
    }
    var stream = new MyStream();
    info(stream instanceof events.EventEmitter); // true
    info(MyStream.super_ === events.EventEmitter); // true
    stream.on("data", function(data) {
        info('Received data: "' + data + '"');
    })
    stream.write("It works!"); // Received data: "It works!"
    </code></pre>
    
    @method inherts
    */
    inherits: util.inherits,
    
    /**
    Bind on <a href="http://nodejs.org/api/util.html#util_util_inspect_object_showhidden_depth_colors">util.inspect</a> method.
    
    Return a string representation of object, which is useful for debugging.
    If showHidden is true, then the object's non-enumerable properties will be shown too. Defaults to false.
    If depth is provided, it tells inspect how many times to recurse while formatting the object. This is useful for inspecting large complicated objects.
    The default is to only recurse twice. To make it recurse indefinitely, pass in null for depth.
    If colors is true, the output will be styled with ANSI color codes. Defaults to false.
    Example of inspecting all properties of the util object:
    
    @example
    <pre><code>
    info(inspect(util, true, null));
    </code></pre>
    
    
    @method inspect
    */
    inspect: util.inspect,
    
    apply: apply,
    applyIf: applyIf,
    clone: clone
});

