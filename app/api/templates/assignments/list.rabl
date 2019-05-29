collection @assignments

attributes :id, :name, :enunciation, :start_hour, :end_hour, :controlled

@assignments.each do |assignment|
 
  node(:type_assignment) { |assign| assign.type_assignment == 0 ? :individual : :group}
  node(:start_date) { |assign| assign.schedule.start_date}
  node(:end_date) { |assign| assign.schedule.end_date}
  node :enunciation_files do |assign|
    assign.enunciation_files.map do |file|
      {
        file_name: file.attachment_file_name,
        url: download_assignments_url(id: file.id)
      }
    end
  end

  if @is_student
	  node(:grade) { |assign| assign.info(current_user.id, @at.id)[:grade] || 0 }
	  node(:working_hours) { |assign| assign.info(current_user.id, @at.id)[:working_hours] || 0 }
	  node(:situation) { |assign| assign.info(current_user.id, @at.id)[:situation]}

	  node(:comments) { |assign|
	  	assign.comments_by_user(current_user.id).map do |c|
		    {
		      comment: c.comment,
		      by: c.user.name,
		      files: c.files.map{|f| download_comments_url(file_id: f.id)}
		    }
		  end
		}
	else
		node(:students) { |assign|  "/api/v1/assignments/#{assign.id}/participants/?group_id=#{@group.id}"}
	end
end