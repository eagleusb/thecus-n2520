<?php
////////////////////////////////////////////////////////////////
// PHP script made by Rasmus Petersen - http://www.peters1.dk //
////////////////////////////////////////////////////////////////

require_once(WEBCONFIG);

$data=$webconfig["data"];
$snapshot=$webconfig["snapshot"];
$usb=$webconfig["usb"];
$iscsi=$webconfig["iscsi"];
$unused=$webconfig["unused"];
//echo "<pre>";print_r(gd_info());exit;
//#####################################
//##   Sysconf.txt
//#####################################
$open_snapshot=trim(shell_exec("/img/bin/check_service.sh snapshot"));
$open_iscsi=trim(shell_exec("/img/bin/check_service.sh iscsi_limit"));
$open_target_usb=trim(shell_exec("/img/bin/check_service.sh target_usb"));
//#####################################

$total_label=array();
$total_color=array();
$total_label[]=$data;
$total_color[]="6DA9E7";
if($open_snapshot=="1"){
  $total_label[]=$snapshot;
  $total_color[]="FF8F19";
}
if($open_target_usb=="1"){
  $total_label[]=$usb;
  $total_color[]="7ABC7B";
}
if($open_iscsi!="0"){
  $total_label[]=$iscsi;
  $total_color[]="D8AFFF";
}
$total_label[]=$unused;
$total_color[]="C6BE8C";
$label="";
for($i=0;$i<count($total_label);$i++){
  $label=$label.$total_label[$i];
  if($total_label[$i+1]!=""){
    $label.="*";
  }
}
//echo $label;
//echo $label;

$show_label = true; // true = show label, false = don't show label.
$show_percent = false; // true = show percentage, false = don't show percentage.
$show_text = true; // true = show text, false = don't show text.
$show_parts = false; // true = show parts, false = don't show parts.
$label_form = 'square'; // 'square' or 'round' label.
//$label_form = 'round'; // 'square' or 'round' label.
$width = 199;
//$background_color = 'FFFFFF'; // background-color of the chart...
$background_color = $webconfig['piechart_bg']; // background-color of the chart...
$text_color = $webconfig['piechart_font']; // text-color.
//$colors = array('003366', 'CCD6E0', '7F99B2','F7EFC6', 'C6BE8C', 'CC6600','990000','520000','BFBFC1','808080'); // colors of the slices.
//$colors = array('6DA9E7', 'FF8F19', '7ABC7B','D8AFFF', 'C6BE8C', 'CC6600','990000','520000','BFBFC1','808080'); // colors of the slices.
$colors=$total_color;
//echo "<pre>";print_r($colors);
$shadow_height = 16; // Height on shadown.
$shadow_dark = false; // true = darker shadow, false = lighter shadow...

// DON'T CHANGE ANYTHING BELOW THIS LINE...


//echo $data;
//$label = "Data*snapshot*USB*iSCSI*Unallocatable";
//$label = $_GET["label"];

$height = $width;
$data = $_GET["data"];
$data = explode('*',$data);
//$data = array();
//$data[0]=15;
//$data[1]=0.01;
//$data[2]=3;


if ($label != '') $label = explode('*',$label);

for ($i = 0; $i < count($label); $i++) 
{
	if ($data[$i]/array_sum($data) < 0.1) $number[$i] = ' '.number_format(($data[$i]/array_sum($data))*100,1,',','.').'%';
	else $number[$i] = number_format(($data[$i]/array_sum($data))*100,1,',','.').'%';
	if (strlen($label[$i]) > $text_length) $text_length = strlen($label[$i]);
}
//echo "<pre>";print_r($data);print_r($label);print_r($colors);print_r($number);exit;

if (is_array($label))
{
$antal_label = count($label);
$xtra = (5+15*$antal_label)-($height+ceil($shadow_height));
if ($xtra > 0) $xtra_height = (5+15*$antal_label)-($height+ceil($shadow_height));

$xtra_width = 5;
if ($show_label) $xtra_width += 20;
if ($show_percent) $xtra_width += 45;
if ($show_text) $xtra_width += $text_length*8;
if ($show_parts) $xtra_width += 35;
}

