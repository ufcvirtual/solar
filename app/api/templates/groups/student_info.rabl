object @student => :student

attributes :cpf, :name, :gender, :birthdate

node(:complete_address) { |student| [[student.address, student.address_number].compact.join(', '), student.address_complement, student.address_neighborhood, student.zipcode, [student.city, student.state].compact.join(' - ')].compact.join('. ') }

node :info do |user|
  {
    public_files: user.count_public_files,
    sent_messages: user.all_sent_msgs,
    sent_messages_to_responsible: user.all_resp_sent_msgs,
    accesses: user.count_access,
    posts: user.count_posts,
    discussions: user.count_discussions,
    chat_messages: user.count_chat_messages,
    chat_rooms: user.count_chat_rooms,
    webconferences_accesses: user.count_web_access,
    webconferences: user.count_webs,
    assignments: user.count_assignments
  }
end
