#!/bin/bash
for U in $(ls /home)
do
   cp -r /etc/CIAB-bootstrap/* /home/$U/
   # chown $U:$U /home/$U/ -r
done
