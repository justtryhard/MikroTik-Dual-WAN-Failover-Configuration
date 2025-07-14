/interface bridge
add name=bridge1
/interface ethernet
set [ find default-name=ether1 ] comment=MGTS
set [ find default-name=ether2 ] comment=Inetcom poe-out=off
set [ find default-name=ether3 ] poe-out=off
set [ find default-name=ether4 ] poe-out=off
set [ find default-name=ether5 ] comment=WiFi poe-out=off
/interface pppoe-client
add add-default-route=yes interface=ether2 name=pppoe-out1 password=******* \
    use-peer-dns=yes user=*******
/interface list
add name=WAN
add name=LAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=local_pool ranges=192.168.88.100-192.168.88.254
/ip dhcp-server
add address-pool=local_pool disabled=no interface=bridge1 name=dhcp1
/interface bridge port
add bridge=bridge1 interface=ether3
add bridge=bridge1 interface=ether4
add bridge=bridge1 interface=ether5
/ip neighbor discovery-settings
set discover-interface-list=!LAN
/interface list member
add interface=ether1 list=WAN
add interface=ether2 list=WAN
add interface=ether3 list=LAN
add interface=ether4 list=LAN
add interface=ether5 list=LAN
/ip address
add address=192.168.88.1/24 interface=bridge1 network=192.168.88.0
/ip dhcp-client
add comment=dchp_primary disabled=no interface=ether1
add comment=dhcp_backup disabled=no interface=ether2
/ip dhcp-server network
add address=192.168.88.0/24 gateway=192.168.88.1
/ip dns
set servers=8.8.8.8,1.1.1.1
/ip firewall mangle
add action=mark-routing chain=prerouting disabled=yes dst-address=8.8.8.8 \
    new-routing-mark=to_8888 passthrough=yes protocol=tcp
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
add action=masquerade chain=srcnat out-interface=ether2
/ip route
add check-gateway=ping comment=Main distance=1 gateway=192.168.1.1
add check-gateway=ping comment=Backup distance=2 gateway=176.99.160.1
add comment="reachable only for inetcom (for netwatch)" distance=1 \
    dst-address=1.1.1.1/32 gateway=176.99.160.1
add comment="reachable only for inetcom (for netwatch)" distance=2 \
    dst-address=1.1.1.1/32 type=blackhole
add comment="reachable only for mgts (for netwatch)" distance=1 dst-address=\
    8.8.8.8/32 gateway=192.168.1.1
add comment="reachable only for mgts (for netwatch)" distance=2 dst-address=\
    8.8.8.8/32 type=blackhole
/ip service
set telnet address=192.168.88.0/24
set ssh address=192.168.88.0/24
set winbox address=192.168.88.0/24
/system clock
set time-zone-name=Europe/Moscow
/system script
add dont-require-permissions=yes name=mgts_is_down owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local token \"PLACE_YOUR_TOKEN_HERE\";\r\
    \n:local chat \"PLACE_YOUR_CHATID_HERE\";\r\
    \n:local text \"MGTS is DOWN\";\r\
    \n:local url \"https://api.telegram.org/bot\$token/sendMessage\?chat_id=\$\
    chat&text=\$text\"\r\
    \n:log info (\"Sending message to Telegram: \" . \$url);\r\
    \n/tool fetch url=\$url keep-result=no"
add dont-require-permissions=yes name=mgts_is_up owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local token \"PLACE_YOUR_TOKEN_HERE\";\r\
    \n:local chat \"PLACE_YOUR_CHATID_HERE\";\r\
    \n:local text \"MGTS is UP\";\r\
    \n:local url \"https://api.telegram.org/bot\$token/sendMessage\?chat_id=\$\
    chat&text=\$text\"\r\
    \n:log info (\"Sending message to Telegram: \" . \$url);\r\
    \n/tool fetch url=\$url keep-result=no"
add dont-require-permissions=yes name=inetcom_is_down owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local token \"PLACE_YOUR_TOKEN_HERE\";\r\
    \n:local chat \"PLACE_YOUR_CHATID_HERE\";\r\
    \n:local text \"Inetcom is DOWN\";\r\
    \n:local url \"https://api.telegram.org/bot\$token/sendMessage\?chat_id=\$\
    chat&text=\$text\"\r\
    \n:log info (\"Sending message to Telegram: \" . \$url);\r\
    \n/tool fetch url=\$url keep-result=no"
add dont-require-permissions=yes name=inetcom_is_up owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local token \"PLACE_YOUR_TOKEN_HERE\";\r\
    \n:local chat \"PLACE_YOUR_CHATID_HERE\";\r\
    \n:local text \"Inetcom is UP\";\r\
    \n:local url \"https://api.telegram.org/bot\$token/sendMessage\?chat_id=\$\
    chat&text=\$text\"\r\
    \n:log info (\"Sending message to Telegram: \" . \$url);\r\
    \n/tool fetch url=\$url keep-result=no"
/tool netwatch
add down-script="/ip route set \"Main\" distance=3\r\
    \n:delay 10s\r\
    \n/system script run mgts_is_down" host=8.8.8.8 interval=5s timeout=2s \
    up-script=\
    "/system script run mgts_is_up\r\
    \n/ip route set \"Main\" distance=1\r\
    \n"
add down-script="/system script run inetcom_is_down" host=1.1.1.1 interval=5s \
    timeout=2s up-script="/system script run inetcom_is_up"
