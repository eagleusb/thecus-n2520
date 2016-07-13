#/opt/python/bin/python

import subprocess
import os
import Image
import sys
from glob import glob
from os.path import splitext

# Parser parameter
from optparse import OptionParser 
MSG_USAGE = "thumbnail.py SOURCE_FILE [--resize <1024x768> [--crop <60x60>]] [--rotate <angle>] [TARGET_FILE]" 
optParser = OptionParser(MSG_USAGE) 

optParser.add_option("--resize", type = "string", dest = "size", help = "SIZE format: <length>x<width>")
optParser.add_option("--crop", type = "string", dest = "crop", help = "CROP format: <length>x<width>")
optParser.add_option("--rotate", type = "string", dest = "angle")

options, args = optParser.parse_args()

# Judge parameter role
if len(args) <1:
    print "Without source file name !"
    sys.exit()

if (os.path.exists(args[0]))==0:
    print "Source file isn't exit !"
    sys.exit()


'''
Function define
'''

def webdav_thumbnail(path):
    dir = os.path.dirname(path)
    file_name = os.path.basename(path)
    Index_ext = os.path.splitext(path)
    Goal_dir = dir + "/.thumbnail/"
    check_dir = os.path.exists(Goal_dir)
    ext = Index_ext[1].lower()

    if ext==".jpg" or ext==".gif" or ext==".jpeg" or ext==".png" or ext==".tif" or ext==".tiff" or ext==".bmp":
        if check_dir == False:
            os.makedirs(Goal_dir)

        im = Image.open(path)
        im.thumbnail( (160,120) )
        im.save(Goal_dir + file_name)


def piczza_resize(source_im,size):
    # Check size format
    if "x" in size:
        length = size.split('x',1)[0]
        width = size.split('x',1)[1]
    else:
        print "size format error !"
        sys.exit()

    if (not length.isdigit()) or (not width.isdigit()):
        print "size format error !"
        sys.exit()

    source_im.thumbnail( (int(length), int(width)) )

    return source_im


def piczza_rotate(source_im, angle):

    if (angle == "90"):
        res_im = source_im.transpose(Image.ROTATE_270)
    elif (angle == "-90"):
        res_im = source_im.transpose(Image.ROTATE_90)

    return res_im


def piczza_crop(source_im, crop):
    # Check crop size format
    if "x" in crop:
        length = crop.split('x',1)[0]
        width = crop.split('x',1)[1]
    else:
        print "crop size format error !"
        sys.exit()

    if (not length.isdigit()) or (not width.isdigit()):
        print "crop size format error !"
        sys.exit()

    ## Count crop size to fit picture size
    x_start = 0
    y_start = 0
    src_length,src_width = source_im.size
    length = int(length)
    width = int(width)
    if ( length > src_length ):
        length = src_length
    if ( width > src_width ):
        width = src_width

    res_im = source_im.crop( (x_start,y_start,length,width) )
    return res_im


'''
Main
'''

without_thumbnail = ".thumb" in args[0]

if (len(args)==1):
    if (without_thumbnail==False):
        webdav_thumbnail(args[0])
else:
    im = Image.open(args[0])

    if(options.size!=None):
        im = piczza_resize(im, options.size)
    if(options.angle!=None):
        im = piczza_rotate(im, options.angle)
    if(options.crop!=None):
        im = piczza_crop(im, options.crop)

    im.save(args[1]) 
