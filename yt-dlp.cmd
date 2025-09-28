:: yt-dlp.cmd [url[.txt]] [...]
:: v0.1 2021/01/09 CirothUngol
:: https://www.reddit.com/r/youtubedl/comments/kws98p/simple_batchfile_for_using_youtubedlexe_with
::
:: for drag'n'drop function any combination of URLs
:: and text files may be used. text files are found 
:: and processed first, then all URLs.
::
:: v1.6 28.09.2025 Lichtenshtein

:: to convert comments to readable HTML python needs to be installed
:: then you may also need to install "pip install json2html"

:: recomended ffmpeg static build with nonfree codecs
:: https://github.com/AnimMouse/ffmpeg-stable-autobuild

@ECHO OFF

setlocal ENABLEDELAYEDEXPANSION
:: endlocal


:: set terminal size (scrolling won't work without walkarouds)
:: MODE con: cols=120 lines=53
:: set the screen buffer size to enable scrolling (this is walkaroud for scrolling)
:: powershell -command "&{$H=get-host;$W=$H.ui.rawui;$B=$W.buffersize;$B.width=120;$B.height=9999;$W.buffersize=$B;}"
:: set terminal color, and codepage to unicode (65001=UTF-8)
color 0f
CHCP 65001 >NUL

:: 
::                ...---......
::               .........-.---..
::              ...........-.-----.
::            ..--.......-----------
::            ............----------.
::               .-...-.......-------.
::                . ..-.....----------.
::                   .---..     -------..
::          .--.     ---      --.------..
::           .      .---.   .------------.
::                 .-----.....---------...
::                  .------....--------..
::                  .. .-....----------..
::                  ..  .-. .----------.-..
::                    ...-- ..--------..--.
::                   ..-----. -----------..
::                    ..-----..----------.
::                .-----....-- .---------
::                     .--     .--------.
::                 .           .--------
::       -       .-....-.  ..  -------
::       .      . ..---.  .-.  -------
::               ....---.---. .-------
::                  ...-----..--------
::                ..-------.---------.
::                 .-----.-----------
::        ..-.     ..---.------------.
::        ..--..     ...----------------...
::         .....    ....------------------.. ----.
::  . .      ..     ...---------------------.----------.
::  .....           .----------------..----------------------.
::   ..----.       ...-.------------..----------------------------.
::   ..------.    ...--------------.....------------------------------.
::    ..-----   ..---------------. ....-..-.---.. ..---------------------
::   ...--         --------------  ..............-....   ..----------------
:: 
:: -------.-    .----------            -               .--------  -   .-------------
:: --      --.     ----   -----        --.            ----       .--    .----      --
:: ---.      ..     ----    ----       ----          -----          -    .----       .
:: ------           ----    ----      ------        .----                .----   -
::  --------        ----   ----      -. -----       -----                .----  --
::    --------.     --------        .-   -----      -----                .---- ---
::  	 .-----     ----            -    .-----     -----                .----   -
:: -        ----    ----           -      .----      -----               .----        -
:: --       .--     ----          -.       -----      ----.        --    .----       --
:: ----....---     ------       .---        -----.      ------..---      --------------
:: set /F needs some spaces
FOR /F %%a in ('echo prompt $H ^| cmd') DO SET "BS=%%a"
SET "n=2"
SET "spcs="
FOR /L %%i in (1,1,%n%) DO SET "spcs=!spcs! "
SET "=X!BS!%spcs%"

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
:: SET "PATH=%PATH%;B:\phantomjs;B:\rsgain;B:\aacgain;B:\vorbisgain;B:\mp3gain;"

:: set target folder and exe locations
SET    TargetFolder=B:\Downloads
SET    YTdlp-Folder=B:\yt-dlp
SET    Archive-Path=%YTdlp-Folder%\archive.txt
SET      YTdlp-Path=%YTdlp-Folder%\yt-dlp.exe
SET    Cookies-Path=%YTdlp-Folder%\cookies.txt
SET       List-Path=%YTdlp-Folder%\download.list
SET     FFmpeg-Path=B:\FFmpeg\ffmpeg.exe
SET     Python-Path=B:\Python\python.exe
:: SET      Paste-Path=B:\paste\paste.exe
SET   A-Player-Path=B:\Aimp\aimp.exe
SET   V-Player-Path=B:\PotPlayer\PotPlayer.exe
SET  	   Aria2-Path=B:\aria2c\aria2c.exe
SET        Sed-Path=B:\git-for-windows\usr\bin\sed.exe
SET         tr-Path=B:\git-for-windows\usr\bin\tr.exe
SET   truncate-Path=B:\git-for-windows\usr\bin\truncate.exe
SET       head-Path=B:\git-for-windows\usr\bin\head.exe
:: we will be getting clipboard content using Windows mshta instead of 'paste'
SET           mshta=mshta "javascript:var x=clipboardData.getData('text');if(x) new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(x);close();"
:: set aria args
SET       Aria-Args=--conf-path="B:\aria2c\aria2.conf"
:: sed special commands file
SET    Sed-Commands=%YTdlp-Folder%\sed.commands
:: set yt-dlp common options
SET          SpeedLimit=8096K
SET             Threads=3
SET        Thumb-Format=jpg
SET FFmpeg-Thumb-Format=mjpeg
SET      Thumb-Compress=3
SET           Sub-langs=en,en-en,ru,-live_chat
SET          Sub-Format=srt/vtt/ass/best
SET          User-Agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0
SET     YTdlp-Cache-Dir=%TEMP%\yt-dlp
SET    Sponsorblock-Api=https://sponsor.ajay.app
:: plugins settings
SET	  Chapters-Path=%YTdlp-Folder%\chapters.txt
:: if defined will create folders for each text list entered
SET 	MakeListDir=
:: capture errorlevel and display warning if non-zero for yt-dlp
SET	appErr=%ERRORLEVEL%

:: set yt-dlp.exe commandline options, all options MUST begin with a space
:: name shorthand: %~d0=D:,%~p0=\path\to\,%~n0=name,%~x0=.ext,%~f0=%~dpnx0
:: remember to double percentage signs when used as output in batch files

::
::
:: DRAG AND DROP PRESET
::
::

:: DRAG AND DROP DEFAULT PRESET
SET  OutTemplate= --output "%TargetFolder%\%%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview --sponsorblock-api "%Sponsorblock-Api%"
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
SET       Format= --format "bestvideo[height<=480][ext=mp4]+bestaudio/best" -S "fps:30,channels:2"
SET     Subtitle= --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json

::
::
:: DRAG AND DROP LINKS TO BAT FUNCTIONS
::
::

:: capture commandline, add batch folder to path, create and enter target
SET source=%*
CALL SET "PATH=%~dp0;%%PATH:%~dp0;=%%"
MD "%TargetFolder%" >NUL 2>&1
PUSHD "%TargetFolder%"

:getURL-drag -- main loop
cls
:: if no drag and drop files - go to menu
if "%~1"=="" GOTO :getURL
:: prompt for source, exit if empty, call routines, loop
IF NOT DEFINED source (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=!BS!%spcs%%Green-n%›%ColorOff%  
)
IF NOT DEFINED source POPD & EXIT /B %appErr%
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
IF DEFINED MakeListDir MD "%TargetFolder%\%~n1" >NUL 2>&1
IF DEFINED MakeListDir PUSHD "%TargetFolder%\%~n1"
:: clean a .URL file from innapropriate lines 
:: drag link from browser to disk to download .URL
%Sed-Path% -i -e '/InternetShortcut/d';'s/URL=//g';'s/^&.*//' %1 & %truncate-path% -s -1 %1 >NUL 2>&1
FOR /F "usebackq tokens=*" %%A IN ("%~1") DO CALL :doYTDL-drag "%%~A"
:: return to target folder, left-shift parameters, and loop
IF DEFINED MakeListDir POPD
SHIFT
GOTO :getLST-drag

:getURL
:: man, this is just dirty...
:: get clipboard content
:: try deleting double quotes because script will crash before it even starts
%mshta% > %TargetFolder%\clipboard.tmp
%Sed-Path% -i -e "s/\"//g";"s/\"$//g" %TargetFolder%\clipboard.tmp
SET /p "clipboard=" < %TargetFolder%\clipboard.tmp
del /q %TargetFolder%\clipboard.tmp 2> nul
:: check if clipboard content is a link
:: quote it because echo doesn't like & and other symbols 
ECHO "%clipboard%" | findstr /R /C:"^.https://.*">NUL 2>&1
:: delete & and everything after (may break links). mostly ok for youtube.
:: something that deletes double quotes (ok when done that way, otherwise crashes when piped).
:: delete spaces. delete newline symbol that sed brings every time.
:: copy link back to clipboard.
if %errorlevel% equ 0 (
ECHO "%clipboard%" | %Sed-Path% -e 's/^&.*//';'s/\"//g';'s/\"$//g';'s/[ \t]*$//' | %tr-Path% -d "\n" | clip >NUL 2>&1
FOR /f "tokens=* delims=" %%c IN ('%mshta%') DO SET clipboard=%%c
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE URL ^(or enter "q" to quick-download URL from clipboard^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=!BS!%spcs%%Green-n%›%ColorOff%  
IF NOT DEFINED URL EXIT /B %appErr%
IF "!URL!"=="q" (SET URL=!clipboard!& GOTO :doYTDL-quick) ELSE (GOTO :start)
) else (
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE URL
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=!BS!%spcs%%Green-n%›%ColorOff%  
IF NOT DEFINED URL EXIT /B %appErr%
GOTO :start)

:start
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  MENU
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Download Audio
ECHO   %Cyan-s%2%ColorOff%. Download Video
ECHO   %Cyan-s%3%ColorOff%. Download Manually
ECHO   %Cyan-s%4%ColorOff%. Download Subtitles Only
ECHO   %Cyan-s%5%ColorOff%. Download Comments Only
ECHO   %Cyan-s%6%ColorOff%. Download Section
ECHO   %Cyan-s%7%ColorOff%. Stream to Player
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%e%ColorOff%. Enter URL		%Yellow-s%t%ColorOff%. Set Duration Filter
ECHO   %Yellow-s%w%ColorOff%. Set Downloader	%Yellow-s%d%ColorOff%. Set Date Filter
ECHO   %Yellow-s%c%ColorOff%. Set Cookies	%Yellow-s%v%ColorOff%. Version Info
ECHO   %Yellow-s%p%ColorOff%. Set Plugins	%Yellow-s%u%ColorOff%. Update
ECHO   %Red-s%q%ColorOff%. Exit		%Yellow-s%x%ColorOff%. Error Info
ECHO.
SET /p choice=!BS!%spcs%Enter Your Choice: 
IF "%choice%"=="1" GOTO :select-format-audio
IF "%choice%"=="2" GOTO :select-format-video
IF "%choice%"=="3" GOTO :select-format-manual
IF "%choice%"=="4" GOTO :select-preset-subs
IF "%choice%"=="5" GOTO :select-preset-comments
IF "%choice%"=="6" GOTO :select-preset-sections
IF "%choice%"=="7" GOTO :select-format-stream
IF "%choice%"=="e" GOTO :getURL-re-enter
IF "%choice%"=="v" GOTO :info
IF "%choice%"=="x" GOTO :error-info
IF "%choice%"=="t" GOTO :set-duration-filter
IF "%choice%"=="d" GOTO :set-date-filter
IF "%choice%"=="u" GOTO :update
IF "%choice%"=="c" GOTO :cookies
IF "%choice%"=="p" GOTO :plugins
IF "%choice%"=="w" GOTO :aria
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :start

:getURL-re-enter
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE URL
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=!BS!%spcs%%Green-n%›%ColorOff%  
IF NOT DEFINED URL EXIT /B %appErr%
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

:getURL-continue
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  ENTER SOURCE URL
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P URL=!BS!%spcs%%Green-n%›%ColorOff%  
IF NOT DEFINED URL EXIT /B %appErr%
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

:aria
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  DOWNLOADER
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Yes
ECHO   %Cyan-s%2%ColorOff%. No
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p usearia=!BS!%spcs%Use aria2c as External Downloader? 
IF "%usearia%"=="1" GOTO :start
IF "!usearia!"=="2" SET !usearia!=& GOTO :start
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
SET /p usecookies=!BS!%spcs%Use cookies.txt? 
IF "%usecookies%"=="1" GOTO :start
IF "!usecookies!"=="2" SET !usecookies!=& GOTO :start
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
SET /p choice=!BS!%spcs%Which Plugin to Enable? 
IF "%choice%"=="1" GOTO :plugin-1
IF "%choice%"=="2" GOTO :plugin-2
IF "%choice%"=="3" GOTO :plugin-3
IF "%choice%"=="4" GOTO :plugin-4
IF "%choice%"=="w" GOTO :start
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
SET /p use_pl_srtfixer=!BS!%spcs%Enable SRT_fixer Plugin? 
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
SET /p use_pl_replaygain=!BS!%spcs%Enable ReplayGain Plugin? 
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
SET /p use_pl_customchapters=!BS!%spcs%Enable CustomChapters Plugin? 
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
SET /p use_pl_returnyoutubedislike=!BS!%spcs%Enable ReturnYoutubeDislike Plugin? 
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
%YTdlp-Path% -v
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  OK
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE 2 >nul
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
ECHO   %Green-s%•%ColorOff%  OK
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE 2 >nul
GOTO :start

:update
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  UPDATING...
ECHO ------------------------------------------------------------------------------------------------------------------------
%YTdlp-Path% -U
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Continue
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
GOTO :start

:continue
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  CONTINUE
ECHO ------------------------------------------------------------------------------------------------------------------------
:: meant for download another link with same params
ECHO   %Cyan-s%1%ColorOff%. Download Another?
:: meant to retry failed download with same params (in case if link is invalid)
ECHO   %Cyan-s%2%ColorOff%. Retry
:: resets all variables
ECHO   %Cyan-s%3%ColorOff%. Main Menu
ECHO ------------------------------------------------------------------------------------------------------------------------
:: re-enter link to retry the download
ECHO   %Yellow-s%e%ColorOff%. Re-Enter URL
:: this seems useless here, params won't change from within this menu
REM ECHO   %Yellow-s%w%ColorOff%. Set Downloader
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Exit? 
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
IF "%choice%"=="3" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& GOTO :start
IF "%choice%"=="e" GOTO :getURL-re-enter
REM IF "%choice%"=="w" GOTO :aria
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :continue

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
%YTdlp-Path% --list-formats --no-playlist --simulate --extractor-args "youtube:player_client=mweb" --ffmpeg-location "%FFmpeg-Path%" "%URL%"
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
GOTO :selection

:selection
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Video + Audio		%Yellow-s%w%ColorOff%. Go Back
ECHO   %Cyan-s%2%ColorOff%. Audio Only / Video Only	%Red-s%q%ColorOff%. Exit
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P choice=!BS!%spcs%Select Option: 
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
SET /P video=!BS!%spcs%Select Video Format: 
SET /P audio=!BS!%spcs%Select Audio Format: 
GOTO :download-manual

:download-manual
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
%YTdlp-Path% --concurrent-fragments %Threads% --ffmpeg-location "%FFmpeg-Path%" --output "%TargetFolder%\%%(title)s.%%(ext)s" -f "%video%+%audio%" -i --ignore-config%Download% "%URL%"
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
IF "%appErr%"=="1" ECHO   %Red-s%•%ColorOff%  Try re-entering correct format. & GOTO :selection-manual
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=1& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Stream=& SET Downloaded-Sections=& SET Downloaded-Quick=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
GOTO :continue

:selection-manual-single
SET /P format=!BS!%spcs%Select Format: 
GOTO :download-manual-single

:download-manual-single
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
%YTdlp-Path% --concurrent-fragments %Threads% --ffmpeg-location "%FFmpeg-Path%" --output "%TargetFolder%\%%(title)s.%%(ext)s" -f "%format%" -i --ignore-config%Download% "%URL%"
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
IF "%appErr%"=="1" ECHO   %Red-s%•%ColorOff%  Try re-entering correct format. & GOTO :selection-manual-single
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=1& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Stream=& SET Downloaded-Sections=& SET Downloaded-Quick=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
GOTO :continue

::
::
:: AUDIO MENU PART
::
::

:select-format-audio
SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-opus=& SET CustomFormat-ogg=& SET CustomFormatAudio=
SET Downloaded-Audio=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO FORMAT
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Convert → m4a	%Cyan-s%10%ColorOff%. Convert → m4a ^(libfdk/VBR^)	%Cyan-s%13%ColorOff%. Convert → m4a ^(libfdk/VBR/filter^) 
ECHO   %Cyan-s%2%ColorOff%. Convert → mp3
ECHO   %Cyan-s%3%ColorOff%. Convert → opus
ECHO   %Cyan-s%4%ColorOff%. Convert → aac
ECHO   %Cyan-s%5%ColorOff%. Convert → ogg
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%6%ColorOff%. Extract opus	%Cyan-s%11%ColorOff%. Extract opus ^(up to 4.0^) 	%Cyan-s%14%ColorOff%. Extract opus ^(up to 4.0^) + ^(downmix to 2.0/148k/filter^)
ECHO   %Cyan-s%7%ColorOff%. Extract mp4a	%Cyan-s%12%ColorOff%. Extract mp4a ^(up to 5.1^)	%Cyan-s%15%ColorOff%. Extract mp4a ^(up to 5.1^) + ^(downmix to 2.0/VBR/filter^)
ECHO   %Cyan-s%8%ColorOff%. Extract vorbis
ECHO   %Cyan-s%9%ColorOff%. Extract mp3
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Audio Format: 
IF "%choice%"=="1" SET AudioFormat=m4a& GOTO :select-quality-audio
IF "%choice%"=="2" SET AudioFormat=mp3& GOTO :select-quality-audio
IF "%choice%"=="3" SET AudioFormat=opus& GOTO :select-quality-audio
IF "%choice%"=="4" SET AudioFormat=aac& GOTO :select-quality-audio
IF "%choice%"=="5" SET AudioFormat=vorbis& GOTO :select-quality-audio
IF "%choice%"=="6" SET CustomFormatAudio=1& SET CustomFormat-opus=1& SET AudioFormat=opus& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="7" SET CustomFormatAudio=1& SET CustomFormat-m4a=1& SET AudioFormat=m4a& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="8" SET CustomFormatAudio=1& SET CustomFormat-ogg=1& SET AudioFormat=vorbis& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="9" SET CustomFormatAudio=1& SET CustomFormat-mp3=1& SET AudioFormat=mp3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="10" SET CustomFormat-m4a=2& SET AudioFormat=m4a& GOTO :select-quality-vbr-audio
IF "%choice%"=="11" SET CustomFormatAudio=1& SET CustomFormat-opus=2& SET AudioFormat=opus& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="12" SET CustomFormatAudio=1& SET CustomFormat-m4a=3& SET AudioFormat=m4a& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="13" SET CustomFormat-m4a=4& SET AudioFormat=m4a& GOTO :select-quality-vbr-audio
IF "%choice%"=="14" SET CustomFormatAudio=1& SET CustomFormat-opus=3& SET AudioFormat=opus& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="15" SET CustomFormat-m4a=5& SET AudioFormat=m4a& GOTO :select-quality-vbr-audio
IF "%choice%"=="w" IF "%SectionsAudio%"=="1" (GOTO :select-preset-sections) ELSE (IF "%SectionsAudio%"=="2" (GOTO :select-preset-sections) ELSE (GOTO :start))
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-format-audio

:select-quality-audio
SET quality_libfdk=& SET quality_simple=
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
SET /p choice=!BS!%spcs%Select Audio Quality: 
IF "%choice%"=="1" SET quality_simple=1& SET AudioQuality=1& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="2" SET quality_simple=1& SET AudioQuality=2& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="3" SET quality_simple=1& SET AudioQuality=3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="4" SET quality_simple=1& SET AudioQuality=4& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="5" SET quality_simple=1& SET AudioQuality=5& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="6" SET quality_simple=1& SET AudioQuality=6& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="7" SET quality_simple=1& SET AudioQuality=7& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="8" SET quality_simple=1& SET AudioQuality=8& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="9" SET quality_simple=1& SET AudioQuality=9& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="10" SET quality_simple=1& SET AudioQuality=10& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="11" IF "%AudioFormat%"=="mp3" (SET quality_simple=1& SET AudioQuality=320k& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))) ELSE (SET quality_simple=1& SET AudioQuality=0& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio)))
IF "%choice%"=="w" GOTO :select-format-audio
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-quality-audio

