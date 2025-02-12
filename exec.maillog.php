<?php
include_once(dirname(__FILE__).'/ressources/class.templates.inc');
include_once(dirname(__FILE__).'/ressources/class.ini.inc');
include_once(dirname(__FILE__).'/ressources/class.os.system.inc');
include_once(dirname(__FILE__).'/framework/frame.class.inc');
include_once(dirname(__FILE__).'/framework/class.unix.inc');

if(posix_getuid()<>0){die("Cannot be used in web server mode\n\n");}

if(!Build_pid_func(__FILE__,"MAIN")){
	writelogs(basename(__FILE__).":Already executed.. aborting the process",basename(__FILE__),__FILE__,__LINE__);
	die();
}

$pid=getmypid();
$pidfile="/etc/artica-postfix/".basename(__FILE__).".pid";
$sock=new sockets();
$unix=new unix();
events("running $pid ");
file_put_contents($pidfile,$pid);
smtp_hack_reconfigure();
include_once(dirname(__FILE__).'/ressources/class.ini.inc');
include_once(dirname(__FILE__).'/ressources/class.users.menus.inc');
$users=new usersMenus();
$_GET["server"]=$users->hostname;
$_GET["IMAP_HACK"]=array();
$GLOBALS["POP_HACK"]=array();
$GLOBALS["SMTP_HACK"]=array();
$GLOBALS["PHP5_BIN"]=LOCATE_PHP5_BIN2();
$GLOBALS["PopHackEnabled"]=$sock->GET_INFO("PopHackEnabled");
$GLOBALS["PopHackCount"]=$sock->GET_INFO("PopHackCount");
if($GLOBALS["PopHackEnabled"]==null){$GLOBALS["PopHackEnabled"]=1;}
if($GLOBALS["PopHackCount"]==null){$GLOBALS["PopHackCount"]=10;}
$GLOBALS["MYPATH"]=dirname(__FILE__);
$GLOBALS["SIEVEC_PATH"]=$unix->LOCATE_SIEVEC();
$GLOBALS["SMTP_HACK_CONFIG_RATE"]["NAME_SERVICE_NOT_KNOWN"]=10;
$GLOBALS["SMTP_HACK_CONFIG_RATE"]["SASL_LOGIN"]=15;
$GLOBALS["SMTP_HACK_CONFIG_RATE"]["RBL"]=5;
$GLOBALS["SMTP_HACK_CONFIG_RATE"]["USER_UNKNOWN"]=10;
$GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]=5;

$GLOBALS["postfix_bin_path"]=$unix->find_program("postfix");

@mkdir("/etc/artica-postfix/cron.1",0755,true);
@mkdir("/etc/artica-postfix/cron.2",0755,true);

$pipe = fopen("php://stdin", "r");
while(!feof($pipe)){
$buffer .= fgets($pipe, 4096);
Parseline($buffer);
$buffer=null;
}
fclose($pipe);
events("Shutdown...");
die();
function Parseline($buffer){
$buffer=trim($buffer);
if($buffer==null){return null;}

if(is_file("/var/log/artica-postfix/smtp-hack-reconfigure")){smtp_hack_reconfigure();}

if(preg_match("#assp\[.+?LDAP Results#",$buffer,$re)){return null;}
if(preg_match("#smtpd\[.+?\]: disconnect from#",$buffer,$re)){return null;}
if(preg_match("#smtpd\[.+?\]: connect from#",$buffer,$re)){return null;}
if(preg_match("#smtpd\[.+?\]: timeout after END-OF-MESSAGE#",$buffer,$re)){return null;}
if(preg_match("#smtpd\[.+?\]:.+?enabling PIX workarounds#",$buffer,$re)){return null;}
if(preg_match("#milter-greylist:.+?skipping greylist#",$buffer,$re)){return null;}
if(preg_match("#milter-greylist:\s+\(.+?greylisted entry timed out#",$buffer,$re)){return null;}
if(preg_match("#postfix\/qmgr\[.+?\]:\s+.+?: removed#",$buffer,$re)){return null;}
if(preg_match("#postfix\/smtpd\[.+?\]:\s+lost connection after#",$buffer,$re)){return null;}
if(preg_match("#assp.+?\[MessageOK\]#",$buffer,$re)){return null;}
if(preg_match("#assp.+?\[NoProcessing\]#",$buffer,$re)){return null;}
if(preg_match("#passed trough amavis and event is saved#",$buffer,$re)){return null;}
if(preg_match("#assp.+?AdminUpdate#",$buffer,$re)){return null;}
if(preg_match("#last message repeated.+?times#",$buffer,$re)){return null;}
if(preg_match("#cyrus\/master.+?about to exec#",$buffer,$re)){return null;}
if(preg_match("#cyrus\/.+?open: user#",$buffer,$re)){return null;}
if(preg_match("#cyrus\/lmtpunix.+?accepted connection#",$buffer,$re)){return null;}
if(preg_match("#cyrus\/lmtpunix.+?Delivered:#",$buffer,$re)){return null;}
if(preg_match("#cyrus\/master.+?process.+?exited#",$buffer,$re)){return null;}
if(preg_match("#lmtpunix.+?mystore: starting txn#",$buffer,$re)){return null;}
if(preg_match("#lmtpunix.+?duplicate_mark#",$buffer,$re)){return null;}
if(preg_match("#lmtpunix.+?mystore: committing txn#",$buffer,$re)){return null;}
if(preg_match("#ctl_cyrusdb.+?archiving#",$buffer,$re)){return null;}
if(preg_match("#assp.+?LDAP - found.+?in LDAPlist;#",$buffer,$re)){return null;}
if(preg_match("#anvil.+?statistics: max#",$buffer,$re)){return null;}
if(preg_match("#smfi_getsymval failed for#",$buffer)){return null;}
if(preg_match("#cyrus\/imap\[.+?Expunged\s+[0-9]+\s+message.+?from#",$buffer)){return null;}
if(preg_match("#cyrus\/imap\[.+?seen_db:\s+#",$buffer)){return null;}
if(preg_match("#cyrus\/[pop3|imap]\[.+?SSL_accept\(#",$buffer)){return null;}
if(preg_match("#cyrus\/[pop3|imap]\[.+?starttls:#",$buffer)){return null;}
if(preg_match("#cyrus\/[pop3|imap]\[.+?:\s+inflate#",$buffer)){return null;}
if(preg_match("#cyrus\/.+?\[.+?:\s+accepted connection$#",$buffer)){return null;}
if(preg_match("#cyrus\/.+?\[.+?:\s+deflate\(#",$buffer)){return null;}
if(preg_match("#cyrus\/.+?\[.+?:\s+\=>\s+compressed to#",$buffer)){return null;}
if(preg_match("#filter-module\[.+?:\s+KASINFO#",$buffer)){return null;}
if(preg_match("#exec\.mailbackup\.php#",$buffer)){return null;}
if(preg_match("#kavmilter\[.+?\]:\s+Loading#",$buffer)){return null;}
if(preg_match("#DBERROR: init.+?on berkeley#",$buffer)){return null;}
if(preg_match("#FATAL: lmtpd: unable to init duplicate delivery database#",$buffer)){return null;}
if(preg_match("#skiplist: checkpointed.+?annotations\.db#",$buffer)){return null;}
if(preg_match("#duplicate_prune#",$buffer)){return null;}
if(preg_match("#cyrus\/cyr_expire\[[0-9]+#",$buffer)){return null;}
if(preg_match("#cyrus\/imap.+?SSL_accept#",$buffer)){return null;}
if(preg_match("#cyrus\/pop3.+?SSL_accept#",$buffer)){return null;}
if(preg_match("#cyrus\/imap.+?:\s+executed#",$buffer)){return null;}
if(preg_match("#cyrus\/ctl_cyrusdb.+?recovering cyrus databases#",$buffer)){return null;}
if(preg_match("#cyrus.+?executed#",$buffer)){return null;}
if(preg_match("#postfix\/.+?refreshing the Postfix mail system#",$buffer)){return null;}
if(preg_match("#master.+?reload -- version#",$buffer)){return null;}
if(preg_match("#SQUAT failed#",$buffer)){return null;}
if(preg_match("#lmtpunix.+?sieve\s+runtime\s+error\s+for#",$buffer)){return null;}
if(preg_match("#imapd:Loading hard-coded DH parameters#",$buffer)){return null;}
if(preg_match("#ctl_cyrusdb.+?checkpointing cyrus databases#",$buffer)){return null;}
if(preg_match("#idle for too long, closing connection#",$buffer)){return null;}
if(preg_match("#amavis\[.+?Found#",$buffer)){return null;}
if(preg_match("#amavis\[.+?Module\s+#",$buffer)){return null;}
if(preg_match("#amavis\[.+?\s+loaded$#",trim($buffer))){return null;}
if(preg_match("#amavis\[.+?\s+Internal decoder#",trim($buffer))){return null;}
if(preg_match("#amavis\[.+?\s+Creating db#",trim($buffer))){return null;}
if(preg_match("#lost connection after CONNECT from unknown#",$buffer)){return null;}
if(preg_match("#lost connection after DATA from unknown#",$buffer)){return null;}
if(preg_match("#lost connection after RCPT#",$buffer)){return null;}
if(preg_match("#smtpd\[.+? warning:.+?address not listed for hostname#",$buffer)){return null;}

//SMTP HACK ######################################################################################################




if(preg_match("#smtpd\[.+?:\s+reject:\s+CONNECT from\s+(.+?)\[([0-9\.]+)\]:\s+554.+?Service unavailable;.+?blocked#",$buffer,$re)){	
	$GLOBALS["SMTP_HACK"][$re[1]]["RBL"]=$GLOBALS["SMTP_HACK"][$re[2]]["RBL"]+2;
	events("Postfix Hack: {$re[1]} RBL !! {$re[2]}={$GLOBALS["SMTP_HACK"][$re[2]]["RBL"]} attempts");
	if($GLOBALS["SMTP_HACK"][$re[2]]["RBL"]>=$GLOBALS["SMTP_HACK_CONFIG_RATE"]["RBL"]){
		smtp_hack_perform($re[2],$GLOBALS["SMTP_HACK"][$re[2]],"RBL");
		unset($GLOBALS["SMTP_HACK"][$re[2]]);	
	}	
	return null;
}


if(preg_match("#smtpd\[.+?warning:\s+(.+?):\s+hostname\s+(.+?)\s+verification failed: Name or service not known#",$buffer,$re)){
	$GLOBALS["SMTP_HACK"][$re[1]]["NAME_SERVICE_NOT_KNOWN"]=$GLOBALS["SMTP_HACK"][$re[1]]["NAME_SERVICE_NOT_KNOWN"]+1;
	events("Postfix Hack: {$re[1]} Name or service not known {$re[1]}={$GLOBALS["SMTP_HACK"][$re[1]]["NAME_SERVICE_NOT_KNOWN"]} attempts");
	if($GLOBALS["SMTP_HACK"][$re[1]]["NAME_SERVICE_NOT_KNOWN"]>=$GLOBALS["SMTP_HACK_CONFIG_RATE"]["NAME_SERVICE_NOT_KNOWN"]){
		smtp_hack_perform($re[1],$GLOBALS["SMTP_HACK"][$re[1]],"NAME_SERVICE_NOT_KNOWN");
		unset($GLOBALS["SMTP_HACK"][$re[1]]);
	}
	return;
}

if(preg_match('#warning.+?\[([0-9\.]+)\]:\s+SASL LOGIN authentication failed: authentication failure#',$buffer,$re)){
	$GLOBALS["SMTP_HACK"][$re[1]]["SASL_LOGIN"]=$GLOBALS["SMTP_HACK"][$re[1]]["SASL_LOGIN"]+1;
	events("Postfix Hack:bad SASL login {$re[1]}:{$GLOBALS["SMTP_HACK"][$re[1]]["SASL_LOGIN"]} retries");
	if($GLOBALS["SMTP_HACK"][$re[1]]["SASL_LOGIN"]>=$GLOBALS["SMTP_HACK_CONFIG_RATE"]["SASL_LOGIN"]){
		smtp_hack_perform($re[1],$GLOBALS["SMTP_HACK"][$re[1]],"SASL_LOGIN");
		unset($GLOBALS["SMTP_HACK"][$re[1]]);	
	}
	return null;
}

if(preg_match("#NOQUEUE: reject:.+?from.+?\[([0-9\.]+)\]:.+?Service unavailable.+?blocked using.+?from=<(.+?)> to=<(.+?)> proto#",$buffer,$re)){
	event_message_reject_hostname("RBL",$re[2],$re[3],$re[1]);
	$GLOBALS["SMTP_HACK"][$re[1]]["RBL"]=$GLOBALS["SMTP_HACK"][$re[1]]["RBL"]+1;
	
	events("Postfix Hack: {$re[1]} RBL !! from=<{$re[2]}> to=<{$re[3]}> {$re[1]}={$GLOBALS["SMTP_HACK"][$re[1]]["RBL"]} attempts");
	
	if($GLOBALS["SMTP_HACK"][$re[1]]["RBL"]>=$GLOBALS["SMTP_HACK_CONFIG_RATE"]["RBL"]){
		smtp_hack_perform($re[1],$GLOBALS["SMTP_HACK"][$re[1]],"RBL");
		unset($GLOBALS["SMTP_HACK"][$re[1]]);	
	}	
	return null;
}

if(preg_match("#NOQUEUE: reject:.+?from.+?\[([0-9\.]+)\]:.+?<(.+?)>:\s+Recipient address rejected: User unknown in local recipient table;\s+from=<(.+?)>\s+to=<(.+?)>#",$buffer,$re)){
	event_message_reject_hostname("User unknown",$re[2],$re[3],$re[1]);
		$GLOBALS["SMTP_HACK"][$re[1]]["USER_UNKNOWN"]=$GLOBALS["SMTP_HACK"][$re[1]]["USER_UNKNOWN"]+1;
	events("Postfix Hack: : {$re[1]} User unknown from=<{$re[2]}> to=<{$re[3]}> {$GLOBALS["SMTP_HACK"][$re[1]]["USER_UNKNOWN"]} attempts/{$GLOBALS["SMTP_HACK_CONFIG_RATE"]["USER_UNKNOWN"]}");
	if($GLOBALS["SMTP_HACK"][$re[1]]["USER_UNKNOWN"]>=$GLOBALS["SMTP_HACK_CONFIG_RATE"]["USER_UNKNOWN"]){
		smtp_hack_perform($re[1],$GLOBALS["SMTP_HACK"][$re[1]],"USER_UNKNOWN");
		unset($GLOBALS["SMTP_HACK"][$re[1]]);	
	}	
	return null;
}


if(preg_match("#ch[0-9]+.+\[.+?]:.+?Blocked SPAM,\s+.+?\[.+?\]\s+\[(.+?)]#",$buffer,$re)){
	$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]=$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]+1;
	events("Postfix Hack: {$re[1]} Spam {$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]} attempts/{$GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]}");
	if($GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]>=$GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]){
		smtp_hack_perform($re[1],$GLOBALS["SMTP_HACK"][$re[1]],"BLOCKED_SPAM");
		unset($GLOBALS["SMTP_HACK"][$re[1]]);	
	}	
	return null;
}

