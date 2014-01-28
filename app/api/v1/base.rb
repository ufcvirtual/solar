module V1
  class Base < ApplicationAPI
    version "v1", using: :path

    mount Users
    mount CurriculumUnits
    mount Groups
  end
end
