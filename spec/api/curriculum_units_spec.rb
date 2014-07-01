require "spec_helper"

describe "CurriculumUnits" do

  fixtures :all

  describe ".list" do

    context "with access token" do

      let!(:user) { User.find_by_username("aluno1") }
      let!(:token) { Doorkeeper::AccessToken.create! resource_owner_id: user.id }

      it "gets list of UC" do
        get "/api/v1/curriculum_units", access_token: token.token

        response.status.should eq(200)
        response.body.should == [{id: 1,code: "RM404",name: "Introducao a Linguistica"},{id: 3,code: "RM301",name: "Quimica I"},{id: 2,code: "RM405",name: "Teoria da Literatura I"}].to_json
      end

      it "gets list of UC with groups" do
        get "/api/v1/curriculum_units/groups", access_token: token.token

        response.status.should eq(200)
        response.body.should == [
          {id: 1, code: "RM404", name: "Introducao a Linguistica",
            groups: [{id: 1, code: "IL-FOR", semester: "2011.1"}]},
          {id: 3, code: "RM301", name: "Quimica I",
            groups: [{id: 3, code: "QM-CAU", semester: "2011.1"}]},
          {id: 2, code: "RM405", name: "Teoria da Literatura I",
            groups: [{id: 2, code: "TL-CAU", semester: "2011.1"}]}].to_json
      end
    end

    context "without access token" do

      it 'gets an unauthorized error to list' do
        get "/api/v1/curriculum_units"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end

      it 'gets an unauthorized error to list with groups' do
        get "/api/v1/curriculum_units/groups"

        response.status.should eq(401)
        response.body.should == {error: "unauthorized"}.to_json
      end
    end

  end

end
