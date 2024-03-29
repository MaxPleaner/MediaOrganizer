# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_02_19_202352) do
  create_table "collections", force: :cascade do |t|
    t.string "name"
  end

  create_table "items", force: :cascade do |t|
    t.string "path"
    t.text "phash"
    t.boolean "dirty", default: false
    t.string "media_type"
  end

  create_table "items_collections", force: :cascade do |t|
    t.integer "item_id"
    t.integer "collection_id"
    t.index ["collection_id"], name: "index_items_collections_on_collection_id"
    t.index ["item_id"], name: "index_items_collections_on_item_id"
  end

  create_table "items_tags", force: :cascade do |t|
    t.integer "item_id"
    t.integer "tag_id"
    t.index ["item_id"], name: "index_items_tags_on_item_id"
    t.index ["tag_id"], name: "index_items_tags_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
  end

end
