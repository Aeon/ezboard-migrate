#!/usr/bin/env ruby

# EZBoard migration script
# v 0.1
# 
# (c) 2008 Anton Stroganov <stroganov.a@gmail.com>
# aeontech.tumblr.com

# forum config:
forum_address = 'http://p098.ezboard.com/bbaymountaininstructors'
admin_user = 'USERNAME'
admin_password = 'PASSWORD'
# end config

require File.dirname(__FILE__) + '/../config/boot'

options = { :environment => (ENV['RAILS_ENV'] || "development").dup }
ENV["RAILS_ENV"] = options[:environment]
RAILS_ENV.replace(options[:environment]) if defined?(RAILS_ENV)
require RAILS_ROOT + '/config/environment'

match = s.match('^(http:\\/\/p[0-9]+\.ezboard\.com)\/b(.+)$')
unless match.nil?
  forum_host = match[1] # should be like 'http://p098.ezboard.com'
  forum_id = match[2] # should be like 'yourforumname'
  forum_url = forum_host + '/b' + forum_id
else
  print 'malformed forum url specified, expected form is http://SERVER.ezboard.com/bBOARD'
  exit
end

require 'rubygems'
require 'mechanize'
# puts File.expand_path File.dirname(__FILE__) + '/tmp/migration_cache/'
# exit
def get_or_create_user(username)
  u = User.find_by_login(username.gsub(/\s+/,''))
  if(!u)
    @agent.get(forum_url + '.showUserPublicProfile?gid='+username.gsub(/\s+/,''))
    puts 'creating ' + username
    u = User.new
    u.login = username.downcase.gsub(/\s+/,'')
    u.password = username.reverse
    if @agent.page.at('div[@id=membersince]')
      u.created_at = @agent.page.at('div[@id=membersince]').html.match(/[A-z]+ [0-9]{1,2}, [0-9]{4}/).to_s
    end
    u.save!
  end
  return u
end

posts_count = 0
topics_count = 0
skipped_posts = 0

@emoticons = [
  ['>D'       ,":grin:",      'http://www.ezboard.com/images/images/emoticons/grin.gif'], 
  ['0\]'      ,":alien:",     'http://www.ezboard.com/images/emoticons/alien.gif'], 
  ['8\)'      ,":glasses:",   'http://www.ezboard.com/images/emoticons/glasses.gif'],
  ['8o'       ,":nerd:",      'http://www.ezboard.com/images/emoticons/nerd.gif'],
  [':\('      ,":frown:",     'http://www.ezboard.com/images/emoticons/frown.gif'],
  [':\)'      ,":smile:",     'http://www.ezboard.com/images/emoticons/smile.gif'],
  [':b'       ,":tongue:",    'http://www.ezboard.com/images/emoticons/tongue.gif'],
  [':D'       ,":happy:",     'http://www.ezboard.com/images/emoticons/happy.gif'],
  [':eek'     ,":eek:",       'http://www.ezboard.com/images/emoticons/eek.gif'],
  [':evil'    ,":devil:",     'http://www.ezboard.com/images/emoticons/devil.gif'],
  [':hat'     ,":pimp:",     'http://www.ezboard.com/images/emoticons/pimp.gif'],
  [':lol'     ,":laugh:",     'http://www.ezboard.com/images/emoticons/laugh.gif'],
  [':o'       ,":embarassed:",'http://www.ezboard.com/images/emoticons/embarassed.gif'],
  [':p'       ,":tongue:",    'http://www.ezboard.com/images/emoticons/tongue.gif'],
  [':rolleyes',":eyes:",      'http://www.ezboard.com/images/emoticons/eyes.gif'],
  [':rollin'  ,".oO",         'http://www.ezboard.com/images/emoticons/roll.gif'],
  [':smokin'  ,"8-)",         'http://www.ezboard.com/images/emoticons/smokin.gif'],
  [':x'       ,":x",          'http://www.ezboard.com/images/emoticons/sick.gif'],
  [':\\'      ,":\\",         'http://www.ezboard.com/images/emoticons/ohwell.gif'],
  [':|'       ,":|",          'http://www.ezboard.com/images/emoticons/indifferent.gif'],
  [';\)'      ,";)",          'http://www.ezboard.com/images/emoticons/wink.gif'],
  ['>:'       ,">:x",         'http://www.ezboard.com/images/emoticons/mad.gif'],
  ['\\|I'     ,"._o",         'http://www.ezboard.com/images/emoticons/tired.gif']]

