collection @contacts

@contacts.each do |file|
  attributes :id, :name, :email, :profile_name
end