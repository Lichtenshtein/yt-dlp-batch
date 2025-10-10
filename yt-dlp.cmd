:: yt-dlp.cmd [url[.txt]] [...]
:: v0.1 2021/01/09 CirothUngol
:: https://www.reddit.com/r/youtubedl/comments/kws98p/simple_batchfile_for_using_youtubedlexe_with
::
:: for drag'n'drop function any combination of URLs
:: and text files may be used. text files are found 
:: and processed first, then all URLs.
::
:: v2.1 10.10.2025 Lichtenshtein

:: to convert comments to readable HTML python needs to be installed
:: then you may also need to install "pip install json2html"

:: recomended ffmpeg static build with nonfree codecs
:: https://github.com/AnimMouse/ffmpeg-stable-autobuild

@ECHO OFF

:: welcome to escaping hell. you think escaping a character 3 times might be enough?
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
:: endlocal

:: set terminal size (scrolling won't work without walkarouds)
:: MODE con: cols=120 lines=53
:: set the screen buffer size to enable scrolling (this is walkaroud for scrolling)
:: powershell -command "&{$H=get-host;$W=$H.ui.rawui;$B=$W.buffersize;$B.width=120;$B.height=9999;$W.buffersize=$B;}"
:: set terminal color, and codepage to unicode (65001=UTF-8)
color 0f
CHCP 65001 >NUL

:: set /F needs some spaces
for /f %%j in ('"prompt $H &echo on &for %%k in (1) do rem"') do set "BS=%%j"

:: color sets
FOR /F %%a in ('"prompt $E$S & echo on & FOR %%b in (1) DO rem"') DO SET "ESC=%%a"
:: STYLES
SET Underline=%ESC%[4m
SET Bold=%ESC%[1m
SET Inverse=%ESC%[7m
:: NORMAL FOREGROUND COLORS 
SET Black-n=%ESC%[30m
SET Red-n=%ESC%[31m
SET Green-n=%ESC%[32m
SET Yellow-n=%ESC%[33m
SET Blue-n=%ESC%[34m
SET Magenta-n=%ESC%[35m
SET Cyan-n=%ESC%[36m
SET White-n=%ESC%[37m
:: NORMAL BACKGROUND COLORS 
SET Black-n-b=%ESC%[40m
SET Red-n-b=%ESC%[41m
SET Green-n-b=%ESC%[42m
SET Yellow-n-b=%ESC%[43m
SET Blue-n-b=%ESC%[44m
SET Magenta-n-b=%ESC%[45m
SET Cyan-n-b=%ESC%[46m
SET White-n-b=%ESC%[47m
:: STRONG FOREGROUND COLORS 
SET Black-s=%ESC%[90m
SET Red-s=%ESC%[91m
SET Green-s=%ESC%[92m
SET Yellow-s=%ESC%[93m
SET Blue-s=%ESC%[94m
SET Magenta-s=%ESC%[95m
SET Cyan-s=%ESC%[96m
SET White-s=%ESC%[97m
:: STRONG FOREGROUND COLORS 
SET ColorOff=%ESC%[0m
:: example
:: ECHO An attempt to show a word as %Underline%yellow%ColorOff% color in a sentence...

:: temporary register exes required for plugins to system PATH
SET "PATH=%PATH%;B:\phantomjs;B:\rsgain;B:\aacgain;B:\vorbisgain;B:\mp3gain;"

:: set target folder and exe locations
SET       TARGET_FOLDER=F:\Temp
SET        YTDLP_FOLDER=D:\yt-dlp
SET        ARCHIVE_PATH=%YTDLP_FOLDER%\archive.txt
SET          YTDLP_PATH=%YTDLP_FOLDER%\yt-dlp.exe
SET        COOKIES_PATH=%YTDLP_FOLDER%\cookies.txt
SET            LOG_PATH=%TEMP%\yt-dlp-log.txt
SET         FFMPEG_PATH=D:\ffmpeg\ffmpeg.exe
SET         PYTHON_PATH=D:\Python313\python.exe
SET   AUDIO_PLAYER_PATH=D:\Aimp\Aimp.exe
SET   VIDEO_PLAYER_PATH=D:\PotPlayer\PotPlayerMini.exe
SET          ARIA2_PATH=D:\aria2c\aria2c.exe
SET            SED_PATH=D:\git-for-windows\usr\bin\sed.exe
SET             TR_PATH=D:\git-for-windows\usr\bin\tr.exe
SET           GREP_PATH=D:\git-for-windows\usr\bin\grep.exe
SET       TRUNCATE_PATH=D:\git-for-windows\usr\bin\truncate.exe
SET           HEAD_PATH=D:\git-for-windows\usr\bin\head.exe
SET          PASTE_PATH=D:\paste\paste.exe
SET      MOREUTILS_PATH=D:\moreutils-go\moreutils.exe
:: we will be getting clipboard content using Windows mshta instead of 'paste' which requiers .net 4. upd: nope.
REM SET           MSHTA=mshta "javascript:var x=clipboardData.getData('text');if(x) new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(x);close();"
REM SET  YTSUBCONVERTER=%YTDLP_FOLDER%\YTSubConverter.exe
:: set aria args
SET           ARIA_ARGS=--conf-path="D:\PortableApps\cmder\bin\aria2c\aria2.conf"
:: sed special commands file
SET        SED_COMMANDS=%YTDLP_FOLDER%\sed.txt
:: set yt-dlp common options
SET         SPEED_LIMIT=8096K
SET             THREADS=3
SET        THUMB_FORMAT=jpg
SET      THUMB_COMPRESS=3
SET           SUB_LANGS=ru,en,-live_chat
SET          SUB_FORMAT=srt/vtt/ass/best
SET          USER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0
SET     YTDLP_CACHE_DIR=%TEMP%\yt-dlp
SET    SPONSORBLOCK_OPT=sponsor,preview
:: set ffmpeg common options
SET FFMPEG_THUMB_FORMAT=mjpeg
SET       AUDIO_BITRATE=148
SET AUDIO_SAMPLING_RATE=44100
SET         VOLUME_GAIN=2
SET              CUTOFF=20000
SET   SILENCE_THRESHOLD=30
SET      FFMPEG_FILTERS=%YTDLP_FOLDER%\filters_complex.txt
:: i.e. http://proxy-ip:port; socks5://localhost:port
SET               PROXY=
:: default/never/two-letter ISO 3166-2 country code/IP block in CIDR notation
SET          GEO-BYPASS=1.138.171.50/24
:: plugins settings
SET		  CHAPTERS_PATH=%YTDLP_FOLDER%\chapters.txt
:: if defined will create folders for each text list entered
SET 	  MAKE_LIST_DIR=
:: capture errorlevel and display warning if non-zero for yt-dlp
SET             APP_ERR=%ERRORLEVEL%
:: finding out what aac encoders ffmpeg version supports
"%FFMPEG_PATH%" -encoders -hide_banner | "%GREP_PATH%" -wq "aac_at" >nul 2>&1
if %errorlevel% equ 0 (SET ENCODER=aac_at) ELSE (
"%FFMPEG_PATH%" -encoders -hide_banner | "%GREP_PATH%" -wq "libfdk_aac" >nul 2>&1
if %errorlevel% equ 0 (SET ENCODER=libfdk_aac) ELSE (SET ENCODER=aac))

:: set yt-dlp.exe commandline options, all options MUST begin with a space
:: name shorthand: %~d0=D:,%~p0=\path\to\,%~n0=name,%~x0=.ext,%~f0=%~dpnx0
:: remember to double percentage signs when used as output in batch files

::
::
:: DRAG AND DROP PRESET
::
::

:: DRAG AND DROP DEFAULT PRESET
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(title)s.%%(ext)s"
REM SET      Options= --ignore-errors --ignore-config
SET      Options= --ignore-config
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
SET  GeoRestrict= --xff "%GEO-BYPASS%"
SET       Select= --no-download-archive --compat-options no-youtube-unavailable-videos
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %THUMB_FORMAT% --postprocessor-args "ThumbnailsConvertor:-q:v %THUMB_COMPRESS%"
SET    Verbosity= --color always --console-title --progress --progress-template ["download] Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"
SET  WorkArounds=
SET       Format= --format "bestvideo[height<=480][ext=mp4]+bestaudio/best" -S "fps:30,channels:2"
SET     Subtitle= --sub-format "%SUB_FORMAT%" --sub-langs "%SUB_LANGS%" --compat-options no-live-chat
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --no-keep-video --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json

::
::
:: DRAG AND DROP LINKS TO BAT FUNCTIONS
::
::

:: capture commandline, add batch folder to path, create and enter target
SET source=%*
CALL SET "PATH=%~dp0;%%PATH:%~dp0;=%%"
MD "%TARGET_FOLDER%" >NUL 2>&1
PUSHD "%TARGET_FOLDER%"

:getURL-drag -- main loop
cls
:: if no drag and drop files - go to menu
if "%~1"=="" GOTO :getURL
:: prompt for source, exit if empty, call routines, loop
IF DEFINED Downloaded-Drag (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  COLLECTED ERRORS
ECHO ------------------------------------------------------------------------------------------------------------------------
FOR /f "delims=" %%j IN ('type "%LOG_PATH%"') DO ECHO %%j
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done. Press any key.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
IF EXIST "%LOG_PATH%" del /f /q "%LOG_PATH%" >nul 2>&1
)
IF NOT DEFINED source (
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=%BS%  %Green-n%›%ColorOff%  
)
IF NOT DEFINED source POPD & EXIT /B %APP_ERR%
CALL :getLST-drag %source%
CALL :doYTDL-drag %source%
SET source=
GOTO :getURL-drag

:getLST-drag url[.txt] [...]
:: if source <> file & 2nd paramer is empty then exit, else left-shift and loop
IF NOT EXIST "%~1" IF ""=="%~2" ( EXIT /B 0 ) ELSE SHIFT & GOTO :getLST-drag
:: remove file from source, display filename, call yt-dlp
CALL SET source=%%source:%1=%%
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  Fetching URLs from %1
ECHO ------------------------------------------------------------------------------------------------------------------------
:: create new target using list.txt filename and enter new target
IF DEFINED MAKE_LIST_DIR MD "%TARGET_FOLDER%\%~n1" >NUL 2>&1
IF DEFINED MAKE_LIST_DIR PUSHD "%TARGET_FOLDER%\%~n1"
:: clean a .URL file from innapropriate lines 
:: drag link from browser to disk to download .URL
"%SED_PATH%" -i -e '/InternetShortcut/d';'s/URL=//g';'s/^&.*//' %1 >nul 2>&1
REM "%TRUNCATE_PATH%" -s -1 %1 >NUL 2>&1
"%TR_PATH%" -d "\n" %1 >NUL 2>&1
FOR /F "usebackq tokens=*" %%A IN ("%~1") DO CALL :doYTDL-drag "%%~A"
:: return to target folder, left-shift parameters, and loop
IF DEFINED MAKE_LIST_DIR POPD
SHIFT
GOTO :getLST-drag


:getURL
SET temp_file1=%TEMP%\clipboard.txt
SET temp_file2=%TEMP%\clipboard2.txt
:: get clipboard content to file
"%PASTE_PATH%" > "%temp_file1%"
:: find out if clipboard content is a link
findstr /R "^.https://.* ^https://.*" "%temp_file1%" >nul 2>&1
if %errorlevel% equ 0 (SET YAY=1) ELSE (SET YAY=)
:: if true try deleting double quotes because script will crash before it even starts
:: delete & and everything after (may break links). mostly ok for youtube
:: sed is a capricious but useful piece of stinky shit (at least here on windows)
:: delete spaces, delete new lines, delete newline symbol that sed brings every time
:: copy everything back to clipboard, and finally set a 'clipboard' variable that is finally settable
:: 12 hours of guessing what was (and still) ruining all the echo formating here and there (color, etc). no clue
IF DEFINED YAY (
"%SED_PATH%" -e 's/^&.*//';'s/\"//g';'s/\"$//g';'s/[ \t]*$//' "%temp_file1%" > "%temp_file2%"
REM "%TRUNCATE_PATH%" -s -1 "%temp_file1%"
"%TR_PATH%" -d "\n" < "%temp_file2%" > "%temp_file1%"
type "%TEMP%\clipboard.txt" | clip
SET /p clipboard=<"%TEMP%\clipboard.txt"
IF EXIST "%temp_file1%" del /f /q "%temp_file1%" >nul 2>&1
IF EXIST "%temp_file2%" del /f /q "%temp_file2%" >nul 2>&1
)
IF "%YAY%"=="1" (
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE URL ^(or enter "q" to quick-download URL from clipboard; "a" for quick-download audio^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=%BS%  %Green-n%›%ColorOff%  
IF NOT DEFINED URL EXIT /B %APP_ERR%
IF "!URL!"=="q" (SET URL=!clipboard!& GOTO :doYTDL-quick) ELSE (
IF "!URL!"=="a" (SET URL=!clipboard!& GOTO :doYTDL-preset-quick) ELSE (GOTO :start))
) ELSE (
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE URL
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=%BS%  %Green-n%›%ColorOff%  
IF NOT DEFINED URL EXIT /B %APP_ERR%
GOTO :start)

:start
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  MENU
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Download Audio
ECHO   %Cyan-s%2%ColorOff%. Download Video
ECHO   %Cyan-s%3%ColorOff%. Download From List
ECHO   %Cyan-s%4%ColorOff%. Download Manually
ECHO   %Cyan-s%5%ColorOff%. Download Subtitles Only
ECHO   %Cyan-s%6%ColorOff%. Download Comments Only
ECHO   %Cyan-s%7%ColorOff%. Stream To Player
ECHO   %Cyan-s%8%ColorOff%. Sections / Chapters Splitter
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%e%ColorOff%. Enter URL	%Yellow-s%v%ColorOff%. Version Info
ECHO   %Yellow-s%s%ColorOff%. Settings	%Yellow-s%c%ColorOff%. Extractor Descriptions
ECHO   %Yellow-s%u%ColorOff%. Update	%Yellow-s%x%ColorOff%. Error Info
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Enter your choice: 
IF "%choice%"=="1" GOTO :select-format-audio
IF "%choice%"=="2" GOTO :select-format-video
IF "%choice%"=="3" GOTO :select-download-list
IF "%choice%"=="4" GOTO :select-format-manual
IF "%choice%"=="5" GOTO :select-preset-subs
IF "%choice%"=="6" GOTO :select-preset-comments
IF "%choice%"=="7" GOTO :select-format-stream
IF "%choice%"=="8" GOTO :select-preset-sections
IF "%choice%"=="e" GOTO :getURL-re-enter
IF "%choice%"=="s" GOTO :settings
IF "%choice%"=="u" GOTO :update
IF "%choice%"=="v" GOTO :info
IF "%choice%"=="c" GOTO :extractors
IF "%choice%"=="x" GOTO :error-info
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :start

:extractors
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  EXTRACTORS INFO
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%" --extractor-descriptions
ECHO.
IF %APP_ERR% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Cyan-s%%APP_ERR%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Press any key to continue
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :start

:getURL-re-enter
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE URL
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=%BS%  %Green-n%›%ColorOff%  
IF NOT DEFINED URL EXIT /B %APP_ERR%
IF "%Downloaded-Audio%"=="1" (
GOTO :continue
) ELSE (IF "%Downloaded-Video%"=="1" (
GOTO :continue
) ELSE (IF "%Downloaded-Manual%"=="1" (
GOTO :continue
) ELSE (IF "%Downloaded-Manual-Single%"=="1" (
GOTO :continue
) ELSE (IF "%Downloaded-Comments%"=="1" (
GOTO :continue
) ELSE (IF "%Downloaded-Subs%"=="1" (
GOTO :continue
) ELSE (IF "%Downloaded-Stream%"=="1" (
GOTO :continue
) ELSE (IF "%Downloaded-Sections%"=="1" (
GOTO :continue
) ELSE (IF "%Downloaded-Quick%"=="1" (
GOTO :continue
) ELSE (
GOTO :start
)))))))))

:settings
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  SETTINGS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Set Cookies
ECHO   %Cyan-s%2%ColorOff%. Set Downloader
ECHO   %Cyan-s%3%ColorOff%. Set Plugins
ECHO   %Cyan-s%4%ColorOff%. Set Geo-Bypass
ECHO   %Cyan-s%5%ColorOff%. Set Proxy
ECHO   %Cyan-s%6%ColorOff%. Set Duration Filter
ECHO   %Cyan-s%7%ColorOff%. Set Date Filter
ECHO   %Cyan-s%8%ColorOff%. Set Behaviour On Errors
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Enter your choice: 
IF "%choice%"=="1" GOTO :cookies
IF "%choice%"=="2" GOTO :aria
IF "%choice%"=="3" GOTO :plugins
IF "%choice%"=="4" GOTO :geo-bypass
IF "%choice%"=="5" GOTO :proxy
IF "%choice%"=="6" GOTO :set-duration-filter
IF "%choice%"=="7" GOTO :set-date-filter
IF "%choice%"=="8" GOTO :playlist-error
IF "%choice%"=="w" GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :settings


:select-download-list
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  DOWNLOAD FROM TEXT LIST
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Audio List
ECHO   %Cyan-s%2%ColorOff%. Audio List + Crop Thumbnail
ECHO   %Cyan-s%3%ColorOff%. Audio List + Crop Thumbnail + Only New
ECHO   %Cyan-s%4%ColorOff%. Audio List + Crop Thumbnail + Interpret Title As "Artist - Title"
ECHO   %Cyan-s%5%ColorOff%. Audio List + Crop Thumbnail + Interpret Title As "Artist - Title" + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%6%ColorOff%. Video List
ECHO   %Cyan-s%7%ColorOff%. Video List + Crop Thumbnail
ECHO   %Cyan-s%8%ColorOff%. Video List + Crop Thumbnail + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select preset: 
IF "%choice%"=="1" SET DownloadList=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :select-format-audio) ELSE (GOTO :select-format-audio)
IF "%choice%"=="2" SET DownloadList=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :select-format-audio) ELSE (GOTO :select-format-audio)
IF "%choice%"=="3" SET DownloadList=1& SET CropThumb=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :select-format-audio) ELSE (GOTO :select-format-audio)
IF "%choice%"=="4" SET DownloadList=1& SET CropThumb=1& SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :select-format-audio) ELSE (GOTO :select-format-audio)
IF "%choice%"=="5" SET DownloadList=1& SET CropThumb=1& SET FormatTitle=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :select-format-audio) ELSE (GOTO :select-format-audio)
IF "%choice%"=="6" SET DownloadList=1& GOTO :select-format-video
IF "%choice%"=="7" SET DownloadList=1& SET CropThumb=1& GOTO :select-format-video
IF "%choice%"=="8" SET DownloadList=1& SET CropThumb=1& SET OnlyNew=1& GOTO :select-format-video
IF "%choice%"=="w" GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-download-list



:playlist-error
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  Number of allowed failures until the rest of the playlist is skipped
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. After 1 Error
ECHO   %Cyan-s%2%ColorOff%. After 2 Errors
ECHO   %Cyan-s%3%ColorOff%. After 3 Errors
ECHO   %Cyan-s%4%ColorOff%. After 4 Errors
ECHO   %Cyan-s%5%ColorOff%. After 5 Errors
ECHO   %Cyan-s%6%ColorOff%. After 6 Errors
ECHO   %Cyan-s%7%ColorOff%. After 7 Errors
ECHO   %Cyan-s%8%ColorOff%. After 8 Errors
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-n%a%ColorOff%. Abort ANY Further Downloading On Error
ECHO   %Yellow-n%r%ColorOff%. Do NOT Stop On Errors
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Enter your choice: 
IF "%choice%"=="1" SET stop_on_error=1& GOTO :settings
IF "%choice%"=="2" SET stop_on_error=2& GOTO :settings
IF "%choice%"=="3" SET stop_on_error=3& GOTO :settings
IF "%choice%"=="4" SET stop_on_error=4& GOTO :settings
IF "%choice%"=="5" SET stop_on_error=5& GOTO :settings
IF "%choice%"=="6" SET stop_on_error=6& GOTO :settings
IF "%choice%"=="7" SET stop_on_error=7& GOTO :settings
IF "%choice%"=="8" SET stop_on_error=8& GOTO :settings
IF "%choice%"=="a" SET stop_on_error=9& GOTO :settings
IF "%choice%"=="r" SET stop_on_error=& GOTO :settings
IF "%choice%"=="w" GOTO :settings
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :playlist-error

:aria
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ARIA DOWNLOADER
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Yes
ECHO   %Cyan-s%2%ColorOff%. No
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p usearia=%BS%  Use aria2c as external downloader? 
IF "%usearia%"=="1" GOTO :settings
IF "!usearia!"=="2" SET !usearia!=& GOTO :settings
IF "%usearia%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :aria

:cookies
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  COOKIES
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Yes
ECHO   %Cyan-s%2%ColorOff%. No
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p usecookies=%BS%  Use cookies.txt? 
IF "%usecookies%"=="1" GOTO :settings
IF "!usecookies!"=="2" SET !usecookies!=& GOTO :settings
IF "%usecookies%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :cookies

:plugins
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  PLUGINS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Use SRT_fix
ECHO   %Cyan-s%2%ColorOff%. Use ReplayGain
ECHO   %Cyan-s%3%ColorOff%. Use CustomChapters
ECHO   %Cyan-s%4%ColorOff%. Use ReturnYoutubeDislike
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Which Plugin to Enable? 
IF "%choice%"=="1" GOTO :plugin-1
IF "%choice%"=="2" GOTO :plugin-2
IF "%choice%"=="3" GOTO :plugin-3
IF "%choice%"=="4" GOTO :plugin-4
IF "%choice%"=="w" GOTO :settings
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :plugins

:plugin-1
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  SRT_fixer
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Yes
ECHO   %Cyan-s%2%ColorOff%. No
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p use_pl_srtfixer=%BS%  Enable SRT_fixer plugin? 
IF "%use_pl_srtfixer%"=="1" GOTO :plugins
IF "!use_pl_srtfixer!"=="2" SET !use_pl_srtfixer!=& GOTO :plugins
IF "%use_pl_srtfixer%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :plugin-1

:plugin-2
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ReplayGain
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Yes
ECHO   %Cyan-s%2%ColorOff%. No
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p use_pl_replaygain=%BS%  Enable ReplayGain plugin? 
IF "%use_pl_replaygain%"=="1" GOTO :plugins
IF "!use_pl_replaygain!"=="2" SET !use_pl_replaygain!=& GOTO :plugins
IF "%use_pl_replaygain%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :plugin-2

:plugin-3
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  CustomChapters
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Yes
ECHO   %Cyan-s%2%ColorOff%. No
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p use_pl_customchapters=%BS%  Enable CustomChapters plugin? 
IF "%use_pl_customchapters%"=="1" GOTO :plugins
IF "!use_pl_customchapters!"=="2" SET !use_pl_customchapters!=& GOTO :plugins
IF "%use_pl_customchapters%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :plugin-3

:plugin-4
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ReturnYoutubeDislike
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Yes
ECHO   %Cyan-s%2%ColorOff%. No
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p use_pl_returnyoutubedislike=%BS%  Enable ReturnYoutubeDislike plugin? 
IF "%use_pl_returnyoutubedislike%"=="1" GOTO :plugins
IF "!use_pl_returnyoutubedislike!"=="2" SET !use_pl_returnyoutubedislike!=& GOTO :plugins
IF "%use_pl_returnyoutubedislike%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :plugin-4

:info
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  VERSION INFO
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%" -v
ECHO.
IF %APP_ERR% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Cyan-s%%APP_ERR%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Press any key to continue
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :start

:error-info
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  YT-DLP ERROR INFO
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   0  No error
ECHO   1  Invalid url/Missing file
ECHO   2  No arguments/Invalid parameters
ECHO   3  File I/O error
ECHO   4  Network failure
ECHO   5  SSL verification failure
ECHO   6  Username/Password failure
ECHO   7  Protocol errors
ECHO   8  Server issued an error response
ECHO  403 Bot protection/Need to set cookies
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Press any key to continue
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :start

:update
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  UPDATING...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%" -U
ECHO.
IF %APP_ERR% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Cyan-s%%APP_ERR%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff% Press any key to continue.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :start

:continue
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  CONTINUE DOWNLOAD
ECHO ------------------------------------------------------------------------------------------------------------------------
:: meant for download another link with same params
ECHO   %Cyan-s%1%ColorOff%. New URL ^(same parameters^)
:: meant to retry failed download with same params (in case if link is invalid)
ECHO   %Cyan-s%2%ColorOff%. Retry ^(same parameters^)
ECHO ------------------------------------------------------------------------------------------------------------------------
:: re-enter link to retry the download
ECHO   %Yellow-s%e%ColorOff%. Re-Enter URL
:: resets all variables
ECHO   %Yellow-s%r%ColorOff%. Main Menu
:: this seems useless here, params won't change from within this menu
REM ECHO   %Yellow-s%w%ColorOff%. Set Downloader
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Continue? 
IF "%choice%"=="1" GOTO :getURL-continue
IF "%choice%"=="2" (IF "%Downloaded-Audio%"=="1" (
GOTO :doYTDL
) ELSE (IF "%Downloaded-Video%"=="1" (
GOTO :doYTDL
) ELSE (IF "%Downloaded-Manual%"=="1" (
GOTO :download-manual
) ELSE (IF "%Downloaded-Manual-Single%"=="1" (
GOTO :download-manual-single
) ELSE (IF "%Downloaded-Comments%"=="1" (
GOTO :doYTDL
) ELSE (IF "%Downloaded-Subs%"=="1" (
GOTO :doYTDL
) ELSE (IF "%Downloaded-Stream%"=="1" (
GOTO :doYTDL-stream
) ELSE (IF "%Downloaded-Sections%"=="1" (
GOTO :doYTDL-sections
) ELSE (IF "%Downloaded-Quick%"=="1" (
GOTO :doYTDL-quick
) ELSE (
ECHO   %Red-s%•%ColorOff%  Nothing to Retry. & GOTO :continue
))))))))))
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="e" GOTO :getURL-re-enter
REM IF "%choice%"=="w" GOTO :aria
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :continue

:getURL-continue
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE URL
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=%BS%  %Green-n%›%ColorOff%  
IF NOT DEFINED URL EXIT /B %APP_ERR%
IF "%Downloaded-Audio%"=="1" (
GOTO :doYTDL
) ELSE (IF "%Downloaded-Video%"=="1" (
GOTO :doYTDL
) ELSE (IF "%Downloaded-Manual%"=="1" (
GOTO :download-manual
) ELSE (IF "%Downloaded-Manual-Single%"=="1" (
GOTO :download-manual-single
) ELSE (IF "%Downloaded-Comments%"=="1" (
GOTO :doYTDL
) ELSE (IF "%Downloaded-Subs%"=="1" (
GOTO :doYTDL
) ELSE (IF "%Downloaded-Stream%"=="1" (
GOTO :doYTDL-stream
) ELSE (IF "%Downloaded-Sections%"=="1" (
GOTO :select-preset-sections
) ELSE (IF "%Downloaded-Quick%"=="1" (
GOTO :doYTDL-quick
) ELSE (
GOTO :start
)))))))))

:exit
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%•%ColorOff%  See Ya, Space Cowboy...
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
EXIT /B 0

::
::
:: CUSTOM MENU PART
::
::

:select-format-manual
cls
SET Downloaded-Manual=& SET Downloaded-Manual-Single=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  FETCHING URL...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%" --list-formats --no-playlist --simulate --ffmpeg-location "%FFMPEG_PATH%" "%URL%"
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
)
GOTO :selection

:selection
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Video + Audio		%Yellow-s%w%ColorOff%. Go Back
ECHO   %Cyan-s%2%ColorOff%. Audio Only / Video Only	%Red-s%q%ColorOff%. Exit
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P choice=%BS%  Select Option: 
IF "%choice%"=="1" GOTO :selection-manual
IF "%choice%"=="2" GOTO :selection-manual-single
IF "%choice%"=="w" GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :selection

:selection-manual
SET /P video=%BS%  Select Video Format: 
SET /P audio=%BS%  Select Audio Format: 
GOTO :download-manual

:download-manual
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%" --concurrent-fragments %THREADS% --ffmpeg-location "%FFMPEG_PATH%" --output "%TARGET_FOLDER%\%%(title)s.%%(ext)s" -f "%video%+%audio%" -i --ignore-config%Download% "%URL%"
IF %APP_ERR% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Cyan-s%%APP_ERR%%ColorOff%.
IF "%APP_ERR%"=="1" ECHO   %Red-s%•%ColorOff%  Try re-entering correct format. & GOTO :selection-manual
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=1& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Stream=& SET Downloaded-Sections=& SET Downloaded-Quick=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done. Press any key.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :continue

:selection-manual-single
SET /P format=%BS%  Select Format: 
GOTO :download-manual-single

:download-manual-single
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%" --concurrent-fragments %THREADS% --ffmpeg-location "%FFMPEG_PATH%" --output "%TARGET_FOLDER%\%%(title)s.%%(ext)s" -f "%format%" -i --ignore-config%Download% "%URL%"
IF %APP_ERR% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Cyan-s%%APP_ERR%%ColorOff%.
IF "%APP_ERR%"=="1" ECHO   %Red-s%•%ColorOff%  Try re-entering correct format. & GOTO :selection-manual-single
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=1& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Stream=& SET Downloaded-Sections=& SET Downloaded-Quick=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done. Press any key.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :continue

::
::
:: AUDIO MENU PART
::
::

:select-format-audio
SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-opus=& SET CustomFormat-ogg=& SET CustomFormatAudio=& SET BestAudio=
SET Downloaded-Audio=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO FORMAT
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Extract Best	%Cyan-s%11%ColorOff%. Extract opus ^(from dash^)
ECHO   %Cyan-s%2%ColorOff%. Extract opus 	%Cyan-s%12%ColorOff%. Extract opus ^(up to 4.0^)
ECHO   %Cyan-s%3%ColorOff%. Extract mp4a	%Cyan-s%13%ColorOff%. Extract opus ^(up to 4.0^) + ^(downmix to 2.0/%AUDIO_BITRATE%k/filter^)
ECHO   %Cyan-s%4%ColorOff%. Extract vorbis	%Cyan-s%14%ColorOff%. Extract mp4a ^(up to 5.1^)
"%FFMPEG_PATH%" -encoders -hide_banner | "%GREP_PATH%" -wq "libfdk_aac" >nul 2>&1
if %errorlevel% equ 0 (
ECHO   %Cyan-s%5%ColorOff%. Extract mp3     	%Cyan-s%15%ColorOff%. Extract mp4a ^(up to 5.1^) + ^(downmix to 2.0/VBR/filter^)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%6%ColorOff%. Convert → m4a	%Cyan-s%16%ColorOff%. Convert → m4a ^(fraunhofer_aac/VBR^)
ECHO   %Cyan-s%7%ColorOff%. Convert → mp3	%Cyan-s%17%ColorOff%. Convert → m4a ^(fraunhofer_aac/VBR/filter^)
) ELSE (
ECHO   %Cyan-s%5%ColorOff%. Extract mp3
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%6%ColorOff%. Convert → m4a
ECHO   %Cyan-s%7%ColorOff%. Convert → mp3
)
"%FFMPEG_PATH%" -encoders -hide_banner | "%GREP_PATH%" -wq "aac_at" >nul 2>&1
if %errorlevel% equ 0 (
ECHO   %Cyan-s%8%ColorOff%. Convert → opus	%Cyan-s%18%ColorOff%. Convert → m4a ^(apple_aac^)
ECHO   %Cyan-s%9%ColorOff%. Convert → aac	%Cyan-s%19%ColorOff%. Convert → m4a ^(apple_aac/filter^)
ECHO  %Cyan-s%10%ColorOff%. Convert → ogg	%Cyan-s%20%ColorOff%. Convert → m4a ^(apple_aac^) + ^(downmix to 2.0/filter^)
) ELSE (
ECHO   %Cyan-s%8%ColorOff%. Convert → opus
ECHO   %Cyan-s%9%ColorOff%. Convert → aac
ECHO  %Cyan-s%10%ColorOff%. Convert → ogg
)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select audio format: 
IF "%choice%"=="1" SET CustomFormatAudio=1& SET BestAudio=1& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="2" SET CustomFormatAudio=1& SET CustomFormat-opus=1& SET AudioFormat=opus& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="3" SET CustomFormatAudio=1& SET CustomFormat-m4a=1& SET AudioFormat=m4a& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="4" SET CustomFormatAudio=1& SET CustomFormat-ogg=1& SET AudioFormat=vorbis& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="5" SET CustomFormatAudio=1& SET CustomFormat-mp3=1& SET AudioFormat=mp3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="6" SET AudioFormat=m4a& GOTO :select-quality-audio
IF "%choice%"=="7" SET AudioFormat=mp3& GOTO :select-quality-audio
IF "%choice%"=="8" SET AudioFormat=opus& GOTO :select-quality-audio
IF "%choice%"=="9" SET AudioFormat=aac& GOTO :select-quality-audio
IF "%choice%"=="10" SET AudioFormat=vorbis& GOTO :select-quality-audio
IF "%choice%"=="11" SET CustomFormatAudio=1& SET CustomFormat-opus=4& SET AudioFormat=opus& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="12" SET CustomFormatAudio=1& SET CustomFormat-opus=2& SET AudioFormat=opus& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="13" SET CustomFormatAudio=1& SET CustomFormat-opus=3& SET AudioFormat=opus& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="14" SET CustomFormatAudio=1& SET CustomFormat-m4a=3& SET AudioFormat=m4a& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="15" SET CustomFormat-m4a=5& SET AudioFormat=m4a& GOTO :select-quality-vbr-audio
IF "%choice%"=="16" SET CustomFormat-m4a=2& SET AudioFormat=m4a& GOTO :select-quality-vbr-audio
IF "%choice%"=="17" SET CustomFormat-m4a=4& SET AudioFormat=m4a& GOTO :select-quality-vbr-audio
IF "%choice%"=="18" SET CustomFormat-m4a=6& SET AudioFormat=m4a& GOTO :select-quality-vbr-at-audio
IF "%choice%"=="19" SET CustomFormat-m4a=7& SET AudioFormat=m4a& GOTO :select-quality-vbr-at-audio
IF "%choice%"=="20" SET CustomFormat-m4a=8& SET AudioFormat=m4a& GOTO :select-quality-vbr-at-audio
IF "%choice%"=="w" IF "%SectionsAudio%"=="1" (GOTO :select-preset-sections) ELSE (IF "%SectionsAudio%"=="2" (GOTO :select-preset-sections) ELSE (IF "%DownloadList%"=="1" (GOTO :select-download-list) ELSE (GOTO :start)))
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-format-audio

:select-quality-audio
SET quality_libfdk=& SET quality_simple=& SET quality_aac_at=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%1%ColorOff%. Quality 0 ^(~220-260 Kbps/VBR^)
) ELSE (
ECHO   %Cyan-s%1%ColorOff%. Quality 1
)
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%2%ColorOff%. Quality 2 ^(~170-210 Kbps/VBR^)
) ELSE (
ECHO   %Cyan-s%2%ColorOff%. Quality 2
)
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%3%ColorOff%. Quality 3 ^(~150-195 Kbps/VBR^)
) ELSE (
ECHO   %Cyan-s%3%ColorOff%. Quality 3
)
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%4%ColorOff%. Quality 4 ^(~140-185 Kbps/VBR^)
) ELSE (
ECHO   %Cyan-s%4%ColorOff%. Quality 4
)
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%5%ColorOff%. Quality 5 ^(~120-150 Kbps/VBR^) ^(default^) 
) ELSE (
ECHO   %Cyan-s%5%ColorOff%. Quality 5 ^(default^)
)
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%6%ColorOff%. Quality 6 ^(~100-130 Kbps/VBR^)
) ELSE (
ECHO   %Cyan-s%6%ColorOff%. Quality 6
)
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%7%ColorOff%. Quality 7 ^(~80-120 Kbps/VBR^)
) ELSE (IF "%AudioFormat%"=="m4a" (
ECHO   %Cyan-s%7%ColorOff%. Quality 7 ^(~204-216 Kbps^) ^(optimal^) 
) ELSE (
ECHO   %Cyan-s%7%ColorOff%. Quality 7
))
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%8%ColorOff%. Quality 8 ^(~70-105 Kbps/VBR^)
) ELSE (
ECHO   %Cyan-s%8%ColorOff%. Quality 8
)
IF "%AudioFormat%"=="mp3" (
ECHO   %Cyan-s%9%ColorOff%. Quality 9 ^(~45-85 Kbps/VBR^)
) ELSE (
ECHO   %Cyan-s%9%ColorOff%. Quality 9
)
ECHO  %Cyan-s%10%ColorOff%. Quality 10 ^(worst, smaller^)
ECHO ------------------------------------------------------------------------------------------------------------------------
IF "%AudioFormat%"=="mp3" (
ECHO  %Cyan-s%11%ColorOff%. Quality 320k ^(320 Kbps/CBR^)
) ELSE (
ECHO  %Cyan-s%11%ColorOff%. Quality 0 ^(best, overkill^)
)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select audio quality: 
IF "%choice%"=="1" SET quality_simple=1& SET AudioQuality=1& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="2" SET quality_simple=1& SET AudioQuality=2& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="3" SET quality_simple=1& SET AudioQuality=3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="4" SET quality_simple=1& SET AudioQuality=4& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="5" SET quality_simple=1& SET AudioQuality=5& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="6" SET quality_simple=1& SET AudioQuality=6& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="7" SET quality_simple=1& SET AudioQuality=7& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="8" SET quality_simple=1& SET AudioQuality=8& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="9" SET quality_simple=1& SET AudioQuality=9& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="10" SET quality_simple=1& SET AudioQuality=10& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="11" IF "%AudioFormat%"=="mp3" (SET quality_simple=1& SET AudioQuality=320k& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))) ELSE (SET quality_simple=1& SET AudioQuality=0& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio))))
IF "%choice%"=="w" GOTO :select-format-audio
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-quality-audio

:select-quality-vbr-audio
SET quality_libfdk=& SET quality_simple=& SET quality_aac_at=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  FRAUNHOFER AAC ENCODER QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Quality 1 ^(~40-62 Kbps) ^(worst^)
ECHO   %Cyan-s%2%ColorOff%. Quality 2 ^(~64-80 Kbps^)
ECHO   %Cyan-s%3%ColorOff%. Quality 3 ^(~96-112 Kbps^)
ECHO   %Cyan-s%4%ColorOff%. Quality 4 ^(~128-144 Kbps^)
ECHO   %Cyan-s%5%ColorOff%. Quality 5 ^(~192-224 Kbps^) ^(best^)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%6%ColorOff%. Quality 0 ^(disables VBR, enables CBR^)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select audio quality: 
IF "%choice%"=="1" SET quality_libfdk=1& SET AudioQuality=1& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="2" SET quality_libfdk=1& SET AudioQuality=2& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="3" SET quality_libfdk=1& SET AudioQuality=3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="4" SET quality_libfdk=1& SET AudioQuality=4& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="5" SET quality_libfdk=1& SET AudioQuality=5& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="6" SET quality_libfdk=1& SET AudioQuality=0& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="w" GOTO :select-format-audio
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
:select-quality-vbr-audio

:select-quality-vbr-at-audio
SET quality_libfdk=& SET quality_simple=& SET quality_aac_at=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  APPLE AAC ENCODER QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   ^|          VBR          ^|	^|        CVBR         ^|  	^|         ABR         ^|
ECHO   -------------------------  	-----------------------     	-----------------------
ECHO   %Cyan-s%01%ColorOff%. Quality 0 ^(~320 Kbps^)	%Cyan-s%16%ColorOff%. Quality 256k ^(CVBR^)		%Cyan-s%28%ColorOff%. Quality 256k  ^(ABR^)
ECHO   %Cyan-s%02%ColorOff%. Quality 1			%Cyan-s%17%ColorOff%. Quality 224k ^(CVBR^)		%Cyan-s%29%ColorOff%. Quality 224k  ^(ABR^)
ECHO   %Cyan-s%03%ColorOff%. Quality 2 ^(~256 Kbps^)	%Cyan-s%18%ColorOff%. Quality 202k ^(CVBR^)		%Cyan-s%30%ColorOff%. Quality 202k  ^(ABR^)
ECHO   %Cyan-s%04%ColorOff%. Quality 3 ^(~214 Kbps^)	%Cyan-s%19%ColorOff%. Quality 182k ^(CVBR^)		%Cyan-s%31%ColorOff%. Quality 182k  ^(ABR^)
ECHO   %Cyan-s%05%ColorOff%. Quality 4 ^(~192 Kbps^)	%Cyan-s%20%ColorOff%. Quality 148k ^(CVBR^)		%Cyan-s%32%ColorOff%. Quality 148k  ^(ABR^)
ECHO   %Cyan-s%06%ColorOff%. Quality 5 ^(~160 Kbps^)	%Cyan-s%21%ColorOff%. Quality 128k ^(CVBR^)		%Cyan-s%33%ColorOff%. Quality 128k  ^(ABR^)
ECHO   %Cyan-s%07%ColorOff%. Quality 6 ^(~144 Kbps^)	-----------------------		-----------------------
ECHO   %Cyan-s%08%ColorOff%. Quality 7 ^(~128 Kbps^)	^|         CBR         ^|		^|        HE-AAC       ^|
ECHO   %Cyan-s%09%ColorOff%. Quality 8			-----------------------  	-----------------------  
ECHO   %Cyan-s%10%ColorOff%. Quality 9 ^(~96 Kbps^)	%Cyan-s%22%ColorOff%. Quality 256k  ^(CBR^)		%Cyan-s%34%ColorOff%. High Efficiency AAC
ECHO   %Cyan-s%11%ColorOff%. Quality 10		%Cyan-s%23%ColorOff%. Quality 224k  ^(CBR^)   	-----------------------
ECHO   %Cyan-s%12%ColorOff%. Quality 11		%Cyan-s%24%ColorOff%. Quality 202k  ^(CBR^)   	^|      HE-AAC_v2      ^|
ECHO   %Cyan-s%13%ColorOff%. Quality 12		%Cyan-s%25%ColorOff%. Quality 182k  ^(CBR^)		-----------------------  
ECHO   %Cyan-s%14%ColorOff%. Quality 13		%Cyan-s%26%ColorOff%. Quality 148k  ^(CBR^)		%Cyan-s%35%ColorOff%. High Efficiency AAC
ECHO   %Cyan-s%15%ColorOff%. Quality 14 ^(worst^)   	%Cyan-s%27%ColorOff%. Quality 128k  ^(CBR^)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select audio quality: 
IF "%choice%"=="1" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=0& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="2" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=1& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="3" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=2& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="4" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=3& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="5" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=4& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="6" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=5& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="7" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=6& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="8" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=7& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="9" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=8& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="10" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=9& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="11" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=10& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="12" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=11& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="13" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=12& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="14" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=13& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="15" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-q:a& SET aac-at-param-3=14& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=vbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="16" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=256k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cvbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="17" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=224k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cvbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="18" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=202k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cvbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="19" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=182k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cvbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="20" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=148k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cvbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="21" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=128k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cvbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="22" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=256k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="23" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=224k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="24" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=202k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="25" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=182k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="26" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=148k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="27" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=128k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=cbr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="28" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=256k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=abr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="29" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=224k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=abr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="30" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=202k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=abr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="31" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=182k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=abr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="32" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=148k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=abr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="33" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-b:a& SET aac-at-param-3=128k& SET aac-at-param-4=-aac_at_mode& SET aac-at-param-5=abr& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="34" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-profile:a& SET aac-at-param-3=4& SET aac-at-param-4=& SET aac-at-param-5=& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="35" SET quality_aac_at=1& SET aac-at-param-1=-aac_at_quality 0& SET aac-at-param-2=-profile:a& SET aac-at-param-3=28& SET aac-at-param-4=& SET aac-at-param-5=& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-audio-preset-2) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="w" GOTO :select-format-audio
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
:select-quality-vbr-at-audio

:select-preset-audio
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO PRESETS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Audio Single / Channel				%Cyan-s%12%ColorOff%. Audio Single + Only New
ECHO   %Cyan-s%2%ColorOff%. Audio Single + Crop Thumbnail			%Cyan-s%13%ColorOff%. Audio Single + Crop Thumbnail + Only New
ECHO   %Cyan-s%3%ColorOff%. Audio Single + Title as "Artist - Title"		%Cyan-s%14%ColorOff%. Audio Single + Title as "Artist - Title" + Only New
ECHO   %Cyan-s%4%ColorOff%. Audio Single + Crop + Title as "Artist - Title"	%Cyan-s%15%ColorOff%. Audio Single + Crop + Title as "Artist - Title" + Only New
ECHO   %Cyan-s%5%ColorOff%. Audio Single + 10 Top Comments			%Cyan-s%16%ColorOff%. Audio Single + Crop Thumbnail + 10 Top Comments
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%6%ColorOff%. Audio Album / Release				%Cyan-s%17%ColorOff%. Audio Album + Only New
ECHO   %Cyan-s%7%ColorOff%. Audio Album + Crop Thumbnail			%Cyan-s%18%ColorOff%. Audio Album + Crop Thumbnail + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%8%ColorOff%. Audio Playlist					%Cyan-s%19%ColorOff%. Audio Playlist + Only New
ECHO   %Cyan-s%9%ColorOff%. Audio Playlist + Crop Thumbnail			%Cyan-s%20%ColorOff%. Audio Playlist + Crop Thumbnail + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO  %Cyan-s%10%ColorOff%. Audio Playlist / Various Artists			%Cyan-s%21%ColorOff%. Audio Playlist / Various Artists + Only New
ECHO  %Cyan-s%11%ColorOff%. Audio Playlist / Various Artists + Crop Thumbnail	%Cyan-s%22%ColorOff%. Audio Playlist / Various Artists + Crop + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Choose preset: 
IF "%choice%"=="1" IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="2" SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="3" SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="4" SET CropThumb=1& SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="5" SET CommentPreset=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="6" SET Downloaded-Playlist=1& SET Album=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="7" SET Downloaded-Playlist=1& SET Album=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="8" SET Downloaded-Playlist=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="9" SET Downloaded-Playlist=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="10" SET Downloaded-Playlist=1& SET VariousArtists=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=3& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="11" SET Downloaded-Playlist=1& SET VariousArtists=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=3& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="12" SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="13" SET OnlyNew=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="14" SET OnlyNew=1& SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="15" SET OnlyNew=1& SET CropThumb=1& SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="16" SET CommentPreset=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="17" SET Downloaded-Playlist=1& SET Album=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="18" SET Downloaded-Playlist=1& SET Album=1& SET CropThumb=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="19" SET Downloaded-Playlist=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="20" SET Downloaded-Playlist=1& SET CropThumb=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="21" SET Downloaded-Playlist=1& SET VariousArtists=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=3& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="22" SET Downloaded-Playlist=1& SET VariousArtists=1& SET CropThumb=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=3& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="w" IF "%CustomFormatAudio%"=="1" (GOTO :select-format-audio) ELSE (IF "%quality_libfdk%"=="1" (GOTO :select-quality-vbr-audio) ELSE (GOTO :select-quality-audio))
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-preset-audio

::
::
:: VIDEO MENU PART
::
::

:select-format-video
SET CustomFormatVideo=& SET Downloaded-Video=& SET VideoResolution=& SET VideoFPS=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  VIDEO QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Best Video
ECHO   %Cyan-s%2%ColorOff%. 1440p/%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%3%ColorOff%. 1440p/30fps
ECHO   %Cyan-s%4%ColorOff%. 1280p/%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%5%ColorOff%. 1280p/30fps
ECHO   %Cyan-s%6%ColorOff%. 1080p/%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%7%ColorOff%. 1080p/30fps
ECHO   %Cyan-s%8%ColorOff%. 720p/%Red-s%60%ColorOff%fps 
ECHO   %Cyan-s%9%ColorOff%. 720p/30fps 
ECHO  %Cyan-s%10%ColorOff%. 480p/30fps
ECHO  %Cyan-s%11%ColorOff%. 320p/30fps
ECHO  %Cyan-s%12%ColorOff%. Worst Video		
ECHO  %Cyan-s%13%ColorOff%. Smallest Size	
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select video quality: 
IF "%choice%"=="1" SET CustomFormatVideo=1& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-video-preset-2) ELSE (GOTO :select-preset-video)))
IF "%choice%"=="2" SET VideoResolution=1440& SET VideoFPS=60& GOTO :select-codec-video
IF "%choice%"=="3" SET VideoResolution=1440& SET VideoFPS=30& GOTO :select-codec-video
IF "%choice%"=="4" SET VideoResolution=1280& SET VideoFPS=60& GOTO :select-codec-video
IF "%choice%"=="5" SET VideoResolution=1280& SET VideoFPS=30& GOTO :select-codec-video
IF "%choice%"=="6" SET VideoResolution=1080& SET VideoFPS=60& GOTO :select-codec-video
IF "%choice%"=="7" SET VideoResolution=1080& SET VideoFPS=30& GOTO :select-codec-video
IF "%choice%"=="8" SET VideoResolution=720& SET VideoFPS=60& GOTO :select-codec-video
IF "%choice%"=="9" SET VideoResolution=720& SET VideoFPS=30& GOTO :select-codec-video
IF "%choice%"=="10" SET VideoResolution=480& SET VideoFPS=30& GOTO :select-codec-video
IF "%choice%"=="11" SET VideoResolution=320& SET VideoFPS=30& GOTO :select-codec-video
IF "%choice%"=="12" SET CustomFormatVideo=2& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-video-preset-2) ELSE (GOTO :select-preset-video)))
IF "%choice%"=="13" SET CustomFormatVideo=3& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-video-preset-2) ELSE (GOTO :select-preset-video)))
IF "%choice%"=="w"  IF "%SectionsVideo%"=="1" (GOTO :select-preset-sections) ELSE (IF "%SectionsVideo%"=="2" (GOTO :select-preset-sections) ELSE (IF "%DownloadList%"=="1" (GOTO :select-download-list) ELSE (GOTO :start)))
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-format-video

:select-codec-video
SET CustomCodec=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  VIDEO CODEC
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Any
ECHO   %Cyan-s%2%ColorOff%. AVC
ECHO   %Cyan-s%3%ColorOff%. VP9
ECHO   %Cyan-s%4%ColorOff%. AV1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select a codec: 
IF "%choice%"=="1" SET CustomCodec=any& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-video-preset-2) ELSE (GOTO :select-preset-video)))
IF "%choice%"=="2" SET CustomCodec=avc& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-video-preset-2) ELSE (GOTO :select-preset-video)))
IF "%choice%"=="3" SET CustomCodec=vp9& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-video-preset-2) ELSE (GOTO :select-preset-video)))
IF "%choice%"=="4" SET CustomCodec=av1& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (IF "%DownloadList%"=="1" (GOTO :doYTDL-video-preset-2) ELSE (GOTO :select-preset-video)))
IF "%choice%"=="w" GOTO :select-format-video
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
:select-codec-video

