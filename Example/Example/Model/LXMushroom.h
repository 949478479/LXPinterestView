//
//  Mushroom.h
//  LXWaterfallFlowView
//
//  Created by 从今以后 on 15/7/11.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

@import UIKit;

@interface LXMushroom : NSObject

/** 图片高度. */
@property (nonatomic, readonly) CGFloat h;

/** 图片宽度. */
@property (nonatomic, readonly) CGFloat w;

/** 图片 URL. */
@property (nonatomic, readonly, copy) NSString *img;

/** 价格. */
@property (nonatomic, readonly, copy) NSString *price;

@end