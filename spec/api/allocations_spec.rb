require "spec_helper"

describe "Allocations" do

  fixtures :all

  describe ".allocation" do

    describe "post" do

      context "with valid ip" do

        context 'create allocation' do

          context 'with user_id' do
            let!(:json_data){ { 
              user_id: 2,
              profile_id: 1
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation.where(status: 1),:count).by(1) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'removing previous' do
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

          context 'with cpf' do
            let!(:json_data){ { 
              cpf: "11016853521",
              profile_id: 1
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation.where(user_id: 3, status: 1),:count).by(1) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'with cpf - import from MA' do
            let!(:json_data){ { 
              cpf: ENV['VALID_CPF'],
              profile_id: 1,
              ma: true
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation.where(status: 1),:count).by(2) }
            it { should change(User,:count).by(1) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'with cpfs' do
            let!(:json_data){ { 
              cpfs: ["11016853521", "23885393905"],
              profile_id: 1
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation.where(user_id: 3, status: 1),:count).by(1) }
            it { should change(Allocation.where(user_id: 2, status: 1),:count).by(1) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'with cpfs - import from MA' do
            let!(:json_data){ { 
              cpfs: ENV['VALID_CPFS'].split(","),
              profile_id: 1,
              ma: true
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation.where(status: 1),:count).by(4) }
            it { should change(User,:count).by(2) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end
          context 'with cpfs and codes - course' do
            let!(:json_data){ { 
              cpfs: ["11016853521", "23885393905"],
              course_code: "109",
              profile_id: 2
            } }

            subject{ -> { post "/api/v1/allocations/course", json_data } } 

            it { should change(Allocation.where(user_id: 3, status: 1),:count).by(1) }
            it { should change(Allocation.where(user_id: 2, status: 1),:count).by(1) }

            it {
              post "/api/v1/allocations/course", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'with cpfs and codes - uc' do
            let!(:json_data){ { 
              cpf: "11016853521",
              curriculum_unit_code: "RM404",
              profile_id: 2
            } }

            subject{ -> { post "/api/v1/allocations/curriculum_unit", json_data } } 

            it { should change(Allocation.where(user_id: 3, status: 1),:count).by(1) }

            it {
              post "/api/v1/allocations/curriculum_unit", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'with cpfs and codes - offer' do
            let!(:json_data){ { 
              users_ids: [2,3],
              curriculum_unit_code: "RM301",
              course_code: "109",
              semester: "2011.1",
              profile_id: 2
            } }

            subject{ -> { post "/api/v1/allocations/offer", json_data } } 

            it { should change(Allocation.where(user_id: 2, status: 1),:count).by(1) }
            it { should change(Allocation.where(user_id: 3, status: 1),:count).by(1) }

            it {
              post "/api/v1/allocations/offer", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'with cpfs and codes - offer' do
            let!(:json_data){ { 
              user_id: 3,
              curriculum_unit_code: "RM301",
              course_code: "109",
              semester: "2011.1",
              group_code: "QM-CAU",
              profile_id: 2
            } }

            subject{ -> { post "/api/v1/allocations/group", json_data } } 

            it { should change(Allocation.where(user_id: 3, status: 1),:count).by(1) }

            it {
              post "/api/v1/allocations/group", json_data
              response.status.should eq(201)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'if has id, ignores codes' do
            let!(:json_data){ { 
              user_id: 3,
              curriculum_unit_code: "RM301",
              course_code: "109",
              semester: "2011.1",
              group_code: "QM-CAU",
              profile_id: 2
            } }

            subject{ -> { post "/api/v1/allocations/group/2", json_data } } 

            it { should change(Allocation.where(user_id: 3, allocation_tag_id: 2),:count).by(1) }

            it {
              post "/api/v1/allocations/group", json_data
              response.status.should eq(201)
            }
          end

        end

        context 'dont create allocation' do

          context 'missing params' do
            let!(:json_data){ { 
              profile_id: 1
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation.where(status: 1),:count).by(0) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(400)
            }
          end

          context 'invalid multiple params' do
            let!(:json_data){ { 
              user_id: 2,
              cpf: "11016853521",
              profile_id: 1
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation,:count).by(0) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(400)
            }
          end

          context 'missing params - with codes' do
            let!(:json_data){ { 
              curriculum_unit_code: "RM301",
              course_code: "109",
              semester: "2011.1",
              group_code: "QM-CAU",
              profile_id: 2
            } }

            subject{ -> { post "/api/v1/allocations/group", json_data } } 

            it { should change(Allocation.where(user_id: 3),:count).by(0) }

            it {
              post "/api/v1/allocations/group", json_data
              response.status.should eq(400)
            }
          end

          context 'missing params - missing code' do
            let!(:json_data){ { 
              user_id: 2,
              profile_id: 2
            } }

            subject{ -> { post "/api/v1/allocations/group", json_data } } 

            it { should change(Allocation.where(user_id: 3),:count).by(0) }

            it {
              post "/api/v1/allocations/group", json_data
              response.status.should eq(400)
            }
          end

          context 'user dont exist' do
            let!(:json_data){ { 
              user_id: 100,
              profile_id: 1
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation,:count).by(0) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(404)
            }
          end

          context 'cpf dont exist' do
            let!(:json_data){ { 
              cpf: "12345678911",
              profile_id: 1
            } }

            subject{ -> { post "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation,:count).by(0) }

            it {
              post "/api/v1/allocations/group/3", json_data
              response.status.should eq(404)
            }
          end

        end

      end

    end # post

    describe "delete" do

      context "with valid ip" do

        context 'cancel allocation' do

          context 'with user_id' do
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

          context 'cancel all allocation from user' do
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

          context 'with users_ids' do
            let!(:json_data){ { 
              users_ids: [1,7],
              profile_id: 1
            } }

            subject{ -> { delete "/api/v1/allocations/group/1", json_data } } 

            it { should change(Allocation.where(status: 1),:count).by(-2) }

            it {
              delete "/api/v1/allocations/group/3", json_data
              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }
          end

          context 'with cpf' do
            let!(:json_data){ { 
              cpf: "43463518678",
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

          context 'with cpfs' do
            let!(:json_data){ { 
              cpfs: ["43463518678", "32305605153"],
              profile_id: 1
            } }

            subject{ -> { delete "/api/v1/allocations/group/1", json_data } } 

            it { should change(Allocation.where(status: 1),:count).by(-2) }

            it {
              delete "/api/v1/allocations/group/3", json_data
              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }
          end

        end

        context 'dont cancel allocation' do

          context 'user dont exist' do
            let!(:json_data){ { 
              user_id: 100
            } }

            subject{ -> { delete "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation.where(status: 1),:count).by(0) }

            it {
              delete "/api/v1/allocations/group/3", json_data
              response.status.should eq(404)
            }
          end

          context 'missing params' do
            subject{ -> { delete "/api/v1/allocations/group/3" } } 

            it { should change(Allocation.where(status: 1),:count).by(0) }

            it {
              delete "/api/v1/allocations/group/3"
              response.status.should eq(400)
            }
          end

          context 'invalid multiple params' do
            let!(:json_data){ { 
              user_id: 1,
              cpf: "43463518678",
              profile_id: 1
            } }

            subject{ -> { delete "/api/v1/allocations/group/3", json_data } } 

            it { should change(Allocation.where(status: 1),:count).by(0) }

            it {
              delete "/api/v1/allocations/group/3", json_data
              response.status.should eq(400)
            }
          end

        end

      end

    end # delete

  end # .allocation

end