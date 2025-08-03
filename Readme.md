# Kemono Viewer

此App用于管理kemono.su、Twitter和Pixiv下载的图片。此App的特色在于：
* 可直接浏览从三个网站下载的任意媒体文件
* 可跨post/tweet/artist浏览，当前post/tweet/artist的所有媒体文件浏览完毕后，点按下/上一图片自动跳到下/上一个post/tweet/artist的媒体文件
* 自动播放时，遇到视频/动图时将等待视频/动图全部播放完毕后才自动播放下一媒体文件
* 全屏浏览媒体文件时通过鼠标滚轮和鼠标拖动可任意调整图片/视频的大小和位置
* 按照各网站UI尽力还原了图片的评论区UI
* 通过SQLite数据库记录媒体文件是否浏览过

## 使用方法
### 1. 从网站下载文件
各下载器均使用Python下载文件，请参照各下载器的文档配置Python环境。
kemono.su：使用[KToolBox](https://github.com/Ljzd-PRO/KToolBox)下载文件；

Twitter：使用[twitter_download](https://github.com/caolvchong-top/twitter_download)下载文件；

Pixiv：使用[PixivUtil2](https://github.com/Nandaka/PixivUtil2)下载文件。

### 2. 用本项目附带的python脚本将文件信息写入SQLite数据库

#### 2.1 库依赖
本项目附带的Python脚本依赖`peewee`库，请使用pip或conda安装`peewee`库。

#### 2.2 调整目录
在`pythonUtil/filePathConfig.py`调整下载文件的目录和数据库目录

#### 2.3 执行Python文件
kemono.su：`python kemono_sync.py`

Twitter：`python twitter_sync.py`

Pixiv：`python pixiv_sync.py`

首次执行Python文件时将在`filePathConfig.py`指定的数据库路径创建数据库文件，各下载器下载新的文件后，需手动执行上述命令，已创建的数据库的数据将被更新。

### 3. 使用Kemono Viewer浏览文件
打开App后，在Settings设置下载文件的目录和数据库目录即可开始浏览文件。
