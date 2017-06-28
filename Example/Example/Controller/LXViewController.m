//
//  ViewController.m
//  LXPinterestView
//
//  Created by 从今以后 on 15/7/11.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

@import MJRefresh;
@import MJExtension;

#import "LXMushroom.h"
#import "LXImageCache.h"
#import "LXMushroomCell.h"
#import "LXPinterestView.h"
#import "LXViewController.h"

@interface LXViewController () <LXPinterestViewDataSource, LXPinterestViewDelegate>

/** LXPinterestView 控件. */
@property (nonatomic, strong) IBOutlet LXPinterestView *waterfallFlowView;

/** 蘑菇们. */
@property (nonatomic, strong) NSMutableArray *mushrooms;

@end

@implementation LXViewController

#pragma mark - 初始化

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _mushrooms = [[LXMushroom objectArrayWithFilename:@"2.plist"] mutableCopy];
    }
    return self;
}

#pragma mark - 加载界面

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self p_setupRefreshView];
}

- (void)p_setupRefreshView
{
    self.waterfallFlowView.header =
        [MJRefreshNormalHeader headerWithRefreshingTarget:self
                                         refreshingAction:@selector(loadNewMushrooms)];
    self.waterfallFlowView.footer =
        [MJRefreshBackNormalFooter footerWithRefreshingTarget:self
                                             refreshingAction:@selector(loadMoreMushrooms)];
}

#pragma mark - 加载数据

- (void)loadNewMushrooms
{
    self.mushrooms = [[LXMushroom objectArrayWithFilename:@"1.plist"] mutableCopy];

    // 模拟网络延迟.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.waterfallFlowView.header endRefreshing];
        [self.waterfallFlowView reloadAllData];
    });
}

- (void)loadMoreMushrooms
{
    NSArray *mushrooms = [LXMushroom objectArrayWithFilename:@"3.plist"];
    [self.mushrooms addObjectsFromArray:mushrooms];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.waterfallFlowView.footer endRefreshing];
        [self.waterfallFlowView loadMoreData];
    });
}

#pragma mark - 清除缓存

- (IBAction)clearMemoryCache:(id)sender
{
    [[LXImageCache sharedImageCache] clearMemoryCache];
}

- (IBAction)clearDiskCache:(id)sender
{
    [[LXImageCache sharedImageCache] clearDiskCache];
}

#pragma mark - LXPinterestViewDataSource

- (NSInteger)numberOfCellsInWaterfallFlowView:(LXPinterestView *)waterfallFlowView
{
    return self.mushrooms.count;
}

- (LXPinterestViewCell *)waterfallFlowView:(LXPinterestView *)waterfallFlowView
                                   cellAtIndex:(NSInteger)index
{
    LXMushroomCell *cell = [LXMushroomCell cellWithWaterFlowView:waterfallFlowView];
    [cell configureForMushroom:self.mushrooms[index]];
    return cell;
}

#pragma mark - LXPinterestViewDelegate

- (CGFloat)waterfallFlowView:(LXPinterestView *)waterfallFlowView
          cellHeightForWidth:(CGFloat)width
                     atIndex:(NSInteger)index
{
    LXMushroom *mushroom = self.mushrooms[index];
    return width * mushroom.h / mushroom.w;
}

- (NSInteger)numberOfColumnsInWaterfallFlowView:(LXPinterestView *)waterfallFlowView
{
    return (UIUserInterfaceSizeClassCompact == self.traitCollection.verticalSizeClass) ? 5 : 3;
}

- (void)waterfallFlowView:(LXPinterestView *)waterfallFlowView
     didSelectCellAtIndex:(NSInteger)index
{
    LXMushroomCell *cell = (LXMushroomCell *)[waterfallFlowView cellAtIndex:index];
    NSLog(@"< 索引 %ld : 价格 %@ >", (long)index, cell.priceLabel.text);
}

@end
