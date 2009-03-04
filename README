EZBoard Migrate
===============

This is a basic EZBoard scraping script that uses mechanize to spider a specified ezboard forum and download the forum/topic pages, scrape the html, and create users/topics/posts attempting to preserve original post metadata. Topic view/read counts are not currently preserved, but user creation time and post creation time are.

The script was written to migrate an ezboard forum into a custom rails-based forum. As such, it expects to be run from the environment of a Rails application, and uses ActiveRecord to write to database. However, it should be easy to modify to write to database directly, or even to plaintext.

Requirements
------------

* mechanize
* hpricot

Usage
-----
 
1. Place `ezboard_migrate.rb` in the `RAILS_ROOT/scripts` directory of your Rails app.
2. Ensure that you have a `migration_cache` directory under your `RAILS_ROOT/tmp` directory 
3. Edit `ezboard_migrate.rb` script to point to your forum url (should look something like http://p098.ezboard.com/bYOURFORUM)
4. Set `admin_user` and `admin_password` variables to those of an existing forum user, preferably an admin who has access to all subforums and topics.
5. Check that you have a User, Topic, Post, and Forum model set up in your Rails application. 
6. Run `script/ezboard_migrate.rb`.

Notes
-----

Scraped topic pages are cached in `RAILS_ROOT/tmp/migration_cache` directory in case you need to tweak the script or modify post parsing/cleanup code. If you see strange things going on with posts, or have markup you wish to clean up, just make your changes, wipe the database and re-run the script: it will re-download only new topics, or topics that have had replies since your last import attempt.

Once you're certain the data migrates successfully, lock down the ezboard forum to make sure that users do not post anything while you're migrating, and run the script one final time. Once all data is moved successfully, feel free to remove the `RAILS_ROOT/tmp/migration_cache` directory.

Database Models
---------------

The database models that the script tries to use have the following fields:

        Forum: name
        User: login, password, created_at
        Topic: title, created_at (related to user and forum)
        Post: body, craeted_at (related to forum, topic and user)

Version History
---------------
* 2009-03-03 - 0.1 - cleanup and initial public release

Warranty
--------
This script was written as a one-off. As such, I can promise that the code is messy, poorly documented, and full of ruby newbie mistakes. It works for me, but probably will require changes before it works for you. Please feel free to fork or incorporate it in your own projects. I am making it public in hopes that someone may find it useful when trying to migrate away from ezboard.