class LogNavigationSub < ActiveRecord::Base
  belongs_to :log_navigation

  #deleta logs antigos com mais de 1 ano
  def self.delete_log_navigation_sub
    Thread.new do 
      LogNavigationSub.where("created_at::date < (CURRENT_DATE -INTERVAL '400 day')::date").delete_all
    end  
  end
end
