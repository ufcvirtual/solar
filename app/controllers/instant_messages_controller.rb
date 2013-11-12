require 'xmpp4r'
require 'xmpp4r/httpbinding/client'

class InstantMessagesController < ApplicationController

#############################################################################
# converse.js (Linha 3007)
#http://javascriptcompressor.com/
#http://www.javascriptobfuscator.com/
#http://www.phpblog.com.br/exemplos/encodejavascript/index.php
#############################################################################
# var pass = xmpp_cpf.slice(5)+xmpp_username+xmpp_id;
# var shaObj = new jsSHA(pass, "TEXT");
# var hash = shaObj.getHash("SHA-1", "HEX");
# jid = xmpp_username + "@optiplex-780/im";
# this.connect(jid, hash);
##############################################################################

# def register_user
#       if current_user 
#         unless current_user.is_registered
#           jid = Jabber::JID::new("#{current_user.username}@optiplex-780")
#           xmpp_client = Jabber::Client.new(jid)
#           xmpp_client.connect("localhost")
#           xmpp_client.register(current_user.username, 'name' => "#{current_user.name}", 'email' => "#{current_user.email}")
#           xmpp_client.close
#           current_user.is_registered = true
#           current_user.save
#         end
#       end
#     end

  def prebind
    if current_user.is_registered 
      @client = Jabber::HTTPBinding::Client.new("#{current_user.username}"+ @dominio +"/im")
      puts "#{current_user.username}"+ @dominio +"/im"
      @client.connect('http://'+ @ip +':7070/http-bind/')
      puts @current_user.username
      @client.auth(current_user.username)
      puts current_user.username
      @client.send(Jabber::Presence.new.set_type(:available))

      msg = { :jid => @client.instance_variable_get("@jid").inspect, 
              :sid => @client.instance_variable_get("@http_sid"),
              :rid => @client.instance_variable_get("@http_rid"), 
              :bosh_service_url => 'http://'+ @ip +':7070/http-bind/' }
       
      puts "4"
      puts msg

      render :json => msg

      # session[:sid]  = @client.instance_variable_get("@http_sid")
      # session[:rid]  = @client.instance_variable_get("@http_rid")
      # session[:jid]  = @client.instance_variable_get("@jid").inspect
    end
  end  
end