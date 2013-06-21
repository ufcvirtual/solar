class ChangeOfferRemoveSemester < ActiveRecord::Migration
  def up
    change_table :offers do |t|
      t.integer :offer_schedule_id
      t.integer :semester_id

      t.rename :schedule_id, :enrollment_schedule_id
      t.rename :semester, :semester_name

      t.remove_foreign_key :schedules
      t.foreign_key :schedules, column: "enrollment_schedule_id"
      t.foreign_key :schedules, column: "offer_schedule_id"
      t.foreign_key :semesters
    end

    offers = Offer.order("semester_name")

    offers.each do |offer|
      offer.build_offer_schedule(start_date: offer.start_date, end_date: offer.end_date)
      offer.save

      s = Semester.find_or_create_by_name(name: offer.semester_name, offer_schedule_id: offer.offer_schedule_id, enrollment_schedule_id: offer.enrollment_schedule_id)
      offer.semester_id = s.id

      offer.save
    end

    remove_column :offers, :start_date
    remove_column :offers, :end_date
    remove_column :offers, :semester_name

    change_column :offers, :semester_id, :integer, null: false
  end

  def down
    raise "nao eh possivel fazer rollback com esta migration"
  end
end
