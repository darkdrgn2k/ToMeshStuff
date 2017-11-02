<?php
$depth=0;
function logs($l,$depth) {
        for ($i=0; $i<$depth; $i++) echo " ";
        echo $l;
        echo "\n";
}

function toIP($pub) {
        return trim(shell_exec("/opt/cjdns/publictoip6 " . $pub));
}
$checkedNode[]=0;

/*$bl['ksdkzmw2uryvkfg187kxmkdup8k78urqzpn29zh1nxvl6wfdbjk0.k']=
$bl['3wc3p4dsx6t2ykvp6xwsrqghxpd1sk925llvkvhtvnljdpd6zw30.k']=
$bl['s51m64dvhm38jlsc5vsjy9r3nry8qzcgpt5t10fxkq32fmnycyp0.k']=
$bl['jg035j9hup776kwz1k4n0bwpggxp1qmts6t715x53g8vutxktzz0.k']=
$bl['1941p5k8qqvj17vjrkb9z97wscvtgc1vp8pv1huk5120cu42ytt0.k']=
$bl['2scyvybg4qqms1c5c9nyt50b1cdscxnr6ycpwsxf6pccbmwuynk0.k']=
$bl['gx73lzns92j88p1umq2rsqn3ccll28cxuy2z0vjxxmxuplf8yxc0.k']=1;
//$bl['fgz855zyt2h7wfmf5nj5lf9j2fuh0jbrxrxk2yyqlzj1l9my3jz0.k']=1;
*/
$bl[]=0;


$res= file_get_contents('https://raw.githubusercontent.com/tomeshnet/node-list/master/nodeList.json');
$nodes=json_decode($res);
foreach ($nodes as $node) {

        if (isset($node->IPV6Address)) {
                $wl[$node->IPV6Address]=1;
        }
}

function isLink ($p1,$p2) {
        global $links;
        if ($p1==$p2) return 1; //is Self
        if (isset($bl[$p1])) return 1; //is From Blacklist
        if (isset($bl[$p2])) return 1; //is To Blacklis t
        if (isset($links[$p1][$p2]))  return 1; //is From To list
        if (isset($links[$p2][$p1]))  return 1; //is To From list
        return 0;

}

function AddLink($p1,$p2) {
        global $links;

        if (!isLink($p1,$p2)) {
                $links[$p1][$p2]=1;
        }
}

function ProcessManual($path,$pubKey) {
        global $Links,$depth,$checkedNode,$wl;

        logs("+++ScanOf " . $pubKey . "+++" , $depth);
        $res=shell_exec("./cexec \"RouterModule_getPeers('" . $path  . "')\"");

        $res=json_decode($res);
        //First add links
        if (isset($res->peers))  {
                $p=$res->peers;
                foreach ($p as $pr) {
                        $pr2=explode(".",$pr);
                        $NewPath=$pr2[1] ."." . $pr2[2] . "." . $pr2[3] . "." . $pr2[4]; //Make NEW PATH
                        $newPubKey=$pr2[5] . ".k"; //Make NEW Pub Key
                        addLink($pubKey,$newPubKey);
                }
                //Next Rerusrse
                $p=$res->peers;
                foreach ($p as $pr) {
                        $pr2=explode(".",$pr);
                        $NewPath=$pr2[1] ."." . $pr2[2] . "." . $pr2[3] . "." . $pr2[4]; //Make NEW PATH
                        $newPubKey=$pr2[5] . ".k"; //Make NEW Pub Key
                        if ($NewPath!="0000.0000.0000.0001") { //dont process if im processing myself
                            if (!isset($checkedNode[$newPubKey]) && isset($wl[toIP($newPubKey)]) ) { //If i have not been to this node before
                                $checkedNode[$newPubKey]=1;
                                //logs ($NewPath . "--" . $pubKey .  " -> " . $ip ,$depth);
                                $depth++;
                                $res2=shell_exec("./cexec \"NodeStore_getRouteLabel('". $path. "','" . $NewPath  . "')\"");
//                               echo "./cexec \"NodeStore_getRouteLabel('". $path. "','" . $NewPath  . "')\"\n";
                                 $res2=json_decode($res2);
                                                //print_r($res2);
                                 if ($res2->error=="none") {
                                     $NewPath=$res2->result;
                                      ProcessManual($NewPath,$newPubKey); //Starting Point
                                 }
                                 $depth--;
                            }
                        }
                }
        }
}


function ProcessSNode() {

        $res=file_get_contents('http://h.snode.cjd.li:3333/walk/');
        $resLines=explode("\n",$res);
        foreach ($resLines as $line) {
                $node=json_decode($line);
                if ($node[0]=='link') AddLink($node[3] , $node[4]);
        }
}
ProcessManual ('0000.0000.0000.0001',"ksdkzmw2uryvkfg187kxmkdup8k78urqzpn29zh1nxvl6wfdbjk0.k"); //Starting Point

//ProcessSNode();
foreach ($links as $k=>$link) {

echo $from . "=" . $to . "\n";
        $from=trim(shell_exec("/opt/cjdns/publictoip6 " . $k));
//$from=$k;
        foreach ($link as $k2=>$parent) {

        $to=trim(shell_exec("/opt/cjdns/publictoip6 " . $k2));
//$to=$k2;
//echo $wl[$from] . " " . $wl[$to];
//if (isset($wl[$from]) || isset($wl[$to])) {
            $r['from']=$from;
            $r['to']=$to;
//            $r['pfrom']=$k;
 //           $r['pto']=$k2;
            $n[]=$r;
            unset($r);
//}

                }
}
print_r($n);
file_put_contents("/var/www/html/links.json" , json_encode($n));


print_r($wl);
