module V1
  class Profiles < Base

    segment do

      before { guard! }

      namespace :sav do

        desc "Todos os perfis"
        get :profiles, rabl: "sav/profiles" do
          @profiles = Profile.all_except_basic
        end
        
      end # sav

    end # segment

  end
end