object @webconference_scores

child :logs => :webconference_logs do
  node do |w|
    {
      profile_name: w.profile_name,
      user_name: w.user_name,
      group: AllocationTag.find(w.at_id).info,
      date: w.created_at.to_datetime.strftime("%d/%m/%Y"),
      time: w.created_at.to_datetime.strftime("%H:%M:%S"),
      grade: w.grade,
      frequency: w.wh
    }
  end
end

child :acu do
  child :comments do
    node do |c|
      {
        comment: c.comment,
        by: c.user.nick,
        files: c.files.map{|f| download_comments_url(file_id: f.id)}
      }
    end
  end 
end
