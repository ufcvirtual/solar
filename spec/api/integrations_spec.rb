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
              Turmas: ["QM-CAU", "TL-FOR", "QM-MAR"]
            }

            expect{
              post "/api/v1/integration/events/", events

              response.status.should eq(201)
              response.body.should == [ {Codigo: "QM-CAU", id: ScheduleEvent.last(3).first.id},
                {Codigo: "TL-FOR", id: ScheduleEvent.last(2).first.id}, {Codigo: "QM-MAR", id: ScheduleEvent.last.id}
              ].to_json
            }.to change{ScheduleEvent.where(integrated: true).count}.by(3)
          }
        end

        context "and not existing group" do
          it {
            events = {
              CodigoDisciplina: "RM301", CodigoCurso: "109", Periodo: "2011.1", DataInserida: {
                Tipo: 1, Data: "2014-11-01", Polo: "Pindamanhangaba", HoraInicio: "10:00", HoraFim: "11:00" },
              Turmas: ["T01", "TL-FOR", "QM-MAR"]
            }

            expect{
              post "/api/v1/integration/events/", events

              response.status.should eq(422)
            }.to change{ScheduleEvent.count}.by(0)
          }
        end

        context "and missing event params" do
          it {
            events = {
              CodigoDisciplina: "RM301", CodigoCurso: "109", Periodo: "2011.1", DataInserida: {
                Tipo: 1, Polo: "Pindamanhangaba", HoraInicio: "10:00", HoraFim: "11:00" },
              Turmas: ["QM-CAU", "TL-FOR", "QM-MAR"]
            }

            expect{
              post "/api/v1/integration/events/", events

              response.status.should eq(400)
            }.to change{ScheduleEvent.count}.by(0)
          }
        end

      end # with valid ip

      context "with invalid ip" do
        it "gets a not found error" do
          events = {
            CodigoDisciplina: "RM301", CodigoCurso: "109", Periodo: "2011.1", DataInserida: {
              Tipo: 1, Data: "2014-11-01", Polo: "Pindamanhangaba", HoraInicio: "10:00", HoraFim: "11:00" },
            Turmas: ["QM-CAU", "TL-FOR", "QM-MAR"]
          }

          expect{
            post "/api/v1/integration/events/", events, "REMOTE_ADDR" => "127.0.0.2"
            response.status.should eq(404)
            }.to change{ScheduleEvent.count}.by(0)
        end
      end

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

        context "and non existing events" do
          it {
            expect{
              delete "/api/v1/integration/events/122"

              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
            }.to change{ScheduleEvent.count}.by(0)
          }
        end

        context "and missing params" do
          it {
            expect{
              delete "/api/v1/integration/events/"

              response.status.should eq(405)
            }.to change{ScheduleEvent.count}.by(0)
          }
        end
      end # valid ip

      context "with invalid ip" do
        it "gets a not found error" do
          expect{
            delete "/api/v1/integration/events/2,3", nil, "REMOTE_ADDR" => "127.0.0.2"
            response.status.should eq(404)
            }.to change{ScheduleEvent.count}.by(0)
        end
      end

    end # :ids

  end # .events

  describe ".event" do

    describe "put :id" do

      context "with valid ip" do
        context "and existing event" do
          it {
            event = { Data: (Date.today - 1.day).to_s, HoraInicio: "10:00", HoraFim: "11:00" }

            expect{
              put "/api/v1/integration/event/3", event
              response.status.should eq(200)
              response.body.should == {ok: :ok}.to_json
              expect(ScheduleEvent.find(3).as_json).to eq({
                description: "Encontro Presencial marcado para esse período", # não é alterado
                end_hour: "11:00",
                id: 3,
                integrated: true,
                place: "Polo A", # não é alterado
                schedule_id: 27,
                start_hour: "10:00",
                title: "Encontro Presencial", # não é alterado
                type_event: 2 # não é alterado
              }.as_json)
            }.to change{ScheduleEvent.count}.by(0)
          }
        end

        context "and non existing event" do
          it {
            event = { Data: (Date.today - 1.day).to_s, HoraInicio: "10:00", HoraFim: "11:00" }

            expect{
              put "/api/v1/integration/event/333", event
              response.status.should eq(422)
            }.to change{ScheduleEvent.count}.by(0)
          }
        end

        context "and missing params" do
          it {
            event = { Data: (Date.today - 1.day).to_s, HoraInicio: "10:00" }

            expect{
              put "/api/v1/integration/event/3", event
              response.status.should eq(400)
            }.to change{ScheduleEvent.count}.by(0)
          }
        end
      end # valid ip

      context "with invalid ip" do
        it "gets a not found error" do
          event = { Data: (Date.today - 1.day).to_s, HoraInicio: "10:00", HoraFim: "11:00" }

          expect{
            put "/api/v1/integration/event/3", event, "REMOTE_ADDR" => "127.0.0.2"
            response.status.should eq(404)
            }.to change{ScheduleEvent.count}.by(0)
        end
      end

    end # PUT :id

  end # .event

end
