<?php
	include_once('ressources/class.templates.inc');
	include_once('ressources/class.ldap.inc');
	include_once('ressources/class.users.menus.inc');
	include_once('ressources/class.main_cf.inc');
	
	
	

	if(isset($_GET["ShowOrganizations"])){echo ShowOrganizations();exit;}
	if(isset($_GET["ajaxmenu"])){echo "<div id='orgs'>".ShowOrganizations()."</div>";exit;}
	if(isset($_GET["butadm"])){echo butadm();exit;}
	if(isset($_GET["LoadOrgPopup"])){echo LoadOrgPopup();exit;}
	if(isset($_GET["js"])){js();exit;}
	if(isset($_GET["js-pop"])){popup();exit;}
	if(isset($_GET["countdeusers"])){COUNT_DE_USERS();exit;}
	
function js(){
	if(GET_CACHED(__FILE__,__FUNCTION__,"js")){return;}
	$tpl=new templates();
	$title=$tpl->_ENGINE_parse_body("{organizations}");
	$page=CurrentPageName();
	$html="
	var timeout=0;
	
	function LoadOrg(){
			
		$('#BodyContent').load('$page?js-pop=yes', function() {Orgfillpage();});
		//LoadWinORG('760','$page?js-pop=yes','$title');
		//setTimeout('Orgfillpage()',900);
	}
	
	function Orgfillpage(){
		timeout=timeout+1;
		if(timeout>10){return;}
		if(!document.getElementById('orgs')){
			setTimeout('Orgfillpage()',900);
			return;
		}
		LoadAjax('orgs','$page?ShowOrganizations=yes');
		OrgfillpageButton();
	}
	
	function OrgfillpageButton(){
	var content=document.getElementById('orgs').innerHTML;
	if(content.length<90){
		setTimeout('OrgfillpageButton()',900);
		return;
	}
	
	LoadAjax('butadm','$page?butadm=yes');
	
	}
	
	LoadOrg();
	";
	
	SET_CACHED(__FILE__,__FUNCTION__,"js",$html);
	echo $html;
	
}

function popup(){
	
if(GET_CACHED(__FILE__,__FUNCTION__,__FUNCTION__)){return;}

	$ldap=new clladp();
	$usersnumber=$ldap->COUNT_DE_USERS();
	$ldap->ldap_close();
	$tpl=new templates();
	$users=$tpl->_ENGINE_parse_body("<i>{this_server_store}:&nbsp;<strong>$usersnumber</strong>&nbsp;{users}</i>");

$page=CurrentPageName();	
$html="<H1>{organizations}</H1>
<input type='hidden' name='add_new_organisation_text' id='add_new_organisation_text' value='{add_new_organisation_text}'>
<div style='font-size:16px;text-align:left;padding-bottom:5px;border-bottom:1px solid #CCCCCC'>{about_organization}</div>
<div style='font-size:11px;text-align:right;padding-top:5px;'><span id='countdeusers'>$users</span></div>
<div id='orgs' style='width:720px;height:350px;overflow:auto'></div>

";	

$tpl=new templates();
$html=$tpl->_ENGINE_parse_body($html);
SET_CACHED(__FILE__,__FUNCTION__,__FUNCTION__,$html);
echo $html;
}

function ShowOrganizations(){
	$usersmenus=new usersMenus();
	if($usersmenus->AsArticaAdministrator==true){$orgs=ORGANISATIONS_LIST();}else{
		if($usersmenus->AllowAddGroup==true && $usersmenus->AsArticaAdministrator==false){$orgs=ORGANISTATION_FROM_USER();}
	}
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($orgs);

	
}

function butadm(){
	$usersmenus=new usersMenus();
	if($usersmenus->AsArticaAdministrator==true){
	$html=Paragraphe('folder-addorg-64.png','{add_new_organisation}','{add_new_organisation_explain}','javascript:TreeAddNewOrganisation();',null,220,100);}
	$tpl=new templates();
	return $tpl->_ENGINE_parse_body($html);
	echo $tpl->_ENGINE_parse_body($html);		
	}


function ORGANISTATION_FROM_USER(){
	$ldap=new clladp();
	$hash=$ldap->Hash_Get_ou_from_users($_SESSION["uid"],1);
	$ldap->ldap_close();
	if(!is_array($hash)){return null;}
	return Paragraphe('folder-org-64.jpg',"{manage} &laquo;{$hash[0]}&raquo;","<strong>{$hash[0]}:<br></strong>{manage_organisations_text}",'domains.manage.org.index.php?ou='.$hash[0]);
	
	
}

function ORGANISATIONS_LIST(){
	$ldap=new clladp();
	$page=CurrentPageName();
	$hash=$ldap->hash_get_ou(true);
	$users=new usersMenus();
	if(!is_array($hash)){return null;}
	ksort($hash);
	
	if(!$ldap->BuildOrganizationBranch()){
		$error="<div style='float:left'>".Paragraphe("danger64.png","{GENERIC_LDAP_ERROR}",$ldap->ldap_last_error)."</div>";
	}

	
$page=CurrentPageName();
		


if(isset($_GET["ajaxmenu"])){$header="
	<input type='hidden' name='add_new_organisation_text' id='add_new_organisation_text' value='{add_new_organisation_text}'>
	<input type='hidden' name='ajaxmenu' id='ajaxmenu' value='yes'>";
	}

	
	$html="
	$header
	<div style='width:700px;height:300px'>$error";

	if(isset($_GET["ajaxmenu"])){$ajax=true;}
	
	$html=$html."<div style='float:left'>".butadm()."</div>";
	
	while (list ($num, $ligne) = each ($hash) ){
		$md=md5($ligne);
		$uri="javascript:Loadjs('domains.manage.org.index.php?js=yes&ou=$ligne');";
		if($ajax){
			$uri="javascript:Loadjs('$page?LoadOrgPopup=$ligne');";
		}
		
		$img=$ldap->get_organization_picture($ligne,64);
		

		$html=$html . "<div style='float:left'>" . Paragraphe($img,"{manage} $ligne","
		<strong>$ligne:<br></strong>{manage_organisations_text}",$uri,null,220,100) . "</div>
		";
		
	}
	
	if($users->POSTFIX_INSTALLED){
		$sendmail="<div style='float:left'>".Buildicon64('DEF_ICO_SENDTOALL',220,100)."</div>";
		
	}
	
	if(isset($_GET["ajaxmenu"])){
		$html=$html."
		<div style='float:left'>" .butadm()."</div>";
		
		
	}
	
	$ldap->ldap_close();
	return $html."$sendmail</div>";
}

function LoadOrgPopup(){
	
	echo "
	Loadjs('js/artica_organizations.js');
	Loadjs('js/artica_domains.js');
	YahooWin(750,'domains.manage.org.index.php?org_section=0&SwitchOrgTabs={$_COOKIE["SwitchOrgTabs"]}&ou={$_GET["LoadOrgPopup"]}&ajaxmenu=yes','ORG::{$_GET["LoadOrgPopup"]}');
	
	";
	
	
	
	
	
}


	