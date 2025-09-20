:: yt-dlp.cmd [url[.txt]] [...]
:: v0.1 2021/01/09 CirothUngol
:: https://www.reddit.com/r/youtubedl/comments/kws98p/simple_batchfile_for_using_youtubedlexe_with
::
:: for drag'n'drop function any combination of URLs
:: and text files may be used. text files are found 
:: and processed first, then all URLs.
::
:: v0.9.3 20.09.2025 Lichtenshtein

:: to convert comments to readable HTML python needs to be installed
:: then you may also need to install "pip install json2html"

:: recomended ffmpeg static build with nonfree codecs
:: https://github.com/AnimMouse/ffmpeg-stable-autobuild

@ECHO OFF

:: register --postprocessor-args exe locations to system PATH
:: SET "PATH=%PATH%;"
setlocal ENABLEDELAYEDEXPANSION
:: endlocal

:: set terminal size (scrolling won't work without walkarouds)
REM MODE con: cols=120 lines=48
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

:: set target folder and exe locations
SET    TargetFolder=B:\Downloads
SET    YTdlp-Folder=B:\yt-dlp
SET  Archive-Folder=B:\yt-dlp\download-archive
SET       List-Path=B:\yt-dlp\download.list
SET      YTdlp-Path=B:\yt-dlp\yt-dlp.exe
SET     FFmpeg-Path=B:\FFmpeg\ffmpeg.exe
SET     Python-Path=B:\Python\python.exe
SET      Paste-Path=B:\paste\paste.exe
SET   A-Player-Path=B:\Aimp\aimp.exe
SET   V-Player-Path=B:\PotPlayer\PotPlayer.exe
SET  	 Aria2-Path=B:\aria2c\aria2c.exe
SET        Sed-Path=B:\git-for-windows\usr\bin\sed.exe
SET         tr-Path=B:\git-for-windows\usr\bin\tr.exe
SET   truncate-Path=B:\git-for-windows\usr\bin\truncate.exe
:: set aria args
SET       Aria-Args=--conf-path="B:\aria2c\aria2.conf"
:: sed special commands file
SET    Sed-Commands=B:\yt-dlp\sed.commands
:: set yt-dlp common options
SET          SpeedLimit=8096K
SET             Threads=3
SET        Thumb-Format=jpg
SET FFmpeg-Thumb-Format=mjpeg
SET      Thumb-Compress=3
SET           Sub-langs=en,en-en,ru,-live_chat
SET          Sub-Format=srt/vtt/ass/best
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
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
SET       Format= --format "bestvideo[height<=480][ext=mp4]+bestaudio/best" -S "fps:30,channels:2"
SET     Subtitle= --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-thumbnail --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json

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
%paste-path%> %TargetFolder%\clipboard.tmp
%Sed-Path% -i -e "s/\"//g";"s/\"$//g" %TargetFolder%\clipboard.tmp
SET /p "clipboard=" < %TargetFolder%\clipboard.tmp
If exist %TargetFolder%\clipboard.tmp del /q %TargetFolder%\clipboard.tmp
REM FOR /f "tokens=* delims=" %%c IN ('%paste-path%') DO SET clipboard=%%c 
:: check if clipboard content is a link
:: quote it because echo doesn't like & and other symbols 
ECHO "%clipboard%" | findstr /R /C:"^.https://.*">NUL 2>&1
:: delete & and everything after (may break links). mostly ok for youtube.
:: something that deletes double quotes (ok when done that way, otherwise crashes when piped).
:: delete spaces. delete newline symbol that sed brings every time.
:: copy link back to clipboard.
if %errorlevel% equ 0 (
ECHO "%clipboard%" | %Sed-Path% -e 's/^&.*//';'s/\"//g';'s/\"$//g';'s/[ \t]*$//' | %tr-Path% -d "\n" | clip >NUL 2>&1
FOR /f "tokens=* delims=" %%c IN ('%paste-path%') DO SET clipboard=%%c
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
ECHO   1. Download Audio
ECHO   2. Download Video
ECHO   3. Download Manually
ECHO   4. Download Subtitles Only
ECHO   5. Download Comments Only
ECHO   6. Download Section
ECHO   7. Stream to Player
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   e. Enter URL		a. Version Info
ECHO   w. Set Downloader	s. Error Info
ECHO   q. Exit		d. Update
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
IF "%choice%"=="a" GOTO :info
IF "%choice%"=="s" GOTO :error-info
IF "%choice%"=="d" GOTO :update
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
ECHO   1. Yes
ECHO   2. No
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   q. Exit
ECHO.
SET /p usearia=!BS!%spcs%Use aria2c as External Downloader? 
IF "%usearia%"=="1" GOTO :start
IF "%usearia%"=="2" GOTO :start
IF "%usearia%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :aria

REM :aria-continue
REM cls
REM ECHO ------------------------------------------------------------------------------------------------------------------------
REM ECHO   %Blue-s%•%ColorOff%  DOWNLOADER
REM ECHO ------------------------------------------------------------------------------------------------------------------------
REM ECHO   1. Yes
REM ECHO   2. No
REM ECHO ------------------------------------------------------------------------------------------------------------------------
REM ECHO   q. Exit
REM ECHO.
REM SET /p usearia=!BS!%spcs%Use aria2c as External Downloader? 
REM IF "%usearia%"=="1" 
REM (IF "%Downloaded-Audio%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Video%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Manual%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Manual-Single%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Comments%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Subs%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Stream%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Sections%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Quick%"=="1" (
REM GOTO :continue
REM ) ELSE (
REM GOTO :start
REM ))))))))))
REM IF "%usearia%"=="2" (IF "%Downloaded-Audio%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Video%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Manual%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Manual-Single%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Comments%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Subs%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Stream%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Sections%"=="1" (
REM GOTO :continue
REM ) ELSE (IF "%Downloaded-Quick%"=="1" (
REM GOTO :continue
REM ) ELSE (
REM GOTO :start
REM ))))))))))
REM IF "%usearia%"=="q" GOTO :exit
REM ECHO ------------------------------------------------------------------------------------------------------------------------
REM ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
REM ECHO ------------------------------------------------------------------------------------------------------------------------
REM timeout /t 2 >nul
REM GOTO :aria-continue

