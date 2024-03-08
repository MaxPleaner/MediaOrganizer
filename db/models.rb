require 'sinatra/activerecord'
set :database, {adapter: "sqlite3", database: "MediaOrganizer.sqlite3"}

class Item < ActiveRecord::Base
  has_many :items_tags, dependent: :destroy
  has_many :items_collections, dependent: :destroy
  has_many :tags, through: :items_tags
  has_many :collections, through: :items_collections
  
  def self.import_file(path, update_tags: false, get_tags: true, calc_phash: true)
    parts = path.split("/")
	return if parts.last == ".DS_Store"
	return if parts.last.start_with?(".")
	return if !File.exist?(path) || File.symlink?(path)
    
    item = Item.find_by(path: path)
    exists = !!item
    item ||= Item.create(path: path)
    item.set_type
    
    # avoid sending large files to phash or exiftool
    # since things can freeze up (and timeout won't even handle)
    return if size_mb(item.path) > 50
    
    item.create_tags if get_tags && (!exists || update_tags)
    item.set_phash if calc_phash rescue nil
  end
  
  def self.size_mb(path)
    File.size(path).to_f / (1024 * 1024)
  end
  
  MEDIA_TYPES = ["image", "gif", "video", "other"]
  
  def set_type(force_update: false)
    return if media_type && !force_update
    val = case File.extname(path).downcase
    when ".jpg", ".jpeg", ".svg", ".png", "webp"
		"image"
	when ".gif", "webm"
		"gif"
	when ".avi", ".mp4", ".mkv", ".m4v", ".mov"
		"video"
	else
		"other"
	end
	update(media_type: val)
  end
  
  def create_tags
    keywords = []
	Timeout.timeout(10) do
		exif = MiniExiftool.new(path) rescue nil
		keywords = [*exif&.keywords]
    end rescue puts("#{path} took too long in exiftool")
	tags = keywords.map do |keyword|
	  Tag.find_or_create_by(name: keyword)
	end
	tags.each do |tag|
	  items_tags.find_or_create_by(tag: tag)
	end
  end
  
  def set_phash(force_update: false)
    return if phash && !force_update
    hash = nil
    Timeout.timeout(10) do
      hash = ImageHash.new(path).hash
    end rescue puts("#{path} took too long in phash")
    update(phash: hash)
  end  
  
  def write_metadata
    reload
    return unless File.exist?(path)
    exiftool = MiniExiftool.new(path)
    tag_names = tags.pluck(:name)
    tag_names = nil if tag_names.empty?
    exiftool.keywords = tag_names&.uniq
    exiftool.save
    update(dirty: false) if dirty
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
  
  after_commit :mark_item_dirty, on: [:create, :destroy, :update]
  
  def mark_item_dirty
    return unless item
    item.update(dirty: true) unless item.dirty
  end
end

class ItemsCollection < ActiveRecord::Base
  belongs_to :item
  belongs_to :collection
end
