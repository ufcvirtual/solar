require "spec_helper"

describe "Taggable" do

  fixtures :all

  describe ".delete" do

    context "with valid ip" do

      context 'delete group' do

        subject{ -> { delete "/api/v1/taggables/group/14" } } 

        it { should change(Group,:count).by(-1) }

        it {
          delete "/api/v1/taggables/group/14"
          response.status.should eq(200)
          response.body.should == {ok: :ok}.to_json
        }
      end

      context 'cant delete course' do

        subject{ -> { delete "/api/v1/taggables/course/2" } } 

        it { should change(Course,:count).by(0) }

        it {
          delete "/api/v1/taggables/course/2"
          response.status.should eq(422)
        }
      end

    end

  end # .delete course/uc/offer/group

end