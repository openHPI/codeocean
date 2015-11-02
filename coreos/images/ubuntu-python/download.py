#!/bin/python

import requests
import sys
res = requests.get(sys.argv[1])

resJson = res.json()

for node in resJson["node"]["nodes"]:
  output = open(node["key"].split("/")[-1], "w")
  output.write(node["value"])
  output.close()