if(preg_match("#Blocked SPAM, AM\.PDP-SOCK\s+\[.+?\]\s+\[(.+?)\]#",$buffer,$re)){
	$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]=$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]+1;
	events("Postfix Hack: {$re[1]} Spam {$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]} attempts/{$GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]}");
	if($GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]>=$GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]){
		smtp_hack_perform($re[1],$GLOBALS["SMTP_HACK"][$re[1]],"BLOCKED_SPAM");
		unset($GLOBALS["SMTP_HACK"][$re[1]]);	
	}	
	return null;
}


if(preg_match("#ch[0-9]+.+\[.+?]:.+?Blocked SPAMMY,\s+.+?\[.+?\]\s+\[(.+?)]#",$buffer,$re)){
	$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]=$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]+1;
	events("Postfix Hack: {$re[1]} Spam {$GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]} attempts/{$GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]}");
	if($GLOBALS["SMTP_HACK"][$re[1]]["BLOCKED_SPAM"]>=$GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]){
		smtp_hack_perform($re[1],$GLOBALS["SMTP_HACK"][$re[1]],"BLOCKED_SPAM");
		unset($GLOBALS["SMTP_HACK"][$re[1]]);	
	}	
	return null;
}





//######################################################################################################


if(preg_match("#cyrus\/lmtp\[.+?:\s+IOERROR: not a sieve bytecode file\s+(.+?)$#",$buffer,$re)){
	THREAD_COMMAND_SET("{$GLOBALS["SIEVEC_PATH"]} {$re[1]} {$re[1]}");
	return;	
}


if(preg_match("#postfix\/lmtp\[.+?:\s+(.+?):\s+to=<(.+)>,\s+relay=([0-9\.]+)\[.+?:[0-9]+,.+?status=deferred.+?430 Authentication required#",$buffer,$re)){
	events("postfix LMTP error to {$re[2]}");
	$file="/etc/artica-postfix/croned.1/postfix.lmtp.auth.failed";
	event_messageid_rejected($re[1],"Mailbox Authentication required",$re[3],$re[2]);
	if(file_time_min($file)>5){
		email_events("Postfix: LMTP Error","Postfix\n$buffer\nArtica will reconfigure LMTP settings","postfix");
		THREAD_COMMAND_SET("{$GLOBALS["PHP5_BIN"]} {$GLOBALS["MYPATH"]}/exec.postfix.maincf.php --mailbox-transport");
		@unlink($file);
		file_put_contents($file,"#");
	}
	
	return;	
	
}



if(preg_match("#postfix\/lmtp\[.+?:\s+connect to ([0-9\.]+)\[.+?:[0-9]+:\s+Connection refused#",$buffer)){
	events("postfix LMTP error");
	$file="/etc/artica-postfix/croned.1/postfix.lmtp.auth.failed";
	event_messageid_rejected($re[1],"Mailbox Authentication required","127.0.0.1",$re[2]);
	if(file_time_min($file)>5){
		email_events("Postfix: LMTP Error","Postfix\n$buffer\nArtica will reconfigure LMTP settings","postfix");
		THREAD_COMMAND_SET("{$GLOBALS["PHP5_BIN"]} {$GLOBALS["MYPATH"]}/exec.postfix.maincf.php --mailbox-transport");
		@unlink($file);
		file_put_contents($file,"#");
	}
	
	return;		
}
if(preg_match("#postfix\/.+?:\s+warning:\s+problem talking to server\s+[0-9\.]+:12525:\s+Connection refused#",$buffer)){
	events("postfix policyd-weight error");
	$file="/etc/artica-postfix/croned.1/postfix.policyd-weight.conect.failed";
	
	if(file_time_min($file)>10){
		email_events("Postfix: Policyd-weight server connection problem","Postfix\n$buffer\nArtica will reconfigure restart policyd-weight service","postfix");
		THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart policydw");
		@unlink($file);
		file_put_contents($file,"#");
	}
	
	return;		
}

if(preg_match("#KASERROR.+?keepup2date\s+failed.+?no valid license info found#",$buffer,$re)){
	events("Kas3, license error, uninstall kas3");
	$file="/etc/artica-postfix/croned.1/kas3.license.error";
	if(file_time_min($file)>5){
		email_events("Kaspersky Antispam: license error","Kaspersky Updater claim\n$buffer\nArtica will uninstall Kaspersky Anti-spam","postfix");
		THREAD_COMMAND_SET("/usr/share/artica-postfix/bin/artica-install --kas3-remove");
		@unlink($file);
		file_put_contents($file,"#");
	}
	
	return;
}


if(preg_match("#postfix\/postfix-script\[.+?\]: fatal: the Postfix mail system is not running#",$buffer,$re)){
	THREAD_COMMAND_SET("{$GLOBALS["postfix_bin_path"]} start");
	return;
}


if(preg_match("#zarafa-server\[.+?: SQL Failed: Table.+?zarafa\.(.+?)'\s+doesn.+?exist#",$buffer,$re)){
	events("Zarafa, missing table {$re[1]}");
	zarafa_rebuild_db($table,$buffer);
}

if(preg_match("#zarafa-server\[.+?INNODB engine is not support.+?Please enable the INNODB engine#",$buffer,$re)){
	events("Zarafa, INNODB not enabled, restart mysql {$re[1]}");
	$file="/etc/artica-postfix/croned.1/zarafa.INNODB.error";
	if(file_time_min($file)>5){
		email_events("Zarafa server: innodb is not enabled","Zarafa-server claim\n$buffer\nArtica will restart mysql","mailbox");
		THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart mysql");
		@unlink($file);
		file_put_contents($file,"#");
	}
	
	return;
}




