require "spec_helper"

describe "Offers" do

  fixtures :all

  describe ".offer" do

    describe "post" do

      context "with valid ip" do

        context 'create offer with new semester' do
          let!(:json_data){ { 
            name: "2014",
            offer_start: Date.today - 1.month,
            offer_end: Date.today + 1.month,
            curriculum_unit_id: 3, 
            course_id: 2
          } }

          subject{ -> { post "/api/v1/offer", json_data } } 

          it { should change(Semester,:count).by(1) }
          it { should change(Schedule,:count).by(2) }
          it { should change(Offer,:count).by(1) }

          it {
            post "/api/v1/offer", json_data
            response.status.should eq(201)
            response.body.should == {id: Offer.last.id}.to_json
          }
        end

        context 'create offer with existing semester and same dates' do
          let!(:json_data){ { 
            name: "2011.1",
            offer_start: '2011-03-10',
            offer_end: '2021-12-01',
            enrollment_start: '2011-01-01',
            enrollment_end: '2021-03-02',
            curriculum_unit_id: 1,
            course_id: 1
          } }

          subject{ -> { post "/api/v1/offer", json_data } } 

          it { should change(Semester,:count).by(0) }
          it { should change(Schedule,:count).by(0) }
          it { should change(Offer,:count).by(1) }

          it {
            post "/api/v1/offer", json_data
            response.status.should eq(201)
            response.body.should == {id: Offer.last.id}.to_json
          }
        end

        context 'create offer with existing semester and same offer dates' do
          let!(:json_data){ { 
            name: "2011.1",
            offer_start: '2011-03-10',
            offer_end: '2021-12-01',
            curriculum_unit_id: 1,
            course_id: 1
          } }

          subject{ -> { post "/api/v1/offer", json_data } } 

          it { should change(Semester,:count).by(0) }
          it { should change(Schedule,:count).by(1) }
          it { should change(Offer,:count).by(1) }

          it {
            post "/api/v1/offer", json_data
            response.status.should eq(201)
            response.body.should == {id: Offer.last.id}.to_json
            Offer.last.period_schedule.should be_nil
            Offer.last.enrollment_schedule.should_not be_nil
          }
        end

        context 'create offer with existing semester and different dates' do
          let!(:json_data){ { 
            name: "2011.1",
            offer_start: Date.today,
            offer_end: Date.today+4.month,
            curriculum_unit_id: 1,
            course_id: 1
          } }

          subject{ -> { post "/api/v1/offer", json_data } } 

          it { should change(Semester,:count).by(0) }
          it { should change(Schedule,:count).by(2) }
          it { should change(Offer,:count).by(1) }

          it {
            post "/api/v1/offer", json_data
            response.status.should eq(201)
            response.body.should == {id: Offer.last.id}.to_json
            Offer.last.period_schedule.start_date.to_date.should eq(Date.today.to_date)
            Offer.last.period_schedule.end_date.to_date.should eq((Date.today+4.month).to_date)
          }
        end
        
      end

    end # post

  end # .offer

end