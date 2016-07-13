<script type='text/javascript'>
vwords = <{$vtypes}>;
Ext.apply(Ext.form.VTypes, {
    DomainMask: /[-_.a-zA-Z0-9]/,
    DomainText: vwords.domain,
    Domain: function(val, _, max) {
        max = max || 200;
        if( val.length > max ) {
            return false;
        }
        val = val.split('.');
        if( val.length < 2 ) {
            return false;
        }
        /**
         * For N12000 customer request:
         *   They don't want the full domain name support.
         */
        var i = 0;
        for( i ; i < val.length ; ++i ) {
        //for( i ; i < (val.length - 1) ; ++i ) {
            if( val[i] == '' || this.Hostname(val[i]) == false ) {
                return false;
            }
        }
        return true;
        //return /^[a-zA-Z]+$/.test(val[i]);
    },
    HostnameRe: [
        /^[-_a-zA-Z0-9]{1,30}$/,
        /^[^-]/,
        /[^-]$/
    ],
    HostnameMask: /[-_a-zA-Z0-9]/,
    HostnameText: vwords.hostname,
    Hostname: function(val) {
        for( var i = 0 ; i < this.HostnameRe.length ; ++i ) {
            if( this.HostnameRe[i].test(val) != true ) {
                return false;
            }
        }
        
        return true;
    },
    HaHostnameMask:/[-a-zA-Z0-9]/,
    HaHostnameRe:/^[a-zA-Z][-a-zA-Z0-9]{0,15}$/,
    HaHostnameText: vwords.hahostname,
    HaHostname: function(val){
        if( this.HaHostnameRe.test(val) != true){
            return false;
        }
    return true;
    },
    FQDNMask: /[-_.a-zA-Z0-9]/,
    FQDNText: vwords.fqdn,
    FQDN: function(val) {
        return (val.split('.').length > 2 && /^.{1,254}$/.test(val) && this.Domain(val, null, 254));
    },
    IPv4Val: /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/,
    IPv4Mask: /[0-9.]/,
    IPv4Text: vwords.ipv4,
    IPv4: function(val) {
        return this.IPv4Val.test(val);
    },
    IPv4NetmaskVal: /^(((0|128|192|224|240|248|252|254).0.0.0)|(255.(0|128|192|224|240|248|252|254).0.0)|(255.255.(0|128|192|224|240|248|252|254).0)|(255.255.255.(0|128|192|224|240|248|252|254)))$/,
    IPv4NetmaskMask: /[0-9\.]/,
    IPv4NetmaskText: vwords.ipv4_mask,
    IPv4Netmask: function(val) {
        return this.IPv4NetmaskVal.test(val);
    },
    IPv4GatewayText: vwords.ipv4_gateway,
    IPv4Gateway: function(val) {
        return val == '' ? true : this.IPv4Val.test(val);
    },
    IPv6Val: /^(([A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4})$|^([A-Fa-f0-9]{1,4}::([A-Fa-f0-9]{1,4}:){0,5}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){2}:([A-Fa-f0-9]{1,4}:){0,4}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){3}:([A-Fa-f0-9]{1,4}:){0,3}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){4}:([A-Fa-f0-9]{1,4}:){0,2}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){5}:([A-Fa-f0-9]{1,4}:){0,1}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){6}:[A-Fa-f0-9]{1,4})$/,
    IPv6Mask: /[a-fA-F0-9\.:]/,
    IPv6Text: vwords.ipv6,
    IPv6: function(val) {
        return this.IPv6Val.test(val);
    },
    IPv6PrefixMask: /[a-fA-F0-9\.:]/,
    IPv6PrefixText: vwords.ipv6_prefix,
    IPv6Prefix: function(val) {
        if( /[^:]::$/.test(val) == false ) {
            return false;
        }
        val += '0';
        return this.IPv6Val.test(val);
    },
    IPv6LengthMask: /[0-9]/,
    IPv6LengthText: vwords.ipv6_length,
    IPv6Length: function(val) {
        return (val > 0) && (val % 4 == 0) && (val <= 128);
    },
    IPv6GatewayText: vwords.ipv6_gateway,
    IPv6Gateway: function(val) {
        return val == '' ? true : this.IPv6Val.test(val);
    },
    IPMask: /[a-fA-F0-9\.:]/,
    IPText: vwords.ip,
    IP: function(val) {
        if( this.IPv4Val.test(val) ) {
            return true;
        }
        if( this.IPv6Val.test(val) ) {
            return true;
        }
        return false;
    },
    NETHostText: vwords.nethost,
    NETHost: function(val){
        return (this.IPv4(val) || this.IPv6(val) || this.FQDN(val))
    },
    WINSMask: /[-_.a-zA-Z0-9:]/,
    WINSText: vwords.wins,
    WINS: function(val) {
        //return (this.IP(val) || this.FQDN(val));
        return (this.IPv4(val) || this.FQDN(val));
    },
    iTuneMask: /[a-zA-Z0-9]/,
    iTune: function(val){
        return val;
    },
    PortMask: /[0-9]/,
    PortText: vwords.port_range,
    Port: function(val, field){
        if(parseInt(val) < 65536 && parseInt(val) > 0){
            return true;
        }
        else{
            return false;
        }
    },
    NaturalNumbersMask: /[0-9]/,
    NaturalNumbers: function(val) {
        return Number(val) > 0;
    },
    NumbersMask: /[0-9]/,
    Numbers: function(val) {
        return Number(val) >= 0;
    },
    RaidIDMask: /[a-zA-Z0-9]/,
    RaidIDText: vwords.raid_id,
    RaidID: function(val) {
        if( val.length < 4 || val.length > 12 ) {
            return false;
        }
        return this.RaidIDMask.test(val);
    },
    AliasNameRe: /^[0-9a-zA-Z_-]{0,12}$/,
    AliasNameMask: /[0-9a-zA-Z_-]/,
    AliasNameText: vwords.alias_name,
    AliasName: function(val) {
        return this.AliasNameRe.test(val);
    },
    UserNameRe:/^[\u0021\u0023-\u0029\u002d-\u002e\u0030-\u0039\u0041-\u005a\u005e-\u007b\u007d-\u007e]+$/,
    UserNameMask: /[\u0021\u0023-\u0029\u002d-\u002e\u0030-\u0039\u0041-\u005a\u005e-\u007b\u007d-\u007e]+$/,
    UserNameText: vwords.user_name,
    UserName: function(val){
        var reversedWords = /\b(root|ftp|admin|sshd|nobody)\b/;
        return this.UserNameRe.test(val) && (val.length <= 64) && !reversedWords.test(val);  
    },
    PasswordRe:/^[\u0020\u0022\u0023\u0025-\u007e]+$/,
    PasswordMask: /[\u0020\u0022\u0023\u0025-\u007e]+$/,
    PasswordText: vwords.password,
    Password: function(val){
        return this.PasswordRe.test(val) && (val.length <= 16 && val.length >= 4);
    },
    RsyncPasswordRe: /[_a-zA-Z0-9\[\]\@\%\/\-\+]/,
    RsyncPasswordMask: /[_a-zA-Z0-9\[\]\@\%\/\-\+]/,
    RsyncPassword: function(val){
        return this.RsyncPasswordRe.test(val) && (val.length <= 16 && val.length >= 4);
    },
    ShareNameRe:/^[\u0020\u0024-\u0029\u002b-\u002e\u0030-\u0039\u003b\u003d\u0040-\u005a\u005e-\u007b\u007e]+$/,
    ShareNameMask: /[\u0020\u0024-\u0029\u002b-\u002e\u0030-\u0039\u003b\u003d\u0040-\u005a\u005e-\u007b\u007e]+$/,
    ShareNameText: vwords.share_name,
    ShareName: function(val){
        var reversedWords = /^\s|\s\s|\b(sys|tmp|lost+found|ftproot|global)\b|\s$/;
        return this.ShareNameRe.test(val) && val.length <= 60 && !reversedWords.test(val);
    },
    FileFilterMask: /[^\u002f\u005c\u003a\u003f\u0022\u003c\u003e\u007c]/,
    FileFilter: function(val){
        return this.FileFilterMask.test(val);
    },
    StackNameRe: /^[0-9a-zA-Z_-]{1,60}$/,
    StackNameMask: /[0-9a-zA-Z_-]/,
    StackNameText: vwords.stack_name,
    StackName: function(val){
        return this.StackNameRe.test(val);
    },
    AdminPwdRe: /^[^ ]{4,16}$/,
    AdminPwdMask: /[^ ]/,
    AdminPwdText: vwords.adminpwd,
    AdminPwd: function(val){
        return (val.split('').length > 2 && this.AdminPwdRe.test(val));
    },
    OLEDPwdRe:/^[0-9]{4,4}$/,
    OLEDPwdMask: /[0-9]/,
    OLEDPwdText: vwords.oledpwd,
    OLEDPwd: function(val){
        return this.OLEDPwdRe.test(val);
    }
});
</script>
