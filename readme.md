NAS2CLOUD，个人NAS系统，提供文件及照片管理功能。

服务端使用golang开发，可在Windows、Macos、Linux上运行，可在低性能电脑上提供较快的响应速度，同等硬件配置下响应速度远超nextcloud

客户端使用flutter开发，已适配android 12+，支持文件及照片查看及自动上传。

服务端安装：

1. 生成缩略图需要安装ffmpeg
2. 获取文件夹大小使用du命令，windows下需要单独安装
3. json2dart 命令生成客户端dart数据结构
4. 依赖redis、elasticsearch
