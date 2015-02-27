include EdxHelper

class EnrollmentsController < ApplicationController

  layout false, except: :index

  def index
    authorize! :index, Enrollment

    @uc_types = CurriculumUnitType.all
    @user_requests = current_user.allocations.where(profile_id: Profile.student_profile).where("allocation_tag_id IS NOT NULL") # dividir entre matriculados e outros
    @offers = Offer.to_enroll
  end

  def show
    authorize! :index, Enrollment

    if params.include?(:public) and params.include?(:public_course)
      public_course = params[:public_course]
      course_id     = public_course["course_id"].split("/")
      enroll_date   = [l(public_course["enrollment_start"].to_date , format: :default), l(public_course["enrollment_end"].to_date, format: :default)].join(" - ") unless public_course["enrollment_start"].blank? or public_course["enrollment_end"].blank?
      date          = [l(public_course["start"].to_date , format: :default), l(public_course["end"].to_date, format: :default)].join(" - ") unless public_course["start"].blank? or public_course["end"].blank?

      course_dec = public_course["resource_uri"]
      
      edx = YAML::load(File.open("config/edx.yml"))[Rails.env.to_s] rescue nil

      instructors   = JSON.parse(get_response("#{edx['host']}#{course_dec}instructor/").body)
      staffs        = JSON.parse(get_response("#{edx['host']}#{course_dec}staff/").body)

      responsibles = instructors.collect{|i| "#{User.find_by_username(i.split("/")[5]).name} (Professor)" unless User.find_by_username(i.split("/")[5]).nil?}
      responsibles << staffs.collect{|s| "#{User.find_by_username(s.split("/")[5]).name} (Tutor)" unless User.find_by_username(s.split("/")[5]).nil?}

      @course       = {semester: course_id[2], group: course_id[1], enrollment_date: enroll_date, offer_date: date, name: public_course["display_name"], responsibles: responsibles.flatten.compact}
    else
      @group           = Group.find(params[:group_id])
      @curriculum_unit = @group.offer.curriculum_unit
      @responsibles = AllocationTag.get_participants(@group.allocation_tag.id, {responsibles: true})
    end
  end

end
