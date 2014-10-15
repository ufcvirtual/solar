require "spec_helper"

describe "Courses" do

  fixtures :all

  context "with valid ip" do

    context 'create course' do
      let!(:json_data){ { name: "Curso 01", code: "C01" } }

      subject{ -> { post "/api/v1/course", json_data } } 

      it { should change(Course,:count).by(1) }

      it {
        post "/api/v1/course", json_data
        response.status.should eq(201)
        response.body.should == {id: Course.find_by_code("C01").id}.to_json
      }
    end

    context 'dont create course - already exist' do
      let!(:json_data){ { code: "110", name: "Curso01"} }

      subject{ -> { post "/api/v1/course", json_data } } 

      it { should change(Course,:count).by(0) }

      it {
        post "/api/v1/course", json_data
        response.status.should eq(422)
      }
    end

    context 'dont create course - code too big' do
      let!(:json_data){ { code: "1100"*11, name: "Curso01" } }

      subject{ -> { post "/api/v1/course", json_data } } 

      it { should change(Course,:count).by(0) }

      it {
        post "/api/v1/course", json_data
        response.status.should eq(422)
      }
    end

    context 'dont create course - missing params' do
      subject{ -> { post "/api/v1/course" } } 

      it { should change(Course,:count).by(0) }

      it {
        post "/api/v1/course"
        response.status.should eq(400)
      }
    end

    context 'update course' do
      it {
        put "/api/v1/course/1", { code: "109.2" }
        response.status.should eq(200)
      }
    end        

    context 'dont update course - already exist' do
      it {
        put "/api/v1/course/1", { code: "109" }
        response.status.should eq(422)
      }
    end

    context 'dont update course - missing params' do
      it {
        put "/api/v1/course/1"
        response.status.should eq(400)
      }
    end

  end

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

  describe ".courses" do
    it "list all by type and semester" do
      get "/api/v1/courses", {semester: "2011.1", course_type_id: 3}

      response.status.should eq(200)
      response.body.should == [{id: 10, name: "Introducao a Linguistica", code: "RM404"}].to_json
    end
  end # .courses

end