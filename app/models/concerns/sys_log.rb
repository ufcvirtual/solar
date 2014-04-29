require 'active_support/concern'

module SysLog

  module Access
    extend ActiveSupport::Concern

    # included do
    # end

    # After authentication, log user sign_in at the system
    # def after_database_authentication
    #   LogAccess.create(log_type: Log::TYPE[:login], user_id: self.id, created_at: Time.now)
    # end


  end

  module Actions
    extend ActiveSupport::Concern

    # included do
    #   after_create :log_create
    # end

    # def log_create
    #   LogAccess.create(log_type: 100, user_id: self.id, created_at: Time.now, description: "criando aqui")
    # end

  end


  # ## sempre que criar algo loga
  # ## criacao/edicao de post grava o conteudo

end
