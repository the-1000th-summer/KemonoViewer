import datetime
import os

class Util:
    @staticmethod
    def getSubdirectoryNames(inputDirPath: str):
        """获取指定路径下的所有子目录名称"""
        try:
            return sorted([d for d in os.listdir(inputDirPath) if os.path.isdir(os.path.join(inputDirPath, d))])
        except Exception as e:
            print(f"获取子目录失败: {e}")
            return None

    @staticmethod
    def checkYMDSmall(currentDateTime, latestDateTimeInDb):
        """ 检查当前日期是否小于数据库中的最新日期 """
        return currentDateTime < datetime.datetime(latestDateTimeInDb.year, latestDateTimeInDb.month, latestDateTimeInDb.day)

    @staticmethod
    def checkYMDEqual(currentDateTime, latestDateTimeInDb):
        """ 检查当前日期是否等于数据库中的最新日期 """
        return (currentDateTime.year == latestDateTimeInDb.year and
                currentDateTime.month == latestDateTimeInDb.month and
                currentDateTime.day == latestDateTimeInDb.day)