:select-preset-video
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  VIDEO PRESETS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Video Single / Channel				 %Cyan-s%7%ColorOff%. Video Single + Crop Thumbnail
ECHO   %Cyan-s%2%ColorOff%. Video Single + Top Comments			 %Cyan-s%8%ColorOff%. Video Single + Top Comments + Crop Thumbnail
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%3%ColorOff%. Video Playlist					 %Cyan-s%9%ColorOff%. Video Playlist + Only New
ECHO   %Cyan-s%4%ColorOff%. Video Playlist + Crop Thumbnail			%Cyan-s%10%ColorOff%. Video Playlist + Crop Thumbnail + Only New
ECHO   %Cyan-s%5%ColorOff%. Video Playlist + Top Comments			%Cyan-s%11%ColorOff%. Video Playlist + Top Comments + Only New
ECHO   %Cyan-s%6%ColorOff%. Video Playlist + Top Comments + Crop Thumbnail	%Cyan-s%12%ColorOff%. Video Playlist + Top Comments + Crop + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Choose preset: 
IF "%choice%"=="1" GOTO :doYTDL-video-preset-2
IF "%choice%"=="2" SET CommentPreset=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="3" SET Downloaded-Playlist=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="4" SET Downloaded-Playlist=1& SET CropThumb=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="5" SET Downloaded-Playlist=1& SET Downloaded-Playlist=1& SET CommentPreset=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="6" SET Downloaded-Playlist=1& SET CommentPreset=1& SET CropThumb=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="7" SET CropThumb=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="8" SET CommentPreset=1& SET CropThumb=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="9" SET Downloaded-Playlist=1& SET OnlyNew=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="10" SET Downloaded-Playlist=1& SET OnlyNew=1& SET CropThumb=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="11" SET Downloaded-Playlist=1& SET CommentPreset=1& SET OnlyNew=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="12" SET Downloaded-Playlist=1& SET CommentPreset=1& SET OnlyNew=1& SET CropThumb=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="w" GOTO :select-format-video
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-preset-video