:select-quality-vbr-audio
SET quality_libfdk=& SET quality_simple=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO VBR QUALITY
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
SET /p choice=!BS!%spcs%Select Audio Quality: 
IF "%choice%"=="1" SET quality_libfdk=1& SET AudioQuality=1& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="2" SET quality_libfdk=1& SET AudioQuality=2& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="3" SET quality_libfdk=1& SET AudioQuality=3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="4" SET quality_libfdk=1& SET AudioQuality=4& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="5" SET quality_libfdk=1& SET AudioQuality=5& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="6" SET quality_libfdk=1& SET AudioQuality=0& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsAudio%"=="2" (GOTO :doYTDL-audio-preset-1) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="w" GOTO :select-format-audio
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
:select-quality-vbr-audio


:select-preset-audio
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO PRESETS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Audio Single					%Cyan-s%16%ColorOff%. Audio Single + Only New
ECHO   %Cyan-s%2%ColorOff%. Audio Single + Crop Thumbnail			%Cyan-s%17%ColorOff%. Audio Single + Crop Thumbnail + Only New
ECHO   %Cyan-s%3%ColorOff%. Audio Single + Title as "Artist - Title"		%Cyan-s%18%ColorOff%. Audio Single + Title as "Artist - Title" + Only New
ECHO   %Cyan-s%4%ColorOff%. Audio Single + Crop + Title as "Artist - Title"	%Cyan-s%19%ColorOff%. Audio Single + Crop + Title as "Artist - Title" + Only New
ECHO   %Cyan-s%5%ColorOff%. Audio Single + 10 Top Comments			%Cyan-s%20%ColorOff%. Audio Single + Crop Thumbnail + 10 Top Comments
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%6%ColorOff%. Audio Album					%Cyan-s%21%ColorOff%. Audio Album + Only New
ECHO   %Cyan-s%7%ColorOff%. Audio Album + Crop Thumbnail			%Cyan-s%22%ColorOff%. Audio Album + Crop Thumbnail + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%8%ColorOff%. Audio Playlist					%Cyan-s%23%ColorOff%. Audio Playlist + Only New
ECHO   %Cyan-s%9%ColorOff%. Audio Playlist + Crop Thumbnail			%Cyan-s%24%ColorOff%. Audio Playlist + Crop Thumbnail + Only New
ECHO  %Cyan-s%10%ColorOff%. Audio Playlist Various Artists			%Cyan-s%25%ColorOff%. Audio Playlist Various Artists + Only New
ECHO  %Cyan-s%11%ColorOff%. Audio Playlist Various Artists + Crop Thumbnail	%Cyan-s%26%ColorOff%. Audio Playlist Various Artists + Crop + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO  %Cyan-s%12%ColorOff%. Download Links From Text List
ECHO  %Cyan-s%13%ColorOff%. Download Links From Text List + Crop Thumbnail
ECHO  %Cyan-s%14%ColorOff%. Download Links From Text List + Crop Thumbnail + Interpret Title as "Artist - Title"
ECHO  %Cyan-s%15%ColorOff%. Download Links From Text List + Crop Thumbnail + Interpret Title as "Artist - Title" + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Choose Preset: 
IF "%choice%"=="1" IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="2" SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="3" SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="4" SET CropThumb=1& SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="5" SET CommentPreset=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="6" SET Album=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="7" SET Album=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="8" IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="9" SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="10" SET VariousArtists=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=3& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="11" SET VariousArtists=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=3& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="12" SET DownloadList=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="13" SET DownloadList=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="14" SET DownloadList=1& SET CropThumb=1& SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="15" SET DownloadList=1& SET CropThumb=1& SET FormatTitle=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="16" SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="17" SET OnlyNew=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="18" SET OnlyNew=1& SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="19" SET OnlyNew=1& SET CropThumb=1& SET FormatTitle=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="20" SET CommentPreset=1& SET CropThumb=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=1& GOTO :doYTDL-audio-preset-2) ELSE (GOTO :doYTDL-audio-preset-2)
IF "%choice%"=="21" SET Album=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="22" SET Album=1& SET CropThumb=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="23" SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="24" SET CropThumb=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=2& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="25" SET VariousArtists=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=3& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="26" SET VariousArtists=1& SET CropThumb=1& SET OnlyNew=1& IF "%use_pl_replaygain%"=="1" (SET ReplayGainPreset=3& GOTO :doYTDL-audio-preset-3) ELSE (GOTO :doYTDL-audio-preset-3)
IF "%choice%"=="w" IF "%CustomFormatAudio%"=="1" (GOTO :select-format-audio) ELSE (IF "%quality_libfdk%"=="1" (GOTO :select-quality-vbr-audio) ELSE (GOTO :select-quality-audio))
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& GOTO :start
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
ECHO   %Cyan-s%1%ColorOff%. 320p/30fps
ECHO   %Cyan-s%2%ColorOff%. 480p/30fps
ECHO   %Cyan-s%3%ColorOff%. 720p/30fps
ECHO   %Cyan-s%4%ColorOff%. 720p/%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%5%ColorOff%. 1080p/30fps
ECHO   %Cyan-s%6%ColorOff%. 1080p/%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%7%ColorOff%. 1440p/30fps
ECHO   %Cyan-s%8%ColorOff%. 1440p/%Red-s%60%ColorOff%fps
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%9%ColorOff%. Best Video			%Cyan-s%13%ColorOff%. ^<480p + Best Video		%Cyan-s%17%ColorOff%. ^<480p/mp4/m4a/vp9 + Audio Filter
ECHO  %Cyan-s%10%ColorOff%. Worst Video		%Cyan-s%14%ColorOff%. ^<720p/mp4/m4a/h264/30fps
ECHO  %Cyan-s%11%ColorOff%. Smallest Size		%Cyan-s%15%ColorOff%. ^<720p/fps^>30
ECHO  %Cyan-s%12%ColorOff%. Best Codec + Best Bitrate	%Cyan-s%16%ColorOff%. ^<1080p/mp4/m4a
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Video Quality: 
IF "%choice%"=="1" SET VideoResolution=320& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="2" SET VideoResolution=480& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="3" SET VideoResolution=720& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="4" SET VideoResolution=720& SET VideoFPS=60& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="5" SET VideoResolution=1080& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="6" SET VideoResolution=1080& SET VideoFPS=60& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="7" SET VideoResolution=1440& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="8" SET VideoResolution=1440& SET VideoFPS=60& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="9" SET CustomFormatVideo=1& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="10" SET CustomFormatVideo=2& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="11" SET CustomFormatVideo=3& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="12" SET CustomFormatVideo=4& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="13" SET CustomFormatVideo=5& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="14" SET CustomFormatVideo=6& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="15" SET CustomFormatVideo=7& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="16" SET CustomFormatVideo=8& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="17" SET CustomFormatVideo=9& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (IF "%SectionsVideo%"=="2" (GOTO :doYTDL-video-preset-1) ELSE (GOTO :select-preset-video))
IF "%choice%"=="w" IF "%SectionsVideo%"=="1" (GOTO :select-preset-sections) ELSE (IF "%SectionsVideo%"=="2" (GOTO :select-preset-sections) ELSE (GOTO :start))
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-format-video


