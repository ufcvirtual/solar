object @group => :group

node :info do |group|
  {
    public_files: group.count_public_files,
    sent_messages: group.all_sent_msgs,
    sent_messages_to_responsible: group.all_resp_sent_msgs,
    accesses: group.get_accesses.count,
    posts: group.count_posts,
    discussions: group.count_discussions,
    chat_messages: group.count_chat_messages,
    chat_rooms: group.count_chat_rooms,
    webconferences_accesses: group.count_web_access,
    webconferences: group.count_webconferences,
    assignments: group.count_assignments,
    sent_assignments: group.count_sa,
    students: group.count_students
  }
end
