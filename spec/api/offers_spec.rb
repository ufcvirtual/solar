require "spec_helper"

describe "Offers" do

  fixtures :all

  describe ".offer" do

    describe "post" do

      context "with valid ip" do

        context 'create offer' do

          context 'with new semester' do
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

          context 'with existing semester and same dates' do
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

          context 'with existing semester and same offer dates' do
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

          context 'with existing semester and different dates' do
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
          
          context 'with new semester and codes' do
            let!(:json_data){ { 
              name: "2014",
              offer_start: Date.today - 1.month,
              offer_end: Date.today + 1.month,
              curriculum_unit_code: "RM301",
              course_code: "109"
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

        end # create offer

        context "dont create offer" do

          context 'missing params - uc and course' do
            let!(:json_data){ { 
              name: "2014",
              offer_start: Date.today - 1.month,
              offer_end: Date.today + 1.month
            } }

            subject{ -> { post "/api/v1/offer", json_data } } 

            it { should change(Semester,:count).by(0) }
            it { should change(Schedule,:count).by(0) }
            it { should change(Offer,:count).by(0) }

            it {
              post "/api/v1/offer", json_data
              response.status.should eq(400)
            }
          end

          context 'missing params - others' do
            let!(:json_data){ { 
              offer_start: Date.today - 1.month,
              offer_end: Date.today + 1.month,
              curriculum_unit_code: "RM301",
              course_code: "109"
            } }

            subject{ -> { post "/api/v1/offer", json_data } } 

            it { should change(Semester,:count).by(0) }
            it { should change(Schedule,:count).by(0) }
            it { should change(Offer,:count).by(0) }

            it {
              post "/api/v1/offer", json_data
              response.status.should eq(400)
            }
          end

          context 'wrong date' do
            let!(:json_data){ { 
              name: "2014",
              offer_start: Date.today + 1.month,
              offer_end: Date.today - 1.month,
              curriculum_unit_code: "RM301",
              course_code: "109"
            } }

            subject{ -> { post "/api/v1/offer", json_data } } 

            it { should change(Semester,:count).by(0) }
            it { should change(Schedule,:count).by(0) }
            it { should change(Offer,:count).by(0) }

            it {
              post "/api/v1/offer", json_data
              response.status.should eq(422)
            }
          end

        end # dont create offer

      end

    end # post

  end # .offer

  describe "try access with invalid ip" do
    it "gets a not found error" do
      get "/api/v1/semesters", {}, {"REMOTE_ADDR" => "127.0.0.2"}
      response.status.should eq(404)
    end # describe access
  end

  describe "semesters" do
    it "list all" do
      get "/api/v1/semesters"

      response.status.should eq(200)
      response.body.should == Semester.order('name desc').uniq.to_json(only: [:name])
    end
  end # describe semesters

end