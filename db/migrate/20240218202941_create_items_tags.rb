class CreateItemsTags < ActiveRecord::Migration[7.1]
  def change
    create_table :items_tags do |t|
      t.references :item
      t.references :tag
    end
  end
end
