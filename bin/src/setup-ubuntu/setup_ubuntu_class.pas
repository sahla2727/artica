unit setup_ubuntu_class;
{$MODE DELPHI}
//{$mode objfpc}{$H+}
{$LONGSTRINGS ON}

interface

uses
  Classes, SysUtils,strutils,RegExpr in 'RegExpr.pas',unix,IniFiles,setup_libs,distridetect;
type
  TStringDynArray = array of string;
  type
  tubuntu=class


private
       libs:tlibs;
       function is_application_installed(appname:string):boolean;
       function InstallPackageLists(list:string):boolean;
       function CheckCyrus():string;
       function CheckAmavisPerl():string;
       function Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
       procedure DisableApparmor();




public
      constructor Create();
      procedure Free;
      procedure Show_Welcome;
      function CheckDevcollectd():string;
      function checkSamba():string;
      function InstallPackageListssilent(list:string):boolean;
      function checkApps(l:tstringlist):string;
      function CheckBaseSystem():string;
      function CheckPostfix():string;
      function checkSQuid():string;
      function CheckNFS():string;
      function CheckBasePHP():string;
      function CheckPDNS():string;
      function CheckZabbix():string;
END;

implementation

constructor tubuntu.Create();
begin

libs:=tlibs.Create;
   if FileExists('/tmp/packages.list') then fpsystem('/bin/rm -f /tmp/packages.list');


     if length(Paramstr(1))>0 then begin
         writeln('you can use --silent in order to install packages without human intercation');
     end;
end;
//#########################################################################################
procedure tubuntu.Free();
begin
  libs.Free;
end;
//#########################################################################################
procedure tubuntu.DisableApparmor();
begin
  if FileExists('/etc/init.d/apparmor') then begin
     writeln('Disable AppArmor.....');
     fpsystem('/etc/init.d/apparmor kill');
     fpsystem('update-rc.d -f apparmor remove');
     fpsystem('/bin/mv /etc/init.d/apparmor /etc/init.d/bk.apparmor');
     writeln('You need to reboot after installation');
     writeln('Enter key');
     readln();
  end;

end;
//#########################################################################################
procedure tubuntu.Show_Welcome;
var
   base,postfix,u,cyrus,samba,squid,nfs,pdns,zabbix:string;
