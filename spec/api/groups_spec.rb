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
            main_course: "109",
            main_curriculum_unit: "RM301",
            main_semester: "2011.1"
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
          it { should change(AcademicAllocation.where(allocation_tag_id: 11, academic_tool_type: "Webconference"),:count).by(3) }
          it { should change(Webconference.where('origin_meeting_id IS NOT NULL'),:count).by(2) }
          it { should change(AssignmentWebconference,:count).by(3) }
          it { should change(AssignmentWebconference.where('origin_meeting_id IS NOT NULL'),:count).by(1) }

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
            main_course: "109",
            main_curriculum_unit: "RM301",
            main_semester: "2011.1",
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
          it { should change(AcademicAllocation.where(allocation_tag_id: 3, academic_tool_type: "Webconference"),:count).by(2) }
          it { should change(Webconference,:count).by(2) }
          # it { should change(AssignmentWebconference,:count).by(3) }
          # it { should change(AssignmentWebconference.where('origin_meeting_id IS NOT NULL'),:count).by(1) }

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
          main_course: "109",
          main_curriculum_unit: "RM301",
          main_semester: "2011.1"
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

      context 'group doesnt exist - secundary' do
        let!(:json_data){ {
          main_group: "QM-MAR",
          secundary_groups: ["QM-0"],
          main_course: "109",
          main_curriculum_unit: "RM301",
          main_semester: "2011.1"
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

      context 'group doesnt exist - main' do
        let!(:json_data){ {
          main_group: "QM-0",
          secundary_groups: ["QM-MAR"],
          main_course: "109",
          main_curriculum_unit: "RM301",
          main_semester: "2011.1"
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

      # transfer content from TL-CAU to QM-CAU
      context 'do merge from different courses' do
        let!(:json_data){ {
          main_group: "QM-CAU",
          secundary_groups: ["TL-CAU"],
          main_course: "109",
          main_curriculum_unit: "RM301",
          secundary_course: "110",
          secundary_curriculum_unit: "RM405",
          main_semester: "2011.1"
        } }

        subject{ -> { put "/api/v1/groups/merge/", json_data } }

        it { should change(AcademicAllocation.where(allocation_tag_id: 3, academic_tool_type: "Discussion"),:count).by(1) }
        it { should change(Post,:count).by(0) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 3, academic_tool_type: "Assignment"),:count).by(2) }
        it { should change(SentAssignment,:count).by(1) }
        it { should change(AssignmentFile,:count).by(0) }
        it { should change(AssignmentComment,:count).by(1) }
        it { should change(CommentFile,:count).by(0) }
        it { should change(GroupAssignment,:count).by(0) }
        it { should change(GroupParticipant,:count).by(0) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 3, academic_tool_type: "ChatRoom"),:count).by(0) }
        it { should change(ChatMessage,:count).by(0) }
        it { should change(PublicFile,:count).by(0) }
        it { should change(Message,:count).by(0) }
        it { should change(Webconference,:count).by(2) }
        it { should change(Notification,:count).by(0) }
        it { should change(Lesson,:count).by(0) }
        it { should change(LogAction,:count).by(1) }
        it { should change(Merge,:count).by(1) }
        it { should change(Group.where(status: false),:count).by(1) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 3, academic_tool_type: "Webconference"),:count).by(2) }
        it { should change(Webconference.where('origin_meeting_id IS NOT NULL'),:count).by(2) }

        it {
          put "/api/v1/groups/merge/", json_data
          response.status.should eq(200)
          response.body.should == {ok: :ok}.to_json
        }
      end

      # transfer content back from QM-CAU to TL-CAU
      context 'do merge from different courses' do
        let!(:json_data){ {
          main_group: "QM-CAU",
          secundary_groups: ["TL-CAU"],
          main_course: "109",
          main_curriculum_unit: "RM301",
          secundary_course: "110",
          secundary_curriculum_unit: "RM405",
          main_semester: "2011.1",
          type: false
        } }

        subject{ -> { put "/api/v1/groups/merge/", json_data } }

        it { should change(AcademicAllocation.where(allocation_tag_id: 2, academic_tool_type: "Discussion"),:count).by(6) }
        it { should change(Post,:count).by(7) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 2, academic_tool_type: "Assignment"),:count).by(11) }
        it { should change(SentAssignment,:count).by(4) } # porque ele primeiro remove todo o conteúdo e depois adiciona (porque, teoricamente, deve ter acontecido um merge type true antes)
        it { should change(AssignmentFile,:count).by(4) }
        it { should change(AssignmentComment,:count).by(2) } # deleta todos os prévios objetos e adiciona os novos
        it { should change(CommentFile,:count).by(1) }
        it { should change(GroupAssignment,:count).by(6) }
        it { should change(GroupParticipant,:count).by(9) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 2, academic_tool_type: "ChatRoom"),:count).by(3) }
        it { should change(ChatMessage,:count).by(5) }
        it { should change(PublicFile,:count).by(1) }
        it { should change(Message,:count).by(1) }
        it { should change(Webconference,:count).by(3) } # ja tem um
        it { should change(Notification,:count).by(0) }
        it { should change(Lesson,:count).by(0) }
        it { should change(LogAction,:count).by(1) }
        it { should change(Merge,:count).by(1) }
        it { should change(Group.where(status: false),:count).by(0) }
        it { should change(AcademicAllocation.where(allocation_tag_id: 2, academic_tool_type: "Webconference"),:count).by(3) }
        # it { should change(Webconference.where('origin_meeting_id IS NOT NULL'),:count).by(3) }

        it {
          put "/api/v1/groups/merge/", json_data
          response.status.should eq(200)
          response.body.should == {ok: :ok}.to_json
        }
      end

      context "with invalid ip" do
        let!(:json_data){ {
            main_group: "QM-MAR",
            secundary_groups: ["QM-CAU"],
            main_course: "109",
            main_curriculum_unit: "RM301",
            main_semester: "2011.1"
          } }

        it "gets a not found error" do
          put "/api/v1/groups/merge/", json_data, "REMOTE_ADDR" => "127.0.0.2"
          response.status.should eq(401)
        end
      end

    end #merge

    context "list" do

      it "list all by semester" do
        get "/api/v1/groups", {semester: "2012.1"}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 0},
          {id: 6, code: "IL-FOR", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 2}].to_json # 2 => monitor e aluno
      end

      it "list all by semester and type" do
        get "/api/v1/groups", {semester: "2012.1", course_type_id: 3}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 0},
          {id: 6, code: "IL-FOR", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 2}].to_json
      end

      it "list all by semester, type and course" do
        get "/api/v1/groups", {semester: "2012.1", course_type_id: 3, course_id: 10}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 0},
          {id: 6, code: "IL-FOR", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 2}].to_json
      end

      it "list all by semester, type and discipline" do
        get "/api/v1/groups", {semester: "2012.1", course_type_id: 3, discipline_id: 1}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 0},
          {id: 6, code: "IL-FOR", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 2}].to_json
      end

      it "list all by semester, type, course and discipline" do
        get "/api/v1/groups", {semester: "2012.1", course_type_id: 3, course_id: 10, discipline_id: 1}

        response.status.should eq(200)
        response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 0},
          {id: 6, code: "IL-FOR", offer_id: 6, start_date: '2011-03-10', end_date: '2011-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 3, students: 2}].to_json
      end

      it "list by group it self" do
        get "/api/v1/groups", {group_id: 1}

        response.status.should eq(200)
        response.body.should == [{id: 1, code: "IL-FOR", offer_id: 1, start_date: '2011-03-10', end_date: '2021-12-01', course_id: 10, curriculum_unit_id: 1, semester_id: 2, students: 6}].to_json
      end

    end # list

    context "dont list" do

      it "too many params 1" do
        get "/api/v1/groups", {group_id: 1, semester: "2014.2"}
        response.status.should eq(400)
      end

      it "too many params 2" do
        get "/api/v1/groups", {group_id: 1, course_type_id: 3}
        response.status.should eq(400)
      end

      it "too many params 3" do
        get "/api/v1/groups", {group_id: 1, course_id: 3}
        response.status.should eq(400)
      end

      it "too many params 4" do
        get "/api/v1/groups", {group_id: 1, discipline_id: 3}
        response.status.should eq(400)
      end

    end

  end # groups

  describe ".group" do

    context "with invalid ip" do
      it "gets a not authorized" do
        post "/api/v1/group", {code: "G01", offer_id: 3}, "REMOTE_ADDR" => "127.0.0.2"
        response.status.should eq(401)
      end
      it "gets a not authorized" do
        put "/api/v1/group/3", {code: "G01"}, "REMOTE_ADDR" => "127.0.0.2"
        response.status.should eq(401)
      end
    end

    describe "post" do

      context "with valid ip" do

        context 'create group' do

          context 'with id' do
            let!(:json_data){ { code: "G01", offer_id: 3 } }

            subject{ -> { post "/api/v1/group", json_data } }

            it { should change(Group,:count).by(1) }

            it {
              post "/api/v1/group", json_data
              response.status.should eq(201)
              response.body.should == {id: Group.find_by_code("G01").id}.to_json
            }
          end

          context 'with codes' do
            let!(:json_data){ {
              semester: "2011.1",
              curriculum_unit_code: "RM301",
              course_code: "109",
              code: "G01"
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


        context "dont create group" do
          context 'existing code' do
            let!(:json_data){ { code: "QM-CAU", offer_id: 3 } }

            subject{ -> { post "/api/v1/group", json_data } }

            it { should change(Group,:count).by(0) }

            it {
              post "/api/v1/group", json_data
              response.status.should eq(422)
            }
          end

          context 'missing params' do
            let!(:json_data){ { offer_id: 3 } }

            subject{ -> { post "/api/v1/group", json_data } }

            it { should change(Group,:count).by(0) }

            it {
              post "/api/v1/group", json_data
              response.status.should eq(400)
            }
          end

          context 'missing params - code or id' do
            let!(:json_data){ { code: "G01" } }

            subject{ -> { post "/api/v1/group", json_data } }

            it { should change(Group,:count).by(0) }

            it {
              post "/api/v1/group", json_data
              response.status.should eq(400)
            }
          end

          context 'too many params' do
            let!(:json_data){ { code: "G01", offer_id: 3, course_code: "109" } }

            subject{ -> { post "/api/v1/group", json_data } }

            it { should change(Group,:count).by(0) }

            it {
              post "/api/v1/group", json_data
              response.status.should eq(400)
            }
          end
        end

      end

    end # post

    describe "put" do

      context "with valid ip" do

        context 'update group' do
          let!(:json_data){ { code: "G01" } }

          subject{ -> { put "/api/v1/group/3", json_data } }

          it { should change(Group.where(code: "QM-CAU"),:count).by(-1) }

          it {
            put "/api/v1/group/3", json_data
            response.status.should eq(200)
            response.body.should == {ok: :ok}.to_json
          }
        end

        context 'dont update group - existing code' do
          let!(:json_data){ { code: "QM-MAR" } }

          subject{ -> { put "/api/v1/group/3", json_data } }

          it { should change(Group.where(code: "QM-CAU"),:count).by(0) }

          it {
            put "/api/v1/group/3", json_data
            response.status.should eq(422)
          }
        end

        context 'dont update group - missing params' do
          subject{ -> { put "/api/v1/group/3" } }

          it { should change(Group.where(code: "QM-CAU"),:count).by(0) }

          it {
            put "/api/v1/group/3"
            response.status.should eq(400)
          }
        end

      end

    end # put

  end # .group

end
