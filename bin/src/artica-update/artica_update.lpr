program artica_update;

{$mode objfpc}{$H+}

uses
  Classes,logs,unix,BaseUnix,strutils,SysUtils,RegExpr,update,zsystem,
  kavmilter in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/kavmilter.pas',
  kas3 in '/home/dtouzeau/developpement/artica-postfix/bin/src/artica-install/kas3.pas';

var
tempfile:TstringList;
s:string;
XSETS                   :tupdate;
zlogs                   :Tlogs;
D                       :boolean;
i                       :integer;
SYS                     :Tsystem;
mypid                   :string;
zkas3                   :tkas3;
zkavmilter              :tkavmilter;



//##############################################################################

begin

  XSETS:=tupdate.Create();
  SYS:=Tsystem.Create();
  zlogs:=Tlogs.Create;
  D:=SYS.COMMANDLINE_PARAMETERS('--verbose');

  if ParamStr(1)='-refresh-index' then begin
     zlogs.Debuglogs('Refresh index...');
     XSETS.CheckIndex();
     halt(0);
  end;

 if ParamStr(1)='--index' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--index Already instance executed');
         halt(0);
    end;
    XSETS.indexini();
    halt(0);
 end;

  if SYS.PROCESS_EXIST(SYS.PIDOF_PATTERN('artica-update')) then begin
       zlogs.Debuglogs('Already instance executed pid '+SYS.PIDOF_PATTERN('artica-update'));
       zlogs.Debuglogs('die....');
       halt(0);
  end;

  if ParamStr(1)='--kas3' then begin
     zkas3:=tkas3.Create(SYS);
     zkas3.PERFORM_UPDATE();
     halt(0);
  end;

  if ParamStr(1)='--kavmilter' then begin
     zkavmilter:=tkavmilter.Create(SYS);
     zkavmilter.PERFORM_UPDATE();
     halt(0);
  end;
  

  
  if ParamStr(1)='-startinstall' then begin
     XSETS.Initialize_installation();
     halt(0);
  end;


  


 if ParamStr(1)='--retranslator' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--retranslator Already instance executed');
         halt(0);
    end;
    XSETS.KasperskyRetranslation();
    halt(0);
 end;
 
 
 if ParamStr(1)='--clamav' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--clamav Already instance executed');
         halt(0);
    end;
    XSETS.perform_clamav_updates();
    halt(0);
 end;



 if ParamStr(1)='--clamav-engine' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--clamav-engine Already instance executed');
         halt(0);
    end;
    XSETS.clamav_engine_update();
    halt(0);
 end;

 if ParamStr(1)='--spamassassin' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--spamassassin Already instance executed');
         halt(0);
    end;
    XSETS.update_spamassasin();
    halt(0);
 end;

 if ParamStr(1)='--spamassassin-bl' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--spamassassin-bl Already instance executed');
         halt(0);
    end;
    XSETS.update_spamassassin_blacklist();
    halt(0);
 end;


 if ParamStr(1)='--MalwarePatrol' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--MalwarePatrol Already instance executed');
         halt(0);
    end;
    XSETS.MalwarePatrol();
    halt(0);
 end;


 if ParamStr(1)='--filter-plus' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--filter-plus Already instance executed');
         halt(0);
    end;
    XSETS.update_webfilterplus();
    halt(0);
 end;




 if ParamStr(1)='--backup-ldap' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs(ParamStr(1)+' Already instance executed');
         halt(0);
    end;
    XSETS.backup_ldap_database();
    halt(0);
 end;

 if ParamStr(1)='--dansguardian' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--dansguardian Already instance executed');
         halt(0);
    end;
    XSETS.update_dansguardian();
    XSETS.update_squidguard();
    XSETS.update_webfilterplus();
    halt(0);
 end;

 if ParamStr(1)='--squidguard' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('--squidguard Already instance executed');
         halt(0);
    end;
    XSETS.update_squidguard();
    halt(0);
 end;




 if ParamStr(1)='--upgrade-nightly' then begin
    if not SYS.BuildPids() then begin
         zlogs.Debuglogs('Already instance executed');
         halt(0);
    end;
    XSETS.NightlyBuild();
    halt(0);
 end;

if ParamStr(1)='--help' then begin
   writeln('--upgrade-nightly............................: Upgrade Artica to a nightly build');
   writeln('--dansguardian...............................: Update blacklists web sites for DansGuardian');
   writeln('--MalwarePatrol..............................: Update blacklists web sites from Malware Patrol');
   writeln('--filter-plus ...............................: Update licensed blacklists web sites from Artica');
   writeln('--spamassassin-bl............................: Update & compile SA blacklists');
   writeln('--clamav-engine..............................: Update & compile ClamAV Engine');
   writeln('--clamav.....................................: Update ClamAV Database');
   halt(0);
end;

  
  s:='';

 if ParamCount>0 then begin
     for i:=1 to ParamCount do begin
        s:=s  + ' ' +ParamStr(i);
     end;
 end;
 mypid:=intTostr(fpgetpid);
 s:=trim(SYS.PROCESS_LIST_PID(ParamStr(0)));
 s:=trim(AnsiReplaceText(s,mypid,''));

if not SYS.BuildPids() then halt(0);

  if ParamStr(1)='--patchs' then begin
     XSETS.ApplyPatchs();
     zlogs.Debuglogs('Halt now....');
     halt(0);
  end;


 if D then writeln('Recieve ',s);
 XSETS.CheckAndInstall();

 
 if length(s)>0 then zlogs.Debuglogs('Receive ' + s);
 
 XSETS.perform_update();
 XSETS.perform_update_nightly();
 
 zlogs.Debuglogs('Halt now....');
 halt(0);
end.
