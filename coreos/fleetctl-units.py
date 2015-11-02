#!/usr/bin/python
import json
import os

base_url = 'http://docker:4001/v2/keys'

def runCommand(cmd):
	# print cmd
	res = os.popen(cmd).read()
	return res

def getEtcd(path):
	res = runCommand('curl -s ' + base_url + path)
	return json.loads(res)


def getMachineInfo(path):
	res = getEtcd(path)
	
	val = res["node"]["value"]
	val = json.loads(val)

	return {
		"id": val["ID"],
		"ip": val["PublicIP"]
	}

def getAllMachines():
	res = getEtcd("/_coreos.com/fleet/machines/")

	machines = {}

	for node in res["node"]["nodes"]:
		url = node["key"] + "/object"
		info = getMachineInfo(url)
		machines[info["id"]] = info
	return machines


def getAllStates(machines):
	path = '/_coreos.com/fleet/states'
	res = getEtcd(path)
	nodes = res["node"]["nodes"]

	units = {}
	for node in nodes:
		# get the state
		res = getEtcd(node["key"])
		val = res["node"]["nodes"][0]["value"]
		val = json.loads(val)
		serviceFileName = node["key"].split('/')[-1]
		if "@" in serviceFileName:
			tmp = serviceFileName.split("@")
			containerName = tmp[0]
			i = int(tmp[1].split('.')[0])
		else:
			tmp = serviceFileName.split(".")
			containerName = tmp[0]
			i = 1

		unit = {
			"unitHash": val["unitHash"],
			"machine": val["machineState"]["ID"],
			"ip": machines[val["machineState"]["ID"]]["ip"],
			"name": node["key"].split('/')[-1],
			"i": i,
			"containerName": containerName
		}

		if not containerName in units:
			units[containerName] = []

		units[containerName].append(unit)
		# units[unit["name"]] = unit

	return units
		




if __name__ == '__main__':
	machines = getAllMachines()
	res = {
		"units": getAllStates(machines)
	}
	print json.dumps(res)

