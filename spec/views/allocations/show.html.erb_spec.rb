require 'spec_helper'

describe "allocations/show" do
  before(:each) do
    @allocation = assign(:allocation, stub_model(Allocation))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
