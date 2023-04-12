module V1::OffersAndSemesters
  extend Grape::API::Helpers
  def creates_offer_and_semester(name, offer_period, enrollment_period, params)
    semester = verify_or_create_semester(name, offer_period, enrollment_period)
    offer    = verify_or_create_offer(semester, params, offer_period, enrollment_period)
  end

  def get_offer(curriculum_unit_code, course_code, semester)
    Offer.joins(:semester).where(curriculum_unit_id: CurriculumUnit.where(code: curriculum_unit_code).first, 
               course_id: Course.where(code: course_code).first, semesters: {name: semester}).first
  end

  def verify_or_create_semester(name, offer_period, enrollment_period = {})
    enrollment_period = {start_date: enrollment_period[:start_date].try(:to_date) || offer_period[:start_date], end_date: enrollment_period[:end_date].try(:to_date) || offer_period[:end_date]}
    semester = Semester.where(name: name).first_or_initialize

    if semester.new_record?
      semester.build_offer_schedule offer_period
      semester.build_enrollment_schedule enrollment_period
      semester.verify_current_date = false # don't validates initial date
      semester.save!
    end

    semester
  end

  # def verify_or_create_offer(semester, course, uc, offer_period)
  def verify_or_create_offer(semester, params, offer_period, enrollment_period = {})
    enrollment_period = {start_date: enrollment_period[:start_date].try(:to_date) || offer_period[:start_date], end_date: enrollment_period[:end_date].try(:to_date) || offer_period[:end_date]}
    offer = Offer.where(params.merge!({semester_id: semester.id})).first_or_create!
    group_count = Group.where(offer_id: params[:offer_id], can_update: true).count
    if group_count < 1
      verify_dates(offer, semester, offer_period, enrollment_period)
    end
    offer
  end

  def verify_dates(offer, semester, offer_period, enrollment_period = {})
    s_diff_period = different_dates?(semester.offer_schedule, offer_period) # semester offer  period != params offer  period
    s_diff_enroll = different_dates?(semester.enrollment_schedule, enrollment_period) # semester enroll period != params enroll period

    o_diff_period = different_dates?(offer.period_schedule, offer_period) # offer  period != params offer  period
    o_diff_enroll = different_dates?(offer.enrollment_schedule, enrollment_period) # enroll period != params enroll period

    dates = {}
    dates.merge!({offer_start: offer_period[:start_date], offer_end: offer_period[:end_date]}) if (o_diff_period.nil? && s_diff_period) || (!(o_diff_period.nil?) && o_diff_period)
    dates.merge!({enrollment_start: enrollment_period[:start_date], enrollment_end: enrollment_period[:end_date]}) if (o_diff_enroll.nil? && s_diff_enroll) || (!(o_diff_enroll.nil?) && o_diff_enroll) && !(enrollment_period.empty?)
    update_dates(offer, dates) unless dates.empty?
  end

  def get_date_attributes(offer, semester, params, enroll = false)
    unless enroll
      {start_date: params[:offer_start] || offer.period_schedule.try(:start_date) || semester.offer_schedule.start_date, end_date: params[:offer_end] || offer.period_schedule.try(:end_date) || semester.offer_schedule.end_date}
    else
      {start_date: params[:enrollment_start] || offer.enrollment_schedule.try(:start_date) || semester.enrollment_schedule.start_date, end_date: params[:enrollment_end] || offer.enrollment_schedule.try(:end_date) || semester.enrollment_schedule.end_date}
    end
  end

  def update_dates(offer, params)
    semester = offer.semester

    offer_period      = get_date_attributes(offer, semester, params)
    enrollment_period = get_date_attributes(offer, semester, params, true)

    (offer.period_schedule.nil?     ? offer.build_period_schedule(offer_period) : offer.period_schedule.update_attributes!(offer_period)) if params[:offer_start].present? or params[:offer_end].present?
    (offer.enrollment_schedule.nil? ? offer.build_enrollment_schedule(enrollment_period) : offer.enrollment_schedule.update_attributes!(enrollment_period)) if params[:enrollment_start].present? or params[:enrollment_end].present?

    offer.verify_current_date = false

    offer.save!
  end

  private

    def different_dates?(schedule, params)
      return nil if schedule.nil?
      schedule.start_date.to_date != params[:start_date].try(:to_date) or schedule.end_date.to_date != params[:end_date].try(:to_date)
    end

end