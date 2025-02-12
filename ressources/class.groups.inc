<?php
if(!is_file(dirname($_SERVER['SCRIPT_FILENAME'])."/ressources/class.templates.inc")){include_once(dirname(__FILE__) . '/class.templates.inc');}else{include_once(dirname($_SERVER['SCRIPT_FILENAME'])."/ressources/class.templates.inc");}
if(!is_file(dirname($_SERVER['SCRIPT_FILENAME'])."/ressources/class.ldap.inc")){include_once(dirname(__FILE__) . '/class.ldap.inc');}else{include_once(dirname($_SERVER['SCRIPT_FILENAME'])."/ressources/class.ldap.inc");}

include_once(dirname(__FILE__) . '/class.mysql.inc');
//sambaGroupType: 2 - domain group (global group)
//sambaGroupType: 5 - local group (built-in group)
 
class groups{
	var $group_id;
	var $hash;
	var $objectClass;
	var $SharedFolders_list=array();
	var $main_array=array();
	var $SharedFolderPrefix='shared_';
	var $members=array();
	var $members_array=array();
	var $computers_array=array();
	var $KasperkyASDatas;
	var $KasperskyASGroupNumber;
	var $KasperkyASDatasRules;
	var $Privileges_array=array();
	var $groupName;
	var $ou;
	var $dn;
	var $ldap_error;
	var $generated_id;
	var $sambaSID;
	var $sambaGroupType;
	var $KavMilterSettings;
	var $DefaultGroupPassword;
	var $objectClasses=array();
	var $LOCAL_SID;
	
	function groups($groupid=null){
		$this->group_id=$groupid;
		$ldap=new clladp();
		if($ldap->ldapFailed){return null;}
		$this->LOCAL_SID=$ldap->LOCAL_SID();
		if($groupid<>null){
			$this->LoadDatas();
			$this->ParseClasses();
			$this->ParseSharedFolders();
			$this->BuildOrdinarySambaGroups();
		}
		
	}
	
	function LoadDatas(){
		$ldap=new clladp();
		$ld =$ldap->ldap_connection;
		$bind =$ldap->ldapbind;
		$suffix=$ldap->suffix;
		
			
		$arr=array('description');
		$sr =@ldap_search($ldap->ldap_connection,$suffix,"(&(gidnumber=$this->group_id)(objectclass=posixGroup))");
		if(!$sr){writelogs("Ressource false query (gidnumber=$this->group_id)",__CLASS__.'/'.__FUNCTION__,__FILE__);return null;}
		$entry_id = ldap_first_entry($ldap->ldap_connection,$sr);
		if(!$entry_id){writelogs("entry_id false query (gidnumber=$this->group_id)",__CLASS__.'/'.__FUNCTION__,__FILE__);return null;}
			$attrs = ldap_get_attributes($ldap->ldap_connection, $entry_id);
			$this->hash=$attrs;
			$dn = ldap_get_dn($ldap->ldap_connection,$entry_id);
			
			if(preg_match('#,dc=samba,#',$dn)){
				$hasSambaGroup=true;
			}
			

			
			
			$this->dn=$dn;
			if(preg_match('#ou=groups,ou=(.+?),dc#',$dn,$reg)){$res["ou"]=$reg[1];}
			//writelogs("Group ID $this->group_id is in the root \"$dn\" and ou=\"{$res["ou"]}\"",__CLASS__.'/'.__FUNCTION__,__FILE__);
		
			
			$res["dn"]=$dn;
			$res["cn"]=$attrs["cn"][0];
			$this->groupName=$res["cn"];
			$res["dn_ou"]=str_replace("cn={$res["cn"]},","",$res["dn"]);
			$res["gid"]=$attrs["gidNumber"][0];
			$res["description"]=stripslashes($attrs["description"][0]);
			$res["KasperkyAVScanningDatas"]=$attrs["KasperkyAVScanningDatas"][0];
			$this->DefaultGroupPassword=$attrs["DefaultGroupPassword"][0];
			
			$res["KasperkyASDatas"]=$attrs["KasperkyASDatas"][0];
			$this->KasperkyASDatas=$attrs["KasperkyASDatas"][0];
			
			$this->KasperskyASGroupNumber=$attrs["KasperskyASGroupNumber"][0];
			$res["KasperskyASGroupNumber"]=$attrs["KasperskyASGroupNumber"][0];
			
			$this->KasperkyASDatasRules=$attrs["KasperkyASDatasRules"][0];
			$res["KasperkyASDatasRules"]=$attrs["KasperkyASDatasRules"][0]
			;
			$res["ArticaDansGuardianGroupRuleEnabled"]=$attrs["ArticaDansGuardianGroupRuleEnabled"][0];
			
			//SharedFolderPrefix//SharedFolderList//class SharedFolders
			
			if($res["ArticaDansGuardianGroupRuleEnabled"]==null){
				$upd["ArticaDansGuardianGroupRuleEnabled"]="0";
				if(!$hasSambaGroup){$ldap->Ldap_add_mod($dn,$upd);}
				unset($upd);
				$res["ArticaDansGuardianGroupRuleEnabled"]=0;
				}
			
			for($i=0;$i<$attrs["memberUid"]["count"];$i++){
				$res["ARRAY_MEMBERS"][]=$attrs["memberUid"][$i];
				$this->members[]=$attrs["memberUid"][$i];
				$this->members_array[$attrs["memberUid"][$i]]=true;
					if(substr($attrs["memberUid"][$i],strlen($attrs["memberUid"][$i])-1,1)=='$'){
						$this->computers_array[$attrs["memberUid"][$i]]=$attrs["memberUid"][$i];
					}
					$users[$attrs["memberUid"][$i]]=$attrs["memberUid"][$i];
				}
				
			for($i=0;$i<$attrs["FiltersExtensionsGroupName"]["count"];$i++){
					$res["FiltersExtensionsGroupName"][$attrs["FiltersExtensionsGroupName"][$i]]="yes";
				}				
				
			for($i=0;$i<$attrs["objectClass"]["count"];$i++){
					$this->objectClasses[$attrs["objectClass"][$i]]=true;
				}		
				
				
				
			$res["SharedFolderPrefix"]=$attrs["SharedFolderPrefix"][0];
			$this->SharedFolderPrefix=$res["SharedFolderPrefix"];
			$res["members"]=$users;
			
			if(preg_match_all('#\[([a-zA-Z]+)\]="([a-z0-9]+)"#is',$attrs["ArticaGroupPrivileges"][0],$reg)){
				while (list ($num, $ligne) = each ($reg[1]) ){$priv[$ligne]=$reg[2][$num];}
			}
			$res["ArticaGroupPrivileges"]=$priv;
			$this->Privileges_array=$priv;
			
			if(preg_match("#ou=groups,ou\=([a-zA-Z0-9\s\.\-\(\)_]+)#i",$dn,$pre)){
				$res["ou"]=trim($pre[1]);
			}
			
			$this->ou=$res["ou"];
			$this->sambaSID=$attrs["sambaSID"][0];
			$this->sambaGroupType=$attrs["sambaGroupType"][0];
			$this->main_array=$res;
			
			$this->KavMilterSettings=$this->LoadKavMilterGroup();
			
			return $res;		
		
		
	}
	
