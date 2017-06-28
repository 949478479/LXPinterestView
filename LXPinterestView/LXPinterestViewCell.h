//
//  LXPinterestViewCell.h
//  LXPinterestView
//
//  Created by 从今以后 on 15/6/15.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

@import UIKit;

@interface LXPinterestViewCell : UIView

/** 重用标识符. */
@property(nonatomic, readonly, copy) NSString *reuseIdentifier;

/** 即将被重用. */
- (void)prepareForReuse;

@end
