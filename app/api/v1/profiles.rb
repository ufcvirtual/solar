module V1
  class Profiles < Base

    segment do

      before { verify_ip_access! }

      desc "Todos os perfis"
      get :profiles, rabl: "profiles/list" do
        @profiles = Profile.all_except_basic
      end

      namespace :sav do
        desc "Todos os perfis"
        get :profiles, rabl: "profiles/list" do
          @profiles = Profile.all_except_basic
        end
      end

    end # segment

  end
end