	function SavePrivileges(){
		$conf="#";
		if(is_array($this->Privileges_array)){
			while (list ($num, $ligne) = each($this->Privileges_array)){
				$conf=$conf . "[$num]=\"$ligne\"\n";
				}
			
		}
		$res["ArticaGroupPrivileges"][0]=$conf;
		$ldap=new clladp();
		if(!$ldap->Ldap_modify($this->dn,$res)){
			echo "$this->group_id::$this->ou\n".$tpl->_ENGINE_parse_body("{privileges}:\n$ldap->ldap_last_error");
		}else{
			$tpl=new templates();
			echo "$this->group_id::$this->ou\n".$tpl->_ENGINE_parse_body("{privileges}:{success}");
		}
		
		
	}
	
	function LoadKavMilterGroup(){
		$users=new usersMenus();
		if($users->KAV_MILTER_INSTALLED){
			$users->LoadModulesEnabled();
			if($users->KAVMILTER_ENABLED==1){
				include_once(dirname(__FILE__).'/class.kavmilterd.inc');
				$kav=new kavmilterd();
				$kav->LoadRule("$this->groupName.$this->ou");
				return $kav->RuleDatas;
			}
		}
		}
		
	function edit_DefaultGroupPassword(){
		$upd["DefaultGroupPassword"][0]=$this->DefaultGroupPassword;
		$ldap=new clladp();
		if(!$ldap->Ldap_modify($this->dn,$upd)){
			$this->ldap_error=$ldap->ldap_last_error;
			return false;
		}
		return true;
		}
		
	function changeAllMembersPassword(){
		$password=$this->DefaultGroupPassword;
		if(trim($password)==null){return false;}
		if(!is_array($this->members_array)){return false;}
		reset($this->members_array);
		while (list ($num, $line) = each ($this->members_array)){
			writelogs("Changing password for $num",__CLASS__.'/'.__FUNCTION__,__FILE__);	
			$users=new user($num);
			$users->password=$password;
			$users->add_user();
			$users=null;
		}
		
		return true;
	}
	
	function add_new_group($group,$ou=null,$generated_id=null){
		$group=replace_accents($group);
		
		if(!is_numeric($generated_id)){$generated_id=null;}
		
		if($generated_id==null){
			$generated_id=$this->_GenerateGUID();
			if($generated_id<1001){$generated_id=1001;}
			if($generated_id==1){$generated_id=1001;}
		}
		
		writelogs("Adding \"$group\" in organization \"$ou\" ($generated_id)",__CLASS__.'/'.__FUNCTION__,__FILE__);	
		$this->generated_id=$generated_id;
		$ldap=new clladp();
		if($ou==null){
			
		}
		
		
		if($ou==null){$dn="cn=$group,ou=groups,dc=organizations,$ldap->suffix";}
		else{$dn="cn=$group,ou=groups,ou=$ou,dc=organizations,$ldap->suffix";}
		
		$dn_master_branch="ou=groups,ou=$ou,dc=organizations,$ldap->suffix";
		if(!$ldap->ExistsDN($dn_master_branch)){
			$update_array["objectClass"][]="top";
			$update_array["objectClass"][]="organizationalUnit";
			$update_array["ou"][]="groups";
			if(!$ldap->ldap_add($dn_master_branch,$update_array)){
				echo "Unable to add master branch\n$dn_master_branch\n$this->ldap_last_error";
				return false;
			}
			unset($update_array);
			
		}
		
		
		
		$update_array["cn"][0]="$group";
		$update_array["gidNumber"][0]=$generated_id;
		$update_array["description"][0]="New posix group";
		$update_array["objectClass"][]='posixGroup';
		$update_array["objectClass"][]='ArticaSettings';
		$update_array["objectClass"][]='top';
		
		
		
		$dn=$ldap->dn_escape($dn);
		
		if($ldap->ExistsDN($dn)){
			writelogs("Adding \"$dn\" already exists...",__CLASS__.'/'.__FUNCTION__,__FILE__);
			$this->generated_id=$this->GroupIDFromName($ou,$group);
			writelogs("Return back to generated_id has $this->generated_id",__CLASS__.'/'.__FUNCTION__,__FILE__);
			return true;
		}
		
		writelogs("Adding \"$dn\" in $ldap->suffix",__CLASS__.'/'.__FUNCTION__,__FILE__);	
		
		if(!$ldap->ldap_add($dn,$update_array)){
			$this->ldap_error=
				"Error: Adding {$update_array["gidNumber"][0]} gid 
				cn=$group\ndn:$dn\n".
				$ldap->ldap_last_error;
			return false;
		}
		
		return true;
	}	
	
