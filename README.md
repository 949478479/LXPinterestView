# WaterfallFlow

用 `UIScrollView` 实现的瀑布流,以及简易的加载网络图片功能~

* 提供了数据源和代理,以及 *cell* 各种间距,列数等设置项,支持IB.
* 循环利用 *cell*, 节约资源.
* 提供了 *cell* 点击事件响应.
* 自动为滚进屏幕的 *cell* 后台加载图片,并在 *cell* 离屏后取消未完成的加载操作.
* 提供了内存和硬盘图片缓存,以及清除缓存功能.

感谢 MJ 老师的 `MJExtension` 和 `MJRefresh` 框架.