:select-preset-video
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  VIDEO PRESETS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Video Single					%Cyan-s%10%ColorOff%. Video Single + Crop Thumbnail
ECHO   %Cyan-s%2%ColorOff%. Video Single + Top Comments			%Cyan-s%11%ColorOff%. Video Single + Top Comments + Crop Thumbnail
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%3%ColorOff%. Video Playlist					%Cyan-s%12%ColorOff%. Video Playlist + Only New
ECHO   %Cyan-s%4%ColorOff%. Video Playlist + Crop Thumbnail			%Cyan-s%13%ColorOff%. Video Playlist + Crop Thumbnail + Only New
ECHO   %Cyan-s%5%ColorOff%. Video Playlist + Top Comments			%Cyan-s%14%ColorOff%. Video Playlist + Top Comments + Only New
ECHO   %Cyan-s%6%ColorOff%. Video Playlist + Top Comments + Crop Thumbnail	%Cyan-s%15%ColorOff%. Video Playlist + Top Comments + Crop + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%7%ColorOff%. Download Links From Text List
ECHO   %Cyan-s%8%ColorOff%. Download Links From Text List + Crop Thumbnail
ECHO   %Cyan-s%9%ColorOff%. Download Links From Text List + Crop Thumbnail + Only New
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Choose Preset: 
IF "%choice%"=="1" GOTO :doYTDL-video-preset-2
IF "%choice%"=="2" SET CommentPreset=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="3" GOTO :doYTDL-video-preset-3
IF "%choice%"=="4" SET CropThumb=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="5" SET CommentPreset=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="6" SET CommentPreset=1& SET CropThumb=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="7" SET DownloadList=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="8" SET DownloadList=1& SET CropThumb=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="9" SET DownloadList=1& SET CropThumb=1& SET OnlyNew=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="10" SET CropThumb=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="11" SET CommentPreset=1& SET CropThumb=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="12" SET OnlyNew=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="13" SET OnlyNew=1& SET CropThumb=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="14" SET CommentPreset=1& SET OnlyNew=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="15" SET CommentPreset=1& SET OnlyNew=1& SET CropThumb=1& GOTO :doYTDL-video-preset-3
IF "%choice%"=="w" GOTO :select-format-video
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& GOTO :start
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
ECHO   %Blue-s%•%ColorOff%  PRESETS
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
SET /p choice=!BS!%spcs%Choose Preset: 
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
ECHO   %Blue-s%•%ColorOff%  PRESETS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%.   25 Comments Sorted by TOP
ECHO   %Cyan-s%2%ColorOff%.   25 Comments Sorted by TOP and Converted to HTML
ECHO   %Cyan-s%3%ColorOff%.  500 Comments Sorted by TOP
ECHO   %Cyan-s%4%ColorOff%.  500 Comments Sorted by TOP and Converted to HTML
ECHO   %Cyan-s%5%ColorOff%.  ALL Comments Sorted by TOP
ECHO   %Cyan-s%6%ColorOff%.  ALL Comments Sorted by TOP and Converted to HTML
ECHO   %Cyan-s%7%ColorOff%.   25 Comments Sorted by NEW
ECHO   %Cyan-s%8%ColorOff%.   25 Comments Sorted by NEW and Converted to HTML
ECHO   %Cyan-s%9%ColorOff%.  500 Comments Sorted by NEW
ECHO  %Cyan-s%10%ColorOff%.  500 Comments Sorted by NEW and Converted to HTML	%Cyan-s%13%ColorOff%.  500 Comments Converted to HTML + Sorted by NEW
ECHO  %Cyan-s%11%ColorOff%.  ALL Comments Sorted by NEW
ECHO  %Cyan-s%12%ColorOff%.  ALL Comments Sorted by NEW and Converted to HTML
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Choose Preset: 
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
SET /p choice=!BS!%spcs%Enter Your Choice: 
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
SET /p choice=!BS!%spcs%Enter Your Choice: 
IF "%choice%"=="1" SET StreamVideoFormat=& SET StreamAudioFormat=1& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="2" SET StreamVideoFormat=& SET StreamAudioFormat=2& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="w" GOTO :select-format-stream
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-quality-audio-stream

