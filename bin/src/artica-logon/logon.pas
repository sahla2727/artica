unit logon;

{$MODE DELPHI}
{$LONGSTRINGS ON}

interface

uses
    Classes, SysUtils,variants,strutils,IniFiles, Process,md5,logs,unix,RegExpr in 'RegExpr.pas',zsystem,lighttpd,tcpip,openldap;



  type
  tlogon=class


private
     LOGS:Tlogs;
     D:boolean;
     GLOBAL_INI:TiniFIle;
     SYS:TSystem;
     artica_path:string;                      
     ldap:Topenldap;
public
    procedure   Free;
    constructor Create();
    procedure Menu();
    procedure webaccess();
    procedure credentials();
    procedure ChangeIP();


END;

implementation

constructor tlogon.Create();
begin
       forcedirectories('/etc/artica-postfix');
       SYS:=Tsystem.Create;
       LOGS:=tlogs.Create();
       D:=LOGS.COMMANDLINE_PARAMETERS('debug');




       if not DirectoryExists('/usr/share/artica-postfix') then begin
              artica_path:=ParamStr(0);
              artica_path:=ExtractFilePath(artica_path);
              artica_path:=AnsiReplaceText(artica_path,'/bin/','');

      end else begin
          artica_path:='/usr/share/artica-postfix';
      end;
end;
//##############################################################################
procedure tlogon.free();
begin
    logs.Free;
end;
//##############################################################################
procedure tlogon.Menu();
var
   a:string;
   lighttp:Tlighttpd;
   lightstatus:string;
   port,uris:string;
    slighttpd:Tlighttpd;
begin
fpsystem('clear');
lighttp:=Tlighttpd.Create(SYS);
writeln('########################################################');
writeln('###                                                  ###');
writeln('###             Artica version ' + SYS.ARTICA_VERSION()+'');
writeln('###                                                  ###');
writeln('########################################################');
writeln('');

   if not SYS.PROCESS_EXIST(lighttp.LIGHTTPD_PID()) then begin
      lightstatus:='lighttpd is stopped !';

   end else  begin
//     lightstatus:='lighttpd daemon is running using '+IntToStr(SYS.PROCESS_MEMORY(lighttp.LIGHTTPD_PID()))+' Kb memory';
       slighttpd:=Tlighttpd.Create(SYS);
       port:=slighttpd.LIGHTTPD_LISTEN_PORT();
       uris:=SYS.txt_uris(port);
       writeln(uris);
       writeln('');
   end;

writeln('Menu :');
writeln('');
writeln('[W]..... How to access to the Artica Web interface ?');
writeln('[U]..... Global Administrator Username  & password');
if FileExists('/usr/sbin/dpkg-reconfigure') then begin
   // writeln('[L]..... Configure the system language');
end;

writeln('[Q]..... Exit and enter to the system');
writeln('');
writeln('');
writeln(lightstatus);
writeln('Your command: ');
readln(a);

a:=UpperCase(a);

if a='W' then begin
   webaccess();
   Menu();
   exit;
end;
if a='U' then begin
   credentials();
   Menu();
   exit;
end;

if a='L' then begin
   fpsystem('sudo /usr/sbin/dpkg-reconfigure locales');
   fpsystem('sudo dpkg-reconfigure console-data');
   Menu();
   exit;
end;

if a='Q' then begin
   fpsystem('/bin/login.old');
   halt(0);
end;

 Menu();

end;
//##############################################################################
procedure tlogon.webaccess();
var
   slighttpd:Tlighttpd;
   ip:ttcpip;
   port,uris:string;
begin

   slighttpd:=Tlighttpd.Create(SYS);
   port:=slighttpd.LIGHTTPD_LISTEN_PORT();
   uris:=SYS.txt_uris(port);
   fpsystem('clear');
   writeln('Access to the Artica Web interface');
   writeln('**********************************************');
   writeln('');
   writeln('Here it is uris you can type on your web browser in order');
   writeln('to access to the front-end.');
   writeln('');
   writeln(uris);
   writeln('[Enter] key to Exit');
   readln();
end;

//##############################################################################
procedure tlogon.credentials();
var
   slighttpd:Tlighttpd;
   port,uris:string;
begin
   ldap:=Topenldap.Create;


   fpsystem('clear');
   writeln('Access to the Artica Web interface');
   writeln('**********************************************');
   writeln('');
   writeln('Once connected to the web front-end, use');
   writeln('following parameters');
   writeln('');
   writeln('Username..................:'+ldap.ldap_settings.admin);
   writeln('Password..................:'+ldap.ldap_settings.password);
   writeln('[Enter] key to Exit');
   readln();
end;
//##############################################################################
procedure tlogon.ChangeIP();
var
   IP:string;
   Gateway:string;
   DNS,answer:string;
   NETMASK:string;
   iptcp:ttcpip;
   Gayteway:string;
   perform:string;
begin

    iptcp:=ttcpip.Create;
    IP:=iptcp.IP_ADDRESS_INTERFACE('eth0');
    NETMASK:=iptcp.IP_MASK_INTERFACE('eth0');
    Gayteway:=iptcp.IP_LOCAL_GATEWAY('eth0');
    perform:='o';

    fpsystem('clear');
    writeln('By default, the Artica server is set on DHCP Mode');
    writeln('You will change eth0 network settings using static mode');
    writeln('Remember that you can change IP setting trough the web interface');
    writeln('');
    writeln('Give the network address IP of this computer: ['+IP+']');
    readln(answer);
    if length(trim(answer))>0 then IP:=answer;

    writeln('Give the netmask of this computer:['+NETMASK+']');
    readln(answer);
    if length(trim(answer))>0 then NETMASK:=answer;


    writeln('Give the gateway ip address for this computer:['+Gayteway+']');
    readln(answer);
    if length(trim(answer))>0 then Gayteway:=answer;


    writeln('Give the First DNS ip address for this computer:['+Gayteway+']');
    readln(answer);
    if length(trim(answer))>0 then DNS:=answer;


    writeln('Perform this operation ?(O/N)[O]');
    readln(answer);

    if length(trim(answer))>0 then perform:=UpperCase(answer);

    if perform<>'O' then exit;










end;








end.
