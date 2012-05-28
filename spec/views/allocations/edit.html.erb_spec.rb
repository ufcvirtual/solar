require 'spec_helper'

describe "allocations/edit" do
  before(:each) do
    @allocation = assign(:allocation, stub_model(Allocation))
  end

  it "renders the edit allocation form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => allocations_path(@allocation), :method => "post" do
    end
  end
end