:select-quality-video-stream
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  STREAM VIDEO QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. ^<480p/30fps
ECHO   %Cyan-s%2%ColorOff%. ^<720p/^<%Red-s%60%ColorOff%fps
ECHO   %Cyan-s%3%ColorOff%. Best Video + Best Audio
ECHO   %Cyan-s%4%ColorOff%. Best Video + Best Protocol
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-s%r%ColorOff%. Main Menu
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Enter Your Choice: 
IF "%choice%"=="1" SET StreamAudioFormat=& SET StreamVideoFormat=1& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="2" SET StreamAudioFormat=& SET StreamVideoFormat=2& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="3" SET StreamAudioFormat=& SET StreamVideoFormat=3& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="4" SET StreamAudioFormat=& SET StreamVideoFormat=4& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="w" GOTO :select-format-stream
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-quality-video-stream

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
ECHO   %Cyan-s%1%ColorOff%. Download Audio Sections			     %Cyan-s%5%ColorOff%. Download Audio Sections + Crop Thumbnail
ECHO   %Cyan-s%2%ColorOff%. Download Video Sections			     %Cyan-s%6%ColorOff%. Download Video Sections + Crop Thumbnail
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%3%ColorOff%. Download Audio + Split by Chapters		     %Cyan-s%7%ColorOff%. Download Audio + Split by Chapters + Crop Thumbnail
ECHO   %Cyan-s%4%ColorOff%. Download Video + Split by Chapters		     %Cyan-s%8%ColorOff%. Download Video + Split by Chapters + Crop Thumbnail
IF "%use_pl_customchapters%"=="1" (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%9%ColorOff%. Download Audio + Split by Custom Chapters	    %Cyan-s%11%ColorOff%. Download Audio + Split by Custom Chapters + Crop Thumbnail
ECHO  %Cyan-s%10%ColorOff%. Download Video + Split by Custom Chapters	    %Cyan-s%12%ColorOff%. Download Video + Split by Custom Chapters + Crop Thumbnail
ECHO ------------------------------------------------------------------------------------------------------------------------
) ELSE (
ECHO ------------------------------------------------------------------------------------------------------------------------
)
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Section Download Preset: 
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
SET /p choice=!BS!%spcs%Enter Your Choice: 
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
IF "%choice%"=="w" IF "%SectionsVideo%"=="1" (GOTO :select-format-video) ELSE (IF "%CustomFormatAudio%"=="1" (GOTO :select-format-audio) ELSE (IF "%quality_libfdk%"=="1" (GOTO :select-quality-vbr-audio) ELSE (IF "%quality_simple%"=="1" (GOTO :select-quality-audio) ELSE (GOTO :select-preset-sections))))
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-sections-number

