module MysolarHelper

  #Recebendo um código de um portlet, escolhe qual deve ser renderizado.
  def show_portlet(portlet_code = nil)

    case portlet_code
    when "1"
      render '/portlets/news'
    when "2"
      render '/portlets/lessons'
    when "3"
      render '/portlets/recent_activities'
    when "4"
      render '/portlets/calendar'
    when "5"
      render '/portlets/forum'

    else
      ""
    end
  end
end
