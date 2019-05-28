object @group

attributes :id, :group_name

node(:participants) { |g|
	g.group_participants.map do |participant|
    {
      id: participant.user.id,
      name: participant.user.name,
      file_sent_date: @assignment.info(participant.user.id, @at.id)[:file_sent_date],
			situation: @assignment.info(participant.user.id, @at.id)[:situation],
			grade: @assignment.info(participant.user.id, @at.id)[:grade] || 0,
			working_hours: @assignment.info(participant.user.id, @at.id)[:working_hours] || 0,
    }
  end
}

node(:webconferences) { |g|
	unless g.academic_allocation_user.nil?
		g.academic_allocation_user.assignment_webconferences.map do |aw|
	    {
	      title: aw.title,
        access_url: access_assignment_webconference_url(aw.id),
        recordings: aw.recordings.map{|record| Bbb.get_recording_url(record, 'presentation')}
	    }
	  end
	end
}

node(:assignment_files) { |g|
	unless g.academic_allocation_user.nil?
		g.academic_allocation_user.assignment_files.map do |f|
	    {
	      file_name: f.attachment_file_name,
      	url: download_assignment_files_url(id: f.id)
	    }
	  end
	end
}

node(:comments) { |g|
	unless g.academic_allocation_user.nil?
		g.academic_allocation_user.comments.map do |c|
	    {
	      comment: c.comment,
	      by: c.user.name,
	      files: c.files.map{|f| download_comments_url(file_id: f.id)}
	    }
	  end
	end
}
