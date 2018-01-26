#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require "docopt"

doc = <<DOCOPT
Usage:
#{__FILE__} <url>
#{__FILE__} --from-file <filename>

Convert given video link, or all video links found in given file to mp3, using youtube-dl and avconv.
Audio level normalized using loudnorm audio filter (http://ffmpeg.org/ffmpeg-all.html#loudnorm)

DOCOPT

YOUTUBE_LINK_REGEXP = /(https?:\/\/.*youtube.*\/watch\?v=([^#\&\?\s]+))/

def treat_url(url, video_id)

  def make_filename_complient(title)
    return title.gsub('/','-').gsub('`','\'')
  end

  # Open url
  page = Nokogiri::HTML(open(url))
  video_description = page.css('p[id="eow-description"]').inner_html.gsub('<br>', "\n")
  video_title = page.css('h1[class="watch-title-container"]').text.strip
  print "#{video_id}: #{video_title}\n\n#{video_description}\n\n"
  # Save text
  txt_filename = "#{make_filename_complient(video_title)}-#{video_id}"
  File.open(txt_filename + '.txt', 'w') { |file| file.write(video_description) }

  # Download file
  command = "youtube-dl \"#{url}\""
  puts "--> Running \"#{command}\""
  system(command)
  if $?.exitstatus != 0
      exit(-1)
  end

  # Convert to mp3
  video_file = Dir.glob("*#{video_id}*.*").find{|filename| not filename.end_with? '.txt'}  # Retreive file by video_id
  puts "\n\n--> Converting '#{video_file}' to mp3"
  mp3_filename = File.basename(make_filename_complient(video_file), '.*') + '.mp3'
  puts "'#{mp3_filename}'"
  command = "avconv -i \"#{video_file}\" -c:a mp3 -filter:a loudnorm=i=-10 -qscale:a 2 \"#{mp3_filename}\""
  puts "Running \"#{command}\""
  system(command)
  if $?.exitstatus != 0
      exit(-1)
  end

  # Check mp3 file exists and > 0
  if not (File.exist?(mp3_filename) and File.size(mp3_filename) > 0)
      abort("OOPS, mp3 file doesn't seems to be generated -> abording")
  end

  # remove video file
  File.delete(video_file)
end


begin
  args = Docopt::docopt(doc)
rescue Docopt::Exit => e
  puts e.message
  exit
end

if args['<url>']
  url = args['<url>']
  # Check youtube url
  if match = url.match(YOUTUBE_LINK_REGEXP)  # TODO: allow video ID
    url, video_id = match.captures
  else
    abort("\"#{url}\" is not a valid youtube url !")
  end
  treat_url(url, video_id)
  puts "\n\n--> End"
elsif args['<filename>']
  n_found = 0
  File.readlines(args['<filename>']).each do |line|
    if match = line.match(YOUTUBE_LINK_REGEXP)
      url, video_id = match.captures
      puts "\n\n***** #{url}\n"
      treat_url(url, video_id)
    end
  end
  puts "\n\nEnd\n#{n_found} files treated."
end
