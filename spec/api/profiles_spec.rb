require "spec_helper"

describe "Profiles" do
  fixtures :all

  describe "try access with invalid ip" do
    context "gets a not authorized" do

      it "at profiles list" do
        get "/api/v1/profiles", {}, {"REMOTE_ADDR" => "127.0.0.2"}
        response.status.should eq(401)
      end

    end
  end

  describe "profiles" do

    it "gets a list of all" do
      get "/api/v1/profiles"

      response.status.should eq(200)
      response.body.should == Profile.all_except_basic.select('id, name').to_json
    end # it

  end # describe profiles

end