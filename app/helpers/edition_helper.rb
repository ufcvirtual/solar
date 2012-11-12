module EditionHelper

	##
	# Retorna informação sobre a turma e oferta selecionadas para os fóruns
	##
  def group_and_offer_info(group_id, offer_id)
    offer_semester = Offer.find(offer_id).semester
  	if group_id == "all"
      group_code      = t(:all_groups, :scope => [:discussion])
      group_and_offer = group_code + " " + t(:of) + " " + offer_semester
    elsif group_id != "0"
      group_code      = Group.find(group_id).code
      group_and_offer = group_code + " " + t(:of) + " " + offer_semester
    else
      group_and_offer = offer_semester
    end


    return group_and_offer
  end

end