:info
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  VERSION INFO
ECHO ------------------------------------------------------------------------------------------------------------------------
%YTdlp-Path% -v
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
GOTO :start

:error-info
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  YT-DLP ERROR INFO
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Cyan-s%›%ColorOff%  %Bold%0%ColorOff% = No error
ECHO   %Cyan-s%›%ColorOff%  %Bold%1%ColorOff% = Invalid url/Missing file
ECHO   %Cyan-s%›%ColorOff%  %Bold%2%ColorOff% = No arguments/Invalid parameters
ECHO   %Cyan-s%›%ColorOff%  %Bold%3%ColorOff% = File I/O error
ECHO   %Cyan-s%›%ColorOff%  %Bold%4%ColorOff% = Network failure
ECHO   %Cyan-s%›%ColorOff%  %Bold%5%ColorOff% = SSL verification failure
ECHO   %Cyan-s%›%ColorOff%  %Bold%6%ColorOff% = Username/Password failure
ECHO   %Cyan-s%›%ColorOff%  %Bold%7%ColorOff% = Protocol errors
ECHO   %Cyan-s%›%ColorOff%  %Bold%8%ColorOff% = Server issued an error response
ECHO   %Cyan-s%›%ColorOff%  %Bold%403%ColorOff% = Bot protection/Need to set cookies
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Green-s%•%ColorOff%  Done
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
GOTO :start

:update
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  UPDATING...
ECHO ------------------------------------------------------------------------------------------------------------------------
%YTdlp-Path% -U
IF %appErr% NEQ 0 ECHO. & ECHO   %Red-s%•%ColorOff%  %Red-s%ERROR%ColorOff%: yt-dlp ErrorLevel is %Bold%%appErr%%ColorOff%.
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Yellow-s%•%ColorOff%  Wait...
ECHO ------------------------------------------------------------------------------------------------------------------------
PAUSE
GOTO :start

:continue
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  CONTINUE
ECHO ------------------------------------------------------------------------------------------------------------------------
:: meant for download another link with same params
ECHO   1. Download Another?
:: meant to retry failed download with same params (in case if link is invalid)
ECHO   2. Retry
:: resets all variables
ECHO   3. Main Menu
ECHO ------------------------------------------------------------------------------------------------------------------------
:: re-enter link to retry the download
ECHO   e. Re-Enter URL
:: this seems useless here, params won't change from within this menu
REM ECHO   w. Set Downloader
ECHO   q. Exit
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
IF "%choice%"=="3" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET DownloadLinks=& SET AudioQuality=& SET CustomPreset=& SET VideoResolution=& SET VideoFPS=& SET CustomFormat=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& GOTO :start
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
%YTdlp-Path% -F --extractor-args "youtube:player_client=all" "%URL%"
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
GOTO :selection

:selection
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   1. Video + Audio		w. Go Back
ECHO   2. Audio Only / Video Only	q. Exit
ECHO ------------------------------------------------------------------------------------------------------------------------
:: ECHO  w. Go Back
:: ECHO  q. Exit
:: ECHO.
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
cls
SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=
SET Downloaded-Audio=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO FORMAT
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   1. m4a
ECHO   2. mp3
ECHO   3. opus
ECHO   4. aac
ECHO   5. ogg
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   6. m4a (ba/acodec)	 9. m4a + Filter/vbr	12. m4a + Filter/vbr/cutoff+20k
ECHO   7. mp3 (ba/acodec)	10. opus + Filter
ECHO   8. opus (ba/acodec)	11. aac + Filter
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Audio Format: 
IF "%choice%"=="1" SET AudioFormat=m4a& GOTO :select-quality-audio
IF "%choice%"=="2" SET AudioFormat=mp3& GOTO :select-quality-audio
IF "%choice%"=="3" SET AudioFormat=opus& GOTO :select-quality-audio
IF "%choice%"=="4" SET AudioFormat=aac& GOTO :select-quality-audio
IF "%choice%"=="5" SET AudioFormat=vorbis& GOTO :select-quality-audio
IF "%choice%"=="6" SET CustomFormat-m4a=1& SET AudioFormat=m4a& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="7" SET CustomFormat-mp3=1& SET AudioFormat=mp3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="8" SET CustomFormat-opus=2& SET AudioFormat=opus& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="9" SET CustomFormat-m4a=2& SET AudioFormat=m4a& GOTO :select-quality-vbr-audio
IF "%choice%"=="10" SET CustomFormat-opus=1& SET AudioFormat=opus& GOTO :select-quality-audio
IF "%choice%"=="11" SET CustomFormat-aac=2& SET AudioFormat=aac& GOTO :select-quality-audio
IF "%choice%"=="12" SET CustomFormat-m4a=3& SET AudioFormat=m4a& GOTO :select-quality-vbr-audio
IF "%choice%"=="w" IF "%SectionsAudio%"=="1" (GOTO :select-preset-sections) ELSE (GOTO :start)
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-format-audio



