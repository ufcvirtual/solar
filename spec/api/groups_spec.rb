require "spec_helper"

describe "Groups" do

  fixtures :all

  describe ".list" do

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:application) { d = Doorkeeper::Application.new(name: "MyApp", redirect_uri: "http://app.com"); d.owner = user; d.save; d }
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

      it "gets list of groups by UC" do
        get "/api/v1/curriculum_units/1/groups", access_token: token.token

        response.status.should eq(200)
        response.body.should == [{id: 1, code: "IL-FOR", semester: "2011.1"}].to_json
      end
    end

    context "without access token" do
      it 'gets an unauthorized error' do
        get "/api/v1/curriculum_units/5/groups"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end # .list

  describe ".groups" do

    describe "merge" do

      context "with valid ip" do

        # transfer content from QM-CAU to QM-MAR
        context 'do merge' do
          let!(:json_data){ { 
            main_group: "QM-MAR",
            secundary_groups: ["QM-CAU"],
            course: "109",
            curriculum_unit: "RM301",
            period: "2011.1"
          } }

          subject{ -> { put "/api/v1/groups/merge/", json_data } } 

          it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "Discussion"),:count).by(4) }
          it { should change(Post,:count).by(4) }
          it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "Assignment"),:count).by(9) }
          it { should change(SentAssignment,:count).by(5) }
          it { should change(AssignmentFile,:count).by(4) }
          it { should change(AssignmentComment,:count).by(3) }
          it { should change(CommentFile,:count).by(1) }
          it { should change(GroupAssignment,:count).by(6) }
          it { should change(GroupParticipant,:count).by(9) }
          it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "ChatRoom"),:count).by(3) }
          it { should change(ChatMessage,:count).by(5) }
          it { should change(PublicFile,:count).by(1) }
          it { should change(Message,:count).by(1) }
          it { should change(LogAction,:count).by(1) }
          it { should change(Merge,:count).by(1) }
          it { should change(Group.where(status: false),:count).by(1) }

          it {
            put "/api/v1/groups/merge/", json_data
            response.status.should eq(200)
            response.body.should == {ok: :ok}.to_json
          }
        end
      
        # transfer content from QM-MAR to QM-CAU (QM-MAR only has one post and one sent_assignment different from QM-CAU)
        context 'undo merge' do
          let!(:json_data){ { 
            main_group: "QM-MAR",
            secundary_groups: ["QM-CAU"],
            course: "109",
            curriculum_unit: "RM301",
            period: "2011.1",
            type: false
          } }

          subject{ -> { put "/api/v1/groups/merge/", json_data } } 

          # QM-CAU loses all content it have to receive QM-MAR's content
          it { should change(AcademicAllocation.where(allocation_tag_id: 3, academic_tool_type: "Discussion"),:count).by(0) }
          it { should change(Post,:count).by(-3) } # it has 4, received 1
          it { should change(AcademicAllocation.where(allocation_tag_id: 3, academic_tool_type: "Assignment"),:count).by(0) }
          it { should change(SentAssignment,:count).by(-3) } # it has 4, received 1
          it { should change(AssignmentFile,:count).by(-4) }
          it { should change(AssignmentComment,:count).by(-2) }
          it { should change(CommentFile,:count).by(-1) }
          it { should change(GroupAssignment,:count).by(-5) }
          it { should change(GroupParticipant,:count).by(-8) }
          it { should change(AcademicAllocation.where(allocation_tag_id: 3, academic_tool_type: "ChatRoom"),:count).by(0) }
          it { should change(ChatMessage,:count).by(-5) }
          it { should change(PublicFile,:count).by(0) }
          it { should change(Message,:count).by(0) }
          it { should change(LogAction,:count).by(1) }
          it { should change(Merge,:count).by(1) }
          it { should change(Group.where(status: false),:count).by(0) }

          it {
            put "/api/v1/groups/merge/", json_data
            response.status.should eq(200)
            response.body.should == {ok: :ok}.to_json
          }
        end 
      end

      context 'missing params' do
        let!(:json_data){ { 
          main_group: "QM-MAR",
          course: "109",
          curriculum_unit: "RM301",
          period: "2011.1"
        } }

        subject{ -> { put "/api/v1/groups/merge/", json_data } } 

        it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "Discussion"),:count).by(0) }
        it { should change(Post,:count).by(0) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "Assignment"),:count).by(0) }
        it { should change(SentAssignment,:count).by(0) }
        it { should change(AssignmentFile,:count).by(0) }
        it { should change(AssignmentComment,:count).by(0) }
        it { should change(CommentFile,:count).by(0) }
        it { should change(GroupAssignment,:count).by(0) }
        it { should change(GroupParticipant,:count).by(0) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "ChatRoom"),:count).by(0) }
        it { should change(ChatMessage,:count).by(0) }
        it { should change(PublicFile,:count).by(0) }
        it { should change(Message,:count).by(0) }
        it { should change(LogAction,:count).by(0) }
        it { should change(Merge,:count).by(0) }
        it { should change(Group.where(status: false),:count).by(0) }

        it {
          put "/api/v1/groups/merge/", json_data
          response.status.should eq(400)
        }
      end

      context 'group doesnt exist' do
        let!(:json_data){ { 
          main_group: "QM-MAR",
          secundary_groups: ["QM-0"],
          course: "109",
          curriculum_unit: "RM301",
          period: "2011.1"
        } }

        subject{ -> { put "/api/v1/groups/merge/", json_data } } 

        it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "Discussion"),:count).by(0) }
        it { should change(Post,:count).by(0) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "Assignment"),:count).by(0) }
        it { should change(SentAssignment,:count).by(0) }
        it { should change(AssignmentFile,:count).by(0) }
        it { should change(AssignmentComment,:count).by(0) }
        it { should change(CommentFile,:count).by(0) }
        it { should change(GroupAssignment,:count).by(0) }
        it { should change(GroupParticipant,:count).by(0) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "ChatRoom"),:count).by(0) }
        it { should change(ChatMessage,:count).by(0) }
        it { should change(PublicFile,:count).by(0) }
        it { should change(Message,:count).by(0) }
        it { should change(LogAction,:count).by(0) }
        it { should change(Merge,:count).by(0) }
        it { should change(Group.where(status: false),:count).by(0) }

        it {
          put "/api/v1/groups/merge/", json_data
          response.status.should eq(404) # not found
        }
      end

      context "with invalid ip" do
        let!(:json_data){ { 
            main_group: "QM-MAR",
            secundary_groups: ["QM-CAU"],
            course: "109",
            curriculum_unit: "RM301",
            period: "2011.1"
          } }

        it "gets a not found error" do
          put "/api/v1/groups/merge/", json_data, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(404)
        end
      end

    end #merge

    context "list" do

      it "list all by semester" do
        get "/api/v1/groups", {semester: "2012.1"}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
      end

      it "list all by semester and type" do
        get "/api/v1/groups", {semester: "2012.1", course_type_id: 3}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
      end

      it "list all by semester, type and course" do
        get "/api/v1/groups", {semester: "2012.1", course_type_id: 3, course_id: 10}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
      end

      it "list all by semester, type and discipline" do
        get "/api/v1/groups", {semester: "2012.1", course_type_id: 3, discipline_id: 1}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
      end

      it "list all by semester, type, course and discipline" do
        get "/api/v1/groups", {semester: "2012.1", course_type_id: 3, course_id: 10, discipline_id: 1}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
      end

    end # list

  end # groups

  describe ".group" do

    describe "post" do

      context "with valid ip" do

        context 'create group' do
          let!(:json_data){ { 
            code: "G01",
            offer_id: 3
          } }

          subject{ -> { post "/api/v1/group", json_data } } 

          it { should change(Group,:count).by(1) }

          it {
            post "/api/v1/group", json_data
            response.status.should eq(201)
            response.body.should == {id: Group.find_by_code("G01").id}.to_json
          }
        end

      end

    end # post

  end # .group

end
