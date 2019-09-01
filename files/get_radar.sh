#!/bin/sh

WEBLOC="/var/www/html/custom"

wget -q -O /tmp/radar.gif ftp://ftp2.bom.gov.au/anon/gen/radar/IDR403.gif

if [ -f /tmp/radar00.gif ]; then
  if [ $(sum /tmp/radar.gif | tr -d ' ') != $(sum /tmp/radar00.gif | tr -d ' ') ]; then
    echo "NEW FILE"
    if [ -f /tmp/radar11.gif ]; then cp /tmp/radar11.gif /tmp/radar12.gif; fi
    if [ -f /tmp/radar10.gif ]; then cp /tmp/radar10.gif /tmp/radar11.gif; fi
    if [ -f /tmp/radar09.gif ]; then cp /tmp/radar09.gif /tmp/radar10.gif; fi
    if [ -f /tmp/radar08.gif ]; then cp /tmp/radar08.gif /tmp/radar09.gif; fi
    if [ -f /tmp/radar07.gif ]; then cp /tmp/radar07.gif /tmp/radar08.gif; fi
    if [ -f /tmp/radar06.gif ]; then cp /tmp/radar06.gif /tmp/radar07.gif; fi
    if [ -f /tmp/radar05.gif ]; then cp /tmp/radar05.gif /tmp/radar06.gif; fi
    if [ -f /tmp/radar04.gif ]; then cp /tmp/radar04.gif /tmp/radar05.gif; fi
    if [ -f /tmp/radar03.gif ]; then cp /tmp/radar03.gif /tmp/radar04.gif; fi
    if [ -f /tmp/radar02.gif ]; then cp /tmp/radar02.gif /tmp/radar03.gif; fi
    if [ -f /tmp/radar01.gif ]; then cp /tmp/radar01.gif /tmp/radar02.gif; fi
    cp /tmp/radar00.gif /tmp/radar01.gif
    cp /tmp/radar.gif /tmp/radar00.gif
    cp /tmp/radar.gif $WEBLOC

    rm /tmp/filelist.txt
    for f in $(ls -1 /tmp/radar??.gif | sort -r); do echo "file '$f'" >> /tmp/filelist.txt; done
    /bin/ffmpeg -r 2 -y -f concat -i /tmp/filelist.txt -c:v libx264 -q:v 2 -pix_fmt yuv420p $WEBLOC/radar.mp4
#    /bin/ffmpeg -r 2 -y -f concat -safe 0 -i /tmp/filelist.txt -c:v libx264 -q:v 2 -pix_fmt yuv420p /opt/weewx/public_html/custom/radar.mp4

  else
    echo "SAME FILE"
  fi
else
  cp /tmp/radar.gif /tmp/radar00.gif
fi