::
::
:: SUBS MENU PART
::
::

:select-preset-subs
cls
SET Downloaded-Subs=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  SUBTITLES
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Download Subtitles
ECHO   %Cyan-s%2%ColorOff%. Download Transcript
IF "%use_pl_srtfixer%"=="1" (
ECHO   %Cyan-s%3%ColorOff%. Download Autosubs + SRT_fix
ECHO ------------------------------------------------------------------------------------------------------------------------
) ELSE (
ECHO ------------------------------------------------------------------------------------------------------------------------
)
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Choose option: 
IF "%choice%"=="1" SET SubsPreset=1& GOTO :subs-preset-1
IF "%choice%"=="2" SET SubsPreset=2& GOTO :subs-preset-1
IF "%choice%"=="3" SET SubsPreset=3& GOTO :subs-preset-1
IF "%choice%"=="w" GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-preset-subs

::
::
:: COMMENTS MENU PART
::
::

:select-preset-comments
cls
SET Downloaded-Comments=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  COMMENTS DOWNLOAD
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%.   25 Comments Sorted By TOP
ECHO   %Cyan-s%2%ColorOff%.   25 Comments Sorted By TOP And Converted To HTML
ECHO   %Cyan-s%3%ColorOff%.  500 Comments Sorted By TOP
ECHO   %Cyan-s%4%ColorOff%.  500 Comments Sorted By TOP And Converted To HTML
ECHO   %Cyan-s%5%ColorOff%.  ALL Comments Sorted By TOP
ECHO   %Cyan-s%6%ColorOff%.  ALL Comments Sorted By TOP And Converted To HTML
ECHO   %Cyan-s%7%ColorOff%.   25 Comments Sorted By NEW
ECHO   %Cyan-s%8%ColorOff%.   25 Comments Sorted By NEW And Converted To HTML
ECHO   %Cyan-s%9%ColorOff%.  500 Comments Sorted By NEW
ECHO  %Cyan-s%10%ColorOff%.  500 Comments Sorted By NEW And Converted To HTML	%Cyan-s%13%ColorOff%.  500 Comments Converted To HTML + Sorted By NEW
ECHO  %Cyan-s%11%ColorOff%.  ALL Comments Sorted By NEW
ECHO  %Cyan-s%12%ColorOff%.  ALL Comments Sorted By NEW And Converted To HTML
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Choose option: 
IF "%choice%"=="1" SET CommentPreset=1& GOTO :comments-preset-1
IF "%choice%"=="2" SET CommentPreset=2& GOTO :comments-preset-1
IF "%choice%"=="3" SET CommentPreset=3& GOTO :comments-preset-1
IF "%choice%"=="4" SET CommentPreset=4& GOTO :comments-preset-1
IF "%choice%"=="5" SET CommentPreset=5& GOTO :comments-preset-1
IF "%choice%"=="6" SET CommentPreset=6& GOTO :comments-preset-1
IF "%choice%"=="7" SET CommentPreset=7& GOTO :comments-preset-1
IF "%choice%"=="8" SET CommentPreset=8& GOTO :comments-preset-1
IF "%choice%"=="9" SET CommentPreset=9& GOTO :comments-preset-1
IF "%choice%"=="10" SET CommentPreset=10& GOTO :comments-preset-1
IF "%choice%"=="11" SET CommentPreset=11& GOTO :comments-preset-1
IF "%choice%"=="12" SET CommentPreset=12& GOTO :comments-preset-1
IF "%choice%"=="13" SET CommentPreset=13& GOTO :comments-preset-1
IF "%choice%"=="w" GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-preset-comments

