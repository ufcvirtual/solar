require "spec_helper"

describe "Integrations" do

  fixtures :all

  describe ".events" do

    describe "/" do

      context "with valid ip" do
        context "and existing groups" do
          it {
            events = {
              CodigoDisciplina: "RM301", CodigoCurso: "109", Periodo: "2011.1", DataInserida: {
                Tipo: 1, Data: "2014-11-01", Polo: "Pindamanhangaba", HoraInicio: "10:00", HoraFim: "11:00" },
              Turmas: ["QM-MAR", "TL-FOR", "QM-MAR"]
            }

            expect{
              post "/api/v1/integration/events/", events

              response.status.should eq(201)
              response.body.should == [ {Codigo: "QM-MAR", id: ScheduleEvent.last(3).first.id}, 
                {Codigo: "TL-FOR", id: ScheduleEvent.last(2).first.id}, {Codigo: "QM-MAR", id: ScheduleEvent.last.id}
              ].to_json
            }.to change{ScheduleEvent.count}.by(3)
          }
        end
      end # with valid ip

    end # /

    describe ":ids" do

      context "with valid ip" do
        context "and existing events" do
          it {
            expect{
              delete "/api/v1/integration/events/2,3"

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }.to change{ScheduleEvent.count}.by(-2)
          }
        end
      end

    end # :ids

  end # .events

end