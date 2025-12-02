#!/bin/bash

if [ ! -d /storage/zones ]; then
	install -d -o nsd -g nsd -m 775 /storage/zones
fi

if [ ! -f /config/nsd_control.key ]; then
	nsd-control-setup
fi

if [ ! -f /config/tls_service.key ]; then
	openssl ecparam -name prime256v1 -genkey -noout -out /config/tls_service.key
	openssl req -new -x509 -out /config/tls_service.pem -key /config/tls_service.key -subj "/CN=nsd" -nodes -days 10000
fi

nsd -d $NSD_OPTIONS
