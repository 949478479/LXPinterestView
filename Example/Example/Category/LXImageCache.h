//
//  LXImageCache.h
//  LXWaterfallFlowView
//
//  Created by 从今以后 on 15/7/15.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

@import UIKit;

@interface LXImageCache : NSObject

/** 获取图片缓存单例. */
+ (instancetype)sharedImageCache;

/** 异步清除硬盘缓存. */
- (void)clearDiskCache;

/** 清除内存缓存. */
- (void)clearMemoryCache;

/** 取消操作. */
- (void)cancelForURL:(NSURL *)url;

/** 获取缓存图片. */
- (void)cachedImageForURL:(NSURL *)url complete:(void (^)(UIImage *image))complete;

@end