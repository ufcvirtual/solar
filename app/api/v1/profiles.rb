module V1
  class Profiles < Base

    segment do

      before { verify_ip_access_and_guard! }

      namespace :profiles do

        desc "Todos os perfis"
        get "/", rabl: "profiles/list" do
          @profiles = Profile.all_except_basic
        end

      end

    end # segment

  end
end