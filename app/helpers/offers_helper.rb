module OffersHelper

  def enrollment_info(offer)
    enrollment_period = offer.enrollment_period

    enroll_period = [I18n.l(enrollment_period.first, format: :normal),
      (enrollment_period.last.nil? ? I18n.t("offers.no_end_date") : I18n.l(enrollment_period.last, format: :normal))].join(' - ')

    is_active = Time.now.between?(enrollment_period.first, enrollment_period.last || Time.now + 100.years) # pode nao ter periodo final
    offer_period = [I18n.l(offer.start_date), (offer.end_date.nil? ? I18n.t("offers.no_end_date") : I18n.l(offer.end_date))].join(' - ')

    {period: enroll_period, is_active: is_active, offer: offer_period}
  end

end
