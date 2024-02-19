class AddDirtyToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :dirty, :boolean, default: false
  end
end
