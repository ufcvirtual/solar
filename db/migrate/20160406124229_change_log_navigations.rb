class ChangeLogNavigations < ActiveRecord::Migration[5.1]
  def change
    change_table :log_navigations do |t|
      t.remove :offers_id
    end
  end
end
