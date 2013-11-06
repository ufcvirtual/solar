class RemoveEnrollments < ActiveRecord::Migration
  def up
    # Passa os valores salvos em enrollments para ofertas/schedules
    Enrollment.all.each do |enroll|
      offer = Offer.find(enroll.offer_id)
      if offer.schedule.nil? 
        schedule = Schedule.create(start_date: enroll.start, end_date: enroll.end)
      else
        schedule = offer.schedule
        schedule.update_attributes(start_date: enroll.start, end_date: enroll.end)
      end
      offer.update_attribute(:schedule_id, schedule.id)
    end

    # Preenche as offers sem schedule, estas recebem como data inicial do período de matrícula sua própria data inicial (isto é feito apenas para não ficar vazio)
    Offer.find_all_by_schedule_id(nil).each do |offer|
      schedule = Schedule.create(start_date: offer.start_date)
      offer.update_attribute(:schedule_id, schedule.id)
    end

    # Remove a tabela de enrollments
    drop_table :enrollments
  end

  def down
    # Cria a tabela de enrollments
    create_table "enrollments" do |t|
      t.integer  "offer_id"
      t.date     "start",      :null => false
      t.date     "end"
    end
    add_foreign_key(:enrollments, :offers)

    # Passa os valores salvos em ofertas/schedules para enrollments
    Offer.all.each do |offer|
      Enrollment.create(offer_id: offer.id, start: offer.schedule.start_date, :end => offer.schedule.end_date)
    end
  end
end
