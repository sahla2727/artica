unit cyrus;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,openldap,lighttpd,zarafa_server;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  Tcyrus=class


private
     LOGS:Tlogs;
     SYS:Tsystem;
     myldap:topenldap;
    CyrusEnableBackendMurder:integer;
    CyrusEnableImapMurderedFrontEnd:integer;
    EnableCyrusMasterCluster:integer;
    CyrusClusterID:integer;
    CyrusEnableiPurge:integer;
    EnableCyrusReplicaCluster:integer;
    CyrusEnableLMTPUnix:integer;
    CyrusLMTPListen:string;

     artica_path:string;
     function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
     function LINUX_GET_HOSTNAME:string;
     function ReadFileIntoString(path:string):string;
     function sudo_tool_path():string;
     procedure CreateCyrAdm();
     function SASLAUTHD_PID():string;
     function IMAPD_GET_ARTICA(key:string):string;
     function TestingMailBox_saslauthd_infos():string;
    function TestingMailBox_imapdconf():string;

    function MURDER_MAILBOX_EXISTS(user:string):string;
    function MURDER_SEND_COMMAND(uid:string;command:string):string;
    function CHECK_CYRADM_FAILURE(filetemp:string):integer;
    function CLUSTER_SEND_MASTER(command:string;value:string):string;
    function CYRUS_SYNC_CLIENT_PID():string;
    function sieved_path():string;
    function notify_path():string;
public
    ldapserver:LDAP;
    EnableVirtualDomainsInMailBoxes:integer;
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    function    IMAPD_GET(key:string):string;
    procedure   IMAPD_WRITE(key:string;value:string);
    function    IMAPD_BIN_PATH():string;
    procedure   ETC_DEFAULT_SASLAUTHD();
    procedure   CYRUS_ETC_DEFAULT_CYRUS22();
    function    CYRUS_IMAPD_BIN_PATH():string;
    function    CYRUS_DELIVER_BIN_PATH():string;
    function    CYRUS_DAEMON_BIN_PATH():string;
    function    CYRUS_PROXYD_BIN_PATH():string;
    function    CYRUS_SYNC_CLIENT_BIN_PATH():string;
    function    CYRUS_SYNC_SERVER_BIN_PATH():string;
    function    CYRUS_POP3D_BIN_PATH():string;
    function    CYRUS_GET_INITD_PATH:string;
    function    CYRUS_LMTPD_BIN_PATH():string;
    function    CYRUS_VERSION():string;
    function    CYRADM_PATH():string;
    function    CYRUS_PID_PATH():string;
    FUNCTION    CYRUS_STATUS():string;
    function    CYRUS_PID():string;
    procedure   CYRUS_DAEMON_START();
    procedure   CYRUS_DAEMON_RELOAD();
    procedure   WRITE_CYRUS_CONF();
    procedure   WRITE_IMAPD_CONF();
    procedure   CYRUS_DAEMON_STOP();
    function    cyrquota():string;
    function    cyr_expire_path():string;
    function    SASLAUTHD_PATH():string;
    function    SASLAUTHD_CONF_PATH():string;
    procedure   SASLAUTHD_CONFIGURE();
    function    SASLAUTHD_INITD_PATH():string;
    function    SASLAUTHD_GET(key:string):string;
    function    UserInfos(uid:string):string;
    procedure   CYRUS_CERTIFICATE();
    procedure   Cyrus_set_sasl_pwcheck_method(val:string);
    function    Cyrus_get_sasl_pwcheck_method:string;
    function    POSTFIX_QUEUE_DIRECTORY():string;
    function    Cyrus_get_lmtpsocket:string;
    function    ctl_cyrusdb_path():string;
    function    ctl_deliver_path():string;
    function    tls_prune_path():string;
    procedure   Cyrus_set_value(info:string;val:string);
    function    LIST_MAILBOXES():TStringList;
    function    LIST_MAILBOXES_DOMAIN(domain:string):TStringList;

    procedure   DELETE_MAILBOXE(user:string);
    function    MAILBOX_EXISTS(user:string):boolean;
    function    MAILBOX_QUOTA(user:string):string;
    function    MAILBOX_EXISTS_CGI(uid:string):string;
    function    CREATE_USER(uid:string):string;

    function    LMTPD_PATH():string;
    function    MON():string;
    function    REPAIR_CYRUS():string;
    procedure   REPAIR_CYRUS_SEEN_FILE(path:string);
    function    reconstruct_path():string;
    procedure   CLEAN();
    procedure   CheckRightsAndConfig();
    function    TestingMailBox(username:string;password:string):string;
    procedure   MASTER_RECOVER();
    procedure   RECOVER_CYRUS_DB_SINGLE();


    //murder
    function    MURDER_TEST_BACKEND():string;
    function    MURDER_SEND_BACKEND():string;
    function    MURDER_CHANGE_LDAP():string;
    function    MURDER_SEND_CREATE_MBX(user:string):string;
    function    MURDER_SEND_USERINFOS(uid:string):string;

    function    CLUSTER_NOTIFY_REPLICA():string;
    function    CLUSTER_NOTIFY_ISREPLICA():string;
    function    CLUSTER_SEND_COMMAND(command:string):string;
    procedure   CLUSTER_SEND_LDAP_DATABASE();
    function    CLUSTER_DISABLE_MASTER():string;
    procedure   ANTIVIRUS_SCAN();



END;

implementation
//##############################################################################
constructor Tcyrus.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       SYS:=zSys;
       LOGS:=tlogs.Create();
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;

       myldap:=topenldap.Create;
       ldapserver.admin:=myldap.ldap_settings.admin;
       ldapserver.password:=myldap.ldap_settings.password;
       ldapserver.servername:=myldap.ldap_settings.servername;
       ldapserver.Port:=myldap.ldap_settings.Port;
       ldapserver.suffix:=myldap.ldap_settings.suffix;

       if length(ldapserver.Port)=0 then ldapserver.Port:='389';
       if length(ldapserver.servername)<2 then ldapserver.servername:='127.0.0.1';

       if not TryStrToInt(SYS.GET_INFO('EnableVirtualDomainsInMailBoxes'),EnableVirtualDomainsInMailBoxes) then EnableVirtualDomainsInMailBoxes:=0;
       if not TryStrToInt(SYS.GET_INFO('CyrusEnableBackendMurder'),CyrusEnableBackendMurder) then CyrusEnableBackendMurder:=0;
       if not tryStrToint(SYS.GET_INFO('CyrusEnableImapMurderedFrontEnd'),CyrusEnableImapMurderedFrontEnd) then CyrusEnableImapMurderedFrontEnd:=0;
       if not tryStrToint(SYS.GET_INFO('CyrusClusterID'),CyrusClusterID) then CyrusClusterID:=0;
       if not tryStrToint(SYS.GET_INFO('EnableCyrusReplicaCluster'),EnableCyrusReplicaCluster) then EnableCyrusReplicaCluster:=0;
       if not tryStrToint(SYS.GET_INFO('CyrusEnableiPurge'),CyrusEnableiPurge) then CyrusEnableiPurge:=0;
       if not tryStrToint(SYS.GET_INFO('CyrusEnableLMTPUnix'),CyrusEnableLMTPUnix) then CyrusEnableLMTPUnix:=1;

       CyrusLMTPListen:=SYS.GET_INFO('CyrusLMTPListen');

       if CyrusEnableImapMurderedFrontEnd=1 then begin
          if EnableCyrusReplicaCluster=1 then begin
             logs.Syslogs('Tcyrus.Create():: Incompatible parameters This server is a murder frontend and a replica cluster, unload cluster');
             EnableCyrusReplicaCluster:=0;
          end;

          if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer') then begin
             logs.Syslogs('Tcyrus.Create():: something wrong ?? CyrusEnableImapMurderedFrontEnd is active but no ..settings/Daemons/CyrusMurderBackendServer file ??');
             CyrusEnableImapMurderedFrontEnd:=0;
          end;

       end;







       if not tryStrToint(SYS.GET_INFO('EnableCyrusMasterCluster'),EnableCyrusMasterCluster) then EnableCyrusMasterCluster:=0;
       if EnableCyrusMasterCluster=1 then begin
          if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusClusterReplicaInfos') then begin
             logs.Syslogs('Tcyrus.Create():: something wrong ?? CyrusEnableImapMurderedFrontEnd is active but no ..settings/Daemons/CyrusClusterReplicaInfos file ??');
             EnableCyrusMasterCluster:=0;
          end;
       end;








end;
//##############################################################################
procedure Tcyrus.free();
begin
//    logs.Free;
end;
//##############################################################################
function Tcyrus.POSTFIX_QUEUE_DIRECTORY():string;
var
    ver:string;
    tmp:string;
begin
   if not FileExists('/usr/sbin/postconf') then exit;
   tmp:=logs.FILE_TEMP();
   fpsystem('/usr/sbin/postconf -h queue_directory >'+tmp+' 2>&1');
   if not FileExists(tmp) then exit;
   ver:=logs.ReadFromFile(tmp);
   logs.DeleteFile(tmp);
   exit(trim(ver));

end;
//#############################################################################


function Tcyrus.CYRUS_PID_PATH():string;
var  path:string;
begin
   if FileExists('/var/run/cyrus-master.pid') then path:='/var/run/cyrus-master.pid';
   if FileExists('/var/run/cyrmaster.pid') then path:='/var/run/cyrmaster.pid';
   if FileExists('/var/run/cyrus.pid') then path:='/var/run/cyrus.pid';
   result:=path;
end;
//##############################################################################
function Tcyrus.CYRUS_IMAPD_BIN_PATH():string;
begin
    if FileExists('/usr/lib/cyrus/bin/imapd') then exit('/usr/lib/cyrus/bin/imapd');
    if FileExists('/opt/artica/cyrus/bin/imapd') then exit('/opt/artica/cyrus/bin/imapd');
    if FIleExists('/usr/lib/cyrus-imapd/imapd') then exit('/usr/lib/cyrus-imapd/imapd');

end;
//#############################################################################
function Tcyrus.CYRUS_DELIVER_BIN_PATH():string;
begin

    if FileExists('/usr/lib/cyrus/bin/deliver') then exit('/usr/lib/cyrus/bin/deliver');
    if FileExists('/usr/sbin/cyrdeliver') then exit('/usr/sbin/cyrdeliver');
    if FileExists('/opt/artica/cyrus/bin/deliver') then exit('/opt/artica/cyrus/bin/deliver');
    if FIleExists('/usr/lib/cyrus-imapd/deliver') then exit('/usr/lib/cyrus-imapd/deliver');
end;
//#############################################################################
function Tcyrus.CYRUS_POP3D_BIN_PATH():string;
begin

    if FileExists('/usr/lib/cyrus/bin/pop3d') then exit('/usr/lib/cyrus/bin/pop3d');
    if FileExists('/usr/sbin/pop3d') then exit('/usr/sbin/pop3d');
    if FileExists('/opt/artica/cyrus/bin/pop3d') then exit('/opt/artica/cyrus/bin/pop3d');
    if FIleExists('/usr/lib/cyrus-imapd/pop3d') then exit('/usr/lib/cyrus-imapd/pop3d');
end;
//#############################################################################
function Tcyrus.CYRUS_LMTPD_BIN_PATH():string;
begin

    if FileExists('/usr/lib/cyrus/bin/lmtpd') then exit('/usr/lib/cyrus/bin/lmtpd');
    if FileExists('/usr/sbin/lmtpd') then exit('/usr/sbin/lmtpd');
    if FileExists('/opt/artica/cyrus/bin/lmtpd') then exit('/opt/artica/cyrus/bin/lmtpd');
    if FIleExists('/usr/lib/cyrus-imapd/lmtpd') then exit('/usr/lib/cyrus-imapd/lmtpd');
end;
//#############################################################################
function Tcyrus.ctl_deliver_path():string;
begin
    if FileExists('/usr/lib/cyrus-imapd/ctl_deliver') then exit('/usr/lib/cyrus-imapd/ctl_deliver');
    if FileExists('/usr/lib/cyrus/bin/ctl_deliver') then exit('/usr/lib/cyrus/bin/ctl_deliver');
    if FileExists('/usr/sbin/ctl_deliver') then exit('/usr/sbin/ctl_deliver');

end;
//#############################################################################
function Tcyrus.ctl_cyrusdb_path():string;
begin
    if FileExists('/usr/lib/cyrus-imapd/ctl_cyrusdb') then exit('/usr/lib/cyrus-imapd/ctl_cyrusdb');
    if FileExists('/usr/sbin/ctl_cyrusdb') then exit('/usr/sbin/ctl_cyrusdb');
    if FileExists('/usr/lib/cyrus/bin/ctl_cyrusdb') then exit('/usr/lib/cyrus/bin/ctl_cyrusdb');
    if FileExists('/usr/lib/cyrus/ctl_cyrusdb') then exit('/usr/lib/cyrus/ctl_cyrusdb');
end;
//#############################################################################
function Tcyrus.sieved_path():string;
begin
    if FileExists('/usr/lib/cyrus-imapd/sieved') then exit('/usr/lib/cyrus-imapd/ctl_cyrusdb');
    if FileExists('/usr/sbin/sieved') then exit('/usr/sbin/sieved');
    if FileExists('/usr/lib/cyrus/bin/timsieved') then exit('/usr/lib/cyrus/bin/timsieved');
    if FileExists('/usr/lib/cyrus/bin/sieved') then exit('/usr/lib/cyrus/bin/sieved');
    if FileExists('/usr/lib/cyrus/timsieved') then exit('/usr/lib/cyrus/timsieved');
end;
//#############################################################################
function Tcyrus.reconstruct_path():string;
begin
   if FileExists('/usr/lib/cyrus-imapd/reconstruct') then exit('/usr/lib/cyrus-imapd/reconstruct');
   if FileExists('/usr/lib/cyrus/bin/reconstruct') then exit('/usr/lib/cyrus/bin/reconstruct');
   if FileExists('/usr/sbin/reconstruct') then exit('/usr/sbin/reconstruct');
   if FileExists('/usr/sbin/cyrreconstruct') then exit('/usr/sbin/cyrreconstruct');
end;
//#############################################################################
function Tcyrus.notify_path():string;
begin
   if FileExists('/usr/lib/cyrus-imapd/notifyd') then exit('/usr/lib/cyrus-imapd/notifyd');
   if FileExists('/usr/lib/cyrus/bin/notifyd') then exit('/usr/lib/cyrus/bin/notifyd');
   if FileExists('/usr/sbin/notifyd') then exit('/usr/sbin/notifyd');
   if FileExists('/usr/lib/cyrus/notifyd') then exit('/usr/lib/cyrus/notifyd');
end;
//#############################################################################



function Tcyrus.CYRUS_DAEMON_BIN_PATH():string;
begin

    if FIleExists('/usr/lib/cyrus-imapd/cyrus-master') then exit('/usr/lib/cyrus-imapd/cyrus-master');
    if FIleExists('/usr/lib/cyrus/bin/master') then exit('/usr/lib/cyrus/bin/master');
    if FileExists('/usr/sbin/cyrmaster') then exit('/usr/sbin/cyrmaster');
    if FileExists('/opt/artica/cyrus/bin/master') then exit('/opt/artica/cyrus/bin/master');
end;
//#############################################################################
function Tcyrus.CYRUS_SYNC_CLIENT_BIN_PATH():string;
begin

    if FIleExists('/usr/lib/cyrus-imapd/sync_client') then exit('/usr/lib/cyrus-imapd/sync_client');
    if FIleExists('/usr/lib/cyrus/bin/sync_client') then exit('/usr/lib/cyrus/bin/sync_client');
    if FileExists('/usr/sbin/sync_client') then exit('/usr/sbin/sync_client');

