<?
	require_once('../../../../function/conf/localconfig.php');
	require_once(INCLUDE_ROOT.'session.php');
	
	//require_once("../../setlang/lang.html");
	require_once(WEBCONFIG);
	$words=$session->PageCode("xpublish");
	$gwords=$session->PageCode("global");
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<link rel="stylesheet" href="../css/css.css" type="text/css">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<style type="text/css">
<!--
body {
        font-family : Verdana, Arial, Helvetica, sans-serif;
        font-size: 12px;
        color : Black;
	margin-left: 0px;
	margin-top: 0px;
	margin-right: 0px;
	margin-bottom: 0px;
        line-height: 1.5;
	height:100%
}

table {
	height:100%
}

td {
        font-size: 12px;
}

h1{
        font-weight: bold;
        font-size: 22px;
        font-family: "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
        text-decoration: none;
        line-height : 100%;
	margin-top: 30px;
	margin-left: 30px;
        color : #000000;
}

h2 {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 18px;
        color: #0E72A4;
        text-decoration: underline;
        margin-top: 20px;
	margin-left: 30px;
        margin-bottom: 10px;
}

h3 {
        font-weight: bold;
        font-family: Verdana, Arial, Helvetica, sans-serif;
        font-size: 12px;
	margin-left: 30px;
        text-decoration: underline;
}

p {
        font-family : Verdana, Arial, Helvetica, sans-serif;
        font-size: 12px;
        margin: 10px 10px 20px 20px;
}

ul {
        margin-left: 35px;
        margin-right: 25px;
        margin-top: 10px;
        margin-bottom: 10px;
        padding: 0px;
        list-style-type: square;
}

li {
        margin-left: 40px;
        margin-top: 6px;
        margin-bottom: 6px;
        padding: 0px;
        list-style-position: outside;
}
-->
</style>
<!-- $Id: xp_publish.php,v 1.5 2004/07/24 15:03:53 gaugau Exp $ -->
</head>

<body bgcolor="#686868" text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="719px" height="100%" border="0" cellspacing="0" cellpadding="0" align="center" class="outerpage">
  <? require_once("../HtmlBanner.html"); ?>
  <tr>
    <td align="center">
      <h1><?=$words['display_title']?></h1>
        <p><?=$words['display_desp']?> <b><?=$webconfig['product_no'].$webconfig['pro']?></b>.</p>

      <h2><?=$words['display_requires_header']?></h2>
      <ul>
        <li><?=$words['display_requires_content']?></li>
      </ul>
      <h2><?=$words['display_install_header']?></h2>
      <ul>
        <li>
	  <?=$words['display_install_content_1']?> <a href="<?=$PHP_SELF?>?cmd=send_reg"><?=$words['display_install_content_2']?></a>.
	  <?=$words['display_install_content_3']?>
	  <?=$words['display_install_content_4']?>
	  <?=$words['display_install_content_5']?>
        </li>
      </ul>
      <h2><?=$words['display_publish_header']?></h2>
      <ul>
        <li><?=$words['display_publish_content_1']?></li>
        <li><?=$words['display_publish_content_2']?></li>
      </ul>
    </td>
  </tr>
  <? require_once("../HtmlBottom.html"); ?>
</table>
</body>
</html>
