object @group

attributes :id, :code, :uc_code, :uc_name, :course_code, :course_name, :semester_name, :type, :profiles

node(:profiles) { |group| group.profiles.split(',') }
