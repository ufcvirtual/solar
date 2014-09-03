require "em-websocket"
class WebsocketServer    
  EM.run {
    @subs = {} # list with subscribed users
    EventMachine::WebSocket.start(host: "127.0.0.1", port: 3001) do |ws|
      ws.onopen { |data|
        academic_allocation_id = data.path.split("/")[1]
        ac_subs = @subs[academic_allocation_id.to_sym]
        # add new client
        if ac_subs.nil?
          @subs[academic_allocation_id.to_sym] = [ws]
        else
          @subs[academic_allocation_id.to_sym] << ws
        end
      }
      ws.onmessage { |msg|
        # get academic_allocation
        subs = @subs[msg.split(":").last.delete('"}').to_sym].dup
        subs.delete(ws) # remove the client who have sent the message
        subs.each {|s| s.send msg }
      }
      ws.onclose { |data|
        @subs.delete_if {|key, value| key == ws}
      }
    end
  }
end