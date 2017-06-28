//
//  LXImageCache.m
//  LXPinterestView
//
//  Created by 从今以后 on 15/7/15.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

#import "LXImageCache.h"

/** 硬盘缓存路径. */
static inline NSString * LXCachePath()
{
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]
                stringByAppendingPathComponent:@"LXImageCaches"];
}

@interface LXImageCache ()

/** 内存缓存. */
@property (nonatomic, strong) NSCache *memoryCache;

/** 查询硬盘缓存的 block 字典. */
@property (nonatomic, strong) NSMutableDictionary *queryBlockDictionary;

/** 图片下载任务字典. */
@property (nonatomic, strong) NSMutableDictionary *downloadTaskDictionary;

/** 图片下载会话. */
@property (nonatomic, strong) NSURLSession *downloadSession;

/** 访问缓存的私有并发队列. */
@property (nonatomic, strong) dispatch_queue_t accessCacheQueue;

@end

@implementation LXImageCache

#pragma mark - 下载会话

- (NSURLSession *)downloadSession
{
    if (!_downloadSession) {
        _downloadSession = ({
            NSURLSessionConfiguration *configuration =
                [NSURLSessionConfiguration ephemeralSessionConfiguration];
            configuration.URLCache = nil;
            [NSURLSession sessionWithConfiguration:configuration];
        });
    }
    return _downloadSession;
}

#pragma mark - 缓存单例

+ (instancetype)sharedImageCache
{
    static LXImageCache *sharedImageCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedImageCache = [[super allocWithZone:NULL] init];
        [sharedImageCache p_createCacheDirectory];
    });
    return sharedImageCache;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _memoryCache            = [NSCache new];
        _queryBlockDictionary   = [NSMutableDictionary new];
        _downloadTaskDictionary = [NSMutableDictionary new];
        _accessCacheQueue       = dispatch_queue_create("com.nizi.accessCacheQueue",
                                                        DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedImageCache];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - 创建/删除缓存文件夹

- (void)p_createCacheDirectory
{
    [[NSFileManager defaultManager] createDirectoryAtPath:LXCachePath()
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
}

- (void)p_deleteCacheDirectory
{
    [[NSFileManager defaultManager] removeItemAtPath:LXCachePath() error:NULL];
}

#pragma mark - 解压图片

- (UIImage *)p_decompressImage:(UIImage *)image
{
    if (!image) return nil;

    UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -image.size.height);

    CGContextDrawImage(context, (CGRect){.size = image.size}, image.CGImage);

    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return resultImage;
}

#pragma mark - 取消操作

- (void)cancelForURL:(NSURL *)url
{
    if (!url) return;

    dispatch_block_t block = self.queryBlockDictionary[url];
    if (block) {
        dispatch_block_cancel(block);
        [self.queryBlockDictionary removeObjectForKey:url];
    }

    NSURLSessionDataTask *dataTask = self.downloadTaskDictionary[url];
    if (dataTask) {
        [dataTask cancel];
        [self.downloadTaskDictionary removeObjectForKey:url];
    }
}

#pragma mark - 清除缓存

- (void)clearDiskCache
{
    dispatch_barrier_async(self.accessCacheQueue, ^{
        [self p_deleteCacheDirectory];
        [self p_createCacheDirectory];
    });
}

- (void)clearMemoryCache
{
    [self.memoryCache removeAllObjects];
}

#pragma mark - 访问缓存

- (void)cachedImageForURL:(NSURL *)url complete:(void (^)(UIImage *image))complete
{
    UIImage *memoryImage = [self.memoryCache objectForKey:url];
    if (memoryImage) {
        !complete ?: complete(memoryImage);
        return;
    }

    dispatch_block_t block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{

        NSString *cachePath = [LXCachePath() stringByAppendingPathComponent:url.lastPathComponent];
        UIImage  *diskImage = [self p_decompressImage:[UIImage imageWithContentsOfFile:cachePath]];

        if (diskImage) {
            [self.memoryCache setObject:diskImage forKey:url];
        }
    });

    dispatch_block_notify(block, dispatch_get_main_queue(), ^{

        if (dispatch_block_testcancel(block)) return;

        [self.queryBlockDictionary removeObjectForKey:url];

        UIImage *memoryImage = [self.memoryCache objectForKey:url];
        if (memoryImage) {
            !complete ?: complete(memoryImage);
        } else {
            [self p_downloadImageForURL:url complete:complete];
        }
    });

    self.queryBlockDictionary[url] = block;
    dispatch_async(self.accessCacheQueue, block);
}

#pragma mark - 下载图片

- (void)p_downloadImageForURL:(NSURL *)url complete:(void (^)(UIImage *image))complete
{
    NSURLSessionDataTask *dataTask = [self.downloadSession dataTaskWithURL:url
                                                         completionHandler:
                                      ^(NSData *data, NSURLResponse *response, NSError *error) {

        if ( (int64_t)data.length == response.expectedContentLength ) {

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

                UIImage *image = [self p_decompressImage:[UIImage imageWithData:data]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.downloadTaskDictionary[url]) {
                        if (image && complete) { complete(image); }
                        [self.downloadTaskDictionary removeObjectForKey:url];
                    }
                });

                if (image) {
                    [self.memoryCache setObject:image forKey:url];

                    NSString *filePath =
                        [LXCachePath() stringByAppendingPathComponent:url.lastPathComponent];
                    dispatch_barrier_async(self.accessCacheQueue, ^{
                        [data writeToFile:filePath atomically:YES];
                    });
                }
            });

            return; // 跳过最后的回主线程代码.
        }

        // 除非操作被取消,则由外界移除下载任务,否则即使下载出错也须回主线程移除下载任务.
        if (error.code != NSURLErrorCancelled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.downloadTaskDictionary[url]) {
                    [self.downloadTaskDictionary removeObjectForKey:url];
                }
            });
        }
    }];

    self.downloadTaskDictionary[url] = dataTask;
    
    [dataTask resume];
}

@end