//$im=ImageCreateFromJpeg($tmp);
$img = ImageCreateTrueColor($width+$xtra_width, $height+ceil($shadow_height)+$xtra_height);
//ImageCopeResampled

ImageFill($img, 0, 0, colorHex($img, $background_color));

foreach ($colors as $colorkode) 
{
	$fill_color[] = colorHex($img, $colorkode);
	$shadow_color[] = colorHexshadow($img, $colorkode, $shadow_dark);
}

$label_place = 5;

if (is_array($label))
{
for ($i = 0; $i < count($label); $i++) 
{
	if ($label_form == 'round' && $show_label)
	{
		imagefilledellipse($img,$width+11,$label_place+5,10,10,colorHex($img, $colors[$i % count($colors)]));
		imageellipse($img,$width+11,$label_place+5,10,10,colorHex($img, $text_color));
	}
	else if ($label_form == 'square' && $show_label)
	{	
		imagefilledrectangle($img,$width+6,$label_place,$width+16,$label_place+10,colorHex($img, $colors[$i % count($colors)]));
		imagerectangle($img,$width+6,$label_place,$width+16,$label_place+10,colorHex($img, $text_color));
	}

	if ($show_percent) $label_output = $number[$i].' ';
	if ($show_text) $label_output = $label_output.$label[$i].' ';
	if ($show_parts) $label_output = $label_output.$data[$i];

	imagestring($img,'2',$width+20,$label_place,$label_output,colorHex($img, $text_color));
	$label_output = '';

	$label_place = $label_place + 15;
}
}
$centerX = round($width/2);
$centerY = round($height/2);
$diameterX = $width;
$diameterY = $height;

$data_sum = array_sum($data);

$start = 270;

for ($i = 0; $i < count($data); $i++) 
{
	$value += $data[$i];
	$end = ceil(($value/$data_sum)*360) + 270;
	$slice[] = array($start, $end, $shadow_color[$value_counter % count($shadow_color)], $fill_color[$value_counter % count($fill_color)]);
	$start = $end;
	$value_counter++;
}

/*
for ($i=$centerY+$shadow_height; $i>$centerY; $i--) 
{
	for ($j = 0; $j < count($slice); $j++)
	{
		ImageFilledArc($img, $centerX, $i, $diameterX, $diameterY, $slice[$j][0], $slice[$j][1], $slice[$j][2], IMG_ARC_PIE);
	}
}	
*/

//echo $centerX."=".$centerY."=".$diameterX."=".$diameterY."<br>";
//echo "<pre>";print_r($data);print_r($slice);
for ($j = 0; $j < count($slice); $j++)
{
	//echo $slice[$j][3]."<br>";
	if($slice[$j][0]!=$slice[$j][1]){
	ImageFilledArc($img, $centerX, $centerY, $diameterX, $diameterY, $slice[$j][0], $slice[$j][1], $slice[$j][3], IMG_ARC_PIE);
	}
}
//exit;
OutputImage($img);
ImageDestroy($img);


function colorHex($img, $HexColorString) 
{
		$R = hexdec(substr($HexColorString, 0, 2));
		$G = hexdec(substr($HexColorString, 2, 2));
		$B = hexdec(substr($HexColorString, 4, 2));
		return ImageColorAllocate($img, $R, $G, $B);
}

function colorHexshadow($img, $HexColorString, $mork) 
{
	$R = hexdec(substr($HexColorString, 0, 2));
	$G = hexdec(substr($HexColorString, 2, 2));
	$B = hexdec(substr($HexColorString, 4, 2));

	if ($mork)
	{
		($R > 99) ? $R -= 100 : $R = 0;
		($G > 99) ? $G -= 100 : $G = 0;
		($B > 99) ? $B -= 100 : $B = 0;
	}
	else
	{
		($R < 220) ? $R += 35 : $R = 255;
		($G < 220) ? $G += 35 : $G = 255;
		($B < 220) ? $B += 35 : $B = 255;				
	}			
	
	return ImageColorAllocate($img, $R, $G, $B);
}

function OutputImage($img) 
{
	header('Content-type: image/jpg');
	ImageJPEG($img,NULL,100);
}

?>
