// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
// ,error:function(jqXHR,data,errorThrown){alert(jqXHR.responseText+data+errorThrown);}
var dialog_content;

$(document).ready(function(){
  $(document).ajaxError(function(e,jqXHR,data,errorThrown) {
    alert(jqXHR.responseText);
    $('#loading_indicator').hide();
  });

  $(document).ajaxSend(function(e,jqXHR,options) {
    // do not show loading indicator on priodical update
    if(options.url != "/actions/update_all"){
      $('#loading_indicator').show();
    }
  });
  $(document).ajaxComplete(function(e,jqXHR,options) {
    // do not show loading indicator on priodical update
    if(options.url != "/actions/update_all"){
      $('#loading_indicator').hide();
      update_all();
    }
  });

});

function open_tasks(){
  //jQuery.ajax('/tasks');
  //$('#tasks_dialog').dialog('open');
  link_to_dialog('/tasks');
}

function open_console(path){
	if ((!term) || (term.closed)) {

    $('#console_dialog').html("");
    jQuery.ajax("/console/dialog",{asnyc:false});
    $('#console_dialog').dialog('open');
  }
}

function link_to_dialog(path){
  jQuery.ajax(path);
  $('#standard_dialog').html("");
  $('#standard_dialog').dialog('open');
}

function update_all(){
  jQuery.ajax('/actions/update_all');
}

function closed_event_dialog(){
  jQuery.ajax('/actions/dialog_closed');  
}

function attack_host(host_id){
  link_to_dialog('/hosts/'+host_id+'/exploits');
}

function autoexploit_host(host_id){
  jQuery.ajax('/actions/attack_host',{data:"host_id="+host_id});
}
function exploit_service(service_id){
  jQuery.ajax('/actions/attack_service',{data:"service_id="+service_id});
}
function reconnaissance_from_host(host_id){
  jQuery.ajax('/actions/reconnaissance',{data:"host_id="+host_id});
}

function nvd_entries(host_id){
  jQuery.ajax("/hosts/"+host_id+"/nvd_entries");
}

function pick_exploit(id){
  jQuery.ajax("/exploits/"+id+"/pick");
}

function run_single_exploit(host_id, exploit_id){
  jQuery.ajax('/actions/single_exploit',{data:{'host_id':host_id, 'exploit_id':exploit_id}});
}

var storePos = [];
function save_layout(){
  storePos = [];
  for(i=0;i<layout.nodes().length;i++){
    node = layout.nodes()[i];
    storePos[node.hostID] = {x:node.x,y:node.y,marked:node.marked};
  }
}

function toggle_ki(navi_el){
  navi_el = $(navi_el);

  title = navi_el.html();
  if(title == "Start"){
    title = "Stop";
    jQuery.ajax('/actions/start_ki');  
  }else{
    title = "Start";
    jQuery.ajax('/actions/stop_ki');  
  }
  navi_el.html(title);
}

function mark_host(hostID){
  if(hostID != -1){
    for(i=0;i<layout.nodes().length;i++){
      node = layout.nodes()[i];
      node.marked=false;
    }
    for(i=0;i<layout.nodes().length;i++){
      node = layout.nodes()[i];
      if(hostID == node.hostID){
        node.marked=true;
      }
    }
    save_layout();
    layout.reset();
    vis.render();
    restore_layout();
  }
}

function restore_layout(){
  for(i=0;i<layout.nodes().length;i++){
    node = layout.nodes()[i];
    if(storePos[node.hostID]){
      layout.nodes()[i].x = storePos[node.hostID].x;
      layout.nodes()[i].y = storePos[node.hostID].y;
      layout.nodes()[i].marked = storePos[node.hostID].marked;
    }
  }
  vis.render();
}
