
import sys
from peewee import *
import json
import datetime
import os

from Util import Util
from filePathConfig import Config

db = SqliteDatabase(Config.KEMONO_DB_PATH, pragmas={'foreign_keys': 1})

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


class KemonoArtist(BaseModel):
    id = AutoField(column_name='id')  # 自动递增主键
    kemono_artist_id = TextField(column_name='kemono_artist_id')
    name = TextField(column_name='name')
    service = TextField(column_name='service')

    class Meta:
        table_name = 'kemonoArtist'


class KemonoPost(BaseModel):
    id = AutoField(column_name='id')
    kemono_post_id = TextField(column_name='kemono_post_id')
    artist = ForeignKeyField(KemonoArtist, column_name='artist_id', backref='posts', on_delete='CASCADE')
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
class KemonoSyncer:
    def __init__(self):
        # connect to the database
        # if the database does not exist, it will be created
        db.connect()
        self.create_tables_if_not_exist()

    def checkIfTablesExist(self):
        with db:
            artistExists = KemonoArtist.table_exists()
            postExists = KemonoPost.table_exists()
            imageExists = KemonoImage.table_exists()
            assert artistExists == postExists and artistExists == imageExists
            return artistExists

    def create_tables_if_not_exist(self):
        with db:
            if not self.checkIfTablesExist():
                db.create_tables([KemonoArtist, KemonoPost, KemonoImage])
                print("所有表创建成功")

    def parseDate(self, date_str):
        # 原始格式示例: "2023-10-05T14:48:00.000Z"
        try:
            # 尝试不带毫秒的格式
            return datetime.datetime.strptime(date_str, '%Y-%m-%dT%H:%M:%S')
        except ValueError:
            # 移除末尾的 'Z' 并解析为 UTC 时间
            date_str = date_str.rstrip('Z')
            return datetime.datetime.strptime(date_str, '%Y-%m-%dT%H:%M:%S.%f')

    def writeKemonoDataToDatabase(self):
        if db is None:
            print("数据库初始化失败")
            return

        artistNames = Util.getSubdirectoryNames(Config.KEMONO_BASEPATH)
        if not artistNames:
            print("未找到艺术家目录")
            return

        print(f"发现 {len(artistNames)} 位艺术家")

        for i, artistName in enumerate(artistNames):
            print(f'{artistName}: ', flush=True, end='')
            with db.atomic() as transaction:
                self.handleOneArtist(artistName)
            print('', flush=True)

        print("数据处理完成")


    def handleOneArtist(self, artistName: str):
        artistDirPath = os.path.join(Config.KEMONO_BASEPATH, artistName)
        postsName = Util.getSubdirectoryNames(artistDirPath)
        # 没有帖子时跳过
        if not postsName:
            return

        postServices = self.getPostServices(postsName)
        for postService in postServices:
            refPostJsonFilePath = self.findRefPostJsonFilePath(artistName, postService, postsName)
            if not refPostJsonFilePath:
                print(f"未找到符合条件的 post.json 文件: {artistName}, {postService}")
                continue
            artistKemonoId = self.getArtistKemonoId(refPostJsonFilePath)

            artists_SQLObj = KemonoArtist.select(KemonoArtist).where(
                (KemonoArtist.kemono_artist_id == artistKemonoId) &
                (KemonoArtist.service == postService)
            )

            if artists_SQLObj:
                if len(artists_SQLObj) > 1:
                    raise ValueError('数据库中存在多个相同 kemono_id 的艺术家，请检查数据完整性。')
                self.handleExistedArtist(artists_SQLObj.first(), postsName)
            else:
                self.handleNewArtist(artistKemonoId, artistName, postService, postsName)

    def handleExistedArtist(self, artist_SQLObj, postsName):
        posts_SQLObj = KemonoPost.select().where(
            KemonoPost.artist == artist_SQLObj
        ).order_by(KemonoPost.post_date.desc())

        if not posts_SQLObj:
            print(f"艺术家 {artist_SQLObj.name} 没有帖子，跳过")
            return

        latestDateTimeInDb = datetime.datetime.strptime(posts_SQLObj.first().post_date.split('.')[0], '%Y-%m-%dT%H:%M:%S')

        postsName_currentService = self.getPostsNameOfService(postsName, artist_SQLObj.service)
        postsName_notProcessed = self.getNotProcessedPostsName(artist_SQLObj.name, postsName_currentService, latestDateTimeInDb)

        for postName in postsName_notProcessed:
            postDirPath = os.path.join(Config.KEMONO_BASEPATH, artist_SQLObj.name, postName)
            self.handleOnePost(postDirPath, artist_SQLObj)
            print('.', flush=True, end='')

        if not postsName_notProcessed:
            print('(No new posts)', flush=True, end='')

    def getNotProcessedPostsName(self, artistName: str, postsName_currentService, latestDateTimeInDb):
        notProcessedPostsName = []

        for currentPostName in postsName_currentService:
            currentPostDateTime = datetime.datetime.strptime(currentPostName.split(']')[1].strip('['), '%Y-%m-%d')

            if Util.checkYMDSmall(currentPostDateTime, latestDateTimeInDb):
                continue

            if Util.checkYMDEqual(currentPostDateTime, latestDateTimeInDb):
                currentPostJsonFilePath = os.path.join(Config.KEMONO_BASEPATH, artistName, currentPostName, "post.json")
                try:
                    with open(currentPostJsonFilePath, 'r', encoding='utf-8') as f:
                        jsonData = json.load(f)
                except Exception as e:
                    print(f"打开或解析 JSON 文件失败: {currentPostJsonFilePath} - {e}")
                    continue

                post_SQLObj = KemonoPost.select().where(KemonoPost.kemono_post_id == jsonData['id'])
                if not post_SQLObj:
                    notProcessedPostsName.append(currentPostName)

            else:
                notProcessedPostsName.append(currentPostName)

        return notProcessedPostsName


    def handleNewArtist(self, artistKemonoId: str, artistName: str, postService: str, postsName):
        newArtist_SQLObj = self.writeArtistDataToDatabase(artistKemonoId, artistName, postService)
        postsName_currentService = self.getPostsNameOfService(postsName, postService)
        for postName in postsName_currentService:
            postDirPath = os.path.join(Config.KEMONO_BASEPATH, artistName, postName)
            self.handleOnePost(postDirPath, newArtist_SQLObj)
            print('.', flush=True, end='')

            # 如果处理成功，打印成功信息
            # print(f"成功处理帖子: {postDirPath})")

    def writeArtistDataToDatabase(self, artistKemonoId: str, artistName: str, postService: str):
        return KemonoArtist.create(
            kemono_artist_id=artistKemonoId,
            name=artistName,
            service=postService
        )

    def getPostsNameOfService(self, postsName, service: str):
        return list(filter(lambda x: x.startswith(f"[{service}]"), postsName))

    def findRefPostJsonFilePath(self, artistName: str, service: str, postsName):
        for postName in postsName:
            if postName.startswith(f"[{service}]"):
                postJsonFilePath = os.path.join(Config.KEMONO_BASEPATH, artistName, postName, "post.json")
                if os.path.exists(postJsonFilePath) and os.path.isfile(postJsonFilePath):
                    return postJsonFilePath
        print(f"未找到符合条件的 post.json 文件: {artistName}, {service}")
        return None


    def handleOnePost(self, postDirPath: str, artist_SQLObj):
        """ 处理单个帖子目录 """
        postJsonFilePath = os.path.join(postDirPath, "post.json")

        # 读取并解析 JSON 文件
        try:
            with open(postJsonFilePath, 'r', encoding='utf-8') as f:
                jsonData = json.load(f)
        except Exception as e:
            print(f"打开或解析 JSON 文件失败: {postJsonFilePath} - {e}")
            return None

        try:
            # 处理帖子数据
            # post_date = self.parseDate(jsonData["published"])
            post_date = jsonData["published"].split('.')[0] + '.000'

            # 创建帖子记录
            post = KemonoPost.create(
                kemono_post_id=jsonData['id'],
                artist=artist_SQLObj,
                name=jsonData.get("title", "Untitled"),
                post_date=post_date,
                cover_img_file_name=f"{jsonData['id']}_{jsonData['file']['name']}" if jsonData['file']['name'] else "",
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
        except Exception as e:
            print(f"处理帖子失败: {postDirPath} - {e}")


    def getPostServices(self, postsName: str):
        postServices = set(map(lambda x: x.split(']')[0].strip('['), postsName))
        return postServices

    def getArtistKemonoId(self, postJsonFilePath: str):
        """ 获取艺术家的 kemono_id """
        try:
            with open(postJsonFilePath, 'r', encoding='utf-8') as f:
                jsonData = json.load(f)
        except Exception as e:
            print(f"读取 JSON 文件失败: {postJsonFilePath} - {e}")
            return None
        artistKemonoId = jsonData['user']
        return artistKemonoId

if __name__ == "__main__":
    dbManager = KemonoSyncer()
    dbManager.writeKemonoDataToDatabase()