begin
    if not FileExists('/usr/bin/apt-get') then begin
      writeln('Your system does not store apt-get utils, this program must be closed...');
      exit;
    end;
    if not FileExists('/tmp/apt-update') then begin
       fpsystem('touch /tmp/apt-update');
       fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" update');
    end;
    


    writeln('Checking.............: system...');
    writeln('Checking.............: AppArmor...');
    DisableApparmor();
    writeln('Checking.............: Base system...');
    base:=CheckBaseSystem();
    writeln('Checking.............: Postfix system...');
    postfix:=CheckPostfix();
    writeln('Checking.............: Cyrus system...');
    cyrus:=CheckCyrus();
    writeln('Checking.............: Files Sharing system...');
    samba:=checkSamba();
    writeln('Checking.............: Squid proxy and securities...');
    squid:=checkSQuid();
    writeln('Checking.............: NFS System...');
    nfs:=CheckNFS();
    writeln('Checking.............: PowerDNS System...');
    pdns:=CheckPDNS();

    u:=libs.INTRODUCTION(base,postfix,cyrus,samba,squid,nfs,pdns);

    writeln('You have selected the option : ' + u);

    if length(u)=0 then begin
        if length(base)>0 then u:='B';
    end;

    if u='B' then begin
        InstallPackageLists(base);
        Show_Welcome();
        exit;
    end;
    
    if length(u)=0 then begin
        Show_Welcome();
        exit;
    end;
    
    if lowercase(u)='a' then begin
       if FileExists('/usr/sbin/postconf') then fpsystem('/usr/sbin/postconf -e "mydomain = domain.tld"');
       fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" remove exim*');
       InstallPackageLists(postfix+' '+cyrus+' '+samba+' '+squid);
       fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" update --fix-missing');
       fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" install -f');
       fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" autoremove');
       libs.InstallArtica();
          fpsystem('/usr/share/artica-postfix/bin/artica-make APP_ROUNDCUBE3');
          fpsystem('/etc/init.d/artica-postfix restart postfix');
       Show_Welcome;
       exit;
    end;
    
    if u='1' then begin
           if FileExists('/usr/sbin/postconf') then fpsystem('/usr/sbin/postconf -e "mydomain = domain.tld"');
          InstallPackageLists(postfix);
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" remove exim*');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" update --fix-missing');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" install -f');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" autoremove');
          InstallPackageLists(postfix);
          if FileExists('/etc/init.d/artica-postfix') then fpsystem('/etc/init.d/artica-postfix restart postfix');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get autoremove');
          Show_Welcome;
          exit;
    end;
    
    if u='2' then begin
          InstallPackageLists(cyrus);
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" update --fix-missing');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" install -f');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" autoremove');
          if FileExists('/etc/init.d/artica-postfix') then fpsystem('/etc/init.d/artica-postfix restart imap');
          fpsystem('/usr/share/artica-postfix/bin/artica-roundcube --install --verbose');
          if FileExists('/etc/init.d/artica-postfix') then fpsystem('/etc/init.d/artica-postfix restart');
          Show_Welcome;
          exit;
    end;
    
    if u='3' then begin
          InstallPackageLists(samba);
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" update --fix-missing');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" install -f');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" autoremove');
          if FileExists('/etc/init.d/artica-postfix') then fpsystem('/etc/init.d/artica-postfix restart samba');
          Show_Welcome;
          exit;
    end;
    
    if u='4' then begin
          InstallPackageLists(squid);
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" update --fix-missing');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" install -f');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" autoremove');
          if FileExists('/etc/init.d/artica-postfix') then fpsystem('/etc/init.d/artica-postfix restart squid');
          Show_Welcome;
          exit;
    end;
    
    if u='5' then begin
          libs.InstallArtica();
          Show_Welcome;
          exit;
    end;

    if u='6' then begin
          if FIleExists('/etc/init.d/portmap') then fpsystem('/etc/init.d/portmap start');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" update --fix-missing');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" install -f');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" autoremove');
          InstallPackageLists(nfs);
          if FIleExists('/etc/init.d/portmap') then fpsystem('/etc/init.d/portmap start');
          Show_Welcome;
          exit;
    end;

    if u='7' then begin
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" update --fix-missing');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" install -f');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" autoremove');
          fpsystem('DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" remove bind9 bind9-utils');
          InstallPackageLists(pdns);
          fpsystem('/etc/init.d/artica-postfix restart pdns');
          Show_Welcome;
          exit;
    end;





    if lowercase(u)='c' then begin
          fpsystem('/usr/share/artica-postfix/bin/artica-make APP_AMAVISD_MILTER');
          Show_Welcome;
          exit;
    end;


end;
//#########################################################################################
function tubuntu.InstallPackageLists(list:string):boolean;
var
   cmd:string;
   u  :string;
   i  :integer;
   ll :TStringDynArray;
begin
if length(trim(list))=0 then exit;
result:=false;

writeln('');
writeln('The following package(s) must be installed in order to perform continue setup');
writeln('');
writeln('-----------------------------------------------------------------------------');
writeln('"',list,'"');
writeln('-----------------------------------------------------------------------------');
writeln('');
writeln('Do you allow install these packages? [Y]');

if not libs.COMMANDLINE_PARAMETERS('--silent') then begin
   readln(u);
end else begin
    u:='y';
end;


if length(u)=0 then u:='y';

if LowerCase(u)<>'y' then exit;


   ll:=Explode(',',list);
   for i:=0 to length(ll)-1 do begin
       if length(trim(ll[i]))>0 then begin
          cmd:='DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy install ' + ll[i];
          fpsystem(cmd);
       end;
   end;



   if FileExists('/tmp/packages.list') then fpsystem('/bin/rm -f /tmp/packages.list');
   result:=true;


end;
//#########################################################################################
function tubuntu.InstallPackageListssilent(list:string):boolean;
var
   cmd:string;
   u  :string;
   i  :integer;
   ll :TStringDynArray;
