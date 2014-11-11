require "spec_helper"

describe "Savs" do

  fixtures :all

  context "create" do

    context "with sav_id and group_id" do
      let!(:json_data){ { group_id: 3, start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(1) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(201)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with sav_id and groups_ids" do
      let!(:json_data){ { groups_ids: [1,2,3], start_date: Date.current, end_date: Date.current + 4.months } }

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
      let!(:json_data){ { groups_ids: [1,2,3], start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/savX", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/savX", json_data
        response.status.should eq(400)
      }
    end

    context "with wrong params - wrong type - group_id" do
      let!(:json_data){ { group_id: "T01", start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(400)
      }
    end

    context "with wrong params - wrong type - groups_ids" do
      let!(:json_data){ { groups_ids: "T01", start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(400)
      }
    end

    context "with wrong params - multiple params" do
      let!(:json_data){ { groups_ids: [1,2], group_id: 3, start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(400)
      }
    end

    context "missing params - dates" do
      let!(:json_data){ { groups_ids: [1,2] } }

      subject{ -> { post "/api/v1/sav/1", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/1", json_data
        response.status.should eq(400)
      }
    end

    context "already exists" do
      let!(:json_data){ { groups_ids: [1,2], start_date: Date.current, end_date: Date.current + 4.months } }

      subject{ -> { post "/api/v1/sav/3", json_data } } 

      it { should change(Sav,:count).by(0) }
  
      it {
        post "/api/v1/sav/3", json_data
        response.status.should eq(422)
      }
    end
    
  end # dont create

  context "delete" do

    context "with sav_id and group_id" do
      let!(:json_data){ { group_id: 1 } }

      subject{ -> { delete "/api/v1/sav/3", json_data } } 

      it { should change(Sav,:count).by(-1) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(200)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with sav_id and groups_ids" do
      let!(:json_data){ { groups_ids: [1,2] } }

      subject{ -> { delete "/api/v1/sav/3", json_data } } 

      it { should change(Sav,:count).by(-2) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(200)
        response.body.should == {ok: :ok}.to_json
      }
    end

    context "with sav_id" do
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

    context "with wrong params - wrong type - group_id" do
      let!(:json_data){ { group_id: "T01" } }

      subject{ -> { delete "/api/v1/sav/3", json_data} }

      it { should change(Sav,:count).by(0) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(400)
      }
    end

    context "with wrong params - wrong type - groups_ids" do
      let!(:json_data){ { groups_ids: "T01" } }

      subject{ -> { delete "/api/v1/sav/3", json_data } }

      it { should change(Sav,:count).by(0) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(400)
      }
    end

    context "with wrong params - to many params" do
      let!(:json_data){ { groups_ids: [1,2], group_id: 1 } }

      subject{ -> { delete "/api/v1/sav/3", json_data } }

      it { should change(Sav,:count).by(0) }
  
      it {
        delete "/api/v1/sav/3", json_data
        response.status.should eq(400)
      }
    end
    
  end # dont delete

end
