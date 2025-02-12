unit squid;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem;

type LDAP=record
      admin:string;
      password:string;
      suffix:string;
      servername:string;
      Port:string;
  end;

  type
  tsquid=class


private
     LOGS:Tlogs;
     D:boolean;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;
     SQUIDEnable:integer;
     SquidEnableProxyPac:integer;
     TAIL_STARTUP:string;
     function COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
     function get_INFOS(key:string):string;
     function ReadFileIntoString(path:string):string;
     function SQUID_DETERMINE_PID_PATH():string;
     procedure WRITE_INITD();
     procedure ERROR_FD();
     function    DANSGUARDIAN_PORT():string;
     function    GET_LOCAL_PORT():string;
     function    TAIL_PID():string;
     function    PROXY_PAC_PID():string;
     function    GET_SSL_PORT():string;

public
    Caches      :TstringList;
    DansGuardianEnabled:integer;
    procedure   Free;
    constructor Create;
    PROCEDURE   SQUID_RRD_INSTALL();
    function    SQUID_BIN_PATH():string;
    PROCEDURE   SQUID_RRD_EXECUTE();
    procedure   SQUID_START();
    function    SQUID_PID():string;
    PROCEDURE   SQUID_RRD_INIT();
    PROCEDURE   SQUID_VERIFY_CACHE();
    function    SQUID_CONFIG_PATH():string;
    function    SQUID_GET_SINGLE_VALUE(key:string):string;
    procedure   SQUID_SET_CONFIG(key:string;value:string);
    procedure   SQUID_STOP();
    function    SQUID_STATUS():string;
    function    SQUID_VERSION():string;
    function    ldap_auth_path():string;
    function    ntml_auth_path():string;
    function    SQUID_GET_CONFIG(key:string):string;
    function    SQUIDCLIENT_BIN_PATH():string;
    function    SQUID_INIT_PATH():string;
    function    SQUID_SPOOL_DIR():string;
    procedure   PARSE_ALL_CACHES();
    function    SQUID_BIN_VERSION(version:string):int64;
    function    icap_enabled():boolean;
    function    ntlm_enabled():boolean;

    procedure   TAIL_START();
    procedure   TAIL_STOP();
    function    TAIL_STATUS():string;

    procedure   SQUID_RELOAD();
    procedure   AS_TRANSPARENT_MODE();
    function    IS_IPTABLES_SQUID_EXISTS(listen_port:string):boolean;
    procedure   REMOVE();
    procedure   START_SIMPLE();

    //SARG
    function    SARG_VERSION():string;
    function    SARG_SCAN():string;
    procedure   SARG_CONFIG();
    procedure   SARG_EXECUTE();

    //ProxyPac
    procedure   PROXY_PAC_STOP();
    procedure   PROXY_PAC_START();

END;

implementation

constructor tsquid.Create;
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=Tsystem.Create;
       D:=COMMANDLINE_PARAMETERS('--roundcube');
       
       if not TryStrToInt(SYS.GET_INFO('DansGuardianEnabled'),DansGuardianEnabled) then DansGuardianEnabled:=0;
       if not TryStrToInt(SYS.GET_INFO('SQUIDEnable'),SQUIDEnable) then SQUIDEnable:=1;
       if not TryStrToInt(SYS.GET_INFO('SquidEnableProxyPac'),SquidEnableProxyPac) then SquidEnableProxyPac:=0;



       TAIL_STARTUP:=SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.squid-tail.php';
       if SQUIDEnable=0 then begin
          DansGuardianEnabled:=0;
          SquidEnableProxyPac:=0;
       end;
       Caches:=TstringList.Create;
       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tsquid.free();
begin
    logs.Free;
    SYS.Free;
    Caches.free;
end;
//##############################################################################
function tsquid.SQUID_BIN_PATH():string;
begin
  if FileExists('/opt/artica/sbin/squid') then exit('/opt/artica/sbin/squid');
  if FileExists('/usr/sbin/squid') then exit('/usr/sbin/squid');
  if FileExists('/usr/sbin/squid3')  then exit('/usr/sbin/squid3');
  if FileExists('/usr/local/sbin/squid') then exit('/usr/local/sbin/squid');
  if FileExists('/sbin/squid') then exit('/sbin/squid');
end;
//##############################################################################
function tsquid.SQUIDCLIENT_BIN_PATH():string;
begin
  if FileExists('/usr/bin/squidclient') then exit('/usr/bin/squidclient');
  if FileExists('/usr/local/squid/sbin/squidclient') then exit('/usr/local/squid/sbin/squidclient');
end;
//##############################################################################
function tsquid.SQUID_INIT_PATH():string;
begin
  if FileExists('/etc/init.d/squid') then exit('/etc/init.d/squid');
  if FileExists('/etc/init.d/squid3') then exit('/etc/init.d/squid3');
end;
//##############################################################################
function tsquid.icap_enabled():boolean;
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
   FileTemp     :string;
begin
   result:=false;
   FileTemp:=logs.FILE_TEMP();
   fpsystem(SQUID_BIN_PATH() + ' -v >'+FileTemp + ' 2>&1');
   if not FileExists(Filetemp) then exit;
   l:=TstringList.Create;
   l.LoadFromFile(FileTemp);
   logs.DeleteFile(FileTemp);
   RegExpr:=TRegExpr.Create;
   for i:=0 to l.count-1 do begin
       RegExpr.Expression:='--enable-icap-client';
       if  RegExpr.Exec(l.Strings[i]) then begin
           result:=true;
           break;
       end;
       RegExpr.Expression:='--enable-icap-support';
       if  RegExpr.Exec(l.Strings[i]) then begin
           result:=true;
           break;
       end;
   end;
   
   l.free;
   RegExpr.Free;
   

end;
//##############################################################################
function tsquid.ntlm_enabled():boolean;
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
   FileTemp     :string;
begin
   result:=false;
   FileTemp:=logs.FILE_TEMP();
   fpsystem(SQUID_BIN_PATH() + ' -v >'+FileTemp + ' 2>&1');
   if not FileExists(Filetemp) then exit;
   l:=TstringList.Create;
   l.LoadFromFile(FileTemp);
   logs.DeleteFile(FileTemp);
   RegExpr:=TRegExpr.Create;
   for i:=0 to l.count-1 do begin
       RegExpr.Expression:='--enable-auth=(.+?)';
       if  RegExpr.Exec(l.Strings[i]) then begin
           RegExpr.Expression:='ntlm';
           if  RegExpr.Exec(l.Strings[i]) then begin
               result:=true;
           end;
           break;
       end;
   end;

   l.free;
   RegExpr.Free;
end;
//##############################################################################



procedure tsquid.ERROR_FD();
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
   FileTemp     :string;
   LastLog      :string;
begin
  exit;
  caches:=TstringList.Create;
  FileTemp:=SYS.LOCATE_SYSLOG_PATH();
  if not FileExists(FileTemp) then exit;
  l:=TstringList.Create;
  logs.Debuglogs('tsquid.ERROR_FD():: loading ' + FileTemp);
  try
  l.LoadFromFile(FileTemp);
  LastLog:=l.Strings[l.Count-1];
  l.free;
  Except
    logs.Debuglogs('tsquid.ERROR_FD():: Fatal error...');
    exit;
  end;
  logs.Debuglogs('tsquid.ERROR_FD():: Last log='+LastLog);
  RegExpr:=TRegExpr.Create;
  RegExpr.Expression:='httpAccept.+?FD.+?Invalid argument';

  if RegExpr.Exec(LastLog) then begin
     if RegExpr.Match[1]='26' then begin
        PARSE_ALL_CACHES();
        for i:=0 to caches.Count-1 do begin
            if length(caches.Strings[i])>5 then fpsystem('/bin/rm -rf ' + caches.Strings[i]+'/*');
        end;
     logs.Syslogs('tsquid.ERROR_FD():: Error FD Found, restart all server !!!');
     logs.NOTIFICATION(LastLog + ' Artica will be restarted','Fatal error...','system');
     fpsystem('/etc/init.d/artica-postfix restart');
     halt(0);
    end;
  end;
