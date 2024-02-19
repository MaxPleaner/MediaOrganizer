require 'sinatra/activerecord'
set :database, {adapter: "sqlite3", database: "MediaOrganizer.sqlite3"}

class Item < ActiveRecord::Base
  has_many :items_tags, dependent: :destroy
  has_many :items_collections, dependent: :destroy
  has_many :tags, through: :items_tags
  has_many :collections, through: :items_collections
  
  def write_metadata
	exiftool = MiniExiftool.new(path)
	tag_names = reload.tags.pluck(:name)
	tag_names = nil if tag_names.empty?
	exiftool.keywords = tag_names
	exiftool.save  
  end
end

class Tag < ActiveRecord::Base
  has_many :items_tags, dependent: :destroy
  has_many :items, through: :items_tags
end

class Collection < ActiveRecord::Base
  has_many :items_collections, dependent: :destroy
  has_many :items, through: :items_collections
end

class ItemsTag < ActiveRecord::Base
  belongs_to :item
  belongs_to :tag
  
  # after_commit :write_metadata, on: [:create, :destroy, :update]
  
  def write_metadata
    item.write_metadata
  end
end

class ItemsCollection < ActiveRecord::Base
  belongs_to :item
  belongs_to :collection
end