:select-quality-audio
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
IF "%AudioFormat%"=="mp3" (
ECHO   1. Quality 0 ^(220-260kbps/vbr^)
) ELSE (
ECHO   1. Quality 1
)
IF "%AudioFormat%"=="mp3" (
ECHO   2. Quality 2 ^(170-210kbps/vbr^)
) ELSE (
ECHO   2. Quality 2
)
IF "%AudioFormat%"=="mp3" (
ECHO   3. Quality 3 ^(150-195kbps/vbr^)
) ELSE (
ECHO   3. Quality 3
)
IF "%AudioFormat%"=="mp3" (
ECHO   4. Quality 4 ^(140-185kbps/vbr^)
) ELSE (
ECHO   4. Quality 4
)
IF "%AudioFormat%"=="mp3" (
ECHO   5. Quality 5 ^(120-150kbps/vbr^) ^(default^) 
) ELSE (
ECHO   5. Quality 5 ^(default^)
)
IF "%AudioFormat%"=="mp3" (
ECHO   6. Quality 6 ^(100-130kbps/vbr^)
) ELSE (
ECHO   6. Quality 6
)
IF "%AudioFormat%"=="mp3" (
ECHO   7. Quality 7 ^(80-120kbps/vbr^)
) ELSE (IF "%AudioFormat%"=="m4a" (
ECHO   7. Quality 7 ^(204-216kbps^) ^(optimal^) 
) ELSE (
ECHO   7. Quality 7
))
IF "%AudioFormat%"=="mp3" (
ECHO   8. Quality 8 ^(70-105kbps/vbr^)
) ELSE (
ECHO   8. Quality 8
)
IF "%AudioFormat%"=="mp3" (
ECHO   9. Quality 9 ^(45-85kbps/vbr^)
) ELSE (
ECHO   9. Quality 9
)
ECHO  10. Quality 10 ^(worst, smaller^)
ECHO ------------------------------------------------------------------------------------------------------------------------
IF "%AudioFormat%"=="mp3" (
ECHO   0. Quality 320k ^(320kbps/cbr^)
) ELSE (
ECHO   0. Quality 0 ^(best, overkill^)
)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   r. Main Menu
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Audio Quality: 
IF "%choice%"=="0" IF "%AudioFormat%"=="mp3" (SET AudioQuality=320k& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)) ELSE (SET AudioQuality=0& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio))
IF "%choice%"=="1" SET AudioQuality=1& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="2" SET AudioQuality=2& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="3" SET AudioQuality=3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="4" SET AudioQuality=4& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="5" SET AudioQuality=5& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="6" SET AudioQuality=6& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="7" SET AudioQuality=7& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="8" SET AudioQuality=8& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="9" SET AudioQuality=9& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="10" SET AudioQuality=10& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="w" GOTO :select-format-audio
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET DownloadLinks=& SET AudioQuality=& SET CustomPreset=& SET VideoResolution=& SET VideoFPS=& SET CustomFormat=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-quality-audio