  private function _GenerateGUID(){
  		$ldap=new clladp();
  		$ld =$ldap->ldap_connection;
		$bind =$ldap->ldapbind;
		
		$pattern="(&(objectClass=posixGroup)(gidNumber=*))";
		$attr[]="gidNumber";
      	$sr =@ldap_search($ldap->ldap_connection,$ldap->suffix,$pattern,$attr);
      		if ($sr){
				$hash=ldap_get_entries($ldap->ldap_connection,$sr);
				if($hash["count"]>0){
					for($i=0;$i<$hash["count"];$i++){
						$g=$hash[$i]["gidnumber"][0];
						if($g>$a){$a=$g;}
					}
		      			
				}
				if($a==0){$a=1001;}
         		writelogs("Last group number was $a",__CLASS__.'/'.__FUNCTION__,__FILE__);
         		return $a+1;
      		}
     		 return 1001;
   		}	
	
	
	function user_add_to_group($uid){
		$ldap=new clladp();
		if($this->members_array[$uid]==true){return true;}
		
		writelogs("$uid is not a member of $this->group_id ($this->dn)",__CLASS__.'/'.__FUNCTION__,__FILE__);
		$update_array["memberUid"]=$uid;
		writelogs("add memberUid=$uid",__CLASS__.'/'.__FUNCTION__,__FILE__);
		
		if($ldap->Ldap_add_mod($this->dn,$update_array)){
			writelogs("add memberUid=$uid failed...",__CLASS__.'/'.__FUNCTION__,__FILE__);
			return false;
		}
		if(trim($ldap->ldap_last_error)<>null){echo $ldap->ldap_last_error;return false;}
		
		$this->UpdatePlugins();
		
		return true;
		}
		
	function user_delete_from_all_groups($uid){
		$ldap=new clladp();
		$dn="dc=organizations,$ldap->suffix";
		$pattern="(memberUid=$uid)";
		$sr =@ldap_search($ldap->ldap_connection,$dn,"$pattern",array('gidNumber'));
		if(!$sr){return null;}
		$hash = ldap_get_entries($ldap->ldap_connection,$sr);
		echo "<ul>\n";
		for($i=0;$i<$hash["count"];$i++){
			$group=new groups($hash[$i]["gidnumber"][0]);
			if($group->DeleteUserFromThisGroup($uid)){
				echo "<lI>$uid -> {$hash[$i]["gidnumber"][0]} OK</li>\n";
			}
			
		}
			
		echo "</ul>\nDone...\n<br>";
		$this->UpdatePlugins();
		
	}
	
	private function UpdatePlugins(){
		$users=new usersMenus();
		if($users->DANSGUARDIAN_INSTALLED){
			$sock=new sockets();
			$sock->getFrameWork("cmd.php?reload-dansguardian=yes");
		}
	}
		
		
	function GroupIDFromName($ou,$groupname){
		$ldap=new clladp();
		$dn="ou=groups,ou=$ou,dc=organizations,$ldap->suffix";
		$sr =@ldap_search($ldap->ldap_connection,$dn,"(&(cn=$groupname)(objectClass=posixGroup))",array('gidNumber'));
		if(!$sr){return null;}
		$entry_id = ldap_first_entry($ldap->ldap_connection,$sr);
		if($entry_id){
			$attrs = ldap_get_attributes($ldap->ldap_connection, $entry_id);
			return $attrs["gidNumber"][0];
		}		
		
	}		
		
		
	function TransformGroupToSmbGroup(){
		$users=new usersMenus();
		
		$upd["objectClass"][]="sambaGroupMapping";
		$upd["sambaGroupType"][]=5;
		$upd["sambaSID"][]=$this->LOCAL_SID. "-$this->group_id";
		$ldap=new clladp();
		$ldap->Ldap_add_mod($this->dn,$upd);
		}
	
	
	function ParseClasses(){
		if($this->dn==null){return null;}
		$array=$this->hash["objectClass"];
		for($i==0;$i<$array["count"];$i++){
			$this->objectClass[$array[$i]]=true;
		}
		
		if(!$this->objectClass["SharedFolders"]){
			$ldap=new clladp();
			$res["objectClass"][]="SharedFolders";
			$res["SharedFolderPrefix"]='shared_';
			$res["SharedFolerConf"]="NONE";
			$ldap->Ldap_add_mod($this->dn,$res);
			unset($res);
		}
	 }
	 
	 function ParseSharedFolders(){
	 	$array=$this->hash["SharedFolderList"];
	 	for($i=0;$i<$array["count"];$i++){
			$this->SharedFolders_list[]=$array[$i];
		}
	 }
	 
