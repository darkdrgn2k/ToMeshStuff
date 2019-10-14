<?php
@include("0.php");
// $signalIPv6toMacs [[iv6source][mactarget][macsource]
//print_r($signalIPv6toMacs);
//die();

$res= file_get_contents('https://raw.githubusercontent.com/darkdrgn2k/node-list/master/nodeList-nomap.json');
$allnodes[]=json_decode($res);

$res= file_get_contents('https://raw.githubusercontent.com/tomeshnet/node-list/master/nodeList.json');
$allnodes[]=json_decode($res);

$res= file_get_contents('https://raw.githubusercontent.com/tomeshnet/node-list/master/nodeList-nomap.json');
$allnodes[]=json_decode($res);


$nodelink=$r;
function expand($ip){
    $hex = unpack("H*hex", inet_pton($ip));
    $ip = substr(preg_replace("/([A-f0-9]{4})/", "$1:", $hex['hex']), 0, -1);

    return $ip;
}

$group['vanmesh']="#FF0000";
$group['phillymesh']="#1a4a4e";
$group['dugnadsnett']="#a3cbff";
$group['tomesh']="#0000ff";


function findLink($srcIPv6,$trgIPv6) {
	global $mapIPv6toMac;
	if (isset($mapIPv6toMac[$srcIPv6])) {
		$srcMacs=$mapIPv6toMac[$srcIPv6];
	} else {
		return;
	}
	if (isset($mapIPv6toMac[$trgIPv6])) {
		$trgMacs=$mapIPv6toMac[$trgIPv6];
	} else {
		return;
	}


	foreach ($srcMacs as $srcMac=>$connectedSrcMacs) {
		foreach ($trgMacs as $trgMac=>$connectedTrgMacs) {
			foreach ($connectedTrgMacs as $dstMac=>$junk);
			if ($srcMac == $dstMac)
                                return(array( "source" => $srcMac, "target" => $trgMac ));

		}
	}

	foreach ($trgMacs as $trgMac=>$connectedTrgMacs) {
		foreach ($srcMacs as $srcMac=>$connectedSrcMacs) {
			foreach ($connectedSrcMacs as $dstMac=>$junk) {
				if ($trgMac == $dstMac)
                               		return(array( "source" => $trgMac, "target" => $srcMac ));
			}
		}
	}


return;
print_r($srcMacs);
die();

print_r($trgMacs);
die();
	foreach ($srcMacs as $src=>$trg) {
		foreach ($trgMacs as $src2=>$trg2array) {
			foreach ($trg2array as $trg2=>$trg2null) {
				if ($trg==$src2)
				return(array( "source" => $src2, "target" => $trg2 ));
			}
		}
	}
	return ;
}

// Build whitelist from all nodes
foreach ($allnodes as $nodes)
	foreach ($nodes as $node) {

	        if (isset($node->IPV6Address)) {
		    $ipv6=expand($node->IPV6Address);
	            $whiteList[$ipv6]=$node->name;
		    $nodeID=explode(":",expand($node->IPV6Address));
		    $nodeName[$nodeID[count($nodeID)-1]]=$node->name;
if (isset($node->img)) $nodeimg[$ipv6]=$node->img;
if (isset($node->group)) $nodegroup[$ipv6]=$node->group;
	        }
	}
//print_r($nodegroup);
	$nodeName['39dc']='Node1';
//$l['85']="OP ONE";
//$l['6148']="PC";
$nodeName['e260']="tomesh chat";
$nodeName['e260']="Node2";
//$l['39dc']="Node1";
//$l['8583']="XPN";
//$l['2a77']="PC";
//$l['12a7']="GROUND";
//$l['45e9']="Atlas";
//$l['2873']="Maia";
//$l['6389']="Pleione";
//$l['8985']="stouvile";
$nodeName['45d3']="transitiontech";
$nodeName['a3c1']="ventricle";
//$l['b274']="westmount";
//$l['2758']="danforth";
$nodeName['b241']="PhillyMesh";
if (isset($_REQUEST['noname'])) { unset($nodeName); $nodeName[]=0;}
?>
<html>
<head>
<script type="text/javascript" src="vis.min.js"></script>
<link href="vis.min.css" rel="stylesheet" type="text/css" />
<style type="text/css">
#mynetwork {
    width: 100%;
    height: 100%;
    border: 1px solid lightgray;
}
</style>
</head>
<body>