:select-quality-vbr-audio
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  AUDIO VBR QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   1. Quality 1 ^(40-62kbps) ^(worst^)
ECHO   2. Quality 2 ^(64-80kbps^)
ECHO   3. Quality 3 ^(96-112kbps^)
ECHO   4. Quality 4 ^(128-144kbps^)
ECHO   5. Quality 5 ^(192-224kbps^) ^(best^)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   0. Quality 0 ^(disables VBR, enables CBR^)
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   r. Main Menu
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Audio Quality: 
IF "%choice%"=="0" SET AudioQuality=0& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="1" SET AudioQuality=1& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="2" SET AudioQuality=2& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="3" SET AudioQuality=3& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="4" SET AudioQuality=4& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="5" SET AudioQuality=5& IF "%SectionsAudio%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-audio)
IF "%choice%"=="w" GOTO :select-format-audio
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET DownloadLinks=& SET AudioQuality=& SET CustomPreset=& SET VideoResolution=& SET VideoFPS=& SET CustomFormat=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& GOTO :start
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
ECHO   1. Audio Single				12. Audio Single + Interpret the Title as "Artist - Title"
ECHO   2. Audio Single + Crop Thumbnail		13. Audio Single + Crop + Interpret the Title as "Artist - Title"
ECHO   3. Audio Release
ECHO   4. Audio Release + Crop Thumbnail
ECHO   5. Audio Playlist				14. Audio Playlist + Only New
ECHO   6. Audio Playlist + Crop Thumbnail		15. Audio Playlist + Only New + Crop Thumbnail
ECHO   7. Audio Playlist Release			16. Audio Playlist Release + Only New
ECHO   8. Audio Playlist Release + Crop Thumbnail	17. Audio Playlist Release + Only New + Crop Thumbnail
ECHO   9. Audio Playlist Various Artists		18. Audio Playlist Various Artists + Only New
ECHO  10. Audio + Split by Chapters
ECHO  11. Audio With Top Comments
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   e. Download Links From Text List
ECHO   w. Go Back
ECHO   r. Main Menu
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Choose Preset: 
IF "%choice%"=="1" GOTO :doYTDL-audio-preset-2
IF "%choice%"=="2" GOTO :doYTDL-audio-preset-10
IF "%choice%"=="3" GOTO :doYTDL-audio-preset-3
IF "%choice%"=="4" GOTO :doYTDL-audio-preset-4
IF "%choice%"=="5" GOTO :doYTDL-audio-preset-5
IF "%choice%"=="6" GOTO :doYTDL-audio-preset-6
IF "%choice%"=="7" GOTO :doYTDL-audio-preset-7
IF "%choice%"=="8" GOTO :doYTDL-audio-preset-8
IF "%choice%"=="9" GOTO :doYTDL-audio-preset-9
IF "%choice%"=="10" GOTO :doYTDL-audio-preset-1
IF "%choice%"=="11" SET CustomPreset=1& GOTO :doYTDL-audio-preset-2
IF "%choice%"=="12" SET FormatTitle=1& GOTO :doYTDL-audio-preset-2
IF "%choice%"=="13" SET FormatTitle=1& GOTO :doYTDL-audio-preset-10
IF "%choice%"=="14" SET OnlyNew=1& GOTO :doYTDL-audio-preset-5
IF "%choice%"=="15" SET OnlyNew=1& GOTO :doYTDL-audio-preset-6
IF "%choice%"=="16" SET OnlyNew=1& GOTO :doYTDL-audio-preset-7
IF "%choice%"=="17" SET OnlyNew=1& GOTO :doYTDL-audio-preset-8
IF "%choice%"=="18" SET OnlyNew=1& GOTO :doYTDL-audio-preset-9
IF "%choice%"=="e" SET DownloadLinks=1& GOTO :doYTDL-audio-preset-0
IF "%choice%"=="w" IF "%CustomFormat-m4a%"=="2" (GOTO :select-quality-vbr-audio) ELSE (IF "%CustomFormat-m4a%"=="3" (GOTO :select-quality-vbr-audio) ELSE (IF "%CustomFormat-opus%"=="2" (GOTO :select-format-audio) ELSE (IF "%CustomFormat-mp3%"=="1" (GOTO :select-format-audio) ELSE (IF "%CustomFormat-m4a%"=="1" (GOTO :select-format-audio) ELSE (GOTO :select-quality-audio)))))
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET DownloadLinks=& SET AudioQuality=& SET CustomPreset=& SET VideoResolution=& SET VideoFPS=& SET CustomFormat=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& GOTO :start
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
SET CustomFormat=
SET Downloaded-Video=
cls
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  VIDEO QUALITY
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   1. 320p/30fps
ECHO   2. 480p/30fps
ECHO   3. 720p/30fps
ECHO   4. 720p/%Red-s%60%ColorOff%fps
ECHO   5. 1080p/30fps
ECHO   6. 1080p/%Red-s%60%ColorOff%fps
ECHO   7. 1440p/30fps
ECHO   8. 1440p/%Red-s%60%ColorOff%fps
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   9. Best Video			13. ^<480p + Best Video		17. ^<480p/mp4/aac/vp9
ECHO  10. Worst Video		14. ^<720p/mp4/m4a/h264/30fps	18. ^<480p/mp4/aac/vp9 + Audio Filter
ECHO  11. Smallest Size		15. ^<720p/fps^>30
ECHO  12. Best Codec + Best Bitrate	16. ^<1080p/mp4/m4a
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Select Video Quality: 
IF "%choice%"=="1" SET VideoResolution=320& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="2" SET VideoResolution=480& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="3" SET VideoResolution=720& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="4" SET VideoResolution=720& SET VideoFPS=60& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="5" SET VideoResolution=1080& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="6" SET VideoResolution=1080& SET VideoFPS=60& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="7" SET VideoResolution=1440& SET VideoFPS=30& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="8" SET VideoResolution=1440& SET VideoFPS=60& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="9" SET CustomFormat=1& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="10" SET CustomFormat=2& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="11" SET CustomFormat=3& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="12" SET CustomFormat=4& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="13" SET CustomFormat=5& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="14" SET CustomFormat=6& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="15" SET CustomFormat=7& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="16" SET CustomFormat=8& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="17" SET CustomFormat=9& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="18" SET CustomFormat=10& IF "%SectionsVideo%"=="1" (GOTO :select-sections-number) ELSE (GOTO :select-preset-video)
IF "%choice%"=="w" IF "%SectionsVideo%"=="1" (GOTO :select-preset-sections) ELSE (GOTO :start)
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
ECHO   1. Video Single
ECHO   2. Video Single + Top Comments
ECHO   3. Video Playlist
ECHO   4. Video Playlist + Top Comments
ECHO   5. Video + Split by Chapters
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   e. Download Links From Text List
ECHO   w. Go Back
ECHO   r. Main Menu
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Choose Preset: 
IF "%choice%"=="1" GOTO :doYTDL-video-preset-2
IF "%choice%"=="2" GOTO :doYTDL-video-preset-3
IF "%choice%"=="3" GOTO :doYTDL-video-preset-4
IF "%choice%"=="4" GOTO :doYTDL-video-preset-5
IF "%choice%"=="5" GOTO :doYTDL-video-preset-1
IF "%choice%"=="e" SET DownloadLinks=1& SET CustomPreset=1& GOTO :doYTDL-video-preset-2
IF "%choice%"=="w" GOTO :select-format-video
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET DownloadLinks=& SET AudioQuality=& SET CustomPreset=& SET VideoResolution=& SET VideoFPS=& SET CustomFormat=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& GOTO :start
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
ECHO   1. Download Subtitles
ECHO   2. Download Transcript
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Choose Preset: 
IF "%choice%"=="1" SET SubsPreset=1& GOTO :subs-preset-1
IF "%choice%"=="2" SET SubsPreset=2& GOTO :subs-preset-1
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
ECHO   1.   25 Comments Sorted by TOP
ECHO   2.   25 Comments Sorted by TOP and Converted to HTML
ECHO   3.  500 Comments Sorted by TOP
ECHO   4.  500 Comments Sorted by TOP and Converted to HTML
ECHO   5.  ALL Comments Sorted by TOP
ECHO   6.  ALL Comments Sorted by TOP and Converted to HTML
ECHO   7.   25 Comments Sorted by NEW
ECHO   8.   25 Comments Sorted by NEW and Converted to HTML
ECHO   9.  500 Comments Sorted by NEW
ECHO  10.  500 Comments Sorted by NEW and Converted to HTML	13.  500 Comments Converted to HTML + Sorted by NEW
ECHO  11.  ALL Comments Sorted by NEW
ECHO  12.  ALL Comments Sorted by NEW and Converted to HTML
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   q. Exit
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
ECHO   1. Stream Audio
ECHO   2. Stream Video
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   q. Exit
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
ECHO   1. Best Audio
ECHO   2. Best Audio + Best Protocol
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   r. Main Menu
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Enter Your Choice: 
IF "%choice%"=="1" SET StreamVideoFormat=& SET StreamAudioFormat=1& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="2" SET StreamVideoFormat=& SET StreamAudioFormat=2& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="w" GOTO :select-format-stream
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET DownloadLinks=& SET AudioQuality=& SET CustomPreset=& SET VideoResolution=& SET VideoFPS=& SET CustomFormat=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& GOTO :start
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
ECHO   1. ^<480p/30fps
ECHO   2. ^<720p/^<%Red-s%60%ColorOff%fps
ECHO   3. Best Video + Best Audio
ECHO   4. Best Video + Best Protocol
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   r. Main Menu
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Enter Your Choice: 
IF "%choice%"=="1" SET StreamAudioFormat=& SET StreamVideoFormat=1& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="2" SET StreamAudioFormat=& SET StreamVideoFormat=2& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="3" SET StreamAudioFormat=& SET StreamVideoFormat=3& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="4" SET StreamAudioFormat=& SET StreamVideoFormat=4& GOTO :doYTDL-preset-stream-1
IF "%choice%"=="w" GOTO :select-format-stream
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET DownloadLinks=& SET AudioQuality=& SET CustomPreset=& SET VideoResolution=& SET VideoFPS=& SET CustomFormat=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& GOTO :start
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
cls
SET Downloaded-Sections=
SET SectionsAudio=
SET SectionsVideo=
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Blue-s%•%ColorOff%  FORMAT
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   1. Download Audio Sections
ECHO   2. Download Video Sections
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   q. Exit
ECHO.
SET /p choice=!BS!%spcs%Enter Your Choice: 
IF "%choice%"=="1" SET SectionsAudio=1& GOTO :select-format-audio
IF "%choice%"=="2" SET SectionsVideo=1& GOTO :select-format-video
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
ECHO   1. Set 1 Section
ECHO   2. Set 2 Sections
ECHO   3. Set 3 Sections
ECHO   4. Set 4 Sections
ECHO   5. Set 5 Sections
ECHO   6. Set 6 Sections
ECHO   7. Set 7 Sections
ECHO   8. Set 8 Sections
ECHO   9. Set 9 Sections
ECHO  10. Set 10 Sections
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   w. Go Back
ECHO   r. Main Menu
ECHO   q. Exit
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
IF "%choice%"=="w" GOTO 
IF "%choice%"=="w" IF "%SectionsVideo%"=="1" (GOTO :select-format-video) ELSE (IF "%SectionsAudio%"=="1" (GOTO :select-quality-audio) ELSE (GOTO :select-preset-sections))
IF "%choice%"=="r" SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET DownloadLinks=& SET AudioQuality=& SET CustomPreset=& SET VideoResolution=& SET VideoFPS=& SET CustomFormat=& SET StreamAudioFormat=& SET CustomFormat-m4a=& SET CustomFormat-mp3=& SET CustomFormat-aac=& SET CustomFormat-opus=& SET StreamVideoFormat=& SET CommentPreset=& SET SectionsAudio=& SET SectionsVideo=& SET DoSections=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET OnlyNew=& SET Downloaded-Quick=& SET SubsPreset=& SET FormatTitle=& GOTO :start
IF "%choice%"=="q" GOTO :exit
ECHO ------------------------------------------------------------------------------------------------------------------------
ECHO   %Red-s%•%ColorOff%  Invalid choice, please try again.
ECHO ------------------------------------------------------------------------------------------------------------------------
timeout /t 2 >nul
GOTO :select-sections-number

