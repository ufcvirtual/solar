module V1::All
  include AllocationsH
  include OffersAndSemesters
  include CurriculumUnitsAndCourses
  include GroupsH
  include UsersH
  include EventsH
  include Contents # replicates content of a group

  include General
  include FileDownload
end