begin
if length(trim(list))=0 then exit;
result:=false;

   cmd:='/usr/bin/apt-get -y -f install';
   fpsystem(cmd);
   cmd:='/usr/bin/apt-get -y autoremove';
   fpsystem(cmd);

   cmd:='DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get update';
   fpsystem(cmd);
   ll:=Explode(',',list);
   for i:=0 to length(ll)-1 do begin
       if length(trim(ll[i]))>0 then begin
          cmd:='DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy install ' + ll[i];
          fpsystem(cmd);
       end;
   end;



   if FileExists('/tmp/packages.list') then fpsystem('/bin/rm -f /tmp/packages.list');
   result:=true;


end;
//#########################################################################################
function tubuntu.is_application_installed(appname:string):boolean;
var
   l:TstringList;
   RegExpr:TRegExpr;
   i:integer;
   D:boolean;
begin
    D:=false;
    result:=false;
    appname:=trim(appname);
    D:=libs.COMMANDLINE_PARAMETERS('--verbose');
    if not FileExists('/tmp/packages.list') then begin
       fpsystem('/usr/bin/dpkg -l >/tmp/packages.list');
    end;

    l:=TstringList.Create;
    l.LoadFromFile('/tmp/packages.list');
    if l.Count<10 then begin
       fpsystem('/bin/rm -rf /tmp/packages.list');
       result:=is_application_installed(appname);
       exit;
    end;
    RegExpr:=TRegExpr.Create;
    RegExpr.Expression:='ii\s+(.+?)\s+';

    
    for i:=0 to l.Count-1 do begin
        if RegExpr.Exec(l.Strings[i]) then begin
           if lowercase(trim(RegExpr.Match[1]))=trim(lowercase(appname)) then begin
           result:=true;
           break;
           end;
        end;

    end;
    if D then writeln('Search ',RegExpr.Expression,' failed');
    l.free;
    RegExpr.free;

end;

//#########################################################################################
function tubuntu.CheckNFS():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;
   UbuntuIntVer:integer;
   libs:tlibs;

begin

f:='';
UbuntuIntVer:=9;
l:=TstringList.Create;
distri:=tdistriDetect.Create();
libs:=tlibs.Create;
   l.add('portmap');
   l.add('nfs-common');
   l.add('nfs-kernel-server');

fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;

end;
//#########################################################################################
function tubuntu.CheckBasePHP():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;
   UbuntuIntVer:integer;
   libmysqlclient:boolean;
   libs:tlibs;

begin
f:='';
UbuntuIntVer:=9;
l:=TstringList.Create;
distri:=tdistriDetect.Create();
libs:=tlibs.Create;
if not TryStrToInt(distri.DISTRINAME_VERSION,UbuntuIntVer) then UbuntuIntVer:=9;

if(UbuntuIntVer=0) then begin
      writeln('Unable to obtain Major release of '+distri.DISTRINAME);
      exit;
end;

l.add('apache2-prefork-dev');
l.add('libexpat1-dev');
l.add('libfreetype6-dev');
l.add('libgcrypt11-dev');
l.add('libgd2-xpm-dev');
l.add('libgmp3-dev');
l.add('libjpeg62-dev');
l.add('libkrb5-dev');
l.add('libldap2-dev');
l.add('libmcrypt-dev');
l.add('libmhash-dev');







l.add('libncurses5-dev');
l.add('libpam0g-dev');
l.add('libpcre3-dev');
l.add('libpng12-dev');
l.add('libpq-dev');
l.add('libpspell-dev');
l.add('librecode-dev');
l.add('libsasl2-dev');
l.add('libsqlite0-dev');
l.add('libssl-dev');
l.add('libt1-dev');
l.add('libtidy-dev');
l.add('libtool');
l.add('libwrap0-dev');
l.add('libxmltok1-dev');
l.add('libxml2-dev');
l.add('libxslt1-dev');
l.add('quilt');
l.add('re2c');
l.add('unixodbc-dev');
l.add('zlib1g-dev');
l.add('chrpath');
//l.add('debhelper');
l.add('flex');
l.add('freetds-dev');



