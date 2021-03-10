class AddEvaluationPeriodToAssignment < ActiveRecord::Migration[5.1]
   def up
  	add_column :assignments, :end_evaluation_date, :date

   	Assignment.all.each do |assignment|
   		offer = assignment.group.offer
      assignment.update_attributes!(:end_evaluation_date => offer.end_date)
    end

  end

  def down
  	remove_column :assignments, :end_evaluation_date
  end
end
