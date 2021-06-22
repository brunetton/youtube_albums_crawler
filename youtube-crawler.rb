#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require "docopt"

doc = <<DOCOPT
Usage:
#{__FILE__} <url>
#{__FILE__} --from-file <filename> [--numbering]

Options:
  --numbering        add a number at begining of mp3 files (ex: 01 - blabla.mp3)
  --metadata -m      (only if Youtube url) add a text file containing video description
  --youtubedl_args   custom additional Youtube-dl args

Convert given video link, or all video links found in given file to mp3, using youtube-dl and avconv.
Audio level normalized using loudnorm audio filter (http://ffmpeg.org/ffmpeg-all.html#loudnorm)

DOCOPT

YOUTUBE_LINK_REGEXP = /(https?:\/\/.*youtube.*\/watch\?v=([^#\&\?\s]+))/
YOUTUBEDL_DEFAULT_ARGS = "-f bestaudio --no-playlist --console-title"
FFMPEG_OPTIONS = "-c:a mp3 -filter:a loudnorm=i=-18:lra=17 -qscale:a 2"

def treat_url(url, audio_file_number=nil)

  def make_filename_complient(title)
    return title.gsub('/','-').gsub('`','\'')
  end

  # Check youtube url and extract parts (clean url and video id)
  if match = url.match(YOUTUBE_LINK_REGEXP)  # TODO: allow video ID
    url, video_id = match.captures
    if $args['metadata']
      # Open youtube link and get text informations
      page = Nokogiri::HTML(open(url))
      video_description = page.css('p[id="eow-description"]').inner_html.gsub('<br>', "\n")
      video_title = page.css('h1[class="watch-title-container"]').text.strip
      print "#{video_id}: #{video_title}\n\n#{video_description}\n\n"
      # Save text
      txt_filename = "#{make_filename_complient(video_title)}-#{video_id}"
      File.open(txt_filename + '.txt', 'w') { |file| file.write(video_description) }
    end
  end

  # Call youtube-dl to download sound
  youtubedl_args = YOUTUBEDL_DEFAULT_ARGS
  youtubedl_args += ' ' + $args['youtubedl_args'] if $args['youtubedl_args']
  command = "youtube-dl #{youtubedl_args} \"#{url}\""
  puts "--> Running \"#{command}\""
  system(command)
  if $?.exitstatus != 0
      exit(-1)
  end

  # Convert to mp3 and normalize audio
  ## Find the last file by date in directory
  input_file = Dir.glob("*").find_all{|filename| not filename.end_with? '.txt' and File.file?(filename) }.map{|filename| [filename, File.stat(filename).ctime]}.max_by{|e| e[1]}.first
  puts "\n\n--> Converting '#{input_file}' to mp3 and normalize audio loudness"
  number = audio_file_number ? "%02d - " % audio_file_number : ''
  mp3_filename = number + File.basename(make_filename_complient(input_file), '.*') + '.mp3'
  command = "ffmpeg -i \"#{input_file}\" #{FFMPEG_OPTIONS} \"#{mp3_filename}\""
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
  File.delete(input_file)
end


begin
  $args = Docopt::docopt(doc)
rescue Docopt::Exit => e
  puts e.message
  exit
end

if $args['<url>']
  url = $args['<url>']
  treat_url(url)
  puts "\n\n--> End"
elsif $args['<filename>']
  file_number = 0
  File.readlines($args['<filename>']).each do |line|
    if match = line.match(YOUTUBE_LINK_REGEXP)
      file_number += 1
      url = match.captures
      puts "\n\n***** #{url}\n"
      number = $args['--numbering'] ? file_number : nil
      treat_url(url, number)
    end
  end
  puts "\n\nEnd\n#{file_number} files treated."
end
