#/usr/bin/bash

floatingCidr=$(cat externalRouterConfig.ini | grep floatingCidr | awk '{print$3}')
floatingCidr=$(echo $floatingCidr | tr -d '"')
externalPeerMac=$(cat externalRouterConfig.ini | grep externalPeerMac | awk '{print$3}')
externalPeerMac=$(echo $externalPeerMac | tr -d '"')

if [ -z $floatingCidr ]; then
  echo "floatingCidr is empty. Please fix externelRouterConfig.ini"
  exit 1
fi

if [ -z $externalPeerMac ]; then
  echo "externalPeerMac is empty. Please fix externelRouterConfig.ini"
  exit 1
fi

echo && echo "externalRouterConfig.ini"
cat externalRouterConfig.ini

echo && echo "pulling opensona/docker-quagga"
sudo docker pull opensona/docker-quagga
echo && echo "pulling done"

echo && echo "deleting existing container and port" 
sudo docker stop router
sudo docker rm router
sudo ovs-vsctl del-port router
echo && echo "deleting done"

echo && echo "running external router container"
sudo docker run --privileged --cap-add=NET_ADMIN --cap-add=NET_RAW --name router --hostname router -d opensona/docker-quagga
sudo ~/sona-setup/pipework br-int -i eth1 -l router router $floatingCidr $externalPeerMac
sudo docker exec -d router iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo && echo "running done"
sudo docker ps

