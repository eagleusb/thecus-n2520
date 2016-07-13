<html>
<head> 
<link rel="stylesheet" type="text/css" href="<{$urlcss}>manual.css?<{$randValue}>" />   
<script  type="text/javascript">
window.onload = function(){
	if("<{$title}>"!=""){
		parent.document.getElementById('tab_special').innerHTML='<{$title}>';
	}
}
</script>
</head>
<body>  
	<{if $id!="" && $cid!="" }>
		<p> 
			 <strong><{$title}></strong> 
		</p>
		<p>
			<{$manual_content}>
		</p> 
	<{else}>	 
		<ul>
			<{foreach from=$manual_list item=data}>
				<li><p><a href="javascript:void(0)" onclick="parent.Manual.set(1,'<{$data.treeid}>')" ><{$data.title}></a><br><{$data.desc}></p></li>
			<{/foreach}> 
			
			<{foreach from=$eventlog_list item=data}>
				<li><p><a href="javascript:void(0)" onclick="parent.Manual.set(2,'<{$data.logid}>')"><{$data.desc}></a></p></li>
			<{/foreach}> 
		</ul>   
	<{/if}>
</body>
</html>