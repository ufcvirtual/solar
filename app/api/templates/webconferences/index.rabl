collection @webconferences

@webconferences.each do |webconference|
  extends 'webconferences/show', locals: {webconference: webconference}
end
