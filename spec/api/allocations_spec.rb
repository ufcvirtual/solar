require "spec_helper"

describe "Allocations" do

  fixtures :all

  describe ".allocation" do

    describe "post" do

      context "with valid ip" do

        context 'create allocation' do
          let!(:json_data){ { 
            user_id: 2,
            profile_id: 1
          } }

          subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

          it { should change(Allocation,:count).by(1) } # já existiam 4

          it {
            post "/api/v1/allocations/group/3", json_data
            response.status.should eq(201)
            response.body.should == {ok: :ok}.to_json
          }
        end

        context 'create allocation removing previous' do
          let!(:json_data){ { 
            user_id: 2,
            profile_id: 1,
            remove_previous_allocations: true
          } }

          subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

          it { should change(Allocation.where(status: 1),:count).by(-3) } # já existiam 4

          it {
            post "/api/v1/allocations/group/3", json_data
            response.status.should eq(201)
            response.body.should == {ok: :ok}.to_json
          }
        end

      end

    end # post

    describe "delete" do

      context "with valid ip" do

        context 'remove allocation' do
          let!(:json_data){ { 
            user_id: 1,
            profile_id: 1
          } }

          subject{ -> { delete "/api/v1/allocations/group/1", json_data } } 

          it { should change(Allocation.where(status: 1),:count).by(-1) }

          it {
            delete "/api/v1/allocations/group/3", json_data
            response.status.should eq(200)
            response.body.should == {ok: :ok}.to_json
          }
        end

        context 'remove all allocation from user' do
          let!(:json_data){ { 
            user_id: 6
          } }

          subject{ -> { delete "/api/v1/allocations/group/3", json_data } } 

          it { should change(Allocation.where(status: 1),:count).by(-3) }

          it {
            delete "/api/v1/allocations/group/3", json_data
            response.status.should eq(200)
            response.body.should == {ok: :ok}.to_json
          }
        end

      end

    end # delete

  end # .allocation

end