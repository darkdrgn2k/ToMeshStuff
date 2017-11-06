<?php
$res= file_get_contents('https://raw.githubusercontent.com/tomeshnet/node-list/master/nodeList.json');
$nodes=json_decode($res);

$r="";

foreach ($nodes as $node) {
        if (isset($node->IPV6Address)) {

                if (TestProm($node->IPV6Address)) {
                        if ($r) $r.=",";
                        $r.="\"[" . $node->IPV6Address   . "]:9100\"";

                }
        }
}
                        echo "[\n{\n\"targets\": [" .  $r . "]\n}\n]";


function TestProm($ip) {
@       $fp = fsockopen("[" . $ip . "]", 9100, $errno, $errstr, 10);
        if (!$fp) {
           return 0;
        } else {
                return 1;
                    fclose($fp);
        }
}

