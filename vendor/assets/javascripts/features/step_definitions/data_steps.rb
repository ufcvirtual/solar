# baseado em https://github.com/jdfrens/calvincs/blob/6c9e9cb9bd80cf001ffe150d1d8bedfc7adeab23/features/step_definitions/date_selection_steps.rb
# code inspired by https://gist.github.com/12499d2cf62753f0c339


Dado /^que eu selecionei a data "([^"]*)" no campo com id "([^"]*)"$/ do |date, id_prefix|
  date = Chronic.parse(date)

  select date.year.to_s, :from => "#{id_prefix}_#{date_and_time_suffixes[:year]}"
  select date.strftime('%B'), :from => "#{id_prefix}_#{date_and_time_suffixes[:month]}"
  select date.day.to_s, :from => "#{id_prefix}_#{date_and_time_suffixes[:day]}"

end

When /^(?:|I )select "([^\"]*)" as the date and time$/ do |date|
  date = Chronic.parse(date)

  id_prefix = "colloquium_start"

  select date.year.to_s, :from => "#{id_prefix}_#{date_and_time_suffixes[:year]}"
  select date.strftime('%B'), :from => "#{id_prefix}_#{date_and_time_suffixes[:month]}"
  select date.day.to_s, :from => "#{id_prefix}_#{date_and_time_suffixes[:day]}"
  select date.hour.to_s, :from => "#{id_prefix}_#{date_and_time_suffixes[:hour]}"
  select date.min.to_s, :from => "#{id_prefix}_#{date_and_time_suffixes[:minute]}"
end

def date_and_time_suffixes
   {
    :year   => '1i',
    :month  => '2i',
    :day    => '3i',
    :hour   => '4i',
    :minute => '5i'
  }
end
