#!/bin/bash

echo FreeDMR Docker installer...

echo Installing require packages...
apt-get install docker.io && 
apt-get install conntrack &&

echo Set userland-proxy to false...
echo '{ "userland-proxy": false}' > /etc/docker/daemon.json &&

echo Restart docker...
systemctl restart docker &&

echo Pull FreeDMR latest image...
docker pull hacknix/freedmr:latest &&

echo Make config directory...
mkdir /etc/freedmr &&
chmod 755 /etc/freedmr &&

echo Install /etc/freedmr/freedmr.cfg ... 
cat << EOF > /etc/freedmr/freedmr.cfg
[GLOBAL]
PATH: ./
PING_TIME: 10
MAX_MISSED: 3
USE_ACL: True
REG_ACL: PERMIT:ALL
SUB_ACL: DENY:0-100000
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: DENY:0-79
GEN_STAT_BRIDGES: True
ALLOW_NULL_PASSPHRASE: True
ANNOUNCEMENT_LANGUAGES: en_GB,en_GB_2,en_US,es_ES,es_ES_2,fr_FR,de_DE,dk_DK,it_IT,no_NO,pl_PL,se_SE
SERVER_ID: 0

[REPORTS]
REPORT: True
REPORT_INTERVAL: 60
REPORT_PORT: 4321
REPORT_CLIENTS: *

[LOGGER]
LOG_FILE: freedmr.log
LOG_HANDLERS: file-timed
LOG_LEVEL: INFO
LOG_NAME: FreeDMR

[ALIASES]
TRY_DOWNLOAD: False
PATH: ./
PEER_FILE: peer_ids.json
SUBSCRIBER_FILE: subscriber_ids.json
TGID_FILE: talkgroup_ids.json
PEER_URL: https://www.radioid.net/static/rptrs.json
SUBSCRIBER_URL: https://www.radioid.net/static/users.json
STALE_DAYS: 7

[MYSQL]
USE_MYSQL: False
USER: hblink
PASS: mypassword
DB: hblink
SERVER: 127.0.0.1
PORT: 3306
TABLE: repeaters

[OBP-TEST]
MODE: OPENBRIDGE
ENABLED: False
IP:
PORT: 62044
NETWORK_ID: 1
PASSPHRASE: mypass
TARGET_IP: 
TARGET_PORT: 62044
USE_ACL: True
SUB_ACL: DENY:1
TGID_ACL: PERMIT:ALL
RELAX_CHECKS: True
ENHANCED_OBP: True


[SYSTEM]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 1
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54000
PASSPHRASE:
GROUP_HANGTIME: 5
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 60
SINGLE_MODE: True
VOICE_IDENT: True
TS1_STATIC:
TS2_STATIC:
DEFAULT_REFLECTOR: 0
ANNOUNCEMENT_LANGUAGE: en_GB_2
GENERATOR: 100

[ECHO]
MODE: PEER
ENABLED: True
LOOSE: False
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54916
MASTER_IP: 127.0.0.1
MASTER_PORT: 54915
PASSPHRASE: passw0rd
CALLSIGN: ECHO
RADIO_ID: 1000001
RX_FREQ: 449000000
TX_FREQ: 444000000
TX_POWER: 25
COLORCODE: 1
SLOTS: 1
LATITUDE: 00.0000
LONGITUDE: 000.0000
HEIGHT: 75
LOCATION: United Kingdom
DESCRIPTION: ECHO
URL: www.w1abc.org
SOFTWARE_ID: 20170620
PACKAGE_ID: MMDVM_FreeDMR
GROUP_HANGTIME: 5
OPTIONS:
USE_ACL: True
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
ANNOUNCEMENT_LANGUAGE: en_GB_2
EOF

echo Install rules.py ...
echo "BRIDGES = {'9990': [{'SYSTEM': 'ECHO', 'TS': 2, 'TGID': 9990, 'ACTIVE': True, 'TIMEOUT': 2, 'TO_TYPE': 'NONE', 'ON': [], 'OFF': [], 'RESET': []},]}" > /etc/freedmr/rules.py &&

echo Set perms on config directory...
chown -R 54000 /etc/freedmr &&

echo Setup logging...
mkdir -p /var/log/freedmr &&
touch /var/log/freedmr/freedmr.log &&
chown -R 54000 /var/log/freedmr &&

echo Run FreeDMR container...
docker run --name=freedmr -d --read-only -v /etc/freedmr/freedmr.cfg:/opt/freedmr/freedmr.cfg \
-v /var/log/freedmr/freedmr.log:/opt/freedmr/freedmr.log \
-v /etc/freedmr/rules.py:/opt/freedmr/rules.py -p 62031:62031/udp -p 62036-62046:62036-62046/udp \
-p 4321:4321/tcp hacknix/freedmr:latest

echo Set to restart on boot and when it dies...
docker update --restart unless-stopped freedmr

echo FreeDMR setup complete!


