<?php

//Read existing nodes

$tmp=file_get_contents ("/var/www/html/ping.json");

$pingNodes=json_decode($tmp, true);

//  Initiate curl
$ch = curl_init();
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_URL,"https://raw.githubusercontent.com/tomeshnet/node-list/master/nodeList.json");
$result=curl_exec($ch);
curl_close($ch);

// Will dump a beauty json :3
foreach (json_decode($result, true) as $node) {
        if (isset($node['IPV6Address'])) {
                $pingNodes[$node['IPV6Address']]=pingAddress($node['IPV6Address']);
        }
}

file_put_contents ("/var/www/html/ping.json", json_encode($pingNodes));

function pingAddress($ip) {
    $pingresult = exec("/bin/ping6 -c 5  $ip", $outcome, $status);
    if (0 == $status) {
        $val=explode(" ",$pingresult);
        $stats=explode("/",$val[3]);

        $pingData['status']='ok';
        $pingData['pingMin']=$stats[0];
        $pingData['pingAvg']=$stats[1];
        $pingData['pingMax']=$stats[2];
    } else {
        $pingData['status']='dead';
        $pingData['pingMin']=-1;
        $pingData['pingAvg']=-1;
        $pingData['pingMax']=-1;
    }
        $pingData['lastPing']=date("Y-m-j H:i:s");

        return $pingData;
}