if(preg_match("#zarafa-server\[.+?:\s+Cannot instantiate user plugin: ldap_bind_s: Invalid credentials#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/zarafa.ldap_bind_s.error";
	events("zarafa-server -> ldap_bind_s: Invalid credentials");
	if(file_time_min($file)>5){
		email_events("Zarafa server cannot connect to ldap server","Zarafa-server claim\n$buffer\nArtica will restart and reconfigure zarafa","mailbox");
		THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart zarafa");
		@unlink($file);
		file_put_contents($file,"#");
	}
	
	return;
}

if(preg_match("#smtp\[.+? fatal: specify a password table via the.+?smtp_sasl_password_maps.+?configuration parameter#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/postfix.smtp_sasl_password_maps.error";
	events("postfix -> smtp_sasl_password_maps");
	if(file_time_min($file)>5){
		email_events("Postfix configuration problem","Postfix claim\n$buffer\nArtica will disable SMTP Sasl feature","postfix");
		THREAD_COMMAND_SET("{$GLOBALS["PHP5_BIN"]} /usr/share/artica-postfix/exec.postfix.maincf.php --disable-smtp-sasl");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return;	
}

if(preg_match("#amavis\[.+?TROUBLE.+?in child_init_hook: BDB can't connect db env.+?No such file or directory#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/amavis.BDB.error";
	events("amavis BDB ERROR");
	if(file_time_min($file)>5){
		email_events("AMAVIS BDB Error","amavis claim\n$buffer\nArtica will restart amavis service","postfix");
		THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart amavis");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return;	
}


if(preg_match("#Decoding of p[0-9]+\s+\(.+?data, at least.+?failed, leaving it unpacked: Compress::Raw::Zlib version\s+(.+?)\s+required.+?this is only version\s+(.+?)\s+#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/amavis.Compress.Raw.Zlib.error";
	events("amavis Compress::Raw::Zlib need to be upgraded");
	if(file_time_min($file)>20){
		email_events("AMAVIS Compress::Raw::Zlib need to be upgraded from {$re[1]} to {$re[2]}","amavis claim\n$buffer\nArtica will install a newest Compress::Raw::Zlib version","postfix");
		THREAD_COMMAND_SET("/usr/share/artica-postfix/bin/artica-make APP_COMPRESS_ROW_ZLIB");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return;	
}

if(preg_match("#smtp\[.+?:\s+fatal: valid hostname or network address required in server description:(.+?)#",$buffer,$re)){
	mail_events("{$re[1]} Bad configuration parameters","Postfix claim\n$buffer\nPlease come back to the interface and check your configuration!","postfix");
	return;
}


if(preg_match("#.+?postfix-.+?\/master\[.+?:\s+fatal:\s+bind\s+[0-9\.]+\s+port\s+25:\s+Address already in use#",$buffer,$re)){
	events("Address already in use, restart postfix");
	THREAD_COMMAND_SET("{$GLOBALS["postfix_bin_path"]} stop");
	THREAD_COMMAND_SET("{$GLOBALS["postfix_bin_path"]} postfix start");
	return null;	
}

if(preg_match("#postfix\/.+?warning:\s+(.+?)\s+and\s+(.+?)\s+differ#",$buffer,$re)){
	THREAD_COMMAND_SET("/bin/cp -pf {$re[2]} {$re[1]}");
	return ;
}

if(preg_match("#smtpd\[.+?warning:\s+connect to Milter service unix:(.+?):\s+Permission denied#",$buffer,$re)){
	events("chown postfix:postfix {$re[1]}");
	shell_exec("/bin/chown postfix:postfix {$re[1]} &");
	return;
}


if(preg_match("#amavis.+?:.+?_DIE:\s+Can.+?locate.+?.+?body_[0-9]+\.pm\s+in\s+@INC#",$buffer,$re)){
	SpamAssassin_error_saupdate($buffer);
	return null;	
}




if(preg_match("#spamd\[[0-9]+.+?Can.+?locate\s+Mail\/SpamAssassin\/CompiledRegexps\/body_[0-9]+\.pm#",$buffer,$re)){
	SpamAssassin_error_saupdate($buffer);
	return null;
}

if(preg_match("#cyrus\/lmtp\[.+?verify_user\(user\.(.+?)\)\s+failed: Mailbox does not exist#",$buffer,$re)){
	cyrus_mailbox_not_exists($buffer,$re[1]);
	return null;
}

if(preg_match("#cyrus\/imap\[.+?: IOERROR: opening\s+(.+?):\s+No such file or directory#",$buffer,$re)){
	@mkdir(dirname($re[1]),0755,true);
	shell_exec("/bin/touch {$re[1]}");
	events("postfix -> mkdir ".dirname($re[1]));
	THREAD_COMMAND_SET("chown -R cyrus:mail ".dirname($re[1]));
	return;
	
}


if(preg_match("#zarafa-monitor.+?:\s+Unable to get store entry id for company\s+(.+?), error code#",$buffer,$re)){
	zarafa_store_error($buffer);
	return null;
}

if(preg_match("#postfix\/lmtp.+?:\s+(.+?):\s+to=<(.+?)>.+?lmtp.+?deferred.+?451.+?Mailbox has an invalid format#",$buffer,$re)){
	event_messageid_rejected($re[1],"Mailbox corrupted",null,$re[2]);
	mailbox_corrupted($buffer,$re[2]);
	return null;
	}
	

	
if(preg_match("#postfix\/lmtp.+?(.+?):\s+to=<(.+?)>.+?lmtp.+?status=deferred.+?452.+?Over quota#",$buffer,$re)){
	event_messageid_rejected($re[1],"Over quota",null,$re[2]);
	mailbox_overquota($buffer,$re[2]);
	return null;
	}	



if(preg_match("#smtp.+?status=deferred.+?connect.+?\[127\.0\.0\.1\]:10024: Connection refused#",$buffer,$re)){
	AmavisConfigErrorInPostfix($buffer);
	return null;
}

if(preg_match("#postfix\/.+?:(.+?):\s+milter-reject: END-OF-MESSAGE\s+.+?Error in processing.+?ALL VIRUS SCANNERS FAILED;.+?from=<(.+?)>\s+to=<(.+?)>#",$buffer,$re)){
	event_message_milter_reject($re[1],"antivirus failed",$re[1],$re[2],$buffer);
	clamav_error_restart($buffer);
	return null;	
	}

if(preg_match("#postfix\/.+?:(.+?):\s+to=<(.+?)>,.+?\[(.+?)\].+?status=deferred.+?virus_scan FAILED#",$buffer,$re)){
	event_messageid_rejected($re[1],"antivirus failed",$re[3],$re[2]);
	return null;
	}
	
if(preg_match("#smtp\[[0-9]+\]:\s+(.+?):\s+to=<(.+?)>,\s+relay=127\.0\.0.+:[0-9]+,.+?deferred.+?451.+?during fwd-connect\s+\(Negative greeting#",$buffer,$re)){
	event_messageid_rejected($re[1],"Internal timed-out","127.0.0.1",$re[2]);
	$file="/etc/artica-postfix/croned.1/timedout-amavis";
	events("fwd-connect ERROR");
	if(file_time_min($file)>5){
		THREAD_COMMAND_SET("{$GLOBALS["postfix_bin_path"]} stop");
		THREAD_COMMAND_SET("{$GLOBALS["postfix_bin_path"]} start");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return;		
}
	
	
if(preg_match("#master\[.+?:\s+fatal:\s+binds\+(.+?)\s+port\s+(.+?).+?Address already in use#",$buffer,$re)){
	postfix_bind_error($re[1],$re[2],$buffer);
	return null;
}


if(preg_match("#kavmilter\[.+?:\s+KAVMilter Error\(13\):\s+Active key expired.+?Exiting#",$buffer,$re)){
	kavmilter_expired($buffer);
	return null;
}

if(preg_match("#.+?\/(.+?)\[.+?:\s+fatal:\s+open\s+(.+?):\s+No such file or directory#",$buffer,$re)){
	postfix_nosuch_fileor_directory($re[1],$re[2],$buffer);
	return null;
}
if(preg_match("#.+?\/(.+?)\[.+?:\s+fatal:\s+open\s+(.+?)\.db:\s+Bad file descriptor#",$buffer,$re)){
	postfix_baddb($re[1],$re[2],$buffer);
	return null;
}

if(preg_match("#postfix\/qmgr.+?:\s+(.+?):\s+from=<(.*?)>,\s+status=expired, returned to sender#",$buffer,$re)){
	event_finish($re[1],null,"expired","expired",$re[2],$buffer);
	return null;
}


if(preg_match("#postfix postmulti\[[0-9+]\]: fatal: No matching instances#",$buffer,$re)){
	multi_instances_reconfigure($buffer);
	return null;
}


if(preg_match("#cyrus\/.+?\[.+?IOERROR: fstating sieve script\s+(.+?):\s+No such file or directory#",$buffer,$re)){
	@mkdir(dirname($re[1]),null,true);
	@file_put_contents($re[1]," ");
	return null;
}
if(preg_match("#cyrus\/.+?\[.+?IOERROR: fstating sieve script\s+(.+?):\s+Permission denied#",$buffer,$re)){
	shell_exec("/bin/chown cyrus:mail {$re[1]}");
	return null;
}
if(preg_match("#cyrus\/.+?\[.+?IOERROR: fstating sieve script\s+(.+?):\s+Permission denied#",$buffer,$re)){
	shell_exec("/bin/chown cyrus:mail {$re[1]}");
	return null;
}

if(preg_match("#cyrus\/imap\[.+?:\s+Deleted mailbox user\.(.+)#",$buffer,$re)){
	email_events("{$re[1]} Mailbox has been deleted",$buffer,"mailbox"); 
	return;
}
if(preg_match("#cyrus.+?reconstruct\[.+?:\s+Updating last_appenddate for user\.(.+?):#",$buffer,$re)){
	email_events("{$re[1]} Mailbox has been reconstructed",$buffer,"mailbox"); 
	return;
}

if(preg_match("#cyrus\/lmtpunix.+?IOERROR:\s+opening.+?\/user\/(.+?)\/cyrus.header:\s+No such file or directory#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/postfix.{$re[1]}.mbx.error";
	events("lmtpunix -> mailbox IOERROR error");
	if(file_time_min($file)>5){
		email_events("{$re[1]} Mailbox is deleted but postfix wants to tranfert mails !","Postfix claim\n$buffer\nArtica will re-create the mailbox","mailbox");
		events("{$GLOBALS["PHP5_BIN"]} /usr/share/artica-postfix/exec.cyrus-restore.php --create-mbx {$re[1]}"); 
		THREAD_COMMAND_SET("{$GLOBALS["PHP5_BIN"]} /usr/share/artica-postfix/exec.cyrus-restore.php --create-mbx {$re[1]}");
		@unlink($file);
		file_put_contents($file,"#");
	}
	events("lmtpunix -> mailbox IOERROR error (timeout)");
	return;
}

if(preg_match('#NOQUEUE: reject: MAIL from.+?452 4.3.1 Insufficient system storage#',$buffer)){
	$file="/etc/artica-postfix/croned.1/postfix.storage.error";
	if(file_time_min($file)>10){
		email_events("Postfix Insufficient storage disk space!!! ","Postfix claim: $buffer\n Please check your hard disk space !" ,"system");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;
}


if(preg_match("#starting amavisd-milter.+?on socket#",$buffer)){
	email_events("Amavisd New has been successfully started",$buffer,"system"); 
	return;
}


if(preg_match("#kavmilter\[.+?\]:\s+Could not open pid file#",$buffer)){
	$file="/etc/artica-postfix/croned.1/postfix.kavmilter.pid.error";
		if(file_time_min($file)>10){
			events("Kaspersky Milter PID error");
			email_events("Kaspersky Milter PID error","kvmilter claim $buffer\nArtica will try to restart it","postfix");
			THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart kavmilter');
			@unlink($file);
		}else{
			events("Kaspersky Milter PID error, but take action after 10mn");
		}	
	file_put_contents($file,"#");	
	return null;
	
}	


// HACK POP3
if(preg_match("#cyrus\/pop3\[.+?badlogin.+?.+?\[(.+?)\]\s+APOP.+?<(.+?)>.+?SASL.+?: user not found: could not find password#",$buffer,$re)){
	hackPOP($re[1],$re[2],$buffer);
	return;
	}
if(preg_match("#cyrus\/pop3\[.+?:\s+badlogin:\s+.+?\[(.+?)\]\s+plaintext\s+(.+?)\s+SASL.+?authentication failure:#",$buffer,$re)){
	hackPOP($re[1],$re[2],$buffer);
	return;
}

if(preg_match("#zarafa-gateway\[.+?: Failed to login from\s+(.+?)\s+with invalid username\s+\"(.+?)\"\s+or wrong password#",$buffer,$re)){
	hackPOP($re[1],$re[2],$buffer);
	return;
}
if(preg_match("#cyrus.+?unable to get certificate from.+?(.+?)cyrus\.pem#",$buffer,$re)){
	cyrus_vertificate_error();
	return;
}




if(preg_match("#smtpd.+?:\s+warning: SASL authentication failure: no secret in database#",$buffer)){
	$file="/etc/artica-postfix/croned.1/postfix.sasl.secret.error";
		if(file_time_min($file)>10){
			events("SASL authentication failure");
			email_events("Postfix error SASL","Postfix claim $buffer\nArtica will try to repair it","postfix");
			THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --postfix-sasldb2');
			@unlink($file);
		}else{
			events("SASL authentication failure, but take action after 10mn");
		}	
	return null;
	
}

if(preg_match("#smtp.+?connect to 127\.0\.0\.1\[127\.0\.0\.1\]:10024: Connection refused#",$buffer,$re)){
	AmavisConfigErrorInPostfix($buffer);
	return null;
}


if(preg_match("#postfix\/smtp\[.+?:\s+(.+?):\s+to=<(.+?)>.+?status=deferred\s+\(SASL authentication failed.+?\[(.+?)\]#",$buffer,$re)){
	event_messageid_rejected($re[1],"authentication failed",$re[3],$re[2]);
	smtp_sasl_failed($re[3],$re[3],$buffer);
}


if(preg_match("#postfix\/smtp\[.+?:\s+(.+?):\s+to=<(.+?)>.+?status=bounced.+?.+?\[(.+?)\]\s+said:\s+554.+?http:\/\/#",$buffer,$re)){
	ImBlackListed($re[3],$buffer);
	event_messageid_rejected($re[1],"Your are blacklisted",$re[3],$re[2]);
	return null;
}

if(preg_match("#postfix\/(cleanup|bounce|smtp|smtpd|flush|trivial-rewrite)\[.+?warning: database\s+(.+?)\.db\s+is older than source file\s+(.+)#",$buffer,$re)){
	postfix_compile_db($re[3],$buffer);
	return null;
}
if(preg_match("#postfix\/(cleanup|bounce|smtp|smtpd|flush|trivial-rewrite)\[.+?fatal: open database\s+(.+?)\.db:\s+No such file or directory#",$buffer,$re)){
	postfix_compile_missing_db($re[2],$buffer);
	return null;
}

if(preg_match("#postfix\/smtp\[.+?:\s+(.+?):\s+host.+?\[(.+?)\]\s+said:\s+[0-9]+\s+invalid sender domain#",$buffer,$re)){
	event_messageid_rejected($re[1],"invalid sender domain",$re[2],null);
	return null;
}

if(preg_match("#warning: connect to Milter service unix:(.+?)clamav-milter.ctl: Connection refused#",$buffer,$re)){
	MilterClamavError($buffer,"$re[1]/clamav-milter.ctl");
	return null;
}

if(preg_match("#warning: connect to Milter service unix:(.+?)spamass.sock: No such file or directory#",$buffer,$re)){
	MilterSpamAssassinError($buffer,"$re[1]/spamass.sock");
	return null;
}

if(preg_match("#warning: connect to Milter service unix:(.+?)greylist.sock: No such file or directory#",$buffer,$re)){
	miltergreylist_error($buffer,"{$re[1]}/greylist.sock");
	return null;
}

if(preg_match("#postfix\/smtpd\[.+?warning: connect to Milter service unix:(.+?)milter-greylist.sock: No such file or directory#",$buffer,$re)){
	miltergreylist_error($buffer,"{$re[1]}/milter-greylist.sock");
	return null;
}

if(preg_match("#warning: connect to Milter service unix:/var/spool/postfix/var/run/amavisd-milter/amavisd-milter.sock: Connection refused#",$buffer)){
		AmavisConfigErrorInPostfix($buffer);
		return null;
}

if(preg_match("#qmgr.+?transport amavis: Connection refused#",$buffer)){
	AmavisConfigErrorInPostfixRestart($buffer);
	return null;
}



if(preg_match('#milter-greylist: greylist: Unable to bind to port (.+?): Permission denied#',$buffer,$re)){
	miltergreylist_error($buffer,$re[1]);
}

if(preg_match("#cyrus\/master.+? unable to create lmtpunix listener socket(.+?)#",$buffer,$re)){
	cyrus_socket_error($buffer,"$re[1]");
	return null;
}

if(preg_match("#cyrus\/lmtpunix\[.+?:\s+verify_user\(.+?\)\s+failed:\s+System I\/O error#",$buffer,$re)){
	cyrus_generic_reconfigure($buffer,"Cyrus I/O error");
	return null;
}

if(preg_match('#]:\s+(.+?): to=<(.+?)>.+?socket/lmtp\].+?status=deferred.+?lost connection with.+?end of data#',$buffer,$re)){
	event_finish($re[1],$re[2],"deferred","mailbox service error",null,$buffer);
	return null;
}
if(preg_match('#imap.+?IOERROR.+?opening\s+(.+?):.+?Permission denied#',$buffer,$re)){
	if(is_dir($re[1])){
		events("chown ".dirname($re[1]));
		THREAD_COMMAND_SET('/bin/chown -R cyrus:mail '.dirname($re[1]));
	}
	return null;
}
if(preg_match('#IOERROR: fstating sieve script (.+?): No such file or directory#',$buffer,$re)){
		events("/bin/touch {$re[1]}");
		THREAD_COMMAND_SET("/bin/touch {$re[1]}");
		return null;
}
if(preg_match('#ctl_cyrusdb.+?IOERROR.+?: Permission denied#',$buffer,$re)){
		$file="/etc/artica-postfix/croned.1/cyrus.IOERROR.permissions.error";
		if(file_time_min($file)>10){
			events("IOERROR detected, check perms");
			email_events("Cyrus error permissions on databases","Cyrus imap claim $buffer\nArtica will try to repair it","mailbox");
			THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --cyrus-checkperms');
			@unlink($file);
		}else{
			events("IOERROR detected, but take action after 10mn");
		}	
	@file_put_contents($file,"#");	
	return null;
}

if(preg_match('#cyrus\/lmtpunix\[.+? IOERROR: can not open sieve script\s+(.+?):\s+Permission denied#',$buffer,$re)){
		$file="/etc/artica-postfix/croned.1/cyrus.IOERROR.permissions.". md5($re[1]).".error";
		if(file_time_min($file)>10){
			events("IOERROR detected {$re[1]}, check perms");
			THREAD_COMMAND_SET("/bin/chown cyrus:mail {$re[1]}");
			@unlink($file);
		}else{
			events("IOERROR detected, {$re[1]} but take action after 10mn");
		}	
	@file_put_contents($file,"#");	
	return null;
}







if(preg_match('#badlogin: \[(.+?)\] plaintext\s+(.+?)\s+SASL\(-13\): authentication failure: checkpass failed#',$buffer,$re)){
	$date=date('Y-m-d H');
	$_GET["IMAP_HACK"][$re[1]][$date]=$_GET["IMAP_HACK"][$re[1]][$date]+1;
	events("cyrus Hack:bad login {$re[1]}:{$_GET["IMAP_HACK"][$re[1]][$date]} retries");
	if($_GET["IMAP_HACK"][$re[1]][$date]>15){
		email_events("Cyrus HACKING !!!!","Build iptables rule \"iptables -I INPUT -s {$re[1]} -j DROP\" for {$re[1]}!\nlaster error: $buffer","mailbox");
		shell_exec("iptables -I INPUT -s {$re[1]} -j DROP");
		events("IMAP Hack: -> iptables -I INPUT -s {$re[1]} -j DROP");
		unset($_GET["IMAP_HACK"][$re[1]]);
	}
	
	return null;
}



if(preg_match('#badlogin: \[(.+?)\] plaintext\s+(.+?)\s+SASL\(-1\): generic failure: checkpass failed#',$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/cyrus.checkpass.error";
	if(file_time_min($file)>10){
		email_events("Cyrus auth error","Artica will restart messaging service\n\"$buffer\"","mailbox");
		THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart imap');
		@unlink($file);
	}
	return null;
}
if(preg_match('#cyrus\/lmtpunix.+?DBERROR:\s+opening.+?\.db:\s+Cannot allocate memory#',$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/cyrus.dberror.restart.error";
	if(file_time_min($file)>10){
		email_events("Cyrus DBERROR error","Artica will restart messaging service\n\"$buffer\"","mailbox");
		THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart imap');
		@unlink($file);
	}
	return null;
}
if(preg_match('#cyrus\/imap.+?DBERROR.+?Open database handle:\s+(.+?)tls_sessions\.db#',$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/cyrus.dberror.tls_sessions.error";
	if(file_time_min($file)>10){
		email_events("Cyrus DBERROR error","Artica will delete {$re[1]}tls_sessions.db file\n\"$buffer\"","mailbox");
		@unlink("{$re[1]}tls_sessions.db");
		@unlink($file);
	}
	return null;
}







if(preg_match('#cyrus\/notify.+?DBERROR db[0-9]: PANIC: fatal region error detected; run recovery#',$buffer)){
	$file="/etc/artica-postfix/croned.1/cyrus.db.error";
	if(file_time_min($file)>10){
		$buffer="Artica has detected a fatal error on cyrus\n$buffer\nArtica will try to repair it but it should not working\n";
		$buffer=$buffer."Perhaps you need to contact your support to correctly recover cyrus databases\n";
		$buffer=$buffer."Notice,read this topic : http://www.gradstein.info/software/how-to-recover-from-cyrus-when-you-have-some-db-errors/\n";
		THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --cyrus-recoverdb');
		email_events("Cyrus database error !!",$buffer,"mailbox");
		events("DBERROR detected, take action");
		@unlink($file);
		file_put_contents($file,"#");
	}else{
		events("DBERROR detected, but take action after 10mn");
	}
	return null;	
}


if(preg_match("#cyrus.+?DBERROR\s+db[0-9]+:\s+DB_AUTO_COMMIT may not be specified in non-transactional environment#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/cyrus.db.error";
	if(file_time_min($file)>10){
		$buffer="Artica has detected a fatal error on cyrus\n$buffer\nArtica will try to repair it but it should not working\n";
		$buffer=$buffer."Perhaps you need to contact your support to correctly recover cyrus databases\n";
		$buffer=$buffer."Notice,read this topic : http://www.gradstein.info/software/how-to-recover-from-cyrus-when-you-have-some-db-errors/\n";
		THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --cyrus-ctl-cyrusdb');
		email_events("Cyrus database error !!",$buffer,"mailbox");
		events("DBERROR detected, take action");
		@unlink($file);
		file_put_contents($file,"#");
	}else{
		events("DBERROR detected, but take action after 10mn");
	}
	return null;
}


if(preg_match('#cyrus\/imap.+?DBERROR db[0-9]: PANIC: fatal region error detected; run recovery#',$buffer)){
	$file="/etc/artica-postfix/croned.1/cyrus.db.error";
	$ftime=file_time_min($file);
	if($ftime>10){
		$buffer="Artica has detected a fatal error on cyrus\n$buffer\nArtica will try to repair it but it should not working\n";
		$buffer=$buffer."Perhaps you need to contact your support to correctly recover cyrus databases\n";
		$buffer=$buffer."Notice,read this topic : http://www.gradstein.info/software/how-to-recover-from-cyrus-when-you-have-some-db-errors/\n";
		THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --cyrus-recoverdb');
		email_events("Cyrus database error !!",$buffer,"mailbox");
		events("DBERROR detected, take action ftime=$ftime");
		@unlink($file);
		
		file_put_contents($file,"#");
	}else{
		events("DBERROR detected, but take action after 10mn");
	}
	return null;	
}



if(preg_match("#cyrus.+?:\s+DBERROR:\s+opening.+?mailboxes.db:\s+cyrusdb error#",$buffer)){
	$file="/etc/artica-postfix/croned.1/cyrus.db.error";
	if(file_time_min($file)>10){
		$buffer="Artica has detected a fatal error on cyrus\n$buffer\nArtica will try to repair it but it should not working\n";
		$buffer=$buffer."Perhaps you need to contact your support to correctly recover cyrus databases\n";
		$buffer=$buffer."Notice,read this topic : http://www.gradstein.info/software/how-to-recover-from-cyrus-when-you-have-some-db-errors/\n";
		THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --cyrus-recoverdb');
		email_events("Cyrus database error !!",$buffer,"mailbox");
		@unlink($file);
		file_put_contents($file,"#");
	}else{
		events("DBERROR detected, but take action after 10mn");
	}
	return null;	
}


if(preg_match('#cyrus\/(.+?)\[.+?login:(.+?)\[(.+?)\]\s+(.+?)\s+.+?User#',$buffer,$re)){
	$service=trim($re[1]);
	$server=trim($re[2]);
	$server_ip=trim($re[3]);
	$user=trim($re[4]);
	cyrus_imap_conx($service,$server,$server_ip,$user);
	return null;
}

if(preg_match("#zarafa-gateway\[.+?:\s+IMAP Login from\s+(.+)\s+for user\s+(.+?)\s+#",$buffer,$re)){
	$service="IMAP";
	$server=trim($re[1]);
	$server_ip=trim($re[1]);
	$user=trim($re[2]);
	cyrus_imap_conx($service,$server,$server_ip,$user);
	return null;
}




if(preg_match('#cyrus\/ctl_mboxlist.+?DBERROR: reading.+?, assuming the worst#',$buffer)){
	$file="/etc/artica-postfix/croned.1/cyrus.db1.error";
	if(file_time_min($file)>10){
		$buffer="Artica has detected a fatal error on cyrus\n$buffer\n\n";
		email_events("Cyrus database error !!",$buffer,"mailbox");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;	
}
if(preg_match('#cyrus\/sync_client.+?Can not connect to server#',$buffer)){
	$file="/etc/artica-postfix/croned.1/cyrus.cluster.error";
	if(file_time_min($file)>10){
		$buffer="Artica has detected that the cyrus cluster replica is not available on cyrus\n$buffer\n\n";
		email_events("Cyrus replica not available",$buffer,"mailbox");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;	
}

if(preg_match('#cyrus\/sync_client.+?connect.+?failed: No route to host#',$buffer)){
	$file="/etc/artica-postfix/croned.1/cyrus.cluster.error";
	if(file_time_min($file)>10){
		$buffer="Artica has detected that the cyrus cluster replica is not available on cyrus\n$buffer\n\n";
		email_events("Cyrus replica not available",$buffer,"mailbox");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;	
}

if(preg_match('#warning: dict_ldap_connect: Unable to bind to server ldap#',$buffer)){
	$file="/etc/artica-postfix/croned.1/ldap.error";
	if(file_time_min($file)>10){
		email_events("Postfix is unable to connect to ldap server ",$buffer,"system");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;
}





if(preg_match('#service pop3 pid.+?in BUSY state and serving connection#',$buffer)){
	$file="/etc/artica-postfix/croned.1/pop3-busy.error";
	if(file_time_min($file)>10){
		email_events("Pop3 service is overloaded","pop3 report:\n$buffer\nPlease,increase pop3 childs connections in artica Interface","mailbox");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;
}

if(preg_match('#milter inet:[0-9\.]+:1052.+?Connection timed out#',$buffer)){
	$file="/etc/artica-postfix/croned.1/KAV-TIMEOUT.error";
	if(file_time_min($file)>10){
		email_events("Postfix service Cannot connect to Kaspersky Antivirus milter",
		"it report:\n$buffer\nPlease,disable Kaspersky service or contact your support",
		"postfix");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;
}

if(preg_match('#milter unix:/var/run/milter-greylist/milter-greylist.sock.+?Connection timed out#',$buffer)){
	$file="/etc/artica-postfix/croned.1/miltergreylist-TIMEOUT.error";
	if(file_time_min($file)>10){
		email_events("milter-greylist error",
		"it report:\n$buffer\nPlease,investigate what plugin cannot send to milter-greylist events",
		"postfix");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;
}


if(preg_match('#SASL authentication failure: cannot connect to saslauthd server#',$buffer)){
	$file="/etc/artica-postfix/croned.1/saslauthd.error";
	if(file_time_min($file)>10){
		email_events("saslauthd failed to run","it report:\n$buffer\nThis error is fatal, nobody can be logged on the system.","mailbox");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;
}


if(preg_match("#smtp.+?warning:\s+(.+?)\[(.+?)\]:\s+SASL DIGEST-MD5 authentication failed#",$buffer,$re)){
	$router_name=$re[1];
	$ip=$re[2];
	smtp_sasl_failed($router,$ip,$buffer);
	return null;
}



if(preg_match('#warning: connect to Milter service unix:/var/run/kas-milter.socket: Permission denied#',$buffer)){
	$file="/etc/artica-postfix/croned.1/kas-perms.error";
	if(file_time_min($file)>10){
		email_events("Kaspersky Anti-spam socket error","it report:\n$buffer\nArtica will restart kas service...","postfix");
		@unlink($file);
		file_put_contents($file,"#");
		THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart kas3');
		
	}
	return null;
}


if(preg_match('#smtpd.+?warning: problem talking to server (.+?):\s+Connection refused#',$buffer,$re)){
	$pb=md5($re);
	$file="/etc/artica-postfix/croned.1/postfix-talking.$pb.error";
	$time=file_time_min($file);
	if($time>10){
		events("Postfix routing error {$re[1]}");
		email_events("Postfix routing error {$re[1]}","it report:\n$buffer\nPlease take a look of your routing table","postfix");
		@unlink($file);
		file_put_contents($file,"#");
	}
	events("Postfix routing error {$re[1]} (SKIP) $time/10mn");
	return null;
	
}



if(preg_match("#sync_client.+?connect\((.+?)\) failed: Connection refused#",$buffer,$re)){
$file="/etc/artica-postfix/croned.1/".md5($buffer);
	if(file_time_min($file)>10){
		email_events("Cyrus replica {$re[1]} cluster failed","it report:\n$buffer\n
		please check your support, mails will not be delivered until replica is down !","mailbox");
		@unlink($file);
		file_put_contents($file,"#");
	}
	return null;	
}


if(preg_match("#could not connect to amavisd socket /var/spool/postfix/var/run/amavisd-new/amavisd-new.sock: No such file or directory#",$buffer)){
	amavis_socket_error($buffer);
	return null;
	}
	
if(preg_match("#could not connect to amavisd socket.+?Connection timed out#",$buffer)){
	amavis_socket_error($buffer);
	return null;	
}

if(preg_match("#NOQUEUE: reject:.+?from.+?\[([0-9\.]+)\]:.+?Sender address rejected: Domain not found; from=<(.+?)> to=<(.+?)> proto#",$buffer,$re)){
	event_message_reject_hostname("Domain not found",$re[2],$re[3],$re[1]);
	events("{$re[1]} Domain not found from=<{$re[2]}> to=<{$re[3]}>");
	return null;
	}
	
if(preg_match("#NOQUEUE: reject:.+?from.+?\[([0-9\.]+)\]:.+?Client host rejected: cannot find your hostname.+?from=<(.+?)> to=<(.+?)> proto#",$buffer,$re)){
	event_message_reject_hostname("hostname not found",$re[2],$re[3],$re[1]);
	return null;
}

if(preg_match("#smtpd.+?NOQUEUE:.+?from.+?\[(.+?)\].+?Client host rejected.+?reverse hostname.+?from=<(.+?)>.+?to=<(.+?)>#",$buffer,$re)){
	event_message_reject_hostname("hostname not found",$re[2],$re[3],$re[1]);
	return null;
}

if(preg_match("#smtpd.+?NOQUEUE: reject.+?from.+?\[(.+?)\].+?Helo command rejected:.+?from=<(.+?)> to=<(.+?)>#",$buffer,$re)){
	event_message_reject_hostname("Helo command rejected",$re[2],$re[3],$re[1]);
	return null;
}
if(preg_match("#smtpd.+?NOQUEUE: reject.+?from.+?\[(.+?)\].+?4.3.5 Server configuration problem.+?from=<(.+?)> to=<(.+?)>#",$buffer,$re)){
	event_message_reject_hostname("Server configuration problem",$re[2],$re[3],$re[1]);
	return null;
}



if(preg_match("#cyrus.+?badlogin:\s+(.+?)\s+\[(.+?)\]\s+.+?\s+(.+?)\s+(.+)#",$buffer,$re)){
	$router=$re[1];
	$ip=$re[2];
	$user=$re[3];
	$error=$re[4];
	cyrus_bad_login($router,$ip,$user,$error);
	return null;
}



if(preg_match("#IOERROR.+?fstating sieve script\s+(.+?):\s+No such file or directory#",$buffer,$re)){
	THREAD_COMMAND_SET("/bin/touch \"".trim($re[1])."\"");
	return null;
}



if(preg_match("#smtp.+?\].+?([A-Z0-9]+):\s+to=<(.+?)>.+?status=deferred.+?\((.+?)command#",$buffer,$re)){
	event_message_rejected("deferred",$re[1],$re[2],$re[3]);
	return null;
}
if(preg_match("#smtp.+?:\s+(.+?):\s+to=<(.+?)>,\s+relay=none,.+?status=deferred \(connect to .+?\[(.+?)\].+?Connection refused#",$buffer,$re)){
	event_message_rejected("Connection refused",$re[1],$re[2],$re[3]);
	return null;
}



if(preg_match("#smtp.+?\].+?([A-Z0-9]+):.+?SASL authentication failed#",$buffer,$re)){
	event_messageid_rejected($re[1],"Authentication failed");
	return null;
}
if(preg_match("#smtp.+?\].+?([A-Z0-9]+):.+?refused to talk to me.+?554 RBL rejection#",$buffer,$re)){
	ImBlackListed($re[2],$buffer);
	event_messageid_rejected($re[1],"Your are blacklisted");
	return null;
}


if(preg_match("#smtp\[.+?:\s+(.+?):\s+to=<(.+?)>,\s+relay=.+?\[(.+?)\].+?status=deferred.+?refused to talk to me#",$buffer,$re)){
	ImBlackListed($re[3],$buffer);
	event_messageid_rejected($re[1],"Your are blacklisted",$re[3],$re[2]);
	return null;
}

if(preg_match("#postfix\/bounce\[.+?:\s+(.+?):\s+sender non-delivery notification#",$buffer,$re)){
	events("{$re[1]} non-delivery");
	event_messageid_rejected($re[1],"non-delivery",null,null);
	return null;
	}	


if(preg_match("#smtp\[.+?\]:\s+(.+?):\s+to=<(.+?)>, relay=(.+?)\[.+?status=bounced\s+\(.+?loops back to myself#",$buffer,$re)){
	event_messageid_rejected($re[1],"loops back to myself",$re[3],$re[2]);
	return null;
}



if(preg_match("#smtp\[.+?:\s+(.+?):\s+host.+?\[(.+?)\]\s+refused to talk to me:#",$buffer,$re)){
	ImBlackListed($re[2],$buffer);
	event_messageid_rejected($re[1],"Your are blacklisted",$re[2]);
	return null;
}





if(preg_match('#milter-greylist:.+?:.+?addr.+?from <(.+?)> to <(.+?)> delayed for#',
$buffer,$re)){
	event_message_milter_reject(md5($re[1].$re[2].date('Y-m d H is')),"Greylisting",$re[1],$re[2],$buffer);
	return null;
}

if(preg_match("#assp.+?<(.+?)>\s+to:\s+(.+?)\s+recipient delayed#",$buffer,$re)){
	event_message_milter_reject(md5($re[1].$re[2].date('Y-m d H is')),"Greylisting",$re[1],$re[2],$buffer);
	return null;
}

if(preg_match("#assp.+?MessageScoring.+?<(.+?)>\s+to:\s+(.+?)\s+\[spam found\]#",$buffer,$re)){
	event_message_milter_reject(md5($re[1].$re[2].date('Y-m d H is')),"SPAM",$re[1],$re[2],$buffer);
	return null;
}
if(preg_match("#assp.+?MalformedAddress.+?<(.+?)>\s+to:\s+(.+?)\s+\malformed address:'|(.+?)'#",$buffer,$re)){
	event_message_milter_reject(md5($re[1].$re[2].date('Y-m d H is')),"malformed address",$re[1],$re[2],$buffer);
	return null;
}

if(preg_match("#assp.+?\[Extreme\]\s+(.+?)\s+<(.+?)>\s+to:\s+(.+?)\s+\[spam found\]#",$buffer,$re)){
	event_message_milter_reject(md5($re[1].$re[2].date('Y-m d H is')),"SPAM",$re[2],$re[3],$buffer,$re[1]);
	return null;	
}


if(preg_match("#assp.+?<(.*?)>\s+to:\s+(.+?)\s+bounce delayed#",$buffer,$re)){
	if($re[1]==null){$re[1]="Unknown";}
	event_message_milter_reject(md5($re[1].$re[2].date('Y-m d H is')),"bounce delayed",$re[1],$re[2],$buffer);
}

if(preg_match("#assp.+?\[DNSBL\]\s+(.+?)\s+<(.*?)>\s+to:\s+(.+?)\s+#",$buffer,$re)){
	if($re[2]==null){$re[2]="Unknown";}
	event_message_reject_hostname("DNSBL",$re[2],$re[3],$re[1]);
	return null;
}
if(preg_match("#assp.+?\[URIBL\]\s+(.+?)\s+<(.*?)>\s+to:\s+(.+?)\s+#",$buffer,$re)){
	if($re[2]==null){$re[2]="Unknown";}
	event_message_reject_hostname("URIBL",$re[2],$re[3],$re[1]);
	return null;
}


if(preg_match("#assp.+?\[SpoofedSender\]\s+(.+?)\s+<(.*?)>\s+to:\s+(.+?)\s+.+?No Spoofing Allowed#",$buffer,$re)){
	if($re[2]==null){$re[2]="Unknown";}
	event_message_reject_hostname("SPOOFED",$re[2],$re[3],$re[1]);
	return null;
}
if(preg_match("#assp.+?\[InvalidHELO\]\s+(.+?)\s+<(.*?)>\s+to:\s+(.+?)\s+#",$buffer,$re)){
	if($re[2]==null){$re[2]="Unknown";}
	event_message_reject_hostname("BAD HELO",$re[2],$re[3],$re[1]);
	return null;
}


if(preg_match("#NOQUEUE: reject: RCPT from.+?<(.+?)>: Recipient address rejected: User unknown in relay recipient table;.+?to=<(.+?)> proto=SMTP#",
$buffer,$re)){
	$id=md5($re[1].$re[2].date('Y-m d H is'));
	event_finish($id,$re[2],"reject","User unknown",$re[1]);
	return null;
	
}

if(preg_match("#postfix\/lmtp.+?:\s+(.+?):\s+to=<(.+?)>.+?said:\s+550-Mailbox unknown#",$buffer,$re)){
	$id=$re[1];
	$to=$re[2];
	event_message_milter_reject($id,"Mailbox unknown",null,$re[2],$buffer);
	mailbox_unknown($buffer,$to);
	return null;
}


if(preg_match('#: (.+?): reject: RCPT.+?Relay access denied; from=<(.+?)> to=<(.+?)> proto=SMTP#',$buffer,$re)){
	if($re[1]=="NOQUEUE"){$re[1]=md5($re[3].$re[2].date('Y-m d H is'));}
	event_finish($re[1],$re[3],"reject","Relay access denied",$re[2],$buffer);
	return null;
}

if(preg_match('#postfix.+?cleanup.+?:\s+(.+?):\s+milter-reject: END-OF-MESSAGE.+4.6.0 Content scanner malfunction; from=<(.+?)> to=<(.+?)> proto=SMTP#',
$buffer,$re)){
	events("{$re[1]} Content scanner malfunction from=<{$re[2]}> to=<{$re[3]}>");
	event_Content_scanner_malfunction($re[1],$re[2],$re[3]);
	return null;
}
if(preg_match("#postfix.+?cleanup.+?:\s+(.+?):\s+milter-discard.+?END-OF-MESSAGE.+?DISCARD.+?from=<(.+?)> to=<(.+?)> proto=SMTP#",
$buffer,$re)){
	event_DISCARD($re[1],$re[2],$re[3],$buffer);
	return null;
}
	
if(preg_match("#^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+client=(.+)#",$buffer,$re)){
	$date=date('Y-m-d H:i:s');
	event_newmail($re[4],$date);
	return null;
}



if(preg_match("#^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+message-id=<(.*?)>#",$buffer,$re)){
	events("NEW message_id {$re[4]} {$re[5]}");
	event_message_id($re[4],$re[5]);
	return null;	
}
if(preg_match("#^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+from=<(.*?)>, size=([0-9]+)#",$buffer,$re)){
	events("NEW MAIL {$re[4]} <{$re[5]}> ({$re[6]} bytes)");
	event_message_from($re[4],$re[5],$re[6]);
	return null;
}

if(preg_match("#NOQUEUE: milter-reject: RCPT from.+?: 451 4.7.1 Greylisting in action, please come back in .+?; from=<(.+?)> to=<(.+?)> proto=SMTP#",$buffer,$re)){
	event_message_milter_reject(md5($re[1].$re[2].date('Y-m d H is')),"Greylisting",$re[1],$re[2],$buffer);
	return null;
}

if(preg_match("#^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+milter-reject:.+?:(.+?)\s+from=<(.+?)>#",$buffer,$re)){
	events("milter-reject {$re[4]} <{$re[5]}> ({$re[6]})");
	event_message_milter_reject($re[4],$re[5],$re[6],null,$buffer);
	return null;
}




if(preg_match("#^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+to=<(.+?)>,\s+orig_to=<.+?>,\s+relay=(.+?),\s+delay=.+?,\s+delays=.+?,\s+dsn=.+?,\s+status=([a-zA-Z]+)#"
,$buffer,$re)){
	if(preg_match('#\s+status=.+?\s+\((.+?)\)#',$buffer,$ri)){
		$bounce_error=$ri[1];
	}
   events("Finish {$re[4]} <{$re[5]}> ({$re[7]})");
   event_finish($re[4],$re[5],$re[7],$bounce_error,null,$buffer);   
   return null;
	
}
if(preg_match("#^([A-ZA-z]+)\s+([0-9]+)\s+([0-9\:]+).+?:\s+([A-Z0-9]+):\s+to=<(.+?)>,\s+relay=(.+?),\s+delay=.+?,\s+delays=.+?,\s+dsn=.+?,\s+status=([a-zA-Z]+)#"
,$buffer,$re)){
	if(preg_match('#\s+status=.+?\s+\((.+?)\)#',$buffer,$ri)){
		$bounce_error=$ri[1];
	}
   event_finish($re[4],$re[5],$re[7],$bounce_error,null,$buffer);   
   return null;	
}

	
//-------------------------------------------------------------- ERRORS

if(preg_match('#amavisd-milter.+?could not read from amavisd socket.+?\.sock:Connection timed out#',$buffer,$re)){
	amavis_socket_error($buffer);
	return null;
}

if(preg_match('#DBERROR: skiplist recovery\s+(.+?)\.seen:\s+ADD\s+at.+?exists#',$buffer,$re)){
	cyrus_bad_seen($re[1]);
	return null;
}

if(preg_match('#warning: milter unix.+?amavisd-milter.sock:.+SMFIC_MAIL reply packet header: Broken pipe#',$buffer,$re)){
	amavis_error_restart($buffer);
	return null;
}
if(preg_match('#sfupdates.+?KASERROR.+?keepup2date\s+failed.+?code.+?critical error#',$buffer,$re)){
	kas_error_update($buffer);
	return null;
}
if(preg_match('#DBERROR db4:(.+?): unexpected file type or format#',$buffer,$re)){
	cyrus_db_error($buffer,$re[1]);
	return null;
}

if(preg_match('#couldn.+?exec.+?imapd: Too many open files#',$buffer)){
	cyrus_generic_error($buffer,"Too many open files");
	return null;
}
if(preg_match("#sieve script\s+(.+?)\s+doesn.+?t exist: No such file or directory#",$buffer,$re)){
	cyrus_sieve_error($re[1]);
	return null;
}

if(preg_match('#lmtp.+?:\s+(.+?): to=<(.+?)>,.+?status=deferred.+?connect to .+?\[(.+?)\].+?No such file or directory#',
$buffer,$re)){
	event_message_milter_reject($re[1],"deferred",null,$re[1]);
	cyrus_socket_error($buffer,"$re[3]");
	return null;
}

if(preg_match('#lmtp.+?:(.+?):\s+to=<(.+?)>.+?said: 550-Mailbox unknown#',$buffer,$re)){
	event_message_milter_reject($re[1],"Mailbox unknown",null,$re[2]);
	mailbox_unknown($buffer,$re[2]);
	return null;
}

if(preg_match('#cyrus.+?:DBERROR.+?DB_VERSION_MISMATCH#',$buffer,$re)){
	cyrus_database_error($buffer);
	return null;
}


events("Not Filtered:\"$buffer\"");	
}





function events($text){
		$pid=@getmypid();
		$date=@date("H:i:s");
		$logFile="/var/log/artica-postfix/postfix-logger.debug";
		$size=@filesize($logFile);
		if($size>1000000){@unlink($logFile);}
		$f = @fopen($logFile, 'a');
		@fwrite($f, "[$pid] $date $text\n");
		@fclose($f);	
		}
		
function event_Content_scanner_malfunction($postfix_id,$from,$to){
	$file="/var/log/artica-postfix/RTM/$postfix_id.msg";
	$ini=new Bs_IniHandler($file);
	$ini->set("TIME","mailfrom","$from");
	$ini->set("TIME","mailto","$to");
	$ini->set("TIME","bounce_error","Content scanner malfunction");
	$ini->set("TIME","time_end",date("Y-m-d H:i:s"));
	$ini->set("TIME","delivery_success","no");
	$ini->saveFile($file);	
}
function event_DISCARD($postfix_id,$from,$to,$buffer=null){
	$file="/var/log/artica-postfix/RTM/$postfix_id.msg";
	$ini=new Bs_IniHandler($file);
	
	if(preg_match("#from.+?\[([0-9\.]+)?\]#",$buffer,$re)){$ini->set("TIME","smtp_sender",$re[1]);}	
	
	$ini->set("TIME","mailfrom","$from");
	$ini->set("TIME","mailto","$to");
	$ini->set("TIME","bounce_error","Discard");
	$ini->set("TIME","time_end",date("Y-m-d H:i:s"));
	$ini->set("TIME","delivery_success","no");
	$ini->saveFile($file);	
}
function event_newmail($postfix_id,$date){
	$file="/var/log/artica-postfix/RTM/$postfix_id.msg";
	$ini=new Bs_IniHandler($file);
	$ini->set("TIME","time_connect",$date);
	$ini->set("TIME","delivery_success","no");
	$ini->saveFile($file);	
}
function event_message_from($postfix_id,$from,$size){
	$file="/var/log/artica-postfix/RTM/$postfix_id.msg";
	$ini=new Bs_IniHandler($file);
	$ini->set("TIME","mailfrom",$from);
	$ini->set("TIME","mailsize",$size);
	$ini->set("TIME","time_connect",date("Y-m-d H:i:s"));
	$ini->set("TIME","delivery_success","no");
	$ini->saveFile($file);	
}
function event_message_milter_reject($postfix_id,$reject,$from,$to=null,$buffer=null,$sender=null){
	$file="/var/log/artica-postfix/RTM/$postfix_id.msg";
	$ini=new Bs_IniHandler($file);
	if($sender==null){
		if(preg_match("#from.+?\[([0-9\.]+)?\]#",$buffer,$re)){$ini->set("TIME","smtp_sender",$re[1]);}	
		if(preg_match("#assp\[.+?\]:\s+.+?\s+(.+?)\s+<#",$buffer,$re)){$ini->set("TIME","smtp_sender",$re[1]);}
	}
	if($to<>null){$ini->set("TIME","mailto",$to);}
	if($from<>null){$ini->set("TIME","mailfrom",$from);}
	$ini->set("TIME","bounce_error",$reject);
	$ini->set("TIME","time_connect",date("Y-m-d H:i:s"));
	$ini->set("TIME","delivery_success","no");
	$ini->saveFile($file);	
}

function event_message_reject_hostname($reject,$from,$to=null,$server){
	$file="/var/log/artica-postfix/RTM/".md5(date("Y-m-d H:i:s").$server.$from).".msg";
	$ini=new Bs_IniHandler($file);
	$ini->set("TIME","smtp_sender",$server);	
	if($to<>null){$ini->set("TIME","mailto",$to);}
	if($from<>null){$ini->set("TIME","mailfrom",$from);}
	$ini->set("TIME","bounce_error",$reject);
	$ini->set("TIME","time_connect",date("Y-m-d H:i:s"));
	$ini->set("TIME","delivery_success","no");
	$ini->saveFile($file);	
}


function event_messageid_rejected($msg_id_postfix,$error,$server=null,$to=null){
	$file="/var/log/artica-postfix/RTM/$msg_id_postfix.msg";
	$ini=new Bs_IniHandler($file);
	if($server<>null){$ini->set("TIME","smtp_sender",$server);}
	if($to<>null){$ini->set("TIME","mailto",$to);}
	$ini->set("TIME","delivery_success","no");
	$ini->set("TIME","bounce_error",$error);
	$ini->set("TIME","time_connect",date("Y-m-d H:i:s"));
	$ini->saveFile($file);		
}

function event_message_rejected($reject,$msg_id_postfix,$to=null,$buffer){
	$file="/var/log/artica-postfix/RTM/$msg_id_postfix.msg";
	$ini=new Bs_IniHandler($file);
	
	if(preg_match("#invalid sender domain#",$buffer)){
		$reject="Invalid sender domain";
	}
	
	if(preg_match("#^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+#",$buffer)){
		$ini->set("TIME","server_from","$buffer");
	}
	
	if($to<>null){$ini->set("TIME","mailto",$to);}
	
	$ini->set("TIME","bounce_error",$reject);
	$ini->set("TIME","time_connect",date("Y-m-d H:i:s"));
	$ini->set("TIME","delivery_success","no");
	$ini->saveFile($file);	
}

function event_message_id($postfix_id,$messageid){
	$file="/var/log/artica-postfix/RTM/$postfix_id.msg";
	$ini=new Bs_IniHandler($file);
	$ini->set("TIME","message-id","$messageid");
	$ini->set("TIME","time_connect",date("Y-m-d H:i:s"));
	$ini->saveFile($file);		
}
		
function event_greylisted($server,$from){
	$file="/var/log/artica-postfix/RTM/".md5(date("Y-m-d H:i:s").$server.$from).".msg";
	$ini=new Bs_IniHandler($file);
	$ini->set("TIME","mailfrom","$from");
	$ini->set("TIME","server_from","$server");
	$ini->set("TIME","bounce_error","greylisted");
	$ini->set("TIME","time_end",date("Y-m-d H:i:s"));
	$ini->set("TIME","delivery_success","no");
	$ini->saveFile($file);
}
function event_finish($postfix_id,$to,$status,$bounce_error,$from=null,$buffer=null){
 
    $delivery_success='yes';
    if($status='bounced'){$delivery_success='no';}
	if($status='deferred'){$delivery_success='no';}
	if($status='reject'){$delivery_success='no';}
	if($status='expired'){$delivery_success='no';}
    
	if(preg_match("#Queued mail for delivery#",$bounce_error)){
		$status="Deliver";
		$delivery_success="yes";
		$bounce_error="Sended";
	}
	
	if(preg_match("#Sender address rejected: need fully-qualified address#",$bounce_error)){
		$status="rejected";
		$delivery_success="no";
		$bounce_error="need fully-qualified address";
	}
	
	if(preg_match("#no mailbox here#",$bounce_error)){
		$status="rejected";
		$delivery_success="no";
		$bounce_error="Mailbox Unknown";
	}	
	
	if(preg_match("#refused to talk to me.+?RBL rejection#",$bounce_error)){
			$status="rejected";
			$delivery_success="no";
			$bounce_error="RBL";
	}

	if(preg_match("#550.+?Service unavailable.+?blocked using.+?RBL#",$bounce_error)){
			$status="rejected";
			$delivery_success="no";
			$bounce_error="RBL";
	}
	
	if(preg_match("#554 : Recipient address rejected: Access denied#",$bounce_error)){
			$status="rejected";
			$delivery_success="no";
			$bounce_error="Access denied";
	}	
	
	
	if(preg_match("#451 4.2.0 Mailbox has an invalid format#",$bounce_error)){
			$status="rejected";
			$delivery_success="no";
			$bounce_error="Mailbox corrupt";
	}		
	
	if(preg_match("#delivered via#",$bounce_error)){
		$status="Deliver";
		$delivery_success="yes";
		$bounce_error="Sended";
	}
	
	
	if(preg_match("#Content scanner malfunction#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="Content scanner malfunction";
	}
	
	if(preg_match("#4\.5\.0 Failure#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="Error";
	}	
	
	
	if(preg_match("#250 2\.0\.0 Ok#",$bounce_error)){
		$status="Deliver";
		$delivery_success="yes";
		$bounce_error="Sended";
	}
	
	if(preg_match("#Host or domain name not found#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="Host or domain name not found";
	}
	
	
	if(preg_match("#4\.5\.0 Error in processing#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="Error";
	};
	
if(preg_match("#Sender address rejected.+?Domain not found#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="Domain not found";
	};	
	
if(preg_match("#delivered to command: procmail -a#",$bounce_error)){
		$status="Deliver";
		$delivery_success="yes";
		$bounce_error="Sent to procmail";
	};

if(preg_match("#550 must be authenticated#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="Authentication error";
	};	

if(preg_match("#250 Message.+?accepted by#",$bounce_error)){
		$status="Deliver";
		$delivery_success="yes";
		$bounce_error="Sended";
	};		
	
	
if(preg_match("#Connection timed out#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="timed out";
	};	
	
if(preg_match("#connect\s+to.+?Connection refused#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="Connection refused";		
}

if(preg_match("#temporary failure.+?artica-msmtp:\s+recipient address\s+(.+?)\s+not accepted by the server artica-msmtp#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="artica-filter error";		
}
		
	if(preg_match("#250 2\.1\.5 Ok#",$bounce_error)){
		$status="Deliver";
		$delivery_success="yes";
		$bounce_error="Sended";
	}
	
	if($bounce_error=="250 OK: data received"){
		$status="Deliver";
		$delivery_success="yes";
		$bounce_error="Sended";		
	}
	
	if($bounce_error=="250 Ok: queued as"){
			$status="Deliver";
			$delivery_success="yes";
			$bounce_error="Sended";		
		}


	
	
	if(preg_match("#504.+?Recipient address rejected#",$bounce_error)){
		$status="Error";
		$delivery_success="no";
		$bounce_error="recipient address rejected";
		
	}
	
if(preg_match("#Address rejected#",$bounce_error)){
			$status="Error";
			$delivery_success="no";
			$bounce_error="Address rejected";
			}

if(preg_match("#conversation with .+?timed out#",$bounce_error)){
			$status="Error";
			$delivery_success="no";
			$bounce_error="timed out";
			}	

if(preg_match("#connect to\s+(.+?)\[.+?cyrus.+?lmtp\]: Connection refused#",$bounce_error)){
			$status="Error";
			$delivery_success="no";
			$bounce_error="mailbox service error";
			cyrus_generic_error($bounce_error,"Cyrus socket error");	
			}
	
if(preg_match("#host.+?\[(.+?)\]\s+said:.+?<(.+?)>: Recipient address rejected: User unknown in local recipient table#",$bounce_error)){
			$status="Error";
			$delivery_success="no";
			$bounce_error="User unknown";
			$to=$re[2];
			}
			
			
		if(preg_match("#said:.+?Authentication required#",$bounce_error)){
					$status="Error";
					$delivery_success="no";
					$bounce_error="Authentication required";	
		}
		
		if(preg_match("#temporary failure.+?[0-9]+\s+[0-9\.]+\s+Bad sender address syntax.+?could not send mail#",$bounce_error)){
					$status="Error";
					$delivery_success="no";
					$bounce_error="Bad sender address syntax";	
		}
		
		if(preg_match("#connect.+?Permission denied#",$bounce_error)){
					$status="Error";
					$delivery_success="no";
					$bounce_error="service permissions error";	
		}
		
		if(preg_match("#Command died with status 255:.+?exec\.artica-filter\.php#",$bounce_error)){
					$status="Error";
					$delivery_success="no";
					$bounce_error="artica-filter error";
		}
		if(preg_match("#250 2\.5\.0\s+Ok#",$bounce_error)){
			$status="Deliver";
			$delivery_success="yes";
			$bounce_error="Sended";
		}

			

if($delivery_success=="no"){
			if($bounce_error=="User unknown in relay recipient table"){$bounce_error="User unknown";}
			
	    	events("event_finish() line ".__LINE__. " bounce_error=$bounce_error");
	    	if(preg_match("#connect to.+?\[(.+?)lmtp\].+?No such file or directory#",$bounce_error,$ra)){
	    		events("Cyrus error found -> CyrusSocketErrot");
	    		cyrus_socket_error($bounce_error,$ra[1].'/lmtp');
	    		}
	    	if(preg_match("#550\s+User\s+unknown\s+<(.+?)>.+?in reply to RCPT TO command#",$bounce_error,$ra)){mailbox_unknown($bounce_error,$ra[1]);}
	    }
    
	$file="/var/log/artica-postfix/RTM/$postfix_id.msg";
	$ini=new Bs_IniHandler($file);
	if(preg_match("#from.+?\[([0-9\.]+)?\]#",$buffer,$re)){$ini->set("TIME","smtp_sender",$re[1]);}	
	if($from<>null){$ini->set("TIME","mailfrom",$from);}
	$ini->set("TIME","mailto","$to");
	$ini->set("TIME","bounce_error","$bounce_error");
	$ini->set("TIME","time_end",date("Y-m-d H:i:s"));
	$ini->set("TIME","delivery_success","$delivery_success");
	
	events("event_finish() [$postfix_id]: $from => $to err=$bounce_error success=$delivery_success");
	
	$ini->saveFile($file);	    
       
	
}

function cyrus_imap_conx($service,$server,$server_ip,$user){
	$date=date('Y-m-d H:i:s');
	events("imap connection $user from ($server_ip)");
	$sql="INSERT INTO mbx_con (`zDate`,`mbx_service`,`client_name`,`client_ip`,`uid`,`imap_server`)
	VALUES('$date','$service','$server','$server_ip','$user','{$_GET["server"]}')";
	$md5=md5($sql);
	@mkdir("/var/log/artica-postfix/IMAP",0750,true);
	$file="/var/log/artica-postfix/IMAP/$md5.sql";
	@file_put_contents($file,$sql);
}


function CyrusSocketErrot(){
	
	
}

function _MonthToInteger($month){
  $zText=$month;	
  $zText=str_replace('JAN', '01',$zText);
  $zText=str_replace('FEB', '02',$zText);
  $zText=str_replace('MAR', '03',$zText);
  $zText=str_replace('APR', '04',$zText);
  $zText=str_replace('MAY', '05',$zText);
  $zText=str_replace('JUN', '06',$zText);
  $zText=str_replace('JUL', '07',$zText);
  $zText=str_replace('AUG', '08',$zText);
  $zText=str_replace('SEP', '09',$zText);
  $zText=str_replace('OCT', '10',$zText);
  $zText=str_replace('NOV', '11',$zText);
  $zText=str_replace('DEC', '12',$zText);
  return $zText;	
}
function email_events($subject,$text,$context){
	send_email_events($subject,$text,$context);
	}
	
function interface_events($product,$line){
	$ini=new Bs_IniHandler();
	if(is_file("/usr/share/artica-postfix/ressources/logs/interface.events")){
		$ini->loadFile("/usr/share/artica-postfix/ressources/logs/interface.events");
	}
	$ini->set($product,'error',$line);
	$ini->saveFile("/usr/share/artica-postfix/ressources/logs/interface.events");
	@chmod("/usr/share/artica-postfix/ressources/logs/interface.events",0755);
	
}



function amavis_socket_error($line){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	$ftime=file_time_min($file);
	if($ftime<15){
		events("Unable to process new operation for amavis...waiting 15mn (current {$ftime}mn)");
		return null;
	}
	THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart amavis");
	email_events("Warning Amavis socket is not available",$line." (Postfix claim that amavis socket is not available, 
	Artica will restart amavis service)","postfix");
	@unlink($file);
	@mkdir("/etc/artica-postfix/cron.1");
	@file_put_contents($file,"#");	
}

function mailbox_unknown($line,$to){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.'.'.md5($to);
	if(file_time_min($file)<15){return null;}
	email_events("Warning unknown mailbox $to","Postfix claim: $to mailbox is not available you should create an alias or mailbox $line","mailbox");
	@unlink($file);
	@file_put_contents($file,"#");	
	
}
function cyrus_mailbox_not_exists($line,$user){
	$user=str_replace('^','.',$user);
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.'.'.md5($user);
	if(file_time_min($file)<15){return null;}
	email_events("Warning Mailbox does not exist $user","Mailbox server claim: $user mailbox is not available you should create an alias or mailbox $line","mailbox");
	@unlink($file);
	@file_put_contents($file,"#");	
	
}

function cyrus_bad_seen($fileseen){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	$fileseen=$fileseen.".seen";
	if(file_time_min($file)<15){return null;}
	email_events('Warning Corrupted mailbox detected','Cyrus claim that '.$fileseen.'is corrupted, Artica will delete this file to repair it','mailbox');
    THREAD_COMMAND_SET("/usr/share/artica-postfix/bin/artica-backup --repair-seen-file $fileseen");
	@unlink($file);
	file_put_contents($file,"#");
 }
 
function amavis_error_restart($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	email_events('Warning Amavis error',"Amavis claim that $buffer, Artica will restart amavis",'postfix');
	THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart amavis");
	@unlink($file);
	file_put_contents($file,"#");	
	}
	
	function clamav_error_restart($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	email_events('Warning Clamad error',"Postfix claim that $buffer, Artica will restart clamav",'postfix');
	THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart clamd");
	@unlink($file);
	file_put_contents($file,"#");	
	}	
	
function kas_error_update($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	email_events('Kaspersky Anti-spam report failure when updating it`s database',"for your information: $buffer",'postfix');
	THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart amavis");
	@unlink($file);
	file_put_contents($file,"#");	
	}
function cyrus_db_error($buffer,$dbfile){
	$dbfile=strim($dbfile);
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	$stime=date('YmdHis');
	$b_path="$dbfile.bak.$stime";
	@unlink($dbfile);
	THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart imap');
	email_events("Warning cyrus db error on $dbfile","cyrus-imap claim: $buffer file will be backuped to",'mailbox');
	@unlink($file);
	file_put_contents($file,"#");	
	}
function cyrus_generic_error($buffer,$subject){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	events("Cyrus error !! $buffer (cache=$file)");
	email_events("cyrus-imapd error: $subject","$buffer, Artica will restart cyrus",'mailbox');
	THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart imap");
	@unlink($file);
	file_put_contents($file,"#");
	
}

function cyrus_generic_reconfigure($buffer,$subject){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	events("Cyrus error !! $buffer (cache=$file)");
	email_events("cyrus-imapd error: $subject","$buffer, Artica will reconfigure cyrus",'mailbox');
	THREAD_COMMAND_SET("/usr/share/artica-postfix/bin/artica-install --reconfigure-cyrus");
	@unlink($file);
	file_put_contents($file,"#");	
	
}


function cyrus_sieve_error($file){
	THREAD_COMMAND_SET("/bin/touch $file");
}

function cyrus_socket_error($buffer,$socket){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	email_events("cyrus-imapd socket error: $socket","Postfix claim \"$buffer\", Artica will restart cyrus",'mailbox');
	THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --cyrus-checkconfig');
	THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart imap');
	@unlink($file);
	@file_put_contents($file,"#");
}

function MilterSpamAssassinError($buffer,$socket){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	email_events("spamassin-milter socket error: $socket","Postfix claim \"$buffer\", Artica will reload Postfix and compile new Postfix settings",'postfix');
	THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --postfix-reload');
	@unlink($file);
	@file_put_contents($file,"#");	
}


function AmavisConfigErrorInPostfix($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	$timeFile=file_time_min($file);
	if($timeFile<15){
		events("*** $buffer ****");
		events("amavisd-new socket no operations, blocked by timefile $timeFile Mn!!!");
		return null;}	
	events("amavisd-new socket error time:$timeFile Mn!!!");
	email_events("amavisd-new socket error","Postfix claim \"$buffer\", Artica will reload Postfix and compile new Postfix settings",'postfix');
	THREAD_COMMAND_SET("{$GLOBALS["PHP5_BIN"]} ".dirname(__FILE__)."/exec.postfix.maincf.php --reconfigure");
	THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart amavis');
	THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --postfix-reload');
	@unlink($file);
	@file_put_contents($file,"#");	
	if(!is_file($file)){
		events("error writing time file:$file");
	}
}

function SpamAssassin_error_saupdate($buffer){
$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	$timeFile=file_time_min($file);
	if($timeFile<15){
		events("*** $buffer ****");
		events("Spamassassin no operations, blocked by timefile $timeFile Mn!!!");
		return null;}	
	events("Spamassassin error time:$timeFile Mn!!!");
	email_events("SpamAssassin error Regex","SpamAssassin claim \"$buffer\", Artica will run /usr/bin/sa-update to fix it",'postfix');
	THREAD_COMMAND_SET("/usr/share/artica-postfix/bin/artica-update --spamassassin --force");
	@unlink($file);
	@file_put_contents($file,"#");	
	if(!is_file($file)){
		events("error writing time file:$file");
	}	
}

function miltergreylist_error($buffer,$socket){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	email_events("Milter Greylist error: $socket","System claim \"$buffer\", Artica will restart milter-greylist",'postfix');
	THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart mgreylist');
	@unlink($file);
	@file_put_contents($file,"#");
}

function cyrus_database_error($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}
	email_events("cyrus-imapd FATAL error !! database engine is incompatible reinstall mailbox system !","Cyrus claim: $buffer",'mailbox');
	interface_events("APP_CYRUS_IMAP",$buffer);
	@unlink($file);
	@file_put_contents($file,"#");
}

function MilterClamavError($buffer,$socket){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	email_events("Milter-clamav socket error: $socket","Postfix claim \"$buffer\", 
	Artica will grant postfix to this socket\but you can use amavis instead that will handle clamav antivirus scanner too",'postfix');
	THREAD_COMMAND_SET("/bin/chmod -R 775 ". dirname($socket));
	THREAD_COMMAND_SET("/bin/chown -R postfix:postfix ". dirname($socket));
	THREAD_COMMAND_SET("postqueue -f");
	@unlink($file);
	@file_put_contents($file,"#");	
	
}
function AmavisConfigErrorInPostfixRestart($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){return null;}	
	email_events("Amavis network error: $socket","Postfix claim \"$buffer\", Artica will restart postfix",'postfix');
	THREAD_COMMAND_SET("/etc/init.d/artica-postfix restart postfix");
	@unlink($file);
	@file_put_contents($file,"#");		
}
function ImBlackListed($server,$buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.".".md5($server);
	if(file_time_min($file)<15){return null;}	
	email_events("Your are blacklisted from $server","Postfix claim \"$buffer\", try to investigate why or contact our technical support",'postfix');
	@unlink($file);
	@file_put_contents($file,"#");		
}


function postfix_compile_db($hash_file,$buffer){
	$unix=new unix();
	events("DB Problem -> $hash_file");
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.".".md5($hash_file);
	if(file_time_min($file)<5){return null;}
	
	if(!is_file($hash_file)){
		@file_put_contents($hash_file,"#");
	}
	email_events("Postfix Database problem","Postfix claim \"$buffer\", Artica will recompile ".basename($hash_file),'postfix');
	$cmd=$unix->find_program("postmap"). " hash:$hash_file";
	THREAD_COMMAND_SET($cmd);
	events("DB Problem -> $hash_file -> $cmd");
	THREAD_COMMAND_SET($unix->find_program("postfix"). " reload");		
	@unlink($file);
	@file_put_contents($file,"#");		
	
}

function postfix_compile_missing_db($hash_file,$buffer){
	$unix=new unix();
	events("DB Problem -> $hash_file");
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.".".md5($hash_file);
	if(file_time_min($file)<5){return null;}
	
	if(!is_file($hash_file)){
		@file_put_contents($hash_file,"#");
	}
	
	email_events("Postfix Database problem","Postfix claim \"$buffer\", Artica will create blanck file and recompile ".basename($hash_file),'postfix');
	$cmd=$unix->find_program("postmap"). " hash:$hash_file";
	THREAD_COMMAND_SET($cmd);
	events("DB Problem -> $hash_file -> $cmd");
	THREAD_COMMAND_SET($unix->find_program("postfix"). " reload");		
	@unlink($file);
	@file_put_contents($file,"#");		
	
}

function cyrus_bad_login($router,$ip,$user,$error){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.".".md5("$router,$ip,$user,$error");
	if(file_time_min($file)<15){return null;}	
	@unlink($file);
	email_events("User $user cannot login to mailbox","cyrus claim \"$error\" for $user (router:$router, ip:$ip),
	 please,send the right password to $user",'mailbox');
	@file_put_contents($file,"#");		
}

function smtp_sasl_failed($router,$ip,$buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.".".md5("$router,$ip");
	if(file_time_min($file)<15){return null;}
	@unlink($file);
	email_events("SMTP authentication failed from $router","Postfix claim \"$buffer\" for ip address $ip",'postfix');
	@file_put_contents($file,"#");		
}

function kavmilter_expired($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.".expired";
	if(file_time_min($file)<15){return null;}
	@unlink($file);
	@file_put_contents("/etc/artica-postfix/settings/Daemons/kavmilterEnable","0");
	$cmd=LOCATE_PHP5_BIN()." ".dirname(__FILE__)."/exec.postfix.maincf.php --reconfigure";
	events("$cmd");
	THREAD_COMMAND_SET($cmd);
	THREAD_COMMAND_SET("/etc/init.d/artica-postfix stop kavmilter");
	email_events("Kaspersky For Mail server, license expired","Postfix claim \"$buffer\" Artica will disable Kaspersky and restart postfix",'postfix');
	@file_put_contents($file,"#");
	}

function hackPOP($ip,$logon,$buffer){
	if($GLOBALS["PopHackEnabled"]==0){return;}
	$file="/etc/artica-postfix/croned.1/postfix.hackPop3.error";
	if($ip=="127.0.0.1"){return;}
	$GLOBALS["POP_HACK"][$ip]=$GLOBALS["POP_HACK"][$ip]+1;
	$count=$GLOBALS["POP_HACK"][$ip];
	events("POP HACK {$ip} email={$logon} $count/{$GLOBALS["PopHackCount"]} failed");

	if(file_time_min($file)>10){
			email_events("POPHACK {$ip}/{$logon} $count/{$GLOBALS["PopHackCount"]} failed",
			"Mailbox server claim $buffer\nAfter ( $count/{$GLOBALS["PopHackCount"]}) {$GLOBALS["PopHackCount"]} times failed, 
			a firewall rule will added","mailbox");
			@unlink($file);
		}else{
			events("User not found for mailbox {$ip}/{$logon} $count/{$GLOBALS["PopHackCount"]} failed");
		}	
	
	if($GLOBALS["POP_HACK"][$ip]>=$GLOBALS["PopHackCount"]){
		shell_exec("iptables -I INPUT -s {$ip} -j DROP");
		events("POP HACK RULE CREATED {$ip} $count/{$GLOBALS["PopHackCount"]} failed");
		email_events("HACK pop3 from {$ip}","A firewall rule has been created and this IP:{$ip} is now denied ","mailbox");
		unset($GLOBALS["POP_HACK"][$ip]);
	}
	file_put_contents($file,"#");	
}


function zarafa_store_error($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.".store.error";
	if(file_time_min($file)<3600){return null;}
	@unlink($file);
	$cmd=LOCATE_PHP5_BIN()." ".dirname(__FILE__)."/exec.zarafa.build.stores.php";
	events("$cmd");
	THREAD_COMMAND_SET($cmd);
	email_events("Zarafa mailbox server store error","Zarafa claim \"$buffer\" Artica will try to reactivate stores and accounts",'mailbox');
	@file_put_contents($file,"#");	
}

function postfix_nosuch_fileor_directory($service,$targetedfile,$buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.md5($targetedfile).".postfix.file";
	if(file_time_min($file)<15){return null;}	
	@unlink($file);
	
	$targetedfile=trim($targetedfile);
	if($targetedfile==null){return;}
	if(preg_match("#(.+?)\.db$#",$targetedfile,$re)){
		$unix=new unix();
		$postmap=$unix->find_program("postmap");
		$cmd="/bin/touch {$re[1]}";
		events(__FUNCTION__. " <$cmd>");
		THREAD_COMMAND_SET($cmd);
		$cmd="$postmap hash:{$re[1]}";
		events(__FUNCTION__. " <$cmd>");
		THREAD_COMMAND_SET($cmd);
		email_events("missing database ". basename($file),"Service postfix/$service claim \"$buffer\" Artica will create a blank $targetedfile",'smtp');
		THREAD_COMMAND_SET("postfix reload");
		@file_put_contents($file,"#");	
		return;		
	 }
	

	
	$cmd="/bin/touch $targetedfile";
	events("$cmd");
	THREAD_COMMAND_SET($cmd);
	THREAD_COMMAND_SET("postfix reload");
	email_events("missing ". basename($file),"Service postfix/$service claim \"$buffer\" Artica will create a blank $targetedfile",'smtp');
	@file_put_contents($file,"#");		
}
function postfix_baddb($service,$targetedfile,$buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.md5($targetedfile).".postfix.file";
	if(file_time_min($file)<15){return null;}	
	@unlink($file);
	$targetedfile=trim($targetedfile);
	if($targetedfile==null){return;}	
	$unix=new unix();
	$postmap=$unix->find_program("postmap");
	$cmd="$postmap hash:$targetedfile";
	events(__FUNCTION__. " <$cmd>");
	THREAD_COMMAND_SET($cmd);
	email_events("corrupted database ". basename($file),"Service postfix/$service claim \"$buffer\" Artica will rebuild $targetedfile.db",'smtp');
	THREAD_COMMAND_SET("postfix reload");
	@file_put_contents($file,"#");	
	return;			
}

function multi_instances_reconfigure($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.".postfix.file";
	if(file_time_min($file)<15){return null;}	
	@unlink($file);
	$cmd="{$GLOBALS["PHP5_BIN"]} /usr/share/artica-postfix/exec.postfix-multi.php";
	events(__FUNCTION__. " <$cmd>");
	THREAD_COMMAND_SET($cmd);	
	email_events("multi-instances not correctly set","Service postfix claim \"$buffer\" Artica will rebuild multi-instances settings",'smtp');
	@file_put_contents($file,"#");	
	return;		
}

function postfix_bind_error($ip,$port,$buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.md5("$ip:$port");
	if(file_time_min($file)<15){
		events("Postfix bind error, time-out");
		return null;
	}	
	@unlink($file);
	$cmd="{$GLOBALS["PHP5_BIN"]} /usr/share/artica-postfix/exec.postfix-multi.php --restart-all";
	events(__FUNCTION__. " <$cmd>");
	THREAD_COMMAND_SET($cmd);	
	email_events("Unable to bind $ip:$port","Service postfix claim \"$buffer\" Artica will restart all daemons to fix it",'smtp');
	@file_put_contents($file,"#");	
	return;	
}

function cyrus_vertificate_error($buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){
		events("Cyrus certificate error, time-out");
		return null;
	}	
	@unlink($file);
	$cmd="/usr/share/artica-postfix/bin/artica-install -cyrus ssl";
	events(__FUNCTION__. " <$cmd>");
	THREAD_COMMAND_SET($cmd);	
	email_events("Cyrus certificate error","Service cyrus claim \"$buffer\" Artica will rebuild certificate for cyrus-imapd",'mailbox');
	@file_put_contents($file,"#");	
	return;		
}

function mailbox_corrupted($buffer,$mail){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.md5($mail);
	if(file_time_min($file)<15){
		events("mailbox_corrupted <$mail>, time-out");
		return null;
	}	
	@unlink($file);
	email_events("Corrupted mailbox $mail","Service postfix claim \"$buffer\" try to repair the mailbox or to use the command line
	turned out to be corrupted quota files:
	find ~cyrus -type f | grep quota\nremove the quota files for the affected mailbox(es)\nrun
	reconstruct -r -f user/mailboxoftheuser\n\n
	if you cannot perform this operation, you can open a ticket on artica technology company http://www.artica-technology.com' ",'mailbox');
	@file_put_contents($file,"#");	
	return;		
}

function mailbox_overquota($buffer,$mail){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__.md5($mail);
	if(file_time_min($file)<15){
		events("mailbox_overquota <$mail>, time-out");
		return null;
	}	
	@unlink($file);
	email_events("mailbox $mail Over Quota","Service postfix claim \"$buffer\" try to increase quota for $mail' ",'mailbox');
	@file_put_contents($file,"#");	
	return;		
}

function zarafa_rebuild_db($table,$buffer){
	$file="/etc/artica-postfix/cron.1/".__FUNCTION__;
	if(file_time_min($file)<15){
		events("Zarafa missing table <$table>, time-out");
		return null;
	}	
	@unlink($file);
	email_events("Zarafa missing Mysql table $table","Service Zarafa claim \"$buffer\" artica will destroy the zarafa database in order to let the Zarafa service create a new one' ",'mailbox');
	THREAD_COMMAND_SET("{$GLOBALS["PHP5_BIN"]} ".dirname(__FILE__)."/exec.mysql.build.php --rebuild-zarafa");
	@file_put_contents($file,"#");	
	return;		
	
}


function smtp_hack_reconfigure(){
	
	if(is_file("/var/log/artica-postfix/smtp-hack-reconfigure")){
		@unlink("/var/log/artica-postfix/smtp-hack-reconfigure");
	}
	
	$sock=new sockets();
	$GLOBALS["SMTP_HACK_CONFIG_RATE"]=unserialize(base64_decode($sock->GET_INFO("PostfixAutoBlockParameters")));
	
	
if($GLOBALS["SMTP_HACK_CONFIG_RATE"]["NAME_SERVICE_NOT_KNOWN"]<1){
		$GLOBALS["SMTP_HACK_CONFIG_RATE"]["NAME_SERVICE_NOT_KNOWN"]=10;
}

if($GLOBALS["SMTP_HACK_CONFIG_RATE"]["SASL_LOGIN"]<1){
		$GLOBALS["SMTP_HACK_CONFIG_RATE"]["SASL_LOGIN"]=15;
}
if($GLOBALS["SMTP_HACK_CONFIG_RATE"]["RBL"]<1){
		$GLOBALS["SMTP_HACK_CONFIG_RATE"]["RBL"]=5;
}	
if($GLOBALS["SMTP_HACK_CONFIG_RATE"]["USER_UNKNOWN"]<1){
		$GLOBALS["SMTP_HACK_CONFIG_RATE"]["USER_UNKNOWN"]=10;
}	
if($GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]<1){
		$GLOBALS["SMTP_HACK_CONFIG_RATE"]["BLOCKED_SPAM"]=5;
}	
if($GLOBALS["SMTP_HACK_CONFIG_RATE"]["ADDRESS_NOT_LISTED"]<1){
		$GLOBALS["SMTP_HACK_CONFIG_RATE"]["ADDRESS_NOT_LISTED"]=2;
}	


while (list ($num, $ligne) = each ($GLOBALS["SMTP_HACK_CONFIG_RATE"]) ){
	$info="Starting......: artica-postfix realtime logs SMTP HACK: $num=$ligne";
	events($info);
	echo $info."\n";
}
	
	
}


function smtp_hack_perform($servername,$array,$matches){
	
	//email_events("SMTP HACKING !!!!","Build iptables rule \"iptables -I INPUT -s {$re[1]} -j DROP\" for {$re[1]}!\nlast error: $buffer","postfix");
	//shell_exec("iptables -I INPUT -s {$re[1]} -j DROP");
	//events("SMTP Hack: -> iptables -I INPUT -s {$re[1]} -j DROP");
	
	$NAME_SERVICE_NOT_KNOWN=$array["NAME_SERVICE_NOT_KNOWN"];
	$SASL_LOGIN=$array["SASL_LOGIN"];
	$USER_UNKNOWN=$array["USER_UNKNOWN"];
	$RBL=$array["RBL"];
	$BLOCKED_SPAM=$array["BLOCKED_SPAM"];
	$ADDRESS_NOT_LISTED=$array["ADDRESS_NOT_LISTED"];
	
	if($NAME_SERVICE_NOT_KNOWN==null){$NAME_SERVICE_NOT_KNOWN=0;}
	if($SASL_LOGIN==null){$SASL_LOGIN=0;}
	if($USER_UNKNOWN==null){$USER_UNKNOWN=0;}
	if($RBL==null){$RBL=0;}
	if($BLOCKED_SPAM==null){$BLOCKED_SPAM=0;}
	if($ADDRESS_NOT_LISTED==null){$ADDRESS_NOT_LISTED=0;}
	
	//$EnablePostfixAutoBlock=$sock->GET_INFO("EnablePostfixAutoBlock");
	
	$text="
	Rule matched: $matches
	--------------------------------------------------------
	NAME_SERVICE_NOT_KNOWN attempts:\t$NAME_SERVICE_NOT_KNOWN
	SASL_LOGIN attempts:\t$SASL_LOGIN
	RBL attempts:\t$RBL
	USER_UNKNOWN attempts:\t$USER_UNKNOWN
	ADDRESS_NOT_LISTED attempts:\t$ADDRESS_NOT_LISTED
	BLOCKED_SPAM attempts:\t$BLOCKED_SPAM";
	
	$md=array(
		"IP"=>$servername,
		"MATCHES"=>$matches,
		"EVENTS"=>$text,
		"DATE"=>date("Y-m-d H:i:s")
	);
	
	$serialize=serialize($md);
	$md5=md5($serialize);
	@mkdir("/var/log/artica-postfix/smtp-hack",0666,true);
	@file_put_contents("/var/log/artica-postfix/smtp-hack/$md5.hack",$serialize);
	events("SMTP Hack: $servername matches $matches $text");
	if(!$GLOBALS["SMTP_HACKS_NOTIFIED"][$servername]){
		$GLOBALS["SMTP_HACKS_NOTIFIED"][$servername]=true;
		email_events("[SMTP HACK]: $servername match rules",$text,'postfix');
	}
}

 
?>
