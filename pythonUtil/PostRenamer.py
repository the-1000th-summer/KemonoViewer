""" 此文件用于规范化post文件夹名 """
import os
import json
from filePathConfig import Config
from Util import Util
from pathvalidate import sanitize_filename

class PostRenamer:
    def __init__(self):
        pass

    def getTargetNameFromJsonFile(self, jsonFilePath: str):
        try:
            with open(jsonFilePath, 'r', encoding='utf-8') as f:
                jsonData = json.load(f)
        except Exception as e:
            print(f"打开或解析 JSON 文件失败: {jsonFilePath} - {e}")
            return None

        published = jsonData['published'].split("T")[0]
        title = sanitize_filename(jsonData['title'])
        service = jsonData['service']

        return '[{}][{}]{}'.format(service, published, title)

    def doRename(self):
        artistsName = Util.getSubdirectoryNames(Config.KEMONO_BASEPATH)
        if not artistsName:
            print("未找到艺术家目录")
            return
        print(f"发现 {len(artistsName)} 位艺术家")

        failedPaths = []

        for artistName in artistsName:
            artistPath = os.path.join(Config.KEMONO_BASEPATH, artistName)
            postNames = Util.getSubdirectoryNames(artistPath)
            if not postNames:
                print(f"艺术家 {artistName} 没有帖子，跳过")
                continue

            for postName in postNames:
                postDirPath = os.path.join(artistPath, postName)

                # 检查是否有 post.json 文件
                postJsonFilePath = os.path.join(postDirPath, "post.json")
                if not os.path.isfile(postJsonFilePath):
                    print(f"跳过没有 post.json 的帖子: {postDirPath}")
                    continue

                folderNameAfterRename = self.getTargetNameFromJsonFile(postJsonFilePath)
                if not folderNameAfterRename:
                    print(f"获取重命名后的文件夹名失败: {postJsonFilePath}")
                    continue

                folderPathAfterRename = os.path.join(artistPath, folderNameAfterRename)

                try:
                    os.rename(postDirPath, folderPathAfterRename)
                except Exception as e:
                    print(f"重命名失败: {e}")
                    failedPaths.append(postDirPath)

        if failedPaths:
            print("以下路径重命名失败，请手动检查:")
            for path in failedPaths:
                print(path)


if __name__ == "__main__":
    renamer = PostRenamer()
    renamer.doRename()
    print("重命名完成")

