class AddTypeToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :media_type, :string
  end
end