:enter-sections-1
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-2
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-3
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-4
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-5
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-6
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-7
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
SET /P section7=!BS!%spcs%Enter Section 7 Time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-8
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
SET /P section7=!BS!%spcs%Enter Section 7 Time: 
SET /P section8=!BS!%spcs%Enter Section 8 Time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-9
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
SET /P section7=!BS!%spcs%Enter Section 7 Time: 
SET /P section8=!BS!%spcs%Enter Section 8 Time: 
SET /P section9=!BS!%spcs%Enter Section 9 Time: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :sections-preset-1
:enter-sections-10
SET /P section1=!BS!%spcs%Enter Section Time (i.e. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
SET /P section7=!BS!%spcs%Enter Section 7 Time: 
SET /P section8=!BS!%spcs%Enter Section 8 Time: 
SET /P section9=!BS!%spcs%Enter Section 9 Time: 
SET /P section10=!BS!%spcs%Enter Section 10 Time: 
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
ECHO   %Cyan-s%1%ColorOff%. IS NOT live AND 1 Duration Filter
ECHO   %Cyan-s%2%ColorOff%. IS NOT live AND 2 Duration Filters
ECHO   %Cyan-s%3%ColorOff%. IS NOT live AND 3 Duration Filters
ECHO   %Cyan-s%4%ColorOff%. IS NOT live AND 4 Duration Filters
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%5%ColorOff%. IS live AND 1 Duration Filter
ECHO   %Cyan-s%6%ColorOff%. IS live AND 2 Duration Filters
ECHO   %Cyan-s%7%ColorOff%. IS live AND 3 Duration Filters
ECHO   %Cyan-s%8%ColorOff%. IS live AND 4 Duration Filters
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%9%ColorOff%. ^< 1 minute Long
ECHO  %Cyan-s%10%ColorOff%. ^> 1 minute Long
ECHO  %Cyan-s%11%ColorOff%. ^< 10 minutes Long
ECHO  %Cyan-s%12%ColorOff%. ^> 10 minutes Long
ECHO  %Cyan-s%13%ColorOff%. ^> 1 minute AND ^< 10 minutes Long
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO  %Cyan-s%14%ColorOff%. Video IS live
ECHO  %Cyan-s%15%ColorOff%. Video IS NOT live
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-n%t%ColorOff%. Disable Duration Filter
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Duration Filter Preset: 
IF "%choice%"=="1" SET duration_filter=1& GOTO :duration-filter-1
IF "%choice%"=="2" SET duration_filter=2& GOTO :duration-filter-2
IF "%choice%"=="3" SET duration_filter=3& GOTO :duration-filter-3
IF "%choice%"=="4" SET duration_filter=4& GOTO :duration-filter-4
IF "%choice%"=="5" SET duration_filter=5& GOTO :duration-filter-1
IF "%choice%"=="6" SET duration_filter=6& GOTO :duration-filter-2
IF "%choice%"=="7" SET duration_filter=7& GOTO :duration-filter-3
IF "%choice%"=="8" SET duration_filter=8& GOTO :duration-filter-4
IF "%choice%"=="9" SET duration_filter=9& GOTO :start
IF "%choice%"=="10" SET duration_filter=10& GOTO :start
IF "%choice%"=="11" SET duration_filter=11& GOTO :start
IF "%choice%"=="12" SET duration_filter=12& GOTO :start
IF "%choice%"=="13" SET duration_filter=13& GOTO :start
IF "%choice%"=="14" SET duration_filter=14& GOTO :start
IF "%choice%"=="15" SET duration_filter=15& GOTO :start
IF "%choice%"=="t" SET duration_filter=& GOTO :start
IF "%choice%"=="w" GOTO :start
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
SET /P duration_filter_1=!BS!%spcs%Set Filter #1: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start

:duration-filter-2
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=!BS!%spcs%Set Filter #1: 
SET /P duration_filter_2=!BS!%spcs%Set Filter #2: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start

:duration-filter-3
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=!BS!%spcs%Set Filter #1: 
SET /P duration_filter_2=!BS!%spcs%Set Filter #2: 
SET /P duration_filter_3=!BS!%spcs%Set Filter #3: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start

:duration-filter-4
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=!BS!%spcs%Set Filter #1: 
SET /P duration_filter_2=!BS!%spcs%Set Filter #2: 
SET /P duration_filter_3=!BS!%spcs%Set Filter #3: 
SET /P duration_filter_4=!BS!%spcs%Set Filter #4: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start

::
::
:: DATE FILTER MENU
::
::

:set-date-filter
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  DATE FILTERS
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%1%ColorOff%. Download only uploaded ON or BEFORE the specified date
ECHO   %Cyan-s%2%ColorOff%. Download only uploaded ON or AFTER the specified date
ECHO   %Cyan-s%3%ColorOff%. Download only uploaded BETWEEN the specified dates
ECHO   %Cyan-s%4%ColorOff%. Download only uploaded ON CURRENT date OR relative to it
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%5%ColorOff%. Download only uploaded ON or BEFORE the specified date + Set 1 Duration Filter
ECHO   %Cyan-s%6%ColorOff%. Download only uploaded ON or AFTER the specified date + Set 1 Duration Filter
ECHO   %Cyan-s%7%ColorOff%. Download only uploaded BETWEEN the specified dates + Set 1 Duration Filter
ECHO   %Cyan-s%8%ColorOff%. Download only uploaded ON CURRENT date OR relative to it + Set 1 Duration Filter
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%9%ColorOff%. Download only uploaded ON or BEFORE the specified date + Set 2 Duration Filters
ECHO  %Cyan-s%10%ColorOff%. Download only uploaded ON or AFTER the specified date + Set 2 Duration Filters
ECHO  %Cyan-s%11%ColorOff%. Download only uploaded BETWEEN the specified dates + Set 2 Duration Filters
ECHO  %Cyan-s%12%ColorOff%. Download only uploaded ON CURRENT date OR relative to it + Set 2 Duration Filters
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%w%ColorOff%. Go Back
ECHO   %Yellow-n%d%ColorOff%. Disable Date Filter
ECHO   %Red-s%q%ColorOff%. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Date Filter Preset: 
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
IF "%choice%"=="d" SET date-filter=& GOTO :start
IF "%choice%"=="w" GOTO :start
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
SET /P date_filter_1=!BS!%spcs%Set Date Filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start
:date-filter-2
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=!BS!%spcs%Set BEFORE Date Filter: 
SET /P date_filter_2=!BS!%spcs%Set AFTER Date Filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start
:date-filter-3
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=!BS!%spcs%Set Date Filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=!BS!%spcs%Set Duration Filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start
:date-filter-4
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=!BS!%spcs%Set BEFORE Date Filter: 
SET /P date_filter_2=!BS!%spcs%Set AFTER Date Filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=!BS!%spcs%Set Duration Filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start
:date-filter-5
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=!BS!%spcs%Set Date Filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=!BS!%spcs%Set Duration Filter #1: 
SET /P duration_filter_2=!BS!%spcs%Set Duration Filter #2: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start
:date-filter-6
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Date in YYYYMMDD format OR relative period ^(now^|today^|yesterday^)[+-][0-9]^(day^|week^|month^|year^), i.e. today-6month
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P date_filter_1=!BS!%spcs%Set BEFORE Date Filter: 
SET /P date_filter_2=!BS!%spcs%Set AFTER Date Filter: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  i.e. ^>60 ^(longer than 60sec^), ^<60 ^(under 60sec^), ^<=600 ^(under or equal 10mins^), ==150 ^(equal 150sec^)
ECHO ------------------------------------------------------------------------------------------------------------------------
SET /P duration_filter_1=!BS!%spcs%Set Duration Filter #1: 
SET /P duration_filter_2=!BS!%spcs%Set Duration Filter #2: 
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 1 >nul
GOTO :start

::
::
:: AUDIO PRESETS
::
::

:: AUDIO SPLIT PRESET
:doYTDL-audio-preset-1
SET  OutTemplate= --path "%TargetFolder%" --output "thumbnail:%TargetFolder%\%%(title)s\cover.%%(ext)s" --output "chapter:%TargetFolder%\%%(title)s\%%(section_title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
IF "%CustomChapters%"=="1" (
SET       Select= --no-download-archive --no-playlist --split-chapters --extractor-args "youtube:chapters_file=%Chapters-Path%"
) ELSE (
SET       Select= --no-download-archive --no-playlist --split-chapters
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
:: --embed-thumbnail with --split-chapters is broken https://github.com/yt-dlp/yt-dlp/issues/6225
IF "%CropThumb%"=="1" (
SET    Thumbnail= --no-embed-thumbnail --write-thumbnail --exec "after_move:\"%FFmpeg-Path%\" -v quiet -i \"%TargetFolder%\\%%^(title^)s\\cover.webp\" -y -c:v mjpeg -q:v 3 -vf crop=\"'if^(gt^(ih,iw^),iw,ih^)':'if^(gt^(iw,ih^),ih,iw^)'\" \"%TargetFolder%\\%%^(title^)s\\cover.%Thumb-Format%\"" --exec "after_move:del /q \"%TargetFolder%\\%%^(title^)s\\cover.webp\""
) ELSE (
SET    Thumbnail= --no-embed-thumbnail --write-thumbnail --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
)
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --extract-audio --format "141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-ogg%"=="1" (
SET       Format= --extract-audio --format "46/45/44/43" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-mp3%"=="1" (
SET       Format= --extract-audio --format "ba[acodec^=mp3]/ba/b" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="4" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="3" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -b:a 148k -c:a libopus -af \"pan=stereo^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="5" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"pan=stereo^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
))))))))))
SET     Subtitle=
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
:: --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s"
SET   PreProcess= --parse-metadata "title:%%(artist)s - %%(album)s" --parse-metadata "%%(chapters|)l:(?P<has_chapters>.)" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album_artist,album_artists,artist,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --no-embed-chapters --compat-options no-attach-info-json --exec "after_move:del /q %%(filepath,_filename|)q"
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check


