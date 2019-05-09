module APILogInfo
  extend ActiveSupport::Concern

  included do |base|
    after do
      APILog.remote_ip = get_remote_ip
    end
  end
end