RegExpr.Expression:='comm_old_accept.+?FD\s+([0-9]+).+?Invalid argument';
if RegExpr.Exec(LastLog) then begin
     if RegExpr.Match[1]='26' then begin
        PARSE_ALL_CACHES();
        for i:=0 to caches.Count-1 do begin
            if length(caches.Strings[i])>5 then fpsystem('/bin/rm -rf ' + caches.Strings[i]+'/*');
        end;
     logs.Syslogs('tsquid.ERROR_FD():: Error FD Found, restart all server !!!');
     logs.NOTIFICATION(LastLog + ' Artica will be restarted','Fatal error...','system');
     fpsystem('/etc/init.d/artica-postfix restart');
     halt(0);
    end;
  end;
end;
//##############################################################################
procedure tsquid.SQUID_RELOAD();
var pid:string;
begin
  pid:=SQUID_PID();
  logs.Debuglogs('Starting......: reloading SQUID PID: '+pid);
  if SYS.PROCESS_EXIST(pid) then begin
     AS_TRANSPARENT_MODE();
     SQUID_VERIFY_CACHE();
     logs.Debuglogs('Starting......: reloading squid...');
     fpsystem(SQUID_BIN_PATH() + ' -k reconfigure');
     fpsystem('/etc/init.d/artica-postfix start kav4proxy &');
     exit;
  end else begin
     SQUID_START();
  end;
end;
//##############################################################################
procedure tsquid.AS_TRANSPARENT_MODE();
var
   hasProxyTransparent:Integer;
   local_port:string;
   https_port:string;
   https_port_int:integer;
begin
if not TryStrToInt(SYS.GET_INFO('hasProxyTransparent'),hasProxyTransparent) then hasProxyTransparent:=0;
if hasProxyTransparent=1 then begin
    if not SYS.ip_forward_enabled() then begin
           logs.Debuglogs('Starting......: Enable this computer has gateway mode...');
           fpsystem('sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1');
           if not SYS.ip_forward_enabled() then begin
                  logs.Syslogs('Starting......: Failed !!! Enable this computer has gateway mode...');
                  exit;
           end;
    end;
    //http://www.fido-fr.net/linux_squid_iptables.shtml
    local_port:=GET_LOCAL_PORT();
    https_port:=GET_SSL_PORT();
    if not TryStrToInt(https_port,https_port_int) then https_port_int:=0;

    if not IS_IPTABLES_SQUID_EXISTS(local_port) then begin
       logs.Syslogs('Starting......: Insert routing table HTTP in iptables configuration... dest:'+local_port);
       fpsystem(SYS.LOCATE_IPTABLES() + ' -A PREROUTING -t nat -p tcp --dport 80 -j REDIRECT --to-port '+local_port);
       if not IS_IPTABLES_SQUID_EXISTS(local_port) then begin
           logs.Syslogs('Starting......: Failed using '+ SYS.LOCATE_IPTABLES() + ' -A PREROUTING -t nat -p tcp --dport 80 -j REDIRECT --to-port '+local_port);
       end;

    end else begin
       logs.Debuglogs('Starting......: Insert routing table HTTP in iptables already done...');
    end;

    if https_port_int<5 then begin
        logs.Debuglogs('Starting......: Insert routing table HTTPS failed, no defined port');
        exit;
    end;

     if not IS_IPTABLES_SQUID_EXISTS(https_port) then begin
          logs.Syslogs('Starting......: Insert routing table HTTPS in iptables configuration... dest:'+https_port);
          fpsystem(SYS.LOCATE_IPTABLES() + ' -A PREROUTING -t nat -p tcp --dport 443 -j REDIRECT --to-port '+https_port);

          if not IS_IPTABLES_SQUID_EXISTS(https_port) then begin
             logs.Syslogs('Starting......: Failed using '+ SYS.LOCATE_IPTABLES() + ' -A PREROUTING -t nat -p tcp --dport 443 -j REDIRECT --to-port '+https_port);
          end;

      end else begin
       logs.Debuglogs('Starting......: Insert routing table HTTPS in iptables already done...');
    end;




end else begin
     logs.Debuglogs('Starting......: Squid, transparent is disabled');

end;

end;

//##############################################################################
function tsquid.IS_IPTABLES_SQUID_EXISTS(listen_port:string):boolean;
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
   tmpstr       :string;
   f            :boolean;
   D:Boolean;
begin
D:=SYS.COMMANDLINE_PARAMETERS('--verbose');
F:=false;
result:=false;
tmpstr:=LOGS.FILE_TEMP();
fpsystem(SYS.LOCATE_IPTABLES() + ' -L -t nat --line-numbers >'+tmpstr + ' 2>&1');
if not FileExists(tmpstr) then begin
   logs.Debuglogs('Starting......: IS_IPTABLES_SQUID_EXISTS failed -> '+tmpstr+' no such file');
   exit;
end;

l:=TstringList.Create;
l.LoadFromFile(tmpstr);
logs.DeleteFile(tmpstr);
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^([0-9]+)\s+REDIRECT\s+tcp.+?dpt:[a-zA-z0-9]+\s+redir\s+ports\s+([0-9]+)';
for i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
       if not F then begin
         if RegExpr.Match[2]=listen_port then begin
            logs.Debuglogs('Starting......: Insert routing table found line '+inttostr(i)+' for port '+listen_port);
            f:=true;
            result:=true;
            RegExpr.free;
            l.free;
            exit;
         end;
       end;

         if f then begin
           if D then logs.Debuglogs('Starting......: delete rounting table number '+RegExpr.Match[1]);
            logs.Outputcmd('iptables -t nat -D PREROUTING '+RegExpr.Match[1]);
            IS_IPTABLES_SQUID_EXISTS(listen_port);
            exit;
         end;

     end else begin
             if D then logs.Debuglogs('Starting......:'+l.Strings[i]+' NO MATCH');
     end;
end;

RegExpr.free;
l.free;
end;
//##############################################################################


function tsquid.GET_LOCAL_PORT():string;
var
   RegExpr      :TRegExpr;


begin
    if DansGuardianEnabled=1 then begin
       result:=DANSGUARDIAN_PORT();
       if length(result)>0 then exit;
    end;
    

   result:=SQUID_GET_CONFIG('http_port');
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='([0-9]+)';
   RegExpr.Exec(result);
   result:=RegExpr.Match[1];


end;

//##############################################################################
function tsquid.GET_SSL_PORT():string;
var
   RegExpr      :TRegExpr;


begin
   result:=SQUID_GET_CONFIG('https_port');
   RegExpr:=TRegExpr.Create;

   RegExpr.Expression:='([0-9\.]+):([0-9]+)';
   if RegExpr.Exec(result) then result:=RegExpr.Match[2];
   RegExpr.Expression:='([0-9]+)';
   RegExpr.Exec(result);
   result:=RegExpr.Match[1];
end;

//##############################################################################



function tsquid.DANSGUARDIAN_PORT():string;
var
   l            :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
begin
result:='';
if not FileExists('/etc/dansguardian/dansguardian.conf') then exit;
l:=TstringList.Create;
l.LoadFromFile('/etc/dansguardian/dansguardian.conf');
RegExpr:=TRegExpr.Create;
RegExpr.Expression:='^filterport.+?([0-9]+)';
for i:=0 to l.Count-1 do begin
      if RegExpr.Exec(l.Strings[i]) then begin
         result:=RegExpr.Match[1];
         break;
      end;
end;

RegExpr.free;
l.free;
end;
//##############################################################################
procedure tsquid.START_SIMPLE();
 var
    pid:string;
    count:integer;
    SYS:Tsystem;
    pidpath:string;
    l:TstringList;
    FileTemp:string;
    options:string;
    http_port:string;
    squidconf:string;
    cmd:string;
    mybinVer:integer;
