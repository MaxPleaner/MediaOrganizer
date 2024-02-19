It's a media organizer built as a Sinatra web app.

It is not completely finished yet.

You can import content using `ENV IMPORT=true irb -r './server.rb` (check the bottom of `scripts.rb` file to configure which folder gets imported)

This builds a database of files including their EXIF keywords.

It currently lets you browse files and change their keywords.

In the future it will also support "collections" of content. 
