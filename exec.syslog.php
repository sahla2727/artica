<?php
include_once(dirname(__FILE__).'/ressources/class.templates.inc');
include_once(dirname(__FILE__).'/ressources/class.ini.inc');
include_once(dirname(__FILE__).'/ressources/class.os.system.inc');
include_once(dirname(__FILE__).'/framework/frame.class.inc');

if(posix_getuid()<>0){die("Cannot be used in web server mode\n\n");}
if(!Build_pid_func(__FILE__,"MAIN")){
	events(basename(__FILE__)." Already executed.. aborting the process");
	die();
}

$pid=getmypid();
$pidfile="/etc/artica-postfix/".basename(__FILE__).".pid";
@mkdir("/var/log/artica-postfix/xapian",0755,true);
@mkdir("/var/log/artica-postfix/infected-queue",0755,true);
events("running $pid ");
file_put_contents($pidfile,$pid);
include_once(dirname(__FILE__).'/ressources/class.ini.inc');
include_once(dirname(__FILE__).'/ressources/class.users.menus.inc');

$GLOBALS["RSYNC_RECEIVE"]=array();
$GLOBALS["LOCATE_PHP5_BIN"]=LOCATE_PHP5_BIN();

$users=new usersMenus();
$_GET["server"]=$users->hostname;
$pipe = fopen("php://stdin", "r");
while(!feof($pipe)){
$buffer .= fgets($pipe, 4096);
try{ Parseline($buffer);}catch (Exception $e) {events("fatal error:".  $e->getMessage());}

$buffer=null;
}
fclose($pipe);
events("Shutdown...");
die();
function Parseline($buffer){
$buffer=trim($buffer);	



if(preg_match("#artica-filter#",$buffer)){return true;}
if(preg_match("#postfix\/#",$buffer)){return true;}
if(preg_match("#CRON\[#",$buffer)){return true;}
if(preg_match("#: CACHEMGR:#",$buffer)){return true;}
if(preg_match("#exec\.postfix-logger\.php:#",$buffer)){return true;}
if(preg_match("#artica-install\[#",$buffer)){return true;}
if(preg_match("#monitor action done#",$buffer)){return true;}
if(preg_match("#monitor service.+?on user request#",$buffer)){return true;}
if(preg_match("#CRON\[.+?\(root\).+CMD#",$buffer)){return true;}


if(preg_match("#smbd_audit:\s+(.+?)\|(.+?)\|(.+?)\|(.+?)\|(.+?)\|(.+?)\|(.+?)\|(.+?)$#",$buffer,$re)){
	events("{$re[5]}/{$re[8]} in xapian queue");
	WriteXapian("{$re[5]}/{$re[8]}"); 
	return true;
}	

if(preg_match("#dansguardian.+?:\s+Error connecting to proxy#",$buffer,$re)){
		$file="/etc/artica-postfix/croned.1/squid.tostart.error";
		if(IfFileTime($file,2)){
			events("Squid not available...! Artica will start squid");
			email_events("Proxy error","DansGuardian claim \"$buffer\", Artica will start squid ",'system');
			THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart squid-cache');
			THREAD_COMMAND_SET('/etc/init.d/artica-postfix start dansguardian');
			WriteFileCache($file);
			return;
		}else{
			events("Proxy error, but take action after 10mn");
			return;
		}		
}


// -------------------------------------------------------------------- MONIT


if(preg_match("#'(.+?)'\s+total mem amount of\s+([0-9]+).+?matches resource limit#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/mem.{$re[1]}.monit";
	if(IfFileTime($file,5)){
				events("{$re[1]} limit memory exceed");
				email_events("{$re[1]}: memory limit","Monitor claim \"$buffer\"",'system');
				WriteFileCache($file);
				return;
			}else{
				events("{$re[1]} limit memory exceed, but take action after 10mn");
				return;
			}			
	}
if(preg_match("#monit\[.+?'(.+?)'\s+trying to restart#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/restart.{$re[1]}.monit";
	if(IfFileTime($file,5)){
				events("{$re[1]} was restarted");
				email_events("{$re[1]}: stopped, try to restart","Monitor claim \"$buffer\"",'system');
				WriteFileCache($file);
				return;
			}else{
				events("{$re[1]}: stopped, try to restart, but take action after 10mn");
				return;
			}			
	}

if(preg_match("#monit\[.+?'(.+?)'\s+process is not running#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/restart.{$re[1]}.monit";
	if(IfFileTime($file,5)){
				events("{$re[1]} was stopped");
				email_events("{$re[1]}: stopped","Monitor claim \"$buffer\"",'system');
				WriteFileCache($file);
				return;
			}else{
				events("{$re[1]}: stopped, but take action after 10mn");
				return;
			}			
	}
	
if(preg_match("#cpu system usage of ([0-9\.]+)% matches#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/cpu.system.monit";
	if(IfFileTime($file,5)){
				events("cpu exceed");
				email_events("cpu warning {$re[1]}%","Monitor claim \"$buffer\"",'system');
				WriteFileCache($file);
				return;
			}else{
				events("cpu exceed, but take action after 10mn");
				return;
			}			
	}

if(preg_match("#monit.+?'(.+)'\s+start:#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/monit.start.{$re[1]}";
	if(IfFileTime($file,5)){
				events("{$re[1]} start");
				email_events("{$re[1]} starting","Monitor currently starting service {$re[1]}",'system');
				WriteFileCache($file);
				return;
			}else{
				events("{$re[1]} start, but take action after 10mn");
				return;
			}			
	}		

if(preg_match("#monit\[.+?:\s+'(.+?)'\s+process is running with pid\s+([0-9]+)#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/monit.run.{$re[1]}";
	if(IfFileTime($file,5)){
				events("{$re[1]} running");
				email_events("{$re[1]} now running pid {$re[2]}","Monitor report $buffer",'system');
				WriteFileCache($file);
				return;
			}else{
				events("{$re[1]} running, but take action after 10mn");
				return;
			}			
	}		
	
if(preg_match("#nmbd.+?:\s+Cannot sync browser lists#",$buffer,$re)){
		$file="/etc/artica-postfix/croned.1/samba.CannotSyncBrowserLists.error";
		if(IfFileTime($file)){
			events("Samba cannot sync browser list, remove /var/lib/samba/wins.dat");
			@unlink("/var/lib/samba/wins.dat");
			WriteFileCache($file);
		}else{
			events("Samba error:$buffer, but take action after 10mn");
			return;
		}		
}

if(preg_match("#freshclam.+?:\s+Database updated \(([0-9]+)\s+signatures\) from .+?#",$buffer,$re)){
			email_events("ClamAV Database Updated {$re[1]} signatures","$buffer",'update');
			return;
		}
		
if(preg_match("#squid.+?:\s+essential ICAP service is down after an options fetch failure:\s+icap:\/\/:1344\/av\/respmod#",$buffer,$re)){
		$file="/etc/artica-postfix/croned.1/squid.icap1.error";
		if(IfFileTime($file)){
			email_events("Kaspersky for Squid Down","$buffer",'system');
			THREAD_COMMAND_SET('/etc/init.d/artica-postfix start kav4proxy');
			THREAD_COMMAND_SET('squid -k reconfigure');
			WriteFileCache($file);
			return;
		}else{
			events("KAV4PROXY error:$buffer, but take action after 10mn");
			return;
		}			
}

if(preg_match("#KASERROR.+?NOLOGID.+?Can.+?find user mailflt3#",$buffer)){
	$file="/etc/artica-postfix/croned.1/KASERROR.NOLOGID.mailflt3";
		if(IfFileTime($file)){
			THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --mailflt3');
			WriteFileCache($file);
			return;
		}else{
			events("KASERROR error:$buffer, but take action after 10mn");
			return;
		}		
}

if(preg_match("#lmtp.+?status=deferred.+?lmtp\]:.+?(No such file or directory|Too many levels of symbolic links)#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/cyrus.lmtp.failed";
		if(IfFileTime($file)){
			email_events("cyrus-imapd socket error","Postfix claim \"$buffer\", Artica will restart cyrus",'system');
			THREAD_COMMAND_SET('/usr/share/artica-postfix/bin/artica-install --cyrus-checkconfig');
			THREAD_COMMAND_SET('/etc/init.d/artica-postfix restart imap');
			THREAD_COMMAND_SET("{$GLOBALS["LOCATE_PHP5_BIN"]} /usr/share/artica-postfix/exec.postfix.main.cf.php --imap-sockets");
			cyrus_socket_error($buffer,$re[1]."lmtp");
			WriteFileCache($file);
			return;
		}else{
			events("CYRUS error:$buffer, but take action after 10mn");
			return;
		}		
}


if(preg_match("#dhcpd: DHCPREQUEST for (.+?)\s+from\s+(.+?)\s+\((.+?)\)\s+via#",$buffer,$re)){
	events("DHCPD: IP:{$re[1]} MAC:({$re[2]}) computer name={$re[3]}-> exec.dhcpd-leases.php");
	THREAD_COMMAND_SET("{$GLOBALS["LOCATE_PHP5_BIN"]} /usr/share/artica-postfix/exec.dhcpd-leases.php --single-computer {$re[1]} {$re[2]} {$re[3]}");
	return;
}


if(preg_match("#rsyncd\[.+?:\s+recv.+?\[(.+?)\].+?([0-9]+)$#",$buffer,$re)){
	$file=md5($buffer);
	@mkdir('/var/log/artica-postfix/rsync',null,true);
	$f["IP"]=$re[1];
	$f["DATE"]=date('Y-m-d H:00:00');
	$f["SIZE"]=$re[2];
	@file_put_contents("/var/log/artica-postfix/rsync/$file",serialize($f));
}






if(preg_match("#kavmilter.+?Can.+?t load keys: No active key#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/kavmilter.key.failed";
		if(IfFileTime($file)){
			email_events("Kaspersky Antivirus Mail license error","KavMilter claim \"$buffer\"",'system');
			WriteFileCache($file);
			return;
		}else{
			events("Kaspersky Antivirus Mail license error:$buffer, but take action after 10mn");
			return;
		}		
}

if(preg_match("#kavmd.+?Can.+?t load keys:.+?#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/kavmd.key.failed";
		if(IfFileTime($file)){
			email_events("Kaspersky Antivirus Mail license error","Kaspersky Antivirus Mail claim \"$buffer\"",'system');
			WriteFileCache($file);
			return;
		}else{
			events("Kaspersky Antivirus Mail license error:$buffer, but take action after 10mn");
			return;
		}		
}

if(preg_match("#kavmd.+?ERROR Engine problem#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/kavmd.engine.failed";
		if(IfFileTime($file)){
			email_events("Kaspersky Antivirus Mail Engine error","Kaspersky Antivirus Mail claim \"$buffer\"",'system');
			WriteFileCache($file);
			return;
		}else{
			events("Kaspersky Antivirus Mail Engine error:$buffer, but take action after 10mn");
			return;
		}		
}



if(preg_match("#kavmilter.+?WARNING.+?Your AV signatures are older than#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/kavmilter.upd.failed";
		if(IfFileTime($file)){
			email_events("Kaspersky Antivirus Mail AV signatures are older","KavMilter claim \"$buffer\"",'system');
			WriteFileCache($file);
			return;
		}else{
			events("Kaspersky Antivirus update license error:$buffer, but take action after 10mn");
			return;
		}		
}
if(preg_match("#dansguardian.+?Error compiling regexp#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/dansguardian.compiling.regexp";
		if(IfFileTime($file)){
			email_events("Dansguardian failed to start","Dansguardian claim \"$buffer\"",'system');
			WriteFileCache($file);
			return;
		}else{
			events("Dansguardian failed to start:$buffer, but take action after 10mn");
			return;
		}		
}

if(preg_match("#kavmilter.+?Invalid value specified for SendmailPath#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/kavmilter.SendmailPath.Invalid";
		if(IfFileTime($file)){
			events("Check SendmailPath for kavmilter");
			THREAD_COMMAND_SET("{$GLOBALS["LOCATE_PHP5_BIN"]} /usr/share/artica-postfix/exec.kavmilter.php --SendmailPath");
			WriteFileCache($file);
			return;
		}else{
			events("Check SendmailPath for kavmilter:$buffer, but take action after 10mn");
			return;
		}		
}

if(preg_match("#KAVMilter Error.+?Group.+?Default.+?has error#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/kavmilter.Default.error";
		if(IfFileTime($file)){
			events("Check Group default for kavmilter");
			THREAD_COMMAND_SET("{$GLOBALS["LOCATE_PHP5_BIN"]} /usr/share/artica-postfix/exec.kavmilter.php --default-group");
			WriteFileCache($file);
			return;
		}else{
			events("Check Group default for kavmilter:$buffer, but take action after 10mn");
			return;
		}		
}

if(preg_match("#kavmilter.+?Message INFECTED from (.+?)\(remote:\[(.+?)\).+?with\s+(.+?)$#",$buffer,$re)){
	events("KAVMILTER INFECTION <{$re[1]}> {$re[2]}");
	infected_queue("kavmilter",trim($re[1]),trim($re[2]),trim($re[3]));
	return;
}


if(preg_match("#pdns\[.+?\[LdapBackend.+?Ldap connection to server failed#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/pdns.ldap.error";
	if(IfFileTime($file)){
			events("PDNS LDAP FAILED");
			email_events("PowerDNS ldap connection failed","PowerDNS claim \"$buffer\"",'system');
			WriteFileCache($file);
			return;
		}else{
			events("PDNS FAILED:$buffer, but take action after 10mn");
			return;
		}		
}





if(preg_match("#master.+?cannot find executable for service.+?sieve#",$buffer,$re)){
	$file="/etc/artica-postfix/croned.1/cyrus.sieve.error";
		if(IfFileTime($file)){
			events("Check sieve path");
			THREAD_COMMAND_SET("/usr/share/artica-postfix/bin/artica-install --reconfigure-cyrus");
			WriteFileCache($file);
			return;
		}else{
			events("Check sieve path error :$buffer, but take action after 10mn");
			return;
		}		
}
	
events("Not Filtered:\"$buffer\"");		
}




function IfFileTime($file,$min=10){
	if(file_time_min($file)>$min){return true;}
	return false;
}

function WriteFileCache($file){
	@unlink("$file");
	@unlink($file);
	@file_put_contents($file,"#");	
}




function events($text){
		$pid=@getmypid();
		$date=@date("H:i:s");
		$logFile="/var/log/artica-postfix/syslogger.debug";
		$size=@filesize($logFile);
		if($size>1000000){@unlink($logFile);}
		$f = @fopen($logFile, 'a');
		@fwrite($f, "[$pid] $date $text\n");
		@fclose($f);	
		}
		
function WriteXapian($path){
	$md=md5($path);
	$f="/var/log/artica-postfix/xapian/$md.queue";
	if(is_file($f)){return null;}
	@file_put_contents($f,$path);
	
}
function email_events($subject,$text,$context){
	events("DETECTED: $subject: $text -> $context");
	send_email_events($subject,$text,$context);
	}

?>