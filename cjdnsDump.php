<?php
$stack[]="";
chdir("/opt/cjdns/tools");
$depth=0;
function expand($ip){
    $hex = unpack("H*hex", inet_pton($ip));         
    $ip = substr(preg_replace("/([A-f0-9]{4})/", "$1:", $hex['hex']), 0, -1);

    return $ip;
}


function logs($l,$depth) {
        for ($i=0; $i<$depth; $i++) echo "| ";
        echo "+" . $l;
        echo "\n";
}

function toIP($pub) {
        return expand(trim(shell_exec("/opt/cjdns/publictoip6 " . $pub)));
}

$checkedNode[]=0;
$currentPath="0000.0000.0000.0000";

$res= file_get_contents('https://raw.githubusercontent.com/tomeshnet/node-list/master/nodeList.json');
$nodes=json_decode($res);
foreach ($nodes as $node) {
        if (isset($node->IPV6Address)) {
                $wl[expand($node->IPV6Address)]=1;
        }
}
$wl['fc44:b25f:9533:dede:9242:e5b4:3df6:a99c']=1;


function isLink ($p1,$p2) {
        global $links,$depth,$currentPath;
        if ($p1==$p2) return 1; //Self link skip
        if (isset($links[$p1][$p2])) return 1; //is From To list
        if (isset($links[$p2][$p1])) return 1; //is To From list       
        return 0;
}

function AddLink($p1,$p2) {
        global $links,$currentPath,$depth;
        if (!isLink($p1,$p2)) {
                logs("Adding " . $p1 . " to " . $p2 . " Over " . $currentPath,$depth);
                $links[$p1][$p2]=$currentPath;
        } else {
                logs("Got it already .. Skipping...",$depth);
        }
}

function ProcessManual($path,$pubKey) {
        global $Links,$depth,$checkedNode,$checkNodeLinks,$wl,$stack,$currentPath;
        array_push($stack, $path . "." . $pubKey);
        $currentPath=$path;
        logs("Begin Proces of " . $pubKey . "+++" , $depth);

        $res=shell_exec("./cexec \"RouterModule_getPeers('" . $path  . "')\"");
        logs("EXEC:  ./cexec \"RouterModule_getPeers('" . $path  . "')\"",$depth);
        $res=json_decode($res);



$skip=0;
        //First add links

        if (isset($res->peers))  {
            $p=$res->peers;


                $pr=$p[0];
                $pr2=explode(".",$pr);

                $newPubKey=$pr2[5] . ".k"; //Make NEW Pub Key
                $NewPath=$pr2[1] ."." . $pr2[2] . "." . $pr2[3] . "." . $pr2[4]; //Make NEW PATH
                if ($NewPath=="0000.0000.0000.0001") {
                        if ($newPubKey  !=  $pubKey) {
                                logs("*******WRONG NODE - SKUPPING*",$depth);
print_r($stack);
$skip=1;
                        }
                } else {
echo $newPubKey . "!=" . $pubKey;
                        die("WRONG PATH");
                }


logs("---------------------[LINKS]-------------------",$depth);
if (!$skip) {
            foreach ($p as $pr) {
                $pr2=explode(".",$pr);
                $newPubKey=$pr2[5] . ".k"; //Make NEW Pub Key
                $NewPath=$pr2[1] ."." . $pr2[2] . "." . $pr2[3] . "." . $pr2[4]; //Make NEW PATH
                logs("Found $newPubKey over $NewPath",$depth);
                $res=addLink($pubKey,$newPubKey);

            }
            unset($newPubKey);


            //Next Recusrse
            foreach ($p as $pr) {
                        $pr2=explode(".",$pr);
                        $NewPath=$pr2[1] ."." . $pr2[2] . "." . $pr2[3] . "." . $pr2[4]; //Make NEW PATH
                        $newPubKey=$pr2[5] . ".k"; //Make NEW Pub Key
                        if ($NewPath!="0000.0000.0000.0001") { //dont process if im processing myself
                            if (!isset($checkedNode[$newPubKey]) && isset($wl[toIP($newPubKey)]) ) { //If i have not been to this node before
                                $checkedNode[$newPubKey]=1;
                                //logs ($NewPath . "--" . $pubKey .  " -> " . $ip ,$depth);
                                $depth++;
                                $NewPathSplice=trim(shell_exec("./splice $NewPath $path"));
logs("Exec ./splice $NewPath $path" , $depth);
/*                                $res2=shell_exec("./cexec \"NodeStore_getRouteLabel('". $path. "','" . $NewPath  . "')\"");
                                $res2=shell_exec("./cexec \"NodeStore_getRouteLabel('". $path. "','" . $NewPath  . "')\"");
//                              echo "./cexec \"NodeStore_getRouteLabel('". $path. "','" . $NewPath  . "')\"\n";
                                $res2=json_decode($res2);
                                //print_r($res2);
                                if ($res2->error=="none") {
echo " $res3 = " . $res2->result . "\n";

                                       $NewPath=$res2->result;
*/
                                        ProcessManual($NewPathSplice,$newPubKey); //Starting Point
  //                              } else {
//                                      logs("Error $newPubKey / $path / $NewPath "  . $res2->error, $depth);
//                              }
                                $depth--;

                            } else {
                                if (isset($checkedNode[$newPubKey])) {
                                        logs("Skipping $newPubKey - Been Dere",$depth);
                                } elseif(!isset($wl[toIP($newPubKey)])) {
                                        logs("Skipping $newPubKey - Not white " ,$depth);
                                } else {
                                        logs("Skipping $newPubKey - no idea why",$depth);

}
                           }
                        } else {
                                $checkedNode[$newPubKey]=1;
                        }
                }
}
        } else  {
                $e=$res->error;
                if (isset($res->result)) $e=" " . $res->result;

                logs("Failed " . $e . "  $path $pubKey",$depth);
                print_r($stack);
        }


         array_pop($stack);

}


function ProcessSNode() {
        global $wl;
        $res=file_get_contents('http://h.snode.cjd.li:3333/walk/');
        $resLines=explode("\n",$res);
        foreach ($resLines as $line) {
                $node=json_decode($line);


                if ($node[0]=='link')
                        if (isset($wl[toIP($node[3])]) || isset($wl[toIP($node[4])]) )
                                AddLink($node[3] , $node[4]);
                        }
}
ProcessManual ('0000.0000.0000.0001',"ksdkzmw2uryvkfg187kxmkdup8k78urqzpn29zh1nxvl6wfdbjk0.k"); //Starting Point
//ProcessSNode();
foreach ($links as $k=>$link) {

        //echo $from . "=" . $to . "\n";
        $from=trim(shell_exec("/opt/cjdns/publictoip6 " . $k));
//$from=$k;
        foreach ($link as $k2=>$parent) {

        $to=trim(shell_exec("/opt/cjdns/publictoip6 " . $k2));
//$to=$k2;
//echo $wl[$from] . " " . $wl[$to];
//if (isset($wl[$from]) || isset($wl[$to])) {
            $r['from']=$from;
            $r['to']=$to;
            $r['pfrom']=$k;
           $r['pto']=$k2;
            $n[]=$r;
            unset($r);
//}

                }
}

unlink("/var/www/html/links.json");
file_put_contents("/var/www/html/links.json" , json_encode($n));
print_r($n);

