unit saslauthd;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,Process,logs,unix,RegExpr in 'RegExpr.pas',zsystem,
    cyrus        in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/cyrus.pas';



  type
  tsaslauthd=class


private
     LOGS:Tlogs;
     SYS:TSystem;
     artica_path:string;
     CCYRUS:Tcyrus;
     EnableVirtualDomainsInMailBoxes:integer;
     procedure CHANGE_INITD();



public
    procedure   Free;
    constructor Create(const zSYS:Tsystem);
    procedure   START();
    function    SASLAUTHD_PID():string;
    procedure   STOP();
    function    VERSION():string;
    function    STATUS():string;
    function    SASLAUTHD_PATH():string;
    function    SASLAUTHD_INITD_PATH():string;
    function    PID_PATH():string;
END;

implementation

constructor tsaslauthd.Create(const zSYS:Tsystem);
begin
       forcedirectories('/etc/artica-postfix');
       LOGS:=tlogs.Create();
       SYS:=zSYS;
       CCYRUS:=Tcyrus.Create(SYS);
       EnableVirtualDomainsInMailBoxes:=0;
       
       if not TryStrToInt(SYS.GET_INFO('EnableVirtualDomainsInMailBoxes'),EnableVirtualDomainsInMailBoxes) then begin
          EnableVirtualDomainsInMailBoxes:=0;
       end;

       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tsaslauthd.free();
begin
    logs.Free;
end;
//##############################################################################
function tsaslauthd.SASLAUTHD_PATH():string;
begin
if FileExists('/usr/sbin/saslauthd') then exit('/usr/sbin/saslauthd');
if FIleExists('/opt/artica/bin/saslauthd') then exit('/opt/artica/bin/saslauthd');
end;
 //#############################################################################
function tsaslauthd.SASLAUTHD_INITD_PATH():string;
begin
    if FileExists('/etc/init.d/saslauthd') then exit('/etc/init.d/saslauthd');
end;
 //#############################################################################
procedure tsaslauthd.STOP();
begin
if not FileExists(SASLAUTHD_PATH()) then begin
   writeln('Stopping SaslAuthd...........: Not installed');
   exit;
end;
if SYS.PROCESS_EXIST(SASLAUTHD_PID()) then begin
   writeln('Stopping SaslAuthd...........: ' + SASLAUTHD_PID() + ' PID..');
   fpsystem('/bin/kill ' + SASLAUTHD_PID());
end else begin
   writeln('Stopping SaslAuthd...........: Already stopped');
end;

CHANGE_INITD();
end;
 //##############################################################################

procedure tsaslauthd.START();
var
   count:integer;
   mechanism:string;
   moinsr:string;
   cmd:string;
   ldap_search_base:string;
   ldap_search_base_conf:string;
begin
   if not FileExists(SASLAUTHD_PATH()) then begin
      logs.Debuglogs('SASLAUTHD_PATH() return null, aborting there is no saslauthd binary here...');
      exit;
   end;
   moinsr:='';

if SYS.PROCESS_EXIST(SASLAUTHD_PID()) then begin
   logs.DebugLogs('Starting......: saslauthd already running using PID ' +SASLAUTHD_PID()+ '...');
   exit;
end;
   forceDirectories('/var/run/saslauthd');
   logs.DebugLogs('Starting......: Configure cyrus...');
   SYS.TEST_MECHANISM();
   CHANGE_INITD();

   ldap_search_base:='dc=organizations,'+CCYRUS.ldapserver.suffix;
   ldap_search_base_conf:=CCYRUS.SASLAUTHD_GET('ldap_search_base');
   if ldap_search_base<>ldap_search_base_conf then begin
        logs.DebugLogs('Starting......: saslauthd corrupted ldap_search_base token "'+ldap_search_base_conf+'", writting configuration');
        CCYRUS.SASLAUTHD_CONFIGURE();
   end;


    mechanism:=SYS.GET_ENGINE('MECHANISM');
    if length(mechanism)=0 then mechanism:='ldap';
    if EnableVirtualDomainsInMailBoxes=1 then begin
       moinsr:='-r ';
       logs.DebugLogs('Starting......: saslauthd enable authentification for multi-domains');
    end;
    
       logs.DebugLogs('Starting......: saslauthd authentification "'+mechanism+'"');
       cmd:=SASLAUTHD_PATH() + ' '+moinsr+' -a ' +mechanism+' -c -m /var/run/saslauthd -n 5';
       logs.OutputCmd(cmd);
       count:=0;
        while not SYS.PROCESS_EXIST(SASLAUTHD_PID()) do begin
              sleep(150);
              inc(count);
              if count>100 then begin
                 logs.DebugLogs('Starting......: saslauthd daemon. (timeout!!!)');
                 break;
              end;
        end;
   if not SYS.PROCESS_EXIST(SASLAUTHD_PID()) then begin
       logs.DebugLogs('Starting......: saslauthd daemon. (failed!!!)');
   end else begin
       logs.DebugLogs('Starting......: saslauthd daemon. PID '+SASLAUTHD_PID());
   end;