end;
//#############################################################################
function Tcyrus.CYRUS_SYNC_CLIENT_PID():string;
begin
    result:=SYS.PIDOF(CYRUS_SYNC_CLIENT_BIN_PATH());
end;
//#############################################################################
function Tcyrus.CYRUS_SYNC_SERVER_BIN_PATH():string;
begin
    if FIleExists('/usr/lib/cyrus-imapd/sync_server') then exit('/usr/lib/cyrus-imapd/sync_server');
    if FIleExists('/usr/lib/cyrus/bin/sync_server') then exit('/usr/lib/cyrus/bin/sync_server');
    if FileExists('/usr/sbin/sync_server') then exit('/usr/sbin/sync_server');
end;
//#############################################################################



function Tcyrus.CYRUS_PROXYD_BIN_PATH():string;
begin
    if FIleExists('/usr/lib/cyrus-imapd/proxyd') then exit('/usr/lib/cyrus-imapd/proxyd');
    if FIleExists('/usr/lib/cyrus/bin/proxyd') then exit('/usr/lib/cyrus/bin/proxyd');
    if FileExists('/usr/sbin/proxyd') then exit('/usr/sbin/proxyd');
    if FileExists('/opt/artica/cyrus/bin/proxyd') then exit('/opt/artica/cyrus/bin/proxyd');
end;
//#############################################################################

function Tcyrus.SASLAUTHD_CONF_PATH():string;
begin
  if FileExists('/etc/saslauthd.conf') then exit('/etc/saslauthd.conf');
  if FileExists('/opt/artica/etc/saslauthd.conf') then exit('/opt/artica/etc/saslauthd.conf');
  if FileExists('/usr/local/etc/saslauthd.conf') then exit('/usr/local/etc/saslauthd.conf');
  exit('/etc/saslauthd.conf');
end;
//##############################################################################
function Tcyrus.cyr_expire_path():string;
begin
  if FileExists('/usr/sbin/cyr_expire') then exit('/usr/sbin/cyr_expire');
  if FileExists('/usr/lib/cyrus-imapd/cyr_expire') then exit('/usr/lib/cyrus-imapd/cyr_expire');
  if FileExists('/usr/lib/cyrus/bin/cyr_expire') then exit('/usr/lib/cyrus/bin/cyr_expire');
end;
//##############################################################################
function Tcyrus.tls_prune_path():string;
begin
  if FileExists('/usr/sbin/tls_prune') then exit('/usr/sbin/tls_prune');
  if FileExists('/usr/lib/cyrus-imapd/tls_prune') then exit('/usr/lib/cyrus-imapd/tls_prune');
  if FileExists('/usr/lib/cyrus/bin/tls_prune') then exit('/usr/lib/cyrus/bin/tls_prune');
end;
//##############################################################################

function TCyrus.CYRUS_PID():string;
var
   pid:string;
begin
    pid:=SYS.GET_PID_FROM_PATH(CYRUS_PID_PATH());
    if not SYS.PROCESS_EXIST(pid) then pid:=SYS.PIDOF(CYRUS_DAEMON_BIN_PATH());
    exit(pid);
end;
//#############################################################################
function Tcyrus.CYRUS_GET_INITD_PATH:string;
begin
   if FileExists('/etc/init.d/cyrus') then result:='/etc/init.d/cyrus';
   if FileExists('/etc/init.d/cyrus-imapd') then result:='/etc/init.d/cyrus-imapd';
   if FileExists('/etc/init.d/cyrus21') then result:='/etc/init.d/cyrus21';
   if FileExists('/etc/init.d/cyrus2.2') then result:='/etc/init.d/cyrus2.2';
end;
 //#############################################################################
function Tcyrus.SASLAUTHD_PATH():string;
begin
if FileExists('/usr/sbin/saslauthd') then exit('/usr/sbin/saslauthd');
if FIleExists('/opt/artica/bin/saslauthd') then exit('/opt/artica/bin/saslauthd');
end;
 //#############################################################################
function Tcyrus.CYRADM_PATH():string;
begin
if FileExists('/usr/bin/cyradm') then exit('/usr/bin/cyradm');
if FIleExists('/usr/share/bin/cyradm') then exit('/usr/share/bin/cyradm');
if FIleExists('/opt/artica/bin/cyradm') then exit('/opt/artica/bin/cyradm');
end;
 //#############################################################################
function Tcyrus.SASLAUTHD_INITD_PATH():string;
begin
    if FileExists('/etc/init.d/saslauthd') then exit('/etc/init.d/saslauthd');
end;
 //#############################################################################
procedure TCyrus.CreateCyrAdm();
var
   DomainName:string;
begin
    Domainname:=SYS.DomainName();
    logs.Debuglogs('Starting......: domain of this server: '+ Domainname);
    logs.Debuglogs(SYS.LOCATE_PHP5_BIN()+ ' ' + artica_path+'/exec.check-cyrus-account.php cyrus >/dev/null 2>&1 &');
    fpsystem(SYS.LOCATE_PHP5_BIN()+ ' ' + artica_path+'/exec.check-cyrus-account.php cyrus & >/dev/null 2>&1 &');
end;
//##############################################################################
procedure Tcyrus.RECOVER_CYRUS_DB_SINGLE();
begin


if FileExists(SYS.LOCATE_ctl_cyrusdb()) then begin
   CYRUS_DAEMON_STOP();
   fpsystem('su - cyrus -c "'+SYS.LOCATE_ctl_cyrusdb()+' -r"');
   CYRUS_DAEMON_START();
end;

end;

//##############################################################################
procedure Tcyrus.MASTER_RECOVER();
var
   configdirectory:string;
begin

configdirectory:=IMAPD_GET('configdirectory');
writeln('Stopping cyrus');
CYRUS_DAEMON_STOP();
if not DirectoryExists(configdirectory) then begin
   writeln('Unable to stat "'+configdirectory+'"');
   exit;
end;

writeln('removing backup databases '+configdirectory+'/db/*');
fpsystem('/bin/rm '+configdirectory+'/db/*');
writeln('removing backup databases '+configdirectory+'/db.backup?/*');
fpsystem('/bin/rm '+configdirectory+'/db.backup?/*');

writeln('removing backup databases '+configdirectory+'/deliver.db');
fpsystem('/bin/rm '+configdirectory+'/deliver.db');
writeln('removing backup databases '+configdirectory+'/tls_sessions.db');
fpsystem('/bin/rm '+configdirectory+'/tls_sessions.db');
writeln('Exporting mailboxes');
fpsystem('su - cyrus -c "'+SYS.LOCATE_ctl_mboxlist()+' -d" >'+configdirectory+'/mailboxlist.txt');
fpsystem('/bin/mv '+configdirectory+'/mailboxes.db '+configdirectory+'/mailboxes.db.old');

writeln('importing mailboxes');
writeln('su - cyrus -c "'+SYS.LOCATE_ctl_mboxlist()+' -u <'+configdirectory+'/mailboxlist.txt"');
fpsystem('su - cyrus -c "'+SYS.LOCATE_ctl_mboxlist()+' -u <'+configdirectory+'/mailboxlist.txt"');
writeln('su - cyrus -c "diff '+configdirectory+'/mailboxes.db*"');
fpsystem('su - cyrus -c "diff '+configdirectory+'/mailboxes.db*"');
writeln('done...');
writeln('Starting cyrus daemon...');
CYRUS_DAEMON_START();
writeln('Recover databases');
writeln('su - cyrus -c "'+ctl_cyrusdb_path()+' -r"');
fpsystem('su - cyrus -c "'+ctl_cyrusdb_path()+' -r"');
end;

function TCyrus.CREATE_USER(uid:string):string;
var
   tmpstr:string;
   cmd:string;
begin

logs.Debuglogs('Is it a frontend ?:: "' +IntToStr(CyrusEnableImapMurderedFrontEnd)+'"');


   if CyrusEnableImapMurderedFrontEnd=1 then begin
       result:=MURDER_SEND_CREATE_MBX(uid);
       exit;
   end;

        tmpstr:=logs.FILE_TEMP();
        cmd:='/usr/share/artica-postfix/bin/artica-ldap -mailbox ' +uid+ ' >'+tmpstr+' 2>&1';
        logs.logs('CREATE_USER::  -> create mailbox ' + uid);
        logs.logs('CREATE_USER::  -> "' + cmd+'"');
        fpsystem(cmd);
        result:=logs.ReadFromFile(tmpstr);
        logs.logs(result);
        logs.DeleteFile(tmpstr);
        if FileExists('/etc/artica-postfix/cyrquota') then logs.DeleteFile('/etc/artica-postfix/cyrquota');
        exit;
end;
//##############################################################################
function TCyrus.MAILBOX_EXISTS_CGI(uid:string):string;
var
   tmpstr:string;
   cmd:string;
   openldap:topenldap;
begin


logs.Debuglogs('MAILBOX_EXISTS_CGI:: Is it a frontend ?:: "' +IntToStr(CyrusEnableImapMurderedFrontEnd)+'"');


   if CyrusEnableImapMurderedFrontEnd=1 then begin
       result:=MURDER_MAILBOX_EXISTS(uid);
       exit;
   end;

       openldap:=Topenldap.Create;
       tmpstr:=logs.FILE_TEMP();
       cmd:='/usr/share/artica-postfix/bin/cyrus-admin.pl -u cyrus -p ' + openldap.get_LDAP('cyrus_password') + ' -m ' +uid+' --exists >'+tmpstr+' 2>&1';
       logs.logs('MAILBOX_EXISTS_CGI::  -> "' + cmd+'"');
       fpsystem(cmd);
       logs.Debuglogs('MailboxExists report="'+logs.ReadFromFile(tmpstr)+'"');
       if CHECK_CYRADM_FAILURE(tmpstr)=1 then begin
          logs.Debuglogs('MAILBOX_EXISTS_CGI change to cyrus password');
          cmd:='/usr/share/artica-postfix/bin/cyrus-admin.pl -u cyrus -p secret -m ' +uid+' --exists >'+tmpstr+' 2>&1';
          fpsystem(cmd);
          if CHECK_CYRADM_FAILURE(tmpstr)=0 then begin
              logs.Debuglogs('MAILBOX_EXISTS_CGI:: Success save cyrus password');
              openldap.set_LDAP('cyrus_password','secret');
          end;
       end;

       result:=(logs.ReadFromFile(tmpstr));
       logs.DeleteFile(tmpstr);

end;
//##############################################################################
procedure TCyrus.ANTIVIRUS_SCAN();
var
   inif:TiniFile;
   nice:string;
   time:string;
   config_directory:string;
   cmd:string;
begin
   if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusAVConfig') then begin
      logs.Debuglogs('ANTIVIRUS_SCAN:: unable to stat CyrusAVConfig file');
      exit;
   end;

   inif:=TiniFile.Create('/etc/artica-postfix/settings/Daemons/CyrusAVConfig');
   nice:=inif.ReadString('SCAN','ProcessNice','-15');

   inif.free;

   if not FIleExists(SYS.LOCATE_GENERIC_BIN('clamscan')) then begin
       logs.Debuglogs('ANTIVIRUS_SCAN:: unable to stat clamscan');
       exit;
   end;

   config_directory:=IMAPD_GET('partition-default');
   logs.Debuglogs('ANTIVIRUS_SCAN:: partition-default:="'+config_directory+'"');
   if not DirectoryExists(config_directory) then begin
       logs.Debuglogs('ANTIVIRUS_SCAN:: unable to stat partition-default directory');
       exit;
   end;


   ForceDirectories('/var/log/artica-postfix/antivirus/cyrus-imap');
   time:=FormatDateTime('yyyy-mm-dd_hh-nn', Now);
   cmd:='/usr/bin/nice -n ' + nice+' ' +  '/usr/bin/clamscan --recursive=yes --infected ';
   cmd:=cmd+'--max-filesize=10M --max-scansize=10M --max-recursion=5 --max-dir-recursion=10 ';
   cmd:=cmd+'--log=/var/log/artica-postfix/antivirus/cyrus-imap/' +time+'.scan '+config_directory;
   logs.Debuglogs(cmd);
   fpsystem(cmd+' &');
end;
//##############################################################################


function TCyrus.CHECK_CYRADM_FAILURE(filetemp:string):integer;
var
   RegExpr:TRegExpr;
   l:TstringList;
   i:integer;

begin

l:=Tstringlist.Create;
result:=0;
if not FileExists(filetemp) then begin
    logs.Debuglogs('CHECK_CYRADM_FAILURE: unable to stat  "'+filetemp+'"');
    exit;
end;


l.LoadFromFile(filetemp);
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='Login failed.+?authentication failure';
for i:=0 to l.Count-1 do begin
   logs.Debuglogs('CHECK_CYRADM_FAILURE: checking "'+l.Strings[i]+'"');
   if RegExpr.Exec(l.Strings[i]) then begin
        logs.Debuglogs('CHECK_CYRADM_FAILURE: Found bad authentication in command' );
        result:=1;
        break;
   end;

end;

l.free;
RegExpr.free;

end;

//##############################################################################
function TCyrus.MURDER_MAILBOX_EXISTS(user:string):string;
begin
 result:=MURDER_SEND_COMMAND(user,'exists-mbx');
end;
//##############################################################################

procedure TCyrus.Cyrus_set_sasl_pwcheck_method(val:string);
var RegExpr:TRegExpr;
list:TstringList;
i:integer;
begin
 RegExpr:=TRegExpr.create;
    list:=TstringList.Create();
    list.LoadFromFile('/etc/imapd.conf');
    for i:=0 to list.Count-1 do begin
          RegExpr.expression:='sasl_pwcheck_method';
          if RegExpr.Exec(list.Strings[i]) then begin
               list.Strings[i]:='sasl_pwcheck_method: ' + val;
          end;

    end;
   try
      list.SaveToFile('/etc/imapd.conf');
   except
      logs.Syslogs('Starting......: cyrus-imapd Fatal error, unable to change imapd.conf..');
   end;
   list.Free;
   RegExpr.Free;
end;
 //##############################################################################
procedure TCyrus.Cyrus_set_value(info:string;val:string);
var
   RegExpr:TRegExpr;
   list:TstringList;
   i:integer;
   added:boolean;
begin
added:=false;
if not FileExists('/etc/imapd.conf') then exit;
if length(val)=0 then exit;
added:=false;
 RegExpr:=TRegExpr.create;
    list:=TstringList.Create();
    list.LoadFromFile('/etc/imapd.conf');
    for i:=0 to list.Count-1 do begin
          RegExpr.expression:=info;
          if RegExpr.Exec(list.Strings[i]) then begin
               LOGS.Debuglogs('Cyrus_set_value:: Found "' + info + '"');
               LOGS.Debuglogs('Cyrus_set_value:: Set line "' + IntTostr(i) + '" to "' + val + '"');
               list.Strings[i]:=info+ ': ' + val;
               added:=True;
          end;

    end;
    if added=False then begin
      list.Add(info+ ': ' +val);

    end;
   try
      list.SaveToFile('/etc/imapd.conf');
   except
         logs.Syslogs('Starting......: cyrus-imapd Fatal error, unable to change imapd.conf (Cyrus_set_value)..');
   end;
   list.Free;
   RegExpr.Free;
end;
 //##############################################################################
function TCyrus.Cyrus_get_sasl_pwcheck_method;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:='sasl_pwcheck_method[:\s]+([a-z]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //##############################################################################
function TCyrus.Cyrus_get_lmtpsocket;
var RegExpr:TRegExpr;
datas:string;
begin
 RegExpr:=TRegExpr.create;
 datas:=ReadFileIntoString('/etc/imapd.conf');
 RegExpr.expression:='lmtpsocket[:\s]+([a-z\/]+)';
 if RegExpr.Exec(datas) then begin
     result:=Trim(RegExpr.Match[1]);
 end;
 RegExpr.Free;
