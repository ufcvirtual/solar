class LogNavigation < ActiveRecord::Base
  belongs_to :user
  belongs_to :menu
  belongs_to :contexts
  belongs_to :allocation_tag
  has_many   :log_navigation_subs

  def self.to_csv(attributes_to_include, options = {})
    CSV.generate(options) do |csv|
      csv << attributes_to_include
      all.each do |log_navigation|
        csv << log_navigation.attributes.values_at(*attributes_to_include)
      end
    end
  end

  #deleta logs antigos com mais de 1 ano
  def self.delete_log_navigation
    Thread.new do
      LogNavigation.where("created_at::date < (CURRENT_DATE -INTERVAL '400 day')::date").delete_all
    end
  end

end