begin
mybinVer:=SQUID_BIN_VERSION(SQUID_VERSION());
count:=0;
SYS:=Tsystem.Create;
  if not FileExists(SQUID_BIN_PATH()) then begin
     logs.Debuglogs('Starting......: Squid is not installed aborting...');
     exit;
  end;

  if SQUIDEnable=0 then begin
      logs.Debuglogs('Starting......: Squid is disabled aborting...');
      exit;
  end;

  ERROR_FD();
  pid:=SQUID_PID();
  if SYS.PROCESS_EXIST(pid) then begin
     logs.DebugLogs('Starting......: Squid already running with pid ' + pid+ '...');
     if SQUIDEnable=0 then SQUID_STOP();
   exit;
  end;


if DirectoryExists('/var/lib/squidguard') then begin
     logs.DebugLogs('Starting......: Squid apply security permissions on /var/lib/squidguard');
     fpsystem('/bin/chmod -R 755 /var/lib/squidguard');
end;



squidconf:=SQUID_CONFIG_PATH();
http_port:=SQUID_GET_CONFIG('http_port');
options:=' -sYC -a '+http_port +' -f ' +squidconf;
if mybinVer<300000000000 then options:=' -D'+options;
pidpath:=SQUID_GET_CONFIG('pid_filename');
LOGS.DeleteFile(pidpath);
FileTemp:=logs.FILE_TEMP();
logs.DebugLogs('Starting......: Squid binary.....: '+SQUID_BIN_PATH());
logs.DebugLogs('Starting......: Squid config path: '+squidconf);
AS_TRANSPARENT_MODE();
ForceDirectories('/etc/squid3');
if not FileExists('/etc/squid3/malwares.acl') then fpsystem('/bin/touch /etc/squid3/malwares.acl');
if not FileExists('/etc/squid3/squid-block.acl') then fpsystem('/bin/touch /etc/squid3/squid-block.acl');


fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.squid.php --build >' +FileTemp+' 2>&1');
cmd:=SQUID_BIN_PATH() + ' '+options +' >>' +FileTemp+' 2>&1';
logs.Debuglogs('running: '+cmd);
fpsystem(cmd);

 while not SYS.PROCESS_EXIST(SQUID_PID()) do begin
        sleep(100);
        inc(count);
        if count>20 then break;
  end;

 l:=Tstringlist.Create;
 try
    if FileExists(FileTemp) then l.LoadFromFile(FileTemp);
    for count:=0 to l.Count-1 do begin
        logs.DebugLogs('Starting......: Squid '+ L.Strings[count]);
    end;
 finally
    l.free;
 end;
 logs.DeleteFile(FileTemp);

 pid:=SQUID_PID();
  if SYS.PROCESS_EXIST(pid) then begin
   logs.DebugLogs('Starting......: Squid with new pid ' + pid+ '...');
   if FileExists(FileTemp) then LOGS.DeleteFile(FileTemp);
   SQUID_RRD_EXECUTE();
  end else begin
   logs.DebugLogs('Starting......: Squid Failed to start...');
  end;

  SYS.FREE;

end;

//##############################################################################
procedure tsquid.SQUID_START();
 var
    pid:string;
    SYS:Tsystem;
    pidpath:string;
begin
SYS:=Tsystem.Create;
  if not FileExists(SQUID_BIN_PATH()) then begin
     logs.Debuglogs('Starting......: Squid is not installed aborting...');
     exit;
  end;

  if SQUIDEnable=0 then begin
      logs.Debuglogs('Starting......: Squid is disabled aborting...');
      exit;
  end;

 if SYS.isoverloadedTooMuch() then begin
     logs.DebugLogs('Starting......: Squid System is overloaded');
     exit;
end;

  TAIL_START();
  ERROR_FD();
  pid:=SQUID_PID();
  if SYS.PROCESS_EXIST(pid) then begin
     logs.DebugLogs('Starting......: Squid already running with pid ' + pid+ '...');
     if SQUIDEnable=0 then SQUID_STOP();
   exit;
  end;
  //http_port:=SQUID_GET_CONFIG('http_port');
 // options:=' -D -sYC -a '+http_port +' -f ' +SQUID_CONFIG_PATH();
  

  pidpath:=SQUID_GET_CONFIG('pid_filename');
  LOGS.DeleteFile(pidpath);
 // FileTemp:=artica_path+'/ressources/logs/squid.start.daemon';
  
       if not SYS.IsUserExists('squid') then begin
           logs.DebugLogs('Starting......: Squid user "squid" doesn''t exists... reconfigure squid');
           fpsystem(Paramstr(0) + ' -squid-configure');
       end else begin
           logs.DebugLogs('Starting......: Squid user "squid" exists OK');
       end;
  
        logs.DebugLogs('Starting......: Squid binary: '+SQUID_BIN_PATH());



        SQUID_RRD_INIT();
        SQUID_RRD_INSTALL();
        SQUID_VERIFY_CACHE();
        WRITE_INITD();
        fpsystem(SQUID_BIN_PATH() + ' -z');
        START_SIMPLE();

  SYS.free;
end;
//#############################################################################
function tsquid.ldap_auth_path():string;
begin
if FileExists('/usr/lib/squid3/squid_ldap_auth') then exit('/usr/lib/squid3/squid_ldap_auth');
if FileExists('/usr/lib/squid/ldap_auth') then exit('/usr/lib/squid/ldap_auth');
if FileExists('/opt/artica/libexec/squid_ldap_auth') then exit('/opt/artica/libexec/squid_ldap_auth');
end;
//#############################################################################
function tsquid.ntml_auth_path():string;
begin
if FileExists('/usr/bin/ntlm_auth') then exit('/usr/bin/ntlm_auth');
end;
//#############################################################################




procedure tsquid.SQUID_SET_CONFIG(key:string;value:string);
var
   tmp          :TstringList;
   RegExpr      :TRegExpr;
   Found        :boolean;
   i            :integer;
begin
 found:=false;
 if not FileExists(SQUID_CONFIG_PATH()) then exit;
 tmp:=TstringList.Create;
 tmp.LoadFromFile(SQUID_CONFIG_PATH());
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='^' + key;

 for i:=0 to tmp.Count-1 do begin
       if RegExpr.Exec(tmp.Strings[i]) then begin
         found:=true;
         tmp.Strings[i]:=key + chr(9) + value;
         break;
       end;

 end;

 if not found then begin
     tmp.Add(key + chr(9) + value);

 end;
 tmp.SaveToFile(SQUID_CONFIG_PATH());
 tmp.free;

 RegExpr.Free;
end;
//##############################################################################
function tsquid.SQUID_GET_CONFIG(key:string):string;
var
   tmp          :TstringList;
   RegExpr      :TRegExpr;
   i            :integer;
begin

 if not FileExists(SQUID_CONFIG_PATH()) then exit;
 
 tmp:=TstringList.Create;
 tmp.LoadFromFile(SQUID_CONFIG_PATH());
 RegExpr:=TRegExpr.Create;
 RegExpr.Expression:='^' + key+'\s+(.+)';

 for i:=0 to tmp.Count-1 do begin
       if RegExpr.Exec(tmp.Strings[i]) then begin
         result:=RegExpr.Match[1];
         break;
       end;
 end;
 tmp.free;
 RegExpr.Free;
end;
//##############################################################################
PROCEDURE tsquid.SQUID_VERIFY_CACHE();
 var
    FileS    :TstringList;
    RegExpr  :TRegExpr;
    path     :string;
    i        :integer;
    user,group,cache_store_log,cache_log,access_log,coredump_dir,visible_hostname:string;
begin

   user:=SQUID_GET_CONFIG('cache_effective_user');
   group:=SQUID_GET_CONFIG('cache_effective_group');
   cache_store_log:=SQUID_GET_CONFIG('cache_store_log');
   cache_log:=SQUID_GET_CONFIG('cache_log');
   access_log:=SQUID_GET_CONFIG('access_log');
   coredump_dir:=SQUID_GET_CONFIG('coredump_dir');
   visible_hostname:=SQUID_GET_CONFIG('visible_hostname');
   if DirectoryExists('/var/lib/squidguard') then fpsystem('/bin/chown -R squid:squid /var/lib/squidguard');
           
   if Not FileExists(cache_log) then begin
        cache_log:='/var/log/squid/cache.log';
        SQUID_SET_CONFIG('cache_log','/var/log/squid/cache.log');
   end;

   if cache_log='/var/log/squid3' then begin
        cache_log:='/var/log/squid/cache.log';
        SQUID_SET_CONFIG('cache_log','/var/log/squid/cache.log');
   end;
   
    if(length(visible_hostname)=0) then begin
       visible_hostname:=SYS.HOSTNAME_g();
       SQUID_SET_CONFIG('visible_hostname',visible_hostname);
   end;

