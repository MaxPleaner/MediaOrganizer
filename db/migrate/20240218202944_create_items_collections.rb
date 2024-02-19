class CreateItemsCollections < ActiveRecord::Migration[7.1]
  def change
     create_table :items_collections do |t|
      t.references :item
      t.references :collection
    end 
  end
end
