<!--
/*
  iap,2005.1.11
  usage:
    new Loading(url)
*/
function Loading(url){
    var html='<span id="LoadingBox" name="LoadingBox">Loading....</span>';
    document.write(html);
    this.run=run;
    function run(){
        var box=document.getElementById('LoadingBox'); 
        box.style.backgroundColor='#FFA500';
        box.innerHTML='Loading';
        this.flush(); 
    }
    if (typeof(url)!='undefined') setTimeout('location.href="'+url+'"',100);
    run(); 
    
}
function flush(){
    var box=document.getElementById('LoadingBox'); 
    var c=box.innerHTML;
    if (c=='') c='Loading...'
    else c=''
    box.innerHTML=c
    var w=box.style.width
    if (!w) w=0;
    box.style.width=parseInt(w) + 10 *  Math.random();
    setTimeout(flush,750)
}
Loading.prototype.flush=flush;
-->
