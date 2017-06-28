//
//  LXPinterestView.h
//  LXPinterestView
//
//  Created by 从今以后 on 15/7/11.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

@import UIKit;

@class LXPinterestView, LXPinterestViewCell;

#pragma mark - LXPinterestViewDataSource

@protocol LXPinterestViewDataSource <NSObject>

/** 返回 cell 总数. */
- (NSInteger)numberOfCellsInWaterfallFlowView:(LXPinterestView *)waterfallFlowView;

/** 返回 index 对应的 cell. */
- (LXPinterestViewCell *)waterfallFlowView:(LXPinterestView *)waterfallFlowView
                                   cellAtIndex:(NSInteger)index;
@end

#pragma mark - LXPinterestViewDelegate

@protocol LXPinterestViewDelegate <UIScrollViewDelegate>

/** 根据 index 对应的 cell 的宽度返回 cell 要呈现的高度. */
- (CGFloat)waterfallFlowView:(LXPinterestView *)waterfallFlowView
          cellHeightForWidth:(CGFloat)width
                     atIndex:(NSInteger)index;
@optional

/** 点击了 index 对应的 cell. */
- (void)waterfallFlowView:(LXPinterestView *)waterfallFlowView
     didSelectCellAtIndex:(NSInteger)index;

/** 返回显示的列数,默认为 3 列. */
- (NSInteger)numberOfColumnsInWaterfallFlowView:(LXPinterestView *)waterfallFlowView;

@end

#pragma mark - LXPinterestView

@interface LXPinterestView : UIScrollView

/** 四边边距,默认为 10. */
@property (nonatomic, assign) UIEdgeInsets sectionInset;

/** 行间距,默认为 10. */
@property (nonatomic, assign) IBInspectable CGFloat   rowSpacing;

/** 列间距,默认为 10. */
@property (nonatomic, assign) IBInspectable CGFloat   columnSpacing;

/** 显示的列数,默认为 3 列. */
@property (nonatomic, assign) IBInspectable NSInteger numberOfColumns;

/** 代理. */
@property (nonatomic, weak) IBOutlet id<LXPinterestViewDelegate> delegate;

/** 数据源. */
@property (nonatomic, weak) IBOutlet id<LXPinterestViewDataSource> dataSource;

/** 刷新全部表格. */
- (void)reloadAllData;

/** 拼接更多数据. */
- (void)loadMoreData;

/** 根据标识从缓存池获取 cell. */
- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)reuseIdentifier;

/** 获取 index 对应的 cell. */
- (LXPinterestViewCell *)cellAtIndex:(NSInteger)index;

@end