::
::
:: STREAM MENU PART
::
::

:select-format-stream
cls
SET Downloaded-Stream=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  STREAM TO PLAYER
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Stream Audio
ECHO   %Cyan-s%2%ColorOff%. Stream Video
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Choose option: 
IF "%choice%"=="1" GOTO :select-quality-audio-stream
IF "%choice%"=="2" GOTO :select-quality-video-stream
IF "%choice%"=="w" GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-format-stream

:select-quality-audio-stream
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  STREAM AUDIO QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Best Audio
ECHO   %Cyan-s%2%ColorOff%. Best Audio + Best Protocol
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Enter your choice: 
IF "%choice%"=="1" SET StreamVideoFormat=& SET StreamAudioFormat=1& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="2" SET StreamVideoFormat=& SET StreamAudioFormat=2& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="w" GOTO :select-format-stream
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-quality-audio-stream

:select-quality-video-stream
SET VideoResolution=& SET VideoFPS=& SET StreamVideoFormat=& SET StreamAudioFormat=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  STREAM VIDEO QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Best Video
ECHO   %Cyan-s%2%ColorOff%. 1440p/%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%3%ColorOff%. 1440p/30fps
ECHO   %Cyan-s%4%ColorOff%. 1280p/%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%5%ColorOff%. 1280p/30fps
ECHO   %Cyan-s%6%ColorOff%. 1080p/%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%7%ColorOff%. 1080p/30fps
ECHO   %Cyan-s%8%ColorOff%. 720p/%Red-s%60%ColorOff%fps 
ECHO   %Cyan-s%9%ColorOff%. 720p/30fps 
ECHO  %Cyan-s%10%ColorOff%. 480p/30fps
ECHO  %Cyan-s%11%ColorOff%. 320p/30fps
ECHO  %Cyan-s%12%ColorOff%. Worst Video		
ECHO  %Cyan-s%13%ColorOff%. Smallest Size	
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Enter your choice: 
IF "%choice%"=="1" SET StreamAudioFormat=& SET StreamVideoFormat=1& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="2" SET StreamAudioFormat=& SET VideoResolution=1440& SET VideoFPS=60& GOTO :select-codec-video-stream
IF "%choice%"=="3" SET StreamAudioFormat=& SET VideoResolution=1440& SET VideoFPS=30& GOTO :select-codec-video-stream
IF "%choice%"=="4" SET StreamAudioFormat=& SET VideoResolution=1280& SET VideoFPS=60& GOTO :select-codec-video-stream
IF "%choice%"=="5" SET StreamAudioFormat=& SET VideoResolution=1280& SET VideoFPS=30& GOTO :select-codec-video-stream
IF "%choice%"=="6" SET StreamAudioFormat=& SET VideoResolution=1080& SET VideoFPS=60& GOTO :select-codec-video-stream
IF "%choice%"=="7" SET StreamAudioFormat=& SET VideoResolution=1080& SET VideoFPS=30& GOTO :select-codec-video-stream
IF "%choice%"=="8" SET StreamAudioFormat=& SET VideoResolution=720& SET VideoFPS=60& GOTO :select-codec-video-stream
IF "%choice%"=="9" SET StreamAudioFormat=& SET VideoResolution=720& SET VideoFPS=30& GOTO :select-codec-video-stream
IF "%choice%"=="10" SET StreamAudioFormat=& SET VideoResolution=480& SET VideoFPS=30& GOTO :select-codec-video-stream
IF "%choice%"=="11" SET StreamAudioFormat=& SET VideoResolution=320& SET VideoFPS=30& GOTO :select-codec-video-stream
IF "%choice%"=="12" SET StreamAudioFormat=& SET StreamVideoFormat=2& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="13" SET StreamAudioFormat=& SET StreamVideoFormat=3& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="w" GOTO :select-format-stream
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-quality-video-stream

:select-codec-video-stream
SET StreamVideoFormat=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  VIDEO CODEC
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Any
ECHO   %Cyan-s%2%ColorOff%. AVC
ECHO   %Cyan-s%3%ColorOff%. VP9
ECHO   %Cyan-s%4%ColorOff%. AV1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select a codec: 
IF "%choice%"=="1" SET StreamVideoFormat=4& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="2" SET StreamVideoFormat=5& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="3" SET StreamVideoFormat=6& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="4" SET StreamVideoFormat=7& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="w" GOTO :select-quality-video-stream
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
:select-codec-video-stream

::
::
:: SECTIONS MENU PART
::
::

:select-preset-sections
SET Downloaded-Sections=& SET SectionsAudio=& SET SectionsVideo=& SET CropThumb=& SET CustomChapters=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  SECTION DOWNLOAD PRESETS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Audio Sections			     %Cyan-s%5%ColorOff%. Audio Sections + Crop Thumbnail
ECHO   %Cyan-s%2%ColorOff%. Video Sections			     %Cyan-s%6%ColorOff%. Video Sections + Crop Thumbnail
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%3%ColorOff%. Audio + Split By Chapters		     %Cyan-s%7%ColorOff%. Audio + Split By Chapters + Crop Thumbnail
ECHO   %Cyan-s%4%ColorOff%. Video + Split By Chapters		     %Cyan-s%8%ColorOff%. Video + Split By Chapters + Crop Thumbnail
IF "%use_pl_customchapters%"=="1" (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%9%ColorOff%. Audio + Split By Custom Chapters	    %Cyan-s%11%ColorOff%. Audio + Split By Custom Chapters + Crop Thumbnail
ECHO  %Cyan-s%10%ColorOff%. Video + Split By Custom Chapters	    %Cyan-s%12%ColorOff%. Video + Split By Custom Chapters + Crop Thumbnail
ECHO ------------------------------------------------------------------------------------------------------------------------
) ELSE (
ECHO ------------------------------------------------------------------------------------------------------------------------
)
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select preset: 
IF "%choice%"=="1" SET SectionsAudio=1& GOTO :select-format-audio
IF "%choice%"=="2" SET SectionsVideo=1& GOTO :select-format-video
IF "%choice%"=="3" SET SectionsAudio=2& GOTO :select-format-audio
IF "%choice%"=="4" SET SectionsVideo=2& GOTO :select-format-video
IF "%choice%"=="5" SET SectionsAudio=1& SET CropThumb=1& GOTO :select-format-audio
IF "%choice%"=="6" SET SectionsVideo=1& SET CropThumb=1& GOTO :select-format-video
IF "%choice%"=="7" SET SectionsAudio=2& SET CropThumb=1& GOTO :select-format-audio
IF "%choice%"=="8" SET SectionsVideo=2& SET CropThumb=1& GOTO :select-format-video
IF "%choice%"=="9" SET CustomChapters=1& SET SectionsAudio=2& GOTO :select-format-audio
IF "%choice%"=="10" SET CustomChapters=1& SET SectionsVideo=2& GOTO :select-format-video
IF "%choice%"=="11" SET CustomChapters=1& SET SectionsAudio=2& SET CropThumb=1& GOTO :select-format-audio
IF "%choice%"=="12" SET CustomChapters=1& SET SectionsVideo=2& SET CropThumb=1& GOTO :select-format-video
IF "%choice%"=="w" GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-preset-sections

:select-sections-number
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  SECTIONS NUMBER
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Set 1 Section
ECHO   %Cyan-s%2%ColorOff%. Set 2 Sections
ECHO   %Cyan-s%3%ColorOff%. Set 3 Sections
ECHO   %Cyan-s%4%ColorOff%. Set 4 Sections
ECHO   %Cyan-s%5%ColorOff%. Set 5 Sections
ECHO   %Cyan-s%6%ColorOff%. Set 6 Sections
ECHO   %Cyan-s%7%ColorOff%. Set 7 Sections
ECHO   %Cyan-s%8%ColorOff%. Set 8 Sections
ECHO   %Cyan-s%9%ColorOff%. Set 9 Sections
ECHO  %Cyan-s%10%ColorOff%. Set 10 Sections
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Enter your choice: 
IF "%choice%"=="1" SET DoSections=1& GOTO :enter-sections-1
IF "%choice%"=="2" SET DoSections=2& GOTO :enter-sections-2
IF "%choice%"=="3" SET DoSections=3& GOTO :enter-sections-3
IF "%choice%"=="4" SET DoSections=4& GOTO :enter-sections-4
IF "%choice%"=="5" SET DoSections=5& GOTO :enter-sections-5
IF "%choice%"=="6" SET DoSections=6& GOTO :enter-sections-6
IF "%choice%"=="7" SET DoSections=7& GOTO :enter-sections-7
IF "%choice%"=="8" SET DoSections=8& GOTO :enter-sections-8
IF "%choice%"=="9" SET DoSections=9& GOTO :enter-sections-9
IF "%choice%"=="10" SET DoSections=10& GOTO :enter-sections-10
IF "%choice%"=="w" IF "%SectionsVideo%"=="1" (GOTO :select-codec-video) ELSE (IF "%CustomFormatAudio%"=="1" (GOTO :select-format-audio) ELSE (IF "%quality_libfdk%"=="1" (GOTO :select-quality-vbr-audio) ELSE (IF "%quality_simple%"=="1" (GOTO :select-quality-audio) ELSE (IF "%quality_aac_at%"=="1" (GOTO :select-quality-vbr-at-audio) ELSE (GOTO :select-preset-sections)))))
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-sections-number

