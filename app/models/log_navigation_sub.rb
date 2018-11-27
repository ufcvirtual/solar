class LogNavigationSub < ActiveRecord::Base
  belongs_to :log_navigation

  #deleta logs antigos com mais de 1 ano
  def self.delete_log_navigation_sub
    Thread.new do 
      LogNavigationSub.where("created_at::date < (CURRENT_DATE -INTERVAL '400 day')::date").delete_all
    end  
  end

  def self.after_post_discussion_user(user_id, discussion_id)
  	LogNavigationSub.joins(:log_navigation).select("DISTINCT log_navigation_subs.id, log_navigation_subs.created_at").where("log_navigations.user_id = ? AND log_navigation_subs.discussion_id = ? ", user_id, discussion_id).order("log_navigation_subs.id DESC").limit(1)
  end	
end
