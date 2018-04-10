collection @logs

@logs.each do |log|
  extends 'logs/show', locals: {log: log}
end
