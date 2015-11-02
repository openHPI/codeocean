
docker \
    run \
	    --add-host=docker:$(ifconfig eth0 | grep 'inet ' | awk '{ print $2 }') \
	    --add-host=co-postgres:$POSTGRES_FLANNEL_IP \
	    --add-host=co-python:$POSTGRES_PYTHON_IP \
	    -t -i --privileged=true \
	    -p 3000:3000 \
	    -e DOCKER_HOST=tcp://docker:2376  \
	    --name codeocean \
	    torpedro/codeocean

