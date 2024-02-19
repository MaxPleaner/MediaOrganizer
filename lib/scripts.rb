require 'mini_exiftool'
require 'image_hash'
require 'timeout'

class Scripts
  def self.import_folder(folder, start_idx: 0, i: -1, calc_phash: true, total_count: nil, recurse: true, update_tags: false, logger: false)
    total_count ||= `find #{folder} -type f | wc -l`.to_i
    set_logger(enabled: logger) do
		folder = File.expand_path(folder)
		entries = Dir.entries(folder)
		puts "\n\nimporting from #{folder}: #{entries.count} items"
		next_folders = []
		entries.each do |entry|
		  i += 1
		  next if start_idx > i
		  next if ["..", "."].include?(entry)
		  path = File.join(folder, entry)
		  if File.directory?(path)
			next_folders << path
		  else
			import_file(path, update_tags: update_tags, calc_phash: calc_phash)
			print '.'
		  end
		  if i % 50 == 0
		    puts "#{i}/#{total_count} (#{(i * 100 / total_count).round(2)}%)"
		  end
		end
		
		if recurse
		  next_folders.each do |folder|
			i = import_folder(folder, total_count: total_count, i: i)
		  end
		end
	end
	return i
  end
  
  def self.set_logger(enabled:, &blk)
    return blk.call if enabled || !ActiveRecord::Base.logger
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    result = blk.call
    ActiveRecord::Base.logger = old_logger
    result
  end
  
  def self.import_file(path, update_tags: false, calc_phash: true)
    parts = path.split("/")
	return if parts.last == ".DS_Store"
	return if parts.last.start_with?(".")
	return if !File.exist?(path) || File.symlink?(path)
    
    item = Item.find_by(path: path)
    exists = !!item
    item ||= Item.create(path: path)
    
    # avoid sending large files to phash or exiftool
    # since things can freeze up (and timeout won't even handle)
    return if size_mb(item.path) > 50
    
    create_tags(item) if (!exists || update_tags)
    set_phash(item) if calc_phash rescue nil
  end
  
  def self.size_mb(path)
    File.size(path).to_f / (1024 * 1024)
  end
  
  def self.create_tags(item)
    keywords = []
	Timeout.timeout(10) do
		exif = MiniExiftool.new(item.path) rescue nil
		keywords = [*exif&.keywords]
    end rescue puts("#{item.path} took too long in exiftool")
	tags = keywords.map do |keyword|
	  Tag.find_or_create_by(name: keyword)
	end
	tags.each do |tag|
	  item.items_tags.find_or_create_by(tag: tag)
	end
  end
  
  def self.set_phash(item, force_update: false)
    return if item.phash && !force_update
    hash = nil
    Timeout.timeout(10) do
      hash = ImageHash.new(item.path).hash
    end rescue puts("#{item.path} took too long in phash")
    item.update(phash: hash)
  end
end

if ENV["IMPORT"] == "true"
  Scripts.import_folder("~/Desktop/xyz", update_tags: false)
end
