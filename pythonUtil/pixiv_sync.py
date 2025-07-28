"""_"""

import sys
from peewee import *
import json
import datetime
import os
from pathlib import Path

from Util import Util
from filePathConfig import Config

db = SqliteDatabase(Config.PIXIV_DB_PATH, pragmas={'foreign_keys': 1})

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

class PixivArtist(BaseModel):
    id = AutoField(column_name='id')  # 自动递增主键
    pixiv_artist_id = TextField(column_name='pixiv_artist_id')
    name = TextField(column_name='name')
    userAccount = TextField(column_name='user_account')
    artistFolderName = TextField(column_name='artist_folder_name')

    class Meta:
        table_name = 'pixivArtist'

class PixivPost(BaseModel):
    id = AutoField(column_name='id')
    pixiv_post_id = TextField(column_name='pixiv_post_id')
    artist = ForeignKeyField(PixivArtist, column_name='artist_id', backref='posts', on_delete='CASCADE')
    name = TextField(column_name='name')
    post_date = TextField(column_name='post_date')
    postFolderName = TextField(column_name='post_folder_name')
    imageNumber = IntegerField(column_name='image_number')

    bookmarkCount = IntegerField(column_name='bookmark_count')
    likeCount = IntegerField(column_name='like_count')
    commentCount = IntegerField(column_name='comment_count')
    viewCount = IntegerField(column_name='view_count')

    xRestrict = IntegerField(column_name='x_restrict')
    illustType = IntegerField(column_name='illust_type')
    isHowto = BooleanField(column_name='is_howto')
    isOriginal = BooleanField(column_name='is_original')
    aiType = IntegerField(column_name='ai_type')

    viewed = BooleanField(column_name='viewed', default=False)

    class Meta:
        table_name = 'pixivPost'


class PixivImage(BaseModel):
    id = AutoField(column_name='id')
    post = ForeignKeyField(PixivPost, column_name='post_id', backref='images', on_delete='CASCADE')
    imageName = TextField(column_name='name')

    class Meta:
        table_name = 'pixivImage'


