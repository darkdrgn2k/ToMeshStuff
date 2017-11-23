import requests, json
import subprocess
import shlex

data = requests.get('https://raw.githubusercontent.com/tomeshnet/node-list/master/nodeList.json').json()
result = {}
for value in data:
	if "IPV6Address" in value:
		node = {}
		command_line = "ping6 -c 1 " + value["IPV6Address"]
		args = shlex.split(command_line)
		ping = subprocess.Popen(args,stdout=subprocess.PIPE)
		ping.wait()
		output = ping.stdout.read()
		lines = output.split("\n")
		for line in lines:
			if line.find("packets transmitted") > -1:
				words = line.split()
				node.update({'loss' : words[5]})
				node.update({'status' : "dead" })
			if line.find("rtt") > -1:
				words = line.split()
				pingData = words[3].split("/")
				node.update({'pingMin' : pingData[0]})
				node.update({'pingAvg' : pingData[1]})
				node.update({'pingMax' : pingData[2]})
				node.update({'status' : "ok" })
		result.update({value["IPV6Address"] : node})
print result