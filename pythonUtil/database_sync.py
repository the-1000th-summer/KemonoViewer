
import sys
from peewee import *
import json
import datetime
import os

from filePathConfig import Config

db = SqliteDatabase(Config.DB_PATH, pragmas={'foreign_keys': 1})

# 单例装饰器
def singleton(cls):
    instances = {}

    def get_instance(*args, **kwargs):
        if cls not in instances:
            instances[cls] = cls(*args, **kwargs)
        return instances[cls]
    return get_instance


class BaseModel(Model):
    class Meta:
        database = db


class Artist(BaseModel):
    id = AutoField(column_name='id')  # 自动递增主键
    name = TextField(column_name='name')
    service = TextField(column_name='service')

    class Meta:
        table_name = 'artist'


class KemonoPost(BaseModel):
    id = AutoField(column_name='id')
    artist = ForeignKeyField(Artist, column_name='artist_id', backref='posts', on_delete='CASCADE')
    name = TextField(column_name='name')
    post_date = TextField(column_name='post_date')
    cover_img_file_name = TextField(column_name='cover_name')
    post_folder_name = TextField(column_name='folder_name')
    attachment_number = IntegerField(column_name='att_number')
    viewed = BooleanField(column_name='viewed', default=False)

    class Meta:
        table_name = 'kemonoPost'


class KemonoImage(BaseModel):
    id = AutoField(column_name='id')
    post = ForeignKeyField(KemonoPost, column_name='post_id', backref='images', on_delete='CASCADE')
    image_name = TextField(column_name='name')

    class Meta:
        table_name = 'kemonoImage'

@singleton  # 应用单例装饰器
class DatabaseManager:
    def __init__(self):
        db_exists = os.path.exists(Config.DB_PATH)

        try:
            db.connect()
            # 如果数据库不存在，创建所有表
            if not db_exists:
                self.create_tables()
        except Exception as e:
            print(f"数据库连接失败: {e}")

    def create_tables(self):
        try:
            with db:
                db.create_tables([Artist, KemonoPost, KemonoImage])
                print("所有表创建成功")
        except Exception as e:
            print(f"创建表失败: {e}")

    def parseDate(self, date_str):
        # 原始格式示例: "2023-10-05T14:48:00.000Z"
        try:
            # 尝试不带毫秒的格式
            return datetime.datetime.strptime(date_str, '%Y-%m-%dT%H:%M:%S')
        except ValueError:
            # 移除末尾的 'Z' 并解析为 UTC 时间
            date_str = date_str.rstrip('Z')
            return datetime.datetime.strptime(date_str, '%Y-%m-%dT%H:%M:%S.%f')

    def getSubdirectoryNames(self, inputDirPath: str):
        """获取指定路径下的所有子目录名称"""
        try:
            return sorted([d for d in os.listdir(inputDirPath) if os.path.isdir(os.path.join(inputDirPath, d))])
        except Exception as e:
            print(f"获取子目录失败: {e}")
            return None

    def writeKemonoDataToDatabase(self):
        input_folder_path = "/Volumes/ACG/kemono"

        if db is None:
            print("数据库初始化失败")
            return

        artistNames = self.getSubdirectoryNames(input_folder_path)
        if not artistNames:
            print("未找到艺术家目录")
            return

        print(f"发现 {len(artistNames)} 位艺术家")

        for i, artistName in enumerate(artistNames):
            artistDirPath = os.path.join(input_folder_path, artistName)
            # 获取艺术家下的所有帖子目录
            postNames = self.getSubdirectoryNames(artistDirPath)
            if not postNames:
                continue

            with db.atomic() as transaction:
                artistId = None

                # 限制每个艺术家只处理前10个帖子（可选）
                for postName in postNames[:10]:
                    postDirPath = os.path.join(artistDirPath, postName)
                    artistId = self.handleOnePost(postDirPath, artistId)

                    if artistId is None:
                        # 如果处理失败，回滚当前艺术家的所有更改
                        transaction.rollback()
                        print(f"处理帖子失败，已回滚: {postDirPath}")
                        break
        print("数据处理完成")

    def handleOnePost(self, postDirPath: str, artistId=None):
        """处理单个帖子目录"""
        postJsonFilePath = os.path.join(postDirPath, "post.json")

        # 读取并解析 JSON 文件
        try:
            with open(postJsonFilePath, 'r', encoding='utf-8') as f:
                jsonData = json.load(f)
        except Exception as e:
            print(f"打开或解析 JSON 文件失败: {postJsonFilePath} - {e}")
            return None

        # 获取艺术家名称（来自父目录名）
        artist_name = os.path.basename(os.path.dirname(postDirPath))
        artistId_upload = None
        try:
            # 处理艺术家数据
            if artistId is None:
                # 创建新艺术家
                artist = Artist.create(
                    name=artist_name,
                    service=jsonData.get("service", "unknown")
                )
                artistId_upload = artist.id
            else:
                # 使用现有艺术家 ID
                artist = Artist.get_by_id(artistId)
                artistId_upload = artistId

            # 处理帖子数据
            # post_date = self.parseDate(jsonData["published"])
            post_date = jsonData["published"] + '.000'

            # 创建帖子记录
            post = KemonoPost.create(
                artist=artist,
                name=jsonData.get("title", "Untitled"),
                post_date=post_date,
                cover_img_file_name=f"{jsonData['id']}_{jsonData['file']['name']}",
                post_folder_name=os.path.basename(postDirPath),
                attachment_number=len(jsonData.get("attachments", []))
            )

            # 处理附件数据
            for i, attachment in enumerate(jsonData.get("attachments", [])):
                file_name = attachment['name']
                file_ext = os.path.splitext(file_name)[1]

                # 创建图片记录
                KemonoImage.create(
                    post=post,
                    image_name=f"{i + 1}{file_ext}"
                )

            return artistId_upload

        except Exception as e:
            print(f"处理帖子失败: {postDirPath} - {e}")
            return None

if __name__ == "__main__":
    dbManager = DatabaseManager()
    dbManager.writeKemonoDataToDatabase()