:enter-sections-1
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
GOTO :sections-preset-1
:enter-sections-2
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
GOTO :sections-preset-1
:enter-sections-3
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
GOTO :sections-preset-1
:enter-sections-4
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
GOTO :sections-preset-1
:enter-sections-5
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
GOTO :sections-preset-1
:enter-sections-6
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
GOTO :sections-preset-1
:enter-sections-7
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
SET /P section7=!BS!%spcs%Enter Section 7 Time: 
GOTO :sections-preset-1
:enter-sections-8
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
SET /P section7=!BS!%spcs%Enter Section 7 Time: 
SET /P section8=!BS!%spcs%Enter Section 8 Time: 
GOTO :sections-preset-1
:enter-sections-9
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
SET /P section7=!BS!%spcs%Enter Section 7 Time: 
SET /P section8=!BS!%spcs%Enter Section 8 Time: 
SET /P section9=!BS!%spcs%Enter Section 9 Time: 
GOTO :sections-preset-1
:enter-sections-10
SET /P section1=!BS!%spcs%Enter Section Time (ex. 21:00-22:00): 
SET /P section2=!BS!%spcs%Enter Section 2 Time: 
SET /P section3=!BS!%spcs%Enter Section 3 Time: 
SET /P section4=!BS!%spcs%Enter Section 4 Time: 
SET /P section5=!BS!%spcs%Enter Section 5 Time: 
SET /P section6=!BS!%spcs%Enter Section 6 Time: 
SET /P section7=!BS!%spcs%Enter Section 7 Time: 
SET /P section8=!BS!%spcs%Enter Section 8 Time: 
SET /P section9=!BS!%spcs%Enter Section 9 Time: 
SET /P section10=!BS!%spcs%Enter Section 10 Time: 
GOTO :sections-preset-1

::
::
:: AUDIO PRESETS
::
::

