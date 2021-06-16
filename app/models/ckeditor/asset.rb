class Ckeditor::Asset < ActiveRecord::Base
  include ActiveRecord
  include Ckeditor::Orm::ActiveRecord::AssetBase
  include Ckeditor::Backend::Paperclip
end
