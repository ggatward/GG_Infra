#!/bin/sh

WEBLOC="/var/www/html/custom"

rm -f /tmp/directory_listing

# get listing from directory sorted by modification date
ftp -n ftp2.bom.gov.au > /tmp/directory_listing <<fin 
quote USER anonymous
quote PASS password
cd /anon/gen/gms
ls -t
quit
fin

# parse the filenames from the directory listing
file_to_get=`cut -c 57- < /tmp/directory_listing | grep IDE00135 | grep -v radar | head -1`

wget -q -O /tmp/sat.jpg ftp://ftp2.bom.gov.au/anon/gen/gms/${file_to_get}

if [ -f /tmp/sat00.jpg ]; then
  if [ $(sum /tmp/sat.jpg | tr -d ' ') != $(sum /tmp/sat00.jpg | tr -d ' ') ]; then
    echo "NEW FILE"
    if [ -f /tmp/sat23.jpg ]; then cp /tmp/sat23.jpg /tmp/sat24.jpg; fi
    if [ -f /tmp/sat22.jpg ]; then cp /tmp/sat22.jpg /tmp/sat23.jpg; fi
    if [ -f /tmp/sat21.jpg ]; then cp /tmp/sat21.jpg /tmp/sat22.jpg; fi
    if [ -f /tmp/sat20.jpg ]; then cp /tmp/sat20.jpg /tmp/sat21.jpg; fi
    if [ -f /tmp/sat19.jpg ]; then cp /tmp/sat19.jpg /tmp/sat20.jpg; fi
    if [ -f /tmp/sat18.jpg ]; then cp /tmp/sat18.jpg /tmp/sat19.jpg; fi
    if [ -f /tmp/sat17.jpg ]; then cp /tmp/sat17.jpg /tmp/sat18.jpg; fi
    if [ -f /tmp/sat16.jpg ]; then cp /tmp/sat16.jpg /tmp/sat17.jpg; fi
    if [ -f /tmp/sat15.jpg ]; then cp /tmp/sat15.jpg /tmp/sat16.jpg; fi
    if [ -f /tmp/sat14.jpg ]; then cp /tmp/sat14.jpg /tmp/sat15.jpg; fi
    if [ -f /tmp/sat13.jpg ]; then cp /tmp/sat13.jpg /tmp/sat14.jpg; fi
    if [ -f /tmp/sat12.jpg ]; then cp /tmp/sat12.jpg /tmp/sat13.jpg; fi
    if [ -f /tmp/sat11.jpg ]; then cp /tmp/sat11.jpg /tmp/sat12.jpg; fi
    if [ -f /tmp/sat10.jpg ]; then cp /tmp/sat10.jpg /tmp/sat11.jpg; fi
    if [ -f /tmp/sat09.jpg ]; then cp /tmp/sat09.jpg /tmp/sat10.jpg; fi
    if [ -f /tmp/sat08.jpg ]; then cp /tmp/sat08.jpg /tmp/sat09.jpg; fi
    if [ -f /tmp/sat07.jpg ]; then cp /tmp/sat07.jpg /tmp/sat08.jpg; fi
    if [ -f /tmp/sat06.jpg ]; then cp /tmp/sat06.jpg /tmp/sat07.jpg; fi
    if [ -f /tmp/sat05.jpg ]; then cp /tmp/sat05.jpg /tmp/sat06.jpg; fi
    if [ -f /tmp/sat04.jpg ]; then cp /tmp/sat04.jpg /tmp/sat05.jpg; fi
    if [ -f /tmp/sat03.jpg ]; then cp /tmp/sat03.jpg /tmp/sat04.jpg; fi
    if [ -f /tmp/sat02.jpg ]; then cp /tmp/sat02.jpg /tmp/sat03.jpg; fi
    if [ -f /tmp/sat01.jpg ]; then cp /tmp/sat01.jpg /tmp/sat02.jpg; fi
    cp /tmp/sat00.jpg /tmp/sat01.jpg
    cp /tmp/sat.jpg /tmp/sat00.jpg
    cp /tmp/sat.jpg $WEBLOC/satellite.jpg

    rm /tmp/filelist_s.txt
    for f in $(ls -1 /tmp/sat??.jpg | sort -r); do echo "file '$f'" >> /tmp/filelist_s.txt; done
    /usr/bin/ffmpeg -r 2 -y -f concat -safe 0 -i /tmp/filelist_s.txt -c:v libx264 -q:v 2 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -pix_fmt yuv420p $WEBLOC/satellite.mp4
  else
    echo "SAME FILE"
  fi
else
  cp /tmp/sat.jpg /tmp/sat00.jpg
fi

