$(document).ready(function() {

  var date = new Date();
  var d = date.getDate();
  var m = date.getMonth();
  var y = date.getFullYear();

  var edition_param = $("#calendar").attr("data-edition");
  var ids_to_forms_param = $("#calendar").attr("data-ids");

  $('#calendar').fullCalendar({
    editable: false,
    header: {
            left: 'prev,next today',
            center: 'title',
            right: 'month,agendaWeek,agendaDay'
        },
        defaultView: 'month',
        height: 500,
        slotMinutes: 15,
        
        loading: function(bool){
          if (bool) 
              $('#loading').show();
          else 
              $('#loading').hide();
        },
        
        eventSources: [{
            url: '/schedules/events',
            data: {
              "allocation_tags_ids": $("#allocation_tags_ids").val(),
              "all_groups_ids": $("#all_groups_ids").val()
            },
            textColor: 'black',
            ignoreTimezone: false
        }],

        edition: edition_param,
        ids_to_forms: ids_to_forms_param,
        timeFormat: 'h:mm t{ - h:mm t} ',
        dragOpacity: "0.5",
        
        eventRender: function(event, element) { 
             var fancyContent = '<div class="dropdown-panel">'+
              '<h1>Event Details</h1> <br>' +
              '<label><b>Event: </b></label>' + event.title + '<br>' + 
              '<label><b>Date: </b></label>' + event.date + '<br>' + 
              '<label><b>Start Time: </b></label>' + event.start + '<br>' + 
              '<label><b>End Time: </b></label>' + event.end + '<br>' + 
              '<label><b>Description: </b></label>' + '<div class="event_desc">' + event.description + '</div>' + 
              '<label><b>Location: </b></label><a href=' + event.url + '>' + event.location + '</a>' + '<br>' + '</div>';

          var dropdown = $("<div class='dropdown dropdown-tip' id='dropdown_details_"+event.type+"_"+event.id+"'>"+fancyContent+"</div>");
          $(element).after(dropdown);
        },

        eventClick: function(event, jsEvent, view){
        },
  });
});
