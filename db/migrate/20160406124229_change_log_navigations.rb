class ChangeLogNavigations < ActiveRecord::Migration
  def change
    change_table :log_navigations do |t|
      t.remove :offers_id
    end
  end
end
