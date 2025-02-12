<?php
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.artica.inc');
	include_once('ressources/class.groups.inc');
	include_once('ressources/class.user.inc');
	
	//if(count($_POST)>0)
	$usersmenus=new usersMenus();
	if(!$usersmenus->AllowAddUsers){
		writelogs("Wrong account : no AllowAddUsers privileges",__FUNCTION__,__FILE__);
		if(isset($_GET["js"])){
			$tpl=new templates();
			$error="{ERROR_NO_PRIVS}";
			echo $tpl->_ENGINE_parse_body("alert('$error')");
			die();
		}
		header("location:domains.manage.org.index.php?ou={$_GET["ou"]}");
		}
		
		if(isset($_GET["popup"])){popup();exit;}
		if(isset($_GET["find-member"])){echo find_member();exit;}
		
js();


function js(){
	
	$page=CurrentPageName();
	$prefix=str_replace('.',"_",$page);
	$tpl=new templates();
	$title=$tpl->_ENGINE_parse_body("{find_members}");
	$find=$tpl->_ENGINE_parse_body("{find}");
	$ou=$_GET["ou"];
	$ou_encrypted=base64_encode($ou);
$html="
	function {$prefix}Load(){
		YahooWin(500,'$page?popup=yes&ou=$ou_encrypted','$title');
	
	}
	
var x_FIndMember= function (obj) {
				var results=obj.responseText;
				document.getElementById('search-results').innerHTML=results;
			}	
	
	function FIndMember(){
		var XHR = new XHRConnection();
		var pattern=document.getElementById('find-member').value;
		document.getElementById('search-results').innerHTML='<center><H2>$find<br>'+pattern+'</H2></center><hr><center><img src=\"img/wait_verybig.gif\"></center>';
		XHR.appendData('find-member',pattern);
		XHR.appendData('ou','$ou');
		XHR.sendAndLoad('$page', 'GET',x_FIndMember);	
	}
	
	function FindMemberPress(e){
		if(checkEnter(e)){FIndMember();}
	}
	
	{$prefix}Load();
	
	";
	echo $html;
}

function popup(){
	if(is_base64_encoded($_GET["ou"])){$_GET["ou"]=base64_decode($_GET["ou"]);}
	
	$form="<table style='width:100%;margin:0px;padding:0px'>
	<tr>
		<td style='margin:0px;padding:0px'>". Field_text("find-member",null,'width:100%;font-size:12px;padding:5px;margin:5px',null,null,null,false,"FindMemberPress(event)")."</td>
	</tr>
	</table>";
	
	
	$html="<H2>{find_members}</H2>
	$form
	<hr>
	<div id='search-results' style='width:100%;height:350px;overflow:auto'>". find_member()."</div>";
	

$tpl=new templates();	
echo $tpl->_ENGINE_parse_body($html);	
}

function find_member(){
	$tofind=$_GET["find-member"];
	if($_SESSION["uid"]==-100){$ou=$_GET["ou"];}else{$ou=$_SESSION["ou"];}
	$ldap=new clladp();
	if(is_base64_encoded($ou)){$ou=base64_decode($ou);}
	if($tofind==null){$tofind='*';}else{$tofind="*$tofind*";}
	$tofind=str_replace('***','*',$tofind);
	writelogs("FIND $tofind IN OU \"$ou\"",__FUNCTION__,__FILE__,__LINE__);
	
	$filter="(&(objectClass=userAccount)(|(cn=$tofind)(mail=$tofind)(displayName=$tofind)(uid=$tofind) (givenname=$tofind) ))";
	$attrs=array("displayName","uid","mail","givenname","telephoneNumber","title","sn","mozillaSecondEmail","employeeNumber");
	$dn="ou=$ou,dc=organizations,$ldap->suffix";
	$hash=$ldap->Ldap_search($dn,$filter,$attrs,20);
	
	$users=new user();
	
	$number=$hash["count"];
	
	for($i=0;$i<$number;$i++){
		$user=$hash[$i];
		$html=$html .formatUser($user);
		
	}
	return $html;
}


function formatUser($hash){
	
	$html="<table style='width:100%'>
	<tr>
		<td colspan=2>
			<span style='font-size:14px;font-weight:bold;text-transform:capitalize'>{$hash["displayname"][0]}</span>&nbsp;-&nbsp;
			<span style='font-size:10px;font-weight:bold;text-transform:capitalize'>{$hash["sn"][0]}&nbsp;{$hash["givenname"][0]}</span>
			
			<hr style='border:1px solid #FFF;margin:3px'>
			</td>
	</tr>
	<tr>
		<td align='right'><span style='font-size:10px;font-weight:bold'>{$hash["title"][0]}</span>&nbsp;|&nbsp;{$hash["mail"][0]}&nbsp;|&nbsp;{$hash["telephonenumber"][0]}
	</table>
	
	";
	
	
	$js=MEMBER_JS($hash["uid"][0],1);
	$html=RoundedLightGrey($html,$js,1);
	$html="<div style='margin:5px;padding-right:10px;padding-left:10px'>$html</div>";
	return $html;
	
	
}
	
	


?>