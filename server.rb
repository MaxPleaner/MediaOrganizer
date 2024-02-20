require 'sinatra'
require 'pry'
require './db/models.rb'
require './lib/scripts.rb'

configure :development do
    Sinatra::Application.reset!
end

get '/' do
  @tags = Tag.all.sort_by { |tag| tag.name.downcase }
  @collections = Collection.all.sort_by { |collection| collection.name.downcase }
  slim :index
end

get '/undirty_all' do
  Scripts.undirty_all
  redirect back
end

def standard_image_loader(collection, &blk)
  if params[:media_type].present?
    @media_type = params[:media_type]
    collection = collection.where(media_type: params[:media_type])
  end
  @count = collection.count
  if params[:random] == 'true'
    @idx = rand(@count.to_i)
    return redirect request.path + "?idx=#{@idx}&media_type=#{params[:media_type]}"
  else
    @idx = params[:idx].presence.to_i || 0
  end
  @item = collection.limit(1).offset(@idx).first
  if @item
    @tags = @item.tags
    @collections = @item.collections
  end
  blk.call
end

get '/untagged' do
  standard_image_loader(Item.left_outer_joins(:items_tags).where(items_tags: { id: nil })) do
    slim :untagged
  end
end

get '/no_collection' do
  standard_image_loader(Item.left_outer_joins(:items_collections).where(items_collections: { id: nil })) do
    slim :no_collection
  end
end

get '/all' do
  standard_image_loader(Item.all) do
    slim :all
  end
end

get '/tag/:name' do
  @tag = Tag.find_by_name(params[:name])
  standard_image_loader(@tag.items) do
    slim :tag
  end
end

get '/collection/:id' do
  @collection = Collection.find(params[:id])
  standard_image_loader(@collection.items) do
    slim :collection
  end
end

post '/bulk_modify_collection' do
  operation, source_type, source_id, collection_name = params.values_at(
    :operation, :source_type, :source_id, :collection
  )
  source_class = source_type == "tag" ? Tag : Collection
  source = source_class.find(source_id.to_i)
  collection = Collection.find_or_create_by(name: collection_name)
  source.items.each do |item|
    if operation == "add"
      item.items_collections.find_or_create_by(collection: collection)
    else
      item.items_collections.find_by(collection: collection)&.destroy
    end
  end
  if operation == "remove" && collection.items.none?
    collection.destroy
    if source == collection
      return redirect '/'
    end
  end
  redirect back
end

post '/bulk_modify_tag' do
  operation, source_type, source_id, tag_name = params.values_at(
    :operation, :source_type, :source_id, :tag
  )
  source_class = source_type == "tag" ? Tag : Collection
  source = source_class.find(source_id.to_i)
  tag = Tag.find_or_create_by(name: tag_name)
  source.items.each do |item|
    if operation == "add"
      item.items_tags.find_or_create_by(tag: tag)
    else
      item.items_tags.find_by(tag: tag)&.destroy
    end
  end
  if operation == "remove" && tag.items.none?
    tag.destroy
    if source == tag
      return redirect '/'
    end
  end
  redirect back
end

get '/item/:id' do
  @item = Item.find(params[:id])
  send_file @item.path
end

post '/item/:id/update' do
  @item = Item.find(params[:id])
  tag_names = params[:tags].split(" ").reject(&:blank?).map(&:strip)
  tags_changed = @item.tags.pluck(:name).sort != tag_names.sort

  if tags_changed
    tag_names.each do |tag_name|
      tag = Tag.find_or_create_by(name: tag_name)
      @item.tags += [tag] unless @item.items_tags.exists?(tag: tag)
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
    @item.update(dirty: true)
  end

  collection_names = params[:collections].split(" ").reject(&:blank?).map(&:strip)
  collection_names.each do |collection_name|
    collection = Collection.find_or_create_by(name: collection_name)
    @item.collections += [collection] unless @item.items_collections.exists?(collection: collection)
  end
  @item.collections.each do |collection|
    unless collection_names.include?(collection.name)
      @item.items_collections.find_by(collection: collection).destroy
      unless ItemsCollection.exists?(collection: collection)
        collection.destroy
      end
    end
  end
  
  if params[:from_tag].present? && !Tag.exists?(name: params[:from_tag])
    redirect '/'
  elsif params[:from_collection].present? && !Collection.exists?(id: params[:from_collection])
    redirect '/'
  else
    redirect back
  end
end
