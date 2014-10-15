require "spec_helper"

describe "Courses" do

  fixtures :all

  describe ".course" do

    describe "post" do

      context "with valid ip" do

        context 'create course' do
          let!(:json_data){ { 
            name: "Curso 01",
            code: "C01"
          } }

          subject{ -> { post "/api/v1/course", json_data } } 

          it { should change(Course,:count).by(1) }

          it {
            post "/api/v1/course", json_data
            response.status.should eq(201)
            response.body.should == {id: Course.find_by_code("C01").id}.to_json
          }
        end

      end

    end # post

    describe "types" do
      it "list all" do
        get "/api/v1/course/types"

        response.status.should eq(200)
        response.body.should == CurriculumUnitType.select('id, description as name').to_json
      end

      it "gets a not found error" do
        get "/api/v1/course/types", {}, {"REMOTE_ADDR" => "127.0.0.2"}
        response.status.should eq(404)
      end
    end # describe types

  end # .course

  describe ".courses" do
    it "list all by type and semester" do
      get "/api/v1/courses", {semester: "2011.1", course_type_id: 3}

      response.status.should eq(200)
      response.body.should == [{id: 10, name: "Introducao a Linguistica", code: "RM404"}].to_json
    end
  end # .courses

end