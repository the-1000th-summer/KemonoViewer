
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