	 function add_sharedfolder($path){
	 	$ldap=new clladp();
	 	if($this->dn==null){$this->dn=$this->main_array["dn"];}
	 	if($path==null){return false;}
	 	$res["SharedFolderList"]=$path;
	 	writelogs("$this->dn add \"$path\"",__CLASS__.'/'.__FUNCTION__,__FILE__);
	 	$ldap->Ldap_add_mod($this->dn,$res);
	 	$this->SaveCharedConf();
	 	}
	 	
	 function AddUsertoThisGroup($uid){
	 	$ldap=new clladp();
	 	$upd["memberUid"]=$uid;
	 	$ldap->Ldap_add_mod($this->dn,$upd);
	 	
	 }
	 
	 function DeleteUserFromThisGroup($uid){
	 	$ldap=new clladp();
	 	$upd["memberUid"]=$uid;
	 	writelogs("$this->dn Del memberUid=\"$uid\"",__CLASS__.'/'.__FUNCTION__,__FILE__);
	 	$this->UpdatePlugins();
	 	return $ldap->Ldap_del_mod($this->dn,$upd);
	 }
	 
	 public function Delete(){
	 	$ldap=new clladp();
	 	if($ldap->ExistsDN($this->dn)){
	 		$ldap->ldap_delete($this->dn);
	 	}
	 	
	 	$sql="DELETE FROM dansguardian_groups WHERE group_id=$this->group_id";
	 	$q=new mysql();
	 	$q->QUERY_SQL($sql,"artica_backup");
	 	
	 	$this->UpdatePlugins();
	 	$this->SaveCharedConf();
	 	
	 }
	 	
