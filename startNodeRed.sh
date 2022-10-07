cont_name=nodered_interfacer

docker rm -f ${cont_name}

docker run -it -p 1880:1880 -v ${PWD}:/data --name ${cont_name} nodered/node-red