<div id="mynetwork"></div>

<script>
    var nodes = new vis.DataSet([


<?php
$res=file_get_contents("../links.json");
$n=json_decode($res);

foreach ($n as $a) {


$a->from=expand($a->from);
$a->to=expand($a->to);

	if (!isset($test[$a->from])) {
		$test[$a->from]=1;
		$aa=explode(":",$a->from);
		$aa=$aa[7];
		if (isset($nodeName[$aa])) $aa=$nodeName[$aa];
		$color="";
/*echo ($nodegroup[$a->from]);
print_r($nodegroup);
echo ($a->from);
*/

		if (isset($group[$nodegroup[$a->from]])) $color=", color:{color: '" . $group[$nodegroup[$a->from]] . "' } ";
		if (!isset($whiteList[$a->from])) $color=", color:{color: '#cccccc' } ";

		$label=$a->from;
		if(isset($a->pfrom)) $label.="\\n" . $a->pfrom;
		echo "{id:'" . $a->from . "', label: '" . $aa ."'$color , title:'" . $label . "'},\n";
	}
	if (!isset($test[$a->to])) {
		$aa=explode(":",$a->to);
		$aa=$aa[7];
		if (isset($nodeName[$aa])) $aa=$nodeName[$aa];
		$test[$a->to]=1;
		$color="";
		if (isset($group[$nodegroup[$a->from]])) $color=", color:{color: '" . $group[$nodegroup[$a->to]] . "' } ";

		if (!isset($whiteList[$a->to])) $color=", color:'#cccccc'";
		$label=$a->to;
		if(isset($a->pto)) $label.="\\n" . $a->pto;
		echo "{id:'" . $a->to . "', label: '" . $aa ."'$color , title:'" . $label  . "'},\n ";
	}
}

?>
  ]);
    var edges = new vis.DataSet([
<?php
foreach ($n as $a) {

	$from=expand($a->from);
	$to=expand($a->to);
	//From/To IPv6
	$color="";
	$res=findLink($from,$to);
	if (is_array($res)){
		$from1=$res['source'];
		$to1=$res['target'];
		$rx="";
		$tx="";
		if (isset($linkData[$from1][$to1])) $rx=$linkData[$from1][$to1];
		if (isset($linkData[$to1][$from1])) $tx=$linkData[$to1][$from1];
		if ($rx>0 || $tx>0) { $color = " ,dashes:true"; $rx=$rx*-1; $tx=tx*-1;}
		$l=$rx . " - "  . $tx;
		$v=$rx +  $tx;
		$v=$v/2;

		if ($v>-30)
			$color .= ", color: { color: '#00ff00' }  ";
		elseif ($v>-50)
			$color .= ", color: { color: '#00cc00' }  ";
		elseif ($v<-30)
			$color .= ", color: { color: '#cccc00' }  ";
		elseif ($v<-70)
			$color .= ", color: { color: '#ff0000' }  ";

		$color .= ", label: '" . $l . "'";
	}

	echo  "{from:'" . $a->from . "', to: '" . $a->to . "' $color },\n";

}
?>


]);
  var container = document.getElementById('mynetwork');
 var data = {
        nodes: nodes,
        edges: edges
    };
    var options = {
        layout:{randomSeed:2}
};
    var network = new vis.Network(container, data, options);
//network.click =  function(selectionN, selectionE){
//	alert(selectionN);
//}

</script>