logs.DebugLogs('Starting......: Hostname ' + visible_hostname+ '...');
logs.DebugLogs('Starting......: Config file ' + SQUID_CONFIG_PATH()+ '...');

PARSE_ALL_CACHES();
      if caches.Count=0 then begin
          SQUID_SET_CONFIG('cache_dir','ufs /var/cache/squid 2000 16 256');
          caches.Add('/var/cache/squid');
      end;

   
   if(length(user)=0) then begin
       SQUID_SET_CONFIG('cache_effective_user','squid');
       user:='squid';
   end;

   if(length(group)=0) then begin
       SQUID_SET_CONFIG('cache_effective_group','squid');
       user:='squid';
   end;
   
if(length(access_log)=0) then begin
       SQUID_SET_CONFIG('access_log','/var/log/squid/access.log');
       access_log:=SQUID_GET_CONFIG('access_log');
   end;
   
if(length(cache_store_log)=0) then begin
       SQUID_SET_CONFIG('cache_store_log','/var/log/squid/store.log');
       cache_store_log:=SQUID_GET_CONFIG('cache_store_log');
   end;
   
if(length(cache_log)=0) then begin
       SQUID_SET_CONFIG('cache_log','/var/log/squid/cache.log');
       cache_log:=SQUID_GET_CONFIG('cache_log');
   end;

