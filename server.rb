require 'sinatra'
require 'pry'
require './db/models.rb'
require './lib/scripts.rb'

configure :development do
    Sinatra::Application.reset!
end

get '/' do
  @tags = Tag.all.sort_by { |tag| tag.name.downcase }
  slim :index
end

def standard_image_loader(collection, &blk)
  @count = collection.count
  if params[:random] == 'true'
    @idx = rand(@count)
    return redirect request.path + "?idx=#{@idx}"
  else
    @idx = params[:idx].presence.to_i || 0
  end
  @item = collection.limit(1).offset(@idx).first
  @tags = @item.tags
  @collections = @item.collections
  blk.call
end

get '/untagged' do
  standard_image_loader(Item.left_outer_joins(:items_tags).where(items_tags: { id: nil })) do
    slim :untagged
  end
end

get '/all' do
  standard_image_loader(Item.all) do
    slim :all
  end
end

get '/gifs' do
  standard_image_loader(Item.where("path LIKE ?", "%.gif")) do
    slim :gifs
  end
end

get '/tag/:name' do
  @tag = Tag.find_by_name(params[:name])
  standard_image_loader(@tag.items) do
    slim :tag
  end
end

get '/item/:id' do
  @item = Item.find(params[:id])
  send_file @item.path
end

post '/item/:id/update' do
  @item = Item.find(params[:id])
  tag_names = params[:tags].split(" ").reject(&:blank?).map(&:strip)
  tag_names.each do |tag_name|
    tag = Tag.find_or_create_by(name: tag_name)
    @item.tags += [tag] unless @item.tags.exists?(name: tag_name)
  end
  ItemsTag.transaction do
    @item.tags.each do |tag|
      unless tag_names.include?(tag.name)
        @item.items_tags.find_by(tag: tag).destroy
        unless ItemsTag.exists?(tag: tag)
          tag.destroy
        end
      end
    end
  end
  @item.write_metadata
  collections = params[:collections].split("\n").reject(&:blank?).map(&:strip)
  if params[:from_tag].present? && !Tag.exists?(name: params[:from_tag])
    redirect '/'
  else
    redirect back
  end
end
