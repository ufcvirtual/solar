require File.expand_path('../../../config/environment',  __FILE__)
require 'em-websocket'
require 'yaml'
require 'rails'
require 'json'
require 'academic_allocation'
require 'bbb'
# Sempre que este arquivo for alterado, deve-se matar manualmente o processo em producao e rodar o upgrade do projeto
# Always when this file is changed, the production proccess must be killed and then the upgrade of project must be done

class WebsocketServer
  config = YAML::load(File.open('config/global.yml'))[Rails.env.to_s]['websocket']
  EM.run do
    @subs = {} # list with subscribed users
    EventMachine::WebSocket.start(host: config['host'], port: config['port']) do |ws|
      ws.onopen do |data|
        academic_allocation_id = data.path.split('/')[1]
        ac_subs = @subs[academic_allocation_id.to_sym]
        # add new client
        if ac_subs.nil?
          @subs[academic_allocation_id.to_sym] = [ws]
        else
          @subs[academic_allocation_id.to_sym] << ws
        end
      end
      ws.onmessage do |msg|
        # get academic_allocation
        subs = @subs[msg.split(':').last.delete('"}').to_sym].dup
        subs.delete(ws) # remove the client who have sent the message
        subs.each { |s| s.send msg }
      end
      ws.onclose do
        @subs.delete_if { |key| key == ws }
      end
    end

    @user_support = {} # list with subscribed users support
    EventMachine::WebSocket.start(host: config['host_support_help'], port: config['port_support_help']) do |ws_sh|
      ws_sh.onopen do |data|
        puts "Server: Conexão com o websocket aberta"
        # Recebe o id do usuário suporte do path
        user_support_id = data.path.split('/')[1]

        # Sem path - Webconferência chamando (Não é suporte)
        if user_support_id.nil?
          puts "Server: Usuário conectando..."
          # Responde se tem inscritos
          if @user_support.empty?
            puts "Server: Não tem ninguém do suporte inscrito/online"
            ws_sh.send "false"
            puts "Server: Encerra a conexão"
            ws_sh.close()
          else
            puts "Server: Existe suporte inscrito/online"
            ws_sh.send "true"
          end
        # Com path - É suporte. Inscreve os Users com profile type support - 128
        else
          user_support = @user_support[user_support_id.to_sym]
          puts "Server: Suporte conectando..."
          # add new client
          if user_support.nil?
            puts "Server: Cadastrando usuário suporte!"
            @user_support[user_support_id.to_sym] = [ws_sh]
          else
            puts "Server: Usuário suporte já registrado!"
            @user_support[user_support_id.to_sym] << ws_sh
          end
          #puts "Imprimindo usuários:"
          #@user_support.each { |us| puts us.inspect }
        end
      end

      ws_sh.onmessage do |msg|
        # Recebe - path vazio e msg = academic_allocation - das webconferências
        puts "Server: Recebendo academic_allocation do cliente: #{msg}"

        ac_id = JSON.parse(msg)["academic_allocation_id"]
        ac = AcademicAllocation.find(ac_id.to_i)

        if ac.support_help != Support_Help_Request
          puts "Server: Não existe chamado em aberto para essa webconferência"
          # Grava no banco a requisição
          Webconference.set_status_support_help(ac, Support_Help_Request)
          puts "Server: Pedido de suporte salvo no banco"

          # Adciona a quantidade de requisições
          msg.delete!('}').concat(",\"requests\":\"" + (Bbb.count_help).to_s + "\"}")
          puts "Server: Atualizando a quantidade de chamados em aberto"

          # Inscritos (suporte) são avisados do novo chamado.
          user_connections = @user_support.map { |us| us[1] }
          #puts user_connections.inspect
          user_connections.flatten.each { |us| us.send msg }
          puts "Server: Avisando aos usuários do suporte do novo chamado!!!"
        end
      end

      ws_sh.onclose do
        puts "Server: Encerrando a conexão com o websocket..."
        #@user_support.each { |u| puts u.inspect }
        puts ("deletando...")
        @user_support.delete_if {|key, value| value.include? ws_sh}
        puts "Server: Conexão encerrada! Conexões ativas: #{@user_support.keys}"
      end

      ws_sh.onerror do |e|
        puts "Server: Error: #{e.message}"
      end
    end

  end

end
