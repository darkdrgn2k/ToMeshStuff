<?php

$con= shell_exec ("/opt/cjdns/tools/cexec \"IpTunnel_listConnections()\"");
$con2=json_decode($con);
foreach ($con2->connections as $k) {

        $res=shell_exec("/opt/cjdns/tools/cexec \"IpTunnel_showConnection(" . $k . ")\"");
        $c=json_decode($res);
        $d['ip']=$c->ip4Address;
        $d['key']=$c->key;
        $tmp=explode(".",$d['ip']);
        $d['index']=$tmp[3];
        $connI[$d['index']]=$c->key;
        $conn[$c->key]=$d;
        unset($d);
}

$k=$_REQUEST['key'];
$index=1;
while ($index<255) {
        $index++;
        if (!isset($connI[$index])) {
        break;
        }

}

if (isset($conn[$k])) {
        echo "OK";
} else {
        if ($index==255) {
                die("error");
        }
        $ip="192.168.1." . $index;
        $cmd="/opt/cjdns/tools/cexec  \"IpTunnel_allowConnection('" . $k . "',null,null,null,0,null,'" . $ip . "')\"";
        $r=shell_exec($cmd);
$res=json_decode($r);
if ($res->error=="none") {
        echo "OK";
} else {
        echo $res->error;

}
}

