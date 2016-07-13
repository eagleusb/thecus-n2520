/**
 * value is the orignal IPv6 address fotmat
 *
 * @param {String} value
 * @param {Number} len
 * @returns {Array}
 */
function ipv6Extend(value, len) {
    value = value.replace(/^:/, '0:');
    value = value.replace(/^::/, '0::');
    value = value.replace(/:$/, ':0');
    value = value.replace(/::$/, '::0');
    value = value.split(':');
    
    var v6 = [];
    for( var i = 0 ; i < value.length ; ++i ) {
        if( value[i] != '' ) {
            v6.push( parseInt(value[i], 16) );
        } else {
            var missed = 8 - value.length + 1;
            for( var j = 0 ; j < missed ; ++j ) {
                v6.push(0);
            }
        }
    }
    
    len = len || 128;
    if( len == 128 ) {
        return v6;
    }
    else {
        return ipv6Prefix(v6, len);
    }
}

/**
 * value must be IPv6 array
 *
 * @param {Array} value
 * @param {Number} len
 * @returns {Array}
 */
function ipv6Prefix(value, len) {
    var v6 = [];
    for( var i = 0 ; i < 8 && len >= 0 ; ++i, len -= 16 ) {
        if( len > 16 ) {
            v6.push( ( value[i] || 0 ) );
        } else {
            v6.push( ( value[i] || 0 ) >> (16 - len) );
        }
    }
    
    return v6;
}

/**
 * v1, v2 must be IPv6 extend array
 * 
 * @param {Array} v1 IPv6 array
 * @param {Array} v2
 * @param {Number} len
 * @returns {Boolean}
 */
function ipv6Compare(v1, v2, len) {
    len = len || 128;
    return ipv6Prefix(v1, len).join() == ipv6Prefix(v2, len).join();
}

/**
 * ip1, mask and ip2 are string format
 *
 * @param {String} ip1
 * @param {String} mask
 * @param {String} ip2
 * @returns {Boolean}
 */
function ipv4check(ip1, mask, ip2) {
    ip1 = ip1.split('.');
    mask = mask.split('.');
    ip2 = ip2.split('.');
    
    for( var i = 0 ; i < 4 ; ++i ) {
        ip1[i] = Number(ip1[i]);
        mask[i] = Number(mask[i]);
        ip2[i] = Number(ip2[i]);
        if((ip1[i] & mask[i]) != (ip2[i] & mask[i])) {
            return false;
        }
    }
    return true;
}

/**
 * ip is a string
 * @param {String} ip
 * @returns {String}
 */
function ipv4fix(ip) {
    ip = ip.split('.');
    for( var i = 0 ; i < ip.length ; ++i ) {
        ip[i] = Number(ip[i]);
    }
    return ip.join('.');
}