if(length(coredump_dir)=0) then begin
       SQUID_SET_CONFIG('coredump_dir','/var/squid/cache');
       coredump_dir:=SQUID_GET_CONFIG('coredump_dir');
   end;
   
   SYS.AddUserToGroup(user,group,'','');

   forcedirectories(SQUID_SPOOL_DIR());
   forcedirectories(ExtractFilePath(access_log));
   forcedirectories(ExtractFilePath(cache_store_log));
   forcedirectories(ExtractFilePath(cache_log));
   forcedirectories(coredump_dir);
   
   for i:=0 to caches.Count-1 do begin
       logs.DebugLogs('Starting......: Checking cache ' + caches.Strings[i]);
       forcedirectories(caches.Strings[i]);
       fpsystem('/bin/chmod 0755 '+caches.Strings[i]);
       SYS.FILE_CHOWN(user,group,caches.Strings[i]);
   end;
       
   
   
   fpsystem('/bin/chmod 0755 '+SQUID_SPOOL_DIR());
   SYS.FILE_CHOWN(user,group,SQUID_SPOOL_DIR());
   SYS.FILE_CHOWN(user,group,ExtractFilePath(access_log));
   SYS.FILE_CHOWN(user,group,ExtractFilePath(cache_store_log));
   SYS.FILE_CHOWN(user,group,ExtractFilePath(cache_log));
   SYS.FILE_CHOWN(user,group,coredump_dir);

   Files:=TstringList.Create;
   Files.LoadFromFile(SQUID_CONFIG_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^cache_dir\s+(.+?)\s+(.+?)\s+';
   For i:=0 to Files.Count-1 do begin
       if RegExpr.Exec(Files.Strings[i]) then begin
           path:=RegExpr.Match[2];
           if not FileExists(path) then begin
              logs.DebugLogs('Starting......: Building new folder ' + path);
              forcedirectories(path);
              fpsystem('/bin/chmod 0755 ' + path);
              SYS.FILE_CHOWN(user,group,path);
           end;
       end;
   end;



end;
//#############################################################################
procedure tsquid.PARSE_ALL_CACHES();
var
   RegExpr      :TRegExpr;
   RegExpr2     :TRegExpr;
   tmp          :TstringList;
   i            :integer;
begin
caches.Clear;
     if not FileExists(SQUID_CONFIG_PATH()) then begin
        LOGS.logs('SQUID_GET_SINGLE_VALUE() -> unable to get squid.conf');
        exit;
     end;

   tmp:=TstringList.Create;
   tmp.LoadFromFile(SQUID_CONFIG_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr2:=TRegExpr.Create;
   RegExpr.Expression:='^cache_dir\s+(.+)';
   RegExpr2.Expression:='(.+?)\s+(.+?)\s+[0-9]+';

 for i:=0 to tmp.Count-1 do begin
      if RegExpr.Exec(tmp.Strings[i]) then begin
          if RegExpr2.Exec(RegExpr.Match[1]) then begin
             caches.Add(RegExpr2.Match[2]);
          end;
      end;
 end;
 
 tmp.free;
 RegExpr.free;
 RegExpr2.free;
end;
//#############################################################################
function tsquid.SQUID_SPOOL_DIR():string;
begin
result:=SQUID_GET_SINGLE_VALUE('coredump_dir');
if length(result)=0 then begin
    if DirectoryExists('/var/spool/squid') then exit('/var/spool/squid');
    if DirectoryExists('/var/spool/squid3') then exit('/var/spool/squid3');
end;

end;
//#############################################################################
function tsquid.SQUID_DETERMINE_PID_PATH():string;
begin
  if FileExists('/opt/artica/sbin/squid') then exit('/var/run/squid.pid');
  if FileExists('/usr/sbin/squid') then exit('/var/run/squid.pid');
  if FileExists('/usr/sbin/squid3')  then exit('/var/run/squid3.pid');
  if FileExists('/usr/local/sbin/squid') then exit('/var/run/squid.pid');
  if FileExists('/sbin/squid') then exit('/var/run/squid.pid');
end;
//#############################################################################
function tsquid.SQUID_CONFIG_PATH():string;
begin
   if FileExists('/etc/squid3/squid.conf') then exit('/etc/squid3/squid.conf');
   if FileExists('/opt/artica/etc/squid.conf') then exit('/opt/artica/etc/squid.conf');
   if FileExists('/etc/squid/squid.conf') then exit('/etc/squid/squid.conf');
end;
//##############################################################################
function tsquid.SQUID_PID():string;
var
   pidpath:string;
begin
    result:='';
    if not FileExists(SQUID_BIN_PATH()) then exit;
    pidpath:=SQUID_GET_CONFIG('pid_filename');

     if length(pidpath)=0 then begin
       SQUID_SET_CONFIG('pid_filename',SQUID_DETERMINE_PID_PATH());
       SQUID_STOP();
       SQUID_START();
       pidpath:=SQUID_GET_CONFIG('pid_filename');
    end;

    if Not FileExists(pidpath) then begin
       exit(SYS.PidByProcessPath(SQUID_BIN_PATH()));
    end;
    result:=SYS.GET_PID_FROM_PATH(pidpath);
    


end;
//##############################################################################
PROCEDURE tsquid.REMOVE();
begin
SQUID_STOP();
fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --remove "squid"');
fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --remove "squid3"');
if FIleExists(SQUID_BIN_PATH()) then logs.DeleteFile(SQUID_BIN_PATH());
logs.DeleteFile('/etc/artica-postfix/versions.cache');
fpsystem('/usr/share/artica-postfix/bin/artica-install --write-versions');
fpsystem('/usr/share/artica-postfix/bin/process1 --force');
end;
//#############################################################################


PROCEDURE tsquid.SQUID_RRD_EXECUTE();
var
   TL            :TstringList;
   http_port     :string;
   script_path   :string;
   l             :TstringList;
   RegExpr       :TRegExpr;
begin
     if not FileExists(SQUID_BIN_PATH()) then exit;
     http_port:=SQUID_GET_SINGLE_VALUE('http_port');
     RegExpr:=TRegExpr.Create;
     RegExpr.Expression:='([0-9]+)';
     if RegExpr.Exec(http_port) then http_port:= RegExpr.Match[1];
     
     if length(http_port)=0 then begin
         Logs.logs('SQUID_RRD_EXECUTE():: unable to stat http_port in squid.conf');
     end;
     script_path:=artica_path+ '/bin/install/rrd/squid-rrd.pl';
     if not FileExists(script_path) then begin
        Logs.logs('SQUID_RRD_EXECUTE():: '+artica_path+ '/bin/install/rrd/squid-rrd.pl');
        exit;
     end;
     
     l:=TstringList.Create;
     l.LoadFromFile(script_path);
     if l.Count<5 then begin
        logs.Syslogs('WARNING SQUID_RRD_EXECUTE is empty...');
        if FileExists(artica_path+ '/bin/install/rrd/squid-rrd.pl.bak') then begin
                   logs.Syslogs('restoring script squid-rrd.pl');
                   logs.OutputCmd('/bin/cp '+artica_path+ '/bin/install/rrd/squid-rrd.pl.bak '+script_path);
                   logs.OutputCmd('/bin/chmod 777 '+script_path);
        end;
     end;
     l.free;
     

     logs.OutputCmd(script_path + ' 127.0.0.1:' + http_port);
     if FileExists(artica_path + '/bin/install/rrd/squid-rrdex.pl') then begin
        ForceDirectories('/opt/artica/share/www/squid/rrd');
        if not FileExists('/etc/cron.d/artica-squidRRD0') then begin
         TL:=TstringList.Create;
         TL.Add('#This generate rrd pictures from squid statistics');
         TL.Add('1,2,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58 * * * * root ' + artica_path + '/bin/install/rrd/squid-rrdex.pl >/dev/null 2>&1');
         Logs.logs('SQUID_RRD_EXECUTE():: Restore /etc/cron.d/artica-squidRRD0');
         TL.SaveToFile('/etc/cron.d/artica-squidRRD0');
         TL.free;
        end;
    end;

     //


end;
//##############################################################################
function tsquid.SQUID_GET_SINGLE_VALUE(key:string):string;
var
   RegExpr      :TRegExpr;
   tmp          :TstringList;
   i            :integer;
begin
     result:='';
     if not FileExists(SQUID_CONFIG_PATH()) then begin
        LOGS.logs('SQUID_GET_SINGLE_VALUE() -> unable to get squid.conf');
        exit;
     end;
   tmp:=TstringList.Create;
   tmp.LoadFromFile(SQUID_CONFIG_PATH());
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='^' + key+'\s+(.+)';


 for i:=0 to tmp.Count-1 do begin
      if RegExpr.Exec(tmp.Strings[i]) then begin
         result:=trim(RegExpr.Match[1]);
         break;
      end;
 end;
    tmp.free;

end;
//##############################################################################
PROCEDURE tsquid.SQUID_RRD_INSTALL();
var
   TL     :TstringList;
   i      :integer;
   RegExpr:TRegExpr;
   script_path:string;
   script_path_bak:string;
begin
  //usr/local/bin/rrdcgi
  script_path:=artica_path+ '/bin/install/rrd/squid-rrd.pl';
  script_path_bak:=artica_path+ '/bin/install/rrd/squid-rrd.bak';


  if not FileExists(script_path) then begin
      if FileExists(script_path_bak) then logs.OutputCmd('/bin/cp ' + script_path_bak + ' ' +  script_path);
  end;

  if not FileExists(script_path) then exit;
  if SYS.FileSize_ko(script_path)<5 then logs.OutputCmd('/bin/cp ' + script_path_bak + ' ' +  script_path);


  TL:=TStringList.Create;
  if not FileExists(script_path) then exit;
  RegExpr:=TRegExpr.Create;

  TL.LoadFromFile(script_path);
  for i:=0 to TL.Count-1 do begin
      RegExpr.Expression:='my \$rrdtool';
      if RegExpr.Exec(TL.Strings[i]) then TL.Strings[i]:='my $rrdtool = "' + SYS.RRDTOOL_BIN_PATH() + '";';
      RegExpr.Expression:='my \$rrd_database_path';
      if RegExpr.Exec(TL.Strings[i]) then TL.Strings[i]:='my $rrd_database_path = "/opt/artica/var/rrd";';
  end;

  TL.SaveToFile(script_path);
  TL.Free;
  fpsystem('/bin/chmod 777 ' + script_path);

end;
//##############################################################################
procedure tsquid.SQUID_STOP();
 var
    pid:string;
    count:integer;
    i:integer;
    binpath:string;
    FileTemp:string;
begin
count:=0;
binpath:=SQUID_BIN_PATH();
SYS.MONIT_DELETE('APP_SQUID');
  if not FileExists(binpath) then exit;
  pid:=SQUID_PID();
  if SYS.PROCESS_EXIST(pid) then begin
   writeln('Stopping Squid...............: ' + pid + ' PID');
   logs.OutputCmd(binpath+' -k kill');

   while SYS.PROCESS_EXIST(pid) do begin
        sleep(200);
        inc(count);
        if count>30 then break;
        pid:=SQUID_PID();
   end;
   
   if SYS.PROCESS_EXIST(pid) then begin
       writeln('Stopping Squid...............: '+pid+' pid timeout, kill it...');
       logs.OutputCmd('/bin/kill -9 '+pid);
   end;

   count:=0;
   while SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        if count>30 then break;
        pid:=SQUID_PID();
   end;



   if SYS.PROCESS_EXIST(pid) then begin
      logs.Debuglogs('SQUID_STOP():: failed to stop squid');
      writeln('Stopping Squid...............: Failed');
      exit;
   end;
   

   writeln('Stopping Squid...............: Success');
end;

for i:=1 to 10 do begin
pid:=SYS.PIDOF(SQUID_BIN_PATH());

if length(pid)>0 then begin
      writeln('Stopping Squid...............: Ghost daemon ' +pid);
      logs.OutputCmd('/bin/kill -9 '+pid);
end else begin
    break;
end;
end;

for i:=1 to 10 do begin
pid:=SYS.PIDOF('/usr/sbin/squid3');
if length(pid)>0 then begin
      writeln('Stopping Squid...............: /usr/sbin/squid3 ' +pid);
      logs.OutputCmd('/bin/kill -9 '+pid);
end else begin
    break;
end;
end;


if not SYS.PROCESS_EXIST(pid) then begin
     writeln('Stopping Squid...............: success stopping Squid daemon');
     writeln('Stopping Squid...............: checking transparent mode...');
     FileTemp:=logs.FILE_TEMP();
     fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.squid.php --build >' +FileTemp+' 2>&1');
     AS_TRANSPARENT_MODE();
     TAIL_STOP();
  end;
end;
//##############################################################################
function tsquid.SQUID_STATUS():string;
var
  pidpath:string;
begin
 if not FileExists(SQUID_BIN_PATH()) then exit;
 SYS.MONIT_DELETE('APP_SQUID');
 pidpath:=logs.FILE_TEMP();
 fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --all-squid >'+pidpath +' 2>&1');
 result:=logs.ReadFromFile(pidpath);
 logs.DeleteFile(pidpath);
end;
//##############################################################################
function tsquid.SQUID_VERSION():string;
var
   tmp            :string;
   RegExpr        :TRegExpr;
   tmpstr         :string;
begin
   result:='';
   if not SYS.COMMANDLINE_PARAMETERS('--squid-version-bin') then result:=SYS.GET_CACHE_VERSION('APP_SQUID');

   if length(result)>2 then exit;
   if not FileExists(SQUID_BIN_PATH()) then exit;
   tmpstr:=logs.FILE_TEMP();
   fpsystem(SQUID_BIN_PATH() + ' -v >'+tmpstr+' 2>&1');
   tmp:=SYS.ReadFileIntoString(tmpstr);
   LOGS.DeleteFile(tmpstr);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='Squid Cache: Version ([0-9\.A-Za-z]+)';
   if RegExpr.Exec(tmp) then result:=RegExpr.Match[1];
   RegExpr.Free;
   SYS.SET_CACHE_VERSION('APP_SQUID',result);

end;
//#############################################################################
function tsquid.SQUID_BIN_VERSION(version:string):int64;
var
   tmp            :string;
   tmp2           :string;
   RegExpr        :TRegExpr;
begin
   result:=0;
   RegExpr:=TRegExpr.Create;
   //3.0.STABLE13-20090214
   RegExpr.Expression:='([0-9]+)\.([0-9]+)\.STABLE([0-9\-]+)';
   if RegExpr.Exec(version) then begin
     tmp:=RegExpr.Match[1]+RegExpr.Match[2];
     tmp2:=RegExpr.Match[3];
     tmp2:=trim(AnsiReplaceText(tmp2,'-',''));
     if length(tmp2)=1 then tmp2:='0'+tmp2;
     if length(tmp2)<10 then tmp2:=tmp2+'00000000';
     tmp:=tmp+tmp2;
     RegExpr.Free;
     if not TryStrToInt64(tmp,result) then writeln('int64 failed');
     exit;
   end;

   RegExpr.Expression:='([0-9]+)\.([0-9]+)\.([0-9]+)';
   if RegExpr.Exec(version) then begin
      tmp:=RegExpr.Match[1]+RegExpr.Match[2];
      tmp2:=RegExpr.Match[3];
      if length(tmp2)=1 then tmp2:='0'+tmp2;
      if length(tmp2)<10 then tmp2:=tmp2+'00000000';
      tmp:=tmp+tmp2;
      if not TryStrToInt64(tmp,result) then writeln('int64 failed');
      RegExpr.Free;
      exit;
   end;



end;
//#############################################################################

PROCEDURE tsquid.SQUID_RRD_INIT();
var
   TL     :TstringList;
   i      :integer;
   stop   :boolean;
   RegExpr:TRegExpr;
   script_path:string;
begin
     if not FileExists(SQUID_BIN_PATH()) then exit;
     stop:=true;
     script_path:=artica_path+ '/bin/install/rrd/squid-builder.sh';

     if not FileExists(artica_path+ '/bin/install/rrd/squid-builder.info') then begin
        Logs.logs('SQUID_RRD_INIT():: unable to stat '+artica_path+ '/bin/install/rrd/squid-builder.info');
        exit;
     end;

     if not FileExists(script_path) then begin
        Logs.logs('SQUID_RRD_INIT():: unable to stat '+script_path);
        exit;
     end;


     TL:=TStringList.Create;
     TL.LoadFromFile(artica_path+ '/bin/install/rrd/squid-builder.info');

     For i:=0 to TL.Count-1 do begin
          if not FileExists('/opt/artica/var/rrd/' + TL.Strings[i]) then begin
             stop:=false;
             break;
          end;
     end;

     SQUID_RRD_INSTALL();
     if stop=true then exit;
     Logs.Debuglogs('SQUID_RRD_INIT():: Set settings');
     RegExpr:=TRegExpr.Create;


     TL.LoadFromFile(script_path);

     For i:=0 to TL.Count-1 do begin
         RegExpr.Expression:='PATH="(.+)';
         if RegExpr.Exec(TL.Strings[i]) then TL.Strings[i]:='PATH="/opt/artica/var/rrd"';

         RegExpr.Expression:='RRDTOOL="(.+)';
         if RegExpr.Exec(TL.Strings[i]) then TL.Strings[i]:='RRDTOOL="' + SYS.RRDTOOL_BIN_PATH()+'"';

     end;

    TL.SaveToFile(script_path);
    logs.DebugLogs('Starting......: Creating and set rrd parameters for squid OK');
    TL.Free;
    fpsystem('/bin/chmod 777 ' + script_path);
    forcedirectories('/opt/artica/var/rrd');
    fpsystem(script_path);


end;
//##############################################################################
function tsquid.ReadFileIntoString(path:string):string;
var
   List:TstringList;
begin

      if not FileExists(path) then begin
        exit;
      end;

      List:=Tstringlist.Create;
      List.LoadFromFile(path);
      result:=trim(List.Text);
      List.Free;
end;
//##############################################################################
function tsquid.COMMANDLINE_PARAMETERS(FoundWhatPattern:string):boolean;
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
function tsquid.get_INFOS(key:string):string;
var value:string;
begin
GLOBAL_INI:=TIniFile.Create('/etc/artica-postfix/artica-postfix.conf');
value:=GLOBAL_INI.ReadString('INFOS',key,'');
result:=value;
GLOBAL_INI.Free;
end;
//#############################################################################
procedure tsquid.WRITE_INITD();
var
   l:TstringList;
   initPath:string;
begin

l:=TstringList.Create;
initPath:=SQUID_INIT_PATH();
if length(initPath)=0 then initPath:='/etc/init.d/squid3';

l.add('#! /bin/sh');
l.add('#');
l.add('# squid3		Startup script for the SQUID HTTP proxy-cache.');
l.add('#');
l.add('# Version:	@(#)squid3.rc  1.0  07-Jul-2006  luigi@debian.org');
l.add('#');
l.add('### BEGIN INIT INFO');
l.add('# Provides:          squid');
l.add('# Required-Start:    $local_fs $network');
l.add('# Required-Stop:     $local_fs $network');
l.add('# Should-Start:      $named');
l.add('# Should-Stop:       $named');
l.add('# Default-Start:     2 3 4 5');
l.add('# Default-Stop:      0 1 6');
l.add('# Short-Description: Squid HTTP Proxy');
l.add('### END INIT INFO');
l.add('');
l.add('PATH=/bin:/usr/bin:/sbin:/usr/sbin');
l.add('');
l.add('');
l.add('start () {');
l.add('	/etc/init.d/artica-postfix start squid');
l.add('}');
l.add('');
l.add('stop () {');
l.add('      /etc/init.d/artica-postfix stop squid');
l.add('}');
l.add('');
l.add('case "$1" in');
l.add('    start)');
l.add('	/etc/init.d/artica-postfix start squid');
l.add('	;;');
l.add('    stop)');
l.add('	/etc/init.d/artica-postfix stop squid');
l.add('	;;');
l.add('    reload|force-reload)');
l.add('	/etc/init.d/artica-postfix stop squid');
l.add('	/etc/init.d/artica-postfix start squid');
l.add('	;;');
l.add('    restart)');
l.add('	/etc/init.d/artica-postfix stop squid');
l.add('	/etc/init.d/artica-postfix start squid');
l.add('	;;');
l.add('    *)');
l.add('	echo "Usage: '+initPath+' {start|stop|reload|force-reload|restart}"');
l.add('	exit 3');
l.add('	;;');
l.add('esac');
l.add('');
l.add('exit 0');

l.SaveToFile(initPath);
l.free;


end;

//#############################################################################
procedure tsquid.SARG_EXECUTE();
var access_log,cmd:string;

begin
  if not FileExists('/usr/bin/sarg') then begin
   logs.DebugLogs('Starting......: SARG Is not installed');
   exit;
end;

if SQUIDEnable=0 then begin
    logs.DebugLogs('Starting......: SARG Squid is disabled globally...');
    exit;
end;


  SARG_CONFIG();

if FileExists('/usr/sbin/dansguardian') then begin
   if DansGuardianEnabled=1 then begin
     access_log:='/var/log/dansguardian/access.log';
   end else begin
       access_log:='/var/log/squid/access.log';
   end;
end else begin
    access_log:='/var/log/squid/access.log';
end;

  if not FileExists('/etc/squid3/exclude_codes') then logs.OutputCmd('/etc/squid3/exclude_codes');

  cmd:=SYS.EXEC_NICE()+'/usr/bin/sarg -f /etc/squid3/sarg.conf -l '+access_log+' -o /opt/artica/share/www/squid/sarg &';
  logs.DebugLogs(cmd);
  fpsystem(cmd);
end;
//#############################################################################
function tsquid.SARG_SCAN():string;
var
   RegExpr        :TRegExpr;
   l:Tstringlist;
   i:Integer;

begin
  if not FileExists('/usr/bin/sarg') then begin
   logs.DebugLogs('Starting......: SARG Is not installed');
   exit;
end;
  RegExpr:=TRegExpr.Create;
  SYS.DirDir('/opt/artica/share/www/squid/sarg');
  l:=Tstringlist.Create;
  RegExpr.Expression:='(.+?)-(.+)';
  for i:=0 to SYS.DirListFiles.Count-1 do begin
      if SYS.DirListFiles.Strings[i]='sarg-php' then continue;
      if RegExpr.Exec(SYS.DirListFiles.Strings[i]) then  begin
            l.Add(SYS.DirListFiles.Strings[i]);
      end;
  end;
    result:=l.Text;
    l.Free;
    RegExpr.free;

end;
//#############################################################################


procedure tsquid.SARG_CONFIG();
var
   l:TstringList;
begin

if not FileExists('/usr/bin/sarg') then begin
   logs.DebugLogs('Starting......: SARG Is not installed');
   exit;
end;
l:=TstringList.Create;
l.add('language English');

l.add('graphs yes');
l.add('graph_days_bytes_bar_color orange');
l.add('title "Squid User Access Reports"');
l.add('font_face Tahoma,Verdana,Arial');
l.add('header_color darkblue');
l.add('header_bgcolor blanchedalmond');
l.add('font_size 9px');
l.add('header_font_size 9px');
l.add('title_font_size 11px');
l.add('background_color white');
l.add('text_color #000000');
l.add('text_bgcolor lavender');
l.add('title_color green');
l.add('logo_image none');
l.add('logo_text ""');
l.add('logo_text_color #000000');
l.add('image_size 80 45');
l.add('background_image none');
l.add('password none');
l.add('temporary_dir /tmp');
l.add('output_dir /usr/share/artica-postfix/sarg/reports');
l.add('output_email none');
l.add('resolve_ip yes');
l.add('user_ip no');
l.add('topuser_sort_field BYTES reverse');
l.add('user_sort_field BYTES reverse');
l.add('exclude_users none');
l.add('exclude_hosts none');
l.add('useragent_log none');
l.add('date_format u');
l.add('per_user_limit none');
l.add('lastlog 0');
l.add('remove_temp_files yes');
l.add('index yes');
l.add('index_tree file');
l.add('overwrite_report no');
l.add('records_without_userid ip');
l.add('use_comma no');
l.add('#mail_utility mailx');
l.add('topsites_num 100');
l.add('topsites_sort_order CONNECT D');
l.add('index_sort_order D');
l.add('#exclude_codes /etc/squid3/exclude_codes');
l.add('#replace_index <?php echo str_replace(".", "_", $REMOTE_ADDR); echo ".html"; ?>');
l.add('#max_elapsed 28800000');
l.add('# 8 Hours');
l.add('report_type topusers topsites sites_users users_sites date_time denied auth_failures site_user_time_date downloads');
l.add('usertab none');
l.add('#long_url no');
l.add('#date_time_by elap');
l.add('charset Latin1');
l.add('user_invalid_char "&/"');
l.add('privacy no');
l.add('privacy_string "***.***.***.***"');
l.add('privacy_string_color blue');
l.add('include_users none');
l.add('exclude_string none');
l.add('show_successful_message yes');
l.add('show_read_statistics yes');
l.add('topuser_fields NUM DATE_TIME USERID CONNECT BYTES %BYTES IN-CACHE-OUT USED_TIME MILISEC %TIME TOTAL AVERAGE');
l.add('user_report_fields CONNECT BYTES %BYTES IN-CACHE-OUT USED_TIME MILISEC %TIME TOTAL AVERAGE');
l.add('bytes_in_sites_users_report no');
l.add('topuser_num 0');
l.add('site_user_time_date_type table');
l.add('datafile none');
l.add('datafile_delimiter ";"');
l.add('datafile_fields user;date;time;url;connect;bytes;in_cache;out_cache;elapsed');
l.add('datafile ip');
l.add('weekdays 0-6');
l.add('hours 0-23');

if FileExists('/usr/sbin/dansguardian') then begin
   if DansGuardianEnabled=1 then begin
     logs.DebugLogs('Starting......: SARG will scan dansguardian');
     l.add('dansguardian_conf /etc/dansguardian/dansguardian.conf');
     l.add('dansguardian_ignore_date off');
     l.add('access_log /var/log/dansguardian/access.log');
   end else begin
       l.add('access_log /var/log/squid/access.log');
   end;
end else begin
    l.add('access_log /var/log/squid/access.log');
end;
l.add('squidguard_conf none');
l.add('squidguard_ignore_date off');
l.add('#squidguard_log_format #year#-#mon#-#day# #hour# #tmp#/#list#/#tmp#/#tmp#/#url#/#tmp# #ip#/#tmp# #user# #end#');
l.add('show_sarg_info yes');
l.add('show_sarg_logo no');
l.add('parsed_output_log /var/log/squid');
l.add('parsed_output_log_compress /bin/gzip');
l.add('displayed_values abbreviation');
l.add('#authfail_report_limit 10');
l.add('#denied_report_limit 10');
l.add('#siteusers_report_limit 0');
l.add('#squidguard_report_limit 10');
l.add('#dansguardian_report_limit 10');
l.add('#user_report_limit 10');
l.add('#user_report_limit 50');
l.add('#www_document_root /var/www/html');
l.add('block_it none');
l.add('#external_css_file none');
l.add('user_authentication no');
l.add('# AuthUserFile /usr/local/sarg/passwd');
l.add('# AuthName "SARG, Restricted Access"');
l.add('# AuthType Basic');
l.add('# Require user admin %u');
l.add('download_suffix "zip,arj,bzip,gz,ace,doc,iso,adt,bin,cab,com,dot,drv$,lha,lzh,mdb,mso,ppt,rtf,src,shs,sys,exe,dll,mp3,avi,mpg,mpeg"');
l.add('ulimit 20000');
l.add('ntlm_user_format domainname+username');
l.add('realtime_refresh_time 3');
l.add('realtime_access_log_lines 1000');
l.add('realtime_types GET,PUT,CONNECT  ');
l.add('realtime_unauthenticated_records: show');
l.add('byte_cost 0.01 50000000');
l.add('squid24 off');
logs.DebugLogs('Starting......: SARG settings default settings');
logs.WriteToFile(l.Text, '/etc/squid3/sarg.conf');
end;
//#############################################################################
function tsquid.SARG_VERSION():string;
var
   tmp            :string;
   RegExpr        :TRegExpr;
   l:Tstringlist;
   i:Integer;

begin
   result:='';
  tmp:=logs.FILE_TEMP();
  result:=SYS.GET_CACHE_VERSION('APP_SARG');
  if length(result)>0 then exit;
   if not FileExists('/usr/bin/sarg') then exit;
   fpsystem('/usr/bin/sarg -v >'+tmp+' 2>&1');

   l:=Tstringlist.Create;
   l.LoadFromFile(tmp);
   LOGS.DeleteFile(tmp);
   RegExpr:=TRegExpr.Create;
   RegExpr.Expression:='SARG Version:\s+([0-9\.A-Za-z]+)';
   For i:=0 to l.Count-1 do begin
   if RegExpr.Exec(l.Strings[i]) then begin
      result:=RegExpr.Match[1];
      SYS.SET_CACHE_VERSION('APP_SARG',result);
   end;
   end;

   RegExpr.Free;
   l.free;


end;
//#############################################################################
function tsquid.TAIL_PID():string;
var
   pid:string;
begin

if FileExists('/etc/artica-postfix/exec.squid-tail.php.pid') then begin
   pid:=SYS.GET_PID_FROM_PATH('/etc/artica-postfix/exec.squid-tail.php.pid');
   logs.Debuglogs('DANSGUARDIAN_TAIL_PID /etc/artica-postfix/exec.squid-tail.php.pid='+pid);
   if SYS.PROCESS_EXIST(pid) then result:=pid;
   exit;
end;


result:=SYS.PIDOF_PATTERN(TAIL_STARTUP);
logs.Debuglogs(TAIL_STARTUP+' pid='+pid);
end;
//#####################################################################################
procedure tsquid.TAIL_START();
var
   pid:string;
   pidint:integer;
   log_path:string;
   count:integer;
   cmd:string;
   CountTail:Tstringlist;
begin

if not FileExists(SQUID_BIN_PATH()) then begin
   logs.Debuglogs('Starting......: squid RealTime log squid is not installed');
   exit;
end;


if DansGuardianEnabled=1 then begin
    logs.Debuglogs('Starting......: squid RealTime log DansGuardian is enabled, switch to dansguardian mode');
    TAIL_STOP();
    exit;
end;

pid:=TAIL_PID();
if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: squid RealTime log already running with pid '+pid);
      if DansGuardianEnabled=1 then TAIL_STOP();
      CountTail:=Tstringlist.Create;
      CountTail.AddStrings(SYS.PIDOF_PATTERN_PROCESS_LIST('/usr/bin/tail -f -n 0 /var/log/dansguardian/access.log'));
      logs.DebugLogs('Starting......: squid RealTime log process number:'+IntToStr(CountTail.Count));
      if CountTail.Count>3 then fpsystem('/etc/init.d/artica-postfix restart squid-tail');
      CountTail.free;
      exit;
end;
log_path:='/var/log/squid/access.log';

if not FileExists(log_path) then begin
   logs.DebugLogs('Starting......: squid RealTime log stats, unable to stats logfile');
   exit;
end;
TAIL_STOP();
logs.DebugLogs('Starting......: squid RealTime log path: '+log_path);

pid:=SYS.PIDOF_PATTERN('/usr/bin/tail -f -n 0 '+log_path);
count:=0;
pidint:=0;
      while SYS.PROCESS_EXIST(pid) do begin
          if count>0 then break;
          if not TryStrToInt(pid,pidint) then continue;
          logs.DebugLogs('Starting......: squid RealTime log stop tail pid '+pid);
          if pidint>0 then  fpsystem('/bin/kill '+pid);
          sleep(200);
          pid:=SYS.PIDOF_PATTERN('/usr/bin/tail -f -n 0 '+log_path);
          inc(count);
      end;

cmd:='/usr/bin/tail -f -n 0 '+log_path+'|'+TAIL_STARTUP+' >>/var/log/artica-postfix/squid-logger-start.log 2>&1 &';
logs.Debuglogs(cmd);
fpsystem(cmd);
pid:=TAIL_PID();
count:=0;
while not SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        if count>40 then begin
           logs.DebugLogs('Starting......: squid RealTime log (timeout)');
           break;
        end;
        pid:=TAIL_PID();
  end;

pid:=TAIL_PID();

if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: squid RealTime log success with pid '+pid);
      exit;
end else begin
    logs.DebugLogs('Starting......: squid RealTime log failed');
end;
end;
//#####################################################################################
function tsquid.TAIL_STATUS():string;
var
pidpath:string;
begin
   if not FileExists(SQUID_BIN_PATH()) then exit;
   SYS.MONIT_DELETE('APP_ARTICA_SQUID_TAIL');
   pidpath:=logs.FILE_TEMP();
   fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --squid-tail >'+pidpath +' 2>&1');
   result:=logs.ReadFromFile(pidpath);
   logs.DeleteFile(pidpath);
end;
//#####################################################################################
procedure tsquid.TAIL_STOP();
var
   pid:string;
   pidint,i:integer;
   count:integer;
   CountTail:Tstringlist;
begin
pid:=TAIL_PID();
if not SYS.PROCESS_EXIST(pid) then begin
      writeln('Stopping squid RealTime log: Already stopped');
      CountTail:=Tstringlist.Create;
      try
         CountTail.AddStrings(SYS.PIDOF_PATTERN_PROCESS_LIST('/usr/bin/tail -f -n 0 /var/log/squid/access.log'));
         writeln('Stopping squid RealTime log: Tail processe(s) number '+IntToStr(CountTail.Count));
      except
        logs.Debuglogs('Stopping squid RealTime log: fatal error on SYS.PIDOF_PATTERN_PROCESS_LIST() function');
      end;

      count:=0;
     for i:=0 to CountTail.Count-1 do begin;
          pid:=CountTail.Strings[i];
          if count>100 then break;
          if not TryStrToInt(pid,pidint) then continue;
          writeln('Stopping squid RealTime log: Stop tail pid '+pid);
          if pidint>0 then  fpsystem('/bin/kill '+pid);
          sleep(100);
          inc(count);
      end;
      exit;
end;

writeln('Stopping squid RealTime log: Stopping pid '+pid);
fpsystem('/bin/kill '+pid);

pid:=TAIL_PID();
if not SYS.PROCESS_EXIST(pid) then begin
      writeln('Stopping squid RealTime log: Stopped');
end;


CountTail:=Tstringlist.Create;
CountTail.AddStrings(SYS.PIDOF_PATTERN_PROCESS_LIST('/usr/bin/tail -f -n 0 /var/log/squid/access.log'));
writeln('Stopping squid RealTime log: Tail processe(s) number '+IntToStr(CountTail.Count));
count:=0;
     for i:=0 to CountTail.Count-1 do begin;
          pid:=CountTail.Strings[i];
          if count>100 then break;
          if not TryStrToInt(pid,pidint) then continue;
          writeln('Stopping squid RealTime log: Stop tail pid '+pid);
          if pidint>0 then  fpsystem('/bin/kill '+pid);
          sleep(100);
          inc(count);
      end;


end;
//####################################################################################
function  tsquid.PROXY_PAC_PID():string;
begin
result:=SYS.GET_PID_FROM_PATH('/var/run/proxypac.pid');
end;
//####################################################################################
procedure tsquid.PROXY_PAC_START();
var
   pid:string;
   count:integer;
begin

if not FileExists(SQUID_BIN_PATH()) then begin
   logs.Debuglogs('Starting......: proxy.pac service, squid is not installed');
   exit;
end;


if SquidEnableProxyPac=0 then begin
   logs.Debuglogs('Starting......: proxy.pac service is disabled');
   PROXY_PAC_STOP();
   exit;
end;


pid:=PROXY_PAC_PID();
if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: proxy.pac service log already running with pid '+pid);
      exit;
end;

  logs.DebugLogs('Starting......: proxy.pac service');
 fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.proxy.pac.php');
 logs.OutputCmd(SYS.LOCATE_GENERIC_BIN('lighttpd')+ ' -f /etc/lighttpd/proxypac.conf');

pid:=PROXY_PAC_PID();
count:=0;
while not SYS.PROCESS_EXIST(pid) do begin
        sleep(100);
        inc(count);
        if count>40 then begin
           logs.DebugLogs('Starting......: proxy.pac service (timeout)');
           break;
        end;
        pid:=PROXY_PAC_PID();
  end;

pid:=PROXY_PAC_PID();

if SYS.PROCESS_EXIST(pid) then begin
      logs.DebugLogs('Starting......: proxy.pac service success with pid '+pid);
      exit;
end else begin
    logs.DebugLogs('Starting......: proxy.pac service failed');
end;

end;
//####################################################################################
procedure tsquid.PROXY_PAC_STOP();
var
   pid:string;
   count:integer;
begin
if not FileExists(SQUID_BIN_PATH()) then begin
   writeln('Stopping proxy.pac service...: squid is not installed');
   exit;
end;
   pid:=PROXY_PAC_PID();

   if not sys.PROCESS_EXIST(pid) then begin
       writeln('Stopping proxy.pac service...: Already stopped');
       exit;
   end;
   writeln('Stopping proxy.pac service...: PID '+pid);
   fpsystem('/bin/kill '+ pid);
   count:=0;
  while sys.PROCESS_EXIST(pid) do begin
      sleep(100);
      fpsystem('/bin/kill '+ pid);
      inc(count);
      if count>50 then begin
         writeln('Stopping proxy.pac service...: time-out');
         logs.OutputCmd('/bin/kill -9 ' + pid);
         break;
      end;
      pid:=PROXY_PAC_PID();
  end;
pid:=PROXY_PAC_PID();
   if not sys.PROCESS_EXIST(pid) then begin
       writeln('Stopping proxy.pac service...: stopped');
       exit;
   end;
   writeln('Stopping proxy.pac service...: failed');
end;
//##############################################################################

end.
