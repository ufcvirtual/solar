require 'spec_helper'

describe 'users' do
  let!(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "http://app.com") }
  let!(:user) { User.find_by_username("aluno1") }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }

  it 'informacoes do usuario logado' do
    get "/api/v1/users/me", access_token: token.token

    response.status.should eq(200)
    response.body.should == { name: user.name, username: user.username, email: user.email, photo: "/users/#{user.id}/photo" }.to_json
  end

  it 'informacoes do usuario logado - sem token' do
    get "/api/v1/users/me"

    response.status.should eq(401)
    response.body.should == {error: "unauthorized"}.to_json
  end

end
