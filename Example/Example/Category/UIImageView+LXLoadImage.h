//
//  UIImageView+LXLoadImage.h
//  LXPinterestView
//
//  Created by 从今以后 on 15/6/27.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

@import UIKit;

@interface UIImageView (LXLoadImage)

/** 设置占位图片并用下载好的网络图片替换. */
- (void)lx_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)image;

@end
