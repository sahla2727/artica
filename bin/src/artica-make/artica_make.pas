program artica_make;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, setup_collectd, setup_clamav, unix, setup_kas3,
  setup_simple_groupware, setup_atmailopen, setup_milterspy,
  setup_miltergreylist, setup_amavisdmilter, setup_imapsync, setup_obm,
  setup_isoqlog, setup_dotclear, setup_jcheckmail, setup_kavmilter, setup_squid,
  setup_kavsamba, logs, setup_pommo, setup_dar, setup_fetchmail, setup_cicap,
  setup_gnarwl, setup_mhonarc, setup_postfix, setup_msmtp, setup_pflogsumm,
  setup_spamassassin, setup_cups, setup_cyrus, install_generic, setup_pureftpd,
  setup_obm2, setup_smartmontools, setup_nmap, setup_samba, setup_xapian,
  setup_opengoo, setup_joomla, setup_stunnel, setup_gnuplot, setup_dstat,
  setup_eaccelerator, setup_bacula, setup_roundcube, setup_acxdrv,
  setup_hostapd, zsystem, setup_mysql, setup_winexe, setup_assp, setup_ocs,
  setup_lmb, setup_glusterfs, setup_postfilter, setup_vmtools,
  setup_phpldapadmin, setup_zarafa, setup_cpulimit, setup_drupal,
  setup_emailrelay, setup_mldonkey, setup_backuppc, setup_kav4fs;

var
   collectd:tsetup_collectd;
   clamav:tsetup_clamav;
   kas3:tsetup_kas3;
   SimpleGroupWare:tsetup_simple_groupware;
   atmail:tatmail;
   greylist:miltergreylist;
   mailspy:milterspy;
   amavis:amavisd;
   imaps:imapsync;
   zobm:tobm_install;
   zisoqlog:isoqlog;
   zdotclear:dotclear;
   zjcheckmail:jcheckmail;
   kavmilter:tsetup_kavmilter;
   squid:tsetup_squid;
   kavsamba:tsetup_kavsamba;
   pommo:tpommo;
   ddar:dar;
   fetchmail:install_fetchmail;
   ccicap:cicap;
   sgnarwl:gnarwl;
   mhonarc:mhonarcisnt;
   postfix:tpostfix_install;
   msmtp:tmsmtp;
   pflogsumm:tpflogsumm;
   spamassassin:tspam;
   cups:tcups_install;
   zinstall:tinstall;
   zcyrus:tcyrus_install;
   pureftpd:installpure;
   obm2:setupobm2;
   smartmon:smartmontools_install;
   nmap:install_nmap;
   samba:install_samba;
   xapian:install_xapian;
   opengoo:setupopengoo;
   joomla:tsetup_joomla;
   stunnel:tsetup_stunnel;
   gnuplot:install_gnuplot;
   dstat:install_dstat;
   eacc:tsetup_eacc;
   bacula:install_bacula;
   roundcube:install_roundcube;
   acx:tacx;
   hostpad:tsetup_hostapd;
   SYS:Tsystem;
   mysql:tsetup_mysql;
   winexe:tsetup_winexe;
   ocsi:tsetup_ocs;
   assp:tsetup_assp;
   lmb:tsetup_lmb;
   glusterfs:install_glusterfs;
   postfilter:tsetup_postfilter;
   vmtools:tsetup_vmtools;
   phpldapadmin:tsetup_phpldapadmin;
   zarafa:tzarafa;
   cpulimit:tsetup_cpulimit;
   drupal:tsetup_drupal;
   emailrelay:tsetup_emailrelay;
   mldonkey:tsetup_mldonkey;
   backuppc:tsetup_backuppc;
   kav4fs:Tsetup_kav4fs;
