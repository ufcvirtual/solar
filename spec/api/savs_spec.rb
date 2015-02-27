require "spec_helper"

describe "Savs" do

  fixtures :all

  before(:each) do
    Sav.create questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1, start_date: (Date.today - 3), end_date: (Date.today + 3.months)
    Sav.create questionnaire_id: 3, allocation_tag_id: 8, profile_id: 1, start_date: (Date.today - 3), end_date: (Date.today + 3.months)
    Sav.create questionnaire_id: 4, profile_id: 2, start_date: (Date.today - 3), end_date: (Date.today + 3.months)
  end

  context "create" do

    context "with only questionnaire_id" do
      let!(:json_data){ { start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav.where(questionnaire_id: 1, allocation_tag_id: nil, profile_id: nil),:count).by(1) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(201)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id and group_id" do
      let!(:json_data){ { group_id: [3], start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(1) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(201)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id and groups_id" do
      let!(:json_data){ { groups_id: [1,2,3], start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(3) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(201)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id and course_id" do
      let!(:json_data){ { course_id: 1, start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(1) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(201)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id and course_id and profile_id" do
      let!(:json_data){ { course_id: 1, profiles_ids: [1], start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(1) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(201)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id and course_id and semester_id, and profile_id" do
      let!(:json_data){ { course_id: 1, semester_id: 2, profiles_ids: [1] } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(1) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(201)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id and course_id and profiles_ids" do
      let!(:json_data){ { course_id: 1, profiles_ids: [1,2,3], start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(3) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(201)
        response.body.should == {ok: :ok}.to_json
      }
    end

  end # create

  context "dont create" do

    context "with wrong params - wrong type - id" do
      let!(:json_data){ { groups_id: [1,2,3], start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/savX", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/savX", json_data
        response.status.should eq(400)
      }
    end

    context "group doesnt exist" do
      let!(:json_data){ { groups_id: ["T01"], start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(404)
      }
    end

    context "with wrong params - wrong type" do
      let!(:json_data){ { groups_id: "T01", start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(400)
      }
    end

    context "with wrong params - multiple params" do
      let!(:json_data){ { groups_id: [1,2], course_id: 3, start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(400)
      }
    end

    context "already exists" do
      let!(:json_data){ { groups_id: [2,3], start_date: Date.current, end_date: Date.current + 4.months, profiles_ids: [1] } }

      subject{ -> { post "/api/v1/sav/3", json_data  } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/3", json_data
        response.status.should eq(422)
      }
    end

    context "percent with wrong type" do
      let!(:json_data){ { groups_id: [2,3], profiles_ids: [1], percent: "teste" } }

      subject{ -> { post "/api/v1/sav/4", json_data  } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/4", json_data
        response.status.should eq(422)
      }
    end

    context "percent too big" do
      let!(:json_data){ { groups_id: [2,3], profiles_ids: [1], percent: 320 } }

      subject{ -> { post "/api/v1/sav/4", json_data  } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/4", json_data
        response.status.should eq(422)
      }
    end
    
  end # dont create

  context "delete" do

    context "with questionnaire_id and group_id" do
      let!(:json_data){ { groups_id: [3] } }

      subject{ -> { delete "/api/v1/sav/3", json_data } } 

      it { should change(Sav,:count).by(-1) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(200)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id and groups_id" do
      let!(:json_data){ { groups_id: [3,5,6] } }

      subject{ -> { delete "/api/v1/sav/3", json_data } } 

      it { should change(Sav,:count).by(-2) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(200)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id" do
      subject{ -> { delete "/api/v1/sav/3" } } 

      it { should change(Sav,:count).by(-2) }
  
      it {
        delete "/api/v1/sav/3"
        response.status.should eq(200)
        response.body.should == {ok: :ok}.to_json
      }
    end

  end # delete

  context "dont delete" do

    context "with wrong params - wrong type - id" do
      subject{ -> { delete "/api/v1/sav/savX" } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        delete "/api/v1/sav/savX"
        response.status.should eq(400)
      }
    end

    context "with not existing group" do
      let!(:json_data){ { groups_id: ["T01"] } }

      subject{ -> { delete "/api/v1/sav/3", json_data} }

      it { should change(Sav,:count).by(0) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(404)
      }
    end

    context "with wrong params - wrong type - groups_id" do
      let!(:json_data){ { groups_id: "T01" } }

      subject{ -> { delete "/api/v1/sav/3", json_data } }

      it { should change(Sav,:count).by(0) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(400)
      }
    end

    context "with wrong params - to many params" do
      let!(:json_data){ { groups_id: [1,2], course_id: 1 } }

      subject{ -> { delete "/api/v1/sav/3", json_data } }

      it { should change(Sav,:count).by(0) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(400)
      }
    end
    
  end # dont delete

  context "edit" do

    context "with questionnaire_id and group" do
      let!(:json_data){ { start_date: Date.current - 5.months, groups_id: [3]} }

      subject{ -> { put "/api/v1/sav/3", json_data } } 

      it { should change(Sav.where(questionnaire_id: 3, allocation_tag_id: 3),:count).by(0) }
  
      it {
        put "/api/v1/sav/3", json_data
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3).first.start_date == (Date.current - 5.months)
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.end_date == (Date.today + 3.months) # don't change
        response.status.should eq(200)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with questionnaire_id and profile" do
      let!(:json_data){ { start_date: Date.current - 5.months, groups_id: [3], profiles_ids: [1]} }

      subject{ -> { put "/api/v1/sav/3", json_data } } 

      it { should change(Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1),:count).by(0) }
  
      it {
        put "/api/v1/sav/3", json_data
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.start_date == (Date.current - 5.months)
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.end_date == (Date.today + 3.months) # don't change
        response.status.should eq(200)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with start and end dates" do
      let!(:json_data){ { start_date: Date.current - 5.months, end_date: Date.current + 5.months, groups_id: [3], profiles_ids: [1]} }

      subject{ -> { put "/api/v1/sav/3", json_data } } 

      it { should change(Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1),:count).by(0) }
  
      it {
        put "/api/v1/sav/3", json_data
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.start_date == (Date.current - 5.months)
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.end_date == (Date.today + 5.months)
        response.status.should eq(200)
        response.body.should == {ok: :ok}.to_json
      }
    end

  end # edit

  context "dont edit" do

    context "with wrong params - wrong type - id" do
      let!(:json_data){ { start_date: Date.current - 5.months, groups_id: [3], profiles_ids: [1]} }

      it {
        put "/api/v1/sav/savX", json_data
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.start_date == (Date.today - 3) # don't change
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.end_date == (Date.today + 3.months) # don't change
        response.status.should eq(400)
      }
    end

    context "group doesnt exist" do
      let!(:json_data){ { start_date: Date.current - 5.months, groups_id: ["T01"]} }

      it {
        put "/api/v1/sav/savX", json_data
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.start_date == (Date.today - 3) # don't change
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.end_date == (Date.today + 3.months) # don't change
        response.status.should eq(400)
      }
    end
  
    context "with wrong params - wrong type" do
      let!(:json_data){ { start_date: Date.current - 5.months, groups_id: "T01"} }

      it {
        put "/api/v1/sav/savX", json_data
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.start_date == (Date.today - 3) # don't change
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.end_date == (Date.today + 3.months) # don't change
        response.status.should eq(400)
      }
    end
  
    context "with wrong params - multiple params" do
      let!(:json_data){ { start_date: Date.current - 5.months, groups_id: [3], course_id: 3} }

      it {
        put "/api/v1/sav/savX", json_data
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.start_date == (Date.today - 3) # don't change
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.end_date == (Date.today + 3.months) # don't change
        response.status.should eq(400)
      }
    end

    context "missing date" do
      let!(:json_data){ {groups_id: [3]} }

      it {
        put "/api/v1/sav/savX", json_data
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.start_date == (Date.today - 3) # don't change
        Sav.where(questionnaire_id: 3, allocation_tag_id: 3, profile_id: 1).first.end_date == (Date.today + 3.months) # don't change
        response.status.should eq(400)
      }
    end
    
  end # dont edit

end