:: DOWNLOAD LINKS FROM FILE PRESET
:doYTDL-audio-preset-0
SET  OutTemplate= --output "%TargetFolder%\%%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%" --batch-file "%List-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO SPLIT PRESET
:doYTDL-audio-preset-1
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist,uploader)s - %%(title)s\chapter:%%(section_number)03d. %%(section_title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive --no-playlist --split-chapters --download-sections "*0:00-inf"
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
IF "%FormatTitle%"=="1" (
SET   PreProcess= --parse-metadata "title:%(artist)s - %(title)s" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
) ELSE (
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
)
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json --force-keyframes-at-cuts
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL


:: AUDIO SINGLE PRESET
:doYTDL-audio-preset-2
SET  OutTemplate= --output "%TargetFolder%\%%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive --no-playlist
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
IF "%CustomPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=10;comment_sort=top"
) ELSE (
SET     Comments=
)
SET Authenticate=
IF "%CustomPreset%"=="1" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
) ELSE (
SET     AdobePass=
)
IF "%FormatTitle%"=="1" (
SET   PreProcess= --parse-metadata "title:%(artist)s - %(title)s" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
) ELSE (
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
)
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO SINGLE PRESET + CROP THUMBNAIL PRESET
:doYTDL-audio-preset-10
SET  OutTemplate= --output "%TargetFolder%\%%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive --no-playlist
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail= --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\""
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "ba[acodec^=mp4a.40.]/ba[acodec^=aac]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --format 136 --postprocessor-args ExtractAudio:"-y -ac 2 -c:a libfdk_aac -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --format 136 --postprocessor-args ExtractAudio:"-y -ac 2 -c:a libfdk_aac -vbr 0 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --postprocessor-args ExtractAudio:"-vn -y -ac 2 -c:a aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""  --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --postprocessor-args ExtractAudio:"-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
IF "%CustomPreset%"=="1" (
SET     Comments= --write-comments --extractor-args "youtube:max_comments=10;comment_sort=top"
) ELSE (
SET     Comments=
)
SET Authenticate=
IF "%CustomPreset%"=="1" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
) ELSE (
SET     AdobePass=
)
IF "%FormatTitle%"=="1" (
SET   PreProcess= --parse-metadata "title:%(artist)s - %(title)s" --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
) ELSE (
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
)
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO RELEASE PRESET
:doYTDL-audio-preset-3
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist)s - %%(title)s (%%(album)s, %%(release_year,release_date>%%Y,upload_date>%%Y)s).%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive --no-playlist
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO RELEASE + CROP THUMBNAIL PRESET
:doYTDL-audio-preset-4
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist)s - %%(title)s (%%(album)s, %%(release_year,release_date>%%Y,upload_date>%%Y)s).%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive --no-playlist
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail= --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\""
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO PLAYLIST PRESET
:doYTDL-audio-preset-5
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(release_year,release_date>%%Y,upload_date>%%Y)s - %%(playlist_title,playlist|)s\%%(playlist_index,autonumber)03d. %%(title)s.%%(ext)s" 
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Folder%\archive.txt" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO PLAYLIST + CROP THUMBNAIL PRESET
:doYTDL-audio-preset-6
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(release_year,release_date>%%Y,upload_date>%%Y)s - %%(playlist_title,playlist|)s\%%(playlist_index,autonumber)03d. %%(title)s.%%(ext)s" 
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Folder%\archive.txt" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail= --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\""
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO PLAYLIST RELEASE PRESET
:doYTDL-audio-preset-7
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist,uploader)s\%%(release_year,release_date>%%Y,upload_date>%%Y)s - %%(album,playlist_title,playlist|)s\%%(playlist_index,autonumber)03d. %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Folder%\archive.txt" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO PLAYLIST RELEASE + CROP THUMBNAIL PRESET
:doYTDL-audio-preset-8
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist,uploader)s\%%(release_year,release_date>%%Y,upload_date>%%Y)s - %%(album,playlist_title,playlist|)s\%%(playlist_index,autonumber)03d. %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Folder%\archive.txt" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail= --embed-thumbnail --postprocessor-args "ThumbnailsConvertor+ffmpeg_o: -c:v %FFmpeg-Thumb-Format% -q:v %Thumb-Compress% -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\""
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: AUDIO PLAYLIST VARIOUS ARTISTS PRESET
:doYTDL-audio-preset-9
SET  OutTemplate= --output "%TargetFolder%\%%(meta_album_artist)s\%%(release_year,release_date>%%Y,upload_date>%%Y)s - %%(meta_album)s\%%(playlist_index,meta_track,autonumber)03d. %%(meta_artist)s - %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Folder%\archive.txt" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --no-sponsorblock
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
)))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist "^.*$" "Various Artists" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=1& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

::
::
:: VIDEO PRESETS
::
::

:: VIDEO SPLIT PRESET
:doYTDL-video-preset-1
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist,uploader)s - %%(title)s\chapter:%%(section_number)03d. %%(section_title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive --no-playlist --split-chapters --download-sections "*0:00-inf"
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormat%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormat%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --ppa Merger:"-ac 2 -c:a libfdk_aac -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat%"=="10" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-quality 0 --audio-format m4a --ppa Merger:"-y -ac 2 -c:a libfdk_aac -cutoff 20000 -afterburner 1 -vbr 0 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
))))))))))
SET     Subtitle= 
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-thumbnail --embed-metadata --compat-options no-attach-info-json --force-keyframes-at-cuts
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: VIDEO SINGLE PRESET
:doYTDL-video-preset-2
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist,uploader)s - %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive --no-playlist
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview
IF "%CustomPreset%"=="1" (
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%" --batch-file "%List-Path%"
) ELSE (
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
)
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormat%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormat%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --ppa Merger:"-ac 2 -c:a libfdk_aac -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat%"=="10" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-quality 0 --audio-format m4a --ppa Merger:"-y -ac 2 -c:a libfdk_aac -cutoff 20000 -afterburner 1 -vbr 0 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
))))))))))
SET     Subtitle= --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-thumbnail --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: VIDEO SINGLE + TOP COMMENTS PRESET
:doYTDL-video-preset-3
SET  OutTemplate= --output "%TargetFolder%\%%(artists.0,artist,uploader)s - %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select= --no-download-archive --no-playlist
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormat%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormat%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --ppa Merger:"-ac 2 -c:a libfdk_aac -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
)))))))))
SET     Subtitle= --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
SET     Comments= --write-comments --extractor-args "youtube:max_comments=50;comment_sort=top"
SET Authenticate=
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-thumbnail --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json 
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: VIDEO PLAYLIST PRESET
:doYTDL-video-preset-4
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(release_year,release_date>%%Y,upload_date>%%Y)s - %%(playlist_title,playlist|)s\%%(playlist_index,autonumber)03d. %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Folder%\archive.txt" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormat%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormat%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --ppa Merger:"-ac 2 -c:a libfdk_aac -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat%"=="10" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-quality 0 --audio-format m4a --ppa Merger:"-y -ac 2 -c:a libfdk_aac -cutoff 20000 -afterburner 1 -vbr 0 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
))))))))))
SET     Subtitle= --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-thumbnail --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: VIDEO PLAYLIST + TOP COMMENTS PRESET
:doYTDL-video-preset-5
SET  OutTemplate= --output "%TargetFolder%\%%(uploader)s\%%(release_year,release_date>%%Y,upload_date>%%Y)s - %%(playlist_title,playlist|)s\%%(playlist_index,autonumber)03d. %%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
IF "%OnlyNew%"=="1" (
SET       Select= --download-archive "%Archive-Folder%\archive.txt" --no-overwrites --yes-playlist --no-playlist-reverse
) ELSE (
SET       Select= --no-download-archive --yes-playlist --no-playlist-reverse
)
IF "%usearia%"=="1" (
SET     Download= --limit-rate %SpeedLimit% --downloader "%Aria2-Path%" --downloader-args "aria2c: %Aria-Args%" --compat-options no-external-downloader-progress
) ELSE (
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads%
)
SET Sponsorblock= --sponsorblock-mark sponsor,preview --sponsorblock-remove sponsor,preview
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormat%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormat%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --ppa Merger:"-ac 2 -c:a libfdk_aac -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat%"=="10" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-quality 0 --audio-format m4a --ppa Merger:"-y -ac 2 -c:a libfdk_aac -cutoff 20000 -afterburner 1 -vbr 0 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
))))))))))
SET     Subtitle= --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
SET     Comments= --write-comments --extractor-args "youtube:max_comments=50;comment_sort=top"
SET Authenticate=
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists.0,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata "description:(?s)(?P<meta_comment>.+)" --parse-metadata ":(?P<meta_description>)" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET  PostProcess= --embed-thumbnail --embed-metadata --embed-chapters --embed-subs --compat-options no-attach-info-json
:: setting variables for continue menu
SET Downloaded-Video=1& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

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
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select=
SET     Download= --skip-download --concurrent-fragments 1
SET Sponsorblock=
SET   FileSystem= --no-cache-dir --ffmpeg-location "%FFmpeg-Path%"
SET    Thumbnail=
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
SET       Format=
IF "%SubsPreset%"=="1" (
SET     Subtitle= --write-subs --write-auto-subs --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
) ELSE (IF "%SubsPreset%"=="2" (
SET     Subtitle= --write-subs --write-auto-subs --sub-format ttml --convert-subs srt --sub-langs "%Sub-langs%" --compat-options no-live-chat
))
SET     Comments=
SET Authenticate=
IF "%SubsPreset%"=="1" (
SET    AdobePass= --write-subs --write-auto-subs --sub-format "%Sub-Format%" --sub-langs "%Sub-langs%" --compat-options no-live-chat
) ELSE (IF "%SubsPreset%"=="2" (
SET    AdobePass= --exec before_dl:"%Sed-Path% -i -f \"%Sed-Commands%\" %%(requested_subtitles.:.filepath)#q"
))
SET   PreProcess=
SET  PostProcess=
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=1& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

