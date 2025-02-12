<?php
include_once(dirname(__FILE__) . '/ressources/class.main_cf.inc');
include_once(dirname(__FILE__) . '/ressources/class.ldap.inc');
include_once(dirname(__FILE__) . "/ressources/class.sockets.inc");
include_once(dirname(__FILE__) . "/ressources/class.mysql.inc");



if(isset($_GET["install_status"])){install_status();exit;}
if(posix_getuid()<>0){
	$user=new usersMenus();
	if($user->AsSystemAdministrator==false){
		$tpl=new templates();
		echo $tpl->_ENGINE_parse_body("alert('{ERROR_NO_PRIVS}');");
		die();exit();
	}
}

	
	
if(isset($_GET["js"])){js();exit;}	
if(isset($_GET["popup"])){popup();exit;}

if(isset($_GET["mysqlstatus"])){echo mysql_status();exit;}
if(isset($_GET["main"])){echo mysql_main_switch();exit;}
if(isset($_GET["mysqlenable"])){echo mysql_enable();exit;}
if($_GET["script"]=="mysql_enabled"){echo js_mysql_enabled();exit;}
if($_GET["script"]=="mysql_save_account"){echo js_mysql_save_account();exit;}
if(isset($_GET["install_app"])){install_app();exit;}
if(isset($_GET["InstallLogs"])){GetLogsStatus();exit;}
if(isset($_GET["testConnection"])){testConnection();exit;}
if(isset($_GET["remove"])){remove();exit;}
if(isset($_GET["uninstall_app"])){remove_perform();exit;}
if(isset($_GET["remove-refresh"])){remove_refresh();exit;}
if(isset($_GET["ui-samba"])){install_remove_services();exit;}
if(isset($_GET["clear"])){clear();exit;}

if(posix_getuid()<>0){main_page();}