:: AUDIO SINGLE PRESET
:doYTDL-audio-preset-2
IF "%FormatTitle%"=="1" (
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(artist,artists.0,creator,uploader)s - %%(title)s.%%(ext)s"
) ELSE (
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(title)s.%%(ext)s"
)
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Path%" --no-overwrites --no-playlist
) ELSE (
SET       Select= --no-download-archive --no-playlist
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
IF "%DownloadList%"=="1" (
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%" --batch-file "%List-Path%"
) ELSE (
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
)
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if^(gt^(ih,iw^),iw,ih^)':'if^(gt^(iw,ih^),ih,iw^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
)
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --extract-audio --format "141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-ogg%"=="1" (
SET       Format= --extract-audio --format "46/45/44/43" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-mp3%"=="1" (
SET       Format= --extract-audio --format "ba[acodec^=mp3]/ba/b" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="4" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="3" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -b:a 148k -c:a libopus -af \"pan=stereo^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="5" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"pan=stereo^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
))))))))))
SET     Subtitle=
IF "%CommentPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=10;comment_sort=top"
) ELSE (
SET     Comments=
)
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (
SET    AdobePass=
)
IF "%FormatTitle%"=="1" (
SET   PreProcess= --parse-metadata "title:%%(artist)s - %%(title)s" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
) ELSE (
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
)
SET  PostProcess= --embed-metadata --compat-options no-attach-info-json
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
SET     Duration= --match-filters "!is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="2" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="3" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="4" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
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
SET     Duration= --match-filters "!is_live"
))))))))))))))))
IF NOT DEFINED date_filter (
SET         Date=
) ELSE (IF "%date_filter%"=="1" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1%"
) ELSE (IF "%date_filter%"=="2" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1%"
) ELSE (IF "%date_filter%"=="3" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2%"
) ELSE (IF "%date_filter%"=="4" (
SET         Date= --break-match-filters "upload_date == %date_filter_1%"
) ELSE (IF "%date_filter%"=="5" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="6" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="7" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="8" (
SET         Date= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="9" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="10" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="11" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="12" (
SET         Date= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
)))))))))))))
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: AUDIO PLAYLIST PRESET
:doYTDL-audio-preset-3
:: this is an experiment to get an approximate playlist creation date
:: i'm getting the earliest date of all uploaded videos in it and set it to variable
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Getting playlist creation date...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTdlp-Path%" --no-warnings --quiet --simulate --flat-playlist --extractor-args "youtubetab:approximate_date" --print "%%(upload_date>%%Y)s" "%URL%" | sort | "%head-Path%" -n 1 | "%tr-Path%" -d '\012\015' | clip >NUL 2>&1
FOR /f "delims=" %%i IN ('%mshta%') DO SET "playlist_date=%%i"
IF "%VariousArtists%"=="1" (
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(album,playlist_title,playlist|)s\%%(meta_track_number,playlist_index,playlist_autonumber)02d. %%(artist,artists,creator,uploader)s - %%(title)s.%%(ext)s"
) ELSE (IF "%Album%"=="1" (
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(%playlist_date%,release_year,release_date>%%Y,upload_date>%%Y)s - %%(album,playlist_title,playlist|)s\%%(meta_track_number,playlist_index,playlist_autonumber)02d. %%(title)s.%%(ext)s" 
) ELSE (
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(album,playlist_title,playlist|)s\%%(meta_track_number,playlist_index,playlist_autonumber)02d. %%(title)s.%%(ext)s" 
))
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors 1
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Path%" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if^(gt^(ih,iw^),iw,ih^)':'if^(gt^(iw,ih^),ih,iw^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
)
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --extract-audio --format "141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-ogg%"=="1" (
SET       Format= --extract-audio --format "46/45/44/43" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-mp3%"=="1" (
SET       Format= --extract-audio --format "ba[acodec^=mp3]/ba/b" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="4" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="3" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -b:a 148k -c:a libopus -af \"pan=stereo^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="5" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"pan=stereo^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
))))))))))
SET     Subtitle=
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
IF "%VariousArtists%"=="1" (
SET   PreProcess= --parse-metadata "title:%%(artist)s - %%(title)s" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist "^.*$" "Various Artists" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
) ELSE (
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
)
SET  PostProcess= --embed-metadata --compat-options no-attach-info-json
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
SET     Duration= --match-filters "!is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="2" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="3" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="4" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
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
SET     Duration= --match-filters "!is_live"
))))))))))))))))
IF NOT DEFINED date_filter (
SET         Date=
) ELSE (IF "%date_filter%"=="1" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1%"
) ELSE (IF "%date_filter%"=="2" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1%"
) ELSE (IF "%date_filter%"=="3" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2%"
) ELSE (IF "%date_filter%"=="4" (
SET         Date= --break-match-filters "upload_date == %date_filter_1%"
) ELSE (IF "%date_filter%"=="5" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="6" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="7" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="8" (
SET         Date= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="9" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="10" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="11" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="12" (
SET         Date= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
)))))))))))))
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

