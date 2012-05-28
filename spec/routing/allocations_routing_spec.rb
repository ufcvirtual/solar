require "spec_helper"

describe AllocationsController do
  describe "routing" do

    it "routes to #index" do
      get("/allocations").should route_to("allocations#index")
    end

    it "routes to #new" do
      get("/allocations/new").should route_to("allocations#new")
    end

    it "routes to #show" do
      get("/allocations/1").should route_to("allocations#show", :id => "1")
    end

    it "routes to #edit" do
      get("/allocations/1/edit").should route_to("allocations#edit", :id => "1")
    end

    it "routes to #create" do
      post("/allocations").should route_to("allocations#create")
    end

    it "routes to #update" do
      put("/allocations/1").should route_to("allocations#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/allocations/1").should route_to("allocations#destroy", :id => "1")
    end

  end
end
