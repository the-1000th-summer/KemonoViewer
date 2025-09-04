# Kemono Viewer

<img src="mainIcon_round.png" alt="appIcon" width="200"/>

This app is designed to manage media files downloaded from **kemono.cr**, **Twitter**, and **Pixiv**. Its key features include:

* Direct browsing of media files downloaded from any of the three platforms
* Seamless navigation across posts/tweets/artists — when all media in the current item is viewed, navigating to the next/previous image will automatically switch to the next/previous post/tweet/artist
* The playback state of GIFs and Ugoira animations can be controlled, allowing you to pause and view any individual frame. Efforts have been made to fix the issue of slow playback speed when full playback control is enabled.
* During autoplay, the app waits for videos/animations (e.g. GIFs) to finish playing before proceeding to the next media file
* In full-screen mode, you can freely zoom and move media using mouse wheel and drag
* The UI of comment sections is designed to closely resemble those of the original websites
* A local SQLite database is used to keep track of which media files have been viewed

## How to Use

### 1. Download Media Files
All downloaders use Python. Please refer to each downloader’s documentation for Python environment setup.

- kemono.cr: Download using [KToolBox](https://github.com/Ljzd-PRO/KToolBox)
- Twitter: Download using [twitter_download](https://github.com/caolvchong-top/twitter_download)
- Pixiv: Download using [PixivUtil2](https://github.com/Nandaka/PixivUtil2)

Configuration files for the downloaders are provided in the `refFile` folder:
- KToolBox: `.env`
- twitter_download: `settings.json`
- PixivUtil2: `config.ini`

### 2. Use the Provided Python Scripts to Populate the SQLite Database

#### 2.1 Dependencies
The Python scripts require the `peewee` library. Install it via pip or conda:

`pip install peewee`

`conda install -c conda-forge peewee`

#### 2.2 Set File Paths
Modify pythonUtil/filePathConfig.py to specify the paths to your downloaded files and database.

#### 2.3 Run the Scripts
- For kemono.cr: `python kemono_sync.py`
- For Twitter: `python twitter_sync.py`
- For Pixiv: `python pixiv_sync.py`

The first time you run the script, it will create a database at the path specified in filePathConfig.py. You’ll need to rerun the scripts manually whenever new files are downloaded.

### 3. Browse with Kemono Viewer
After launching the app, go to Settings and set the paths for downloaded files and the database. You can then start browsing media.

The app isn't notarized, so a window saying "Apple cannot verify 'KemonoViewer.app'" will pop up. Please go to Settings > Privacy & Security > Security and click "Open Anyway" to open the app. [Reference](https://developer.apple.com/news/?id=saqachfa)

## TODO

* Add English and Chinese language support to the software
* Remove or repurpose unused code
