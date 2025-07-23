import os
import sys

class Config:
    if sys.platform.startswith('win32'):
        KEMONO_BASEPATH = r'E:\ACG\kemono'
        KEMONO_DB_PATH = r'D:\ACG\imagesShown\kemono.sqlite3'
        TWITTER_BASEPATH = r'E:\ACG\twitter'
        TWITTER_DB_PATH = r'D:\ACG\imagesShown\twitter.sqlite3'
        PIXIV_BASEPATH = r'E:\ACG\pixiv'
        PIXIV_DB_PATH = r'D:\ACG\imagesShown\pixiv.sqlite3'
    else:
        KEMONO_BASEPATH = r'/Volumes/ACG/kemono'
        KEMONO_DB_PATH = r'/Volumes/imagesShown/kemono.sqlite3'
        TWITTER_BASEPATH = r'/Volumes/ACG/twitter'
        TWITTER_DB_PATH = r'/Volumes/imagesShown/twitter.sqlite3'
        PIXIV_BASEPATH = r'/Volumes/ACG/pixiv'
        PIXIV_DB_PATH = r'/Volumes/imagesShown/pixiv.sqlite3'

    # 您可以根据需要添加其他配置项
    LOG_LEVEL = "INFO"