end;
 //##############################################################################
procedure TCyrus.ETC_DEFAULT_SASLAUTHD();
var
l:TstringList;
moinsr:string;
begin

if Not Fileexists('/etc/default/saslauthd') then exit;
l:=TstringList.Create;
l.Add('# Settings for saslauthd daemon');
l.Add('# Please read /usr/share/doc/sasl2-bin/README.Debian for details.');
l.Add('#');
l.Add('');
l.Add('# Should saslauthd run automatically on startup? (default: no)');
l.Add('START=yes');
l.Add('');
l.Add('# Description of this saslauthd instance. Recommended.');
l.Add('# (suggestion: SASL Authentication Daemon)');
l.Add('DESC="SASL Authentication Daemon"');
l.Add('');
l.Add('# Short name of this saslauthd instance. Strongly recommended.');
l.Add('# (suggestion: saslauthd)');
l.Add('NAME="saslauthd"');
l.Add('');
l.Add('# Which authentication mechanisms should saslauthd use? (default: pam)');
l.Add('#');
l.Add('# Available options in this Debian package:');
l.Add('# getpwent  -- use the getpwent() library function');
l.Add('# kerberos5 -- use Kerberos 5');
l.Add('# pam       -- use PAM');
l.Add('# rimap     -- use a remote IMAP server');
l.Add('# shadow    -- use the local shadow password file');
l.Add('# sasldb    -- use the local sasldb database file');
l.Add('# ldap      -- use LDAP (configuration is in /etc/saslauthd.conf)');
l.Add('#');
l.Add('# Only one option may be used at a time. See the saslauthd man page');
l.Add('# for more information.');
l.Add('#');

if SYS.GET_ENGINE('MECHANISM')='shadow' then l.Add('MECHANISMS="shadow"');
if SYS.GET_ENGINE('MECHANISM')='ldap' then l.Add('MECHANISMS="ldap"');
if EnableVirtualDomainsInMailBoxes=1 then moinsr:='-r ';

l.Add('');
l.Add('# Additional options for this mechanism. (default: none)');
l.Add('# See the saslauthd man page for information about mech-specific options.');
l.Add('MECH_OPTIONS=""');
l.Add('');
l.Add('# How many saslauthd processes should we run? (default: 5)');
l.Add('# A value of 0 will fork a new process for each connection.');
l.Add('THREADS=5');
l.Add('');
l.Add('# Other options (default: -c -m /var/run/saslauthd)');
l.Add('# Note: You MUST specify the -m option or saslauthd won''t run!');
l.Add('#');
l.Add('# See /usr/share/doc/sasl2-bin/README.Debian for Debian-specific information.');
l.Add('# See the saslauthd man page for general information about these options.');
l.Add('#');
l.Add('# Example for postfix users: "-c -m /var/spool/postfix/var/run/saslauthd"');
l.Add('OPTIONS="'+moinsr+'-c -m /var/run/saslauthd"');
l.SaveToFile('/etc/default/saslauthd');
l.free;
end;
//##############################################################################
function TCyrus.MURDER_TEST_BACKEND():string;
begin
 result:=MURDER_SEND_COMMAND('nil','test-authenticate');
end;
//##############################################################################
function TCyrus.MURDER_SEND_BACKEND():string;
var
sini:TiniFile;
cmd:string;
servername,artica_port,username,password,hostname,myport:string;
tmpstr:string;
lighttpd:tlighttpd;
begin
  if not FileExists(SYS.LOCATE_CURL()) then begin
     result:='FAILED:{ERROR_CURL_NOT_INSTALLED}';
     exit;
  end;

  if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer') then begin
     result:='FAILED:{NO_CONFIG_FILE}';
     exit;
  end;

  sini:=TiniFIle.Create('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer');
  servername:=sini.ReadString('MURDER_BACKEND','servername','');

  if length(servername)=0 then begin
     result:='FAILED: servername value is empty';
     exit;
  end;
  
  lighttpd:=tlighttpd.Create(SYS);
  myport:=lighttpd.LIGHTTPD_LISTEN_PORT();
  artica_port:=sini.ReadString('MURDER_BACKEND','artica_port','9000');
  username:=sini.ReadString('MURDER_BACKEND','username','');
  password:=sini.ReadString('MURDER_BACKEND','password','');
  hostname:=SYS.HOSTNAME_g();
   tmpstr:=logs.FILE_TEMP();
  cmd:=SYS.LOCATE_CURL()+' --connect-timeout 3 --sslv3 --insecure --get --show-error --silent --url ';
  cmd:=cmd+'"https://'+servername+':'+artica_port+'/cyrus.murder.listener.php?enable-frontend=yes&https-port='+myport+'&admin='+username+'&pass='+password+'&hostname='+hostname+'&requestedback='+servername+'"';
  cmd:=cmd+' >'+ tmpstr+' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);
  result:=logs.ReadFromFile(tmpstr);
  logs.DeleteFile(tmpstr);
end;
//##############################################################################
function TCyrus.CLUSTER_SEND_MASTER(command:string;value:string):string;
var
sini:TiniFile;
cmd:string;
servername,artica_port,username,password,hostname:string;
tmpstr:string;
begin
  if not FileExists(SYS.LOCATE_CURL()) then begin
     result:='FAILED:{ERROR_CURL_NOT_INSTALLED}';
     exit;
  end;

  if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer') then begin
     result:='FAILED:{NO_CONFIG_FILE}';
     exit;
  end;

  sini:=TiniFIle.Create('/etc/artica-postfix/settings/Daemons/CyrusReplicaLDAPConfig');
  servername:=sini.ReadString('REPLICA','servername','');

  if length(servername)=0 then begin
     result:='FAILED: servername value is empty';
     exit;
  end;

  artica_port:=sini.ReadString('REPLICA','artica_port','9000');
  username:=sini.ReadString('REPLICA','username','');
  password:=sini.ReadString('REPLICA','password','');
  hostname:=SYS.HOSTNAME_g();
   tmpstr:=logs.FILE_TEMP();
  cmd:=SYS.LOCATE_CURL()+' --connect-timeout 3 --sslv3 --insecure --get --show-error --silent --url ';
  cmd:=cmd+'"https://'+servername+':'+artica_port+'/cyrus.murder.listener.php?'+command+'='+value+'&admin='+username+'&pass='+password+'&hostname='+hostname+'&requestedback='+servername+'"';
  cmd:=cmd+' >'+ tmpstr+' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);
  result:=logs.ReadFromFile(tmpstr);
  logs.DeleteFile(tmpstr);

end;
//##############################################################################
function TCyrus.CLUSTER_DISABLE_MASTER():string;
begin
result:=CLUSTER_SEND_MASTER('disable-replica','me');
end;
//##############################################################################
function TCyrus.MURDER_SEND_CREATE_MBX(user:string):string;
begin
 result:=MURDER_SEND_COMMAND(user,'create-mbx');
end;
//##############################################################################
function Tcyrus.MURDER_CHANGE_LDAP():string;
var
sini:TiniFile;
servername,username,password,suffix:string;
begin
  if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer') then begin
     result:='FAILED:{NO_CONFIG_FILE}';
     exit;
  end;
  sini:=TiniFIle.Create('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer');
  servername:=sini.ReadString('MURDER_BACKEND','servername','');
  username:=sini.ReadString('MURDER_BACKEND','username','');
  password:=sini.ReadString('MURDER_BACKEND','password','');
  suffix:=trim(sini.ReadString('MURDER_BACKEND','suffix',''));

  if length(suffix)=0 then begin
      result:='FAILED:{corrupted} "suffix" ?';
      sini.free;
     exit;
  end;

  if length(servername)=0 then begin
      result:='FAILED:{corrupted} "servername" ?';
      sini.free;
     exit;
  end;

  if length(username)=0 then begin
      result:='FAILED:{corrupted} "username" ?';
      sini.free;
     exit;
  end;

  if length(password)=0 then begin
      result:='FAILED:{corrupted} "password" ?';
      sini.free;
     exit;
  end;

  myldap.ChangeSettings(servername,'389',username,password,suffix,'no');
  result:='SUCCESS';
  logs.Debuglogs('MURDER_CHANGE_LDAP --> '+result);
end;
//##############################################################################
procedure TCyrus.SASLAUTHD_CONFIGURE();
var
   list2:TstringList;
begin

  list2:=TstringList.Create;
  list2.Add('ldap_servers: ldap://' + ldapserver.servername + ':' + ldapserver.Port+'/');
  list2.Add('ldap_version: 3');
  list2.Add('ldap_search_base: dc=organizations,'+ ldapserver.suffix);
  list2.Add('ldap_scope: sub');
  list2.Add('ldap_filter: uid=%u');
  list2.Add('ldap_auth_method: bind');
  list2.Add('ldap_bind_dn: cn=' +ldapserver.admin+ ',' + ldapserver.suffix);
  list2.Add('ldap_password: ' + ldapserver.password);
  list2.Add('ldap_timeout: 10');
  list2.SaveToFile(SASLAUTHD_CONF_PATH());


  if FileExists(SASLAUTHD_INITD_PATH()) then begin
     list2.SaveToFile('/etc/saslauthd.conf');
     logs.Debuglogs('SASLAUTHD_CONFIGURE:: -> Saving /etc/saslauthd.conf' );
  end;
  list2.clear;

  list2.Add('pwcheck_method: saslauthd');
  list2.Add('mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5');
  list2.Add('minimum_layer: 0');
  list2.Add('log_level: 5');

  forcedirectories('/etc/postfix/sasl');
  list2.SaveToFile('/etc/postfix/sasl/smtpd.conf');

  if not FileExists('/usr/lib/sasl2/smtpd.conf') then fpsystem('/bin/ln -s /etc/postfix/sasl/smtpd.conf  /usr/lib/sasl2/smtpd.conf');

  list2.free;

end;
//##############################################################################
function Tcyrus.cyrquota():string;
var
   doit:boolean;
   cmd:string;
   filebytes:integer;
   quotapath:string;
begin


quotapath:=SYS.LOCATE_CYRQUOTA();
if not FileExists(quotapath) then begin
   logs.Syslogs('WARNING !!! cyrquota()::  unable to stat quota binary');
   exit;
end;

doit:=false;

logs.Debuglogs('Is it a frontend ?:: "' +IntToStr(CyrusEnableImapMurderedFrontEnd)+'"');


   if CyrusEnableImapMurderedFrontEnd=1 then begin
       result:=MURDER_SEND_COMMAND('','cyrquota');
       exit;
   end;


    if not FileExists(sudo_tool_path()) then begin
       logs.Debuglogs('cyrquota:unable to stat sudo tool !!!');
    end;
    if FileExists('/etc/artica-postfix/cyrquota') then begin
       if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/cyrquota')>5 then doit:=true;
    end else begin
        doit:=true;
    end;

    filebytes:=logs.GetFileBytes('/etc/artica-postfix/cyrquota');
    logs.Debuglogs('cyrquota:: Bytes: ' + IntTOStr(filebytes));
    if filebytes=0 then doit:=true;
    cmd:=sudo_tool_path() + ' -u cyrus '+quotapath+' >/etc/artica-postfix/cyrquota';

    if doit then begin
       logs.Debuglogs('cyrquota:: Execute : ' +cmd);
       fpsystem(sudo_tool_path() + ' -u cyrus '+quotapath+' >/etc/artica-postfix/cyrquota 2>&1');
    end;
    exit(ReadFileIntoString('/etc/artica-postfix/cyrquota'));
end;
//##############################################################################
procedure TCyrus.CYRUS_CERTIFICATE();
var
   openssl:string;
   cf_path:string;
   cmd,CertificateMaxDays,extensions:string;
   ini:TiniFIle;
begin

CertificateMaxDays:=SYS.GET_INFO('CertificateMaxDays');
if length(CertificateMaxDays)=0 then CertificateMaxDays:='730';
if length(SYS.OPENSSL_CERTIFCATE_HOSTS())>0 then extensions:=' -extensions HOSTS_ADDONS ';


 forcedirectories('/etc/ssl/certs');
 forcedirectories('/opt/artica/tmp');

 if ParamStr(2)='ssl' then fpsystem('/bin/rm -rf /etc/ssl/certs/cyrus.pem');

 if FileExists('/etc/ssl/certs/cyrus.pem') then begin
    logs.Debuglogs('/etc/ssl/certs/cyrus.pem OK... finish');
    exit;
 end;

  SYS.OPENSSL_CERTIFCATE_CONFIG();
  openssl:=SYS.OPENSSL_TOOL_PATH();
  cf_path:=SYS.OPENSSL_CONFIGURATION_PATH();


 if not FileExists(openssl) then begin
    logs.logs('CYRUS_CERTIFICATE():: FATAL ERROR, Unable to stat openssl ');
    exit;
 end;

 if not FileExists(CYRUS_DAEMON_BIN_PATH()) then begin
    logs.logs('CYRUS_CERTIFICATE():: cyrus-imapd is not installed...');
    exit;
 end;


 if not FileExists(cf_path) then begin
    logs.logs('CYRUS_CERTIFICATE():: FATAL ERROR, Unable to stat configuration file ');
    exit;
 end;


 ForceDirectories('/etc/ssl/certs/cyrus');
 cmd:=openssl+' genrsa -out /etc/ssl/certs/cyrus/ca.key 1024 -batch -config '+cf_path+extensions;
 logs.Debuglogs(cmd);
 if ParamStr(2)='ssl' then writeln(cmd);
  fpsystem(cmd);

 cmd:=openssl+' req -new -nodes -key /etc/ssl/certs/cyrus/ca.key -batch -config '+cf_path+extensions+' -out /opt/artica/tmp/req.pem -keyout /opt/artica/tmp/key.pem';
 logs.Debuglogs(cmd);
 if ParamStr(2)='ssl' then writeln(cmd);
 fpsystem(cmd);

 if not FileExists('/opt/artica/tmp/key.pem') then begin
    writeln('Unable to stat /opt/artica/tmp/key.pem switch mode 2');
    cmd:=openssl+' req -new -nodes -out /etc/ssl/certs/cyrus/req.pem -keyout /etc/ssl/certs/cyrus/key.pem -batch -config '+cf_path+extensions;
    if ParamStr(2)='ssl' then writeln(cmd);
    fpsystem(cmd);
     if not FileExists('/etc/ssl/certs/cyrus/key.pem') then begin
         writeln('Unable to stat /etc/ssl/certs/cyrus/key.pem exiting');
         exit;
     end;
    cmd:=openssl+' rsa -in /etc/ssl/certs/cyrus/key.pem -out /etc/ssl/certs/cyrus/new.key.pem';
    if ParamStr(2)='ssl' then writeln(cmd);
    fpsystem(cmd);
    cmd:=openssl+' x509 -in /etc/ssl/certs/cyrus/req.pem -out /opt/artica/tmp/ca-cert.pem -req -signkey /etc/ssl/certs/cyrus/new.key.pem -days 999';
    if ParamStr(2)='ssl' then writeln(cmd);
    fpsystem(cmd);
    if not FileExists('/opt/artica/tmp/ca-cert.pem') then begin
       writeln('Unable to stat /opt/artica/tmp/ca-cert.pem EXITING');
       exit;
    end;
    if FileExists('/etc/ssl/certs/cyrus/new.key.pem') then writeln('SUCCESS');
    fpsystem('/bin/cp /etc/ssl/certs/cyrus/new.key.pem /etc/ssl/certs/cyrus.pem');
    fpsystem('/bin/cat /opt/artica/tmp/ca-cert.pem >> /etc/ssl/certs/cyrus.pem');
    exit;
 end;



 cmd:=openssl+' rsa -in /opt/artica/tmp/key.pem -out /opt/artica/tmp/new.key.pem';
 logs.Debuglogs(cmd);
 if ParamStr(2)='ssl' then writeln(cmd);
 fpsystem(cmd);

 ini:=TiniFile.Create(cf_path);
 ini.WriteString('default_db','private_key','/etc/ssl/certs/cyrus/ca.key');
  ini.WriteString('default_db','certificate','/opt/artica/tmp/key.pem');
 ini.UpdateFile;

 cmd:=openssl+' x509 -extfile '+cf_path+extensions+' -in /opt/artica/tmp/req.pem -out /opt/artica/tmp/ca-cert.pem -req -signkey /opt/artica/tmp/new.key.pem -days '+CertificateMaxDays;
 //cmd:=openssl+' ca -batch -config '+cf_path+extensions+' -in /opt/artica/tmp/req.pem  -out /opt/artica/tmp/ca-cert.pem -key /etc/ssl/certs/cyrus/ca.key -days '+CertificateMaxDays;

 logs.Debuglogs(cmd);
 if ParamStr(2)='ssl' then writeln(cmd);
 fpsystem(cmd);

 cmd:='/bin/cp /opt/artica/tmp/new.key.pem /etc/ssl/certs/cyrus.pem';
 logs.Debuglogs(cmd);
 if ParamStr(2)='ssl' then writeln(cmd);
 fpsystem(cmd);


 cmd:='/bin/cat /opt/artica/tmp/ca-cert.pem >> /etc/ssl/certs/cyrus.pem';
 logs.Debuglogs(cmd);
 if ParamStr(2)='ssl' then writeln(cmd);
 fpsystem(cmd);


 cmd:='/bin/chown cyrus:mail /etc/ssl/certs/cyrus.pem';
 logs.Debuglogs(cmd);
 if ParamStr(2)='ssl' then writeln(cmd);
 fpsystem(cmd);


 cmd:='/bin/chmod 600 /etc/ssl/certs/cyrus.pem';
 logs.Debuglogs(cmd);
 if ParamStr(2)='ssl' then writeln(cmd);
 fpsystem(cmd);