# @emoticons = {"http://www.ezboard.com/images/emoticons/grin.gif"=>">D","http://www.ezboard.com/images/emoticons/alien.gif"=>"0]","http://www.ezboard.com/images/emoticons/glasses.gif"=>"8)","http://www.ezboard.com/images/emoticons/nerd.gif"=>"8o","http://www.ezboard.com/images/emoticons/frown.gif"=>":(","http://www.ezboard.com/images/emoticons/smile.gif"=>":)","http://www.ezboard.com/images/emoticons/tongue.gif"=>":b","http://www.ezboard.com/images/emoticons/happy.gif"=>":D","http://www.ezboard.com/images/emoticons/eek.gif"=>"O.O","http://www.ezboard.com/images/emoticons/devil.gif"=>">:","http://www.ezboard.com/images/emoticons/pimp.gif"=>"=]:)","http://www.ezboard.com/images/emoticons/laugh.gif"=>":D","http://www.ezboard.com/images/emoticons/embarassed.gif"=>":o","http://www.ezboard.com/images/emoticons/tongue.gif"=>":p","http://www.ezboard.com/images/emoticons/eyes.gif"=>"<:","http://www.ezboard.com/images/emoticons/roll.gif"=>".oO","http://www.ezboard.com/images/emoticons/smokin.gif"=>"8-)","http://www.ezboard.com/images/emoticons/sick.gif"=>":x","http://www.ezboard.com/images/emoticons/ohwell.gif"=>":\\","http://www.ezboard.com/images/emoticons/indifferent.gif"=>":|","http://www.ezboard.com/images/emoticons/wink.gif"=>";)","http://www.ezboard.com/images/emoticons/mad.gif"=>">:x","http://www.ezboard.com/images/emoticons/tired.gif"=>"._o"}

# def convert_smileys(text)
#   for e in @emoticons
#     r = Regexp.new('<!--EZCODE EMOTICON START .+ --><img src="'+e[1]+'" alt=">:"\s+\/?><!--EZCODE EMOTICON END-->')
#     text.gsub!(r,' '+e[0]+' ')
#   end
#   # <!--EZCODE EMOTICON START :rollin --><img src=\"http://www.ezboard.com/images/emoticons/roll.gif\" alt=\":rollin\" /><!--EZCODE EMOTICON END--> 
#   # <!--EZCODE EMOTICON START >: --><img src=http://www.ezboard.com/images/emoticons/mad.gif ALT=">:"><!--EZCODE EMOTICON END-->
# end

@agent = WWW::Mechanize.new
@agent.user_agent_alias = 'Windows IE 6'

@agent.get(forum_host + '/BBSSystem.handleLoginCheck?action=login&boardName=' + forum_id + '&back=' + forum_id + '&language=EN')

@agent.post(forum_host + '/BBSUser.authorizeUser', [ ['language','EN'],['login',admin_user],['password',admin_password],['referer',forum_url]])

@agent.get(forum_url)

@forums = @agent.page.links.collect { |link| link.uri.to_s =~ /frm\d$/ ? [link.text,link.uri.to_s] : nil }.reject { |link| link == nil }