:enter-sections-1
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-2
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-3
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
SET /P section3=%BS%  Enter section 3 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-4
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
SET /P section3=%BS%  Enter section 3 time: 
SET /P section4=%BS%  Enter section 4 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-5
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
SET /P section3=%BS%  Enter section 3 time: 
SET /P section4=%BS%  Enter section 4 time: 
SET /P section5=%BS%  Enter section 5 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-6
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
SET /P section3=%BS%  Enter section 3 time: 
SET /P section4=%BS%  Enter section 4 time: 
SET /P section5=%BS%  Enter section 5 time: 
SET /P section6=%BS%  Enter section 6 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-7
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
SET /P section3=%BS%  Enter section 3 time: 
SET /P section4=%BS%  Enter section 4 time: 
SET /P section5=%BS%  Enter section 5 time: 
SET /P section6=%BS%  Enter section 6 time: 
SET /P section7=%BS%  Enter section 7 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-8
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
SET /P section3=%BS%  Enter section 3 time: 
SET /P section4=%BS%  Enter section 4 time: 
SET /P section5=%BS%  Enter section 5 time: 
SET /P section6=%BS%  Enter section 6 time: 
SET /P section7=%BS%  Enter section 7 time: 
SET /P section8=%BS%  Enter section 8 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-9
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
SET /P section3=%BS%  Enter section 3 time: 
SET /P section4=%BS%  Enter section 4 time: 
SET /P section5=%BS%  Enter section 5 time: 
SET /P section6=%BS%  Enter section 6 time: 
SET /P section7=%BS%  Enter section 7 time: 
SET /P section8=%BS%  Enter section 8 time: 
SET /P section9=%BS%  Enter section 9 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-10
SET /P section1=%BS%  Enter section time (i.e. 21:00-22:00): 
SET /P section2=%BS%  Enter section 2 time: 
SET /P section3=%BS%  Enter section 3 time: 
SET /P section4=%BS%  Enter section 4 time: 
SET /P section5=%BS%  Enter section 5 time: 
SET /P section6=%BS%  Enter section 6 time: 
SET /P section7=%BS%  Enter section 7 time: 
SET /P section8=%BS%  Enter section 8 time: 
SET /P section9=%BS%  Enter section 9 time: 
SET /P section10=%BS%  Enter section 10 time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1

::
::
:: DURATION FILTER MENU
::
::

:set-duration-filter
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  DURATION FILTER PRESETS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Is NOT live + 1 Duration Filter
ECHO   %Cyan-s%2%ColorOff%. Is NOT live + 2 Duration Filters
ECHO   %Cyan-s%3%ColorOff%. Is NOT live + 3 Duration Filters
ECHO   %Cyan-s%4%ColorOff%. Is NOT live + 4 Duration Filters
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%5%ColorOff%. IS live + 1 Duration Filter
ECHO   %Cyan-s%6%ColorOff%. IS live + 2 Duration Filters
ECHO   %Cyan-s%7%ColorOff%. IS live + 3 Duration Filters
ECHO   %Cyan-s%8%ColorOff%. IS live + 4 Duration Filters
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%9%ColorOff%. ^< 1 Minute Long
ECHO  %Cyan-s%10%ColorOff%. ^> 1 Minute Long
ECHO  %Cyan-s%11%ColorOff%. ^< 10 Minutes Long
ECHO  %Cyan-s%12%ColorOff%. ^> 10 Minutes Long
ECHO  %Cyan-s%13%ColorOff%. ^> 1 Minute AND ^< 10 Minutes Long
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO  %Cyan-s%14%ColorOff%. Video IS live
ECHO  %Cyan-s%15%ColorOff%. Video Is NOT live
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-n%r%ColorOff%. Disable Duration Filter
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select duration dilter preset: 
IF "%choice%"=="1" SET duration_filter=1& GOTO :duration-filter-1
IF "%choice%"=="2" SET duration_filter=2& GOTO :duration-filter-2
IF "%choice%"=="3" SET duration_filter=3& GOTO :duration-filter-3
IF "%choice%"=="4" SET duration_filter=4& GOTO :duration-filter-4
IF "%choice%"=="5" SET duration_filter=5& GOTO :duration-filter-1
IF "%choice%"=="6" SET duration_filter=6& GOTO :duration-filter-2
IF "%choice%"=="7" SET duration_filter=7& GOTO :duration-filter-3
IF "%choice%"=="8" SET duration_filter=8& GOTO :duration-filter-4
IF "%choice%"=="9" SET duration_filter=9& GOTO :settings
IF "%choice%"=="10" SET duration_filter=10& GOTO :settings
IF "%choice%"=="11" SET duration_filter=11& GOTO :settings
IF "%choice%"=="12" SET duration_filter=12& GOTO :settings
IF "%choice%"=="13" SET duration_filter=13& GOTO :settings
IF "%choice%"=="14" SET duration_filter=14& GOTO :settings
IF "%choice%"=="15" SET duration_filter=15& GOTO :settings
IF "%choice%"=="r" SET duration_filter=& GOTO :settings
IF "%choice%"=="w" GOTO :settings
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :set-duration-filter

:duration-filter-1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=%BS%  Set filter #1: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

:duration-filter-2
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=%BS%  Set filter #1: 
SET /P duration_filter_2=%BS%  Set filter #2: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

:duration-filter-3
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=%BS%  Set filter #1: 
SET /P duration_filter_2=%BS%  Set filter #2: 
SET /P duration_filter_3=%BS%  Set filter #3: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

:duration-filter-4
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=%BS%  Set filter #1: 
SET /P duration_filter_2=%BS%  Set filter #2: 
SET /P duration_filter_3=%BS%  Set filter #3: 
SET /P duration_filter_4=%BS%  Set filter #4: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

::
::
:: DATE FILTER MENU
::
::

:set-date-filter
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  DATE DOWNLOAD FILTERS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Only Uploaded ON or BEFORE The Specified Date
ECHO   %Cyan-s%2%ColorOff%. Only Uploaded ON or AFTER The Specified Date
ECHO   %Cyan-s%3%ColorOff%. Only Uploaded BETWEEN The Specified Dates
ECHO   %Cyan-s%4%ColorOff%. Only Uploaded ON CURRENT Date OR Relative To It
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%5%ColorOff%. Only Uploaded ON or BEFORE The Specified Date + Set 1 Duration Filter
ECHO   %Cyan-s%6%ColorOff%. Only Uploaded ON or AFTER The Specified Date + Set 1 Duration Filter
ECHO   %Cyan-s%7%ColorOff%. Only Uploaded BETWEEN The Specified Dates + Set 1 Duration Filter
ECHO   %Cyan-s%8%ColorOff%. Only Uploaded ON CURRENT Date OR Relative To It + Set 1 Duration Filter
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%9%ColorOff%. Only Uploaded ON or BEFORE The Specified Date + Set 2 Duration Filters
ECHO  %Cyan-s%10%ColorOff%. Only Uploaded ON or AFTER The Specified Date + Set 2 Duration Filters
ECHO  %Cyan-s%11%ColorOff%. Only Uploaded BETWEEN The Specified Dates + Set 2 Duration Filters
ECHO  %Cyan-s%12%ColorOff%. Only Uploaded ON CURRENT Date OR Relative To It + Set 2 Duration Filters
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-n%r%ColorOff%. Disable Date Filter
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Select date filter preset: 
IF "%choice%"=="1" SET date-filter=1& GOTO :date-filter-1
IF "%choice%"=="2" SET date-filter=2& GOTO :date-filter-1
IF "%choice%"=="3" SET date-filter=3& GOTO :date-filter-2
IF "%choice%"=="4" SET date-filter=4& GOTO :date-filter-1
IF "%choice%"=="5" SET date-filter=5& GOTO :date-filter-3
IF "%choice%"=="6" SET date-filter=6& GOTO :date-filter-3
IF "%choice%"=="7" SET date-filter=7& GOTO :date-filter-4
IF "%choice%"=="8" SET date-filter=8& GOTO :date-filter-3
IF "%choice%"=="9" SET date-filter=9& GOTO :date-filter-5
IF "%choice%"=="10" SET date-filter=10& GOTO :date-filter-5
IF "%choice%"=="11" SET date-filter=11& GOTO :date-filter-6
IF "%choice%"=="12" SET date-filter=12& GOTO :date-filter-5
IF "%choice%"=="r" SET date-filter=& GOTO :settings
IF "%choice%"=="w" GOTO :settings
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
:set-date-filter

:date-filter-1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=%BS%  Set date filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings
:date-filter-2
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=%BS%  Set BEFORE date filter: 
SET /P date_filter_2=%BS%  Set AFTER date filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings
:date-filter-3
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=%BS%  Set date filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=%BS%  Set duration filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings
:date-filter-4
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=%BS%  Set BEFORE date filter: 
SET /P date_filter_2=%BS%  Set AFTER date filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=%BS%  Set duration filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings
:date-filter-5
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=%BS%  Set date filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=%BS%  Set duration filter #1: 
SET /P duration_filter_2=%BS%  Set duration filter #2: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings
:date-filter-6
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=%BS%  Set BEFORE date filter: 
SET /P date_filter_2=%BS%  Set AFTER date filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=%BS%  Set duration filter #1: 
SET /P duration_filter_2=%BS%  Set duration filter #2: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

::
::
:: PROXY MENU
::
::

:proxy
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  PROXY SETTINGS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Set HTTP Proxy
ECHO   %Cyan-s%2%ColorOff%. Set HTTP Proxy + Authentication
ECHO   %Cyan-s%3%ColorOff%. Set SOCKS Proxy
ECHO   %Cyan-s%4%ColorOff%. Set SOCKS Proxy + Authentication
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-n%r%ColorOff%. Disable Proxies
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Enter your choice: 
IF "%choice%"=="1" SET proxy=1& SET proxy-option=1& GOTO :proxy-1
IF "%choice%"=="2" SET proxy=1& SET proxy-option=2& GOTO :proxy-2
IF "%choice%"=="3" SET proxy=1& SET proxy-option=3& GOTO :proxy-1
IF "%choice%"=="4" SET proxy=1& SET proxy-option=4& GOTO :proxy-2
IF "%choice%"=="r" SET proxy=& SET proxy-option=& SET proxy_adress=& SET proxy_username=& SET proxy_password=& GOTO :settings
IF "%choice%"=="w" GOTO :settings
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :proxy

:proxy-1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. proxy-ip:port, localhost:9150
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P proxy_adress=%BS%  Enter proxy IP:PORT: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

:proxy-2
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. proxy-ip:port, localhost:9150 and include your credentials
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P proxy_adress=%BS%  Enter proxy IP:PORT: 
SET /P proxy_username=%BS%  Enter your Username: 
SET /P proxy_password=%BS%  Enter your Password: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

::
::
:: GEO BYPASS MENU
::
::

:geo-bypass
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  GEO-BYPASS METHODS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Use Default Method To Fake HTTP Header
ECHO   %Cyan-s%2%ColorOff%. Use Two-Letter ISO Country Code
ECHO   %Cyan-s%3%ColorOff%. Use IP Block In CIDR Notation
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%4%ColorOff%. Use HTTP Proxy
ECHO   %Cyan-s%5%ColorOff%. Use HTTP Proxy + Authentication
ECHO   %Cyan-s%6%ColorOff%. Use SOCKS Proxy
ECHO   %Cyan-s%7%ColorOff%. Use SOCKS Proxy + Authentication
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-n%r%ColorOff%. Never Use Bypass
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=%BS%  Enter your choice: 
IF "%choice%"=="1" SET geo-bypass=default& SET geo-option=1& GOTO :settings
IF "%choice%"=="2" SET geo-bypass=1& SET geo-option=2& GOTO :geo-bypass-code
IF "%choice%"=="3" SET geo-bypass=1& SET geo-option=3& GOTO :geo-bypass-cidr
IF "%choice%"=="4" SET geo-bypass=1& SET geo-option=4& GOTO :geo-proxy-1
IF "%choice%"=="5" SET geo-bypass=1& SET geo-option=5& GOTO :geo-proxy-2
IF "%choice%"=="6" SET geo-bypass=1& SET geo-option=6& GOTO :geo-proxy-1
IF "%choice%"=="7" SET geo-bypass=1& SET geo-option=7& GOTO :geo-proxy-2
IF "%choice%"=="r" SET geo-bypass=never& SET geo-option=1& SET geo_proxy_adress=& SET geo_iso_code=& SET geo_cidr=& SET geo_proxy_username=& SET geo_proxy_password=& GOTO :settings
IF "%choice%"=="w" GOTO :settings
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :geo-bypass

:geo-bypass-code
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Specific two-letter ISO 3166-2 country code, i.e. NL for Netherlands
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P geo_iso_code=%BS%  Enter ISO Code: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

:geo-bypass-cidr
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  An IP block in CIDR notation, i.e. 5.104.136.0/21
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P geo_cidr=%BS%  Enter CIDR IP notation: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

:geo-proxy-1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. proxy-ip:port, localhost:9150
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P geo_proxy_adress=%BS%  Enter proxy IP:PORT: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

:geo-proxy-2
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. proxy-ip:port, localhost:9150 and include your credentials
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P geo_proxy_adress=%BS%  Enter proxy IP:PORT: 
SET /P geo_proxy_username=%BS%  Enter your Username: 
SET /P geo_proxy_password=%BS%  Enter your Password: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :settings

::
::
:: AUDIO PRESETS
::
::

REM IF DEFINED usearia (IF "%CustomFormat-m4a%"=="2" (
REM SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
REM ) ELSE (IF "%CustomFormat-m4a%"=="4" (
REM SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
REM ) ELSE (IF "%CustomFormat-m4a%"=="5" (
REM SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
REM ) ELSE (IF "%CustomFormat-m4a%"=="6" (
REM SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
REM ) ELSE (IF "%CustomFormat-m4a%"=="7" (
REM SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
REM ) ELSE (IF "%CustomFormat-m4a%"=="8" (
REM SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
REM ) ELSE (
REM SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
REM ))))))) ELSE (
REM SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
REM )

