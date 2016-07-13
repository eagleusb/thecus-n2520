<!--
var formtypes=new Array('select-one','select-multiple','text','radio','checkbox','textarea','password','submit','reset')
/* 
    Utilty Functions
*/
function formelement(obj){
   t=obj.type
   //alert('type of '+obj.name+' is '+t)
   //alert(formtypes)
   for(i=0;i<formtypes.length;i++){
       if (t==formtypes[i]) return 1
   }
   return false
}

function getValue(obj){
    if (typeof(obj)==typeof('')) return obj
    t=obj.type
    if (typeof(t)=='undefined'){
       if (typeof(obj.length)!='undefined'){
           // is a container, such as radio groups shares the same name
           obj=obj[0]
           t=obj.type
       }
       else return obj // only handling form fields
    }
    if (t=='text' || t=='password'){
       return obj.value
    }
    else if (t=='radio' || r=='checkbox'){
       widgets=obj.form.elements[obj.name]
       values=[]
       for (var i=0;i<widgets.length;i++){
           widget=widgets[i]
           if (widget.checked) values[values.length]= widget.value
       }
       if (t=='radio') return values[0]
       return values
    }
    //alert('can assign value '+t)
    //return obj
}
function equals(param){
    v1=param[0]
    v2=param[1]
    v11=getValue(v1)
    //alert(v1+'->'+v11)
    v22=getValue(v2)
    //alert(v2+'->'+v22)
    return v11==v22

}
function unequals(param){
    return !equals(param)
}
function assigned(obj){
    v=getValue(obj)
    b=typeof(v)!='undefined' && v!=''
    return b
}
//function isarray(obj) {
//    return obj.constructor == Array ;
//}
function setvalue(objs,v,option_factory){
    if(arguments.length==1){
       // apply by array 
       v=objs[1]
       objs=objs[0]
    } 
    //alert(objs.length)
    //if (!isarray(objs)) objs=[objs] // convert to array
    //if (typeof(objs.sort)=='function') objs=[objs] // convert to array
    if (typeof(objs.sort)!='function') objs=[objs] // convert to array
    //alert('setvalue '+widget.name+' -->' +widget.type+','+v)
    //alert(objs.length)
    //if (objs.length==0) alert(objs)
    for (var i=0;i<objs.length;i++){
        widget=objs[i]
        t=widget.type
        if (t=='reset' || t=='submit'){
            //pass
        }
        else if (t=='text' || t=='password' || t=='textarea'){
            if (typeof(v)=='undefined') v=''
            else if (typeof(v)=='object') widget.value=v.join('\n') // array
            else widget.value=v
        }
        else if (t=='radio'){
            if (widget.value==v) widget.checked=1
        }
        else if (t=='checkbox'){
            widget.checked=widget.checked
        }
        else if (t.indexOf('select')==0){ //select-one,select-multiple
            /* inpired by raid.htm */
            //alert('settting select')
            if (typeof(v)==typeof('')||typeof(v)=='undefined') value=[]
            for (var j=0;j<value.length;j++){
                vv=value[j]
                got=0
                for (var k=0;k<widget.options.length;k++){
                    /* select the original items */
                    opt=widget.options[k]
                    if (opt.value==vv) {
                        opt.selected=1
                        got=1
                        break;
                    }
                }
                if (!got){
                    /* Add a new one */
                    opt=option_factory[vv]
                    if (opt){
                         opt.value=vv
                         /* don't why  widget.options[j]=opt donesn't works */
                         widget.options[j]=new Option(opt.text,opt.value)
                    }
                }
            }  
        }
        else{
            alert('unknow '+t+' '+widget.name)
        }
    }
}
/* 
    Class Rule
*/
function initSelectOptions(widget_select,options_factory){
    var i,key;
    i=0;
    for(key in options_factory){
        opt=option_factory[key]
        if (typeof(opt)!='object') continue;
        widget_select.options[i]=opt;
        i++;
    }
}
var _forms={}
function getForm(formname){
    if (typeof(_forms[formname])!='undefined') return _forms[formname]
    f= new Form(formname)
    _forms[formname]=f
    return f
}
function Rule(vfunction,param,err,callOnFalse,callOnFalseParam){
    this.def=vfunction
    this.param=param
    this.err=err ? err : 'unknow'
    this.callOnFalse=callOnFalse
    this.callOnFalseParam=callOnFalseParam
    this.and=and
    this.anddefs=[]  
    function and(f){
       this.anddefs[this.anddefs.length]= f
    }
    this.or=or
    this.ordefs=[]
    function or(f){
        this.ordefs[this.ordefs.length]=f
    }
    this.validate=validate
    function validate(){
        var result=[true,''] // "var" to make result local
        var v=true 
        if (typeof(this.def)=='function'){
            v=this.def(this.param)
            if (v)result=[true,]
            else result=[false,this.err]
        }
        for (var i=0;i<this.anddefs.length;i++){
            r=this.anddefs[i]
            resulta=r.validate()
            if (!resulta[0]) {
                result=resulta
                break 
            }
        }
        for (i=0;i<this.ordefs.length;i++){
            r=this.anddefs[i]
            resultr=r.validate()
            if (resultr[0]) {
                resultr=[true,'']
                break
            }
        }
        if (!result[0] && typeof(this.callOnFalse)!='undefined'){
            //alert(call)
            p=this.callOnFalseParam
            //alert(p[0])
            //alert(p[1])
            this.callOnFalse(p)
        }
        return result
    }
}
/* 
    Class Case
*/
function Case(case_condition,rule){
    this.case_condition=case_condition // a Rule instance
    this.addRule=addRule
    this.rules=[]
    if (rule) this.rules=[rule]
    function addRule(r){
        this.rules[this.rules.length]=r
    }
    this.isThisCase=isThisCase
    function isThisCase(){
        if (this.case_condition==null) return true;
        return this.case_condition.validate()[0] //return an boolean
    }

    this.validate=validate
    function validate(){
        errors=[]
        for (var i=0;i<this.rules.length;i++){
            r=this.rules[i]
            err=r.validate()
            if (!err[0]) errors[errors.length]=err
        } 
        return errors // return an array of array
    }
}
/*
    Class Form
*/
function Form(name,data){
    this.name=name
    this.form=document.getElementById(name)
    this.prefix=this.form.elements['prefix']
    if (this.prefix) this.prefix=this.prefix.value
    this.data=data ? data : (typeof(_formdata)!='undefined' ? _formdata[this.prefix] : {})
    this.cases=[]
    this.Field=Field
    function Field(fieldname){
        f= this.form.elements[fieldname]
        return f
    }
    this.submit=submit
    function submit(){
       this.form.submit()
    }
    this.addCase=addCase
    function addCase(s){
       this.cases[this.cases.length]=s
    }
    this.validate=validate
    function validate(){
        errors=[]
        for (var i=0;i<this.cases.length;i++){
            c=this.cases[i] // "case" is a javascript reserved word
            if (! c.isThisCase()){ continue}
            errors=c.validate()
            break // only one case allow
        } 
        return errors
    }
    
}
Form.prototype.show=function(){
    alert('I am '+this.name+' of '+this.obj)
}
Form.prototype.joinField=function (firstname,len){
    /* join fields like ip:1, ip:2, ip:3, ip:4 */
    firstone=this.form.elements[firstname]
    name=firstone.name.substring(0,firstone.name.length-2);
    form=firstone.form
    ip=firstone.value
    for (var i=2;i<=len;i++){
        v=parseInt(form.elements[name+':'+i].value)
        if (v<0 || v>255) return false
        ip=ip+'.'+v
    }
    return [name,ip]
}

