require 'rest_client'
class DigitalClass < ActiveRecord::Base
    
  DC = YAML::load(File.open("config/digital_class.yml"))[Rails.env.to_s] rescue nil if File.exist?("config/digital_class.yml")

  def self.available?
    (!DC.nil? && DC["integrated"] && !RestClient.get(DC["path"]).nil?)
  rescue
    false # servidor indisponivel
  end

  def self.call(path, params={}, replace=[], method=:get)
    url = File.join(DC["url"], DC["paths"][path])
    replace.each do |string|
      url.gsub! ":#{string}", params[string.to_sym].to_s
    end
    res = RestClient.send(method, url, { params: { access_token: self.access_token }.merge!(params), accept: :json, content_type: 'x-www-form-urlencoded' })
    JSON.parse(res.body)
  rescue
    false # indisponivel ou erro na chamada
  end

  private

    def self.access_token
      File.open(DC["token_path"], &:readline).strip
    end

end
