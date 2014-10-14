module Helpers::V1::OffersAndSemesters

  def creates_offer_and_semester(name, offer_period, enrollment_period, params)
    semester = Semester.where(name: name).first_or_initialize

    enrollment_period = {start_date: enrollment_period[:start_date].try(:to_date) || offer_period[:start_date], end_date: enrollment_period[:end_date].try(:to_date) || offer_period[:end_date]}

    if semester.new_record?
      semester.build_offer_schedule offer_period
      semester.build_enrollment_schedule enrollment_period
      semester.verify_current_date = false # don't validate initial date
      semester.save!
    end

    offer = Offer.new params.merge!({semester_id: semester.id})
    offer.build_period_schedule offer_period          if semester.offer_schedule.start_date.to_date != offer_period[:start_date] or semester.offer_schedule.end_date.to_date != offer_period[:end_date]
    offer.build_enrollment_schedule enrollment_period if semester.enrollment_schedule.start_date.to_date != enrollment_period[:start_date] or semester.enrollment_schedule.end_date.to_date != enrollment_period[:end_date]
    offer.verify_current_date = false # don't validates initial date
    offer.save!

    offer
  end

  def get_offer(curriculum_unit_code, course_code, period, year)
    semester = (period.blank? ? year : "#{year}.#{period}")
    Offer.joins(:semester).where(curriculum_unit_id: CurriculumUnit.where(code: curriculum_unit_code).first, 
               course_id: Course.where(code: course_code).first, semesters: {name: semester}).first
  end

  def verify_or_create_semester(name, offer_period)
    semester = Semester.where(name: name).first_or_initialize

    if semester.new_record?
      semester.build_offer_schedule offer_period
      semester.build_enrollment_schedule start_date: offer_period[:start_date], end_date: offer_period[:start_date] # one day for enrollment
      semester.verify_current_date = false # don't validates initial date
      semester.save!
    end

    semester
  end

  def verify_or_create_offer(semester, course, uc, offer_period)
    offer = Offer.where(semester_id: semester, course_id: course, curriculum_unit_id: uc).first_or_initialize

    if offer.new_record?
      ss = semester.offer_schedule
      offer.build_period_schedule(offer_period) if ss.start_date.to_date != offer_period[:start_date].to_date or ss.end_date.to_date != offer_period[:end_date].to_date # semester offer period != offer period
      offer.verify_current_date = false # don't validates initial date
      offer.save!
    end

    offer
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

    offer.save!
  end

end