end;
//#############################################################################
procedure Tcyrus.CLEAN();
var
RegExpr:TRegExpr;
l:TStringList;
i:integer;
path:string;
t:integer;
tosave:boolean;
begin
 logs.Debuglogs('Starting......: Cleaning imapd.conf');
 path:='/etc/imapd.conf';
 if not FileExists(path) then exit;
 RegExpr:=TRegExpr.Create;
 l:=TStringList.Create;
 l.LoadFromFile(path);
 t:=0;
 tosave:=false;

 For i:=0 to l.Count-1 do begin
     if t>l.Count-1 then break;
     RegExpr.Expression:='([a-z\_]+)[\s:]+(.+)';

     if length(trim(l.Strings[t]))=0 then begin
        if t>l.Count-1 then break;
        continue;
     end;


     if not RegExpr.Exec(l.Strings[t]) then begin
        logs.Debuglogs('Starting......: Cleaning line '+intToStr(t) +'/' + IntToStr(l.Count-1) +' ' + IntToStr(length(trim(l.Strings[t])))+ ' length "' + l.Strings[t]+'"');
        l.Delete(t);
        tosave:=true;
        continue;
     end;



 t:=t+1;
 if t>l.Count-1 then break;
 end;

logs.Debuglogs('Starting......: Cleaning imapd.conf done...');
if tosave then begin
 try
    l.SaveToFile(path);
 except
   logs.Syslogs('TClamav.FRESHCLAM_CLEAN():: FATAL ERROR WHILE SAVING '+path);
   exit;
 end;
end;
end;
//##############################################################################


function Tcyrus.IMAPD_BIN_PATH():string;
begin

    if FileExists('/usr/lib/cyrus/bin/imapd') then exit('/usr/lib/cyrus/bin/imapd');
    if FileExists('/opt/artica/cyrus/bin/imapd') then exit('/opt/artica/cyrus/bin/imapd');
end;
//#############################################################################
function Tcyrus.sudo_tool_path():string;
begin
  if FileExists('/usr/bin/sudo') then exit('/usr/bin/sudo');
end;
//#############################################################################

function Tcyrus.UserInfos(uid:string):string;
var
   partition_default:string;
   path         :string;
   RegExpr      :TRegExpr;
   Firstletter  :string;
   FirstDomainLetter:string;
   domain:string;
   username     :string;
   tmpstr:string;
begin

///!!!!


logs.Debuglogs('Is it a frontend ?:: "' +IntToStr(CyrusEnableImapMurderedFrontEnd)+'"');


   if CyrusEnableImapMurderedFrontEnd=1 then begin
       result:=MURDER_SEND_USERINFOS(uid);
       exit;
   end;

   RegExpr:=TRegExpr.Create;
    partition_default:=IMAPD_GET('partition-default');


   RegExpr.Expression:='(.+?)@(.+)';
   if  RegExpr.Exec(uid) then begin
        username:=AnsiReplaceText(RegExpr.Match[1],'.','^');
        domain:=RegExpr.Match[2];
        FirstDomainLetter:=domain[1];
        Firstletter:=username[1];
        path:=partition_default + '/domain/'+FirstDomainLetter+'/'+domain+ '/'+Firstletter+'/user/' + username;
   end else begin
        username:=AnsiReplaceText(uid,'.','^');
        Firstletter:=uid[1];
        path:=partition_default + '/'+Firstletter+'/user/' + username;
   end;

   tmpstr:=logs.FILE_TEMP();
   logs.Debuglogs('UserInfos:: Partition is "' +path+'"');
   fpsystem(SYS.EXEC_NICE()+SYS.DU_PATH() + ' -s ' + path + ' >'+tmpstr+' 2>&1');
   result:=ReadFileIntoString(tmpstr);
   logs.DeleteFile(tmpstr);
   logs.Debuglogs('UserInfos::' + result);

end;
//#############################################################################
function TCyrus.MURDER_SEND_USERINFOS(uid:string):string;
begin
 result:=MURDER_SEND_COMMAND(uid,'user-infos');
end;
//##############################################################################
function TCyrus.MURDER_SEND_COMMAND(uid:string;command:string):string;
var
sini:TiniFile;
cmd:string;
servername,artica_port,username,password,hostname:string;
tmpstr:string;
begin
  if not FileExists(SYS.LOCATE_CURL()) then begin
     result:='FAILED:{ERROR_CURL_NOT_INSTALLED}';
     exit;
  end;

  if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer') then begin
     result:='FAILED:{NO_CONFIG_FILE}';
     exit;
  end;

  sini:=TiniFIle.Create('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer');
  servername:=sini.ReadString('MURDER_BACKEND','servername','');

  if length(servername)=0 then begin
     result:='FAILED: servername value is empty';
     exit;
  end;


  artica_port:=sini.ReadString('MURDER_BACKEND','artica_port','9000');
  username:=sini.ReadString('MURDER_BACKEND','username','');
  password:=sini.ReadString('MURDER_BACKEND','password','');
  hostname:=SYS.HOSTNAME_g();
   tmpstr:=logs.FILE_TEMP();
  cmd:=SYS.LOCATE_CURL()+' --connect-timeout 3 --sslv3 --insecure --get --show-error --silent --url ';
  cmd:=cmd+'"https://'+servername+':'+artica_port+'/cyrus.murder.listener.php?'+command+'=yes&admin='+username+'&pass='+password+'&hostname='+hostname+'&requestedback='+servername+'&mbx='+uid+'"';
  cmd:=cmd+' >'+ tmpstr+' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);
  result:=logs.ReadFromFile(tmpstr);
  logs.DeleteFile(tmpstr);
end;
//##############################################################################
function TCyrus.CLUSTER_NOTIFY_REPLICA():string;
var
cmd:string;
begin
      cmd:='cluster-master-enable=yes&ldap_admin='+ldapserver.admin+'&ldap_password='+ldapserver.password;
      cmd:=cmd+'&suffix='+ldapserver.suffix;
      result:=CLUSTER_SEND_COMMAND(cmd);
end;
//##############################################################################
function TCyrus.CLUSTER_NOTIFY_ISREPLICA():string;
var
cmd:string;
begin
      cmd:='CheckifReplica=yes';
      result:=CLUSTER_SEND_COMMAND(cmd);
end;
//##############################################################################
function TCyrus.CLUSTER_SEND_COMMAND(command:string):string;
var
sini:TiniFile;
cmd:string;
servername,artica_port,username,password,hostname,master_ip,myport:string;
tmpstr:string;
lighttpd:tlighttpd;
begin
  if not FileExists(SYS.LOCATE_CURL()) then begin
     result:='FAILED:{ERROR_CURL_NOT_INSTALLED}';
     exit;
  end;

  if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusClusterReplicaInfos') then begin
     result:='FAILED:{NO_CONFIG_FILE}';
     exit;
  end;

  sini:=TiniFIle.Create('/etc/artica-postfix/settings/Daemons/CyrusClusterReplicaInfos');
  servername:=sini.ReadString('REPLICA','servername','');
  master_ip:=sini.ReadString('REPLICA','master_ip','');

  if length(servername)=0 then begin
     result:='FAILED: {replica_ip} value is empty';
     exit;
  end;

  if length(master_ip)=0 then begin
     result:='FAILED: {replica_master_ip} value is empty';
     exit;
  end;
  lighttpd:=tlighttpd.Create(SYS);


  artica_port:=sini.ReadString('REPLICA','artica_port','9000');
  username:=sini.ReadString('REPLICA','username','');
  password:=sini.ReadString('REPLICA','password','');
  myport:=lighttpd.LIGHTTPD_LISTEN_PORT();
  lighttpd.free;

  hostname:=SYS.HOSTNAME_g();
   tmpstr:=logs.FILE_TEMP();
  cmd:=SYS.LOCATE_CURL()+' --connect-timeout 3 --sslv3 --insecure --get --show-error --silent --url ';
  cmd:=cmd+'"https://'+servername+':'+artica_port+'/cyrus.murder.listener.php?'+command+'&https-port='+myport+'&admin='+username+'&pass='+password+'&hostname='+hostname+'&requestedback='+servername+'&master-ip='+master_ip;
  cmd:=cmd+'&master-port='+SYS.GET_INFO('CyrusClusterPort');
  cmd:=cmd+'"';
  cmd:=cmd+' >'+ tmpstr+' 2>&1';
  logs.Debuglogs(cmd);
  fpsystem(cmd);
  result:=logs.ReadFromFile(tmpstr);
  logs.DeleteFile(tmpstr);
end;
//##############################################################################
procedure Tcyrus.IMAPD_WRITE(key:string;value:string);
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
   Found        :boolean;
   logs         :Tlogs;
