function showPanel(panelId){
    //alert(panel);
    hideAll();
    $('#'+panelId).show();

}
function hideAll(){
    $('#mysolar_panel_home').hide();
    $('#mysolar_panel_dados').hide();

}