object @participant

attributes :id, :name

node(:file_sent_date) { |user| @event.info(user.id, @at.id)[:file_sent_date]}
node(:situation) { |user| @event.info(user.id, @at.id)[:situation]}
node(:grade) { |user| @event.info(user.id, @at.id)[:grade] || 0 }
node(:working_hours) { |user| @event.info(user.id, @at.id)[:working_hours] || 0 }

node(:event_files) { |user|
	unless @event.acu_by_user(user.id).blank?
		@event.acu_by_user(user.id).schedule_event_files.map do |f|
	    {
	      file_name: f.attachment_file_name,
      	  url: download_schedule_event_files_url(id: f.id)
	    }
	  end
	end
}

node(:comments) { |user|
	unless @event.acu_by_user(user.id).blank?
		@event.acu_by_user(user.id).comments.map do |c|
	    {
	      comment: c.comment,
	      by: c.user.name,
	      files: c.files.map{|f| download_comments_url(file_id: f.id)}
	    }
	  end
	end
}