if distri.DISTRINAME_CODE='DEBIAN' then begin


   if distri.DISTRINAME_VERSION='4' then begin
      l.add('libc-client2002-dev');
      l.add('apache2-prefork-dev');
      l.add('libcurl3-openssl-dev');
      l.add('libdb4.4-dev');
      L.add('libsnmp9-dev');
      l.add('libmysqlclient15-dev');
   end;

   if distri.DISTRINAME_VERSION='5' then begin
       l.add('libc-client2007b-dev');
       l.add('libcurl4-openssl-dev');
       l.add('libsnmp-dev');
       l.add('libmysqlclient15-dev');
   end;

end;

if distri.DISTRINAME_CODE='UBUNTU' then begin
   l.add('libc-client2007b-dev');
   l.add('libcurl4-openssl-dev');
   l.add('libsnmp-dev');

   if UbuntuIntVer<10 then begin
      l.add('libmysqlclient15-dev');
      libmysqlclient:=true;
   end;


   if UbuntuIntVer>9 then  begin
      l.add('libmysqlclient-dev');
      libmysqlclient:=true;
   end;


   if not libmysqlclient then begin
       if UbuntuIntVer=10 then l.add('libmysqlclient-dev');
       if UbuntuIntVer=9 then  l.add('libmysqlclient15-dev');
       if UbuntuIntVer=8 then  l.add('libmysqlclient15-dev');
   end;
end;

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;


end;




function tubuntu.CheckBaseSystem():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;
   UbuntuIntVer:integer;
   libs:tlibs;
   
begin
f:='';
UbuntuIntVer:=9;
l:=TstringList.Create;
distri:=tdistriDetect.Create();
libs:=tlibs.Create;
l.Add('dhcp3-client');
l.Add('cron');
l.Add('debconf-utils');
l.Add('discover');
l.Add('file');
l.Add('hdparm');
l.Add('jove');
l.Add('less');
//l.Add('nscd');
l.Add('rdate');
l.Add('rsync');
l.Add('rsh-client');
l.Add('openssh-client ');
l.Add('openssh-server');
l.Add('strace');
l.add('mtools');
l.add('re2c');
l.add('bridge-utils');
l.add('cfengine2');
l.add('cron');
l.add('debconf-utils');
l.add('discover');
l.add('file');
l.add('hdparm');
l.add('jove');
l.add('less');
l.add('rdate');
l.add('rsync');
l.add('rsh-client');
l.add('sudo');
l.add('iproute');
l.add('curl');
l.add('lm-sensors');
l.add('hddtemp');
l.add('bison');
l.add('autofs');
l.add('autofs-ldap');
l.add('e2fsprogs');
//NFS


//l.add('gfs2-tools');
//l.add('drbd8-utils');


//lvm
if not libs.COMMANDLINE_PARAMETERS('--without-lvm') then begin
   l.add('lvm2');
end;

l.add('libc6-dev');
l.add('iptables-dev');
l.add('libssl-dev');
l.add('libpcap0.8-dev');
l.add('byacc');
l.Add('gcc');
l.Add('make');
l.Add('build-essential');
l.Add('flex');
l.add('libsasl2-dev');
l.add('libcdb-dev');
l.Add('libmcrypt-dev');
l.add('autofs');
l.add('sshfs');
l.add('fuse-utils');
l.add('autofs-ldap');

l.Add('tcsh');
l.Add('time');
l.Add('eject');
l.Add('locales');
l.Add('console-common');
l.Add('pciutils ');
l.Add('usbutils');
l.Add('slapd ');
l.add('ldap-utils');
l.Add('openssl ');
l.Add('strace');
l.add('smbclient');

l.Add('tcsh');
l.Add('time');
l.Add('eject');
l.Add('locales');
l.Add('pciutils');
l.Add('usbutils');
L.add('sysstat');

//PHP engines
l.Add('php5-cgi');
l.Add('php5-cli');
l.Add('php5-ldap');
l.Add('php5-mysql');
l.Add('php5-imap');
l.add('php-net-sieve');
l.Add('php5-gd');
l.add('php5-curl');
l.Add('php5-mcrypt');
l.Add('php-log');
l.add('php-apc');
l.Add('php-pear');
l.add('php5-dev'); // To compile PHP5
l.Add('lighttpd');