:: AUDIO SPLIT PRESET
:doYTDL-audio-preset-1
SET  OutTemplate= --path "%TARGET_FOLDER%" --output "thumbnail:%TARGET_FOLDER%\%%(title)s\cover.%%(ext)s" --output "chapter:%TARGET_FOLDER%\%%(title)s\%%(section_title)s.%%(ext)s"
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
IF "%CustomChapters%"=="1" (
SET       Select= --no-download-archive --no-playlist --split-chapters --extractor-args "youtube:chapters_file=%CHAPTERS_PATH%" --compat-options no-youtube-unavailable-videos
) ELSE (
SET       Select= --no-download-archive --no-playlist --split-chapters --compat-options no-youtube-unavailable-videos
)
IF DEFINED usearia (
SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
:: --embed-thumbnail with --split-chapters is broken https://github.com/yt-dlp/yt-dlp/issues/6225
IF "%CropThumb%"=="1" (
SET    Thumbnail= --no-embed-thumbnail --write-thumbnail --exec "after_move:\"%FFMPEG_PATH%\" -v quiet -i \"%TARGET_FOLDER%\%%^^^(title^^^)s\cover.webp\" -y -c:v %FFMPEG_THUMB_FORMAT% -q:v %THUMB_COMPRESS% -vf crop=\"'if^^^(gt^^^(ih,iw^^^),iw,ih^^^)':'if^^^(gt^^^(iw,ih^^^),ih,iw^^^)'\" \"%TARGET_FOLDER%\%%^^^(title^^^)s\cover.%THUMB_FORMAT%\"" --exec "after_move:del /q \"%TARGET_FOLDER%\%%^^^(title^^^)s\cover.webp\""
) ELSE (
SET    Thumbnail= --no-embed-thumbnail --write-thumbnail --convert-thumbnail %THUMB_FORMAT% --postprocessor-args "ThumbnailsConvertor:-q:v %THUMB_COMPRESS%"
)
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249"
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --extract-audio --format "141/38/22/140/37/59/34/35/59/78/18"
) ELSE (IF "%CustomFormat-ogg%"=="1" (
SET       Format= --extract-audio --format "46/45/44/43"
) ELSE (IF "%CustomFormat-mp3%"=="1" (
SET       Format= --extract-audio --format "ba[acodec^=mp3]/b"
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --extract-audio --format "338/774/251/250/249"
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18"
) ELSE (IF "%CustomFormat-m4a%"=="4" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1 -af \"compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="3" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -threads 0 -b:a %AUDIO_BITRATE%k -c:a libopus -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="4" (
SET       Format= --extract-audio --format "bestaudio[acodec^=opus]/bestaudio[container*=dash]/bestaudio"
) ELSE (IF "%CustomFormat-m4a%"=="5" (
SET       Format= --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1 -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="6" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -ac 2 -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="7" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -ac 2 -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1 -af \"compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="8" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1 -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%BestAudio%"=="1" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43"
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))))))))))
SET     Subtitle=
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
:: --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s"
SET   PreProcess= --parse-metadata "title:%%(artist)s - %%(album)s" --parse-metadata "%%(chapters|)l:(?P<has_chapters>.)" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album_artist,album_artists,artist,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --no-keep-video --embed-metadata --no-embed-chapters --compat-options no-attach-info-json --exec "after_move:del /q %%(filepath,_filename|)q"
IF NOT DEFINED use_pl_replaygain (
SET   ReplayGain=
) ELSE (IF "%ReplayGainPreset%"=="1" (
SET   ReplayGain= --use-postprocessor ReplayGain:when=after_move
) ELSE (IF "%ReplayGainPreset%"=="2" (
SET   ReplayGain= --use-postprocessor ReplayGain:when=playlist
) ELSE (IF "%ReplayGainPreset%"=="3" (
SET   ReplayGain= --use-postprocessor "ReplayGain:when=playlist;no_album=true"
))))
SET     Duration=
SET  Date_Filter=
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: AUDIO SINGLE PRESET
:doYTDL-audio-preset-2
IF "%FormatTitle%"=="1" (
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(uploader)s\%%(artist,artists.0,creator,uploader)s - %%(title)s.%%(ext)s"
) ELSE (
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(uploader)s\%%(title)s.%%(ext)s"
)
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
IF DEFINED OnlyNew (IF "%DownloadList%"=="1" (
SET       Select= --download-archive "%ARCHIVE_PATH%" --no-overwrites --no-playlist --batch-file "%URL%" --compat-options no-youtube-unavailable-videos
) ELSE (
SET       Select= --download-archive "%ARCHIVE_PATH%" --no-overwrites --no-playlist --compat-options no-youtube-unavailable-videos
))
IF NOT DEFINED OnlyNew (IF "%DownloadList%"=="1" (
SET       Select= --no-download-archive --no-playlist --batch-file "%URL%" --compat-options no-youtube-unavailable-videos
) ELSE (
SET       Select= --no-download-archive --no-playlist --compat-options no-youtube-unavailable-videos
))
IF DEFINED usearia (
SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFMPEG_THUMB_FORMAT% -q:v %THUMB_COMPRESS% -vf crop=\"'if^^^(gt^^^(ih,iw^^^),iw,ih^^^)':'if^^^(gt^^^(iw,ih^^^),ih,iw^^^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %THUMB_FORMAT% --postprocessor-args "ThumbnailsConvertor:-q:v %THUMB_COMPRESS%"
)
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249"
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --extract-audio --format "141/38/22/140/37/59/34/35/59/78/18"
) ELSE (IF "%CustomFormat-ogg%"=="1" (
SET       Format= --extract-audio --format "46/45/44/43"
) ELSE (IF "%CustomFormat-mp3%"=="1" (
SET       Format= --extract-audio --format "ba[acodec^=mp3]/b"
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --extract-audio --format "338/774/251/250/249"
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18"
) ELSE (IF "%CustomFormat-m4a%"=="4" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1 -af \"compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="3" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -threads 0 -b:a %AUDIO_BITRATE%k -c:a libopus -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="4" (
SET       Format= --extract-audio --format "bestaudio[acodec^=opus]/bestaudio[container*=dash]/bestaudio"
) ELSE (IF "%CustomFormat-m4a%"=="5" (
SET       Format= --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1 -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="6" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -ac 2 -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="7" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -ac 2 -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1 -af \"compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="8" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1 -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%BestAudio%"=="1" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43"
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))))))))))
SET     Subtitle=
IF "%CommentPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=10;comment_sort=top"
) ELSE (
SET     Comments=
)
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (
SET    AdobePass=
)
IF "%FormatTitle%"=="1" (
SET   PreProcess= --parse-metadata "title:%%(artist)s - %%(title)s" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
) ELSE (
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
)
SET  PostProcess= --no-keep-video --embed-metadata --compat-options no-attach-info-json
IF NOT DEFINED use_pl_replaygain (
SET   ReplayGain=
) ELSE (IF "%ReplayGainPreset%"=="1" (
SET   ReplayGain= --use-postprocessor ReplayGain:when=after_move
) ELSE (IF "%ReplayGainPreset%"=="2" (
SET   ReplayGain= --use-postprocessor ReplayGain:when=playlist
) ELSE (IF "%ReplayGainPreset%"=="3" (
SET   ReplayGain= --use-postprocessor "ReplayGain:when=playlist;no_album=true"
))))
IF NOT DEFINED duration_filter (
SET     Duration=
) ELSE (IF "%duration_filter%"=="1" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="2" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="3" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="4" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
) ELSE (IF "%duration_filter%"=="5" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="6" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="7" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="8" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
) ELSE (IF "%duration_filter%"=="9" (
SET     Duration= --match-filters "duration<60"
) ELSE (IF "%duration_filter%"=="10" (
SET     Duration= --match-filters "duration>60"
) ELSE (IF "%duration_filter%"=="11" (
SET     Duration= --match-filters "duration<600"
) ELSE (IF "%duration_filter%"=="12" (
SET     Duration= --match-filters "duration>600"
) ELSE (IF "%duration_filter%"=="13" (
SET     Duration= --match-filters "duration>=60 & duration<=600"
) ELSE (IF "%duration_filter%"=="14" (
SET     Duration= --match-filters "is_live"
) ELSE (IF "%duration_filter%"=="15" (
SET     Duration= --match-filters "^^^!is_live"
))))))))))))))))
IF NOT DEFINED date_filter (
SET  Date_Filter=
) ELSE (IF "%date_filter%"=="1" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1%"
) ELSE (IF "%date_filter%"=="2" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1%"
) ELSE (IF "%date_filter%"=="3" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2%"
) ELSE (IF "%date_filter%"=="4" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1%"
) ELSE (IF "%date_filter%"=="5" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="6" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="7" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="8" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="9" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="10" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="11" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="12" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
)))))))))))))
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: AUDIO PLAYLIST PRESET
:doYTDL-audio-preset-3
:: this is an experiment to get an approximate playlist creation date
:: i'm getting the earliest date of all uploaded videos in it and set it to variable
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Getting the approximate playlist/album creation DATE...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%" --no-warnings --quiet --simulate --flat-playlist --extractor-args "youtubetab:approximate_date" --print "%%(upload_date>%%Y)s" "%URL%" | sort | "%HEAD_PATH%" -n 1 | "%TR_PATH%" -d '\012\015' | clip >NUL 2>&1
FOR /f "delims=" %%i IN ('"%PASTE_PATH%"') DO SET "playlist_date=%%i"
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Approximate DATE is %Cyan-s%%playlist_date%%ColorOff%
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
IF "%VariousArtists%"=="1" (
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(uploader)s\%%(album,playlist_title,playlist|)s\%%(meta_track_number,playlist_index,playlist_autonumber)02d. %%(artist,artists,creator,uploader)s - %%(title)s.%%(ext)s"
) ELSE (IF "%Album%"=="1" (
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(uploader)s\%%(%Cyan-s%%playlist_date%%ColorOff%,release_year,release_date>%%Y,upload_date>%%Y)s - %%(album,playlist_title,playlist|)s\%%(meta_track_number,playlist_index,playlist_autonumber)02d. %%(title)s.%%(ext)s" 
) ELSE (
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(uploader)s\%%(album,playlist_title,playlist|)s\%%(meta_track_number,playlist_index,playlist_autonumber)02d. %%(title)s.%%(ext)s" 
))
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%ARCHIVE_PATH%" --no-overwrites --yes-playlist --no-playlist-reverse --compat-options no-youtube-unavailable-videos
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse --compat-options no-youtube-unavailable-videos
)
IF DEFINED usearia (
SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFMPEG_THUMB_FORMAT% -q:v %THUMB_COMPRESS% -vf crop=\"'if^^^(gt^^^(ih,iw^^^),iw,ih^^^)':'if^^^(gt^^^(iw,ih^^^),ih,iw^^^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %THUMB_FORMAT% --postprocessor-args "ThumbnailsConvertor:-q:v %THUMB_COMPRESS%"
)
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249"
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --extract-audio --format "141/38/22/140/37/59/34/35/59/78/18"
) ELSE (IF "%CustomFormat-ogg%"=="1" (
SET       Format= --extract-audio --format "46/45/44/43"
) ELSE (IF "%CustomFormat-mp3%"=="1" (
SET       Format= --extract-audio --format "ba[acodec^=mp3]/b"
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --extract-audio --format "338/774/251/250/249"
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18"
) ELSE (IF "%CustomFormat-m4a%"=="4" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1 -af \"compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="3" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -threads 0 -b:a %AUDIO_BITRATE%k -c:a libopus -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="4" (
SET       Format= --extract-audio --format "bestaudio[acodec^=opus]/bestaudio[container*=dash]/bestaudio"
) ELSE (IF "%CustomFormat-m4a%"=="5" (
SET       Format= --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1 -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="6" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -ac 2 -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="7" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -ac 2 -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1 -af \"compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="8" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1 -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%BestAudio%"=="1" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43"
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))))))))))
SET     Subtitle=
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
IF "%VariousArtists%"=="1" (
SET   PreProcess= --parse-metadata "title:%%(artist)s - %%(title)s" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist "^.*$" "Various Artists" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
) ELSE (
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
)
SET  PostProcess= --no-keep-video --embed-metadata --compat-options no-attach-info-json
IF NOT DEFINED use_pl_replaygain (
SET   ReplayGain=
) ELSE (IF "%ReplayGainPreset%"=="1" (
SET   ReplayGain= --use-postprocessor ReplayGain:when=after_move
) ELSE (IF "%ReplayGainPreset%"=="2" (
SET   ReplayGain= --use-postprocessor ReplayGain:when=playlist
) ELSE (IF "%ReplayGainPreset%"=="3" (
SET   ReplayGain= --use-postprocessor "ReplayGain:when=playlist;no_album=true"
))))
IF NOT DEFINED duration_filter (
SET     Duration=
) ELSE (IF "%duration_filter%"=="1" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="2" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="3" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="4" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
) ELSE (IF "%duration_filter%"=="5" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="6" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="7" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="8" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
) ELSE (IF "%duration_filter%"=="9" (
SET     Duration= --match-filters "duration<60"
) ELSE (IF "%duration_filter%"=="10" (
SET     Duration= --match-filters "duration>60"
) ELSE (IF "%duration_filter%"=="11" (
SET     Duration= --match-filters "duration<600"
) ELSE (IF "%duration_filter%"=="12" (
SET     Duration= --match-filters "duration>600"
) ELSE (IF "%duration_filter%"=="13" (
SET     Duration= --match-filters "duration>=60 & duration<=600"
) ELSE (IF "%duration_filter%"=="14" (
SET     Duration= --match-filters "is_live"
) ELSE (IF "%duration_filter%"=="15" (
SET     Duration= --match-filters "^^^!is_live"
))))))))))))))))
IF NOT DEFINED date_filter (
SET  Date_Filter=
) ELSE (IF "%date_filter%"=="1" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1%"
) ELSE (IF "%date_filter%"=="2" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1%"
) ELSE (IF "%date_filter%"=="3" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2%"
) ELSE (IF "%date_filter%"=="4" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1%"
) ELSE (IF "%date_filter%"=="5" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="6" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="7" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="8" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="9" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="10" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="11" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="12" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
)))))))))))))
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: AUDIO QUICK PRESET
:doYTDL-preset-quick
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(uploader)s\%%(artist,artists.0,creator,uploader)s - %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
SET  GeoRestrict= --xff "%GEO-BYPASS%"
SET       Select= --no-download-archive --no-playlist --compat-options no-youtube-unavailable-videos
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFMPEG_THUMB_FORMAT% -q:v %THUMB_COMPRESS% -vf crop=\"'if^^^(gt^^^(ih,iw^^^),iw,ih^^^)':'if^^^(gt^^^(iw,ih^^^),ih,iw^^^)'\""
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
SET  WorkArounds=
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43"
SET     Subtitle=
SET     Comments=
SET Authenticate= --cookies "%COOKIES_PATH%"
SET    AdobePass=
SET   PreProcess= --parse-metadata "title:%%(artist)s - %%(title)s" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --no-keep-video --embed-metadata --compat-options no-attach-info-json
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-quick

::
::
:: VIDEO PRESETS
::
::

