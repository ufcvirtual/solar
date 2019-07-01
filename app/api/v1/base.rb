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
    mount Comments
    mount Webconferences
    mount Logs
    mount MessagesAPI
    mount Assignments

    mount RemoveAfterChanges

    add_swagger_documentation base_path: '/api/',
      hide_documentation_path: true,
      endpoint_auth_wrapper: Rack::OAuth2,
     # swagger_endpoint_guard: 'oauth2 false',
      token_owner: 'resource_owner',
      info: {
        title: "API Solar 2.0",
        description: "Está página contém todas as chamadas da API presentes no Solar 2.0.",
        contact_name: "Instituto UFC Virtual - CP2",
        contact_email: "atendimento@virtual.ufc.br",
        contact_url: "http://portal.virtual.ufc.br/index.php/contato/",
        license: "GPL v3",
        license_url: "https://github.com/wwagner33/solar/blob/master/GPLv3",
      }
  end
end