	 function del_sharedfolder($index){
	 	$ldap=new clladp();
	 	if($this->dn==null){$this->dn=$this->main_array["dn"];}
	 	$res["SharedFolderList"]=$this->SharedFolders_list[$index];
	 	writelogs("$this->dn del \"{$res["SharedFolderList"]}\"",__CLASS__.'/'.__FUNCTION__,__FILE__);
	 	$ldap->Ldap_del_mod($this->dn,$res);
	 	$autofs=new autofs();
	 	$autofs->AutofsDeleteDir($this->group_id,$res["SharedFolderList"]);
	 	}
	 function edit_SharedFolderPrefix(){
		$ldap=new clladp();
	 	if($this->dn==null){$this->dn=$this->main_array["dn"];}
	 	$res["SharedFolderPrefix"][0]=$this->SharedFolderPrefix;
	 	if(!$ldap->Ldap_modify($this->dn,$res)){echo $ldap->ldap_last_error;}else{
	 		$tpl=new templates();
	 		$this->SaveCharedConf();
	 		echo $tpl->_ENGINE_parse_body('
	 		Prefix:{success}');
	 	}
	 }
	 
	 
	 //SharedConfDeleteFolderAll
	 
	 
	 function BuildSharedFolderConf(){
	 	
	 	$ldap=new clladp();
	 	$conf="[SHARED]\n";
	 	$conf=$conf . "key=" . md5(date('Y-m-d H:I:s'))."\n";
	 	$conf=$conf . "groupid=$this->group_id\n";
	 	$conf=$conf. "SharedFolderPrefix=$this->SharedFolderPrefix\n";
	 	$conf=$conf."[SHARED_FOLDERS]\n";
	 	$conf=$conf."sharedfolder_count=" . count($this->SharedFolders_list) ."\n";
	 	for($i=0;$i<count($this->SharedFolders_list);$i++){
			$conf=$conf."shared.$i={$this->SharedFolders_list[$i]}\n";
	 	}
		
	 	$conf=$conf."[members]\n";
	 	$conf=$conf."members_count=" . count($this->members) ."\n";	
	 	
	 	
	 	
	 	for($i=0;$i<count($this->members);$i++){
	 		$hash=$ldap->UserDatas($this->members[$i]);
	 		$homeDirectory=$hash["homeDirectory"];
	 		if($homeDirectory<>null){
	 			$conf=$conf."member.$i=$homeDirectory\n";
	 		}
	 	}
	 		
	 	return $conf;	
	 	}
	 	
	 	function SaveCharedConf(){
	 		$ldap=new clladp();
	 		include_once(dirname(__FILE__).'/class.autofs.inc');
	 		$autofs=new autofs();
	 		$autofs->AutofsSharedDir($this->group_id);
	 		$sock=new sockets();
	 		$sock->getfile('autofsReload');
	 		
	 	}
	 	
	 	
	 	function BuildWhitelistArray(){
	 		$ldap=new clladp();
	 		$domains=$ldap->hash_get_domains_ou($this->ou);
	 		if(!is_array($domains)){return null;}
	 		while (list ($num, $line) = each ($domains)){
	 			$hash=$ldap->WhitelistsFromDomain($line);
	 			if(is_array($hash)){
	 				while (list ($a, $b) = each ($hash)){
	 					$email=$a;
	 					$uid=$ldap->uid_from_email($email);
		 				if($this->members_array[$uid]){
		 					while (list ($c, $d) = each ($b)){
		 						$i[]=$d;
		 					}
		 				}
		 			}
	 			}
	 		}
	 	return $i;	
	 	}
	 	
	 	function BuildBlackListArray(){
	 		$ldap=new clladp();
	 		$domains=$ldap->hash_get_domains_ou($this->ou);
	 		if(!is_array($domains)){return null;}
	 		while (list ($num, $line) = each ($domains)){
	 			$hash=$ldap->BlackListFromDomain($line);
	 			if(is_array($hash)){
	 				while (list ($a, $b) = each ($hash)){
	 					$email=$a;
	 					$uid=$ldap->uid_from_email($email);
		 				if($this->members_array[$uid]){
		 					while (list ($c, $d) = each ($b)){
		 						$i[]=$d;
		 					}
		 				}
		 			}
	 			}
	 		}
	 	return $i;	
	 	}

	 	function BuildEmailsList(){
	 		if(!is_array($this->members)){return null;}
	 		$arr=$this->members;
	 		$ldap=new clladp();
	 		while (list ($num, $line) = each ($arr)){
	 			$hash=$ldap->UserDatas($line);
	 			if(is_array($hash["mailAlias"])){
	 				while (list ($a, $b) = each ($hash["mailAlias"])){
	 					$re[]=$b;
	 					
	 				}
	 			}
	 			if($hash["mail"]<>null){$re[]=$hash["mail"];}
	 		}
	 	 	
	 	return $re;
	 	}
	 	
	 	
	 	
	 	function BuildOrdinarySambaGroups(){
	 		$users=new usersMenus();
	 		$ldap=new clladp();
	 		if($users->SAMBA_INSTALLED==false){return null;}
	 		$this->SambaGroupsBuild();
	 		$dn="cn=users,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 		
	 		if(!$ldap->ExistsDN($dn)){
	 				writelogs("Creating $dn",__CLASS__.'/'.__FUNCTION__,__FILE__);
	 				$u["objectClass"][]="top";
	 				$u["objectClass"][]="posixGroup";
	 				$u["objectClass"][]="sambaGroupMapping";
	 				$u["gidNumber"][]=545;
	 				$u["description"][]="Netbios Domain Ordinary users";
	 				$u["sambaSID"][]="S-1-5-32-545";
	 				$u["sambaGroupType"][]="4";
	 				$u["displayName"][]="users";
	 				$u["cn"][]="users";
	 				$ldap->ldap_add($dn,$u);
	 				unset($u);
	 		}
					 		
	 		
	 	}
	 	

function EditSambaGroups(){
	 		$users=new usersMenus();
	 		$tpl=new templates();
	 		$ldap=new clladp();
			if($users->SAMBA_INSTALLED==false){return null;}
			
	 	$dn="cn=Domain Admins,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 		$this->SambaGroupsBuild();
	 		return null;
	 	}
	 	
	if($this->LOCAL_SID==null){
		writelogs("LOCAL_SID=NULL! Aborting",__CLASS__.'/'.__FUNCTION__,__FILE__);
		return false;
	}

	writelogs("LOCAL_SID=$this->LOCAL_SID",__CLASS__.'/'.__FUNCTION__,__FILE__); 
	$u["sambaSID"][0]="$this->LOCAL_SID-512";	
	writelogs("Editing groups...$dn",__CLASS__.'/'.__FUNCTION__,__FILE__); 			
	if(!$ldap->Ldap_modify($dn,$u)){
		echo $tpl->_ENGINE_parse_body("$dn {failed}\n$ldap->ldap_last_error\n\n");
	 	unset($u);
	 }	

	 
	 $dn="cn=Domain Computers,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 $u["sambaSID"][0]="$this->LOCAL_SID-515";	

	if(!$ldap->Ldap_modify($dn,$u)){
			echo $tpl->_ENGINE_parse_body("$dn {failed}\n$ldap->ldap_last_error\n\n");
		 	unset($u);
		 }		 
	
	 $dn="cn=Domain Guests,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 $u["sambaSID"][0]="$this->LOCAL_SID-514";
	if(!$ldap->Ldap_modify($dn,$u)){
			echo $tpl->_ENGINE_parse_body("$dn {failed}\n$ldap->ldap_last_error\n\n");
		 	unset($u);
		 }		 
	
	 $dn="cn=Domain Users,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 $u["sambaSID"][0]="$this->LOCAL_SID-513";
	if(!$ldap->Ldap_modify($dn,$u)){
			echo $tpl->_ENGINE_parse_body("$dn {failed}\n$ldap->ldap_last_error\n\n");
		 	unset($u);
		 }	

     $dn="cn=domguests,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 $u["sambaSID"][0]="$this->LOCAL_SID-514";
	if(!$ldap->Ldap_modify($dn,$u)){
			echo $tpl->_ENGINE_parse_body("$dn {failed}\n$ldap->ldap_last_error\n\n");
		 	unset($u);
		 }	
	  
}
	 	
	 	
 function SambaGroupsBuild(){
	 		$users=new usersMenus();
	 		$ldap=new clladp();
	 		if($users->SAMBA_INSTALLED==false){return null;}
	 		$dn="dc=samba,dc=organizations,$ldap->suffix";
	 		$ldap=new clladp();
	 		if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="organization";
	 			$u["objectClass"][]="dcObject";
	 			$u["o"][]="samba";
	 			$u["dc"][]="samba";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 		}
	 		
	 		
	$dn="ou=users,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="organizationalUnit";
	 			$u["ou"][]="users";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}
	 			
 	$dn="ou=idmap,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="organizationalUnit";
	 			$u["ou"][]="idmap";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}	 			
	 			
	$dn="ou=Computer,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="organizationalUnit";
	 			$u["ou"][]="Computer";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}
	 			
	 	$dn="ou=People,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="organizationalUnit";
	 			$u["ou"][]="People";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}	 			
	 			
	 	$dn="ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="organizationalUnit";
	 			$u["ou"][]="groups";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}
	 			
	 	$dn="cn=Account Operators,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="posixGroup";
	 			$u["objectClass"][]="sambaGroupMapping";
	 			$u["gidNumber"][]="548";
	 			$u["cn"][]="Account Operators";
	 			$u["description"][]="Netbios Domain Users to manipulate users accounts";
				$u["sambaSID"][]="S-1-5-32-548";	 			
				$u["sambaGroupType"][]="4";
				$u["displayName"][]="Account Operators";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}	
	 			
	 	$dn="cn=Administrators,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="posixGroup";
	 			$u["objectClass"][]="sambaGroupMapping";
	 			$u["gidNumber"][]="544";
	 			$u["cn"][]="Administrators";
	 			$u["description"][]="Netbios Domain Users to manipulate users accounts";
				$u["sambaSID"][]="S-1-5-32-544";	 			
				$u["sambaGroupType"][]="4";
				$u["displayName"][]="Administrators";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}

	

	 	$dn="cn=Backup Operators,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="posixGroup";
	 			$u["objectClass"][]="sambaGroupMapping";
	 			$u["gidNumber"][]="551";
	 			$u["cn"][]="Backup Operators";
	 			$u["description"][]="Netbios Domain Members can bypass file security to back up file";
				$u["sambaSID"][]="S-1-5-32-551";	 			
				$u["sambaGroupType"][]="4";
				$u["displayName"][]="Backup Operators";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}

	 	$dn="cn=Guests,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="posixGroup";
	 			$u["objectClass"][]="sambaGroupMapping";
	 			$u["gidNumber"][]="546";
	 			$u["cn"][]="Guests";
	 			$u["description"][]="Netbios Domain Users granted guest access to the computer/sambaDomainName";
				$u["sambaSID"][]="S-1-5-32-546";	 			
				$u["sambaGroupType"][]="5";
				$u["displayName"][]="Guests";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}

	 	$dn="cn=domguests,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="posixGroup";
	 			$u["objectClass"][]="sambaGroupMapping";
	 			$u["gidNumber"][]="1999";
	 			$u["cn"][]="domguests";
	 			$u["description"][]="Netbios Domain Users granted guest access to the computer/sambaDomainName";
				$u["sambaSID"][]="$this->LOCAL_SID-514";	 			
				$u["sambaGroupType"][]="2";
				$u["displayName"][]="Domain Guests";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}		 			

 			
	 	$dn="cn=Domain Admins,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="posixGroup";
	 			$u["objectClass"][]="sambaGroupMapping";
	 			$u["gidNumber"][]="512";
	 			$u["cn"][]="Domain Admins";
	 			$u["description"][]="Netbios Domain Administrators";
				$u["sambaSID"][]="$this->LOCAL_SID-512";	 			
				$u["sambaGroupType"][]="2";
				$u["displayName"][]="Domain Admins";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}	 

	 	$dn="cn=Domain Computers,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 	if(!$ldap->ExistsDN($dn)){
	 			$u["objectClass"][]="top";
	 			$u["objectClass"][]="posixGroup";
	 			$u["objectClass"][]="sambaGroupMapping";
	 			$u["gidNumber"][]="515";
	 			$u["cn"][]="Domain Computers";
	 			$u["description"][]="Netbios Domain Computers accounts";
				$u["sambaSID"][]="$this->LOCAL_SID-515";	 			
				$u["sambaGroupType"][]="2";
				$u["displayName"][]="Domain Computers";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}	 			 			

	 			
		$dn="cn=Domain Guests,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
		if(!$ldap->ExistsDN($dn)){
				$u["objectClass"][]="top";
				$u["objectClass"][]="posixGroup";
				$u["objectClass"][]="sambaGroupMapping";
				$u["gidNumber"][]="514";
				$u["cn"][]="Domain Guests";
				$u["description"][]="Netbios Domain Guests Users";
				$u["sambaSID"][]="$this->LOCAL_SID-514";
				$u["sambaGroupType"][]="2";
				$u["displayName"][]="Domain Guests";
	 			if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 	}	
		$dn="cn=Domain Users,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
		if(!$ldap->ExistsDN($dn)){
				$u["objectClass"][]="top";
				$u["objectClass"][]="posixGroup";
				$u["objectClass"][]="sambaGroupMapping";
				$u["gidNumber"][]="513";
				$u["cn"][]="Domain Users";
				$u["description"][]="Netbios Domain Users";
				$u["sambaSID"][]="$this->LOCAL_SID-513";
				$u["sambaGroupType"][]="2";
				$u["displayName"][]="Domain Users";
				if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 	}	

		$dn="cn=Print Operators,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
		if(!$ldap->ExistsDN($dn)){
				$u["objectClass"][]="top";
				$u["objectClass"][]="posixGroup";
				$u["objectClass"][]="sambaGroupMapping";
				$u["gidNumber"][]="550";
				$u["cn"][]="Print Operators";
				$u["description"][]="Netbios Domain Print Operators";
				$u["sambaSID"][]="S-1-5-32-550";
				$u["sambaGroupType"][]="4";
				$u["displayName"][]="Print Operators";
				if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 	}	

		$dn="cn=Replicators,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
		if(!$ldap->ExistsDN($dn)){
				$u["objectClass"][]="top";
				$u["objectClass"][]="posixGroup";
				$u["objectClass"][]="sambaGroupMapping";
				$u["gidNumber"][]="552";
				$u["cn"][]="Replicators";
				$u["description"][]="Netbios Domain Supports file replication in a sambaDomainName";
				$u["sambaSID"][]="S-1-5-32-552";
				$u["sambaGroupType"][]="4";
				$u["displayName"][]="Replicators"; 			
				if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 	}
	 	
		$dn="cn=root,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
		if(!$ldap->ExistsDN($dn)){
				$u["objectClass"][]="top";
				$u["objectClass"][]="posixGroup";
				$u["objectClass"][]="sambaGroupMapping";
				$u["sambaSID"][]="S-1-5-32-0";
				$u["sambaGroupType"][]="4";
				$u["gidNumber"][]="0";
				$u["cn"][]="root";
				$u["description"][]="Unix virtual system group";
				$u["displayName"][]="root"; 			
				if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}
	 			
	 $dn="cn=Everyone,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
 		if(!$ldap->ExistsDN($dn)){
				$u["objectClass"][]="top";
				$u["objectClass"][]="posixGroup";
				$u["objectClass"][]="sambaGroupMapping";
				$u["sambaSID"][]="S-1-1-0";
				$u["sambaGroupType"][]="4";
				$u["gidNumber"][]="1998";
				$u["cn"][]="Everyone";
				$u["description"][]="Everyone";
				$u["displayName"][]="Everyone"; 			
				if(!$ldap->ldap_add($dn,$u)){return null;}
	 			unset($u);
	 			}	 
	 			

	 			

	 	} 	

	 	

	 	
	 	function samba_group_list(){
	 		$ldap=new clladp();
	 		$filter=array("gidnumber","cn");
	 		$dr =@ldap_search($ldap->ldap_connection,$ldap->suffix,"(objectClass=sambaGroupMapping)",$filter);	
			if($dr){
				$result =@ldap_get_entries($ldap->ldap_connection, $dr);
				for($i=0;$i<$result["count"];$i++){
					$gt=$result[$i];
					$res[$gt["gidnumber"][0]]=$gt["cn"][0];
					
				}
			}
	 		
	 		return $res;
	 		
	 	}
	 	
	 	function ChangeSMBGroupsSID(){
	 		$ldap=new clladp();
	 		$users=new usersMenus();
	 		
	 		$dn="cn=Domain Users,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 		if(!$ldap->ExistsDN($dn)){$this->SambaGroupsBuild();return null;}
	 		$u["sambaSID"][0]="$this->LOCAL_SID-513";
	 		$ldap->Ldap_modify($dn,$u);
	 		unset($u);
	 		
	 			 		
	 		$dn="cn=Domain Guests,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 		$u["sambaSID"][0]="$this->LOCAL_SID-514";
	 		$ldap->Ldap_modify($dn,$u);
	 		unset($u);
	 		
	 		$dn="cn=Domain Computers,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 		$u["sambaSID"][0]="$this->LOCAL_SID-515";	
			$ldap->Ldap_modify($dn,$u);
	 		unset($u);	 	

	 		$dn="cn=Domain Admins,ou=groups,dc=samba,dc=organizations,$ldap->suffix";
	 		$u["sambaSID"][0]="$this->LOCAL_SID-512";	
	 		$ldap->Ldap_modify($dn,$u); 	
	 		unset($u);	

	 		
			$ldap=new clladp();
			$filter_search="(&(objectClass=sambaGroupMapping)((cn=*))";
			$attrs=array("gidNumber","dn");
			$dn="dc=organizations,$ldap->suffix";
			$hash=$this->samba_group_list();	
			
			while (list ($num, $line) = each ($hash)){
				if($num>600){
					$gpi=new groups($num);
					$gpi->EditAsSamba();
					
				}
	 			
			}				
	 		
	 		
	 	}
	 	
	 	
	 	function samba_standard_groups(){
	 		$ldap=new clladp();
	 		$filter=array("gidnumber","cn");
	 		$dr =ldap_search($ldap->ldap_connection,"dc=samba,dc=organizations,$ldap->suffix","(objectClass=sambaGroupMapping)",$filter);	
			if($dr){
				$result = ldap_get_entries($ldap->ldap_connection, $dr);
				for($i=0;$i<$result["count"];$i++){
					$gt=$result[$i];
					$res[$gt["gidnumber"][0]]=$gt["cn"][0];
					
				}
			}
	 		
	 		return $res;
	 		
	 		
	 	}
	 	
	 	function samba_group_id_from_sid($sid){
	 		$ldap=new clladp();
	 		//writelogs("Search samba SID $sid",__CLASS__.'/'.__FUNCTION__,__FILE__);
	 		$filter=array("gidNumber");
	 		$dr =ldap_search($ldap->ldap_connection,"dc=organizations,$ldap->suffix","(&(objectClass=sambaGroupMapping)(sambaSID=$sid))",$filter);
	 		if($dr){
				$result = ldap_get_entries($ldap->ldap_connection, $dr);
				//writelogs("gidNumber={$result[0]["gidnumber"][0]}",__CLASS__.'/'.__FUNCTION__,__FILE__);
				return $result[0]["gidnumber"][0];
	 		}else{
	 			writelogs("Query was unable to find gidNumber in query (&(objectClass=sambaGroupMapping)(sambaSID=$sid))",__CLASS__.'/'.__FUNCTION__,__FILE__);
	 		}
	 		
	 	}
	 	
	 	function samba_group_sid_from_gid($gid){
	 	$ldap=new clladp();
	 		$filter=array("sambaSID");
	 		$dr =ldap_search($ldap->ldap_connection,"dc=organizations,$ldap->suffix","(&(objectClass=sambaGroupMapping)(gidNumber=$gid))",$filter);
	 		if($dr){
				$result = ldap_get_entries($ldap->ldap_connection, $dr);
				//writelogs("sambaSID($gid)={$result[0]["sambasid"][0]}",__CLASS__.'/'.__FUNCTION__,__FILE__);
				return $result[0]["sambasid"][0];
				
	 		}else{
	 			writelogs("Query was unable to find sambaSID in query (&(objectClass=sambaGroupMapping)(gidNumber=$gid))",__CLASS__.'/'.__FUNCTION__,__FILE__);
	 		}
	 		
	 	}
	 	
	 	
	 	function CountMailingListes(){
	 		if($this->ou==null){return null;}
	 		$ldap=new clladp();
	 		$filter=array("cn");
	 		$dn="ou=$this->ou,dc=organizations,$ldap->suffix";
	 		$dr=ldap_search($ldap->ldap_connection,$dn,"(&(objectClass=MailingAliasesTable)(mailinglistaddress=*))",$filter);
	 		if($dr){
				$result = ldap_get_entries($ldap->ldap_connection, $dr);
				return $result["count"];
	 		}else{
	 			writelogs("Failed search in $dn",__FUNCTION__.'/'.__CLASS__,__FILE__);
	 			return 0;
	 		}
	 		return 0;
	 	}
	 	
	 	function load_MailingList($ou){
			$ldap=new clladp();
	 		$filter=array();
	 		$res=array();
	 		$dr =ldap_search($ldap->ldap_connection,"ou=$ou,dc=organizations,$ldap->suffix","(&(objectClass=MailingAliasesTable)(mailinglistaddress=*))",$filter);
	 		if($dr){
				$result = ldap_get_entries($ldap->ldap_connection, $dr);
				for($i=0;$i<$result["count"];$i++){
					if($result[$i]["mailinglistaddress"]["count"]==0){continue;}
					$res[$result[$i]["cn"][0]]=$result[$i]["mailinglistaddress"]["count"];
				}
	 		}
	 		return $res;
	 	}
	 	
	 	
		function list_of_groups($ou,$fieldlist=0){
		$ldap=new clladp();
		$pos=strpos($ou,',');
		if($pos>0){$ou=substr($ou,0,$pos);}
		$ld =$ldap->ldap_connection;
		$bind =$ldap->ldapbind;
		$suffix=$ldap->suffix;	
		$cols=array("cn","description",'gidnumber');
		$sr = @ldap_search($ld,"ou=groups,ou=$ou,dc=organizations,$suffix",'objectclass=posixGroup',$cols);
		if ($sr) {
			$hash=ldap_get_entries($ld,$sr);
			while (list ($num, $ligne) = each ($hash) ){
				if($ligne["cn"][0]<>null){
					switch ($fieldlist) {
						case 1:$res[$ligne["gidnumber"][0]]=$ligne["cn"][0];break;
						case 2;$res=$res . "{$ligne["gidnumber"][0]};{$ligne["cn"][0]}\n";break;
						default:$res[$ligne["cn"][0]]=array("gid"=>$ligne["gidnumber"][0],"description"=>$ligne["description"][0]);break;
					}
				}
				
			}
		}
		
		
		$cols=array("cn","description",'gidnumber');
		$sr = @ldap_search($ld,"ou=groups,dc=samba,dc=organizations,$suffix",'objectclass=posixGroup',$cols);
		if ($sr) {
			$hash=ldap_get_entries($ld,$sr);
			while (list ($num, $ligne) = each ($hash) ){
				if($ligne["cn"][0]<>null){
					switch ($fieldlist) {
						case 1:$res[$ligne["gidnumber"][0]]=$ligne["cn"][0];break;
						case 2;$res=$res . "{$ligne["gidnumber"][0]};{$ligne["cn"][0]}\n";break;
						default:$res[$ligne["cn"][0]]=array("gid"=>$ligne["gidnumber"][0],"description"=>$ligne["description"][0]);break;
					}
				}
				
			}
		}		
		
		return $res;	
		}	

		
		
		function EditAsSamba(){
			$users=new usersMenus();
			$sid=$this->LOCAL_SID;
			$ldap=new clladp();
			if(!$this->objectClasses["sambaGroupMapping"]){
				$upd["objectClass"]="sambaGroupMapping";
				$upd["sambaSID"]="$sid-".(2 * $this->group_id + 1001 );
				$upd["sambaGroupType"]=$this->sambaGroupType;
				
				if(!$ldap->Ldap_add_mod($this->dn,$upd)){
					echo $ldap->ldap_last_error;
				}else{
					$tpl=new templates();
					echo $tpl->_ENGINE_parse_body('{success}');
				}
			return;}
			writelogs("DN=$this->dn",__CLASS__.'/'.__FUNCTION__,__FILE__);
			$upd["sambaSID"][]="$sid-".(2 * $this->group_id + 1001 );
			$upd["sambaGroupType"][]=$this->sambaGroupType;
			
			if(!$ldap->Ldap_modify($this->dn,$upd)){
					echo $ldap->ldap_last_error;
				}else{
					$tpl=new templates();
					if(posix_getuid()==0){echo "groups::EditAsSamba()::$this->dn = $sid \n";}else{
					echo $tpl->_ENGINE_parse_body("EditAsSamba() $sid {success}\n");}
				}			
			
		}
	 	
	 	
	
}

?>