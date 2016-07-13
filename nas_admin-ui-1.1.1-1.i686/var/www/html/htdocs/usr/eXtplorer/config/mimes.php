<?php
/** ensure this file is being included by a parent file */
if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
//------------------------------------------------------------------------------
// editable files:
$GLOBALS["editable_ext"]=array(
	"\.txt$|\.php$|\.php3$|\.php5$|\.phtml$|\.inc$|\.sql$|\.pl$|\.csv$",
	"\.htm$|\.html$|\.shtml$|\.dhtml$|\.xml$",
	"\.js$|\.css$|\.cgi$|\.cpp$|\.c$|\.cc$|\.cxx$|\.hpp$|\.h$",
	"\.pas$|\.p$|\.java$|\.py$|\.sh$\.tcl$|\.tk$"
);
//------------------------------------------------------------------------------
// image files:
$GLOBALS["images_ext"]="\.png$|\.bmp$|\.jpg$|\.jpeg$|\.gif$|\.ico$";
//------------------------------------------------------------------------------
// mime types: (description,image,extension)
$GLOBALS["super_mimes"]=array(
	// dir, exe, file
	"dir"	=> array($GLOBALS["mimes"]["dir"],"folder.png"),
	"exe"	=> array($GLOBALS["mimes"]["exe"],"run.png","\.exe$|\.com$|\.bin$"),
	"file"	=> array($GLOBALS["mimes"]["file"],"document.png")
);
$GLOBALS["used_mime_types"]=array(
	// text
	"text"	=> array($GLOBALS["mimes"]["text"],"txt.png","\.txt$"),
	
	// programming
	"php"	=> array($GLOBALS["mimes"]["php"],"source_php.png","\.php$|\.php3$|\.phtml$|\.inc$"),
	"sql"	=> array($GLOBALS["mimes"]["sql"],"source.png","\.sql$"),
	"perl"	=> array($GLOBALS["mimes"]["perl"],"source_pl.png","\.pl$"),
	"html"	=> array($GLOBALS["mimes"]["html"],"html.png","\.htm$|\.html$|\.shtml$|\.dhtml$|\.xml$"),
	"js"	=> array($GLOBALS["mimes"]["js"],"js.png","\.js$"),
	"css"	=> array($GLOBALS["mimes"]["css"],"source_css.png","\.css$"),
	"cgi"	=> array($GLOBALS["mimes"]["cgi"],"run.png","\.cgi$"),
	"py"	=> array('Python',"source_py.png","\.py$"),
	//"sh"	=> array($GLOBALS["mimes"]["sh"],"sh.gif","\.sh$"),
	// C++
	"cpps"	=> array($GLOBALS["mimes"]["cpps"],"source_cpp.png","\.cpp$|\.c$|\.cc$|\.cxx$"),
	"cpph"	=> array($GLOBALS["mimes"]["cpph"],"source_h.png","\.hpp$|\.h$"),
	// Java
	"javas"	=> array($GLOBALS["mimes"]["javas"],"source_java.png","\.java$"),
	"javac"	=> array($GLOBALS["mimes"]["javac"],"source_java.png","\.class$"),
	"java_jar"	=> array($GLOBALS["mimes"]["javac"],"java_jar.png","\.jar$"),
	// Pascal
	"pas"	=> array($GLOBALS["mimes"]["pas"],"source.png","\.p$|\.pas$"),
	
	// images
	"gif"	=> array($GLOBALS["mimes"]["gif"],"image.png","\.gif$"),
	"jpg"	=> array($GLOBALS["mimes"]["jpg"],"image.png","\.jpg$|\.jpeg$"),
	"bmp"	=> array($GLOBALS["mimes"]["bmp"],"image.png","\.bmp$"),
	"png"	=> array($GLOBALS["mimes"]["png"],"image.png","\.png$"),
	
	// compressed
	"zip"	=> array($GLOBALS["mimes"]["zip"],"tar.png","\.zip$"),
	"tar"	=> array($GLOBALS["mimes"]["tar"],"tar.png","\.tar$"),
	"gzip"	=> array($GLOBALS["mimes"]["gzip"],"tgz.png","\.tgz$|\.gz$"),
	"bzip2"	=> array($GLOBALS["mimes"]["bzip2"],"tgz.png","\.bz2$|\.tbz$"),
	"rar"	=> array($GLOBALS["mimes"]["rar"],"tgz.png","\.rar$"),
	//"deb"	=> array($GLOBALS["mimes"]["deb"],"package.gif","\.deb$"),
	//"rpm"	=> array($GLOBALS["mimes"]["rpm"],"package.gif","\.rpm$"),
	
	// music
	"mp3"	=> array($GLOBALS["mimes"]["mp3"],"music.png","\.mp3$"),
	"wav"	=> array($GLOBALS["mimes"]["wav"],"music.png","\.wav$"),
	"midi"	=> array($GLOBALS["mimes"]["midi"],"midi.png","\.mid$"),
	"real"	=> array($GLOBALS["mimes"]["real"],"real.png","\.rm$|\.ra$|\.ram$"),
	//"play"	=> array($GLOBALS["mimes"]["play"],"mp3.gif","\.pls$|\.m3u$"),
	
	// movie
	"mpg"	=> array($GLOBALS["mimes"]["mpg"],"multimedia.png","\.mpg$|\.mpeg$"),
	"mov"	=> array($GLOBALS["mimes"]["mov"],"multimedia.png","\.mov$"),
	"avi"	=> array($GLOBALS["mimes"]["avi"],"multimedia.png","\.avi$"),
	"flash"	=> array($GLOBALS["mimes"]["flash"],"flash.gif","\.swf$"),
	
	// Micosoft / Adobe
	"word"	=> array($GLOBALS["mimes"]["word"],"ooo_writer.png","\.doc$"),
	"excel"	=> array($GLOBALS["mimes"]["excel"],"ooo_calc.png","\.xls$"),
	"pdf"	=> array($GLOBALS["mimes"]["pdf"],"pdf.png","\.pdf$")
);
//------------------------------------------------------------------------------
?>
