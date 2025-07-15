import os
import sys

class Config:
    if sys.platform.startswith('win32'):
        KEMONO_BASEPATH = r'E:\ACG\kemono'
        DB_PATH = r'D:\ACG\imagesShown\images_python.sqlite3'
    else:
        KEMONO_BASEPATH = r'/Volumes/ACG/kemono'
        # 默认数据库路径
        DB_PATH = r'/Volumes/imagesShown/images_python.sqlite3'

    # 您可以根据需要添加其他配置项
    LOG_LEVEL = "INFO"