//process limitations
L.add('cpulimit');

l.add('catdoc'); //xapian
l.add('antiword'); //xapian
l.add('uuid-dev'); //zarafa




l.Add('mysql-server');
l.Add('rrdtool');
l.add('libmodule-build-perl');

l.Add('librrdp-perl');
l.Add('librrds-perl');
l.Add('libfile-tail-perl');
l.Add('libgeo-ipfree-perl');
l.Add('libnet-xwhois-perl');
L.Add('libcompress-zlib-perl');
l.Add('librrdp-perl');
l.Add('librrds-perl');
l.Add('libfile-tail-perl');
l.Add('libgeo-ipfree-perl');
l.Add('libnet-xwhois-perl');
l.Add('libgssapi-perl');
l.Add('libwww-perl');
l.Add('mhonarc');
l.Add('libcrypt-openssl-rsa-perl');
l.Add('libcrypt-openssl-bignum-perl');
l.Add('libcrypt-openssl-random-perl');
l.Add('libmailtools-perl');
l.Add('libio-stringy-perl');
l.Add('libunix-syslog-perl');
l.Add('libberkeleydb-perl');
l.Add('libdigest-sha1-perl');
l.Add('libdigest-sha-perl');
l.Add('libmail-dkim-perl');
l.Add('libauthen-sasl-perl');
l.Add('libdbi-perl');
l.Add('libxml-namespacesupport-perl');
l.Add('libxml-sax-expat-perl');
l.Add('libxml-sax-perl');
l.Add('libxml-filter-buffertext-perl');
l.Add('libtest-simple-perl');
l.Add('libtext-iconv-perl');
l.Add('libxml-sax-writer-perl');
l.Add('libconvert-asn1-perl');
l.Add('libconvert-uulib-perl');
l.Add('libnet-ldap-perl');
l.Add('libconfig-inifiles-perl');
l.add('libnet-server-perl');


l.Add('libio-socket-ssl-perl');
l.Add('libcrypt-ssleay-perl');
l.Add('libnet-ssleay-perl');
l.Add('libgeo-ipfree-perl');
l.Add('libconvert-tnef-perl');
l.Add('libhtml-parser-perl');
l.Add('libfile-scan-perl');
l.Add('libarchive-zip-perl');
l.Add('libinline-perl');
l.Add('libcompress-zlib-perl');
l.Add('libhtml-format-perl');
l.Add('libwww-perl');
l.add('libgd2-xpm-dev');                           
l.Add('libnss-ldap');
l.Add('libpam-ldap');
l.Add('libpam-smbpass');
l.Add('ldap-utils');
l.add('libunix-syslog-perl');
l.add('libnet-server-perl');
l.add('libtext-template-perl');
l.add('libnet-dns-perl');
l.add('libstring-random-perl');


//openvpn
L.add('openvpn');
l.add('bridge-utils');

l.add('mailsync');
l.Add('sasl2-bin');
l.Add('sudo');
l.Add('ntp');
l.Add('iproute');
l.add('bzip2');
l.add('unrar-free');
l.add('arj');
l.add('zip');
l.add('re2c');
if not TryStrToInt(distri.DISTRINAME_VERSION,UbuntuIntVer) then UbuntuIntVer:=9;

l.add('libgdbm-dev'); //for grawl

l.Add('dhcp3-server');
l.Add('libexpat1-dev');
l.Add('libxml2-dev');  //for squid & dansguardian
l.Add('libgssapi-perl');
l.add('zlib1g-dev');
l.add('libdotconf-dev');
l.Add('libpcre3-dev');
l.add('pkg-config');
l.add('libldap2-dev');
l.add('libpam0g-dev');
l.add('libconfuse-dev');
l.add('libcdio-dev');
l.add('libusb-dev');
l.add('libkrb5-dev');
l.add('zlib1g-dev');
l.add('libdotconf-dev');
l.add('libfreetype6-dev');
l.add('libt1-dev');
l.add('libpaper-dev');
l.add('libbz2-dev');
l.add('libxml2-dev');
l.add('libgd-tools');
l.add('libfuse2');
l.add('libusb-0.1-4');
l.add('iptables-dev');
l.add('libssl-dev');
l.add('libpcap0.8-dev');
l.add('libpcre3-dev');
l.add('libsasl2-dev');
l.add('libreadline5-dev');
l.add('libmcrypt-dev');
l.add('libcdb-dev');
l.add('pkg-config');
l.add('libpspell-dev');
l.add('libjpeg62-dev');
l.add('libpng12-dev');
l.add('mtools');
l.add('dar');
l.add('libgeoip-dev');
l.add('libgeoip1');
l.add('libwrap0-dev');
l.add('libclamav-dev');
l.add('gettext');
l.add('ruby');
l.add('libdb4.2-ruby1.8');
l.add('libcairo-ruby1.8');
l.add('cryptsetup');
l.add('monit');
l.add('libtommath-devel'); //clamav
l.add('udisks');