@singleton  # 应用单例装饰器
class PixivSyncer:

    def __init__(self):
        # connect to the database
        # if the database does not exist, it will be created
        db.connect()
        self.create_tables_if_not_exist()

    def checkIfTablesExist(self):
        with db:
            artistExists = PixivArtist.table_exists()
            postExists = PixivPost.table_exists()
            imageExists = PixivImage.table_exists()
            assert artistExists == postExists and artistExists == imageExists
            return artistExists

    def create_tables_if_not_exist(self):
        with db:
            if not self.checkIfTablesExist():
                db.create_tables([PixivArtist, PixivPost, PixivImage])
                print("所有表创建成功")


    def writePixivDataToDatabase(self):
        if db is None:
            print("数据库初始化失败")
            return

        artistsFolderName = Util.getSubdirectoryNames(Config.PIXIV_BASEPATH)
        if not artistsFolderName:
            print("未找到艺术家目录")
            return
        print(f"发现 {len(artistsFolderName)} 位艺术家")

        for i, artistFolderName in enumerate(artistsFolderName):
            print(f'{artistFolderName}: ', flush=True, end='')
            with db.atomic() as transaction:
                self.handleOneArtist(artistFolderName)
            print('', flush=True)

        print("数据处理完成")

    def handleOneArtist(self, artistFolderName: str):
        artistDirPath = os.path.join(Config.PIXIV_BASEPATH, artistFolderName)
        postsFolderName = Util.getSubdirectoryNames(artistDirPath)
        # 没有帖子时跳过
        if not postsFolderName:
            return

        refPostJsonFilePath = self.findRefPostJsonFilePath(artistDirPath, postsFolderName)
        if not refPostJsonFilePath:
            print(f"未找到参考的 post.json 文件: {artistDirPath}")
            return
        artistPixivId = self.getArtistPixivId(refPostJsonFilePath)
        if not artistPixivId:
            print(f"获取艺术家 Pixiv ID 失败: {refPostJsonFilePath}")
            return

        artists_SQLObj = PixivArtist.select(PixivArtist).where(
            (PixivArtist.pixiv_artist_id == artistPixivId)
        )

        if artists_SQLObj:
            if len(artists_SQLObj) > 1:
                raise ValueError('数据库中存在多个相同 twitter_artist_id 的艺术家，请检查数据完整性。')
            self.handleExistedArtist(artists_SQLObj.first(), artistDirPath)
        else:
            self.handleNewArtist(artistDirPath, refPostJsonFilePath)

    def writeArtistDataToDatabase(self, refPostJsonFilePath: str):
        try:
            with open(refPostJsonFilePath, 'r', encoding='utf-8') as f:
                jsonData = json.load(f)
        except Exception as e:
            print(f"打开 JSON 文件失败: {refPostJsonFilePath} - {e}")
            return None

        artistFolderName = os.path.basename(Path(refPostJsonFilePath).parent.parent.absolute())

        artist_SQLObj = PixivArtist.create(
            pixiv_artist_id=jsonData['userId'],
            name=jsonData['userName'],
            userAccount=jsonData['userAccount'],
            artistFolderName=artistFolderName,
        )
        return artist_SQLObj

    def handleNewArtist(self, artistDirPath: str, refPostJsonFilePath: str):
        newArtist_SQLObj = self.writeArtistDataToDatabase(refPostJsonFilePath)
        postsFolderName = Util.getSubdirectoryNames(artistDirPath)

        for postFolderName in postsFolderName:
            postDirPath = os.path.join(artistDirPath, postFolderName)
            jsonFileName = self.getJsonFileName(postDirPath, '.json')
            if not jsonFileName:
                print(f"跳过没有或有多个json文件的帖子: {postDirPath}")
                continue
            jsonFilePath = os.path.join(postDirPath, jsonFileName)

            self.handleOnePost(postFolderName, jsonFilePath, newArtist_SQLObj)
            print('.', flush=True, end='')

    def handleExistedArtist(self, artist_SQLObj, artistDirPath: str):
        posts_SQLObj = PixivPost.select().where(
            PixivPost.artist == artist_SQLObj
        ).order_by(PixivPost.post_date.desc())

        if not posts_SQLObj:
            print(f"艺术家 {artist_SQLObj.name} 没有帖子，跳过")
            return

        latestDateTimeInDb = datetime.datetime.strptime(posts_SQLObj.first().post_date.split('.')[0], '%Y-%m-%dT%H:%M:%S')

        postsFolderName_notProcessed = self.getNotProcessedPostsFolderName(artistDirPath, latestDateTimeInDb)

        for postFolderName in postsFolderName_notProcessed:
            postDirPath = os.path.join(artistDirPath, postFolderName)
            jsonFileName = self.getJsonFileName(postDirPath, '.json')
            if not jsonFileName:
                print(f"跳过没有或有多个json文件的帖子: {postDirPath}")
                continue
            jsonFilePath = os.path.join(postDirPath, jsonFileName)

            self.handleOnePost(postFolderName, jsonFilePath, artist_SQLObj)
            print('.', flush=True, end='')

        if not postsFolderName_notProcessed:
            print('(No new posts)', flush=True, end='')

    def getNotProcessedPostsFolderName(self, artistDirPath: str, latestDateTimeInDb):
        notProcessedPostsFolderName = []

        postsFolderName = Util.getSubdirectoryNames(artistDirPath)
        for currentPostFolderName in postsFolderName:
            currentPostDateTime = datetime.datetime.strptime(currentPostFolderName.split(']')[0].strip('['), '%Y-%m-%d')

            if Util.checkYMDSmall(currentPostDateTime, latestDateTimeInDb):
                continue

            if Util.checkYMDEqual(currentPostDateTime, latestDateTimeInDb):
                postDirPath = os.path.join(artistDirPath, currentPostFolderName)
                currentPostJsonFileName = self.getJsonFileName(postDirPath, '.json')
                if not currentPostJsonFileName:
                    print(f"跳过没有或有多个json文件的帖子: {postDirPath}")
                    continue
                currentPostJsonFilePath = os.path.join(postDirPath, currentPostJsonFileName)
                try:
                    with open(currentPostJsonFilePath, 'r', encoding='utf-8') as f:
                        jsonData = json.load(f)
                except Exception as e:
                    print(f"打开或解析 JSON 文件失败: {currentPostJsonFilePath} - {e}")
                    continue

                post_SQLObj = PixivPost.select().where(PixivPost.pixiv_post_id == jsonData['illustId'])
                if not post_SQLObj:
                    notProcessedPostsFolderName.append(currentPostFolderName)

            else:
                notProcessedPostsFolderName.append(currentPostFolderName)

        return notProcessedPostsFolderName

    def handleOnePost(self, postFolderName: str, jsonFilePath: str, artist_SQLObj):
        try:
            with open(jsonFilePath, 'r', encoding='utf-8') as f:
                jsonData = json.load(f)
        except Exception as e:
            print(f"打开或解析 JSON 文件失败: {jsonFilePath} - {e}")
            return None

        try:
            imageNumber = jsonData['pageCount']

            post = PixivPost.create(
                pixiv_post_id=jsonData['illustId'],
                artist=artist_SQLObj,
                name=jsonData['illustTitle'],
                post_date=self.parseDate(jsonData['uploadDate']),
                postFolderName=postFolderName,
                imageNumber=imageNumber,
                bookmarkCount=jsonData['bookmarkCount'],
                likeCount=jsonData['likeCount'],
                commentCount=jsonData['commentCount'],
                viewCount=jsonData['viewCount'],
                xRestrict=jsonData['xRestrict'],
                illustType=jsonData['illustType'],
                isHowto=jsonData['isHowto'],
                isOriginal=jsonData['isOriginal'],
                aiType=jsonData['aiType']
            )

            firstFileURL = jsonData['urls']['original']
            if not firstFileURL:
                raise ValueError("帖子缺少原始图片 URL")
            firstFileName = os.path.basename(firstFileURL)


            if jsonData['illustType'] == 2:
                # Ugoira file
                imageFileName = firstFileName.split("_ugoira0")[0] + '_ugoira1920x1080.ugoira'
                PixivImage.create(
                    post=post,
                    imageName=imageFileName
                )
            else:
                for i in range(imageNumber):
                    imageFileName = firstFileName.replace('_p0', '_p{}'.format(i))
                    PixivImage.create(
                        post=post,
                        imageName=imageFileName
                    )
        except Exception as e:
            print(f"处理帖子失败: {postFolderName} - {e}")

    def getPlusOrMinus(self, date_str):
        if '+' in date_str:
            return '+'
        elif '-' in date_str:
            return '-'
        else:
            raise ValueError("日期字符串格式错误，必须包含 '+' 或 '-' 符号")

    def parseDate(self, date_str):
        plusOrMinus = self.getPlusOrMinus(date_str)

        timeDeltaInHour = int(date_str.split(plusOrMinus)[1].split(':')[0])
        datetimeStr = date_str.split(plusOrMinus)[0]
        datetimeObj = datetime.datetime.strptime(datetimeStr, '%Y-%m-%dT%H:%M:%S')
        if plusOrMinus == '+':
            datetimeObj -= datetime.timedelta(hours=timeDeltaInHour)
        else:
            datetimeObj += datetime.timedelta(hours=timeDeltaInHour)
        return datetimeObj.strftime('%Y-%m-%dT%H:%M:%S') + '.000'

    def getArtistPixivId(self, refPostJsonFilePath: str):
        try:
            with open(refPostJsonFilePath, 'r', encoding='utf-8') as f:
                jsonData = json.load(f)
            return jsonData['userId']
        except Exception as e:
            print(f"打开或解析 JSON 文件失败: {refPostJsonFilePath} - {e}")
            return None

    def getJsonFileName(self, inputDirPath: str, extension: str):
        jsonFilesName = sorted([f for f in os.listdir(inputDirPath) if f.endswith(extension) and os.path.isfile(os.path.join(inputDirPath, f))])
        if len(jsonFilesName) != 1:
            print(f"ERROR: 在 {inputDirPath} 中找到多个 JSON 文件: {jsonFilesName}")
            return None
        return jsonFilesName[0]

    def findRefPostJsonFilePath(self, artistDirPath: str, postsFolderName):
        for postFolderName in postsFolderName:
            postDirPath = os.path.join(artistDirPath, postFolderName)
            jsonFileName = self.getJsonFileName(postDirPath, '.json')
            if not jsonFileName:
                continue
            jsonFilePath = os.path.join(artistDirPath, postFolderName, jsonFileName)
            return jsonFilePath

        print(f'未找到符合条件的 post.json 文件: {artistDirPath}')
        return None

if __name__ == '__main__':
    syncer = PixivSyncer()
    syncer.writePixivDataToDatabase()
    db.close()
    print("Pixiv 数据同步完成")