:: DOWNLOAD JUST COMMENTS
:comments-preset-1
SET  OutTemplate= --output "%TargetFolder%\%%(title)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select=
SET     Download= --skip-download
SET Sponsorblock=
SET   FileSystem= --no-cache-dir --ffmpeg-location "%FFmpeg-Path%"
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
SET Authenticate=
IF "%CommentPreset%"=="1" (
SET    AdobePass= --exec pre_process:"del %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="2" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="3" (
SET    AdobePass= --exec pre_process:"del %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="4" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="5" (
SET    AdobePass= --exec pre_process:"del %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="6" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="7" (
SET    AdobePass= --exec pre_process:"del %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="8" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="9" (
SET    AdobePass= --exec pre_process:"del %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="10" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="11" (
SET    AdobePass= --exec pre_process:"del %%(id)s.comments.json"
) ELSE (IF "%CommentPreset%"=="12" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_fork.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
) ELSE (IF "%CommentPreset%"=="13" (
SET    AdobePass= --exec before_dl:"%Python-Path% "%YTdlp-Folder%\yt-dlp_nest_comments_new.py" -i %%(infojson_filename)#q -o %%(infojson_filename)#q.comments.html" --exec before_dl:"del %%(infojson_filename)#q"
)))))))))))))
SET   PreProcess=
SET  PostProcess=
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=1& SET Downloaded-Subs=& SET Downloaded-Sections=& SET Downloaded-Stream=& SET Downloaded-Quick=& GOTO :doYTDL

::
::
:: STREAM TO PLAYER PRESETS
::
::

