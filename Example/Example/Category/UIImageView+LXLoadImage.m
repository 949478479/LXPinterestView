//
//  UIImageView+LXLoadImage.m
//  LXPinterestView
//
//  Created by 从今以后 on 15/6/27.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

@import ObjectiveC.runtime;

#import "UIImageView+LXLoadImage.h"
#import "LXImageCache.h"

@interface UIImageView ()

/** 绑定图片 URL. */
@property (nonatomic, strong, setter = lx_setURL:) NSURL *lx_url;

@end

@implementation UIImageView (LXLoadImage)

#pragma mark - 绑定图片 URL

- (void)lx_setURL:(NSURL *)lx_url
{
    objc_setAssociatedObject(self, @selector(lx_url), lx_url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)lx_url
{
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - 设置图片

- (void)lx_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)image
{
    if ([self.lx_url isEqual:url]) return;
    
    self.image = image;

    LXImageCache *imageCache = [LXImageCache sharedImageCache];
    [imageCache cancelForURL:self.lx_url];
    [imageCache cachedImageForURL:url complete:^(UIImage *image) {
        self.image = image;
    }];

    self.lx_url = url;
}

@end
