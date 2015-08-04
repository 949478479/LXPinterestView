# WaterfallFlow

用 `UIScrollView` 实现的瀑布流,以及简易的加载网络图片功能~

###功能

* 提供了数据源和代理,以及 *cell* 各种间距,列数等设置项,支持IB.
* 循环利用 *cell*, 节约资源.
* 提供了 *cell* 点击事件响应.
* 自动为滚进屏幕的 *cell* 后台加载图片,并在 *cell* 离屏后取消未完成的加载操作.
* 提供了内存和硬盘图片缓存,以及清除缓存功能.

###思路

* 利用二分查找在滚动中实时检测出离屏 *cell* 并加入缓存池实现重用,数据量很大时检测过程也很效率.
* 用 `NSArray` 提供的二分查找方法快速获取被点击的 *cell*.
* 为 `UIImageView` 构建分类实现自动加载图片,用 `关联对象` 为分类绑定必要的数据.
* 用 `GCD` 配合 `dispatch_block_t` 后台读写硬盘缓存,支持取消操作.
* 用 `NSURLSession` 后台下载图片,支持取消操作.
* 在后台将原始图片绘制到位图上下文再重新获取实现图片解压,提高主线程图片加载效率.
* 用 `NSCache` 缓存解压后的图片,不仅线程安全,还能在内存紧张时自动丢弃缓存.

###备注

感谢 MJ 老师的 `MJExtension` 和 `MJRefresh` 框架.