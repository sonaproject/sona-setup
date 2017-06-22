#/usr/bin/bash

if [ -f "bgpd.conf" ]
then
    rm bgpd.conf
fi

if [ -f "zebra.conf" ]
then
    rm zebra.conf
fi

# Create bgpd.conf and zebra.conf for quagga
onos=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' 'onos-vrouter')
python -c "from sonaGatewaySetup import SonaGatewaySetup; handler = SonaGatewaySetup(); handler.createBgpdConf(); handler.createZebraConf(\"$onos\")"

echo "Created bgpd.conf for quagga"
cat bgpd.conf
echo "Create zebra.conf for quagga"
cat zebra.conf

mv bgpd.conf ./volumes/gateway/bgpd.conf
mv zebra.conf ./volumes/gateway/zebra.conf

vRouterName=$(cat vRouterConfig.ini | grep vRouterName | awk '{print$3}' | sed "s/\"//g")
localPeerIp=$(cat vRouterConfig.ini | grep localPeerIp | awk '{print$3}'| sed "s/\"//g")
localPeerMac=$(cat vRouterConfig.ini | grep localPeerMac | awk '{print$3}'| sed "s/\"//g")

echo && echo "run /quagga.sh --name=$vRouterName --ip=$localPeerIp --mac=$localPeerMac"
./quagga.sh --name=$vRouterName --ip=$localPeerIp --mac=$localPeerMac

# Change controlPlaneConnectPoint in  vrouter.json 
portNum=$(sudo ovs-ofctl dump-ports-desc br-router | grep quagga\) | awk -F'(' '{print $1}')

python -c "from sonaGatewaySetup import SonaGatewaySetup; handler = SonaGatewaySetup(); handler.jsonModInCaseQuaggaRestarted($portNum)"

mv vrouter.json vrouter.json.temp
python -mjson.tool vrouter.json.temp > vrouter.json
rm vrouter.json.temp

echo && echo "Changed vrouter.json"
cat vrouter.json

# Restart vRouter
./vrouter.sh