function js(){
if(posix_getuid()==0){return false;}	
$page=CurrentPageName();
$tpl=new templates();
$title=$tpl->_ENGINE_parse_body('{application_setup}');
$perform_operation_on_services_scheduled=$tpl->javascript_parse_text('{perform_operation_on_services_scheduled}');
$prefix="SetupControlCenter";
$html="
var {$prefix}timerID  = null;
var {$prefix}timerID1  = null;
var {$prefix}tant=0;
var {$prefix}reste=0;
var {$prefix}x_idname;
var {$prefix}x_product='';
var {$prefix}x_num=0;
var {$prefix}x_max=0;
var {$prefix}timeout=0;

function ChargeSetupControlCenter(){
	YahooSetupControl(820,'$page?popup=yes','$title');
	YahooWinHide();
	YahooWin0Hide();
	YahooWinSHide();
	setTimeout(\"{$prefix}Launch()\",300);
	}

function {$prefix}demarre(){
	if(!YahooSetupControlOpen()){return false;}
	{$prefix}tant = {$prefix}tant+1;
		if ({$prefix}tant <15 ) {                           
			{$prefix}timerID = setTimeout(\"{$prefix}demarre()\",5000);
	      } else {
					if(!YahooSetupControlOpen()){return false;}
					{$prefix}tant = 0;
					{$prefix}ChargeLogs();
					{$prefix}demarre();
	   }
	}



function {$prefix}ChargeLogs(){
	var selected = $('#main_setup_config').tabs('option', 'selected');
	var ll=$('#main_setup_config').tabs('length')-1;
	if(selected>0){	
		if(selected!==ll){
			RefreshTab('main_setup_config');
			SetupCenterRemoveRefresh();
			}
	}
}

function SetupCenterRemove(cmdline,appli){
	YahooWin(550,'$page?remove=yes&cmdline='+cmdline+'&appli='+appli);
	}
	
var x_SetupCenterRemoveRefresh= function (obj) {
	var results=obj.responseText;
	document.getElementById('remove_software').innerHTML=results;
}
	
function SetupCenterRemoveRefresh(){
	if(!YahooWinOpen()){return;}
	if(!document.getElementById('remove-app')){return;}
	if(!document.getElementById('remove-refresh')){return;}
	if(document.getElementById('remove-refresh').value!=='yes'){return;}
	var XHR = new XHRConnection();
	XHR.appendData('remove-refresh',document.getElementById('remove-app').value);
	XHR.sendAndLoad('$page', 'GET',x_SetupCenterRemoveRefresh);
}	

var x_RemoveSoftwareConfirm= function (obj) {
	var results=obj.responseText;
	document.getElementById('remove_software').innerHTML=results;
}

function RemoveSoftwareConfirm(app,cmdline){
 	var XHR = new XHRConnection();
	XHR.appendData('uninstall_app',cmdline);
	XHR.appendData('application_name',app);
	document.getElementById('remove-refresh').value='yes';
	document.getElementById('remove_software').innerHTML='<center><img src=\"img/wait_verybig.gif\"></center>';
	XHR.sendAndLoad('$page', 'GET',x_RemoveSoftwareConfirm);
	}
	
var x_ApplyInstallUninstallServices= function (obj) {
	alert('$perform_operation_on_services_scheduled');
	RefreshTab('main_setup_config');
}	
	
function ApplyInstallUninstallServices(){
	var XHR = new XHRConnection();
	XHR.appendData('ui-samba',document.getElementById('samba').value);
	XHR.appendData('ui-postfix',document.getElementById('postfix').value);
	XHR.appendData('ui-squid',document.getElementById('squid').value);
	document.getElementById('img_postfix').src='img/wait_verybig.gif';
	document.getElementById('img_samba').src='img/wait_verybig.gif';
	document.getElementById('img_squid').src='img/wait_verybig.gif';
	XHR.sendAndLoad('$page', 'GET',x_ApplyInstallUninstallServices);
	
}

var x_InstallRefresh= function (obj) {
	RefreshTab('main_setup_config');
}	

function InstallRefresh(){
	var XHR = new XHRConnection();
	XHR.appendData('clear','yes');
	XHR.sendAndLoad('$page', 'GET',x_InstallRefresh);
}
	  
	
var x_ApplicationSetup= function (obj) {
	var results=obj.responseText;
	alert(results);
	{$prefix}ChargeLogs();
}
	
function ApplicationSetup(app){
    var XHR = new XHRConnection();
	XHR.appendData('install_app',app);
	XHR.sendAndLoad('$page', 'GET',x_ApplicationSetup);
	}
	
function InstallLogs(app){
	{$prefix}timeout=0;
	{$prefix}x_product=app;
	YahooWin('630','$page?InstallLogs='+ app,app);
	setTimeout(\"{$prefix}LoupeProgress()\",500);
	
}
function {$prefix}LoupeProgress(){
	{$prefix}timeout={$prefix}timeout+1;
	if({$prefix}timeout>50){alert('timeout');return;}
	
	if(!document.getElementById('loupe-logs')){
		setTimeout(\"{$prefix}LoupeProgress()\",500);
		return;
	}
	{$prefix}timeout=0;
	Loadjs('setup.index.progress.php?product='+{$prefix}x_product);
   
	}

	function TestConnection(){
		YahooWin('600','$page?testConnection=yes','$title');
	}



function {$prefix}Launch(){
	{$prefix}timeout={$prefix}timeout+1;
	if({$prefix}timeout>10){
		alert('timeout!');
		return;
	}
	
	if(!document.getElementById('main_setup_config')){
		setTimeout(\"{$prefix}Launch()\",800);
	}
	
	{$prefix}timeout=0;
	{$prefix}demarre();
	{$prefix}ChargeLogs();
}
	


ChargeSetupControlCenter();

";

echo $html;
	
	
}

function popup(){
	


$tpl=new templates();
echo $tpl->_ENGINE_parse_body(mysql_tabs());
	
}


function remove(){
	
	$app=$_GET["appli"];
	$cmdline=$_GET["cmdline"];
	
	$html="
	<table style='width:100%'>
	<tr>
		<td valign='top'><img src='img/software-remove-128.png'></td>
		<td valign='top'>
		<center>
		<H3 style='font-size:22px;color:#005447'>{uninstall} {{$app}}</H3>
		<hr>
		<p style='font-size:14px'>{are_you_sure_to_delete} {{$app}} ???</p>
		<hr>
		
		</center>
		<input type='hidden' id='remove-refresh' value='no'>
		<input type='hidden' id='remove-app' value='$app'>
		<div id='remove_software' style='width:100%;height:300px;overflow:auto'>
		<center>". button("{uninstall} {{$app}}","RemoveSoftwareConfirm('$app','$cmdline')")."</center>
		</div>
		</td>
	</tr>
	</table>
		
	
	";
	
$tpl=new templates();
echo $tpl->_ENGINE_parse_body($html);	
}

function remove_perform(){
	$cmdline=base64_encode($_GET["uninstall_app"]);
	$sock=new sockets();
	$datas= unserialize(base64_decode($sock->getFrameWork("cmd.php?uninstall-app=".$cmdline."&app={$_GET["application_name"]}")));
	if(is_array($datas)){
		while (list ($num, $ligne) = each ($datas) ){
			echo "<div><code style='font-size:11px'>$ligne</code></div>";
		}
	}
	
}

function remove_refresh(){
	
	$app=$_GET["remove-refresh"];
	$file="/usr/share/artica-postfix/ressources/logs/UNINSTALL_$app";
	$datas=explode("\n",@file_get_contents($file));
	if(is_array($datas)){
		while (list ($num, $ligne) = each ($datas) ){
			echo "<div><code style='font-size:11px'>$ligne</code></div>";
		}
	}	
}

function index(){
	$back=Paragraphe("setup-90-back.png","{back_system}","{back_system_text}","javascript:Loadjs('system.index.php?js=yes&load-tab=services')");
	$prefix="SetupControlCenter";
	
$intro="

<table style='width:100%'>
	<tr>
	<td width=1% valign='top'>
	<div style='margin-right:30px;margin-bottom:5px'>$back</div>
	" . Paragraphe("64-recycle.png","{refresh_index_file}","{refresh_index_file}","javascript:TestConnection()")."

	</td>
	<td valign='top'>
		<p style='font-size:14px;letter-spacing:3px;color:black;line-height:150%;font-family:verdana,helvetica,arial,sans-serif'>{setup_index_explain}</p>
		<center><div id='mysql_status'></div></center>
	</td>
	</tr>
</table>
<input type='hidden' id='tabnum' name='tbanum' value='{$_GET["main"]}'>
<script>setTimeout(\"{$prefix}Launch()\",300);</script>";


$html="$intro";
$tpl=new templates();
echo $tpl->_ENGINE_parse_body($html);
}







	
function main_page(){
	$prefix="SetupControlCenter";	
$page=CurrentPageName();
	if($_GET["hostname"]==null){
		$user=new usersMenus();
		$_GET["hostname"]=$user->hostname;}
		$tpl=new templates();
		$title=$tpl->_ENGINE_parse_body('{refresh_index_file}');
	
	$html=
"<span id='scripts'><script type=\"text/javascript\" src=\"$page?script=load_functions\"></script></span>	
<script language=\"JavaScript\">       
".default_scripts()."
</script>		
	
	<table style='width:100%'>
	<tr>
	<td width=1% valign='top'><img src='img/setup-256.png'style='margin-right:30px;margin-bottom:5px'></td>
	<td valign='top'>
		<div id='mysql_status'></div>
		<table style='width:100%'>
		<tr>
			<td valign='top'>
		<p class='caption'>{setup_index_explain}</p>
		</td>
		<td><td align='right'>" . Paragraphe("64-recycle.png","{refresh_index_file}","{refresh_index_file}","javascript:TestConnection()")."
		</td>
		</tr>
		</table>
	</td>
	</tr>
	<tr>
		<td colspan=2 valign='top'>
			<table style='width:100%'>	
			<tr>
			<td valign='top'>
				<div id='main_setup_config'></div>
			</td>
			</tr>
			</table>
		</td>
	</tr>
	</table>
	<script>{$prefix}{demarre();{$prefix}ChargeLogs();LoadAjax('main_setup_config','$page?main=$num&hostname={$_GET["hostname"]}');</script>
	
	
	";
	
	$tpl=new template_users('{application_setup}',$html,0,0,0,0,$cfg);
	
	$sock=new sockets();
	$sock->getFrameWork('cmd.php?SetupCenter=yes');
	
	echo $tpl->web_page;
	
	
	
}

function mysql_tabs(){
	$page=CurrentPageName();
	$tpl=new templates();
	$users=new usersMenus();
	$array["index"]='{index}';
	if($users->SQUID_INSTALLED){
		$sock=new sockets();
		$SQUIDEnable=trim($sock->GET_INFO("SQUIDEnable"));
		if($SQUIDEnable==null){$SQUIDEnable=1;}
		if($SQUIDEnable==0){$user->SQUID_INSTALLED=false;}	
	}
	
	
	
	if($users->POSTFIX_INSTALLED){
		$array["smtp_packages"]='{smtp_packages}';
	}
	$array["stat_packages"]='{stat_packages}';
	if(!$users->KASPERSKY_SMTP_APPLIANCE){
		$array["web_packages"]='{web_packages}';
	}
	
	if($users->SQUID_INSTALLED){
		$array["proxy_packages"]='{proxy_packages}';
	}
	$array["system_packages"]='{setup_center_system}';
	
	if($users->SAMBA_INSTALLED){
		$array["samba_packages"]='{fileshare}';
		
	}
	if(!$users->KASPERSKY_SMTP_APPLIANCE){
		$array["service_family"]="{services_family}";
	}
	
	if($users->KASPERSKY_WEB_APPLIANCE){
		unset($array["service_family"]);
		unset($array["samba_packages"]);
		unset($array["web_packages"]);
		unset($array["smtp_packages"]);
	}
	
	if($users->ZARAFA_APPLIANCE){
		unset($array["web_packages"]);
	}
	
	while (list ($num, $ligne) = each ($array) ){
		if($_GET["main"]==$num){$class="id=tab_current";}else{$class=null;}
		$ligne=$tpl->_ENGINE_parse_body($ligne);
		$ligne_text= html_entity_decode($ligne,ENT_QUOTES,"UTF-8");
		if(strlen($ligne_text)>17){
			$ligne_text=substr($ligne_text,0,14);
			$ligne_text=htmlspecialchars($ligne_text)."...";
			$ligne_text=texttooltip($ligne_text,$ligne,null,null,1);
			}
		//$html=$html . "<li><a href=\"javascript:ChangeSetupTab('$num')\" $class>$ligne</a></li>\n";
		
		$html[]= "<li><a href=\"$page?main=$num\"><span>$ligne_text</span></li>\n";
			
		}
	$tpl=new templates();
	
	return "
	<div id=main_setup_config style='width:100%;height:550px;overflow:auto;background-color:white;'>
		<ul>". implode("\n",$html)."</ul>
	</div>
		<script>
				$(document).ready(function(){
					$('#main_setup_config').tabs({
				    load: function(event, ui) {
				        $('a', ui.panel).click(function() {
				            $(ui.panel).load(this.href);
				            return false;
				        });
				    }
				});
			

			});
		</script>";		
}



function mysql_status(){
	$tpl=new templates();
	$ini=new Bs_IniHandler();
	$sock=new sockets();
	$ini->loadString($sock->getfile('articamakestatus'));
	$status=DAEMON_STATUS_ROUND("ARTICA_MAKE",$ini,null);
	echo $tpl->_ENGINE_parse_body($status);
	}
function mysql_main_switch(){
	$tab=null;
	
	$users=new usersMenus();
	$sock=new sockets();
	$sock->getFrameWork('cmd.php?SetupCenter=yes');
	if(!isset($_GET["refresh"])){
		
	echo "
	<input type='hidden' id='main_array_setup_install_selected' value='{$_GET["main"]}'>
	<div style='text-align:right'>". imgtootltip("refresh-24.png","{refresh}","InstallRefresh()")."</div>
	<div id='main_array_setup_install_{$_GET["main"]}'>";
	}
	switch ($_GET["main"]) {
		case "index":echo $tab.index();break;
		case "smtp_packages":echo $tab.smtp_packages();break;
		case "stat_packages":echo $tab.stat_packages();break;
		case "web_packages":echo $tab.web_packages();break;
		case "proxy_packages":echo $tab.proxy_packages();break;
		case "samba_packages":echo $tab.samba_packages();break;
		case "system_packages":echo $tab.system_packages();break;
		case "xapian_packages":echo $tab.xapian_packages();break;
		case "service_family":echo services_family();break;
		
	
		default:
			if($users->POSTFIX_INSTALLED){
				echo $tab.smtp_packages();
				exit;
			}
			
			if($users->SQUID_INSTALLED){
				echo $tab.proxy_packages();
				exit;
			}

			if($users->SAMBA_INSTALLED){
				echo $tab.samba_packages();
				exit;
			}			
			echo $tab.system_packages();exit;
			
	}
	
		if(!isset($_GET["refresh"])){echo "</div>";}
}


function clear(){
	$sock=new sockets();
	$sock->SET_APC_STORE("GlobalApplicationsStatus",null);
	$sock->APC_CLEAN();
}

function smtp_packages(){
	


$users=new usersMenus();
$sock=new sockets();
$GlobalApplicationsStatus=$sock->APC_GET("GlobalApplicationsStatus",2);
if($GlobalApplicationsStatus==null){
	$GlobalApplicationsStatus=base64_decode($sock->getFrameWork('cmd.php?Global-Applications-Status=yes'));
	$sock->APC_SAVE("GlobalApplicationsStatus",$GlobalApplicationsStatus);
	$GLOBALS["GlobalApplicationsStatus"]=$GlobalApplicationsStatus;
}

$html="

<br>
<table style='width:100%;padding:2px:margin:3px;border:1px solid #CCCCCC'>
<tr style='background-color:#CCCCCC'>
<td>&nbsp;</td>
<td style='font-size:13px'><strong>{software}</strong></td>
<td style='font-size:13px' nowrap><strong>{current_version}</strong></td>
<td style='font-size:13px' nowrap><strong>{available_version}</strong></td>
<td style='font-size:13px'>&nbsp;</td>
<td style='font-size:13px'><strong>{status}</strong></td>
</tr>";




if($users->POSTFIX_INSTALLED){
	
	
	$html=$html.spacer('{CORE_PRODUCTS}');
	$html=$html.BuildRows("APP_POSTFIX",$GlobalApplicationsStatus,"postfix");
	if(!$users->ZARAFA_APPLIANCE){
		$html=$html.BuildRows("APP_CYRUS_IMAP",$GlobalApplicationsStatus,"cyrus-imapd",true);
	}
	$html=$html.BuildRows("APP_ZARAFA",$GlobalApplicationsStatus,"zarafa");
	
	
	$html=$html.spacer('{fetch_mails_family_products}');
	$html=$html.BuildRows("APP_FETCHMAIL",$GlobalApplicationsStatus,"fetchmail");
	$html=$html.BuildRows("APP_IMAPSYNC",$GlobalApplicationsStatus,"imapsync");

		
	
	$html=$html.spacer('{CONNEXIONS_FILTERS_PRODUCTS}');
	$html=$html.BuildRows("APP_MILTERGREYLIST",$GlobalApplicationsStatus,"milter-greylist");
	
	if(!$users->KASPERSKY_SMTP_APPLIANCE){
		$html=$html.spacer('{CONTENTS_FILTERS_PRODUCTS}');
		$html=$html.BuildRows("APP_SPAMASSASSIN",$GlobalApplicationsStatus,"Mail-SpamAssassin");
		$html=$html.BuildRows("APP_AMAVISD_MILTER",$GlobalApplicationsStatus,"amavisd-milter");
		$html=$html.BuildRows("APP_AMAVISD_NEW",$GlobalApplicationsStatus,"amavisd-new");
		$html=$html.BuildRows("APP_ASSP",$GlobalApplicationsStatus,"assp");
		$html=$html.BuildRows("APP_CLAMAV_MILTER",$GlobalApplicationsStatus,"clamav");
	}
	$html=$html.spacer('{LICENSED_FILTERS_PRODUCTS}');
	$html=$html.BuildRows("APP_KAS3",$GlobalApplicationsStatus,"kas");
	$html=$html.BuildRows("APP_KAVMILTER",$GlobalApplicationsStatus,"kavmilter");
	
	$html=$html.spacer('{MAIL_TOOLS}');
	$html=$html.BuildRows("APP_ALTERMIME",$GlobalApplicationsStatus,"altermime");
	if(!$users->KASPERSKY_SMTP_APPLIANCE){$html=$html.BuildRows("APP_POMMO",$GlobalApplicationsStatus,"pommo");}
	$html=$html.BuildRows("APP_MSMTP",$GlobalApplicationsStatus,"msmtp");
	$html=$html.BuildRows("APP_EMAILRELAY",$GlobalApplicationsStatus,"emailrelay");
	$html=$html.BuildRows("APP_STUNNEL",$GlobalApplicationsStatus,"stunnel");
	
	
	$html=$html.spacer('{STATS_TOOLS}');
	$html=$html.BuildRows("APP_MAILSPY",$GlobalApplicationsStatus,"mailspy");
	$html=$html.BuildRows("APP_PFLOGSUMM",$GlobalApplicationsStatus,"pflogsumm");
	
	
	
	
	
	}

$html=$html."</table>";
	
if(posix_getuid()==0){
		file_put_contents(dirname(__FILE__)."/ressources/logs/setup.index.".__FUNCTION__.".html",$html);
		return null;
}

$tpl=new templates();
return $tpl->_ENGINE_parse_body($html);
	
}
function stat_packages(){


$sock=new sockets();
$users=new usersMenus();
$GlobalApplicationsStatus=base64_decode($sock->getFrameWork('cmd.php?Global-Applications-Status=yes'));
$html="

<br>
<table style='width:100%;padding:2px:margin:3px;border:1px solid #CCCCCC'>
<tr style='background-color:#CCCCCC'>
<td>&nbsp;</td>
<td style='font-size:13px'><strong>{software}</strong></td>
<td style='font-size:13px'><strong>{current_version}</strong></td>
<td style='font-size:13px'><strong>{available_version}</strong></td>
<td style='font-size:13px'>&nbsp;</td>
<td style='font-size:13px'><strong>{status}</strong></td>
</tr>";

$html=$html.BuildRows("APP_COLLECTD",$GlobalApplicationsStatus,"collectd");
$html=$html.spacer('&nbsp;');
$html=$html.BuildRows("APP_GNUPLOT",$GlobalApplicationsStatus,"gnuplot");
$html=$html.BuildRows("APP_DSTAT",$GlobalApplicationsStatus,"dstat");
$html=$html.spacer('&nbsp;');

if($users->POSTFIX_INSTALLED){
	$html=$html.BuildRows("APP_ISOQLOG",$GlobalApplicationsStatus,"isoqlog");
}

$html=$html."</table>";

if(posix_getuid()==0){
		file_put_contents(dirname(__FILE__)."/ressources/logs/setup.index.".__FUNCTION__.".html",$html);
		return null;
}

$tpl=new templates();
return $tpl->_ENGINE_parse_body($html);
	
}

function web_packages(){

	
$sock=new sockets();
$users=new usersMenus();
$GlobalApplicationsStatus=$sock->APC_GET("GlobalApplicationsStatus",2);
if($GlobalApplicationsStatus==null){
	$GlobalApplicationsStatus=base64_decode($sock->getFrameWork('cmd.php?Global-Applications-Status=yes'));
	$sock->APC_SAVE("GlobalApplicationsStatus",$GlobalApplicationsStatus);
	$GLOBALS["GlobalApplicationsStatus"]=$GlobalApplicationsStatus;
}
$html="

<br>
<table style='width:100%;padding:2px:margin:3px;border:1px solid #CCCCCC'>
<tr style='background-color:#CCCCCC'>
<td>&nbsp;</td>
<td style='font-size:13px'><strong>{software}</strong></td>
<td style='font-size:13px'><strong>{current_version}</strong></td>
<td style='font-size:13px'><strong>{available_version}</strong></td>
<td style='font-size:13px'>&nbsp;</td>
<td style='font-size:13px'><strong>{status}</strong></td>
</tr>";
	$html=$html.spacer('Groupwares');
  if(!$users->KASPERSKY_SMTP_APPLIANCE){
		$html=$html.BuildRows("APP_DOTCLEAR",$GlobalApplicationsStatus,"dotclear");
		$html=$html.BuildRows("APP_LMB",$GlobalApplicationsStatus,"lmb");
		$html=$html.BuildRows("APP_OPENGOO",$GlobalApplicationsStatus,"opengoo");
		$html=$html.BuildRows("APP_GROUPOFFICE",$GlobalApplicationsStatus,"groupoffice-com");
		$html=$html.BuildRows("APP_DRUPAL",$GlobalApplicationsStatus,"drupal");
	}
if($users->cyrus_imapd_installed){
	$html=$html.spacer('webmails');
	$html=$html.BuildRows("APP_ROUNDCUBE",$GlobalApplicationsStatus,"roundcubemail");
	$html=$html.BuildRows("APP_ROUNDCUBE3",$GlobalApplicationsStatus,"roundcubemail3");	
	
	
	$html=$html.BuildRows("APP_ATOPENMAIL",$GlobalApplicationsStatus,"atmailopen");
}
if(!$users->KASPERSKY_SMTP_APPLIANCE){
	$html=$html.spacer('{APP_SUGARCRM}');
	$html=$html.BuildRows("APP_SUGARCRM",$GlobalApplicationsStatus,"SugarCE");	

	$html=$html.spacer('{APP_JOOMLA}');
	$html=$html.BuildRows("APP_JOOMLA",$GlobalApplicationsStatus,"joomla");
}
	//$html=$html.spacer('{optional}');
	//$html=$html.BuildRows("APP_GROUPWARE_APACHE",$GlobalApplicationsStatus,"httpd");
	//$html=$html.BuildRows("APP_GROUPWARE_PHP",$GlobalApplicationsStatus,"php");		
	
$html=$html."</table>";
	
if(posix_getuid()==0){
		file_put_contents(dirname(__FILE__)."/ressources/logs/setup.index.".__FUNCTION__.".html",$html);
		return null;
}
$tpl=new templates();
return $tpl->_ENGINE_parse_body($html);	
	
}

function proxy_packages(){

	
$sock=new sockets();
$users=new usersMenus();
$GlobalApplicationsStatus=$sock->APC_GET("GlobalApplicationsStatus",2);
if($GlobalApplicationsStatus==null){
	$GlobalApplicationsStatus=base64_decode($sock->getFrameWork('cmd.php?Global-Applications-Status=yes'));
	$sock->APC_SAVE("GlobalApplicationsStatus",$GlobalApplicationsStatus);
	$GLOBALS["GlobalApplicationsStatus"]=$GlobalApplicationsStatus;
}
$html="

<br>
<table style='width:100%;padding:2px:margin:3px;border:1px solid #CCCCCC'>
<tr style='background-color:#CCCCCC'>
<td>&nbsp;</td>
<td style='font-size:13px'><strong>{software}</strong></td>
<td style='font-size:13px'><strong>{current_version}</strong></td>
<td style='font-size:13px'><strong>{available_version}</strong></td>
<td style='font-size:13px'>&nbsp;</td>
<td style='font-size:13px'><strong>{status}</strong></td>
</tr>";
	$html=$html.spacer('{CORE_PRODUCTS}');
	$html=$html.BuildRows("APP_SQUID",$GlobalApplicationsStatus,"squid3");
	if(!$users->KASPERSKY_WEB_APPLIANCE){
		$html=$html.spacer('{STATS_TOOLS}');
		$html=$html.BuildRows("APP_SARG",$GlobalApplicationsStatus,"sarg");
	}
	
	$html=$html.spacer('{CONTENTS_FILTERS_PRODUCTS}');
	
	$html=$html.BuildRows("APP_SQUIDGUARD",$GlobalApplicationsStatus,"squidGuard");
	if(!$users->KASPERSKY_WEB_APPLIANCE){
		$html=$html.BuildRows("APP_DANSGUARDIAN",$GlobalApplicationsStatus,"dansguardian");
		$html=$html.BuildRows("APP_C_ICAP",$GlobalApplicationsStatus,"c-icap");
		$html=$html.BuildRows("APP_CLAMAV",$GlobalApplicationsStatus,"clamav");
	}
	
	$html=$html.spacer('{LICENSED_FILTERS_PRODUCTS}');
	$html=$html.BuildRows("APP_KAV4PROXY",$GlobalApplicationsStatus,"kav4proxy");
$html=$html."</table>";
	
if(posix_getuid()==0){
		file_put_contents(dirname(__FILE__)."/ressources/logs/setup.index.".__FUNCTION__.".html",$html);
		return null;
}

$tpl=new templates();
return $tpl->_ENGINE_parse_body($html);	
	
}

function xapian_packages(){
	
$sock=new sockets();
$users=new usersMenus();
$GlobalApplicationsStatus=$sock->APC_GET("GlobalApplicationsStatus",2);
if($GlobalApplicationsStatus==null){
	$GlobalApplicationsStatus=base64_decode($sock->getFrameWork('cmd.php?Global-Applications-Status=yes'));
	$sock->APC_SAVE("GlobalApplicationsStatus",$GlobalApplicationsStatus);
	$GLOBALS["GlobalApplicationsStatus"]=$GlobalApplicationsStatus;
}
$html="

<br>
<table style='width:100%;padding:2px:margin:3px;border:1px solid #CCCCCC'>
<tr style='background-color:#CCCCCC'>
<td>&nbsp;</td>
<td style='font-size:13px'><strong>{software}</strong></td>
<td style='font-size:13px'><strong>{current_version}</strong></td>
<td style='font-size:13px'><strong>{available_version}</strong></td>
<td style='font-size:13px'>&nbsp;</td>
<td style='font-size:13px'><strong>{status}</strong></td>
</tr>";
	$html=$html.spacer('{CORE_PRODUCTS}');
	$html=$html.BuildRows("APP_XAPIAN",$GlobalApplicationsStatus,"xapian-core");
	$html=$html.BuildRows("APP_CUPS_DRV",$GlobalApplicationsStatus,"cups-drv");	
	$html=$html.spacer('{LICENSED_FILTERS_PRODUCTS}');
	$html=$html.BuildRows("APP_KAV4SAMBA",$GlobalApplicationsStatus,"kav4samba");
	
	
$html=$html."</table>";


if(posix_getuid()==0){
		file_put_contents(dirname(__FILE__)."/ressources/logs/setup.index.".__FUNCTION__.".html",$html);
		return null;
}

$tpl=new templates();
return $tpl->_ENGINE_parse_body($html);		
	


}

function samba_packages(){
	
$sock=new sockets();
$EnableKav4fsFeatures=$sock->GET_INFO("EnableKav4fsFeatures");
if($EnableKav4fsFeatures==null){$EnableKav4fsFeatures=0;}

$users=new usersMenus();
$GlobalApplicationsStatus=$sock->APC_GET("GlobalApplicationsStatus",2);
if($GlobalApplicationsStatus==null){
	$GlobalApplicationsStatus=base64_decode($sock->getFrameWork('cmd.php?Global-Applications-Status=yes'));
	$sock->APC_SAVE("GlobalApplicationsStatus",$GlobalApplicationsStatus);
	$GLOBALS["GlobalApplicationsStatus"]=$GlobalApplicationsStatus;
}
$html="

<br>
<table style='width:100%;padding:2px:margin:3px;border:1px solid #CCCCCC'>
<tr style='background-color:#CCCCCC'>
<td>&nbsp;</td>
<td style='font-size:13px'><strong>{software}</strong></td>
<td style='font-size:13px'><strong>{current_version}</strong></td>
<td style='font-size:13px'><strong>{available_version}</strong></td>
<td style='font-size:13px'>&nbsp;</td>
<td style='font-size:13px'><strong>{status}</strong></td>
</tr>";
	$html=$html.spacer('{CORE_PRODUCTS}');
	$html=$html.BuildRows("APP_SAMBA",$GlobalApplicationsStatus,"samba");
	$html=$html.BuildRows("APP_CUPS_DRV",$GlobalApplicationsStatus,"cups-drv");
	$html=$html.BuildRows("APP_CUPS_BROTHER",$GlobalApplicationsStatus,"brother-drivers");
	$html=$html.BuildRows("APP_HPINLINUX",$GlobalApplicationsStatus,"hpinlinux");
	$html=$html.BuildRows("APP_SCANNED_ONLY",$GlobalApplicationsStatus,"scannedonly");			
	$html=$html.BuildRows("APP_PUREFTPD",$GlobalApplicationsStatus,"pure-ftpd");
	$html=$html.BuildRows("APP_BACKUPPC",$GlobalApplicationsStatus,"BackupPC");
	$html=$html.BuildRows("APP_MLDONKEY",$GlobalApplicationsStatus,"mldonkey");
	
	$html=$html.spacer('{LICENSED_FILTERS_PRODUCTS}');
	$html=$html.BuildRows("APP_KAV4SAMBA",$GlobalApplicationsStatus,"kav4samba");
	if($EnableKav4fsFeatures==1){
		$html=$html.BuildRows("APP_KAV4FS",$GlobalApplicationsStatus,"kav4fs");
	}
	
	
	
$html=$html."</table>";
	
if(posix_getuid()==0){
		file_put_contents(dirname(__FILE__)."/ressources/logs/setup.index.".__FUNCTION__.".html",$html);
		return null;
}

$tpl=new templates();
return $tpl->_ENGINE_parse_body($html);	
	
	
}

function system_packages(){
	

	
$sock=new sockets();
$users=new usersMenus();
$KASPERSKY_APPLIANCE=FALSE;
if($users->KASPERSKY_SMTP_APPLIANCE){$KASPERSKY_APPLIANCE=TRUE;}
if($users->KASPERSKY_WEB_APPLIANCE){$KASPERSKY_APPLIANCE=TRUE;}

$GlobalApplicationsStatus=$sock->APC_GET("GlobalApplicationsStatus",2);
if($GlobalApplicationsStatus==null){
	$GlobalApplicationsStatus=base64_decode($sock->getFrameWork('cmd.php?Global-Applications-Status=yes'));
	$sock->APC_SAVE("GlobalApplicationsStatus",$GlobalApplicationsStatus);
}

$html="

<br>
<table style='width:100%;padding:2px:margin:3px;border:1px solid #CCCCCC'>
<tr style='background-color:#CCCCCC'>
<td>&nbsp;</td>
<td style='font-size:13px'><strong>{software}</strong></td>
<td style='font-size:13px'><strong>{current_version}</strong></td>
<td style='font-size:13px'><strong>{available_version}</strong></td>
<td style='font-size:13px'>&nbsp;</td>
<td style='font-size:13px'><strong>{status}</strong></td>
</tr>";

if($users->VMWARE_HOST){
	$html=$html.BuildRows("APP_VMTOOLS",$GlobalApplicationsStatus,"VMwareTools");
}

	$html=$html.BuildRows("APP_MYSQL",$GlobalApplicationsStatus,"mysql-cluster-gpl");
	$html=$html.BuildRows("APP_PDNS",$GlobalApplicationsStatus,"pdns");	
	//$html=$html.BuildRows("APP_EACCELERATOR",$GlobalApplicationsStatus,"eaccelerator");
	if(!$KASPERSKY_APPLIANCE){$html=$html.BuildRows("APP_DAR",$GlobalApplicationsStatus,"dar");}
	$html=$html.BuildRows("APP_MSMTP",$GlobalApplicationsStatus,"msmtp");
	$html=$html.BuildRows("APP_EMAILRELAY",$GlobalApplicationsStatus,"emailrelay");
	$html=$html.BuildRows("APP_OCSI_LINUX_CLIENT",$GlobalApplicationsStatus,"OCSNG_LINUX_AGENT");
	
	
	
	
	if(!$KASPERSKY_APPLIANCE){$html=$html.BuildRows("APP_PUREFTPD",$GlobalApplicationsStatus,"pure-ftpd");}
	$html=$html.BuildRows("APP_SMARTMONTOOLS",$GlobalApplicationsStatus,"smartmontools");
	$html=$html.BuildRows("APP_PHPLDAPADMIN",$GlobalApplicationsStatus,"phpldapadmin");
	$html=$html.BuildRows("APP_PHPMYADMIN",$GlobalApplicationsStatus,"phpMyAdmin");
	
	
	
 if(!$KASPERSKY_APPLIANCE){
		$html=$html.BuildRows("APP_CLAMAV",$GlobalApplicationsStatus,"clamav");
		$html=$html.BuildRows("APP_AMACHI",$GlobalApplicationsStatus,"hamachi");
		$html=$html.BuildRows("APP_MLDONKEY",$GlobalApplicationsStatus,"mldonkey");
		$html=$html.spacer('{computers_management}');
		$html=$html.BuildRows("APP_NMAP",$GlobalApplicationsStatus,"nmap");
		$html=$html.BuildRows("APP_WINEXE",$GlobalApplicationsStatus,"winexe-static");
		$html=$html.BuildRows("APP_OCSI",$GlobalApplicationsStatus,"OCSNG_UNIX_SERVER");
		}
	
	
if(!$KASPERSKY_APPLIANCE){$html=$html.spacer('{xapian_packages}');
	$html=$html.BuildRows("APP_XAPIAN",$GlobalApplicationsStatus,"xapian-core");
	$html=$html.BuildRows("APP_XAPIAN_OMEGA",$GlobalApplicationsStatus,"xapian-omega");
	$html=$html.BuildRows("APP_XAPIAN_PHP",$GlobalApplicationsStatus,"xapian-bindings");
	$html=$html.BuildRows("APP_XPDF",$GlobalApplicationsStatus,"xpdf");
	//$html=$html.BuildRows("APP_UNZIP",$GlobalApplicationsStatus,"unzip");
	$html=$html.BuildRows("APP_UNRTF",$GlobalApplicationsStatus,"unrtf");
	$html=$html.BuildRows("APP_CATDOC",$GlobalApplicationsStatus,"catdoc");		
	$html=$html.BuildRows("APP_ANTIWORD",$GlobalApplicationsStatus,"antiword");	
}
	$html=$html."</table>";
	
if(posix_getuid()==0){
		file_put_contents(dirname(__FILE__)."/ressources/logs/setup.index.".__FUNCTION__.".html",$html);
		return null;
}	

$tpl=new templates();
return $tpl->_ENGINE_parse_body($html);	
	
	
}
function ParseAppli($status,$key){

if(!is_array($GLOBALS["GLOBAL_VERSIONS_CONF"])){BuildVersions();}
return $GLOBALS["GLOBAL_VERSIONS_CONF"][$key];	
}

function ParseUninstall($SockStatus,$appli){
	if($SockStatus==null){$SockStatus=$GLOBALS["GlobalApplicationsStatus"];}
	$ini=new Bs_IniHandler();
	$ini->loadString($SockStatus);

	if(is_array($ini->_params)){
	while (list ($num, $line) = each ($ini->_params) ){
		if($line["service_name"]==$appli){
			if($ini->_params[$num]["remove_cmd"]<>null){
				return $ini->_params[$num]["remove_cmd"];
				}
			}
	}	}

}



function BuildVersions(){
	$GlobalApplicationsStatus=@file_get_contents("/usr/share/artica-postfix/ressources/logs/global.versions.conf");
	
	if(strlen($GlobalApplicationsStatus)<150){
		if(posix_getuid()==0){
			shell_exec("/usr/share/artica-postfix/bin/artica-install --write-versions");
			$GlobalApplicationsStatus=@file_get_contents("/usr/share/artica-postfix/ressources/logs/global.versions.conf");
		}
	}
	
	
	
	
	
	$tb=explode("\n",$GlobalApplicationsStatus);
	while (list ($num, $line) = each ($tb) ){
		if(preg_match('#\[(.+?)\]\s+"(.+?)"#',$line,$re)){
			$GLOBALS["GLOBAL_VERSIONS_CONF"][trim($re[1])]=trim($re[2]);
		}
		
	}
}


function spacer($text){
	
return "
<tr style='background-image:url(img/bg_row.jpg)'>
	<td colspan=6 style='padding-top:4px'><span style='font-size:13px;font-weight:bold;text-transform:capitalize;color:black'>$text</td>
</tr>
";
	
}


function BuildRows($appli,$SockStatus,$internetkey,$noupgrade=false){
	$ini=new Bs_IniHandler();
	$ini->loadFile(dirname(__FILE__). '/ressources/index.ini');
	$tpl=new templates();
	$button_text=$tpl->_parse_body('{install_upgrade}');
	if(strlen($button_text)>27){$button_text=substr($button_text,0,24)."...";}
	$bgcolor="style='background-color:#DFFDD6'";
	$version=ParseAppli($SockStatus,$appli);
	$uninstall=ParseUninstall($SockStatus,$appli);
	if(($version=="0") OR (strlen($version)==0)){
		$version="{not_installed}";
		$bgcolor=null;
		$uninstall=null;
	}
	
	if(file_exists(dirname(__FILE__). "/ressources/install/$appli.dbg")){
		$dbg_exists=imgtootltip('22-logs.png',"{events}","InstallLogs('$appli')");
		$styledbg="background-color:yellow;border:1px solid black";
	
		}
		else{$dbg_exists="<img src='img/fw_bold.gif'>";
		}
		
	$appli_text=$tpl->javascript_parse_text("{{$appli}}");
	$appli_text=html_entity_decode($appli_text,ENT_QUOTES,"UTF-8");
	
	if(strlen($appli_text)>30){$appli_text=texttooltip(htmlentities(substr($appli_text,0,27))."...",htmlentities($appli_text),null,null,1);}
	$button_install=button($button_text,"ApplicationSetup('$appli')");
	
	
	// UNINSTALL
	if($uninstall<>null){
		$version=
		"<table><tr><td style='font-size:13px' valign='middle'>$version</td>
			<td valign='middle'>".imgtootltip("ed_delete.gif","{uninstall} {{$appli}}","SetupCenterRemove('$uninstall','$appli')")."</td></tr></table>";
	}
	
	
	if($ini->_params["NEXT"]["$internetkey"]==null){
		$ini->_params["NEXT"]["$internetkey"]="<div style='color:red'>{error_network}</div>";
		$button_install=null;
		}
		
	if($noupgrade){$button_install=null;}
	
	return "
	<tr $bgcolor>
		<td width=2% style=\"$styledbg\">$dbg_exists</td>
		<td style='font-size:13px' nowrap>$appli_text</td>
		<td style='font-size:13px'>$version</td>
		<td style='font-size:13px'>{$ini->_params["NEXT"]["$internetkey"]}</td>
		<td style='font-size:11px'>$button_install</td>
		<td style='font-size:13px'><div style='width:100px;height:22px;border:1px solid #CCCCCC' id='STATUS_$appli'>".install_status($appli)."</div></td>
	</tr>
	";	
	
}


function install_app(){
	$sock=new sockets();
	$sock->getfile("CheckDaemon");
	$sock->getfile("install_app:{$_GET["install_app"]}");
	$tpl=new templates();
	$echo="{{$_GET["install_app"]}}\n{installation_lauched}";
	
	$echo=html_entity_decode(strip_tags($tpl->_ENGINE_parse_body($echo)));
	echo replace_accents($echo);
	
	
}

function install_status($appli){
	$appname=$appli;
	$ini=new Bs_IniHandler();
	$dbg_exists=false;
	if(file_exists(dirname(__FILE__). "/ressources/install/$appname.ini")){
	    $data=file_get_contents(dirname(__FILE__). "/ressources/install/$appname.ini");
		$ini->loadString($data);
		$status=$ini->_params["INSTALL"]["STATUS"];
		$text_info=$ini->_params["INSTALL"]["INFO"];
		writelogs("Loading ressources/install/$appname.ini; status:$status",__FUNCTION__,__FILE__);
		if(strlen($text_info)>0){$text_info="<span style='color:black;font-size:10px'>$text_info...</span>";}
		
	}else{
		//writelogs("Loading ressources/install/$appname.ini doesn't exists",__FUNCTION__,__FILE__);
	}
	
	if($status==null){$status=0;}
	if($status>100){$color="#D32D2D";$status=100;$text='{failed}';}else{$color="#5DD13D";$text=$status.'%';}
	$tpl=new templates();
	return  $tpl->_ENGINE_parse_body("
		<div style='width:{$status}px;text-align:center;color:white;padding-top:3px;padding-bottom:3px;background-color:$color'>
			<strong>{$text}&nbsp;$text_info</strong>
		</div>");
	
writelogs("Loading $appname status ($status) done",__FUNCTION__,__FILE__);	
}

function GetLogsStatus(){
			$sock=new sockets();
			$tb=unserialize(base64_decode($sock->getFrameWork("cmd.php?AppliCenterGetDebugInfos={$_GET["InstallLogs"]}")));	
			writelogs(count($tb). " lines number for {$_GET["InstallLogs"]}",__FUNCTION__,__FILE__);
			$start=0;
			if(count($tb)>200){$start=count($tb)-200;}
			if(is_array($tb)){
			for($i=$start;$i<count($tb);$i++){
				$count=$count=1;
				$line=$tb[$i];
				if(trim($line)==null){continue;}
					$line=htmlentities($line);
					if(substr($line,0,1)=="#"){continue;}
					if(preg_match('#[0-9]+\.[0-9]+\%#',$line)){continue;}
					$line=wordwrap($line, 70, " ", true);
					$ligne[]="<div style='border-bottom:1px dotted #CCCCCCC;font-size:10px'>$line</div>";
				
			}
			}
			if(is_array($ligne)){
			$html="<div style='width:600px;height:450px;padding:5px;border:1px solid #CCCCCC;overflow:auto;background-color:white' id='loupe-logs'>".implode("\n",$ligne)."</div>";
			}
			writelogs(count($tb). " lines number for {$_GET["InstallLogs"]} finish",__FUNCTION__,__FILE__);
			echo $html;
	
}

function testConnection(){
	$sock=new sockets();
	$datas=$sock->getFrameWork('cmd.php?SetupIndexFile=yes');
	$tbl=explode("\n",$datas);
	while (list ($num, $line) = each ($tbl) ){
		if(trim($line)==null){continue;}
		$line=htmlentities($line);
		$ligne[]="<div style='border-bottom:1px dotted #CCCCCCC;font-size:10px'>$line</div>";
	}
	if(is_array($ligne)){
		$logs=RoundedLightWhite(implode("\n",$ligne));
	}
	$html="<H1>{refresh_index_file}</H1>
	<div style='width:100%;height:250px;overflow:auto'>$logs</div>
	
	";
	
	$tpl=new templates();
	echo $tpl->_ENGINE_parse_body($html);
	
}

function services_family(){
	// perform_operation_on_services_scheduled
	$users=new usersMenus();
	if($users->POSTFIX_INSTALLED){$postfix=1;}else{$postfix=0;}
	if($users->SAMBA_INSTALLED){$samba=1;}else{$samba=0;}
	if($users->SQUID_INSTALLED){$squid=1;}else{$squid=0;}
	$postfix=Paragraphe_switch_img("{messaging_service}","{messaging_service_text}","postfix",$postfix);
	$samba=Paragraphe_switch_img("{filesharing_service}","{filesharing_service_text}","samba",$samba);
	$squid=Paragraphe_switch_img("{webproxy_service}","{webproxy_service_text}","squid",$squid);				
	
	
	$html="
	<input type='hidden' id='tabfamily' value='no'>
	<p style='font-size:13px;font-weight:bold'>{services_family_text}</p>
	<table style='width:100%'>
	<tr>
		<td valign='top'>$postfix</td>
		<td valign='top'>$samba</td>
		<td valign='top'>$squid</td>
	</tr>
	</table>
	
	<div style='width:100%;text-align:right'>
		<hr>". button("{apply}","ApplyInstallUninstallServices()")."
	</div>
	
		
	";
	

	
	$tpl=new templates();
	return $tpl->_ENGINE_parse_body($html);
	
}

function install_remove_services(){
	$sock=new sockets();
	$users=new usersMenus();
	if($_GET["ui-postfix"]==0){
		$sock->getFrameWork("cmd.php?uninstall-app=". base64_encode("--postfix-remove")."&app=APP_POSTFIX");
		
	}
	if($_GET["ui-postfix"]==1){
		if(!$users->POSTFIX_INSTALLED){
			$sock->getFrameWork("cmd.php?services-install=". base64_encode("--check-postfix")."&app=APP_POSTFIX");
		}
		
	}
	
	if($_GET["ui-samba"]==0){
		$sock->getFrameWork("cmd.php?uninstall-app=". base64_encode("--samba-remove")."&app=APP_SAMBA");
		
	}	

	if($_GET["ui-samba"]==1){
		if(!$users->SAMBA_INSTALLED){
			$sock->getFrameWork("cmd.php?services-install=". base64_encode("--check-samba")."&app=APP_SAMBA");
		}
		
	}	

	if($_GET["ui-squid"]==0){
		$sock->getFrameWork("cmd.php?uninstall-app=". base64_encode("--squid-remove")."&app=APP_SQUID");
		
	}	

	if($_GET["ui-squid"]==1){
		if(!$users->SQUID_INSTALLED){
			$sock->getFrameWork("cmd.php?services-install=". base64_encode("--check-squid")."&app=APP_SAMBA");
		}
		
	}		
	
}

?>