for remote_forum in @forums do
  @forum = Forum.find_by_name(remote_forum[0])
  if(!@forum)
    puts 'creating forum ' + remote_forum[0]
    @forum = Forum.new
    @forum.name = remote_forum[0]
    @forum.save!
  end
  
  @agent.get(remote_forum[1])

  # if !File.exists? File.dirname(__FILE__) + '/tmp/migration_cache/forum_' + Digest::SHA1.hexdigest(remote_forum[1]) + '_p1.html'
  #   f = File.new(File.dirname(__FILE__) + '/tmp/migration_cache/forum_' + Digest::SHA1.hexdigest(remote_forum[1]) + '_p1.html', "w")
  #   f.puts(@agent.get_file(remote_forum[1]))
  #   f.close
  #   puts 'put forum page in cache'
  # end
  
  # collect all pages
  @pages = @agent.page.links.collect { |link| link.uri.to_s =~ /page/ ? [link.text,link.uri.to_s] : nil }.reject { |link| link == nil }.uniq
  
  # collect all topics
  @topics = @agent.page.links.collect { |link| link.uri.to_s =~ /topicID=[0-9]+\.topic$/ ? [link.text.sub(/^\?/,'').strip,link.uri.to_s] : nil }.reject { |link| link == nil }.uniq
  
  @topic_archive = {}
  # figure out how many posts should be in each topic and store them...
  topic_rows = @agent.page.search("//table[3]/tr")
  topic_rows.shift # remove the header row
  topic_rows.each do |topic_row|
    # post link
    tlink = topic_row.search('/td[3]/a[@href]')[0].attributes['href']
    # post count for topic
    tpcount = topic_row.search('/td[4]').inner_html.to_i + 1
    unless tlink.nil? || tpcount.nil?
      @topic_archive[tlink] ||= tpcount
    end
    tlink = nil
    tpcount = nil
  end
  topic_rows = nil
  
  # collect all users
  @users = @agent.page.links.collect { |link| link.uri.to_s =~ /showUserPublicProfile/ ? [link.text,link.uri.to_s] : nil }.reject { |link| link == nil }.uniq
  
  for page in @pages do
    @agent.get(page[1])
    @topics += @agent.page.links.collect { |link| link.uri.to_s =~ /topicID=[0-9]+\.topic$/ ? [link.text.sub(/^\?/,'').strip,link.uri.to_s] : nil }.reject { |link| link == nil }
    @users += @agent.page.links.collect { |link| link.uri.to_s =~ /showUserPublicProfile/ ? [link.text,link.uri.to_s] : nil }.reject { |link| link == nil }.uniq
    
    # figure out how many posts should be in each topic and store them...
    topic_rows = @agent.page.search("//table[3]/tr")
    topic_rows.shift # remove the header row
    topic_rows.each do |topic_row|
      # post link
      tlink = topic_row.search('/td[3]/a[@href]')[0].attributes['href']
      # post count for topic
      tpcount = topic_row.search('/td[4]').inner_html.to_i + 1
      unless tlink.nil? || tpcount.nil?
        @topic_archive[tlink] ||= tpcount
      end
      tlink = nil
      tpcount = nil
    end
    topic_rows = nil
  end

  @users.uniq!

  @topics.uniq!

  puts 'creating users'
  # create users that don't exist yet
  for user in @users do
    get_or_create_user(user[0])
  end
    
  # create threads
  for topic in @topics do
    @agent.transact do
      # page = @agent.get(topic[1])
      if File.exists? File.dirname(__FILE__) + '/../tmp/migration_cache/' + Digest::SHA1.hexdigest(topic[1])
        @agent_page = File.open(File.dirname(__FILE__) + '/../tmp/migration_cache/' + Digest::SHA1.hexdigest(topic[1]), "r") { |f| Hpricot(f) }
      end
      if(!@agent_page)
        @agent.get(topic[1])
        @agent_page = @agent.page
        f = File.new(File.dirname(__FILE__) + '/../tmp/migration_cache/' + Digest::SHA1.hexdigest(topic[1]), "w")
        f.puts(@agent.get_file(topic[1]))
        f.close
        # puts 'put topic in cache'
      else
        # puts File.expand_path File.dirname(__FILE__) + '/tmp/migration_cache/' + Digest::SHA1.hexdigest(topic[1])
        # puts @page.to_s
        # puts 'read topic from cache'
      end
      puts 'creating topic ' + topic[0]

      # topic_pages = @agent_page.links.collect { |link| (link.uri.to_s =~ /showMessageRange/ && link.text =~ /^\d+$/) ? [link.text.sub(/^\?/,''),link.uri.to_s] : nil }.reject { |link| link == nil }.uniq
      topic_pages = @agent_page.search('a').collect { |link| (link[:href] =~ /showMessageRange/ && link.html =~ /^\d+$/) ? [link.html.sub(/^\?/,''),link[:href]] : nil }.reject { |link| link == nil }.uniq

      @messages_html = @agent_page.search("//tr[@bgcolor=#000000]")
      @messages = @messages_html.collect {|msg|
        # if a timestamp can be found (missing posts won't have timestamp)
        unless msg.search('td/span[3]').html.empty?
          {
            'author' => msg.search('td[1]/span[1]/').html.gsub(/<\/?[^>]*>/, '').gsub(/\s+/,''), 
            'date' =>  DateTime.strptime(msg.search('td/span[3]').html.match(/[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2} (am|pm)/).to_s + ' PST','%m/%d/%y %I:%M %p %Z').new_offset(0),
            'body'=> msg.search('td[@class=m]').inner_html.gsub(/^.+<hr size=\"1\" \/>\r\r/,'').gsub(/Edited by:.+(am|pm)/,'').strip
          }
        end
      }
      @agent_page = nil
      
      if topic_pages
        for tpage in topic_pages do
          # page = @agent.get(page[1])
          if File.exists? File.dirname(__FILE__) + '/../tmp/migration_cache/' + Digest::SHA1.hexdigest(tpage[1])
            @agent_page = File.open(File.dirname(__FILE__) + '/../tmp/migration_cache/' + Digest::SHA1.hexdigest(tpage[1]), "r") { |f| Hpricot(f) }
          end
          if(!@agent_page)
            @agent.get(tpage[1])
            @agent_page = @agent.page
            f = File.new(File.dirname(__FILE__) + '/../tmp/migration_cache/' + Digest::SHA1.hexdigest(tpage[1]), "w")
            f.puts(@agent.get_file(tpage[1]))
            f.close
            puts 'put topic subpage in cache'
          else
            puts 'read topic subpage from cache'
          end
          
          # @agent.get(page[1])
          @messages_html = @agent_page.search("//tr[@bgcolor=#000000]")
          @messages += @messages_html.collect {|msg|
            # if a timestamp can be found (missing posts won't have timestamp)
            unless msg.search('td/span[3]').html.empty?
              {
                'author' => msg.search('td[1]/span[1]/').html.gsub(/<\/?[^>]*>/, '').gsub(/\s+/,''), 
                'date' =>  DateTime.strptime(msg.search('td/span[3]').html.match(/[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2} (am|pm)/).to_s + ' PST','%m/%d/%y %I:%M %p %Z').new_offset(0), 
                'body'=> msg.search('td[@class=m]').inner_html.gsub(/^.+<hr size=\"1\" \/>\r\r/,'').gsub(/Edited by:.+(am|pm)/,'')
              }
            end
          }
        end
      end
      @agent_page = nil
      
      mesg_ct = @messages.size
      # skip any empty messages
      @messages.reject! {|msg| msg.nil? }

      unless @messages.empty?
        @messages.each { |msg|
          # replace smileys
          for e in @emoticons
            r = Regexp.new('<!--EZCODE EMOTICON START '+e[0]+' --><img src="'+e[2]+'" alt="[^"]+"\s+\/?><!--EZCODE EMOTICON END-->')
            msg['body'].gsub!(r,'!' + e[2].gsub(/http:\/\/www\.ezboard\.com/,'') +'!')
          end

          #clean up autolinks
          msg['body'].gsub!(/<!--EZCODE AUTOLINK START--><a href="(.+)">(.+)<\/a><!--EZCODE AUTOLINK END-->/) do |match| 
            url = $~[1].to_s;
            link = $~[2].to_s;
            '"'+link+'":'+url;
          end
        
          msg['body'].gsub!(/<\/?[^>]*>/, '').strip!
        }
      
        @messages.reject! { |m| m['body'].empty? }

        # if some posts got thrown away, count them.
        if mesg_ct > @messages.size
          skipped_posts = skipped_posts + ( mesg_ct - @messages.size )
        end
      
        if @messages.size > 0
          @topic  = @forum.topics.build({
              :title => topic[0],
              :forum => @forum,
            }
          )
          @topic.user = get_or_create_user(@messages[0]['author'])
          @topic.created_at = @messages[0]['date']
          @topic.save!
      
          for message in @messages do
            @post   = @topic.posts.build({
                :forum => @forum,
                :body => message['body']
              }
            )
            @post.topic = @topic
            @post.created_at = message['date']
            @post.user = get_or_create_user(message['author'])
            @post.save! 
            posts_count = posts_count + 1
          end
          topics_count = topics_count+1
        end
      else
        if mesg_ct > @messages.size
          skipped_posts = skipped_posts + ( mesg_ct - @messages.size )
        end
      end
    end
    if !@topic_archive[topic[1]].nil?
      if @topic_archive[topic[1]] != @messages.size
        print "GAHH!!! Topic " + topic[1] + " should have " + @topic_archive[topic[1]].to_s + " messages, but has " + @messages.size.to_s + "\n"
      end
    else
      print "GAHH!!! Topic " + topic[1] + " is unknown to science!\n"
    end
    total_posts = skipped_posts + posts_count;
    print "So far, #{posts_count} posts created in #{topics_count} topics (#{skipped_posts} posts skipped for being empty, so #{total_posts} posts processed)\n"
  end
  
  print "Forum done: " + @topic_archive.size.to_s + " topics expected, " + @topics.size.to_s + " topics found"
  for topic in @topics do
    @topic_archive[topic[1]] = nil
  end

  @topic_archive.reject! {|topic, posts| posts.nil? }
  if @topic_archive.size > 0
    print "The following topics were expected, but not converted:\n"
    @topic_archive.each do |link, posts|
        print "#{link} (#{posts} posts)\n"
    end
  end
end

print "In total, #{posts_count} posts created in #{topics_count} topics (#{skipped_posts} posts skipped for being empty, so #{total_posts} posts processed)\n"