l.add('rsync');
l.add('stunnel4');
l.add('smbfs');

//python
l.add('python-dev');

//groupOffice:
l.add('libwbxml2-utils');

l.add('apache2-mpm-prefork');
l.add('libapache2-mod-php5');
l.add('libiodbc2-dev');



if not TryStrToInt(distri.DISTRINAME_VERSION,UbuntuIntVer) then UbuntuIntVer:=9;

if distri.DISTRINAME_CODE='DEBIAN' then begin
   if distri.DISTRINAME_VERSION='4' then begin
      l.Add('libdb4.4-dev');
      l.Add('sysutils');
      l.add('libcurl3-openssl-dev');
      l.add('libsnmp9-dev');
      l.add('apache');
      l.add('apache-common');
      l.add('libversion-perl');
   end;

   if distri.DISTRINAME_VERSION='5' then begin
      l.Add('libdb4.6-dev');
      l.add('memtester');
      l.add('procinfo');
      l.Add('libgeo-ip-perl');
      l.add('libcurl4-openssl-dev');
      l.add('php5-geoip');
      l.add('libtommath-dev');
      l.add('libsnmp-dev');
      l.add('perl-modules');

   end;

   l.Add('libpam0g-dev');
   l.Add('unrar-free');
   l.add('pike7.6-core');
   l.add('pike7.6-dev');
   l.add('libltdl3-dev');

end;

if distri.DISTRINAME_CODE='UBUNTU' then begin
   l.Add('unrar');
   l.Add('lha');
   l.add('pike7.6');
   l.Add('libdb4.6-dev');
   l.add('memtester');
   l.add('procinfo');
   l.Add('libgeo-ip-perl');
   l.add('libcurl4-openssl-dev');
   l.add('libsnmp-dev');
   l.add('libltdl-dev'); //Clamav compilation
   l.add('language-pack-nl'); // Zarafa


   if UbuntuIntVer=8 then begin
      l.add('libversion-perl');
   end;

   if UbuntuIntVer>8 then begin
      l.add('php5-geoip');
      l.add('libtommath-dev');
      l.add('perl-modules');

   end;

end;

//OCS
l.Add('libapache2-mod-perl2');
l.Add('libxml-simple-perl');
l.Add('libcompress-zlib-perl');
l.Add('libdbi-perl');
l.add('libapache-dbi-perl');
l.add('libdbd-mysql-perl');
l.add('libapache-dbi-perl');
l.add('libnet-ip-perl');
l.add('libsoap-lite-perl');
l.add('libnet-ip-perl');
l.add('libsoap-lite-perl');
l.Add('libusb-dev ');
l.Add('libusb-0.1-4 ');
l.Add('libinline-perl ');
l.Add('libcdio-dev ');
l.Add('libconfuse-dev');
l.add('libssl-dev');
l.Add('curl');
l.Add('lm-sensors');
l.Add('hddtemp');
l.Add('libsasl2-modules ');
l.Add('libsasl2-modules-ldap');
l.Add('libauthen-sasl-perl');
l.add('xutils-dev');
l.Add('bzip2');
l.add('unzip');
l.Add('arj');
l.Add('htop');
l.Add('telnet');
l.Add('lsof');
l.Add('dar');
l.add('hostapd');
l.add('hostap-utils');





fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
end;
//#########################################################################################