::
::
:: VIDEO PRESETS
::
::

:: VIDEO SPLIT PRESET
:doYTDL-video-preset-1
SET  OutTemplate= --path "%TargetFolder%" --output "thumbnail:%TargetFolder%\%%(title)s\cover.%%(ext)s" --output "chapter:%TargetFolder%\%%(title)s\%%(section_title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
IF "%CustomChapters%"=="1" (
SET       Select= --no-download-archive --no-playlist --split-chapters --extractor-args "youtube:chapters_file=%Chapters-Path%"
) ELSE (
SET       Select= --no-download-archive --no-playlist --split-chapters
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview --sponsorblock-api "%Sponsorblock-Api%" 
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --no-embed-thumbnail --write-thumbnail --exec "after_move:\"%FFmpeg-Path%\" -v quiet -i \"%TargetFolder%\\%%^(title^)s\\cover.webp\" -y -c:v mjpeg -q:v 3 -vf crop=\"'if^(gt^(ih,iw^),iw,ih^)':'if^(gt^(iw,ih^),ih,iw^)'\" \"%TargetFolder%\\%%^(title^)s\\cover.%Thumb-Format%\"" --exec "after_move:del /q \"%TargetFolder%\\%%^(title^)s\\cover.webp\""
) ELSE (
SET    Thumbnail= --no-embed-thumbnail --write-thumbnail --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
)
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormatVideo%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormatVideo%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormatVideo%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-format m4a --postprocessor-args Merger:"-v quiet -y -ac 2 -c:a libfdk_aac -afterburner 1 -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
)))))))))
SET     Subtitle= 
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(chapters|)l:(?P<has_chapters>.)" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,artist,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
:: --embed-thumbnail with --split-chapters is broken https://github.com/yt-dlp/yt-dlp/issues/6225
SET  PostProcess= --embed-metadata --no-embed-chapters --compat-options no-attach-info-json --force-keyframes-at-cuts --match-filters "has_chapters" --exec "after_move:del /q %%(filepath,_filename|)q"
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: VIDEO SINGLE PRESET
:doYTDL-video-preset-2
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist,uploader)s - %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Path%" --no-overwrites --no-download-archive --no-playlist
) ELSE (
SET       Select= --no-download-archive --no-playlist
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview --sponsorblock-api "%Sponsorblock-Api%"
IF "%DownloadList%"=="1" (
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%" --batch-file "%List-Path%"
) ELSE (
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
)
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if^(gt^(ih,iw^),iw,ih^)':'if^(gt^(iw,ih^),ih,iw^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
)
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormatVideo%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormatVideo%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormatVideo%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-format m4a --postprocessor-args Merger:"-v quiet -y -ac 2 -c:a libfdk_aac -afterburner 1 -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
)))))))))
SET     Subtitle= --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
IF "%CommentPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=50;comment_sort=top"
) ELSE (
SET     Comments=
)
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (
SET    AdobePass=
)
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json
IF NOT DEFINED duration_filter (
SET     Duration=
) ELSE (IF "%duration_filter%"=="1" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="2" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="3" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="4" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
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
SET     Duration= --match-filters "!is_live"
))))))))))))))))
IF NOT DEFINED date_filter (
SET         Date=
) ELSE (IF "%date_filter%"=="1" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1%"
) ELSE (IF "%date_filter%"=="2" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1%"
) ELSE (IF "%date_filter%"=="3" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2%"
) ELSE (IF "%date_filter%"=="4" (
SET         Date= --break-match-filters "upload_date == %date_filter_1%"
) ELSE (IF "%date_filter%"=="5" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="6" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="7" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="8" (
SET         Date= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="9" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="10" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="11" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="12" (
SET         Date= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
)))))))))))))
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: VIDEO PLAYLIST PRESET
:doYTDL-video-preset-3
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Getting playlist creation date...
ECHO ------------------------------------------------------------------------------------------------------------------------
"%YTdlp-Path%" --no-warnings --quiet --simulate --flat-playlist --extractor-args "youtubetab:approximate_date" --print "%%(upload_date>%%Y)s" "%URL%" | sort | "%head-Path%" -n 1 | "%tr-Path%" -d '\012\015' | clip >NUL 2>&1
FOR /f "delims=" %%i IN ('%mshta%') DO SET "playlist_date=%%i"
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(%playlist_date%,release_year,release_date>%%Y,upload_date>%%Y)s - %%(album,playlist_title,playlist|)s\%%(meta_track_number,playlist_index,playlist_autonumber)02d. %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config --skip-playlist-after-errors 1
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Path%" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview --sponsorblock-api "%Sponsorblock-Api%"
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if^(gt^(ih,iw^),iw,ih^)':'if^(gt^(iw,ih^),ih,iw^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
)
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormatVideo%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormatVideo%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormatVideo%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-format m4a --postprocessor-args Merger:"-v quiet -y -ac 2 -c:a libfdk_aac -afterburner 1 -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
)))))))))
SET     Subtitle= --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
IF "%CommentPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=50;comment_sort=top"
) ELSE (
SET     Comments=
)
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (
SET    AdobePass=
)
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json
IF NOT DEFINED duration_filter (
SET     Duration=
) ELSE (IF "%duration_filter%"=="1" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1%"
) ELSE (IF "%duration_filter%"=="2" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%duration_filter%"=="3" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3%"
) ELSE (IF "%duration_filter%"=="4" (
SET     Duration= --match-filters "!is_live & duration%duration_filter_1% & duration%duration_filter_2% & duration%duration_filter_3% & duration%duration_filter_4%"
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
SET     Duration= --match-filters "!is_live"
))))))))))))))))
IF NOT DEFINED date_filter (
SET         Date=
) ELSE (IF "%date_filter%"=="1" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1%"
) ELSE (IF "%date_filter%"=="2" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1%"
) ELSE (IF "%date_filter%"=="3" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2%"
) ELSE (IF "%date_filter%"=="4" (
SET         Date= --break-match-filters "upload_date == %date_filter_1%"
) ELSE (IF "%date_filter%"=="5" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="6" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="7" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="8" (
SET         Date= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1%"
) ELSE (IF "%date_filter%"=="9" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="10" (
SET         Date= --break-match-filters "upload_date >= %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="11" (
SET         Date= --break-match-filters "upload_date <= %date_filter_1% & upload_date >= %date_filter_2% & duration%duration_filter_1% & duration%duration_filter_2%"
) ELSE (IF "%date_filter%"=="12" (
SET         Date= --break-match-filters "upload_date == %date_filter_1% & duration%duration_filter_1% & duration%duration_filter_2%"
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
SET  OutTemplate= --output "%TargetFolder%\%%(title)s.%%(ext)s"
) ELSE (IF "%SubsPreset%"=="2" (
SET  OutTemplate= --output "%TargetFolder%\%%(title)s-transcript.%%(ext)s"
))
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
SET       Select=
SET     Download= --skip-download --concurrent-fragments 1
SET Sponsorblock=
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail=
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
SET       Format=
IF "%SubsPreset%"=="1" (
SET     Subtitle= --write-subs --write-auto-subs --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
) ELSE (IF "%SubsPreset%"=="2" (
SET     Subtitle= --write-subs --write-auto-subs --sub-format ttml --convert-subs srt --sub-langs "%Sub-langs%" --compat-options no-live-chat
) ELSE (IF "%SubsPreset%"=="3" (
SET     Subtitle= --sub-langs "%Sub-langs%" --write-auto-subs --write-subs --convert-subs srt --use-postprocessor srt_fix:when=before_dl --compat-options no-live-chat
)))
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
IF "%SubsPreset%"=="1" (
SET    AdobePass= --write-subs --write-auto-subs --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
) ELSE (IF "%SubsPreset%"=="2" (
SET    AdobePass= --exec before_dl:"%Sed-Path% -i -f \"%Sed-Commands%\" %%(requested_subtitles.:.filepath)#q"
))
SET   PreProcess=
SET  PostProcess=
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=1& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL-check

:: DOWNLOAD JUST COMMENTS
:comments-preset-1
SET  OutTemplate= --output "%TargetFolder%\%%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
SET       Select=
SET     Download= --skip-download
SET Sponsorblock=
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail=
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
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
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="2" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="3" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="4" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="5" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="6" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="7" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="8" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="9" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="10" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="11" (
SET    AdobePass= --exec pre_process:"del /q %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="12" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="13" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_new.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del /q %%(infojson_filename)#q"
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
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
SET       Select=
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads% --downloader "%FFmpeg-Path%"
SET Sponsorblock=
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail=
SET    Verbosity= --quiet --console-title --progress
SET  WorkArounds=
IF "%StreamVideoFormat%"=="1" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w"
) ELSE (IF "%StreamVideoFormat%"=="2" (
SET       Format= --format "((bv*[fps<60]/bv*)[height<=720]/(wv*[fps<60]/wv*)) + ba / (b[fps<60]/b)[height<=720]/(w[fps<60]/w)"
) ELSE (IF "%StreamVideoFormat%"=="3" (
SET       Format= --format "bv*+ba/b"
) ELSE (IF "%StreamVideoFormat%"=="4" (
SET       Format= -S "proto"
) ELSE (IF "%StreamAudioFormat%"=="1" (
SET       Format= --format "ba/b"
) ELSE (IF "%StreamAudioFormat%"=="2" (
SET       Format= --format "ba/b" -S "proto"
))))))
SET     Subtitle=
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
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
SET  OutTemplate= --output "%TargetFolder%\%%(title)s_%%(duration)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network= --add-headers "User-Agent:%User-Agent%"
SET  GeoRestrict= --xff "default"
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
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --cache-dir "%YTdlp-Cache-Dir%" --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%CropThumb%"=="1" (
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if^(gt^(ih,iw^),iw,ih^)':'if^(gt^(iw,ih^),ih,iw^)'\""
) ELSE (
SET    Thumbnail= --embed-thumbnail --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
)
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
IF "%use_pl_returnyoutubedislike%"=="1" (
SET  WorkArounds= --use-postprocessor ReturnYoutubeDislike:when=pre_process
) ELSE (
SET  WorkArounds=
)
IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --extract-audio --format "141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-ogg%"=="1" (
SET       Format= --extract-audio --format "46/45/44/43" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-mp3%"=="1" (
SET       Format= --extract-audio --format "ba[acodec^=mp3]/ba/b" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="4" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="3" (
SET       Format= --extract-audio --format "338/774/251/250/249" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -b:a 148k -c:a libopus -af \"pan=stereo^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="5" (
SET       Format= --extract-audio --format "258/380/327/256/141/38/22/140/37/59/34/35/59/78/18" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-v quiet -vn -y -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"pan=stereo^|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3^|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3,compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm,silenceremove=start_periods=1:stop_periods=-1:start_threshold=-30dB:stop_threshold=-30dB:start_silence=2:stop_silence=2\"" --force-overwrites --post-overwrites
) ELSE (IF "%SectionsAudio%"=="1" (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
) ELSE (IF "%CustomFormatVideo%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormatVideo%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormatVideo%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormatVideo%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-format m4a --postprocessor-args Merger:"-v quiet -y -ac 2 -c:a libfdk_aac -afterburner 1 -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%SectionsVideo%"=="1" (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
)))))))))))))))))))))
SET     Subtitle=
SET     Comments=
IF "%usecookies%"=="1" (
SET Authenticate= --cookies "%Cookies-Path%"
) ELSE (
SET Authenticate=
)
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
IF "%SectionsVideo%"=="1" (
SET  PostProcess= --embed-metadata --compat-options no-attach-info-json --force-keyframes-at-cuts
) ELSE (
SET  PostProcess= --embed-metadata --compat-options no-attach-info-json
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
ECHO   %Green-s%›%ColorOff%  Date:%Date%
)
IF "%DownloadList%"=="1" (
ECHO   %Green-n%›%ColorOff%  URLs: %Underline%%List-Path%%ColorOff%
) ELSE (
ECHO   %Green-n%›%ColorOff%  URL: "%Underline%%URL%%ColorOff%"
)
ECHO.
:: test thing to reset without script quiting
SET /P doYTDL=!BS!%spcs%'Enter' to Download or Type 'r' to Return to Main Menu: 
IF NOT DEFINED doYTDL GOTO :doYTDL
IF "!doYTDL!"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET AudioQuality=& SET DownloadList=& SET VideoResolution=& SET VideoFPS=& SET CustomFormatVideo=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET quality_libfdk=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& SET CustomFormat-ogg=& SET CropThumb=& SET VariousArtists=& SET quality_simple=& SET CustomFormatAudio=& SET CustomChapters=& SET ReplayGainPreset=& SET ALBUM=& SET doYTDL=& GOTO :start
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :doYTDL-check

