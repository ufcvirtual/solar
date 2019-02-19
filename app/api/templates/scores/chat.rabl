object @chat_scores

child :messages do
  node do |m|
    {
      message: m.text,
      date: m.created_at.to_datetime.strftime("%d/%m/%Y"),
      time: m.created_at.to_datetime.strftime("%H:%M:%S")
    }
  end
end 

child :acu do
  attributes :grade, :working_hours
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