function tubuntu.CheckZabbix():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;
   UbuntuIntVer:integer;
begin

f:='';
l:=TstringList.Create;
distri:=tdistriDetect.Create();
UbuntuIntVer:=9;
libs:=tlibs.Create;
if not TryStrToInt(distri.DISTRINAME_VERSION,UbuntuIntVer) then UbuntuIntVer:=9;

if not FileExists('/etc/artica-postfix/KASPER_MAIL_APP') then begin
   l.add('zabbix-server-mysql');
   l.add('zabbix-frontend-php');
   l.add('zabbix-agent');
end;

fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;


end;
//#########################################################################################

function tubuntu.CheckPostfix():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;
   UbuntuIntVer:integer;
begin
f:='';
l:=TstringList.Create;
distri:=tdistriDetect.Create();
UbuntuIntVer:=9;
libs:=tlibs.Create;
if not TryStrToInt(distri.DISTRINAME_VERSION,UbuntuIntVer) then UbuntuIntVer:=9;

l.Add('razor');
l.Add('pyzor');
l.Add('queuegraph');
l.Add('mailgraph');
l.Add('libio-socket-ssl-perl');
l.Add('libcrypt-ssleay-perl');
l.Add('libnet-ssleay-perl');
l.Add('libgeo-ipfree-perl');
l.Add('libconvert-tnef-perl');
l.Add('libhtml-parser-perl ');
l.Add('libfile-scan-perl ');
l.Add('libarchive-zip-perl ');
l.Add('sanitizer ');
l.Add('wv');
l.Add('ttf-dustin ');
l.Add('libgd-tools ');
l.Add('awstats');
l.add('postfix');
l.Add('postfix-ldap');
l.Add('spamass-milter');
l.Add('spamassassin');
l.Add('mailman');
l.Add('spamc');
l.add('wv');
l.add('libmilter-dev');
l.add('pflogsumm');
l.add('dkim-filter');


//Zarafa
l.add('libgsasl7-dev'); //gsasl.h

//ASSP

l.add('libcompress-zlib-perl');
l.add('libemail-valid-perl');
l.add('libfile-readbackwards-perl');

l.add('libmail-imapclient-perl');
L.add('libemail-mime-perl');
l.add('libemail-mime-modifier-perl');
l.add('libmail-srs-perl');
l.add('libnet-dns-perl');
l.add('libsys-syslog-perl');
l.add('libnet-ldap-perl');
l.add('libemail-send-perl');
l.add('libio-socket-ssl-perl');

 if distri.DISTRINAME_CODE='DEBIAN' then begin
   if distri.DISTRINAME_VERSION='5' then begin
     l.add('libmail-spf-perl');
   end;
end;

if distri.DISTRINAME_CODE='UBUNTU' then begin
   if UbuntuIntVer>=9 then begin
     l.add('libmail-spf-perl');
   end;
end;



fpsystem('/bin/rm -rf /tmp/packages.list');

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
end;
//#########################################################################################
function tubuntu.CheckPDNS():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;

begin
f:='';
l:=TstringList.Create;
//pdns

l.add('pdns-server');
l.add('pdns-recursor');
l.add('pdns-backend-ldap');
l.add('libboost-dev'); //shared_ptr.hpp
l.add('libboost-serialization-dev');
l.add('liblua5.1-0-dev');
for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;

end;

function tubuntu.CheckAmavisPerl():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;

begin
f:='';
distri:=tdistriDetect.Create();
l:=TstringList.Create;
l.Add('libcrypt-openssl-rsa-perl');
l.Add('libmail-dkim-perl');

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;

InstallPackageListssilent(f);
l.free;
 
end;
//#########################################################################################
function tubuntu.CheckCyrus():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;

begin
f:='';
distri:=tdistriDetect.Create();
l:=TstringList.Create;
l.Add('cyrus-imapd-2.2');
l.Add('cyrus-admin-2.2');
l.Add('sasl2-bin');
l.Add('cyrus-pop3d-2.2');
l.Add('cyrus-murder-2.2');
l.add('libsnmp-dev');
l.add('libopenafs-dev');
l.add('cyrus-clients-2.2');
l.add('imapsync');
if distri.DISTRINAME_CODE='UBUNTU' then begin
   l.Add('fdm');
