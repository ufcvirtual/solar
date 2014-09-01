require "spec_helper"

describe UserBlacklistController do
  describe "routing" do

    it "routes to #index" do
      get("/user_blacklist").should route_to("user_blacklist#index")
    end

    it "routes to #new" do
      get("/user_blacklist/new").should route_to("user_blacklist#new")
    end

    it "routes to #show" do
      get("/user_blacklist/1").should route_to("user_blacklist#show", :id => "1")
    end

    it "routes to #edit" do
      get("/user_blacklist/1/edit").should route_to("user_blacklist#edit", :id => "1")
    end

    it "routes to #create" do
      post("/user_blacklist").should route_to("user_blacklist#create")
    end

    it "routes to #update" do
      put("/user_blacklist/1").should route_to("user_blacklist#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/user_blacklist/1").should route_to("user_blacklist#destroy", :id => "1")
    end

  end
end
