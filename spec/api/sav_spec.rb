require "spec_helper"

describe "Sav" do

  fixtures :all

  describe "try access with invalid ip" do
    it "gets a not found error" do
      get "/api/v1/sav/profiles", {}, {"REMOTE_ADDR" => "127.0.0.2"}
      response.status.should eq(404)

      get "/api/v1/sav/course/types", {}, {"REMOTE_ADDR" => "127.0.0.2"}
      response.status.should eq(404)

      get "/api/v1/sav/semesters", {}, {"REMOTE_ADDR" => "127.0.0.2"}
      response.status.should eq(404)
    end # describe access
  end

  describe "profiles" do

    it "gets a list of all" do
      get "/api/v1/sav/profiles"

      response.status.should eq(200)
      response.body.should == Profile.all_except_basic.select('id, name').to_json
    end # it

  end # describe profiles

  describe "semesters" do
    it "list all" do
      get "/api/v1/sav/semesters"

      response.status.should eq(200)
      response.body.should == Semester.order('name desc').uniq.to_json(only: [:name])
    end
  end # describe semesters

  describe "courses" do
    describe "types" do
      it "list all" do
        get "/api/v1/sav/course/types"

        response.status.should eq(200)
        response.body.should == CurriculumUnitType.select('id, description as name').to_json
      end
    end # describe types

    it "list all by type and semester" do
      get "/api/v1/sav/courses", {semester: "2011.1", course_type_id: 3}

      response.status.should eq(200)
      response.body.should == [{id: 10, name: "Introducao a Linguistica", code: "RM404"}].to_json
    end
  end # describe courses


  describe "disciplines" do
    it "list all by semester" do
      get "/api/v1/sav/disciplines", {semester: "2012.1"}

      response.status.should eq(200)
      response.body.should == [{id: 1, code: "RM404", name: "Introducao a Linguistica" }, {id: 3, code: "RM301", name: "Quimica I"}].to_json
    end

    it "list all by semester and type" do
      get "/api/v1/sav/disciplines", {semester: "2012.1", course_type_id: 2}

      response.status.should eq(200)
      response.body.should == [{id: 3, code: "RM301", name: "Quimica I"}].to_json
    end

    it "list all by semester and course" do
      get "/api/v1/sav/disciplines", {semester: "2012.1", course_id: 2}

      response.status.should eq(200)
      response.body.should == [{id: 3, code: "RM301", name: "Quimica I"}].to_json
    end

    it "list all by semester, type and course" do
      get "/api/v1/sav/disciplines", {semester: "2013.1", course_type_id: 5, course_id: 3}

      response.status.should eq(200)
      response.body.should == [{id: 5, code: "RM414", name: "Literatura Brasileira I"}].to_json
    end
  end # describe disciplines

  describe "groups" do
    it "list all by semester" do
      get "/api/v1/sav/groups", {semester: "2012.1"}

      response.status.should eq(200)
      response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
    end

    it "list all by semester and type" do
      get "/api/v1/sav/groups", {semester: "2012.1", course_type_id: 3}

      response.status.should eq(200)
      response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
    end

    it "list all by semester, type and course" do
      get "/api/v1/sav/groups", {semester: "2012.1", course_type_id: 3, course_id: 10}

      response.status.should eq(200)
      response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
    end

    it "list all by semester, type and discipline" do
      get "/api/v1/sav/groups", {semester: "2012.1", course_type_id: 3, discipline_id: 1}

      response.status.should eq(200)
      response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
    end

    it "list all by semester, type, course and discipline" do
      get "/api/v1/sav/groups", {semester: "2012.1", course_type_id: 3, course_id: 10, discipline_id: 1}

      response.status.should eq(200)
      response.body.should == [{id: 8, code: "IL-CAU", offer_id: 6},{id: 6, code: "IL-FOR", offer_id: 6}].to_json
    end
  end

end
