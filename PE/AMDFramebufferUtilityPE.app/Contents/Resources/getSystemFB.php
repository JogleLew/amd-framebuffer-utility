<?php
function padHex($d,$l) {return str_pad(dechex($d),$l,'0',STR_PAD_LEFT);}
function toHex($s){$i=0;$t='';while(isset($s[$i])){$t.=padHex(ord($s[$i++]),2);}return $t;}
function toStr($h){$s='';$i=4;while($i-->0){$s.=chr($h>>(8*$i)&0xFF);}return $s;}
$ctype=array('02000000'=>'LVDS','04000000'=>'DDVI','80000000'=>'SVIDEO','10000000'=>'VGA','00020000'=>'SDVI','00040000'=>'DP','00080000'=>'HDMI','00100000'=>'????');
foreach(glob('/System/Library/Extensions/'.(file_exists('/System/Library/Extensions/AMD6000Controller.kext') ? 'AMD' : 'ATI').'*Controller.kext') as $file) {
	echo str_pad(substr(strrchr($file,'/'),1),72,'-',STR_PAD_BOTH)."\n\n";
	$file=array_pop(glob("$file/Contents/MacOS/*"));
	$a=popen("/tmp/otool -XvQt $file",'r');
	$b=fopen($file,'r');
	while ($l=fgets($a)) {
		if (strncmp($l,'__ZN',4)!=0 || ($i=strpos($l,'Info10createInfo'))===false) continue;
		$f=new stdClass();
		$f->name=substr($l,5+is_numeric($l[5]),$i-5-is_numeric($l[5]));
		while(($l=fgets($a)) && strpos($l,'ret')===false) {
			if (strpos($l,'leaq')!==false) $f->addr=hexdec(substr($l,6,strpos($l,'(')-6));
			if (!isset($f->ports) && strpos($l,"movb\t$")!==false) $f->ports=hexdec(substr($l,strpos($l,'$'),strpos($l,',')-strpos($l,'$')))&0xFF;
			if (strpos($l,'jl')!==false) $i=hexdec(substr($l,4));
			if (strpos($l,'jmp')!==false) $i=hexdec(substr($l,4)) + 0x1A;
		}
		$f->addr+=$i;
		echo "$f->name ($f->ports) @ 0x".dechex($f->addr)."\n";
		$t=$p=array();
		fseek($b,$f->addr);
		while($f->ports-- > 0) $p[]=$ctype[substr($t[]=toHex(fread($b,16)),0,8)];
		echo implode(', ',$p)."\n";
		echo implode("\n",$t)."\n\n";
	}
	pclose($a);
	fclose($b);
}