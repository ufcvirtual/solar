class ChangeOfferDatesNames < ActiveRecord::Migration
  def up
  	rename_column :offers, :start, :start_date
  	rename_column :offers, :end, :end_date
  end

  def down
  	rename_column :offers, :start_date, :start
  	rename_column :offers, :end_date, :end
  end
end
