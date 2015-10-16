CODEMIRROR=html/js/codemirror.js

all:	logs

logs:
	mkdir logs

# These are put into source control
generated: $(CODEMIRROR)


$(CODEMIRROR):	CodeMirror/lib/codemirror.js CodeMirror/mode/python/python.js
	(cd CodeMirror; bin/compress codemirror python) > $@

run:	all kill
	twistd -l logs/webpython.log -y webpython.tac

runpy:	killpy
	twistd --pidfile pylaunch.pid -l logs/pylaunch.log -y pylaunch.tac

manager: all killmanager
	twistd --pidfile manager.pid -l logs/manager.log -y manager.tac

kill:
	if [ -f twistd.pid ];\
	then\
		kill `cat twistd.pid`;\
	fi

killpy:
	if [ -f pylaunch.pid ];\
	then\
		kill `cat pylaunch.pid`;\
	fi

killmanager:
	if [ -f manager.pid ];\
	then\
		kill `cat manager.pid`;\
	fi

docker:
	docker.io build --rm -t webpython .

update:
	git pull
	make docker
	service webpython-worker restart

rmexited:
	docker.io ps -a|grep 'Exit '|awk '{print $$1;}'|xargs docker.io rm

rmi:
	docker.io rmi $$(docker.io images | grep "^<none>" | awk '{print $$3;}')

killold:
	-docker.io ps | egrep 'hours? ago' |awk '{print $$1}'|xargs docker.io kill
	-killall -o 30m -9 python3
