<?php
$res= file_get_contents('https://raw.githubusercontent.com/tomeshnet/node-list/master/nodeList.json');
$nodes=json_decode($res);
foreach ($nodes as $node) {

        if (isset($node->IPV6Address)) {
                $wl[expand($node->IPV6Address)]=1;
        }
}

function expand($ip){
    $hex = unpack("H*hex", inet_pton($ip));         
    $ip = substr(preg_replace("/([A-f0-9]{4})/", "$1:", $hex['hex']), 0, -1);

    return $ip;
}

$l['85']="OP ONE";
$l['e099']="ATOM";
$l['6148']="PC";
$l['5e09']="Node2";
$l['39dc']="Node1";
$l['8583']="XPN";
$l['2a77']="PC";
$l['12a7']="GROUND";
$l['45e9']="Atlas";
$l['2873']="Maia";
$l['6389']="Pleione";
$l['8985']="stouvile";
$l['45d3']="transitiontech";
$l['a3c1']="ventricle";
$l['b274']="westmount";
$l['2758']="danforth";
if (isset($_REQUEST['noname'])) { unset($l); $l[]=0;}
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
                if (isset($l[$aa])) $aa=$l[$aa];
                $color="";
                if (!isset($wl[$a->from])) $color=", color:'#cccccc'";
                $label=$a->from;
                if(isset($a->pfrom)) $label.="\\n" . $a->pfrom;
                echo "{id:'" . $a->from . "', label: '" . $aa ."'$color , title:'" . $label . "'},\n";
        }
        if (!isset($test[$a->to])) {
                $aa=explode(":",$a->to);
                $aa=$aa[7];
                if (isset($l[$aa])) $aa=$l[$aa];
                $test[$a->to]=1;
                $color="";
                if (!isset($wl[$a->to])) $color=", color:'#cccccc'";
                $label=$a->to;
                if(isset($a->pto)) $label.="\\n" . $a->pto;
                echo "{id:'" . $a->to . "', label: '" . $aa ."'$color , title:'" . $label  . "'},\n ";
        }
}

?>
  ]);
    var edges = new vis.DataSet([
<?php foreach ($n as $a) {

        echo  "{from:'" . $a->from . "', to: '" . $a->to . "'},";


}
?>


]);
  var container = document.getElementById('mynetwork');
 var data = {
        nodes: nodes,
        edges: edges
    };
    var options = {};
    var network = new vis.Network(container, data, options);
//network.click =  function(selectionN, selectionE){
//      alert(selectionN);
//}

</script>