begin
   Found:=False;
   logs:=Tlogs.Create;
   if not FileExists('/etc/imapd.conf') then exit();
   l:=TstringList.Create;
   l.LoadFromFile('/etc/imapd.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+':(.+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
           l.Strings[i]:=key+': ' + value;
           logs.DebugLogs('Starting......: cyrus-imapd modify value:' + key+'='+value);
           Found:=True;
       end;
   end;

if not Found then  begin
   logs.DebugLogs('Starting......: cyrus-imapd adding new value:' + key+'='+value);
   l.Add(key+': ' + value);
end;
try
   logs.WriteToFile(l.Text,'/etc/imapd.conf');
except
    logs.Syslogs('Starting......: cyrus-imapd Fatal error, unable to change imapd.conf (IMAPD_WRITE)..');
end;
l.Free;
RegExpr.Free;

end;
//##############################################################################
function Tcyrus.IMAPD_GET(key:string):string;
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
begin
   if not FileExists('/etc/imapd.conf') then exit();
   l:=TstringList.Create;
   l.LoadFromFile('/etc/imapd.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+':(.+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
           result:=trim(RegExpr.Match[1]);
           break;
       end;
   end;

l.Free;
RegExpr.Free;

end;
//##############################################################################
function Tcyrus.SASLAUTHD_GET(key:string):string;
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
begin
   if not FileExists('/etc/saslauthd.conf') then begin
      logs.Syslogs('Starting......: saslauthd, unable to stat /etc/saslauthd.conf configuration file');
      exit();
   end;
   l:=TstringList.Create;
   l.LoadFromFile('/etc/saslauthd.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+':(.+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
           result:=trim(RegExpr.Match[1]);
           break;
       end;
   end;
if length(result)=0 then logs.Syslogs('Starting......: saslauthd, unable to find "'+key+'" in /etc/saslauthd.conf');
l.Free;
RegExpr.Free;

end;
//##############################################################################


function Tcyrus.IMAPD_GET_ARTICA(key:string):string;
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
begin
   if not FileExists('/etc/artica-postfix/settings/Daemons/impadconf') then begin
      logs.Debuglogs('error: cyrus-imapd no "/etc/artica-postfix/settings/Daemons/impadconf" set');
      exit();
   end;

   l:=TstringList.Create;
   l.LoadFromFile('/etc/artica-postfix/settings/Daemons/impadconf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^'+key+':(.+)';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
           result:=trim(RegExpr.Match[1]);
           break;
       end;
   end;

l.Free;
RegExpr.Free;

end;
//##############################################################################
function Tcyrus.LMTPD_PATH():string;
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
begin
   if not FileExists('/etc/cyrus.conf') then begin
      logs.Syslogs('Starting......: cyrus-imapd Fatal error, unable to stat /etc/cyrus.conf');
      exit;
   end;

   l:=TstringList.Create;
   l.LoadFromFile('/etc/cyrus.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='lmtpunix.+?listen="(.+?)"';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
           result:=trim(RegExpr.Match[1]);
           break;
       end;
   end;

l.Free;
RegExpr.Free;

end;
//##############################################################################
function Tcyrus.LINUX_GET_HOSTNAME:string;
var datas:string;
begin
 fpsystem('/bin/hostname >/opt/artica/logs/hostname.txt');
 datas:=ReadFileIntoString('/opt/artica/logs/hostname.txt');
 result:=Trim(datas);
end;

 //#############################################################################
function Tcyrus.LIST_MAILBOXES():TStringList;
var
   cyradm:string;
   CyrPassword:string;
   cmd:string;
   l:TstringList;
   tmpstr:string;
begin
    l:=TstringList.Create;
    result:=l;
    cyradm:='cyrus';
    CyrPassword:=myldap.ldap_settings.cyrus_password;
    tmpstr:=logs.FILE_TEMP();
    cmd:=artica_path+'/bin/cyrus-admin.pl -u '+cyradm+' -p '+CyrPassword+' --list >'+tmpstr + ' 2>&1';
    fpsystem(cmd);
    logs.Debuglogs('LIST_MAILBOXES:: Exec '+cmd);
    if not FileExists(tmpstr) then exit;
    l.LoadFromFile(tmpstr);
    logs.DeleteFile(tmpstr);
    result:=l;
end;
 //#############################################################################
function Tcyrus.LIST_MAILBOXES_DOMAIN(domain:string):TStringList;
var
   cyradm:string;
   CyrPassword:string;
   cmd:string;
   l:TstringList;
   tmpstr:string;
begin
    l:=TstringList.Create;
    result:=l;
    cyradm:='cyrus';
    CyrPassword:=myldap.ldap_settings.cyrus_password;
    tmpstr:=logs.FILE_TEMP();
    cmd:=artica_path+'/bin/cyrus-admin.pl -u '+cyradm+'@'+domain+' -p '+CyrPassword+' --list >'+tmpstr + ' 2>&1';
    fpsystem(cmd);
    logs.Debuglogs('LIST_MAILBOXES_DOMAIN:: Exec '+cmd);
    if not FileExists(tmpstr) then exit;
    l.LoadFromFile(tmpstr);
    logs.DeleteFile(tmpstr);
    result:=l;
end;
 //#############################################################################
procedure Tcyrus.DELETE_MAILBOXE(user:string);
var
   cyradm,ruser:string;
   CyrPassword:string;
   cmd:string;
   RegExpr:TRegExpr;

begin
logs.Debuglogs('DELETE_MAILBOXE:: Is it a frontend ?:: "' +IntToStr(CyrusEnableImapMurderedFrontEnd)+'"');
   if CyrusEnableImapMurderedFrontEnd=1 then begin
       MURDER_SEND_COMMAND(user,'DelMbx');
       exit;
   end;

    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='(.+?)@(.+)';
    cyradm:='cyrus';
    ruser:=user;
    if RegExpr.Exec(user) then begin
       ruser:=RegExpr.Match[1];
       cyradm:=cyradm+'@'+RegExpr.Match[2];
    end;



    CyrPassword:=myldap.ldap_settings.cyrus_password;
    cmd:=artica_path+'/bin/cyrus-admin.pl -u '+cyradm+' -p '+CyrPassword+' -m ' + ruser + ' --delete';
    logs.OutputCmd(cmd);
    RegExpr.free;


end;
 //#############################################################################
procedure Tcyrus.REPAIR_CYRUS_SEEN_FILE(path:string);
begin
    if not FileExists(path) then begin
       logs.Debuglogs('Try to repair ' + path +' but does not exists');
       exit;
    end;

    if FileExists(path+'.old') then begin
       logs.NOTIFICATION('This file will no longer be repaired',path+'.old already exists, it seems that this procedure will not repair this mailbox, please investigate','system' );
       exit;
    end;

    logs.NOTIFICATION('Stopping cyrus server in order to repair a mailbox','Cyrus will be stopped in order to repair ' + path + ' file','system');
    CYRUS_DAEMON_STOP();
    fpsystem('/bin/mv ' + path + ' '+ path+'.old');
    CYRUS_DAEMON_START();
end;
 //#############################################################################
function Tcyrus.MAILBOX_EXISTS(user:string):boolean;
var
   cyradm:string;
   CyrPassword:string;
   cmd:string;
   tmp:string;
   RegExpr      :TRegExpr;
   usermbx      :string;
   s:TstringList;
   i:Integer;
begin


logs.Debuglogs('MAILBOX_EXISTS('+user+'):: Is it a frontend ?:: "' +IntToStr(CyrusEnableImapMurderedFrontEnd)+'"');
result:=false;
    cyradm:='cyrus';
    CyrPassword:=myldap.ldap_settings.cyrus_password;
    tmp:=logs.FILE_TEMP();
    usermbx:=user;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='(.+?)@(.+)';
    if RegExpr.Exec(user) then begin
        usermbx:=RegExpr.Match[1];
        cyradm:=cyradm+'@'+RegExpr.Match[2];
    end;


   if CyrusEnableImapMurderedFrontEnd=1 then begin
       logs.WriteToFile(MURDER_SEND_COMMAND(user,'MbxStat'),tmp);
   end else begin
       cmd:=artica_path+'/bin/cyrus-admin.pl -u '+cyradm+' -p '+CyrPassword+' -m ' + usermbx + ' --exists >'+tmp + ' 2>&1';
       logs.Debuglogs(cmd);
       fpsystem(cmd);
   end;

if CHECK_CYRADM_FAILURE(tmp)=1 then begin
          logs.Debuglogs('MAILBOX_EXISTS change to cyrus password');
          cmd:=artica_path+'/bin/cyrus-admin.pl -u '+cyradm+' -p secret -m ' + usermbx + ' --exists >'+tmp + ' 2>&1';
          fpsystem(cmd);
          if CHECK_CYRADM_FAILURE(tmp)=0 then begin
              logs.Debuglogs('MAILBOX_EXISTS_CGI:: Success save cyrus password');
              myldap.set_LDAP('cyrus_password','secret');
          end;
       end;


    if FileExists(tmp) then begin
       RegExpr.Expression:='TRUE\s+.+';
       s:=TstringList.Create;
       s.LoadFromFile(tmp);
       logs.DeleteFile(tmp);
       for i:=0 to s.Count-1 do begin
         logs.Debuglogs('MAILBOX_EXISTS(' + user + ') ='+s.Strings[i]);
         if RegExpr.Exec(s.Strings[i]) then begin
            result:=true;
            break;
         end;
       end;
    end;

    s.free;
    RegExpr.Free;

end;
 //#############################################################################
function Tcyrus.MAILBOX_QUOTA(user:string):string;
var
   cyradm:string;
   CyrPassword:string;
   cmd:string;
   tmp:string;
   RegExpr      :TRegExpr;
   usermbx      :string;
begin
    cyradm:='cyrus';
    CyrPassword:=myldap.ldap_settings.cyrus_password;
    tmp:=logs.FILE_TEMP();
    usermbx:=user;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='(.+?)@(.+)';
    if RegExpr.Exec(user) then begin
        usermbx:=RegExpr.Match[1];
        cyradm:=cyradm+'@'+RegExpr.Match[2];
    end;

   if CyrusEnableImapMurderedFrontEnd=1 then begin
       logs.WriteToFile(MURDER_SEND_COMMAND(user,'MailboxQuota'),tmp);
   end else begin
       cmd:=artica_path + '/bin/cyrus-admin.pl -u '+cyradm+' -p ' + CyrPassword + ' -m ' +usermbx+' --quotag >'+tmp+' 2>&1';
       logs.Debuglogs(cmd);
       fpsystem(cmd);
   end;



if CHECK_CYRADM_FAILURE(tmp)=1 then begin
          logs.Debuglogs('MAILBOX_EXISTS change to cyrus password');
          cmd:=artica_path + '/bin/cyrus-admin.pl -u '+cyradm+' -p secret -m ' +usermbx+' --quotag >'+tmp+' 2>&1';
          fpsystem(cmd);
          if CHECK_CYRADM_FAILURE(tmp)=0 then begin
              logs.Debuglogs('MAILBOX_EXISTS_CGI:: Success save cyrus password');
              myldap.set_LDAP('cyrus_password','secret');
          end;
       end;


       result:=logs.ReadFromFile(tmp);
       logs.DeleteFile(tmp);
end;
 //#############################################################################

procedure Tcyrus.CYRUS_ETC_DEFAULT_CYRUS22();
var
   l:TstringList;
begin
if not FileExists('/etc/default/cyrus2.2') then exit;

l:=TstringList.Create;
l.Add('# Defaults for Cyrus IMAPd 2.2 scripts');
l.Add('# $Id: cyrus-common-2.2.cyrus2.2.default 543 2006-08-08 16:36:00Z sven $');
l.Add('# sourced by /etc/init.d/cyrus2.2, /usr/sbin/cyrus-makedirs');
l.Add('# installed at /etc/default/cyrus2.2 by the maintainer scripts');
l.Add('#');
l.Add('');
l.Add('#');
l.Add('# This is a POSIX shell fragment');
l.Add('#');
l.Add('');
l.Add('# Set this to 1 or higher to enable debugging on cyrmaster');
l.Add('#CYRUS_VERBOSE=1');
l.Add('');
l.Add('# Socket listen queue backlog size');
l.Add('# See listen(2). Default is 32, you may want to increase');
l.Add('# this number if you have a very high connection rate');
l.Add('#LISTENQUEUE=32');
l.Add('');
l.Add('# Wether cyrus-makedirs should optimize filesystems');
l.Add('# or not.  Switch it off if you are going to do your');
l.Add('# own optimizations.  Set to 1 to enable, 0 to disable');
l.Add('CYRUSOPTFILESYS=1');
l.Add('');
l.Add('# The default Cyrus IMAP config file that the scripts should');
l.Add('# use. You better know what you''re doing if you change this');
l.Add('CONF=/etc/imapd.conf');
l.Add('');
l.Add('# The default cyrus master config file that the scripts shoud');
l.Add('# use. You better know what you''re doing if you change this.');
l.Add('MASTERCONF=/etc/cyrus.conf');
l.Add('');
l.Add('# Check spool condition with chk_cyrus on daily cronjob');
l.Add('# Set to 1 to enable, default is disabled');
l.Add('CHKCYRUS=1');
l.Add('');
l.Add('# Set the path to the PID file');
l.Add('PIDFILE=/var/run/cyrmaster.pid');
l.Add('');
l.Add('# Set other Options here. ');
l.Add('OPTIONS=""');
try
   l.SAveToFile('/etc/default/cyrus2.2');
   logs.Debuglogs('Starting......: cyrus-imapd success writing /etc/default/cyrus2.2');
except
   logs.Syslogs('Starting......: cyrus-imapd fatal error while writing /etc/default/cyrus2.2');
end;

l.free;
end;
//#############################################################################
procedure Tcyrus.CheckRightsAndConfig();
var
   config_directory:string;
   partition_default:string;
begin

if SYS.COMMANDLINE_PARAMETERS('--force') then logs.DeleteFile('/etc/artica-postfix/cyrus.check.time');



   if FileExists('/etc/artica-postfix/cyrus.check.time') then begin
      if SYS.FILE_TIME_BETWEEN_MIN('/etc/artica-postfix/cyrus.check.time')<5 then begin
         logs.DebugLogs('Starting......: too short time to perform this operation less than 10 minutes');
         exit;
      end;
   end;

if FIleExists(SYS.sudo_path()) then begin
 if FileExists('/usr/sbin/cyrus-makedirs') then logs.OutputCmd(SYS.sudo_path() + ' -u cyrus /usr/sbin/cyrus-makedirs');
end;


   config_directory:=IMAPD_GET('configdirectory');
   partition_default:=IMAPD_GET('partition-default');


   logs.Debuglogs('TCyrus.CheckRightsAndConfig():: Configure start...');
   logs.DebugLogs('Starting......: reconfigure cyrus-imapd');
   logs.DebugLogs('Starting......: configdirectory='+config_directory);
   logs.DebugLogs('Starting......: partition-default='+partition_default);
   if length(trim(config_directory))=0 then config_directory:='/var/lib/cyrus';
   if not DirectoryExists(config_directory) then config_directory:='/var/lib/cyrus';
   forceDirectories(config_directory);
   forceDirectories(config_directory+'/db');
   forceDirectories(config_directory+'/rpm');
   forceDirectories(config_directory+'/proc');
   forceDirectories(config_directory+'/socket');
   forceDirectories(partition_default);
   CreateCyrAdm();
   logs.OutputCmd(artica_path + '/bin/artica-make APP_ATOPENMAIL --config >/dev/null 2>&1 &');
   if FileExists(CYRUS_DAEMON_BIN_PATH()) then begin
      if sys.IsUserExists('bind') then sys.AddUserToGroup('cyrus','bind','','');
      sys.AddUserToGroup('cyrus','mail','','');
   end;

  logs.DebugLogs('Starting......: Scheduling permissions');
  SYS.THREAD_COMMAND_SET(SYS.LOCATE_GENERIC_BIN('nohup')+ ' /bin/chown -R cyrus:mail '+config_directory+' >/dev/null');
  SYS.THREAD_COMMAND_SET(SYS.LOCATE_GENERIC_BIN('nohup')+ ' /bin/chown -R cyrus:mail '+partition_default+' >/dev/null');
  SYS.THREAD_COMMAND_SET(SYS.LOCATE_GENERIC_BIN('nohup')+ ' /bin/chmod -R 755 '+partition_default+' >/dev/null');
  logs.OutputCmd('/bin/chown -R cyrus:mail /usr/sieve');
  logs.OutputCmd('/bin/chown -R cyrus:mail /var/sieve');


  if DirectoryExists('/var/lib/cyrus/proc') then SYS.FILE_CHOWN('cyrus','mail','/var/lib/cyrus/proc');
  if DirectoryExists('/var/run/saslauthd') then logs.OutputCmd('/bin/chown postfix:mail /var/run/saslauthd');

   if EnableCyrusMasterCluster=1 then begin
      if Not FileExists(CYRUS_SYNC_SERVER_BIN_PATH()) then EnableCyrusMasterCluster:=0;
   end;

   if EnableCyrusReplicaCluster=1 then begin
      if Not FileExists(CYRUS_SYNC_SERVER_BIN_PATH()) then EnableCyrusReplicaCluster:=0;
   end;
   logs.Debuglogs('Configure -> ETC_DEFAULT_SASLAUTHD()');
   ETC_DEFAULT_SASLAUTHD();
   logs.Debuglogs('Configure -> CYRUS_ETC_DEFAULT_CYRUS22()');
   CYRUS_ETC_DEFAULT_CYRUS22();
   logs.Debuglogs('Configure -> SASLAUTHD_CONFIGURE()');
   SASLAUTHD_CONFIGURE();
   logs.Debuglogs('Configure -> CYRUS_CERTIFICATE()');
   CYRUS_CERTIFICATE();
   logs.Debuglogs('Configure -> IMPAD_CONF()');
   WRITE_IMAPD_CONF();
   logs.Debuglogs('Configure -> CYRUS_CONF()');
   WRITE_CYRUS_CONF();
   CLEAN();
   if FileExists('/usr/share/artica-postfix/exec.imapd.conf.php') then logs.OutputCmd(SYS.LOCATE_PHP5_BIN()+ ' /usr/share/artica-postfix/exec.imapd.conf.php >/dev/null 2>&1 &');
   logs.Debuglogs('TCyrus.CheckRightsAndConfig():: Configure end...');
   logs.DeleteFile('/etc/artica-postfix/cyrus.check.time');
   logs.WriteToFile('#','/etc/artica-postfix/cyrus.check.time');

end;
//#############################################################################


function Tcyrus.CYRUS_VERSION():string;
var
    path:string;
    RegExpr:TRegExpr;
    zini:TStringList;
    i:integer;
    tmpstr:string;
begin
   path:=CYRUS_DELIVER_BIN_PATH();

   if not FileExists(path) then begin
      logs.Debuglogs('CYRUS_VERSION::Unable to stat CYRUS_DELIVER_BIN_PATH');
      exit;
   end;

   result:=SYS.GET_CACHE_VERSION('APP_CYRUS');
   if length(result)>0 then exit;
   logs.Debuglogs('deliver:'+path);
   tmpstr:=logs.FILE_TEMP();
   fpsystem(path + ' >'+tmpstr+' 2>&1');
   zini:=TStringList.Create;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=' v([0-9A-Za-z\.\-]+)';
   try
      zini.LoadFromFile(tmpstr);
   except
   end;
   logs.DeleteFile(tmpstr);

   for i:=0 to zini.Count-1 do begin
          logs.Debuglogs('CYRUS_VERSION()::'+zini.Strings[i]);
          if RegExpr.Exec(zini.Strings[i]) then begin
             logs.Debuglogs('CYRUS_VERSION():: ->'+RegExpr.Match[1]);
             result:=RegExpr.Match[1];
             break;
          end;
   end;
   RegExpr.Free;
   zini.Free;
   SYS.SET_CACHE_VERSION('APP_CYRUS',result);
   logs.Debuglogs('CYRUS_VERSION:: -> ' + result);
end;

//##############################################################################

function Tcyrus.ReadFileIntoString(path:string):string;
var
   List:TstringList;
begin

      if not FileExists(path) then begin
        exit;
      end;

      List:=Tstringlist.Create;
      List.LoadFromFile(path);
      result:=List.Text;
      List.Free;
end;
//##############################################################################
function Tcyrus.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
var
   i:integer;
   s:string;
   RegExpr:TRegExpr;

begin
 result:=false;
 s:='';
 if ParamCount>1 then begin
     for i:=2 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:=FoundWhatPattern;
   if RegExpr.Exec(s) then begin
      RegExpr.Free;
      result:=True;
   end;


end;
//##############################################################################
FUNCTION Tcyrus.CYRUS_STATUS():string;
var
  pidpath:string;
begin
SYS.MONIT_DELETE('APP_CYRUS');
if not FileExists(CYRUS_DAEMON_BIN_PATH()) then exit;

pidpath:=logs.FILE_TEMP();
fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --cyrus-imap >'+pidpath +' 2>&1');
result:=logs.ReadFromFile(pidpath);
logs.DeleteFile(pidpath);

end;
//#########################################################################################
procedure Tcyrus.CYRUS_DAEMON_RELOAD();
var
   pid:string;
begin

pid:=CYRUS_PID();
if SYS.PROCESS_EXIST(pid) then begin
   fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.check-cyrus-account.php --check-adms');
   fpsystem('/bin/kill -HUP '+pid);
end else begin
   CYRUS_DAEMON_START();
end;
end;
//#########################################################################################


procedure Tcyrus.CYRUS_DAEMON_START();
var
   m_cyrus_pid:string;
   count:integer;
   config_directory:string;

   servername:string;
   cur_domain:string;
   cyr_domain:string;
   cmd_daemon:string;
   ldap_member_base:string;
   ldap_member_base_config:string;
   lmtpsocket:string;
begin

   if not FIleExists(CYRUS_DAEMON_BIN_PATH()) then begin
      logs.DebugLogs('Starting......: cyrus-imapd not installed...');
      exit;
   end;

  if FileExists('/etc/artica-postfix/cyrus-stop') then begin
       logs.DebugLogs('Starting......: cyrus-imapd is locked');
       exit;
  end;


  if SYS.PROCESS_EXIST(SYS.GET_PID_FROM_PATH('/etc/artica-postfix/artica-backup.pid')) then begin
     logs.DebugLogs('Starting......: cyrus-imapd a backup task currently is in use');
  end;

  if not FileExists(ctl_cyrusdb_path()) then begin
      logs.Syslogs('warning, unable to stat ctl_cyrusdb');
  end;


   m_cyrus_pid:=CYRUS_PID();
   count:=0;



   if SYS.PROCESS_EXIST(m_cyrus_pid) then begin
      logs.DebugLogs('Starting......: cyrus-imapd already running using PID ' +m_cyrus_pid+ '...');
      exit;
   end;


   if not FIleExists('/usr/bin/cyradm') then begin
      if FIleExists(CYRADM_PATH()) then begin
         logs.OutputCmd('/bin/ln -s '+CYRADM_PATH()+' /usr/bin/cyradm');
      end;
   end;

   config_directory:=IMAPD_GET('configdirectory');
   logs.DebugLogs('CYRUS_DAEMON_START:: PID='+m_cyrus_pid);
   logs.DebugLogs('CYRUS_DAEMON_START:: configdirectory='+config_directory);


   if not FileExists('/etc/artica-postfix/cyrus.check.time') then CheckRightsAndConfig();

   cur_domain:=SYS.DomainName();
   cyr_domain:=trim(IMAPD_GET('defaultdomain'));
   if EnableVirtualDomainsInMailBoxes=1 then begin
      if  cyr_domain=cur_domain then begin
           logs.Syslogs('Starting......: cyrus-imapd change  defaultdomain to localhost.localdomain current : "'+ cyr_domain+'"');
           WRITE_IMAPD_CONF();
           WRITE_CYRUS_CONF();
      end;
   end;


   servername:=trim(IMAPD_GET('servername'));
   logs.Syslogs('Starting......: cyrus-imapd servername is : "'+ servername+'"');
   if length(trim(servername))=0 then begin
     servername:=SYS.HOSTNAME_g();
     logs.Syslogs('Starting......: cyrus-imapd corrupted value "servername" try to set "'+servername+'"');
     WRITE_IMAPD_CONF();
     WRITE_CYRUS_CONF();
   end;


   ldap_member_base:='dc=organizations,' + ldapserver.suffix;
   ldap_member_base_config:=trim(IMAPD_GET('ldap_member_base'));

   if ldap_member_base<>ldap_member_base_config then begin
     logs.Syslogs('Starting......: cyrus-imapd corrupted value "ldap_member_base" try to set "'+ldap_member_base+'"');
     WRITE_IMAPD_CONF();
   end;
    if ExtractFileName(ParamStr(0))<>'artica-backup' then logs.NOTIFICATION('[ARTICA]: ('+sys.HOSTNAME_g()+'): cyrus-imap daemon is stopped','Artica will try to start it','system');

    if not DirectoryExists('/var/lib/cyrus/db') then begin
    forceDirectories('/var/lib/cyrus/db');
    forceDirectories('/var/lib/cyrus/socket');
    ForceDirectories('/var/lib/cyrus/proc');
    ForceDirectories('/var/run/cyrus/socket');

    ForceDirectories(POSTFIX_QUEUE_DIRECTORY()+'/var/run/cyrus/socket');

    fpsystem(SYS.LOCATE_GENERIC_BIN('nohup')+ ' /bin/chown -R cyrus:mail /var/lib/cyrus >/dev/null 2>&1 &');
    end;
    ForceDirectories('/var/run/cyrus/socket');
    logs.OutputCmd('/bin/chmod -R 0755 /var/run/cyrus');
    logs.OutputCmd('/bin/chmod -R 0755 '+POSTFIX_QUEUE_DIRECTORY()+'/var/run/cyrus');


    if not FIleExists('/var/lib/cyrus/user_deny.db') then begin
       logs.OutputCmd('/bin/touch /var/lib/cyrus/user_deny.db');
       logs.OutputCmd('/bin/chown cyrus:mail /var/lib/cyrus/user_deny.db');
    end;

    fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.check-cyrus-account.php --check-adms');

    cmd_daemon:=CYRUS_DAEMON_BIN_PATH +' -M /etc/cyrus.conf -C /etc/imapd.conf -p /var/run/cyrmaster.pid -d &';
    logs.Debuglogs(cmd_daemon);
    fpsystem(cmd_daemon);


  count:=0;
  while not SYS.PROCESS_EXIST(CYRUS_PID()) do begin
     sleep(150);
     inc(count);
     if count>30 then begin
        writeln('');
        logs.DebugLogs('Starting......: cyrus-imapd (timeout!!!)');
        break;
     end;
     write('.');
  end;

   if not SYS.PROCESS_EXIST(CYRUS_PID()) then begin
      If FileExists(CYRUS_GET_INITD_PATH()) then begin
         logs.OutputCmd(CYRUS_GET_INITD_PATH() + ' start');
      end;

      if not SYS.PROCESS_EXIST(CYRUS_PID()) then begin
       logs.DebugLogs('Starting......: cyrus-imapd (failed)');
       logs.NOTIFICATION('[ARTICA]: ('+sys.HOSTNAME_g()+'): Unable to start cyrus-imapd daemon !','Artica is unable to start the imap/pop3 server','system');
       exit;
      end;
   end;



  if SYS.PROCESS_EXIST(CYRUS_PID()) then begin
      logs.DebugLogs('Starting......: cyrus-imapd succes PID '+CYRUS_PID());
      if ExtractFileName(ParamStr(0))<>'artica-backup' then logs.NOTIFICATION('[ARTICA]: ('+sys.HOSTNAME_g()+'): cyrus-imap was successfully started','Service is now running PID number '+CYRUS_PID(),'system');
  end;


     forceDirectories('/var/spool/postfix/var/run/cyrus/socket');
     lmtpsocket:=IMAPD_GET('lmtpsocket');
     logs.DebugLogs('Starting......: cyrus-imapd lmtpsocket:'+lmtpsocket);


     if lmtpsocket<>'/var/spool/postfix/var/run/cyrus/socket/lmtp' then begin
        logs.DebugLogs('Starting......: Linking lmtp socket');
        if not FileExists('/var/spool/postfix/var/run/cyrus/socket/lmtp') then logs.OutputCmd('/bin/ln -s '+lmtpsocket+' /var/spool/postfix/var/run/cyrus/socket/lmtp');
     end;
     logs.OutputCmd('/bin/chown -R postfix:postfix /var/spool/postfix/var/run');





end;
 //#############################################################################
function Tcyrus.MON():string;
var
l:TstringList;
begin
      exit;
if not FileExists(CYRUS_DAEMON_BIN_PATH()) then begin
   logs.DebugLogs('Starting......: cyrus-imapd is not installed, abort');
   exit;
end;
l:=TstringList.Create;
l.Add('check process cyrus with pidfile '+CYRUS_PID_PATH());
l.Add('group mail');
l.Add('start program = "/etc/init.d/artica-postfix start imap"');
l.Add('stop program = "/etc/init.d/artica-postfix stop imap"');
l.Add('if 5 restarts within 5 cycles then timeout');
result:=l.Text;
l.free;

end;
//##############################################################################
function Tcyrus.REPAIR_CYRUS():string;
var
   pid:string;
   cmd_repaire:string;
begin
result:='';
Writeln('Lock the watchdog daemon');
fpsystem('/bin/touch /etc/artica-postfix/cyrus-stop');
writeln('Stopping cyrus ');
CYRUS_DAEMON_STOP();

if FileExists(ctl_cyrusdb_path()) then begin
   Writeln('Launch '+ctl_cyrusdb_path());
   pid:=SYS.PIDOF(ctl_cyrusdb_path());

   if not SYS.PROCESS_EXIST(pid) then begin
      writeln('try to repair');
      cmd_repaire:='su cyrus -c "'+ctl_cyrusdb_path()+' -r"';
      writeln(cmd_repaire);
      fpsystem(cmd_repaire);
   end;
end else begin
    writeln('Unable to find ctl_cyrusdb');
end;

if FileExists(reconstruct_path()) then begin

end;

logs.DeleteFile('/etc/artica-postfix/cyrus-stop');
CYRUS_DAEMON_START();

end;
//##############################################################################

 procedure Tcyrus.CYRUS_DAEMON_STOP();
var

   count:integer;
   PID:string;
begin

   if not FIleExists(CYRUS_DAEMON_BIN_PATH()) then begin
      writeln('Stopping cyrus-imap..........: Not installed');
      exit;
   end;

   PID:=trim(CYRUS_PID());
   if not SYS.PROCESS_EXIST(PID) then begin
      writeln('Stopping cyrus-imap..........: Already stopped');
      exit;
   end;


   count:=0;
   writeln('Stopping cyrus-imap..........: ' + CYRUS_PID() + ' PID..');
    PID:=trim(CYRUS_PID());
    if length(PID)>0 then fpsystem('/bin/kill ' + PID);
    while SYS.PROCESS_EXIST(PID) do begin
          sleep(100);

          if length(PID)>0 then begin
             if SYS.PROCESS_EXIST(PID) then fpsystem('/bin/kill ' + PID);
          end;

          Inc(count);
          if count>20 then begin
             writeln('');
             writeln('killing cyrus-imap...........: ' + PID + ' PID.. (timeout)');
              if length(PID)>0 then fpsystem('/bin/kill -9 ' + PID);
             break;
          end;
          PID:=trim(CYRUS_PID());
    end;



    if count>0 then  writeln('');
    if SYS.PROCESS_EXIST(CYRUS_PID()) then begin
        writeln('Stopping cyrus-imap..........: ' + CYRUS_PID() + ' PID (failed)');
        exit;
    end;

    if FIleExists(CYRUS_SYNC_CLIENT_BIN_PATH()) then begin
       writeln('Stopping cyrus-imap..........: checking sync_client');
       PID:=trim(CYRUS_SYNC_CLIENT_PID());
       if length(PID)>0 then fpsystem('/bin/kill ' + PID);
       PID:=trim(CYRUS_SYNC_CLIENT_PID());
       while SYS.PROCESS_EXIST(PID) do begin
          sleep(100);

          if length(PID)>0 then begin
             if SYS.PROCESS_EXIST(PID) then fpsystem('/bin/kill ' + PID);
          end;
          Inc(count);
          if count>20 then begin
             writeln('');
             writeln('killing cyrus-imap...........: sync_client: ' + PID + ' PID.. (timeout)');
              if length(PID)>0 then fpsystem('/bin/kill -9 ' + PID);
             break;
          end;
          PID:=trim(CYRUS_SYNC_CLIENT_PID());
       end;
     end;

PID:=trim(CYRUS_PID());
   if not SYS.PROCESS_EXIST(PID) then begin
      writeln('Stopping cyrus-imap..........: Main services: Done...');
      SYS.MONIT_DELETE('APP_CYRUS');
   end;
 if FIleExists(CYRUS_SYNC_CLIENT_BIN_PATH()) then begin
      PID:=trim(CYRUS_PID());
      if not SYS.PROCESS_EXIST(PID) then begin
         writeln('Stopping cyrus-imap..........: Cluster client Done...');
      end;
end;


end;

 //#############################################################################
procedure Tcyrus.WRITE_IMAPD_CONF();
var
   list2:TstringList;
   cur_domain:string;
   cur_email:string;

   maxmessagesize:string;

   quotawarn:string;
   allowallsubscribe:string;
   duplicatesuppression:string;
   popminpoll:string;
   autocreateinboxfolders:string;
   murderConf:TiniFIle;
   backend_server_name:string;
   MURDER_BACKEND:string;
   CyrusClusterID:integer;
   configdirectory:string;
   partition_default:string;
   srvtab:string;
   CyrusImapDisableCluster:integer;
   cyrus_id:integer;
begin



maxmessagesize:=IMAPD_GET_ARTICA('maxmessagesize');

autocreateinboxfolders:=IMAPD_GET_ARTICA('autocreateinboxfolders');
quotawarn:=IMAPD_GET_ARTICA('quotawarn');
allowallsubscribe:=IMAPD_GET_ARTICA('allowallsubscribe');
duplicatesuppression:=IMAPD_GET_ARTICA('duplicatesuppression');
popminpoll:=IMAPD_GET_ARTICA('popminpoll');

partition_default:=trim(SYS.GET_INFO('CyrusPartitionDefault'));
if length(partition_default)=0 then partition_default:='/var/spool/cyrus/mail';


if not TryStrToInt(SYS.GET_INFO('CyrusImapDisableCluster'),CyrusImapDisableCluster) then CyrusImapDisableCluster:=0;
if not TryStrToInt(SYS.GET_CLUSTER('cyrus_id'),cyrus_id) then cyrus_id:=0;


if EnableCyrusMasterCluster=1 then begin
    logs.DebugLogs('Starting......: cyrus-imapd change imapd.conf, this server is a "master server"');
    logs.DebugLogs('Starting......: cyrus-imapd '+SYS.CHANGE_SERVICES_IP('csync',SYS.GET_INFO('CyrusClusterPort')));
end;

if EnableCyrusReplicaCluster=1 then begin
    logs.DebugLogs('Starting......: cyrus-imapd change imapd.conf, this server is a "replica server"');
    logs.DebugLogs('Starting......: cyrus-imapd '+SYS.CHANGE_SERVICES_IP('csync',SYS.GET_INFO('CyrusReplicaClusterPort')));
end;



//usermod -u 10000 tom

   list2:=TstringList.Create;
if CyrusEnableBackendMurder=1 then begin
   list2.Add('configdirectory: /var/lib/cyrus-murder');
   list2.Add('partition-default: '+partition_default);
   list2.Add('ldap_uri: ldap://' + ldapserver.servername + ':' + ldapserver.Port);
   list2.Add('sasl_mech_list: PLAIN LOGIN');
   list2.Add('admins: murder');
   logs.WriteToFile(list2.Text,'/etc/imap-murder.conf');
   forcedirectories('/var/lib/cyrus-murder/socket');
   forceDirectories('/var/lib/cyrus-murder/db');
   logs.OutputCmd('/bin/chown -R cyrus:mail /var/lib/cyrus-murder');
   logs.OutputCmd('/bin/echo "'+ldapserver.password+'"|/usr/sbin/saslpasswd2 -c murder');
end;

  configdirectory:='/var/lib/cyrus';
  srvtab:='/var/lib/cyrus/srvtab';


if CyrusImapDisableCluster=0 then begin
  if FIleExists('/usr/sbin/glusterfsd') then begin
     if SYS.IS_GLFS_MOUNTED('/var/lib/cyrus-clustered') then begin
           logs.DebugLogs('Starting......: cyrus-imapd running in cluster GLFS mode');
           configdirectory:='/var/lib/cyrus-clustered';
           partition_default:='/var/spool/cyrus/mail-clustered';
           srvtab:='/var/lib/cyrus-clustered/srvtab';



           if cyrus_id>0 then begin
                logs.DebugLogs('Starting......: Change cyrus id to '+IntToStr(cyrus_id));
                fpsystem('usermod -o -u '+IntToStr(cyrus_id)+' cyrus');
           end;

           if sys.IsUserExists('bind') then begin
              sys.AddUserToGroup('cyrus','bind','','');
              sys.AddUserToGroup('bind','mail','','');
           end;

     end else begin
         logs.DebugLogs('Starting......: /var/lib/cyrus-clustered is not mounted');
     end;
  end;
end;



   list2.Clear;
   list2.Add('configdirectory: '+configdirectory);
   list2.Add('defaultpartition: default');
   list2.Add('partition-default: '+partition_default);
   list2.Add('partition-news: /var/spool/cyrus/news');
   list2.Add('srvtab: '+srvtab);
   list2.Add('newsspool: '+ExtractFilePath(partition_default)+'news');
   list2.Add('sievedir: '+ExtractFilePath(partition_default)+'sieve');
   list2.Add('');
   list2.Add('');
   list2.Add('idlesocket: /var/run/cyrus/socket/idle');
   list2.Add('notifysocket: /var/run/cyrus/socket/notify');
   list2.Add('lmtpsocket: '+ POSTFIX_QUEUE_DIRECTORY()+'/var/run/cyrus/socket/lmtp');
   list2.Add('sasl_saslauthd_path:/var/run/saslauthd/mux');
   list2.Add('');
   list2.Add('');
   list2.Add('altnamespace: no');
   list2.Add('unixhierarchysep: yes');
   list2.Add('lmtp_downcase_rcpt: yes');
   list2.Add('allowanonymouslogin: no');
   list2.Add('umask: 077');
   list2.Add('sieveusehomedir: false');
   list2.Add('hashimapspool: true');
   list2.Add('');
   list2.Add('');
   list2.Add('allowplaintext: yes');
   list2.Add('sasl_pwcheck_method: saslauthd');
   list2.Add('sasl_auto_transition: no');
   list2.Add('sasl_minimum_layer: 0');
   list2.Add('ldap_member_base:dc=organizations,' + ldapserver.suffix);
   list2.Add('');
   list2.Add('');
   list2.Add('idlemethod: poll');
   list2.Add('syslog_prefix: cyrus');
   list2.Add('servername: ' + sys.HOSTNAME_g());

if CyrusEnableBackendMurder=1 then begin
   list2.Add('mupdate_server: '+sys.HOSTNAME_g());
   list2.Add('mupdate_port: 3905');
   list2.Add('mupdate_authname: murder');
   list2.Add('mupdate_username: murder');
   list2.Add('mupdate_password: '+ldapserver.password);
   list2.Add('proxyservers: murder');
end;



if CyrusEnableImapMurderedFrontEnd=1 then begin
   murderConf:=TiniFile.Create('/etc/artica-postfix/settings/Daemons/CyrusMurderBackendServer');
   logs.DebugLogs('Starting......: cyrus-imapd change imapd.conf, enable murdered frontend server');
   MURDER_BACKEND:=murderConf.ReadString('MURDER_BACKEND','servername','');
   list2.Add('mupdate_server: '+MURDER_BACKEND);
   list2.Add('mupdate_port: 3905');
   list2.Add('mupdate_authname: murder');
   list2.Add('mupdate_username: murder');
   list2.Add('mupdate_password: '+ldapserver.password);
   list2.Add('#mupdate_config: standard');
   list2.Add('allowusermoves: true');
   backend_server_name:=ansiReplaceText(MURDER_BACKEND,'.','_');
   list2.Add(backend_server_name+'_authname: murder');
   list2.Add(backend_server_name+'_password: '+ldapserver.password);
   list2.Add('proxy_authname: murder');
end;

if EnableCyrusMasterCluster=1 then begin
     murderConf:=TiniFile.Create('/etc/artica-postfix/settings/Daemons/CyrusClusterReplicaInfos');
     logs.DebugLogs('Starting......: cyrus-imapd change imapd.conf, enable cluster Master server (notify '+murderConf.ReadString('REPLICA','servername',''));
     if not TryStrToInt(SYS.GET_INFO('CyrusClusterID'),CyrusClusterID) then CyrusClusterID:=1;
     list2.Add('sync_host: '+murderConf.ReadString('REPLICA','servername',''));
     list2.Add('sync_authname: cyrus');
     list2.Add('sync_password: '+murderConf.ReadString('REPLICA','password',''));
     list2.Add('guid_mode: sha1');
     list2.Add('sync_log: yes');
     list2.Add('sync_repeat_interval: 60');
     list2.Add('sync_batch_size: 1000');
     list2.Add('sync_machineid: '+IntToStr(CyrusClusterID));
end;


   cur_domain:=SYS.DomainName();
   if length(cur_domain)>0 then cur_email:=' cyrus@'+cur_domain;

   if EnableVirtualDomainsInMailBoxes=1 then begin
      logs.DebugLogs('Starting......: cyrus-imapd change imapd.conf, enable multi-domains..');
      list2.Add('virtdomains: userid');
      list2.Add('defaultdomain: localhost.localdomain');
      list2.Add('sasl_mech_list: PLAIN LOGIN');
   end else begin
         list2.Add('virtdomains: no');
         list2.Add('sasl_mech_list: PLAIN LOGIN');
   end;


if CyrusEnableBackendMurder=1 then cur_email:=cur_email+' murder';
if CyrusEnableImapMurderedFrontEnd=1 then cur_email:=cur_email+' murder';

   list2.Add('admins: cyrus'+cur_email);
   list2.Add('username_tolower: 1');
   list2.Add('ldap_uri: ldap://' + ldapserver.servername + ':' + ldapserver.Port);


if length(popminpoll)=0 then popminpoll:='0';
if length(maxmessagesize)=0 then maxmessagesize:='0';
if length(autocreateinboxfolders)=0 then autocreateinboxfolders:='sent|drafts|spam|templates';
if length(quotawarn)=0 then quotawarn:='90';
if length(allowallsubscribe)=0 then allowallsubscribe:='1';
if length(duplicatesuppression)=0 then duplicatesuppression:='0';

   list2.Add('');
   list2.Add('');
   list2.Add('autocreatequota: 0');
   list2.Add('popminpoll: '+ popminpoll);
   list2.Add('maxmessagesize: '+ maxmessagesize);
   list2.Add('autocreateinboxfolders: '+ autocreateinboxfolders);
   list2.Add('quotawarn: '+ quotawarn);
   list2.Add('allowallsubscribe: '+ allowallsubscribe);
   list2.Add('duplicatesuppression: '+ duplicatesuppression);
   list2.Add('sieve_maxscriptsize: 1024');
   list2.Add('');

   if FIleExists('/etc/ssl/certs/cyrus.pem') then begin
         list2.Add('tls_cert_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_key_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_imap_cert_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_imap_key_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_pop3_cert_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_pop3_key_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_lmtp_cert_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_lmtp_key_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('sieve_tls_key_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_sieve_cert_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_sieve_key_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_ca_file: /etc/ssl/certs/cyrus.pem');
         list2.Add('tls_ca_path: /etc/ssl/certs');
         list2.Add('tls_session_timeout: 1440');
         list2.Add('tls_cipher_list: TLSv1+HIGH:!aNULL:@STRENGTH');
   end;

   list2.Add('tls_require_cert: false');
   list2.Add('tls_imap_require_cert: false');
   list2.Add('tls_pop3_require_cert: false');
   list2.Add('tls_lmtp_require_cert: false');
   list2.Add('tls_sieve_require_cert: false');

   SYS:=Tsystem.Create;
   if SYS.IsGroupExists('mail') then begin
             logs.Debuglogs('IMPAD_CONF:: adding postfix user into mail group');
      SYS.AddUserToGroup('postfix','mail','','');
   end else begin

       logs.Debuglogs('IMPAD_CONF:: mail group does not exists');
   end;


   logs.DebugLogs('Starting......: cyrus-imapd change imapd.conf done..');



   try
      logs.WriteToFile(list2.Text,'/etc/imapd.conf');
   except
   logs.Syslogs('Starting......: cyrus-imapd Fatal error, unable to change imapd.conf (CYRUS_IMAPD_CONFIGURE)..');
   end;
   list2.free;

end;
 //#############################################################################


procedure Tcyrus.WRITE_CYRUS_CONF();
var
   list2:TstringList;
   l:Tstringlist;
   ctl_cyrusdb:string;
   cyr_expire:string;
   tls_prune:string;
   ini:TiniFile;
   provide_uuid:string;
   zarafa:tzarafa_server;


   service_imap_maxchild:integer;
   service_imapssl_enabed:integer;
   service_imapssl_listen:string;
   service_imapssl_maxchild:integer;

   service_pop3_enabed:integer;
   service_pop3_listen:string;
   service_pop3_maxchild:integer;

   service_pop3ssl_enabed:integer;
   service_pop3ssl_listen:string;
   service_pop3ssl_maxchild:integer;

   service_nntpd_enabed:integer;
   service_nntpd_listen:string;

   service_nntpds_enabed:integer;
   service_nntpds_listen:string;
   imapd,pop3d,nntpd,lmtpd:string;
   basepath:string;
   CyrusEnableSquatter:integer;
   CyrusSquatterRindex:integer;
   CyrusiPurgeSent:integer;
   CyrusiPurgeJunk:integer;
   CyrusiPurgeTrash:integer;
   nice_path:string;
   Zarafa_installed:boolean;
   listen:string;
   SieveListenIp:string;
   CyrusLMTPListen:string;
   CyrusLMTPListenPattern:string;
   RegExpr:TRegExpr;
begin

       if not TryStrToInt(SYS.GET_INFO('CyrusEnableSquatter'),CyrusEnableSquatter) then CyrusEnableSquatter:=0;
       if not TryStrToInt(SYS.GET_INFO('CyrusSquatterRindex'),CyrusSquatterRindex) then CyrusSquatterRindex:=120;

       if not TryStrToInt(SYS.GET_INFO('CyrusiPurgeSent'),CyrusiPurgeSent) then CyrusiPurgeSent:=1;
       if not TryStrToInt(SYS.GET_INFO('CyrusiPurgeJunk'),CyrusiPurgeJunk) then CyrusiPurgeJunk:=1;
       if not TryStrToInt(SYS.GET_INFO('CyrusiPurgeTrash'),CyrusiPurgeTrash) then CyrusiPurgeTrash:=1;
       Zarafa_installed:=false;
       CyrusLMTPListenPattern:='';
       zarafa:=tzarafa_server.Create(SYS);
       if FileExists(zarafa.SERVER_BIN_PATH()) then Zarafa_installed:=true;
       if not FileExists(SYS.LOCATE_CYRUS_SQUATTER()) then CyrusEnableSquatter:=0;

       CyrusLMTPListen:=SYS.GET_INFO('CyrusLMTPListen');
       RegExpr:=TRegExpr.Create;
       RegExpr.Expression:='(.+?):([0-9]+)';
       if RegExpr.Exec(CyrusLMTPListen) then CyrusLMTPListenPattern:=trim(RegExpr.Match[1]+':'+RegExpr.Match[2]);
       if length(CyrusLMTPListenPattern)=0 then CyrusLMTPListenPattern:='127.0.0.1:2005';

       provide_uuid:='';
       if not FileExists(CYRUS_DELIVER_BIN_PATH()) then begin
          logs.DebugLogs('Starting......: cyrus-imapd not installed');
          exit;
       end;

       if not FileExists('/etc/artica-postfix/settings/Daemons/ArticaImapIniConf') then begin
          l:=TstringList.Create;
          l.add('[CYRUS]');
          l.add('service_imap_enabed=1');
          l.add('service_imap_listen=imap');
          l.add('service_imapssl_enabed=0');
          l.add('service_imapssl_listen=imaps');
          l.add('service_pop3_enabed=1');
          l.add('service_pop3_listen=pop3');
          l.add('service_pop3ssl_enabed=0');
          l.add('service_pop3ssl_listen=pop3s');
          l.add('service_nntpd_enabed=0');
          l.add('service_nntpd_listen=nntp');
          l.add('service_nntpds_enabed=0');
          l.add('service_nntpds_listen=nntps');
          logs.WriteToFile(l.Text,'/etc/artica-postfix/settings/Daemons/ArticaImapIniConf');
          l.free;
       end;



           ini:=TiniFile.Create('/etc/artica-postfix/settings/Daemons/ArticaImapIniConf');

           service_imap_maxchild:=ini.ReadInteger('CYRUS','service_imap_maxchild',500);

           service_imapssl_enabed:=ini.ReadInteger('CYRUS','service_imapssl_enabed',0);
           service_imapssl_listen:=ini.ReadString('CYRUS','service_imapssl_listen','imaps');
           service_imapssl_maxchild:=ini.ReadInteger('CYRUS','service_imapssl_maxchild',500);



           service_pop3_enabed:=ini.ReadInteger('CYRUS','service_pop3_enabed',0);
           service_pop3_listen:=ini.ReadString('CYRUS','service_pop3_listen','pop3');
           service_pop3_maxchild:=ini.ReadInteger('CYRUS','service_pop3_maxchild',150);

           service_pop3ssl_enabed:=ini.ReadInteger('CYRUS','service_pop3ssl_enabed',0);
           service_pop3ssl_listen:=ini.ReadString('CYRUS','service_pop3ssl_listen','pop3s');
           service_pop3ssl_maxchild:=ini.ReadInteger('CYRUS','service_pop3ssl_maxchild',150);

           service_nntpd_enabed:=ini.ReadInteger('CYRUS','service_nntpd_enabed',0);
           service_nntpd_listen:=ini.ReadString('CYRUS','service_nntpd_listen','nntp');

           service_nntpds_enabed:=ini.ReadInteger('CYRUS','service_nntpds_enabed',0);
           service_nntpds_listen:=ini.ReadString('CYRUS','service_nntpds_listen','nntps');
           SieveListenIp:=SYS.GET_INFO('SieveListenIp');
           if length(SieveListenIp)>0 then begin
              if SieveListenIp<>'127.0.0.1' then SieveListenIp:=SieveListenIp+':sieve' else SieveListenIp:='';
           end;


       sys:=TSystem.Create();
       sys.CreateGroup('mail');
       sys.AddUserToGroup('cyrus','mail','','');


       ForceDirectories('/var/lib/cyrus/srvtab');
       ForceDirectories('/var/lib/cyrus/db');
       ForceDirectories('/var/spool/cyrus/mail');
       ForceDirectories('/var/spool/cyrus/news');
       ForceDirectories('/var/run/cyrus/socket');
       ForceDirectories('/var/lib/cyrus/socket');
       ForceDirectories('/var/lib/cyrus/proc');
       ForceDirectories('/var/run/cyrus/socket');


       fpsystem('/bin/chmod 750 /var/run/cyrus');
       SYS.THREAD_COMMAND_SET('chmod -R 755 /var/lib/cyrus');
       SYS.THREAD_COMMAND_SET('/bin/chown -R cyrus:mail /var/lib/cyrus >/dev/null 2>&1');
       SYS.THREAD_COMMAND_SET('/bin/chown -R cyrus:mail /var/run/cyrus >/dev/null 2>&1');


        ctl_cyrusdb:=ctl_cyrusdb_path();
        cyr_expire:=cyr_expire_path();
        tls_prune:=tls_prune_path();
        logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: ctl_cyrusdb='+ctl_cyrusdb);
        logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: cyr_expire='+cyr_expire);
        logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: tls_prune='+tls_prune);
        logs.DebugLogs('Starting......: cyrus-imapd murder has backend is:'+IntTOStr(CyrusEnableBackendMurder));

imapd:='imapd';
pop3d:='pop3d';
nntpd:='nntpd';
lmtpd:='lmtpd';

basepath:=ExtractFilePath(CYRUS_POP3D_BIN_PATH());

if CyrusEnableImapMurderedFrontEnd=1 then begin
  imapd:='proxyd';
  pop3d:='pop3proxyd';
  lmtpd:='lmtpproxyd';
end;



if CyrusClusterID>0 then  begin
   provide_uuid:=' provide_uuid='+IntToStr(CyrusClusterID);
   logs.DebugLogs('Starting......: cyrus-imapd provide Universally Unique Identifiers number '+ IntToStr(CyrusClusterID));
end;

list2:=TstringList.Create;
list2.Add('');
list2.Add('START {');
list2.Add('	recover		cmd="' + ctl_cyrusdb+ ' -r"');
list2.Add('	delprune	cmd="' + cyr_expire + ' -E 3"');
list2.Add('	tlsprune	cmd="' + tls_prune+'"');
if CyrusEnableBackendMurder=1 then begin
list2.Add('	mupdatepush     cmd="'+SYS.LOCATE_ctl_mboxlist()+' -m"');
end;

if EnableCyrusMasterCluster=1 then begin
   if FIleExists(CYRUS_SYNC_CLIENT_BIN_PATH()) then begin
      logs.DebugLogs('Starting......: cyrus-imapd change cyrus.conf, this server is a "master server", enable "Rolling" replication');
      list2.Add('syncclient       cmd="'+CYRUS_SYNC_CLIENT_BIN_PATH()+' -r"');
   end else begin
      logs.DebugLogs('Starting......: cyrus-imapd change cyrus.conf, unable to stat sync_client bin');
   end;
end;




list2.Add('}');
list2.Add('');
list2.Add('SERVICES {');

listen:='imap';
if Zarafa_installed then begin
       logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: Zarafa is installed, change to 1143 port to avoid conflicts');
       listen:='1143';
end;


list2.Add('	imap		cmd="'+basepath+imapd+' -U 30" listen="'+listen+'" prefork=0 maxchild='+IntToStr(service_imap_maxchild));
if service_imapssl_enabed=1 then begin
   if Zarafa_installed then service_imapssl_listen:='1993';
   logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: imap SSL enabled');
   list2.Add('	imaps		cmd="'+basepath+imapd+' -s -U 30" listen="'+service_imapssl_listen+'" prefork=0 maxchild='+IntToStr(service_imapssl_maxchild)+' '+provide_uuid);
end;

if service_pop3_enabed=1    then begin
      logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: pop3 enabled');
      if Zarafa_installed then begin
         logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: Zarafa is installed, change to 1143 port to avoid conflicts');
         service_pop3_listen:='1110';
      end;
      list2.Add('	pop3		cmd="'+basepath+pop3d+' -U 30" listen="'+service_pop3_listen+'" prefork=0 maxchild='+IntToStr(service_pop3_maxchild));
end;

if service_pop3ssl_enabed=1 then begin
   logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: pop3 SSL enabled');
   if Zarafa_installed then begin
   logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: Zarafa is installed, change to 1995 port to avoid conflicts');
   service_pop3ssl_listen:='1995';
   end;

   list2.Add('	pop3s		cmd="'+basepath+pop3d+' -s -U 30" listen="'+service_pop3ssl_listen+'" prefork=0 maxchild='+IntToStr(service_pop3ssl_maxchild));
end;


if service_nntpd_enabed=1   then begin
   logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: NNTP enabled');
   list2.Add('	nntp		cmd="'+basepath+nntpd+' -U 30" listen="'+service_nntpd_listen+'" prefork=0 maxchild=100'+provide_uuid);
end;

if service_nntpds_enabed=1  then begin
      logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: NNTP SSL enabled');
      list2.Add('	nntps		cmd="'+basepath+nntpd+' -s -U 30" listen="'+service_nntpds_listen+'" prefork=0 maxchild=100'+provide_uuid);
end;


   list2.Add('	lmtpunix	cmd="'+basepath+lmtpd+'" listen="/var/spool/postfix/var/run/cyrus/socket/lmtp" prefork=0 maxchild=20'+provide_uuid);
 if CyrusEnableLMTPUnix=0 then list2.Add('	lmtp	cmd="'+basepath+lmtpd+'" listen="'+CyrusLMTPListenPattern+'" prefork=0 maxchild=20'+provide_uuid);

if FileExists(sieved_path()) then begin
   list2.Add('  	sieve		cmd="'+sieved_path()+'" listen="localhost:sieve" prefork=0 maxchild=100');
   if length(SieveListenIp)>0 then list2.Add('  	sieveremote		cmd="'+sieved_path()+'" listen="'+SieveListenIp+'" prefork=0 maxchild=100');
end;

if FileExists(notify_path()) then list2.Add('	notify		cmd="'+notify_path()+'" listen="/var/run/cyrus/socket/notify" proto="udp" prefork=1');

if CyrusEnableBackendMurder=1 then begin
logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: enable mupdate machine');
list2.Add('     mupdate         cmd="'+basepath+'mupdate -m -C /etc/imap-murder.conf" listen=3905 prefork=1');
end;

if CyrusEnableImapMurderedFrontEnd=1 then begin
logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: enable mupdate machine (frontend)');
list2.Add('     mupdate         cmd="mupdate" listen=3905 prefork=1');
end;

if EnableCyrusReplicaCluster=1 then begin
list2.Add('     syncserver       cmd="'+CYRUS_SYNC_SERVER_BIN_PATH()+'" listen="csync"');
end;
list2.Add('}');
list2.Add('');
list2.Add('EVENTS {');
list2.Add('	checkpoint	cmd="' + ctl_cyrusdb + ' -c" period=30');
list2.Add('	delprune	cmd="' + cyr_expire  + ' -E 3" at=0401');
list2.Add('	tlsprune	cmd="' + tls_prune   + '" at=0401');


nice_path:=SYS.LOCATE_GENERIC_BIN('nice');
if FileExists(nice_path) then nice_path:=nice_path+' -n 19 ' else nice_path:='';

if CyrusEnableSquatter=1 then begin
list2.Add('	squatter        cmd="' + SYS.LOCATE_CYRUS_SQUATTER() + ' -s -r user" at=2300');
list2.Add('	squatter_1      cmd="'+nice_path+SYS.LOCATE_CYRUS_SQUATTER() + ' -s" period='+IntToStr(CyrusSquatterRindex));
end;


if CyrusEnableiPurge=1 then begin
   if CyrusiPurgeTrash=1 then list2.Add('	purgetrash        cmd="' + SYS.LOCATE_CYRUS_IPURGE() + ' -f -d '+sys.GET_INFO('CyrusiPurgeDays')+' */Trash" at='+sys.GET_INFO('CyrusiPurgeTime'));
   if CyrusiPurgeJunk=1 then list2.Add('	purgejunk         cmd="' + SYS.LOCATE_CYRUS_IPURGE() + ' -f -d '+sys.GET_INFO('CyrusiPurgeDays')+' */Junk" at='+sys.GET_INFO('CyrusiPurgeTime'));
   if CyrusiPurgeSent=1 then list2.Add('	purgesent         cmd="' + SYS.LOCATE_CYRUS_IPURGE() + ' -f -d '+sys.GET_INFO('CyrusiPurgeDays')+' */Sent" at='+sys.GET_INFO('CyrusiPurgeTime'));
end;



list2.Add('');
list2.Add('}');
list2.Add('');
logs.DebugLogs('Starting......: cyrus-imapd cyrus.conf: saving /etc/cyrus.conf '+ IntTOStr(list2.Count)+' lines');
logs.WriteToFile(list2.Text,'/etc/cyrus.conf');
list2.free;

end;
//##############################################################################
 function Tcyrus.SASLAUTHD_PID():string;
var
   conffile:string;
   RegExpr:TRegExpr;
   FileData:TStringList;
   i:integer;
begin
   result:='0';
   if FileExists('/var/run/saslauthd/saslauthd.pid') then conffile:='/var/run/saslauthd/saslauthd.pid';
   if FileExists('/var/run/saslauthd.pid') then conffile:='/var/run/saslauthd.pid';
   if FileExists('/var/run/saslauthd/saslauthd.pid') then conffile:='/var/run/saslauthd/saslauthd.pid';

   if length(conffile)=0 then exit();

  if not FileExists(conffile) then exit();
  RegExpr:=TRegExpr.Create;
  FileData:=TStringList.Create;
  FileData.LoadFromFile(conffile);
  RegExpr.Expression:='([0-9]+)';
  For i:=0 TO FileData.Count -1 do begin
      if RegExpr.Exec(FileData.Strings[i]) then begin
           result:=RegExpr.Match[1];
           break;
      end;
  end;

  FileData.Free;
  RegExpr.Free;
end;
 //##############################################################################


function Tcyrus.TestingMailBox(username:string;password:string):string;
var
   l:Tstringlist;
   s:Tstringlist;
   st:string;
   tmpstr:string;
   saslpid:string;
begin


 tmpstr:=logs.FILE_TEMP();
 saslpid:=SASLAUTHD_PID();


 l:=Tstringlist.Create;
 if not SYS.PROCESS_EXIST(saslpid) then exit('Warning saslauthd is not running !!');
 if length(trim(password))=0 then begin
 l.Add('<strong style="font-size:14px;color:red">Warnig password is not set</strong>');
 end;

 l:=TstringList.Create;
 l.add('<strong style="font-size:14px">Testing mailbox ' + username+'</strong><hr>');
 l.Add('<strong style="font-size:14px">Saslauthd output</strong><hr>');
 fpsystem('/bin/ps -aux|grep saslauthd >' + tmpstr+' 2>&1');
 l.Add(logs.ReadFromFile(tmpstr));
 logs.DeleteFile(tmpstr);
 l.Add('<hr>');
 l.Add('<strong style="font-size:14px">Saslauthd test password:</strong><hr>');

 fpsystem('/usr/sbin/testsaslauthd -u '+ username + ' -p ' + password +' >'+tmpstr+' 2>&1');
 l.Add(logs.ReadFromFile(tmpstr));
 logs.DeleteFile(tmpstr);
 l.Add('<hr>');
 l.Add('<strong style="font-size:14px">IMAP test password:</strong><hr>');

 st:=logs.FILE_TEMP();
 s:=TstringList.Create();
 s.Add('[CONF]');
 s.Add('ImapServer=127.0.0.1');
 s.Add('username='+username);
 s.Add('password='+password);
 s.SaveToFile(st);
 s.free;
 fpsystem('/usr/share/artica-postfix/bin/imap-tests.pl --path '+st+' >'+tmpstr+' 2>&1');
 l.Add(logs.ReadFromFile(tmpstr));
 logs.DeleteFile(tmpstr);
 logs.DeleteFile(st);
 l.Add('<hr>');
 l.Add('<strong style="font-size:14px">/etc/saslauthd.conf:</strong>');
 l.Add(TestingMailBox_saslauthd_infos());
 l.Add('<hr><strong style="font-size:14px">/etc/imapd.conf:</strong>');
 l.Add(TestingMailBox_imapdconf());

 result:=l.Text;
 l.Free;
end;
 //##############################################################################
function Tcyrus.TestingMailBox_saslauthd_infos():string;
var
   l:Tstringlist;
    RegExpr:TRegExpr;
    i:integer;
begin
     if not FileExists('/etc/saslauthd.conf') then begin
            exit('<strong style="font-size:14px;color:red">Warning unable to stat /etc/saslauthd.conf</strong>');
     end;

   l:=Tstringlist.Create;
   l.LoadFromFile('/etc/saslauthd.conf');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^ldap_password';
   for i:=0 to l.Count-1 do begin
       if RegExpr.Exec(l.Strings[i]) then begin
               l.Strings[i]:='ldap_password *****';
       end;
   end;

   result:=l.Text;

  l.free;
end;
 //##############################################################################
function Tcyrus.TestingMailBox_imapdconf():string;
var
   l:Tstringlist;
begin
     if not FileExists('/etc/imapd.conf') then begin
            exit('<strong style="font-size:14px;color:red">Warning unable to stat /etc/imapd.conf</strong>');
     end;

   l:=Tstringlist.Create;
   l.LoadFromFile('/etc/imapd.conf');
   result:=l.Text;
  l.free;
end;
 //##############################################################################
procedure Tcyrus.CLUSTER_SEND_LDAP_DATABASE();
var
sini:TiniFile;
cmd,uri,command:string;
servername,artica_port,username,password,master_ip:string;
begin

if EnableCyrusMasterCluster=0 then begin
   logs.Debuglogs('CLUSTER_SEND_LDAP_DATABASE():: No Master cluster configuration set...');
   exit;
end;

if not FileExists(SYS.LOCATE_SLAPCAT()) then begin
   logs.Debuglogs('CLUSTER_SEND_LDAP_DATABASE():: Backuping LDAP Database unable to stat slapcat');
   exit;
end;
logs.OutputCmd(SYS.LOCATE_SLAPCAT() + ' -l /tmp/ldap.ldif');

  if not FileExists('/etc/artica-postfix/settings/Daemons/CyrusClusterReplicaInfos') then begin
     logs.Debuglogs('CLUSTER_SEND_LDAP_DATABASE:{NO_CONFIG_FILE}');
     exit;
  end;

  sini:=TiniFIle.Create('/etc/artica-postfix/settings/Daemons/CyrusClusterReplicaInfos');
  servername:=sini.ReadString('REPLICA','servername','');
  master_ip:=sini.ReadString('REPLICA','master_ip','');

  if length(servername)=0 then begin
     logs.Debuglogs('CLUSTER_SEND_LDAP_DATABASE: {replica_ip} value is empty');
     exit;
  end;

  if length(master_ip)=0 then begin
     logs.Debuglogs('CLUSTER_SEND_LDAP_DATABASE: {replica_master_ip} value is empty');
     exit;
  end;




  artica_port:=sini.ReadString('REPLICA','artica_port','9000');
  username:=sini.ReadString('REPLICA','username','');
  password:=sini.ReadString('REPLICA','password','');
  uri:='https://'+servername+':'+artica_port+'/cyrus.murder.listener.php';
  command:='?export-ldap=yes&admin='+username+'&pass='+password+'&ldap-suffix='+ldapserver.suffix;
  cmd:=SYS.LOCATE_CURL()+' -H ''Expect: '' --silent --sslv3 --insecure -F file=@/tmp/ldap.ldif "'+uri+command+'"';
  logs.Debuglogs(command);
  fpsystem(cmd);
end;










end.
