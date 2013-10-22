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
        
        // a future calendar might have many sources.        
        eventSources: [{
            url: '/schedules/events',
            data: {
              "allocation_tags_ids": $("#allocation_tags_ids").val(),
              "all_groups_ids": $("#all_groups_ids").val()
            },
            // color: '#4183c4',
            textColor: 'black',
            ignoreTimezone: false
        }],
        edition: edition_param,
        ids_to_forms: ids_to_forms_param,
        timeFormat: 'h:mm t{ - h:mm t} ',
        dragOpacity: "0.5",
        
        //http://arshaw.com/fullcalendar/docs/event_ui/eventDrop/
        eventDrop: function(event, dayDelta, minuteDelta, allDay, revertFunc){
            // updateEvent(event);
        },

        // http://arshaw.com/fullcalendar/docs/event_ui/eventResize/
        eventResize: function(event, dayDelta, minuteDelta, revertFunc){
            // updateEvent(event);
        },

        // http://arshaw.com/fullcalendar/docs/mouse/eventClick/
        eventClick: function(event, jsEvent, view){
          // console.log("oi?");
          // console.log(event);
          // console.log(jsEvent);
          // console.log(view);
          // var bla = $($(this)[0]).attr("class");
          // $(this).append("<div> oi </div>");
          // console.log($(this).first());
          // $($($(this)[0])[0]).append(
          //   "<div>
          //   oi
          //   </div>"
          // );
          // jQuery("#image_center").html("<%= escape_javascript(render(:partial => 'pages/top_link')) %>");
          // $("#btn-move-node").click(function() {
          // trigger = jQuery(this);
          // target = jQuery(this).data('dropdown-alt');
          // if(typeof selNodes == "undefined" || selNodes.length == 0) {
          //   jQuery("#folder_dropdown_alert").show();
          //   jQuery("#folder_dropdown_content").hide();
          // } else {
          //   jQuery("#folder_dropdown_alert").hide();
          //   jQuery("#folder_dropdown_content").show();
          // }
          // jQuery(target)
        },
  });
});

function updateEvent(the_event) {
    $.update(
      "/events/" + the_event.id,
      { event: { title: the_event.title,
                 starts_at: "" + the_event.start,
                 ends_at: "" + the_event.end,
                 description: the_event.description
               }
      },
      function (reponse) { alert('successfully updated task.'); }
    );
};

$(function(){

});

function updateRepeatingEvent(the_event) {
  console.log(the_event);
  // var event = cal.fullCalendar('calendar', 999)[0];
  // event.start = new Date(y, m, 4, 13, 30);
  // event.end = new Date(y, m, 5, 2, 0);
  // event.allDay = true;
  // event.title = "repeat yo";
  // //event.editable = false;
  // // event.url = "http://google.com/";
  // event.color = '#4183c4';
  // // event.textColor = 'green';
  // cal.fullCalendar('updateEvent', event);
  //console.log(cal.fullCalendar('clientEvents', 2));
};
