object @participant

attributes :id, :name


node(:file_sent_date) { |user| @assignment.info(user.id, @at.id)[:file_sent_date]}
node(:situation) { |user| @assignment.info(user.id, @at.id)[:situation]}
node(:grade) { |user| @assignment.info(user.id, @at.id)[:grade] || 0 }
node(:working_hours) { |user| @assignment.info(user.id, @at.id)[:working_hours] || 0 }

node(:webconferences) { |user|
	unless @assignment.acu_by_user(user.id).blank?
		@assignment.acu_by_user(user.id).assignment_webconferences.map do |aw|
	    {
	      title: aw.title,
        access_url: access_assignment_webconference_url(aw.id, student_id: user.id),
        recordings: aw.recordings.map{|record| Bbb.get_recording_url(record, 'presentation')}
	    }
	  end
	end
}

node(:assignment_files) { |user|
	unless @assignment.acu_by_user(user.id).blank?
		@assignment.acu_by_user(user.id).assignment_files.map do |f|
	    {
	      file_name: f.attachment_file_name,
      	url: download_assignment_files_url(id: f.id)
	    }
	  end
	end
}


node(:comments) { |user|
	unless @assignment.acu_by_user(user.id).blank?
		@assignment.acu_by_user(user.id).comments.map do |c|
	    {
	      comment: c.comment,
	      by: c.user.name,
	      files: c.files.map{|f| download_comments_url(file_id: f.id)}
	    }
	  end
	end
}