:doYTDL
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
REM ECHO.
%YTdlp-Path%%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess%%ReplayGain%%Duration%%Date% "%URL%"
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
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
%YTdlp-Path%%Options%%Network%%GeoRestrict%%Select%%Sponsorblock%%Thumbnail%%Verbosity%%WorkArounds%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess%%FileSystem%%OutTemplate%%Download%%Format% "%URL%"| "%V-Player-Path%" -
) ELSE (IF DEFINED StreamAudioFormat (
%YTdlp-Path%%Options%%Network%%GeoRestrict%%Select%%Sponsorblock%%Thumbnail%%Verbosity%%WorkArounds%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess%%FileSystem%%OutTemplate%%Download%%Format% "%URL%"| "%A-Player-Path%" -
))
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
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
REM ECHO.
%YTdlp-Path%%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%URL%"
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
GOTO :continue

:doYTDL-quick
cls
IF "%Downloaded-Quick%"=="1" (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
%YTdlp-Path%%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%URL%"
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
SET clipboard=
SET Downloaded-Quick=1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
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
%YTdlp-Path%%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%URL%"
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
SET clipboard=
SET Downloaded-Quick=1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
GOTO :continue
)

::
::
:: DRAGGED URLs/LISTs DOWNLOADER
::
::

:doYTDL-drag url[.txt] [...]
:: exit if no parameters, display commandline, call %YTdlp-Path%
IF ""=="%~1" EXIT /B 0
IF "%Downloaded-Drag%"=="1" (
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
%YTdlp-Path%%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%*"
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
SET Downloaded-Drag=1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 3 >nul
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
ECHO   %Green-n%›%ColorOff%  URL:"%Underline%%*%ColorOff%"
ECHO.
PAUSE
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  DOWNLOADING...
ECHO ------------------------------------------------------------------------------------------------------------------------
%YTdlp-Path%%OutTemplate%%Options%%Network%%GeoRestrict%%Select%%Download%%Sponsorblock%%FileSystem%%Thumbnail%%Verbosity%%WorkArounds%%Format%%Subtitle%%Comments%%Authenticate%%AdobePass%%PreProcess%%PostProcess% "%*"
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
SET Downloaded-Drag=1
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 3 >nul
EXIT /B 0
)
