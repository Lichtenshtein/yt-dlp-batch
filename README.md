# yt-dlp.cmd v1.9

A batch (cmd) file made to simplify the usage of yt-dlp on Windows.  

- Supports drag and droping for .url files and text files with links (one per line).  
- Can download a link from clipboard with default preset (change it for your needs).  
- Offers many built-in presets for Audio and Video (all is optional).  

Not that it's been tested very well... Suggestions for good presets are welcome.

## yt-dlp_nest_comments_fork.py and yt-dlp_nest_comments_new.py
Python scripts by [many](https://gist.github.com/tinyapps/df2b6757a142ff93caf9c63d0ef38b11) authors to prettify downloaded comments and make them readable.

## sed.commands
Text file with sed commands needed to make subtitles more readable.

## Requirements
-  sed, tr, truncate, head - Linux/Unix utils ported to Windows. [Included](https://github.com/git-for-windows/git) in git for Windows (you may choose PortableGit.7z variant in releases).
-  [moreutils-go](https://github.com/gabe565/moreutils-go) - because of 'ts' linux utility. Used for generating timestamps in standard input/output.
-  aria2c - to use as external downloader if needed. Choose version from [SourceForge](https://sourceforge.net/projects/aria2.mirror/) to avoid certificate files problem on Windows.  
-  [paste](https://gist.github.com/jpflouret/19da43372e643352a1bf) - to pipe contents of Windows clipboard. Download [here](https://gist.github.com/jpflouret/19da43372e643352a1bf#file-paste-zip).  
-  [Python](https://www.python.org/downloads/windows/) - to run .py scripts.  
-  [FFmpeg](https://github.com/AnimMouse/ffmpeg-stable-autobuild) - to merge video and audio files (and a lot more). A static nonfree build version (not gpl,lgpl).

Fill-in the settings (example).

![screenshot](img/img_01.png)

### Recommended Tools
- [yt-dlp-ReturnYoutubeDislike](https://github.com/pukkandan/yt-dlp-returnyoutubedislike) - A postprocessor plugin for Return YouTube Dislikes.
- [yt-autosub-srt-fix](https://github.com/jgoguen/srt_fix) - A plugin to fix double lines of YouTube subtitles.
- [yt-dlp-YTCustomChapters](https://github.com/bashonly/yt-dlp-YTCustomChapters) - Extractor plugin for using custom YouTube chapter lists.
- [yt-dlp-getpot-jsi](https://github.com/grqz/yt-dlp-getpot-jsi) - A plugin that attempts to generate POT. Provides some more [formats](https://github.com/yt-dlp/yt-dlp/wiki/PO-Token-Guide#current-po-token-enforcement) to choose from.
- [yt-dlp-replaygain](https://github.com/Eboreg/yt-dlp-replaygain) - Postprocessor plugin for audio volume normalization.
  - [rsgain](https://github.com/complexlogic/rsgain)
  - [AACGain](https://www.rarewares.org/aac-encoders.php#aacgain)
  - [VorbisGain](https://www.rarewares.org/ogg-tools.php#vorbisgain)
  - [MP3Gain](https://mp3gain.sourceforge.net/download.php)

## Screenshots

![screenshot](img/img_02.png)  
![screenshot](img/img_03.png)  
![screenshot](img/img_04.png)  
![screenshot](img/img_05.png)  
![screenshot](img/img_06.png)  
![screenshot](img/img_07.png)  
![screenshot](img/img_08.png)  
![screenshot](img/img_09.png)  
![screenshot](img/img_10.png)  

## Contribute
Feel free to fork and contribute if you wish.

## Questions

**- Can you code?**  
_- No_.  
**- Do you know batch?**  
_- No_.  
