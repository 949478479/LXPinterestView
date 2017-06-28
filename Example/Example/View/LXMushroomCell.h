//
//  MushroomCell.h
//  LXPinterestView
//
//  Created by 从今以后 on 15/7/11.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

#import "LXPinterestViewCell.h"

@class LXMushroom, LXPinterestView;

@interface LXMushroomCell : LXPinterestViewCell

/** 价格标签. */
@property (nonatomic, readonly, strong) UILabel *priceLabel;

/** 图片视图. */
@property (nonatomic, readonly, strong) UIImageView *imageView;

/** 创建一个 cell. */
+ (instancetype)cellWithWaterFlowView:(LXPinterestView *)waterFlowView;

/** 根据 Mushroom 数据模型配置 cell. */
- (void)configureForMushroom:(LXMushroom *)mushroom;

@end
