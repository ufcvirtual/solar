object @user => :user

node :info do |user|
  {
    public_files: user.count_public_files,
    sent_messages: user.all_sent_msgs,
    accesses: user.count_access,
    posts: user.count_posts,
    discussions: user.count_discussions,
    chat_messages: user.count_chat_messages,
    chat_rooms: user.count_chat_rooms,
    webconferences_accesses: user.count_web_access,
    webconferences: user.count_webs,
    comments: user.count_comments,
    sent_assignment_with_comments: user.count_sent_assignments_with_comments,
    sent_assignment_with_grades: user.count_sent_assignments_assignments_with_grades,
    assignments_with_comments: user.count_assignments_with_comments,
    assignments_with_grades: user.count_assignments_with_grades
  }
end
