# Media Organizer

## Screenshots

### Main Menu
<img src='https://github.com/MaxPleaner/MediaOrganizer/assets/5035719/5b136bb4-beb4-4960-a54d-d1072c602089' width='800px'/>

### Tag / Collection / Item view
<img src='https://github.com/MaxPleaner/MediaOrganizer/assets/5035719/b4d7d1c2-bdfc-4e7f-aada-5941ad628f9a' width='800px' />

---

## Overview

This is a web-based interface for organizing large amounts of media
(mainly intended images, though potentially applicable to other things).

Make no mistake, this is _no_ adobe lightroom. There are no photo manipulation tools here.
Rather, this is solely focused on organization via _tags_ (Exif metatadata keywords) and _collections_ (e.g. folders).

And specifically, it's built for those people (like myself) who do a _lot_
of image organizing and need to do it very efficiently. 

## How it works

This is a web server built in Sinatra, which is a framework for the Ruby language.
It's similar to Rails, but with _way_ less boilerplate.
It's sort of like Ruby's version of Express.js.

Anyway, the web server has a sqlite3 database which stores references to "Items" (e.g. images or other kinds of media).
The expectation is that the files are accessible by the web server for metadata reading/writing.
So, a self-hosting setup is perfect here. It's not currently set up for using remote storage sources, but it could be
accomplished with a bit of tweaking.

You bulk-import your content, and then use the web interface to set tags and collections.
Tags are intended to mirror the files' Exif metadata. For performance reasons this syncing doesn't actually happen
automatically, but the server does keep track of which items are "dirty" (e.g. which ones need syncing)
and there's a button which will write all the sqlite tag changes into the Exif data.

Collections are are a concept that only exists in the sqlite database; there is no support for actually moving
files around the drive right now.

## How to use it

1. Clone
2. install a recent version of Ruby (at the time of writing, that means some 3.x variant)
3. Install system deps: `exiftool`, `imagemagick`
3. Install ruby deps: `bundle install`
4. create the database: `bundle exec rake db:create`
5. create the tables: `bundle exec rake db:migrate`
6. Import your files
  a. First run `irb -r './server.rb'` to open a REPL
  b. Then run `Scripts.import_files("/path/to/folder")`
  c. This will take a while if you have a lot of media, but it will show you progress as it goes.
7. run the server (this will use port 9292): `rackup --host 0.0.0.0`

## Notes:

- There are keyboard shortcuts for navigating through items. Use `[` and `]` for previous and next, respectively.
- The import script will attempt to calculate the persistent hash ("phash") for each item. This can theoretically be used to detect duplicate images,
  though the app doesn't actually have any UI for this yet. If you don't care about this or encounter difficulties, pass the `calc_phash: false` option to the `Scripts.import_files` call.
- Both exif and metadata extraction are skipped for files greater than 50 MB.
- This was developed as a single-user application, e.g. for myself to organize my own image collection (self-hosting the application on a private network). As such, there is no authentication built in.