:: STREAM TO PLAYER
:doYTDL-preset-stream-1
SET  OutTemplate= --output -
SET      Options= --ignore-errors --ignore-config
SET      Network=
SET  GeoRestrict= --xff "default"
SET       Select=
SET     Download= --limit-rate %SpeedLimit% --concurrent-fragments %Threads% --downloader "%FFmpeg-Path%"
SET Sponsorblock=
SET   FileSystem= --no-cache-dir --ffmpeg-location "%FFmpeg-Path%"
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
SET Authenticate=
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
SET  OutTemplate= --output "%TargetFolder%\%%(id)s_%%(title)s_%%(duration)s.%%(ext)s"
SET      Options= --ignore-errors --ignore-config
SET      Network=
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
SET   FileSystem= --no-cache-dir --no-mtime --no-part --ffmpeg-location "%FFmpeg-Path%"
IF "%Thumb-Format%"=="jpg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (IF "%Thumb-Format%"=="jpeg" (
SET    Thumbnail= --convert-thumbnail %Thumb-Format% --postprocessor-args "ThumbnailsConvertor:-q:v %Thumb-Compress%"
) ELSE (
SET    Thumbnail= --convert-thumbnail %Thumb-Format%
))
SET    Verbosity= --console-title --progress --progress-template ["Progress":" %%(progress._percent_str)s","Total Bytes":" %%(progress._total_bytes_str)s","Speed":" %%(progress._speed_str)s","ETA":" %%(progress._eta_str)s"]
SET  WorkArounds=
IF "%CustomFormat-mp3%"=="1" (
SET       Format= --format "ba[acodec^=mp3]/ba/b" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="1" (
SET       Format= --format "141/256/140/22/18/139" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-m4a%"=="2" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-m4a%"=="3" (
SET       Format= --extract-audio --format "ba/b" --audio-format %AudioFormat% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -vbr %AudioQuality% -cutoff 20000 -afterburner 1 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\"" --force-overwrites --post-overwrites
) ELSE (IF "%CustomFormat-opus%"=="2" (
SET       Format= --format "774/251/250/249" --extract-audio --audio-format %AudioFormat%
) ELSE (IF "%CustomFormat-aac%"=="2" (
SET       Format= --extract-audio --format "141/256/140/22/18/139" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libfdk_aac -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat-opus%"=="1" (
SET       Format= --extract-audio --format "774/251/250/249" --audio-format %AudioFormat% --audio-quality %AudioQuality% --postprocessor-args "ExtractAudio:-vn -y -ac 2 -c:a libopus -filter_complex \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%SectionsAudio%"=="1" (
SET       Format= --extract-audio --audio-format %AudioFormat% --audio-quality %AudioQuality%
) ELSE (IF "%CustomFormat%"=="1" (
SET       Format= --format "bv*+ba/b" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="2" (
SET       Format= -f "wv*+wa/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="3" (
SET       Format= -S "+size,+br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="4" (
SET       Format= -S "+res:480,codec,br" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="5" (
SET       Format= --format "bv*[height<=480]+ba/b[height<=480] / wv*+ba/w" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="6" (
SET       Format= --format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best" -S "vcodec:h264,fps:30,acodec:mp4a,channels:2"
) ELSE (IF "%CustomFormat%"=="7" (
SET       Format= --format "((bv*[fps>30]/bv*)[height<=720]/(wv*[fps>30]/wv*)) + ba / (b[fps>30]/b)[height<=720]/(w[fps>30]/w)" --merge-output-format mkv --remux-video mkv
) ELSE (IF "%CustomFormat%"=="8" (
SET       Format= --format "bestvideo[height<=1080][dynamic_range=?SDR]+bestaudio/bestvideo[height<=1080][ext=mp4][dynamic_range=?SDR]+bestaudio[ext=m4a]/best"
) ELSE (IF "%CustomFormat%"=="9" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --ppa Merger:"-ac 2 -c:a libfdk_aac -vbr 5 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%CustomFormat%"=="10" (
SET       Format= -S "res:480,codec:vp9" --merge-output-format mp4 --audio-quality 0 --audio-format m4a --ppa Merger:"-y -ac 2 -c:a libfdk_aac -cutoff 20000 -afterburner 1 -vbr 0 -af \"compand=0 0:1 1:-90/-900 -70/-70 -30/-9 0/-3:6:3:0:0,bass=g=4:f=110:w=0.6,dynaudnorm\""
) ELSE (IF "%SectionsVideo%"=="1" (
SET       Format= --format "bestvideo[height=?%VideoResolution%][fps=?%VideoFPS%]+bestaudio/bestvideo[height<=?%VideoResolution%][fps<=?%VideoFPS%]+bestaudio/best" --merge-output-format mkv --remux-video mkv
)))))))))))))))))))
SET     Subtitle=
SET     Comments=
SET Authenticate=
SET    AdobePass=
SET   PreProcess= --parse-metadata "%%(epoch>%%Y-%%m-%%d)s:%%(meta_download_date)s" --parse-metadata "%%(album,playlist_title)s:%%(meta_album)s" --parse-metadata "%%(album_artist,album_artists,uploader)s:%%(meta_album_artist)s" --parse-metadata "%%(artist,artists,creator,uploader)s:%%(meta_artist)s" --parse-metadata "%%(average_rating)s:%%(meta_rating)s" --parse-metadata "%%(composer,composers)s:%%(meta_composer)s" --parse-metadata "%%(disc_number)s:%%(meta_disc)s" --parse-metadata "%%(dislike_count)s:%%(meta_dislikes)s" --parse-metadata "%%(genre,genres)s:%%(meta_genre)s" --parse-metadata "%%(like_count)s:%%(meta_likes)s" --parse-metadata "%%(playlist_index,track_number|01)s:%%(meta_track)s" --parse-metadata "%%(release_date>%%Y-%%m-%%d,release_year,upload_date>%%Y-%%m-%%d)s:%%(meta_date)s" --parse-metadata "%%(view_count)s:%%(meta_views)s" --parse-metadata ":(?P<meta_longdescription>)" --parse-metadata ":(?P<meta_synopsis>)" --parse-metadata ":(?P<meta_encodersettings>)" --parse-metadata ":(?P<meta_purl>)" --parse-metadata "webpage_url:%%(meta_www)s" --replace-in-metadata meta_album_artist " - Topic" "" --replace-in-metadata meta_date "^NA$" "" --replace-in-metadata meta_rating "^NA$" "" --replace-in-metadata meta_views "^NA$" "" --replace-in-metadata meta_likes "^NA$" "" --replace-in-metadata meta_dislikes "^NA$" "" --replace-in-metadata meta_disc "^NA$" "" --replace-in-metadata meta_encodersettings "^.*$" "" --replace-in-metadata meta_composer "^NA$" "" --replace-in-metadata meta_album "^NA$" "" --replace-in-metadata meta_genre "^NA$" "" --replace-in-metadata title "/" "⁄" --replace-in-metadata title ":" "꞉" --replace-in-metadata album "/" "⁄" --replace-in-metadata album ":" "꞉"
SET PostProcess= --embed-metadata --embed-thumbnail --compat-options no-attach-info-json --force-keyframes-at-cuts
:: setting variables for continue menu
SET Downloaded-Video=& SET Downloaded-Audio=& SET Downloaded-Manual=& SET Downloaded-Manual-Single=& SET Downloaded-Comments=& SET Downloaded-Subs=& SET Downloaded-Stream=& SET Downloaded-Sections=1& SET Downloaded-Quick=& GOTO :doYTDL-sections

::
::
:: DOWNLOADER
::
::

:doYTDL
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
IF "%DownloadLinks%"=="1" (
ECHO   %Green-n%›%ColorOff%  URLs: %Underline%%List-Path%%ColorOff%
) ELSE (
ECHO   %Green-n%›%ColorOff%  URL: %Underline%%URL%%ColorOff%
)
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
ECHO   %Green-n%›%ColorOff%  URL: %Underline%%URL%%ColorOff%
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
ECHO   %Green-n%›%ColorOff%  URL: %Underline%%URL%%ColorOff%
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
ECHO   %Green-n%›%ColorOff%  URL: %Underline%%URL%%ColorOff%
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
ECHO   %Green-n%›%ColorOff%  URL:%Underline%%*%ColorOff%
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