end;

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//#########################################################################################
function tubuntu.checkSamba():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;
   UbuntuIntVer:integer;
begin
f:='';
l:=TstringList.Create;
distri:=tdistriDetect.Create();
if not TryStrToInt(distri.DISTRINAME_VERSION,UbuntuIntVer) then UbuntuIntVer:=9;

l.Add('samba');
l.Add('smbldap-tools');
l.Add('smbclient ');
//l.Add('nscd');
l.Add('nmap');
l.add('libcupsimage2-dev');
l.add('attr');
l.add('acl');
fpsystem('touch /etc/artica-postfix/samba.check.time');
if distri.DISTRINAME_CODE='UBUNTU' then begin
      if UbuntuIntVer>8 then begin
          l.add('libcups2-dev');
          l.add('cups-driver-gutenprint');
      end;
end;

if distri.DISTRINAME_CODE='DEBIAN' then begin
   if distri.DISTRINAME_VERSION='5' then begin
      l.add('libcups2-dev');
      l.add('cups-driver-gutenprint');
   end;
end;

l.add('foomatic-db-gutenprint');
l.add('libgtk2.0-dev');
l.add('libtiff4-dev');
l.add('libjpeg62-dev');
l.add('libpam0g-dev');
l.add('uuid-dev');
l.add('krb5-user');

for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//#########################################################################################
function tubuntu.CheckDevcollectd():string;
var
   l:TstringList;
   f:string;
   i:integer;
   distri:tdistriDetect;

begin
f:='';
distri:=tdistriDetect.Create;
l:=TstringList.Create;
l.Add('iproute-dev');
l.Add('xfslibs-dev');
l.Add('librrd2-dev');
l.Add('libsensors-dev');
if distri.DISTRINAME_CODE='UBUNTU' then l.Add('libperl-dev') else l.Add('libperl5.8');
l.add('libesmtp-dev');
l.add('libnotify-dev');
l.add('libxml2-dev');
l.add('libpcap-dev');
l.add('hddtemp');
l.add('mbmon');
l.add('libconfig-general-perl');
l.Add('memcached');
L.add('libcurl4-openssl-dev');
for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;


//#########################################################################################
function tubuntu.checkSQuid():string;
var
   l:TstringList;
   f:string;
   i:integer;

begin
f:='';
l:=TstringList.Create;
l.Add('squid3');
l.Add('squidclient');
l.Add('dansguardian');
l.Add('awstats');
l.add('sarg');
l.add('libclamav-dev');
for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;

//#########################################################################################
function tubuntu.checkApps(l:tstringlist):string;
var
   f:string;
   i:integer;

begin
f:='';
for i:=0 to l.Count-1 do begin
     if not is_application_installed(l.Strings[i]) then begin
          f:=f + ',' + l.Strings[i];
     end;
end;
 result:=f;
 l.free;
end;
//########################################################################################
function tubuntu.Explode(const Separator, S: string; Limit: Integer = 0):TStringDynArray;
var
  SepLen       : Integer;
  F, P         : PChar;
  ALen, Index  : Integer;
begin
  SetLength(Result, 0);
  if (S = '') or (Limit < 0) then
    Exit;
  if Separator = '' then
  begin
    SetLength(Result, 1);
    Result[0] := S;
    Exit;
  end;
  SepLen := Length(Separator);
  ALen := Limit;
  SetLength(Result, ALen);

  Index := 0;
  P := PChar(S);
  while P^ <> #0 do
  begin
    F := P;
    P := StrPos(P, PChar(Separator));
    if (P = nil) or ((Limit > 0) and (Index = Limit - 1)) then
      P := StrEnd(F);
    if Index >= ALen then
    begin
      Inc(ALen, 5); // mehrere auf einmal um schneller arbeiten zu können
      SetLength(Result, ALen);
    end;
    SetString(Result[Index], F, P - F);
    Inc(Index);
    if P^ <> #0 then
      Inc(P, SepLen);
  end;
  if Index < ALen then
    SetLength(Result, Index); // wirkliche Länge festlegen
end;
//#########################################################################################
end.