end;
//##############################################################################
function tsaslauthd.VERSION():string;
var
    RegExpr:TRegExpr;
    FileDatas:TStringList;
    i:integer;
begin
if not FileExists(CCYRUS.SASLAUTHD_PATH()) then exit;
fpsystem(CCYRUS.SASLAUTHD_PATH()+' -v >/opt/artica/logs/saslauth.tmp 2>&1');
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='^saslauthd\s+([0-9\.]+)';
    FileDatas:=TStringList.Create;
    FileDatas.LoadFromFile('/opt/artica/logs/saslauth.tmp');
    for i:=0 to FileDatas.Count-1 do begin
        if RegExpr.Exec(FileDatas.Strings[i]) then begin
             result:=RegExpr.Match[1];
             break;
        end;
    end;
             RegExpr.free;
             FileDatas.Free;

end;
//#############################################################################
function tsaslauthd.STATUS():string;
var
pidpath:string;
begin
   SYS.MONIT_DELETE('APP_SASLAUTHD');
   pidpath:=logs.FILE_TEMP();
   fpsystem(SYS.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.status.php --saslauthd >'+pidpath +' 2>&1');
   result:=logs.ReadFromFile(pidpath);
   logs.DeleteFile(pidpath);
end;
//#########################################################################################
function tsaslauthd.PID_PATH():string;
begin
  if FileExists('/var/run/saslauthd/saslauthd.pid') then exit('/var/run/saslauthd/saslauthd.pid');
  if FileExists('/var/run/saslauthd.pid') then exit('/var/run/saslauthd.pid');
  if FileExists('/var/run/saslauthd/saslauthd.pid') then exit('/var/run/saslauthd/saslauthd.pid');
end;
//#########################################################################################

 function tsaslauthd.SASLAUTHD_PID():string;
var
   conffile:string;
   RegExpr:TRegExpr;
   FileData:TStringList;
   i:integer;
begin
   result:='0';
   conffile:=PID_PATH();
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
procedure tsaslauthd.CHANGE_INITD();
var
l:TstringList;
begin
if not FileExists(SASLAUTHD_INITD_PATH()) then exit;
l:=TstringList.Create;
l.Add('#!/bin/sh');
l.Add('#Begin /etc/init.d/artica-postfix');
l.Add('case "$1" in');
l.Add(' start)');
l.Add('    /usr/share/artica-postfix/bin/artica-install start saslauthd $3');
l.Add('    ;;');
l.Add('');
l.Add('  stop)');
l.Add('    /usr/share/artica-postfix/bin/artica-install stop saslauthd $3');
l.Add('    ;;');
l.Add('');
l.Add(' restart)');
l.Add('     /usr/share/artica-postfix/bin/artica-install stop saslauthd $3');
l.Add('     sleep 3');
l.Add('     /usr/share/artica-postfix/bin/artica-install start saslauthd $3');
l.Add('    ;;');
l.Add('');
l.Add('  *)');
l.Add('    echo "Usage: $0 {start|stop|restart} (debug or --verbose for more infos)"');
l.Add('    exit 1');
l.Add('    ;;');
l.Add('esac');
l.Add('exit 0');
l.SaveToFile(SASLAUTHD_INITD_PATH());
l.free;
end;
//#############################################################################

end.
