require "spec_helper"

describe "Courses" do

  fixtures :all

  describe ".course" do

    describe "post" do

      context "with valid ip" do

        context 'create course' do
          let!(:json_data){ { 
            name: "Curso 01",
            code: "C01"
          } }

          subject{ -> { post "/api/v1/course", json_data } } 

          it { should change(Course,:count).by(1) }

          it {
            post "/api/v1/course", json_data
            response.status.should eq(201)
            response.body.should == {id: Course.find_by_code("C01").id}.to_json
          }
        end

      end

    end # post

  end # .course

end