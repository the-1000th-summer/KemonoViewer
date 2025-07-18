"""_"""
from peewee import *
import os
import csv
from datetime import datetime

from filePathConfig import Config

db = SqliteDatabase(Config.TWITTER_DB_PATH, pragmas={'foreign_keys': 1})

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

class TwitterArtist(BaseModel):
    id = AutoField(column_name='id')  # 自动递增主键
    name = TextField(column_name='name')
    twitter_artist_id = TextField(column_name='twitter_artist_id')

    class Meta:
        table_name = 'twitterArtist'

class TwitterPost(BaseModel):
    id = AutoField(column_name='id')
    tweet_id = TextField(column_name='tweet_id')
    artist = ForeignKeyField(TwitterArtist, column_name='artist_id', backref='posts', on_delete='CASCADE')
    content = TextField(column_name='content')
    tweet_date = TextField(column_name='tweet_date')
    tweet_url = TextField(column_name='tweet_url')
    filename = TextField(column_name='filename')
    favorite_count = IntegerField(column_name='favorite_count')
    retweet_count = IntegerField(column_name='retweet_count')
    reply_count = IntegerField(column_name='reply_count')

    class Meta:
        table_name = 'twitterPost'

@singleton
class TwitterSyncer:
    def __init__(self):
        # connect to the database
        # if the database does not exist, it will be created
        db.connect()
        self.create_tables_if_not_exist()

    def checkIfTablesExist(self):
        with db:
            artistExists = TwitterArtist.table_exists()
            postExists = TwitterPost.table_exists()
            assert artistExists == postExists
            return artistExists

    def create_tables_if_not_exist(self):
        with db:
            if not self.checkIfTablesExist():
                db.create_tables([TwitterArtist, TwitterPost])
                print("所有表创建成功")

    def getAllCsvFilePaths(self, inputDirPath: str):
        artistName = os.path.basename(inputDirPath)
        csvFilesName = sorted([
            f for f in os.listdir(inputDirPath) if os.path.isfile(os.path.join(inputDirPath, f)) and f.startswith(artistName) and f.endswith('.csv')
        ])
        csvFilesPath = [os.path.join(inputDirPath, f) for f in csvFilesName]
        return csvFilesPath

    def startSync(self):
        artistsId = sorted([
            f for f in os.listdir(Config.TWITTER_BASEPATH) if os.path.isdir(os.path.join(Config.TWITTER_BASEPATH, f))
        ])
        for artistId in artistsId:
            with db.atomic() as transaction:
                self.handleOneArtist(artistId)


    def handleNewArtist(self, artistId):
        artistDirPath = os.path.join(Config.TWITTER_BASEPATH, artistId)
        csvFilePaths = self.getAllCsvFilePaths(artistDirPath)

        artist_SQLObj = self.writeArtistDataToDatabase(csvFilePaths)

        for csvFilePath in csvFilePaths:
            self.handleOneCsvFile(csvFilePath, artist_SQLObj)

    def handleExistedArtist(self, artist_SQLObj, artistId):
        all_tweet_ids_SQLObj = TwitterPost.select(TwitterPost.tweet_id).where(
            TwitterPost.artist == artist_SQLObj.id
        )
        allExistedTweetIds = set(map(lambda x: x.tweet_id, all_tweet_ids_SQLObj))

        artistDirPath = os.path.join(Config.TWITTER_BASEPATH, artistId)
        csvFilePaths = self.getAllCsvFilePaths(artistDirPath)

        for csvFilePath in csvFilePaths:
            self.handleOneCsvFile(csvFilePath, artist_SQLObj, existedTweetIds=allExistedTweetIds)

    def handleOneArtist(self, artistId: str):
        artists_SQLObj = TwitterArtist.select(TwitterArtist).where(
            TwitterArtist.twitter_artist_id == artistId
        )

        if artists_SQLObj:
            if len(artists_SQLObj) > 1:
                raise ValueError('数据库中存在多个相同 twitter_artist_id 的艺术家，请检查数据完整性。')
            self.handleExistedArtist(artists_SQLObj.first(), artistId)
        else:
            self.handleNewArtist(artistId)


    def writeArtistDataToDatabase(self, csvFilesPath: str):
        for csvFilePath in csvFilesPath:
            with open(csvFilePath, 'r', newline='', encoding='utf-8-sig') as f:
                reader = csv.reader(f)
                allData = list(reader)
            if len(allData) < 5:
                continue
            return TwitterArtist.create(
                name=allData[0][0],
                twitter_artist_id=allData[0][1],
            )
        return None

    def handleOneCsvFile(self, csvFilePath: str, artist_SQLObj, existedTweetIds: set = None):
        with open(csvFilePath, 'r', newline='', encoding='utf-8-sig') as f:
            reader = csv.reader(f)
            allData = list(reader)

        if len(allData) < 5:
            return

        allTweet = allData[4:]

        for currentTweet in allTweet:
            tweet_id = currentTweet[3].split('/')[-3]

            if existedTweetIds and tweet_id in existedTweetIds:
                continue

            tweetContent = ' '.join(currentTweet[-4].split(' ')[:-1])

            TwitterPost.create(
                tweet_id=tweet_id,
                artist=artist_SQLObj,
                content=tweetContent,
                tweet_date=currentTweet[0],
                tweet_url=currentTweet[-4].split(' ')[-1],
                filename=currentTweet[-5],
                favorite_count=int(currentTweet[-3]),
                retweet_count=int(currentTweet[-2]),
                reply_count=int(currentTweet[-1])
            )



if __name__ == '__main__':
    t = TwitterSyncer()
    t.startSync()
