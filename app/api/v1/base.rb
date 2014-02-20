module V1
  class Base < ApplicationAPI
    version "v1", using: :path

    mount Routes
    mount Users
    mount Groups
    mount CurriculumUnits
    mount Discussions
    mount Posts
    mount Loads
  end
end
