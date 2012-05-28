require 'spec_helper'

describe "allocations/index" do
  before(:each) do
    assign(:allocations, [
      stub_model(Allocation),
      stub_model(Allocation)
    ])
  end

  it "renders a list of allocations" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
