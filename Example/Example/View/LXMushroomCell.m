//
//  MushroomCell.m
//  LXPinterestView
//
//  Created by 从今以后 on 15/7/11.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

#import "LXMushroom.h"
#import "LXMushroomCell.h"
#import "LXPinterestView.h"
#import "UIImageView+LXLoadImage.h"

/** 价格标签高度. */
static const CGFloat kLabelHeight = 21;

@interface LXMushroomCell ()

/** 价格标签. */
@property (nonatomic, readwrite, strong) UILabel *priceLabel;

/** 图片视图. */
@property (nonatomic, readwrite, strong) UIImageView *imageView;

@end

@implementation LXMushroomCell
@synthesize reuseIdentifier = _reuseIdentifier;

#pragma mark - 初始化

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super init];
    if (self) {
        _reuseIdentifier            = [reuseIdentifier copy];

        _imageView                  = [UIImageView new];

        _priceLabel                 = [UILabel new];
        _priceLabel.textColor       = [UIColor whiteColor];
        _priceLabel.textAlignment   = NSTextAlignmentCenter;
        _priceLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];

        [self addSubview:_imageView];
        [self addSubview:_priceLabel];
    }
    return self;
}

+ (instancetype)cellWithWaterFlowView:(LXPinterestView *)waterFlowView
{
    static NSString *reuseIdentifier = @"mushroom";

    LXMushroomCell *cell = [waterFlowView dequeueReusableCellWithReuseIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[LXMushroomCell alloc] initWithReuseIdentifier:reuseIdentifier];
    }

    return cell;
}

#pragma mark - 配置 cell

- (void)configureForMushroom:(LXMushroom *)mushroom
{
    [self.imageView lx_setImageWithURL:[NSURL URLWithString:mushroom.img]
                      placeholderImage:[UIImage imageNamed:@"loading"]];

    self.priceLabel.text = mushroom.price;
}

#pragma mark - 调整位置

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame  = self.bounds;
    self.priceLabel.frame = (CGRect) {
        0,
        CGRectGetHeight(self.bounds) - kLabelHeight,
        CGRectGetWidth(self.bounds),
        kLabelHeight
    };
}

@end
