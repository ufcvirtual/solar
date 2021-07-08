class DefaultValueToDefaultLocale < ActiveRecord::Migration[5.1]
  def change
    change_column :personal_configurations, :default_locale, :string, default: 'pt_BR'
  end
end
