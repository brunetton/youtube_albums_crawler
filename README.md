# Youtube albums crawler

## What is it ?

The aim of this project is:
  * to download and convert to mp3 full albums found in youtube, facebook or other sources handled by youtube-dl
  * to download all videos found in a text file, as mp3
  * to harmonize sound loudness between different sources (using [ffmpeg loudnorm audio filter](http://ffmpeg.org/ffmpeg-all.html#loudnorm))

It relays on the excellent [youtube-dl](https://rg3.github.io/youtube-dl/) and the non less excellent [avconv](https://libav.org/avconv.html).

It actually calls youtube-dl with a command line like this one:

    youtube-dl -f bestaudio --exec "ffmpeg -i {} -c:a mp3 -filter:a loudnorm=i=-18:lra=17 -qscale:a 2 {}.mp3 && rm {}" [url]

Where [url] is the given video url.

## Installation

### Debian

sudo aptitude install youtube-dl ffmpeg
sudo gem install docopt

### Arch Linux

pacman -S youtube-dl ffmpeg
sudo gem install docopt

## Usage

    youtube-crawler.rb <youtube_video_url>
    youtube-crawler.rb --from-file <filename> [--numbering]

  * `--from-file`   treat all youtube urls found in given text file (max one per line). Urls can be "hidden" in the middle of some text.
  * `--numbering`   add a number before each mp3 filenames. Ex: (ex: `01 - blabla-jYq1X_fJ9.mp3`)
  * use `--youtubedl-args "--yes-playlist"` if you want to download full playlist (if the youtube URL refers to a video and a playlist)

## TODO

  * automatic audio files cutting (silence detect) => will use external tool like [mp3splt](http://mp3splt.sourceforge.net/mp3splt_page/screenshots.php)
  * automatic resulting audio files naming and **tagging** (with the help of video description)

## Known bugs

  * Don't work when \`\ char in file title
