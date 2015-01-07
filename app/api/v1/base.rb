module V1
  class Base < ApplicationAPI
    version "v1", using: :path

    mount Routes
    mount Users
    mount Groups
    mount Offers
    mount CurriculumUnits
    mount Courses
    mount Allocations
    mount Profiles
    mount Discussions
    mount Events
    mount Posts
    mount Lessons
    mount Scores
    mount SupportMaterialFiles
    mount Agendas
    mount Taggables
    mount Savs

    mount RemoveAfterChanges
  end
end