:: VIDEO SPLIT PRESET
:doYTDL-video-preset-1
SET  OutTemplate= --path "%TARGET_FOLDER%" --output "thumbnail:%TARGET_FOLDER%\%%(title)s\cover.%%(ext)s" --output "chapter:%TARGET_FOLDER%\%%(title)s\%%(section_title)s.%%(ext)s"
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
IF "%CustomChapters%"=="1" (
SET       Select= --no-download-archive --no-playlist --split-chapters --extractor-args "youtube:chapters_file=%CHAPTERS_PATH%"
) ELSE (
SET       Select= --no-download-archive --no-playlist --split-chapters
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
)
SET Sponsorblock= --sponsorblock-mark %SPONSORBLOCK_OPT% --sponsorblock-remove %SPONSORBLOCK_OPT%
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --no-embed-thumbnail --write-thumbnail --exec "after_move:\"%FFMPEG_PATH%\" -v quiet -i \"%TARGET_FOLDER%\%%^^^(title^^^)s\cover.webp\" -y -c:v %FFMPEG_THUMB_FORMAT% -q:v %THUMB_COMPRESS% -vf crop=\"'if^^^(gt^^^(ih,iw^^^),iw,ih^^^)':'if^^^(gt^^^(iw,ih^^^),ih,iw^^^)'\" \"%TARGET_FOLDER%\%%^^^(title^^^)s\cover.%THUMB_FORMAT%\"" --exec "after_move:del /q \"%TARGET_FOLDER%\%%^^^(title^^^)s\cover.webp\""
) ELSE (
SET    Thumbnail= --no-embed-thumbnail --write-thumbnail --convert-thumbnail %THUMB_FORMAT% --postprocessor-args "ThumbnailsConvertor:-q:v %THUMB_COMPRESS%"
)
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormatVideo%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv
) ELSE (IF "%CustomFormatVideo%"=="2" (
SET       Format= -S "+size,+br,+res,+fps" --merge-output-format mkv
) ELSE (IF "%CustomFormatVideo%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv
) ELSE (IF "%CustomCodec%"=="avc" (
SET       Format= --format "(bestvideo[vcodec~='^((he|a)vc|h26[45])'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4]) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mp4 --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="vp9" (
SET       Format= --format "(bestvideo[vcodec~='(vp9.2|vp09|vp9)'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mkv --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="av1" (
SET       Format= --format "(bestvideo[vcodec^=av01][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4])+(bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mp4 --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="any" (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
)))))))
SET     Subtitle= 
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(chapters|)l:(?P<has_chapters>.)" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,artist,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
:: --embed-thumbnail with --split-chapters is broken https://github.com/yt-dlp/yt-dlp/issues/6225
SET  PostProcess= --no-keep-video --embed-metadata --no-embed-chapters --compat-options no-attach-info-json --force-keyframes-at-cuts --match-filters "has_chapters" --exec "after_move:del /q %%(filepath,_filename|)q"
SET ReplayGain=
SET Duration=
SET Date_Filter=
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: VIDEO SINGLE PRESET
:doYTDL-video-preset-2
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(artists.0,artist,uploader)s - %%(title)s.%%(ext)s"
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
IF DEFINED OnlyNew (IF "%DownloadList%"=="1" (
SET       Select= --download-archive "%ARCHIVE_PATH%" --no-overwrites --no-playlist --batch-file "%URL%" --compat-options no-youtube-unavailable-videos
) ELSE (
SET       Select= --download-archive "%ARCHIVE_PATH%" --no-overwrites --no-playlist --compat-options no-youtube-unavailable-videos
))
IF NOT DEFINED OnlyNew (IF "%DownloadList%"=="1" (
SET       Select= --no-download-archive --no-playlist --batch-file "%URL%" --compat-options no-youtube-unavailable-videos
) ELSE (
SET       Select= --no-download-archive --no-playlist --compat-options no-youtube-unavailable-videos
))
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
)
SET Sponsorblock= --sponsorblock-mark %SPONSORBLOCK_OPT% --sponsorblock-remove %SPONSORBLOCK_OPT%
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFMPEG_THUMB_FORMAT% -q:v %THUMB_COMPRESS% -vf crop=\"'if^^^(gt^^^(ih,iw^^^),iw,ih^^^)':'if^^^(gt^^^(iw,ih^^^),ih,iw^^^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %THUMB_FORMAT% --postprocessor-args "ThumbnailsConvertor:-q:v %THUMB_COMPRESS%"
)
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormatVideo%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv
) ELSE (IF "%CustomFormatVideo%"=="2" (
SET       Format= -S "+size,+br,+res,+fps" --merge-output-format mkv
) ELSE (IF "%CustomFormatVideo%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv
) ELSE (IF "%CustomCodec%"=="avc" (
SET       Format= --format "(bestvideo[vcodec~='^((he|a)vc|h26[45])'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4]) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mp4 --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="vp9" (
SET       Format= --format "(bestvideo[vcodec~='(vp9.2|vp09|vp9)'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mkv --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="av1" (
SET       Format= --format "(bestvideo[vcodec^=av01][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4])+(bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mp4 --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="any" (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
)))))))
SET     Subtitle= --sub-format "%SUB_FORMAT%" --sub-langs "%SUB_LANGS%" --compat-options no-live-chat
IF "%CommentPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=50;comment_sort=top"
) ELSE (
SET     Comments=
)
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (
SET    AdobePass=
)
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --no-keep-video --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json
SET   ReplayGain=
IF NOT DEFINED duration_filter (
SET     Duration=
) ELSE (IF "%duration_filter%"=="1" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="2" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="3" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="4" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
) ELSE (IF "%duration_filter%"=="5" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="6" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="7" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="8" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
) ELSE (IF "%duration_filter%"=="9" (
SET     Duration= --match-filters "duration<60"
) ELSE (IF "%duration_filter%"=="10" (
SET     Duration= --match-filters "duration>60"
) ELSE (IF "%duration_filter%"=="11" (
SET     Duration= --match-filters "duration<600"
) ELSE (IF "%duration_filter%"=="12" (
SET     Duration= --match-filters "duration>600"
) ELSE (IF "%duration_filter%"=="13" (
SET     Duration= --match-filters "duration>=60 & duration<=600"
) ELSE (IF "%duration_filter%"=="14" (
SET     Duration= --match-filters "is_live"
) ELSE (IF "%duration_filter%"=="15" (
SET     Duration= --match-filters "^^^!is_live"
))))))))))))))))
IF NOT DEFINED date_filter (
SET  Date_Filter=
) ELSE (IF "%date_filter%"=="1" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1%"
) ELSE (IF "%date_filter%"=="2" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1%"
) ELSE (IF "%date_filter%"=="3" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2%"
) ELSE (IF "%date_filter%"=="4" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1%"
) ELSE (IF "%date_filter%"=="5" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="6" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="7" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="8" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="9" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="10" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="11" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="12" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
)))))))))))))
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: VIDEO PLAYLIST PRESET
:doYTDL-video-preset-3
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Getting the approximate playlist/album creation DATE...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%" --no-warnings --quiet --simulate --flat-playlist --extractor-args "youtubetab:approximate_date" --print "%%(upload_date>%%Y)s" "%URL%" | sort | "%HEAD_PATH%" -n 1 | "%TR_PATH%" -d '\012\015' | clip >NUL 2>&1
FOR /f "delims=" %%i IN ('"%PASTE_PATH%"') DO SET "playlist_date=%%i"
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Approximate DATE is %Cyan-s%%playlist_date%%ColorOff%
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(uploader)s\%%(%Cyan-s%%playlist_date%%ColorOff%,release_year,release_date>%%Y,upload_date>%%Y)s - %%(album,playlist_title,playlist|)s\%%(meta_track_number,playlist_index,playlist_autonumber)02d. %%(title)s.%%(ext)s"
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%ARCHIVE_PATH%" --no-overwrites --yes-playlist --no-playlist-reverse --compat-options no-youtube-unavailable-videos
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse --compat-options no-youtube-unavailable-videos
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
)
SET Sponsorblock= --sponsorblock-mark %SPONSORBLOCK_OPT% --sponsorblock-remove %SPONSORBLOCK_OPT%
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFMPEG_THUMB_FORMAT% -q:v %THUMB_COMPRESS% -vf crop=\"'if^^^(gt^^^(ih,iw^^^),iw,ih^^^)':'if^^^(gt^^^(iw,ih^^^),ih,iw^^^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %THUMB_FORMAT% --postprocessor-args "ThumbnailsConvertor:-q:v %THUMB_COMPRESS%"
)
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormatVideo%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv
) ELSE (IF "%CustomFormatVideo%"=="2" (
SET       Format= -S "+size,+br,+res,+fps" --merge-output-format mkv
) ELSE (IF "%CustomFormatVideo%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv
) ELSE (IF "%CustomCodec%"=="avc" (
SET       Format= --format "(bestvideo[vcodec~='^((he|a)vc|h26[45])'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4]) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mp4 --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="vp9" (
SET       Format= --format "(bestvideo[vcodec~='(vp9.2|vp09|vp9)'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mkv --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="av1" (
SET       Format= --format "(bestvideo[vcodec^=av01][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4])+(bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mp4 --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="any" (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
)))))))
SET     Subtitle= --sub-format "%SUB_FORMAT%" --sub-langs "%SUB_LANGS%" --compat-options no-live-chat
IF "%CommentPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=50;comment_sort=top"
) ELSE (
SET     Comments=
)
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (
SET    AdobePass=
)
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --no-keep-video --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json
SET   ReplayGain=
IF NOT DEFINED duration_filter (
SET     Duration=
) ELSE (IF "%duration_filter%"=="1" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="2" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="3" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="4" (
SET     Duration= --match-filters "^^^!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
) ELSE (IF "%duration_filter%"=="5" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="6" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="7" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="8" (
SET     Duration= --match-filters "is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
) ELSE (IF "%duration_filter%"=="9" (
SET     Duration= --match-filters "duration<60"
) ELSE (IF "%duration_filter%"=="10" (
SET     Duration= --match-filters "duration>60"
) ELSE (IF "%duration_filter%"=="11" (
SET     Duration= --match-filters "duration<600"
) ELSE (IF "%duration_filter%"=="12" (
SET     Duration= --match-filters "duration>600"
) ELSE (IF "%duration_filter%"=="13" (
SET     Duration= --match-filters "duration>=60 & duration<=600"
) ELSE (IF "%duration_filter%"=="14" (
SET     Duration= --match-filters "is_live"
) ELSE (IF "%duration_filter%"=="15" (
SET     Duration= --match-filters "^^^!is_live"
))))))))))))))))
IF NOT DEFINED date_filter (
SET  Date_Filter=
) ELSE (IF "%date_filter%"=="1" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1%"
) ELSE (IF "%date_filter%"=="2" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1%"
) ELSE (IF "%date_filter%"=="3" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2%"
) ELSE (IF "%date_filter%"=="4" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1%"
) ELSE (IF "%date_filter%"=="5" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="6" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="7" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="8" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="9" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="10" (
SET  Date_Filter= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="11" (
SET  Date_Filter= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="12" (
SET  Date_Filter= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
)))))))))))))
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

::
::
:: SUBTITLES AND COMMENTS PRESETS
::
::

:: DOWNLOAD JUST SUBS
:subs-preset-1
IF "%SubsPreset%"=="1" (
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(title)s.%%(ext)s"
) ELSE (IF "%SubsPreset%"=="2" (
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(title)s-transcript.%%(ext)s"
))
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
SET       Select=
SET     Download= --skip-download --concurrent-fragments 1
SET Sponsorblock=
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --ffmpeg-location "%FFMPEG_PATH%"
SET    Thumbnail=
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
SET  WorkArounds=
SET       Format=
IF "%SubsPreset%"=="1" (
SET     Subtitle= --write-subs --write-auto-subs --sub-format "%SUB_FORMAT%" --sub-langs "%SUB_LANGS%" --compat-options no-live-chat
) ELSE (IF "%SubsPreset%"=="2" (
SET     Subtitle= --write-subs --write-auto-subs --sub-format ttml --convert-subs srt --sub-langs "%SUB_LANGS%" --compat-options no-live-chat
) ELSE (IF "%SubsPreset%"=="3" (
SET     Subtitle= --sub-langs "%SUB_LANGS%" --write-auto-subs --write-subs --convert-subs srt --use-postprocessor srt_fix:when=before_dl --compat-options no-live-chat
)))
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
IF "%SubsPreset%"=="2" (
SET    AdobePass= --exec before_dl:"\"%SED_PATH%\" -i -f \"%SED_COMMANDS%\" %%(requested_subtitles.:.filepath)#q"
) ELSE (
SET    AdobePass= 
)
SET   PreProcess=
SET  PostProcess=
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=1& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: DOWNLOAD JUST COMMENTS
:comments-preset-1
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(title)s.%%(ext)s"
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
SET       Select=
SET     Download= --skip-download
SET Sponsorblock=
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --ffmpeg-location "%FFMPEG_PATH%"
SET    Thumbnail=
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
SET  WorkArounds=
SET       Format=
SET     Subtitle=
IF "%CommentPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=25;comment_sort=top" --print-to-file "%%(comments)j" "%%(title)s.comments.json"
) ELSE (IF "%CommentPreset%"=="2" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=25;comment_sort=top"
) ELSE (IF "%CommentPreset%"=="3" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=500,all,all,50;comment_sort=top" --print-to-file "%%(comments)j" "%%(title)s.comments.json"
) ELSE (IF "%CommentPreset%"=="4" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=500,all,all,50;comment_sort=top"
) ELSE (IF "%CommentPreset%"=="5" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=all,all,all,all;comment_sort=top" --print-to-file "%%(comments)j" "%%(title)s.comments.json"
) ELSE (IF "%CommentPreset%"=="6" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=all,all,all,all;comment_sort=top"
) ELSE (IF "%CommentPreset%"=="7" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=25;comment_sort=new" --print-to-file "%%(comments)j" "%%(title)s.comments.json"
) ELSE (IF "%CommentPreset%"=="8" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=25;comment_sort=new"
) ELSE (IF "%CommentPreset%"=="9" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=500,all,all,50;comment_sort=new" --print-to-file "%%(comments)j" "%%(title)s.comments.json"
) ELSE (IF "%CommentPreset%"=="10" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=500,all,all,50;comment_sort=new"
) ELSE (IF "%CommentPreset%"=="11" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=all,all,all,all;comment_sort=new" --print-to-file "%%(comments)j" "%%(title)s.comments.json"
) ELSE (IF "%CommentPreset%"=="12" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=all,all,all,all;comment_sort=new"
) ELSE (IF "%CommentPreset%"=="13" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=500,all,all,50;comment_sort=new"
)))))))))))))
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="2" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="3" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="4" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="5" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="6" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="7" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="8" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="9" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="10" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="11" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="12" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_fork.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="13" (
SET    AdobePass= --exec before_dl:"\"%PYTHON_PATH%\" \"%YTDLP_FOLDER%\yt-dlp_nest_comments_new.py\" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
)))))))))))))
SET   PreProcess=
SET  PostProcess=
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=1& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

::
::
:: STREAM TO PLAYER PRESETS
::
::

:: STREAM TO PLAYER
:doYTDL-preset-stream-1
SET  OutTemplate= --output -
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
SET       Select=
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS% --downloader "%FFMPEG_PATH%"
SET Sponsorblock=
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --ffmpeg-location "%FFMPEG_PATH%"
SET    Thumbnail=
SET    Verbosity= --color always --quiet --console-title --progress
SET  WorkArounds=
IF "%StreamVideoFormat%"=="1" (
SET       Format= --format "bv*+ba/b"
) ELSE (IF "%StreamVideoFormat%"=="2" (
SET       Format= -S "+size,+br,+res,+fps"
) ELSE (IF "%StreamVideoFormat%"=="3" (
SET       Format= -S "+size,+br"
) ELSE (IF "%StreamVideoFormat%"=="4" (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best"
) ELSE (IF "%StreamVideoFormat%"=="5" (
SET       Format= --format "(bestvideo[vcodec~='^((he|a)vc|h26[45])'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4]) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best"
) ELSE (IF "%StreamVideoFormat%"=="6" (
SET       Format= --format "(bestvideo[vcodec~='(vp9.2|vp09|vp9)'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best"
) ELSE (IF "%StreamVideoFormat%"=="7" (
SET       Format= --format "(bestvideo[vcodec^=av01][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4])+(bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best"
) ELSE (IF "%StreamAudioFormat%"=="1" (
SET       Format= --format "ba/b"
) ELSE (IF "%StreamAudioFormat%"=="2" (
SET       Format= --format "ba/b" -S "proto"
)))))))))
SET     Subtitle=
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
SET   PreProcess=
SET  PostProcess=
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=1& SET Downloaded-Quick=& GOTO :doYTDL-stream

::
::
:: DOWNLOAD SECTIONS PRESETS
::
::

:: SECTIONS
:sections-preset-1
SET  OutTemplate= --output "%TARGET_FOLDER%\%%(title)s_%%(duration)s.%%(ext)s"
IF NOT DEFINED stop_on_error (
SET      Options= --ignore-errors --ignore-config
) ELSE (IF "%stop_on_error%"=="9" (
SET      Options= --ignore-config
) ELSE (
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors %stop_on_error%
))
IF NOT DEFINED proxy (
SET      Network= --add-headers "User-Agent:%USER_AGENT%"
) ELSE (IF "%proxy-option%"=="1" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="2" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "http://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (IF "%proxy-option%"=="3" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_adress%"
) ELSE (IF "%proxy-option%"=="4" (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "socks5://%proxy_username%:%proxy_password%@%proxy_adress%"
) ELSE (
SET      Network= --add-headers "User-Agent:%USER_AGENT%" --proxy "%PROXY%"
)))))
IF NOT DEFINED geo-bypass (
SET  GeoRestrict=
) ELSE (IF "%geo-option%"=="1" (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
) ELSE (IF "%geo-option%"=="2" (
SET  GeoRestrict= --xff "%geo_iso_code%"
) ELSE (IF "%geo-option%"=="3" (
SET  GeoRestrict= --xff "%geo_cidr%"
) ELSE (IF "%geo-option%"=="4" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="5" (
SET  GeoRestrict= --geo-verification-proxy "http://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="6" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_adress%"
) ELSE (IF "%geo-option%"=="7" (
SET  GeoRestrict= --geo-verification-proxy "socks5://%geo_proxy_username%:%geo_proxy_password%@%geo_proxy_adress%"
) ELSE (
SET  GeoRestrict= --xff "%GEO-BYPASS%"
))))))))
IF "%DoSections%"=="1" (
SET       Select= --download-sections "*%section1%"
) ELSE (IF "%DoSections%"=="2" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%"
) ELSE (IF "%DoSections%"=="3" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%" --download-sections "*%section3%"
) ELSE (IF "%DoSections%"=="4" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%" --download-sections "*%section3%" --download-sections "*%section4%"
) ELSE (IF "%DoSections%"=="5" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%" --download-sections "*%section3%" --download-sections "*%section4%" --download-sections "*%section5%"
) ELSE (IF "%DoSections%"=="6" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%" --download-sections "*%section3%" --download-sections "*%section4%" --download-sections "*%section5%" --download-sections "*%section6%"
) ELSE (IF "%DoSections%"=="7" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%" --download-sections "*%section3%" --download-sections "*%section4%" --download-sections "*%section5%" --download-sections "*%section6%" --download-sections "*%section7%"
) ELSE (IF "%DoSections%"=="8" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%" --download-sections "*%section3%" --download-sections "*%section4%" --download-sections "*%section5%" --download-sections "*%section6%" --download-sections "*%section7%" --download-sections "*%section8%"
) ELSE (IF "%DoSections%"=="9" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%" --download-sections "*%section3%" --download-sections "*%section4%" --download-sections "*%section5%" --download-sections "*%section6%" --download-sections "*%section7%" --download-sections "*%section8%" --download-sections "*%section9%"
) ELSE (IF "%DoSections%"=="10" (
SET       Select= --download-sections "*%section1%" --download-sections "*%section2%" --download-sections "*%section3%" --download-sections "*%section4%" --download-sections "*%section5%" --download-sections "*%section6%" --download-sections "*%section7%" --download-sections "*%section8%" --download-sections "*%section9%" --download-sections "*%section10%"
))))))))))
IF DEFINED usearia (
SET     Download= --limit-rate %SPEED_LIMIT% --downloader "%ARIA2_PATH%" --downloader-args "aria2c: %ARIA_ARGS%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SPEED_LIMIT% --concurrent-fragments %THREADS%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --cache-dir "%YTDLP_CACHE_DIR%" --no-mtime --ffmpeg-location "%FFMPEG_PATH%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFMPEG_THUMB_FORMAT% -q:v %THUMB_COMPRESS% -vf crop=\"'if^^^(gt^^^(ih,iw^^^),iw,ih^^^)':'if^^^(gt^^^(iw,ih^^^),ih,iw^^^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %THUMB_FORMAT% --postprocessor-args "ThumbnailsConvertor:-q:v %THUMB_COMPRESS%"
)
SET    Verbosity= --color always --console-title --progress --progress-template ["download] [Progress":" %%(progress._percent_str)s, Speed: %%(progress._speed_str)s, Elapsed: %%(progress._elapsed_str)s, Time Remaining: %%(progress._eta_str|0)s/s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249"
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --extract-audio --format "141/38/22/140/37/59/34/35/59/78/18"
) ELSE (IF "%CustomFormat-ogg%"=="1" (
SET       Format= --extract-audio --format "46/45/44/43"
) ELSE (IF "%CustomFormat-mp3%"=="1" (
SET       Format= --extract-audio --format "ba[acodec^=mp3]/b"
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --extract-audio --format "338/774/251/250/249"
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18"
) ELSE (IF "%CustomFormat-m4a%"=="4" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1 -af \"compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="3" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -threads 0 -b:a %AUDIO_BITRATE%k -c:a libopus -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="4" (
SET       Format= --extract-audio --format "bestaudio[acodec^=opus]/bestaudio[container*=dash]/bestaudio"
) ELSE (IF "%CustomFormat-m4a%"=="5" (
SET       Format= --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -threads 0 -ar %AUDIO_SAMPLING_RATE% -c:a libfdk_aac -vbr %AudioQuality% -cutoff %CUTOFF% -afterburner 1 -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="6" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -ac 2 -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="7" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -ac 2 -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1 -af \"compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="8" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -y -vn -c:a aac_at %aac-at-param-1% %aac-at-param-2% %aac-at-param-3% %aac-at-param-4% %aac-at-param-5% -cutoff %CUTOFF% -afterburner 1 -af \"pan=stereo^^^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^^^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=attacks=0:points=-80/-169 -54/-80 -49.5/-64.6 -41.1/-41.1 -25.8/-15 -10.8/-4.5 0/0 20/8.3,firequalizer=gain='cubic_interpolate(f)':delay=0.027:accuracy=1:wfunc=hann:gain_entry='entry^^^(31,%VOLUME_GAIN%^^^);entry^^^(40,%VOLUME_GAIN%^^^);entry^^^(41,%VOLUME_GAIN%^^^);entry^^^(50,%VOLUME_GAIN%^^^);entry^^^(100,%VOLUME_GAIN%^^^);entry^^^(200,%VOLUME_GAIN%^^^);entry^^^(392,%VOLUME_GAIN%^^^);entry^^^(523,%VOLUME_GAIN%^^^)':scale=linlog,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:stop_threshold=-%SILENCE_THRESHOLD%dB:detection=peak:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%BestAudio%"=="1" (
SET       Format= --extract-audio --format "773/338/258/328/774/327/256/141/251/22/140/38/37/35/34/59/78/18/250/46/45/44/43"
) ELSE (IF "%SectionsAudio%"=="1" (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
) ELSE (IF "%CustomFormatVideo%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv
) ELSE (IF "%CustomFormatVideo%"=="2" (
SET       Format= -S "+size,+br,+res,+fps" --merge-output-format mkv
) ELSE (IF "%CustomFormatVideo%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv
) ELSE (IF "%CustomCodec%"=="avc" (
SET       Format= --format "(bestvideo[vcodec~='^((he|a)vc|h26[45])'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4]) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mp4 --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="vp9" (
SET       Format= --format "(bestvideo[vcodec~='(vp9.2|vp09|vp9)'][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo) + (bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mkv --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%CustomCodec%"=="av1" (
SET       Format= --format "(bestvideo[vcodec^=av01][height<=%VideoResolution%][fps<=%VideoFPS%]/bestvideo[ext=mp4])+(bestaudio[acodec=opus]/bestaudio[container*=dash]/bestaudio) / best[height<=%VideoResolution%][fps<=%VideoFPS%]/best" --merge-output-format mp4 --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
) ELSE (IF "%SectionsVideo%"=="1" (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --postprocessor-args "Merger:-threads 0 -vcodec copy -b:a %AUDIO_BITRATE%k -ar %AUDIO_SAMPLING_RATE% -acodec %ENCODER% -cutoff %CUTOFF%"
)))))))))))))))))))))))
SET     Subtitle=
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%COOKIES_PATH%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
IF "%SectionsVideo%"=="1" (
SET  PostProcess= --no-keep-video --embed-metadata --compat-options no-attach-info-json --force-keyframes-at-cuts
) ELSE (
SET  PostProcess= --no-keep-video --embed-metadata --compat-options no-attach-info-json
)
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Stream=& SET Downloaded-Sections=1& SET Downloaded-Quick=& GOTO :doYTDL-sections

