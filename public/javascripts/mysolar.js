function showPanel(panelId){
    //alert(panel);
    hideAll();
    $('#'+panelId).show();
    $('#'+panelId+"_button").show();
    $('#'+panelId+'_tab').css('background-color','#F7F7F7');

}
function hideAll(){
    $('#my_cadastral_data').hide();
    $('#my_personal_data').hide();
    $('#my_personal_data_button').hide();
    $('#my_cadastral_data_button').hide();

    $('#my_professional_data_tab').css('background-color','#dedede');
    $('#my_personal_data_tab').css('background-color','#dedede');
    $('#my_cadastral_data_tab').css('background-color','#dedede');
}