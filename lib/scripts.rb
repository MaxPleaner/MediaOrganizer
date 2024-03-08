require 'mini_exiftool'
require 'image_hash'
require 'timeout'

class Scripts
  def self.import_folder_no_metadata(folder)
    import_folder(folder, get_tags: false, calc_phash: false)
  end
  
  def self.import_folder(folder, start_idx: 0, i: -1, get_tags: true, calc_phash: true, total_count: nil, recurse: true, update_tags: false, logger: false)
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
			Item.import_file(path, update_tags: update_tags, get_tags: get_tags, calc_phash: calc_phash)
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
  
  def self.undirty_all(logger: false)
    set_logger(enabled: logger) do
      items = Item.where(dirty: true)
      count = items.count
      items.each_with_index do |item, idx|
        item.write_metadata
	if idx % 50 == 0
	  puts "#{idx}/#{count} (#{(100 * idx / count.to_f).round(1)}%)"
	end
      end
    end
  end
  
  def self.set_logger(enabled:, &blk)
    return blk.call if enabled || !ActiveRecord::Base.logger
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    result = blk.call
    ActiveRecord::Base.logger = old_logger
    result
  end
end