::
::
:: DOWNLOADER
::
::

:doYTDL-check
SET doYTDL=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Magenta-s%•%ColorOff%  Check Parameters:
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-n%›%ColorOff%  Output:%OutTemplate%
ECHO   %Green-n%›%ColorOff%  Options:%Options%
ECHO   %Green-n%›%ColorOff%  Network:%Network%
ECHO   %Green-n%›%ColorOff%  GeoRestrict:%GeoRestrict%
ECHO   %Green-n%›%ColorOff%  Select:%Select%
ECHO   %Green-n%›%ColorOff%  Download:%Download%
ECHO   %Green-n%›%ColorOff%  Sponsorblock:%Sponsorblock%
ECHO   %Green-n%›%ColorOff%  FileSystem:%FileSystem%
ECHO   %Green-n%›%ColorOff%  Thumbnail:%Thumbnail%
ECHO   %Green-n%›%ColorOff%  Verbosity:%Verbosity%
ECHO   %Green-n%›%ColorOff%  WorkArounds:%WorkArounds%
ECHO   %Green-n%›%ColorOff%  Format:%Format%
ECHO   %Green-n%›%ColorOff%  Subtitle:%Subtitle%
ECHO   %Green-n%›%ColorOff%  Comments:%Comments%
ECHO   %Green-n%›%ColorOff%  Authenticate:%Authenticate%
ECHO   %Green-n%›%ColorOff%  AdobePass:%AdobePass%
ECHO   %Green-n%›%ColorOff%  PreProcess:%PreProcess%
ECHO   %Green-n%›%ColorOff%  PostProcess:%PostProcess%
IF DEFINED ReplayGain (
ECHO   %Green-s%›%ColorOff%  ReplayGain:%ReplayGain%
)
IF DEFINED duration_filter (
ECHO   %Green-s%›%ColorOff%  Duration:%Duration%
)
IF DEFINED date_filter (
ECHO   %Green-s%›%ColorOff%  Date:%Date_Filter%
)
IF "%DownloadList%"=="1" (
ECHO   %Green-n%›%ColorOff%  URLs List: "%Underline%%URL%%ColorOff%"
) ELSE (
ECHO   %Green-n%›%ColorOff%  URL: "%Underline%%URL%%ColorOff%"
)
ECHO.
:: test solution to reset without script quiting
SET /P doYTDL=%BS%  'Enter' to download or type 'r' to return to Main Menu: 
IF NOT DEFINED doYTDL GOTO :doYTDL
IF "!doYTDL!"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET BestAudio=& SET aac-at-param-1=& SET aac-at-param-2=& SET aac-at-param-3=& SET aac-at-param-4=& SET aac-at-param-5=& SET CustomCodec=& SET Downloaded-Playlist=& SET ALBUM=& SET doYTDL=& GOTO :start
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :doYTDL-check

:doYTDL
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
:: another test solution to print error messages after big downloads
:: 10 hours. finally sending only errors and warnings to pipe
:: now we can collect errors with timestamps
IF "%DownloadList%"=="1" (
"%YTDLP_PATH%"%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess%%ReplayGain%%Duration%%Date_Filter% 3>&1 1>&2 2>&3 | "%MOREUTILS_PATH%" ts "[%%T]" >"%LOG_PATH%"
) ELSE (
"%YTDLP_PATH%"%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess%%ReplayGain%%Duration%%Date_Filter% "%URL%" 3>&1 1>&2 2>&3 | "%MOREUTILS_PATH%" ts "[%%T]" >"%LOG_PATH%"
)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  COLLECTED ERRORS
ECHO ------------------------------------------------------------------------------------------------------------------------
FOR /f "delims=" %%j IN ('type "%LOG_PATH%"') DO ECHO %%j
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done. Press any key.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :continue

:doYTDL-stream
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Magenta-s%•%ColorOff%  Check Parameters:
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-n%›%ColorOff%  Output:%OutTemplate%
ECHO   %Green-n%›%ColorOff%  Options:%Options%
ECHO   %Green-n%›%ColorOff%  Network:%Network%
ECHO   %Green-n%›%ColorOff%  GeoRestrict:%GeoRestrict%
ECHO   %Green-n%›%ColorOff%  Select:%Select%
ECHO   %Green-n%›%ColorOff%  Download:%Download%
ECHO   %Green-n%›%ColorOff%  Sponsorblock:%Sponsorblock%
ECHO   %Green-n%›%ColorOff%  FileSystem:%FileSystem%
ECHO   %Green-n%›%ColorOff%  Thumbnail:%Thumbnail%
ECHO   %Green-n%›%ColorOff%  Verbosity:%Verbosity%
ECHO   %Green-n%›%ColorOff%  WorkArounds:%WorkArounds%
ECHO   %Green-n%›%ColorOff%  Format:%Format%
ECHO   %Green-n%›%ColorOff%  Subtitle:%Subtitle%
ECHO   %Green-n%›%ColorOff%  Comments:%Comments%
ECHO   %Green-n%›%ColorOff%  Authenticate:%Authenticate%
ECHO   %Green-n%›%ColorOff%  AdobePass:%AdobePass%
ECHO   %Green-n%›%ColorOff%  PreProcess:%PreProcess%
ECHO   %Green-n%›%ColorOff%  PostProcess:%PostProcess%
ECHO   %Green-n%›%ColorOff%  URL: "%Underline%%URL%%ColorOff%"
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  STREAMING...
ECHO ------------------------------------------------------------------------------------------------------------------------
IF DEFINED StreamVideoFormat (
"%YTDLP_PATH%"%Options%%Network%%GeoRestrict%%Select%%Sponsorblock%%Thumbnail%%Verbosity%%WorkArounds%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess%%FileSystem%%OutTemplate%%Download%%Format% "%URL%"| "%VIDEO_PLAYER_PATH%" -
) ELSE (IF DEFINED StreamAudioFormat (
"%YTDLP_PATH%"%Options%%Network%%GeoRestrict%%Select%%Sponsorblock%%Thumbnail%%Verbosity%%WorkArounds%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess%%FileSystem%%OutTemplate%%Download%%Format% "%URL%"| "%AUDIO_PLAYER_PATH%" -
))
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done. Press any key.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :continue

:doYTDL-sections
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Magenta-s%•%ColorOff%  Check Parameters:
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-n%›%ColorOff%  Output:%OutTemplate%
ECHO   %Green-n%›%ColorOff%  Options:%Options%
ECHO   %Green-n%›%ColorOff%  Network:%Network%
ECHO   %Green-n%›%ColorOff%  GeoRestrict:%GeoRestrict%
ECHO   %Green-n%›%ColorOff%  Select:%Select%
ECHO   %Green-n%›%ColorOff%  Download:%Download%
ECHO   %Green-n%›%ColorOff%  Sponsorblock:%Sponsorblock%
ECHO   %Green-n%›%ColorOff%  FileSystem:%FileSystem%
ECHO   %Green-n%›%ColorOff%  Thumbnail:%Thumbnail%
ECHO   %Green-n%›%ColorOff%  Verbosity:%Verbosity%
ECHO   %Green-n%›%ColorOff%  WorkArounds:%WorkArounds%
ECHO   %Green-n%›%ColorOff%  Format:%Format%
ECHO   %Green-n%›%ColorOff%  Subtitle:%Subtitle%
ECHO   %Green-n%›%ColorOff%  Comments:%Comments%
ECHO   %Green-n%›%ColorOff%  Authenticate:%Authenticate%
ECHO   %Green-n%›%ColorOff%  AdobePass:%AdobePass%
ECHO   %Green-n%›%ColorOff%  PreProcess:%PreProcess%
ECHO   %Green-n%›%ColorOff%  PostProcess:%PostProcess%
ECHO   %Green-n%›%ColorOff%  URL: "%Underline%%URL%%ColorOff%"
ECHO.
PAUSE
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%"%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%URL%" 3>&1 1>&2 2>&3 | "%MOREUTILS_PATH%" ts "[%%T]" >"%LOG_PATH%"
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  COLLECTED ERRORS
ECHO ------------------------------------------------------------------------------------------------------------------------
FOR /f "delims=" %%j IN ('type "%LOG_PATH%"') DO ECHO %%j
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done. Press any key.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :continue

:doYTDL-quick
cls
IF "%Downloaded-Quick%"=="1" (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%"%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%URL%" 3>&1 1>&2 2>&3 | "%MOREUTILS_PATH%" ts "[%%T]" >"%LOG_PATH%"
SET clipboard=
SET Downloaded-Quick=1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  COLLECTED ERRORS
ECHO ------------------------------------------------------------------------------------------------------------------------
FOR /f "delims=" %%j IN ('type "%LOG_PATH%"') DO ECHO %%j
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done. Press any key.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :continue
) ELSE (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Magenta-s%•%ColorOff%  Check Parameters:
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-n%›%ColorOff%  Output:%OutTemplate%
ECHO   %Green-n%›%ColorOff%  Options:%Options%
ECHO   %Green-n%›%ColorOff%  Network:%Network%
ECHO   %Green-n%›%ColorOff%  GeoRestrict:%GeoRestrict%
ECHO   %Green-n%›%ColorOff%  Select:%Select%
ECHO   %Green-n%›%ColorOff%  Download:%Download%
ECHO   %Green-n%›%ColorOff%  Sponsorblock:%Sponsorblock%
ECHO   %Green-n%›%ColorOff%  FileSystem:%FileSystem%
ECHO   %Green-n%›%ColorOff%  Thumbnail:%Thumbnail%
ECHO   %Green-n%›%ColorOff%  Verbosity:%Verbosity%
ECHO   %Green-n%›%ColorOff%  WorkArounds:%WorkArounds%
ECHO   %Green-n%›%ColorOff%  Format:%Format%
ECHO   %Green-n%›%ColorOff%  Subtitle:%Subtitle%
ECHO   %Green-n%›%ColorOff%  Comments:%Comments%
ECHO   %Green-n%›%ColorOff%  Authenticate:%Authenticate%
ECHO   %Green-n%›%ColorOff%  AdobePass:%AdobePass%
ECHO   %Green-n%›%ColorOff%  PreProcess:%PreProcess%
ECHO   %Green-n%›%ColorOff%  PostProcess:%PostProcess%
ECHO   %Green-n%›%ColorOff%  URL: "%Underline%%URL%%ColorOff%"
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%"%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%URL%" 3>&1 1>&2 2>&3 | "%MOREUTILS_PATH%" ts "[%%T]" >"%LOG_PATH%"
SET clipboard=
SET Downloaded-Quick=1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  COLLECTED ERRORS
ECHO ------------------------------------------------------------------------------------------------------------------------
FOR /f "delims=" %%j IN ('type "%LOG_PATH%"') DO ECHO %%j
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done. Press any key.
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
GOTO :continue
)

::
::
:: DRAGGED URLs/LISTs DOWNLOADER
::
::

:doYTDL-drag url[.txt] [...]
:: exit if no parameters, display commandline, call yt-dlp
IF ""=="%~1" EXIT /B 0
IF "%Downloaded-Drag%"=="1" (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%"%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%*" 3>&1 1>&2 2>&3 | "%MOREUTILS_PATH%" ts "[%%T]" >>"%LOG_PATH%"
IF %APP_ERR% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Cyan-s%%APP_ERR%%ColorOff%.
SET Downloaded-Drag=1
timeout /t 2 >nul
EXIT /B 0
) ELSE (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Magenta-s%•%ColorOff%  Check Parameters:
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-n%›%ColorOff%  Output:%OutTemplate%
ECHO   %Green-n%›%ColorOff%  Options:%Options%
ECHO   %Green-n%›%ColorOff%  Network:%Network%
ECHO   %Green-n%›%ColorOff%  GeoRestrict:%GeoRestrict%
ECHO   %Green-n%›%ColorOff%  Select:%Select%
ECHO   %Green-n%›%ColorOff%  Download:%Download%
ECHO   %Green-n%›%ColorOff%  Sponsorblock:%Sponsorblock%
ECHO   %Green-n%›%ColorOff%  FileSystem:%FileSystem%
ECHO   %Green-n%›%ColorOff%  Thumbnail:%Thumbnail%
ECHO   %Green-n%›%ColorOff%  Verbosity:%Verbosity%
ECHO   %Green-n%›%ColorOff%  WorkArounds:%WorkArounds%
ECHO   %Green-n%›%ColorOff%  Format:%Format%
ECHO   %Green-n%›%ColorOff%  Subtitle:%Subtitle%
ECHO   %Green-n%›%ColorOff%  Comments:%Comments%
ECHO   %Green-n%›%ColorOff%  Authenticate:%Authenticate%
ECHO   %Green-n%›%ColorOff%  AdobePass:%AdobePass%
ECHO   %Green-n%›%ColorOff%  PreProcess:%PreProcess%
ECHO   %Green-n%›%ColorOff%  PostProcess:%PostProcess%
ECHO   %Green-n%›%ColorOff%  URL: %Underline%%*%ColorOff%
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Press any key to continue
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE >nul
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTDLP_PATH%"%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%*" 3>&1 1>&2 2>&3 | "%MOREUTILS_PATH%" ts "[%%T]" >>"%LOG_PATH%"
IF %APP_ERR% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Cyan-s%%APP_ERR%%ColorOff%.
SET Downloaded-Drag=1
timeout /t 2 >nul
EXIT /B 0
)
