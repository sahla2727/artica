var mem_folder_name;

function SambaBrowser(){
    
    YahooTreeFolders(490,'samba.index.php');
}

function FolderProp(folder){
    YahooWin4(500,'samba.index.php?prop='+folder,folder);
}

var x_FindUserGroup=function (obj) {
tempvalue=obj.responseText;
document.getElementById('finduserandgroupsid').innerHTML=tempvalue;
}

var x_RefreshUserList=function (obj) {
    LoadAjax('userlists','samba.index.php?userlists=yes&prop='+mem_folder_name);
    FindUserGroup();
}

function FindUserGroup(){
	if( document.getElementById('finduserandgroupsid')){
		var XHR = new XHRConnection();
		var IsNFS=document.getElementById('IsNFS').value;
		XHR.appendData('finduserandgroup','yes');
		XHR.appendData('IsNFS',IsNFS);
		XHR.appendData('query',document.getElementById('query').value);
		document.getElementById('finduserandgroupsid').innerHTML='<center><img src="img/wait_verybig.gif"></center>';    
		XHR.sendAndLoad('samba.index.php', 'GET',x_FindUserGroup);
	}
	
    
}


var x_SambaSaveVFSModules=function (obj) {
	tempvalue=obj.responseText;
	if(tempvalue.length>0){alert(tempvalue);}
	RefreshTab('main_config_folder_properties');
    }




function SambaSaveVFSModules(){
	var XHR = new XHRConnection();
	mem_folder_name=document.getElementById('vfs_object').value;
	XHR.appendData('vfs_object',document.getElementById('vfs_object').value);
	if(document.getElementById('mysql_vfs')){XHR.appendData('mysql_vfs',document.getElementById('mysql_vfs').value);}
	if(document.getElementById('kav_vfs')){XHR.appendData('kav_vfs',document.getElementById('kav_vfs').value);}
	if(document.getElementById('recycle_vfs')){XHR.appendData('recycle_vfs',document.getElementById('recycle_vfs').value);}
	if(document.getElementById('scannedonly_vfs')){XHR.appendData('scannedonly_vfs',document.getElementById('scannedonly_vfs').value);}
	XHR.sendAndLoad('samba.index.php', 'GET',x_SambaSaveVFSModules);	
	
	
}


function FindUserGroupClick(e){
	if(checkEnter(e)){
		FindUserGroup();
	}
}


function AddUserToFolder(uid){
    var XHR = new XHRConnection();
    mem_folder_name=document.getElementById('folder_security_users_ff').value;
    XHR.appendData('AddUserToFolder',uid);
    XHR.appendData('prop',mem_folder_name);
    document.getElementById('finduserandgroupsid').innerHTML='<center><img src="img/wait_verybig.gif"></center>';
    XHR.sendAndLoad('samba.index.php', 'GET',x_RefreshUserList);
}

function UserSecurityInfos(item){
    document.getElementById('DeleteUserid').value=item;
    mem_folder_name=document.getElementById('folder_security_users_ff').value;
     LoadAjax('UserSecurityInfos','samba.index.php?UserSecurityInfos='+item+'&prop='+mem_folder_name);   
}

function DeleteUserPrivilege(){
    mem_folder_name=document.getElementById('folder_security_users_ff').value;
   var item=document.getElementById('DeleteUserid').value;
   if(item.length==0){
        alert(document.getElementById('selectuserfirst').value);
        return false;
    
   }
    var XHR = new XHRConnection();
    XHR.appendData('SaveFolderProp',mem_folder_name);
    XHR.appendData('SaveUseridPrivileges',item);
    XHR.appendData('read_list','no');
    XHR.appendData('valid_users','no');
    XHR.appendData('write_list','no');
    document.getElementById('userlists').innerHTML='<center><img src="img/wait_verybig.gif"></center>';
    document.getElementById('UserSecurityInfos').innerHTML='';    
    XHR.sendAndLoad('samba.index.php', 'GET',x_RefreshUserList);
}

var folderTabRefresh=function (obj) {
	if(document.getElementById('main_config')){
		LoadAjax('main_config','samba.index.php?main=shared_folders&hostname=');
	}
	if(document.getElementById('FodPropertiesFrom')){
		YahooWin4Hide();
	}
	
	if(document.getElementById('main_samba_shared_folders')){
		RefreshTab('main_samba_shared_folders');
	}
    
}

function FolderDelete(folder){
    var text=document.getElementById('del_folder_name').value + '\n ' + folder;
    if(confirm(text)){
        var XHR = new XHRConnection();
        XHR.appendData('FolderDelete',folder);
        XHR.sendAndLoad('samba.index.php', 'GET',folderTabRefresh);
        
    }
    
}