Form.prototype.isElement= function (obj){
       t=obj.type
       //alert('type of '+obj.name+' is '+t)
       for(var i=0;i<formtypes.length;i++){
           if (t==formtypes[i]) return 1
       }
       return 0
    }
/*should pass a form object*/
Form.prototype.setFieldsValue=function(option_factory){
    //this.option_fatory=option_factory
    formname=this.name
    form=this.form
    prefix=this.prefix
    if (!this.data) return 1
    values=this.data
    if (!values) return 1
    nodes=form.elements
    for (var i=0;i<nodes.length;i++){
        widget=nodes[i]
        //alert(widget.name)
        if (!formelement(widget)) continue
        //alert('yes')
        t=widget.type
        value=values[prefix+widget.name]
        //alert('setting '+widget.name+' value '+value)
        setvalue(widget,value,option_factory)
    }
    return 1
}
/*
    Class Div
*/
function Div(){
}
function turn (div,off){
        divs=getparents(div)
        // if parent is off, this should be off too
        for(var i=0;i<divs.length;i++){
            pobj=document.getElementById(divs[i])
            if (!pobj) continue
            poff= pobj.style.visibility=='hidden' 
            if (poff){
               off=1;
               break;
            }
        } 
        obj=document.getElementById(div)
        childNodes=obj.childNodes
        for(i=0;i<childNodes.length;i++){
            node=childNodes[i]
            if (!formelement(node)) continue
            //alert(node.name)
            node.disabled=off
        }
        obj.style.visibility= off ?  'hidden' : 'visible'
        //alert(obj.style.visibility)
    }

function getparents(div){
        divs=new Array()
        p=div.lastIndexOf('.')
        while (p!=-1){
            q=div.substring(0,p)
            divs[divs.length]=q
            p=q.lastIndexOf('.')
        }  
        return divs
    }
function turns(div,off){
        if (typeof(div)=='undefined' || !div) return
        if (typeof(div)==typeof('')){
            return turn(div,off)
        }
        else if (typeof(div)==typeof([])){
            for (var i=0;i<div.length;i++){
                turn(div[i],off)
            }
        }
        return 1
    }
function turnon(div){        
        return turns(div,0)
    }
function turnoff(div){
        return turns(div,1)
    }
function checkvalue(id,v){
        obj=document.getElementById(id)
        if (obj.type=='radio'){
            objs=document.getElementsByName(id)
            for (var i=0;i<objs.length;i++){
                if (objs[i].checked) return objs[i].value==v
            }
            return false
        }
        else{
            return obj.value==value
        }
    }
    var rules=[]
function addRule(objname,val,be_enabled,be_disabled){
        rules[rules.length]=[objname,val,be_enabled,be_disabled]
    }
function layout(){
        for (var i=0;i<rules.length;i++){
            rule=rules[i]
            //alert(checkvalue(rule[0],rule[1]))
            //alert('checking '+rule[0]+','+rule[1])
            objname=rule[0];value=rule[1];ons=rule[2];
            if (rule.length>3)offs=rule[3];
            if (checkvalue(objname,value)){
                turnon(ons);
                turnoff(offs);
                }
            else{
                // do nothing
                }
        }
    }

//iap.2005.01.29
function confirmReset(){
    //var sure=getword('_confirm');
    //confirm(sure) && location.reload();
    location.reload();
}
//iap,2005.02.03
// asking user to make sure
function sure(times){
    if (typeof(times)=='undefined') times=1;
    var sure=getword('_confirm')
    for (var i=times;i>0;i--){
       sure_=sure+" (Asking "+(times-i+1)+" times)"
       if (!confirm(sure_)) return false;
    }
    return true;
}
-->