begin


  SetCurrentDir('/root');
  zinstall:=tinstall.Create;


   if ParamStr(1)='--empty-cache' then begin
      zinstall.EMPTY_CACHE();
      halt(0);
   end;





  zinstall.INSTALL_PROGRESS(ParamStr(1),'{checking}');
  zinstall.INSTALL_STATUS(ParamStr(1),5);
  sys:=Tsystem.Create;

   if ParamStr(1)='--db-ver' then begin
      zcyrus:=tcyrus_install.Create;
      writeln(zcyrus.GET_DB_VERSION());
      halt(0);
   end;

   if ParamStr(1)='--cyrus-patch-db' then begin
      zcyrus:=tcyrus_install.Create;
      zcyrus.PatchdebVer(ParamStr(2));
      zinstall.EMPTY_CACHE();
      halt(0);
   end;

   if ParamStr(1)='APP_CPULIMIT' then begin
         cpulimit:=tsetup_cpulimit.Create;
         cpulimit.xinstall();
         halt(0);
   end;


   if ParamStr(1)='APP_BACKUPPC' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         backuppc:=tsetup_backuppc.Create;
         backuppc.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_KAV4FS' then begin
       //  fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
        // fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         kav4fs:=tsetup_kav4fs.Create;
         kav4fs.xinstall();
         //zinstall.EMPTY_CACHE();
         halt(0);
   end;




   if ParamStr(1)='APP_EMAIL_RELAY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         emailrelay:=tsetup_emailrelay.Create;
         emailrelay.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_EMAILRELAY_REMOVE' then begin
         emailrelay:=tsetup_emailrelay.Create;
         emailrelay.xremove();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_EMAILRELAY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         emailrelay:=tsetup_emailrelay.Create;
         emailrelay.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_MLDONKEY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         mldonkey:=tsetup_mldonkey.Create;
         mldonkey.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_DRUPAL' then begin
         drupal:=tsetup_drupal.Create;
         drupal.xinstall();
         halt(0);
   end;




   if ParamStr(1)='APP_MONIT' then begin
         cpulimit:=tsetup_cpulimit.Create;
         cpulimit.monit_xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_ZARAFA_LIBVMIME' then begin
         zarafa:=tzarafa.Create;
         zarafa.libvmime();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_ZARAFA_CLUCENE' then begin
         zarafa:=tzarafa.Create;
         zarafa.clucene();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ZARAFA_GOOGLE' then begin
         zarafa:=tzarafa.Create;
         zarafa.google_perftools();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ZARAFA_LIBICAL' then begin
         zarafa:=tzarafa.Create;
         zarafa.libical();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_ZARAFA' then begin
         zarafa:=tzarafa.Create;
         if ParamStr(2)='--remove' then begin
            fpsystem('/etc/init.d/artica-postfix stop zarafa');
            zarafa.REMOVE();
            zinstall.INSTALL_PROGRESS(ParamStr(1),'{removed}');
            zinstall.INSTALL_STATUS(ParamStr(1),100);
            halt(0);
         end;
         zarafa.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_PHPLDAPADMIN' then begin
         phpldapadmin:=tsetup_phpldapadmin.Create;
         phpldapadmin.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_PHPMYADMIN' then begin
         phpldapadmin:=tsetup_phpldapadmin.Create;
         phpldapadmin.xinstall_phpmyadmin();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_SQUID' then begin
         squid:=tsetup_squid.Create;
         if length(ParamStr(2))>0 then begin
            if SYS.COMMANDLINE_PARAMETERS('--configure') then begin
                 writeln('Artica will compile squid with these directives:');
                 writeln('');
                 squid.command_line_squid();
                 writeln('');
                 halt(0);
            end;
         end;

         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-squid');
         squid.xinstall();
         squid.sarg_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_SQUIDGUARD' then begin
         squid:=tsetup_squid.Create;
         if length(ParamStr(2))>0 then begin
            if SYS.COMMANDLINE_PARAMETERS('--configure') then begin
                 writeln('Artica will compile squidGuard with these directives:');
                 writeln('');
                 writeln(squid.command_line_squidguard());
                 writeln('');
                 halt(0);
            end;
         end;

         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-squid');
         squid.squidguard_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_VMTOOLS' then begin
         vmtools:=tsetup_vmtools.Create;
         vmtools.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_WINEXE' then begin
         winexe:=tsetup_winexe.Create;
         winexe.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_OCSI' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         ocsi:=tsetup_ocs.Create;
         ocsi.xinstall();
         fpsystem('/usr/share/artica-postfix/bin/artica-make APP_OCSI_CLIENT &');
         ocsi.xclient_install();
         winexe:=tsetup_winexe.Create;
         winexe.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_OCSI_CLIENT' then begin
         ocsi:=tsetup_ocs.Create;
         ocsi.xclient_install();
         halt(0);
   end;

   if ParamStr(1)='APP_OCSC' then begin
         ocsi:=tsetup_ocs.Create;
         ocsi.xclient_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_OCSI_LINUX_CLIENT' then begin
         if ParamStr(2)<>'--nocheck' then fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         ocsi:=tsetup_ocs.Create;
         ocsi.xclient_linux_install();
         halt(0);
   end;


   if ParamStr(1)='APP_POSTFILTER' then begin
         postfilter:=tsetup_postfilter.Create;
         postfilter.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_BACULA' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         bacula:=install_bacula.Create;
         bacula.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_MYSQL' then begin
         mysql:=tsetup_mysql.Create;
         mysql.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ACX_DRIVERS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         writeln('Start installing drivers WIFI ACX Code name=APP_ACX_DRIVERS');
         acx:=tacx.Create;
         acx.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_HOSTAPD' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         writeln('Start installing hostapd Code name=APP_HOSTAPD');
         hostpad:=tsetup_hostapd.Create;
         hostpad.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_EACCELERATOR' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         eacc:=tsetup_eacc.Create();
         eacc.xinstall();
         eacc.groupwareinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_GLUSTERFS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         glusterfs:=install_glusterfs.Create();
         glusterfs.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;




  if ParamStr(1)='APP_AMACHI' then begin
         opengoo:=setupopengoo.Create;
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo.APP_AMACHI_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_GROUPWARE_APACHE' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.apacheinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_GROUPOFFICE' then begin
         opengoo:=setupopengoo.Create;
         opengoo.GROUPOFFICE_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_STUNNEL' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         stunnel:=tsetup_stunnel.Create;
         stunnel.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_GNUPLOT' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         gnuplot:=install_gnuplot.Create;
         gnuplot.xinstall();

         dstat:=install_dstat.Create();
         dstat.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_DSTAT' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         gnuplot:=install_gnuplot.Create;
         gnuplot.xinstall();
         dstat:=install_dstat.Create();
         dstat.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ASSP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         clamav:=tsetup_clamav.Create;
         clamav.install_clamav();
         assp:=tsetup_assp.Create;
         assp.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;




  if ParamStr(1)='APP_PHP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-php');
         opengoo:=setupopengoo.Create;
         opengoo.PHP_STANDARD_INSTALL();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;



  if ParamStr(1)='APP_GROUPWARE_PHP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.CC_CLIENT_INSTALL();
         opengoo.phpinstall();
         eacc:=tsetup_eacc.Create();
         eacc.groupwareinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ROUNDCUBE3' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         roundcube:=install_roundcube.Create();
         roundcube.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_ROUNDCUBE3_SIEVE_RULE' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');

         roundcube:=install_roundcube.Create();
         roundcube.SieveRules();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_CC_CLIENT' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.CC_CLIENT_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



  if ParamStr(1)='APP_JOOMLA' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         joomla:=tsetup_joomla.Create;
         joomla.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_LMB' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         lmb:=tsetup_lmb.Create;
         lmb.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

  if ParamStr(1)='APP_SOGO' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         lmb:=tsetup_lmb.Create;
         lmb.sogo_xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

 if ParamStr(1)='APP_SUGARCRM' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         joomla:=tsetup_joomla.Create;
         joomla.SugarCRM_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_CCLIENT' then begin
         //fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.CC_CLIENT_INSTALL();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_OPENGOO' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         opengoo:=setupopengoo.Create;
         opengoo.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_SARG' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         squid:=tsetup_squid.Create;
         squid.sarg_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_XAPIAN' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.libinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_XAPIAN_PHP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.phpinstall();

         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_XAPIAN_OMEGA' then begin
        fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.omegainstall();

         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_XPDF' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.xpdf();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_UNZIP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.unzip();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_CATDOC' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.catdoc();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_UNRTF' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         xapian:=install_xapian.Create;
         xapian.unrtf();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_ANTIWORD' then begin
         xapian:=install_xapian.Create;
         xapian.antiword();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_NMAP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         nmap:=install_nmap.Create;
         nmap.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

 if ParamStr(1)='APP_SMARTMONTOOLS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         smartmon:=smartmontools_install.Create;
         smartmon.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_OBM2' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         obm2:=setupobm2.Create;
         obm2.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_CYRUS_IMAP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         zcyrus:=tcyrus_install.Create;
         zcyrus.install_cyrus();

         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         halt(0);
   end;


   if ParamStr(1)='APP_PUREFTPD' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         pureftpd:=installpure.Create;
         pureftpd.xinstall();
         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_PFLOGSUMM' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         pflogsumm:=tpflogsumm.Create;
         pflogsumm.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;



   if ParamStr(1)='APP_CUPS_DRV' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         cups:=tcups_install.Create;
         cups.cupsdrivers();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_GUTENPRINT' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         cups:=tcups_install.Create;
         cups.gutenprint();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_CUPS_BROTHER' then begin
         cups:=tcups_install.Create;
         cups.cupsBrother();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_HPINLINUX' then begin
         cups:=tcups_install.Create;
         cups.hpinlinux();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_SAMBA' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         samba:=install_samba.Create;
         samba.xinstall();
         fpsystem('/etc/init.d/artica-postfix restart samba');
         fpsystem(sys.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.admin.status.postfix.flow.php --force');
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_SCANNED_ONLY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         samba:=install_samba.Create;
         samba.scannedonly();
         fpsystem('/etc/init.d/artica-postfix restart samba');
         fpsystem(sys.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.admin.status.postfix.flow.php --force &');
         zinstall.EMPTY_CACHE();
         halt(0);;
  end;


   if ParamStr(1)='APP_PDNS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         samba:=install_samba.Create;
         samba.pdnsinstall();
         fpsystem('/etc/init.d/artica-postfix restart pdns');
         fpsystem(sys.LOCATE_PHP5_BIN()+' /usr/share/artica-postfix/exec.admin.status.postfix.flow.php --force &');
         zinstall.EMPTY_CACHE();
         halt(0);;
   end;

   if ParamStr(1)='APP_FOO2ZJS' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-samba');
         cups:=tcups_install.Create;
         cups.foo2zjs();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


 if ParamStr(1)='APP_SPAMASSASSIN' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         spamassassin:=tspam.Create;
         spamassassin.xinstall();
         zinstall.EMPTY_CACHE();
         fpsystem('/usr/share/artica-postfix/bin/process1 --force &');
         halt(0);
   end;




   if ParamStr(1)='APP_MSMTP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         msmtp:=tmsmtp.Create;
         msmtp.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_MHONARC' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         mhonarc:=mhonarcisnt.Create;
         mhonarc.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_POSTFIX' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         postfix:=tpostfix_install.Create;
         postfix.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

 if ParamStr(1)='APP_FETCHMAIL' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fetchmail:=install_fetchmail.Create();
         fetchmail.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_KAV4PROXY' then begin
         squid:=tsetup_squid.Create;
         squid.kav4proxy_install();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_DAR' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         ddar:=dar.Create;
         ddar.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_DANSGUARDIAN' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         squid:=tsetup_squid.Create;
         squid.dansgardian_install();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;


  if ParamStr(1)='APP_KAV4SAMBA' then begin
         kavsamba:=tsetup_kavsamba.Create;
         kavsamba.xinstall();

         halt(0);
   end;

  if ParamStr(1)='APP_C_ICAP' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         ccicap:=cicap.Create;
         if ParamStr(2)='-configure' then begin
            ccicap.configure();
            writeln('done');
            halt(0);
         end;
         ccicap.xinstall();
         halt(0);
   end;

   if ParamStr(1)='APP_GNARWL' then begin
      fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
      sgnarwl:=gnarwl.Create;
      sgnarwl.xinstall();
      halt(0);
   end;


  if ParamStr(1)='APP_COLLECTD' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         collectd:=tsetup_collectd.Create;
         collectd.collectd_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_KAVMILTER' then begin
         kavmilter:=tsetup_kavmilter.Create;
         if ParamStr(2)='remove' then begin
            kavmilter.xremove();
            halt(0);
         end;

         kavmilter.xinstall();

         halt(0);
   end;

   if ParamStr(1)='APP_KAV4LMS' then begin
         kavmilter:=tsetup_kavmilter.Create;
         kavmilter.xremove();
         kavmilter.kav4lms_xinstall();

         halt(0);
   end;




   if ParamStr(1)='APP_CLAMAV_MILTER' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         clamav:=tsetup_clamav.Create;
         clamav.install_clamav();

         halt(0);
   end;

   if ParamStr(1)='APP_CLAMAV' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         clamav:=tsetup_clamav.Create;
         clamav.install_clamav();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_MILTERGREYLIST' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');

         greylist:=miltergreylist.Create;
         greylist.xinstall();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_MAILSPY' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         mailspy:=milterspy.Create;
         mailspy.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_KAS3' then begin
         kas3:=tsetup_kas3.Create();
         kas3.install_kas3();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_SIMPLE_GROUPEWARE' then begin
         SimpleGroupWare:=tsetup_simple_groupware.Create();
         SimpleGroupWare.install_groupware();

         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_OBM' then begin
         zobm:=tobm_install.Create;
         zobm.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   if ParamStr(1)='APP_ATOPENMAIL' then begin
         atmail:=tatmail.Create();
        if ParamStr(2)='--config' then begin
          atmail.SetConfig();
          halt(0);
        end;


         if ParamStr(2)='patch' then begin
              atmail.PatchingLogonForm();
              halt(0);
         end;

         if ParamStr(2)='reconfigure' then begin
              writeln('Reconfigure Atmail... All datas will be erased...');
              atmail.SetConfig();
              atmail.CreateDatabase();
              zinstall.EMPTY_CACHE();
              halt(0);
         end;


         atmail.xinstall();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;

   //APP_AMAVISD_MILTER --local
   if ParamStr(1)='APP_MAIL_DKIM' then begin
      amavis:=amavisd.Create();
      amavis.install_MAIL_DKIM();
      zinstall.EMPTY_CACHE();
      halt(0);
   end;

   //APP_COMPRESS_ROW_ZLIB
   if ParamStr(1)='APP_COMPRESS_ROW_ZLIB' then begin
      amavis:=amavisd.Create();
      amavis.COMPRESS_ROW_ZLIB();
      halt(0);
   end;


   if ParamStr(1)='APP_AMAVISD_MILTER' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');

       amavis:=amavisd.Create();

       if ParamStr(2)='--local' then begin
          amavis.xinstall();
          zinstall.EMPTY_CACHE();
          halt(0);
       end;


       if ParamStr(2)='dnew' then begin
          amavis.xinstallamavis();
          zinstall.EMPTY_CACHE();
          halt(0);
       end;
       amavis.xinstall();
       zinstall.EMPTY_CACHE();
       halt(0);


   end;


   if ParamStr(1)='APP_AMAVISD_NEW' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
          spamassassin:=tspam.Create;
          spamassassin.xinstall();
          amavis:=amavisd.Create();
          amavis.xinstallamavis();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;




   if ParamStr(1)='APP_ALTERMIME' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         amavis:=amavisd.Create();
         amavis.altermime_install();
         zinstall.EMPTY_CACHE();
       halt(0);
   end;



   if ParamStr(1)='APP_DSPAM' then begin
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
         fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-postfix');
         amavis:=amavisd.Create();
         amavis.dspam_install();
         zinstall.EMPTY_CACHE();
         halt(0);
   end;


   if ParamStr(1)='APP_IMAPSYNC' then begin
          fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
          imaps:=imapsync.Create();
          imaps.xinstall();

          halt(0);
   end;

   if ParamStr(1)='APP_ISOQLOG' then begin
          fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
          zisoqlog:=isoqlog.Create();
          zisoqlog.xinstall();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;

   if ParamStr(1)='APP_DOTCLEAR' then begin
          zdotclear:=dotclear.Create;
          zdotclear.xinstall();
          zinstall.EMPTY_CACHE();
          halt(0);
   end;


   if ParamStr(1)='APP_JCHKMAIL' then begin
      fpsystem('/usr/share/artica-postfix/bin/setup-ubuntu --check-base-system');
      zjcheckmail:=jcheckmail.Create();
      zjcheckmail.xinstall();
      zinstall.EMPTY_CACHE();
      halt(0);
   end;

   if ParamStr(1)='APP_POMMO' then begin
      pommo:=tpommo.Create();
      pommo.xinstall();
      zinstall.EMPTY_CACHE();
      halt(0);
   end;



   writeln('APP_COLLECTD.............: install collectd from sources');
   writeln('APP_VMTOOLS..............: install VMWare Tools');
   writeln('APP_POMMO................: install poMMo from sources');
   writeln('APP_CLAMAV_MILTER........: install clamav and clamav milter');
   writeln('APP_AMAVISD_MILTER.......: install amavisd-new and amavisd-milter');
   writeln('APP_AMAVISD_NEW..........: install amavisd-new');
   writeln('APP_KAVMILTER............: install Kaspersky Anti-virus SendMail edition');
   writeln('APP_MAILSPY..............: install mail-spy');
   writeln('APP_MILTERGREYLIST.......: install milter-greylist');
   writeln('APP_KAS3.................: install Kaspersky Anti-spam 3.x');
   writeln('APP_IMAPSYNC.............: install imapsync');
   writeln('APP_MAILSYNC.............: install mailsync');
   writeln('APP_DSPAM................: install dspam');
   writeln('APP_STUNNEL..............: install Install universal SSL Tunnel');
   writeln('APP_GNUPLOT..............: install gnuplot,dtsat');
   writeln('APP_DSTAT................: install gnuplot,dtsat');
   writeln('APP_HOSTAPD..............: install hostapd (wifi)');
   writeln('APP_GLUSTERFS............: install GlusterFS (Clustering)');
   writeln('APP_JCHKMAIL.............: install jcheckmail');
   writeln('APP_ISOQLOG..............: install isoqlog');

   writeln('');
   writeln('Groupwares applications');
   writeln('___________________________________________________________');
   writeln('APP_JOOMLA...............: install Joomla sources');
   writeln('APP_SUGARCRM.............: install SugarCRM sources');
   writeln('APP_SIMPLE_GROUPEWARE....: install SimpleGroupware from sources');
   writeln('APP_DOTCLEAR.............: install DotClear (blog interface)');
   writeln('APP_ATOPENMAIL...........: install @Mail open (webmail)');
   writeln('APP_ROUNDCUBE3...........: install RoundCube WebMail generation 3');
   writeln('APP_ROUNDCUBE3_SIEVE_RULE: install RoundCube Sieve plugin for RoundCube generation 3');
   writeln('APP_GROUPWARE_APACHE.....: Install dedicated Apache engine for groupwares applications');
   writeln('APP_GROUPWARE_PHP........: Install dedicated PHP engine for groupwares applications');
   writeln('APP_PHPLDAPADMIN.........: Install PhpLDAPadmin');
   writeln('APP_PHPMYADMIN...........: Install phpMyadmin');
   writeln('APP_OBM..................: install OBM v2.1 groupware calendar');
   writeln('APP_OBM2.................: install OBM v2.2 groupware calendar');
   writeln('');
   writeln('SQUID');
   writeln('___________________________________________________________');
   writeln('APP_SQUID................: install SQUID3 with ICAP enabled');
   writeln('APP_SQUID................:  --reconfigure to recompile');
   writeln('APP_SQUID................:  --configure to display only configure directives');
   writeln('');
   writeln('APP_SQUIDGUARD...........: install SquidGuard');
   writeln('APP_SQUIDGUARD...........:  --reconfigure to recompile (not implemented)');
   writeln('APP_SQUIDGUARD...........:  --configure to display only configure directives');
   writeln('');
   writeln('APP_KAV4PROXY............: install Kaspersky For Squid');
   writeln('APP_C_ICAP...............: install c-icap');
   writeln('APP_DANSGUARDIAN.........: install/reconfigure Dansguardian');
   writeln('');

   writeln('APP_EMAIL_RELAY..........: install/reconfigure Email-relay');
   writeln('APP_EMAILRELAY_REMOVE....: Uninstall Email-relay');
   writeln('');
   writeln('File Sharing');
   writeln('___________________________________________________________');
   writeln('APP_SAMBA................: install/reconfigure Samba');
   writeln('APP_KAV4SAMBA............: install Kaspersky For Samba server');
   writeln('APP_KAV4FS...............: install Kaspersky For Linux File server 8.x');



   writeln('APP_BACKUPPC.............: install BackupPC');
   writeln('APP_MLDONKEY.............: install MlDonkey');
   writeln('APP_CUPS_DRV.............: install/reconfigure Cups printers drivers');
   writeln('APP_CUPS_BROTHER.........: install/reconfigure Cups Brother printers drivers');
   writeln('APP_GUTENPRINT...........: install/reconfigure Cups gimp additionals drivers');
   writeln('APP_FOO2ZJS..............: install/reconfigure foo2hp --force to install/upgrade');
   writeln('APP_HPINLINUX............: install/reconfigure HP Printers');
   writeln('');


   writeln('APP_CYRUS_IMAP...........: install/reconfigure Cyrus-imapd');
   writeln('APP_ALTERMIME............: install AlterMIME for amavis');
   writeln('APP_CLAMAV...............: install/update clamav engines');
   writeln('APP_GNARWL...............: install gnarwl vacation addon');
   writeln('APP_MHONARC..............: install MHonArc has a Perl mail-to-HTML converter');
   writeln('APP_MSMTP................: install/reconfigure artica-msmtp ');
   writeln('APP_PFLOGSUMM............: install/reconfigure PFLOGSUMM ');
   writeln('APP_SPAMASSASSIN.........: install/reconfigure SpamAssassin');






   writeln('');
   writeln('ZARAFA');
   writeln('___________________________________________________________');
   writeln('APP_ZARAFA_LIBVMIME......: install libvmime for Zarafa');
   writeln('APP_ZARAFA...............: install Zarafa');
   writeln('APP_ZARAFA...............: --remove to remove and re-install');
   writeln('');





   writeln('APP_PUREFTPD.............: install/reconfigure pure-ftpd');

   writeln('');
   writeln('XAPIAN');
   writeln('___________________________________________________________');
   writeln('APP_XAPIAN...............: install/reconfigure xapian library search');
   writeln('APP_XAPIAN_OMEGA.........: install/reconfigure xapian spider search');
   writeln('APP_XAPIAN_PHP...........: install/reconfigure xapian php library');
   writeln('APP_XPDF APP_UNRTF APP_CATDOC APP_ANTIWORD install/reconfigure xapian convert tools');
   writeln('');













end.

