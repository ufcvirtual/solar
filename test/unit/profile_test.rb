require 'test_helper'

class ProfileTest < ActiveSupport::TestCase

  test "cadastrar" do
    profile = Profile.new name: "Lorem", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

    assert profile.valid?
    assert profile.save
  end

  test "cadastrar - testando dados invalidos" do
    profile = Profile.new

    assert not(profile.valid?)
    assert_equal profile.errors.messages.keys, [:description, :name]

    profile.name = "Lorem"

    assert not(profile.valid?)
    assert_equal profile.errors.messages.keys, [:description]

    profile.description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

    assert profile.valid?
    assert profile.save
  end

  test "adicionar permissoes" do
    profile = Profile.create name: "Lorem", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

    assert profile.resources.empty?

    profile.resources << profiles(:aluno).resources ## usando template de aluno

    assert not(profile.resources.empty?)
  end

  test "deletar" do
    profile = Profile.create name: "Lorem", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    profile.resources << profiles(:aluno).resources

    assert profile.destroy
  end

end
