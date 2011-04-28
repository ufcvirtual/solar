require 'spec_helper'

describe CurriculumUnitsController do
   let(:curriculum_unit) {mock_model(CurriculumUnit)}
  describe "#acessando unidade curricular" do

    before(:each) do
      controller.stub!(:authenticate).and_return(true)
    end

    it "should be successful" do
      get :access, :params => {:id => uc.id}
      assigns[:curriculum_unit].should == uc
    end
  end

end
