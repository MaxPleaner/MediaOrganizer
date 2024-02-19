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
			Item.import_file(path, update_tags: update_tags, calc_phash: calc_phash)
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
      Item.where(dirty: true).each(&:write_metadata)
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
