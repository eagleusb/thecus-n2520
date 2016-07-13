<?php
/*************************
  Coppermine Photo Gallery
  ************************
  Copyright (c) 2003-2006 Coppermine Dev Team
  v1.1 originally written by Gregory DEMAR

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
  ********************************************
  Coppermine version: 1.4.4
  $Source: /cvsroot/coppermine/stable/include/exif_php.inc.php,v $
  $Revision: 1.13 $
  $Author: gaugau $
  $Date: 2006/02/24 13:32:44 $
**********************************************/

require("exif.php");

function exif_parse_file($filename)
{
        //String containing all the available exif tags.
        $exif_info = "AFFocusPosition|Adapter|ColorMode|ColorSpace|ComponentsConfiguration|CompressedBitsPerPixel|Contrast|CustomerRender|DateTimeOriginal|DateTimedigitized|DigitalZoom|DigitalZoomRatio|ExifImageHeight|ExifImageWidth|ExifInteroperabilityOffset|ExifOffset|ExifVersion|ExposureBiasValue|ExposureMode|ExposureProgram|ExposureTime|FNumber|FileSource|Flash|FlashPixVersion|FlashSetting|FocalLength|FocusMode|GainControl|IFD1Offset|ISOSelection|ISOSetting|ISOSpeedRatings|ImageAdjustment|ImageDescription|ImageSharpening|LightSource|Make|ManualFocusDistance|MaxApertureValue|MeteringMode|Model|NoiseReduction|Orientation|Quality|ResolutionUnit|Saturation|SceneCaptureMode|SceneType|Sharpness|Software|WhiteBalance|YCbCrPositioning|xResolution|yResolution";


        if (!is_readable($filename)) return false;

        $size = @getimagesize($filename);
        if ($size[2] != 2) return false; // Not a JPEG file

        $exifRawData = explode ("|",$exif_info);

        //Let's build the string of current exif values to be shown
        $showExifStr = "Adapter|ExifImageHeight|ExifImageWidth|Make|Model|DateTimeOriginal|Flash|FocalLength|ExposureTime|FNumber|MaxApertureValue|ISOSpeedRatings|WhiteBalance|MeteringMode";

        // No data in the table - read it from the image file
        $exifRawData = read_exif_data_raw($filename,0);

        $exif = array();

        if (is_array($exifRawData['IFD0'])) {
          $exif = array_merge ($exif,$exifRawData['IFD0']);
        }
        if (is_array($exifRawData['SubIFD'])) {
          $exif = array_merge ($exif,$exifRawData['SubIFD']);
        }
        if (is_array($exifRawData['SubIFD']['MakerNote'])) {
          $exif = array_merge ($exif,$exifRawData['SubIFD']['MakerNote']);
        }

        $exif['IFD1OffSet'] = $exifRawData['IFD1OffSet'];

        $exifParsed = array();

        foreach ($exif as $key => $val) {
          if (strpos($showExifStr,"|".$key) && isset($val)){
                $exifParsed[$key] = $val;
          }
        }

        return $exifParsed;
}
?>
