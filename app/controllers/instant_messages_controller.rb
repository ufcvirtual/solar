require 'xmpp4r'
require 'xmpp4r/httpbinding/client'

class InstantMessagesController < ApplicationController

  def prebind
      # @client = Jabber::HTTPBinding::Client.new("#{current_user.username}"+ @dominio +"/im")
      # puts "#{current_user.username}"+ @dominio +"/im"
      # @client.connect('http://'+ @ip +':' + @porta + '/http-bind/')
      # @client.auth(current_user.encrypted_password)
      # # @client.send(Jabber::Presence.new.set_type(:available))
      # msg = { :jid => @client.instance_variable_get("@jid").inspect, 
      #         :sid => @client.instance_variable_get("@http_sid"),
      #         :rid => @client.instance_variable_get("@http_rid"), 
      #         :bosh_service_url => 'http://'+ @ip +':' + @porta + '/http-bind/' }
       
      # puts "4"
      # puts msg

      # render :json => msg

      # session[:sid]  = @client.instance_variable_get("@http_sid")
      # session[:rid]  = @client.instance_variable_get("@http_rid")
      # session[:jid]  = @client.instance_variable_get("@jid").inspect
  end 
end