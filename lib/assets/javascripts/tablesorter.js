$(document).ready(function(){
    /**
    * Tablesorter
    */

    // setando tipo de sort para data (código desativado pois nossas colunas usam data inicial e final juntas, e não funciona corretamente)
    //$(".tb_list .date").data("sorter", "shortDate");

    // desabilitando tablesorter em colunas de classe no_sort (deve ser feito antes de ativar o tablesorter)
    $(".tb_list .no_sort").data("sorter", false);
    $(".tb_list .date").data("sorter", false);

    // ativando tablesorter
    $(".tb_list").tablesorter({
        // header layout
        headerTemplate: '{content}{icon}',
        // prevent text selection in header
        cancelSelection: true,
        // Enable use of the characterEquivalents reference
        sortLocaleCompare : true,
        // if false, upper case sorts BEFORE lower case
        ignoreCase : true,
        // third click on the header will reset column to default - unsorted
        sortReset: true,
        // formato padrão de data
        dateFormat: "ddmmyyyy"
    });
})