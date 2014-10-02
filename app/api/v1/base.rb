module V1
  class Base < ApplicationAPI
    version "v1", using: :path

    helpers V1::V1Helpers

    mount Routes
    mount Users
    mount Groups
    mount CurriculumUnits
    mount Discussions
    mount Posts
    mount Loads
    mount Integrations
    mount Lessons
    mount Sav
  end
end
