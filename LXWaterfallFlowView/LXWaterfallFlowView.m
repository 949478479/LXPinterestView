//
//  LXWaterfallFlowView.m
//  LXWaterfallFlowView
//
//  Created by 从今以后 on 15/7/11.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

#import "LXWaterfallFlowView.h"
#import "LXWaterfallFlowViewCell.h"

#pragma mark - NSArray (LXExtension)

@implementation NSArray (LXExtension)

- (void)lx_getMinValueAndIndexWithBlock:(void(^)(NSUInteger index, NSNumber *minValue))block
{
    NSNumber   *temp     = nil;
    NSUInteger index     = 0;
    NSNumber   *minValue = self[0];

    NSUInteger count = self.count;
    for (NSUInteger i = 1; i < count; ++i) {
        temp = self[i];
        if ([temp compare:minValue] == NSOrderedAscending) {
            minValue = temp;
            index = i;
        }
    }

    if (block) {
        block(index, minValue);
    }
}

@end

#pragma mark - LXWaterfallFlowView

/** 对小数像素进行四舍五入. */
static inline CGFloat LXPixelRound(CGFloat value, CGFloat scale)
{
    return (scale == 2.0) ? round(value * 2) / 2 : round(value);
}

/** 默认间距. */
static const CGFloat kSpacing = 10;

/** 默认列数. */
static const NSInteger kNumberOfColumns = 3;

@interface LXWaterfallFlowView ()

/** 所有 cell 的 frame. */
@property (nonatomic, strong) NSMutableArray *cellFrames;

/** 缓存所有离屏的 cell. */
@property (nonatomic, strong) NSMutableSet *reusableCells;

/** 所有屏幕上的可见 cell. */
@property (nonatomic, strong) NSMutableDictionary *visibleCells;

/** cell 总数. */
@property (nonatomic, assign) NSUInteger numberOfCells;

/** 储存各列高度的数组. */
@property (nonatomic, strong) NSMutableArray *columnHeights;

/** 记录 ScrollView 上一次的 frame. */
@property (nonatomic, assign) CGRect lastFrame;

@end

@implementation LXWaterfallFlowView
@dynamic delegate;

#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self p_commonInit];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (void)p_commonInit
{
    _rowSpacing      = kSpacing;
    _columnSpacing   = kSpacing;
    _numberOfColumns = kNumberOfColumns;
    _sectionInset    = (UIEdgeInsets){ kSpacing, kSpacing, kSpacing, kSpacing };

    _reusableCells   = [NSMutableSet new];
    _cellFrames      = [NSMutableArray new];
    _visibleCells    = [NSMutableDictionary new];

    // 若未启用自动布局则自动拉伸,旋屏时自动调整尺寸.
    if (self.translatesAutoresizingMaskIntoConstraints) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}
#pragma clang diagnostic pop

#pragma mark - 刷新表格

- (void)reloadAllData
{
    [self p_prepareForReloadAllData];

    [self p_calculateCellFrame];

    [self p_setContentSize];
}

- (void)loadMoreData
{
    [self p_prepareForLoadMoreData];
    
    [self p_calculateCellFrame];

    [self p_setContentSize];
}

- (void)p_prepareForLoadMoreData
{
    self.numberOfCells = [self.dataSource numberOfCellsInWaterfallFlowView:self];
}

- (void)p_prepareForReloadAllData
{
    // 更新必要数据.
    if ([self.dataSource respondsToSelector:@selector(numberOfColumnsInWaterfallFlowView:)]) {
        self.numberOfColumns = [self.delegate numberOfColumnsInWaterfallFlowView:self];
    }
    
    [self p_prepareForLoadMoreData];

    // 重置高度数组.
    self.columnHeights = [NSMutableArray new];
    for (NSInteger i = 0; i < self.numberOfColumns; ++i) {
        self.columnHeights[i] = @(self.sectionInset.top);
    }

    // 移除屏幕上的 cell, 加入重用池.不移除可能会有个别重叠的情况.
    NSArray *visibleCells = self.visibleCells.allValues;
    [self.reusableCells addObjectsFromArray:visibleCells];
    [visibleCells makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // 清空 frame 数组和 cell 字典.
    [self.cellFrames removeAllObjects];
    [self.visibleCells removeAllObjects];
}

- (CGFloat)p_widthOfCell
{
    // 列间距总和.
    CGFloat totalOfMargin = (self.numberOfColumns - 1) * self.columnSpacing;

    // 父视图总宽度去掉两侧间距.
    CGFloat totalOfValidWidth =
        self.bounds.size.width - self.sectionInset.left - self.sectionInset.right;

    return (totalOfValidWidth - totalOfMargin) / self.numberOfColumns;
}

- (void)p_calculateCellFrame
{
    CGFloat    widthOfCell     = self.p_widthOfCell;
    NSUInteger numberOfCells   = self.numberOfCells;
    NSUInteger numberOfColumns = self.numberOfColumns;

    CGFloat scale = [UIScreen mainScreen].scale;

    __block NSUInteger shortestColumn;
    __block NSNumber   *minHeight;

    // 在上次索引的基础上计算新增加的 cell 的 frame, 上次索引可能是0.
    for (NSUInteger idx = self.cellFrames.count; idx < numberOfCells; ++idx) {

        // 获取最矮的一列的索引及其高度.
        [self.columnHeights lx_getMinValueAndIndexWithBlock:
         ^(NSUInteger index, NSNumber *minValue) {
             minHeight      = minValue;
             shortestColumn = index;
         }];

        CGFloat x =
            self.sectionInset.left + (widthOfCell + self.columnSpacing) * shortestColumn;

        // 第 0 行需加上顶部间距.
        CGFloat y = (idx < numberOfColumns) ?
            [minHeight doubleValue] : ([minHeight doubleValue] + self.rowSpacing);

        CGFloat height = [self.delegate waterfallFlowView:self
                                       cellHeightForWidth:widthOfCell
                                                  atIndex:idx];
        // 对 frame 做一下舍入处理,避免小数像素.
        CGRect frame = {
            LXPixelRound(x, scale),
            LXPixelRound(y, scale),
            LXPixelRound(widthOfCell, scale),
            LXPixelRound(height, scale)
        };

        [self.cellFrames addObject:[NSValue valueWithCGRect:frame]]; // 将计算出的 frame 存起来.

        self.columnHeights[shortestColumn] = @(height + y); // 更新高度数组记录.
    }
}

- (void)p_setContentSize
{
    // 获取最高一列的高度.
    NSUInteger count      = self.cellFrames.count;
    CGFloat    tempHeight = 0;
    CGFloat    maxHeight  = CGRectGetMaxY([self.cellFrames.lastObject CGRectValue]);

    for (NSUInteger i = count - self.numberOfColumns; i < count - 1; ++i) {
        tempHeight = CGRectGetMaxY([self.cellFrames[i] CGRectValue]);
        maxHeight  = (maxHeight < tempHeight) ? tempHeight : maxHeight;
    }

    // 根据最高列的高度设置滚动范围.
    self.contentSize = (CGSize){ 0, maxHeight + self.sectionInset.bottom };
}

#pragma mark - 从缓存池取 cell

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier
{
    if (!identifier) { return nil; }

    // 根据标识符从重用池获取 cell.
    LXWaterfallFlowViewCell *reusableCell;
    for (LXWaterfallFlowViewCell *cell in self.reusableCells) {
        if ([cell.reuseIdentifier isEqualToString:identifier]) {
            reusableCell = cell;
            [self.reusableCells removeObject:cell];
            break;
        }
    }

    [reusableCell prepareForReuse];

    return reusableCell;
}

#pragma mark - 获取 index 对应的 cell

- (LXWaterfallFlowViewCell *)cellAtIndex:(NSInteger)index
{
    CGRect frame = [self.cellFrames[index] CGRectValue];
    for (LXWaterfallFlowViewCell *cell in self.visibleCells.allValues) {
        if ( CGRectEqualToRect(frame, cell.frame) ) {
            return cell;
        }
    }
    return nil;
}

#pragma mark - 循环利用

- (void)layoutSubviews
{
    [super layoutSubviews];

    // ScrollView frame 发生变化时刷新表格,重新布局.
    if (!CGRectEqualToRect(self.frame, self.lastFrame)) {
        self.lastFrame = self.frame;
        [self reloadAllData];
    }

    [self p_recycleCell];
}

- (void)p_recycleCell
{
    // 移除父视图上已滚出屏幕的 cell, 加入重用池.
    for (UIView *cell in self.visibleCells.allValues) {
        if (![self p_isFrameOnScreen:cell.frame]) {
            [cell removeFromSuperview];
            [self.reusableCells addObject:cell];
            [self.visibleCells removeObjectForKey:[NSValue valueWithCGRect:cell.frame]];
        }
    }

    // 分别沿上下两个方向(即数组中往前和往后)判断 cell 是否应该显示在屏幕上.
    NSInteger index = [self p_indexOfAnyCellOnScreen];

    [self p_traverseForwardFromIndex:index];
    [self p_traverseBackwardFromIndex:index - 1];
}

- (void)p_traverseForwardFromIndex:(NSInteger)index
{
    NSValue  *rectValue;
    NSInteger count = self.cellFrames.count;
    for (NSInteger idx = index; idx < count; ++idx) { // 往屏幕下方查找.

        rectValue = self.cellFrames[idx];

        // cell 应该显示在屏幕上.若不存在,则需要提供.
        if ([self p_isFrameOnScreen:[rectValue CGRectValue]]) {
            if (!self.visibleCells[rectValue]) {
                [self p_displayCellWithFrameValue:rectValue atIndex:idx];
            }
        } else {
            return; // 由于数组是按照 minY 升序排列的,所以再往后都不会出现在屏幕范围内,直接退出.
        }
    }
}

- (void)p_traverseBackwardFromIndex:(NSInteger)index
{
    NSValue *rectValue;
    for (NSInteger idx = index; idx >= 0; --idx) { // 往屏幕上方查找.

        rectValue = self.cellFrames[idx];

        if ([self p_isFrameOnScreen:[rectValue CGRectValue]]) {
            if (!self.visibleCells[rectValue]) {
                [self p_displayCellWithFrameValue:rectValue atIndex:idx];
            }
        }
        // cell 已离开屏幕,最多再向前查找"列数 - 1"个 cell 就可以了.
        else {
            NSInteger count = MAX(-1, idx - self.numberOfColumns);
            for (NSInteger i = idx - 1; i > count; --i) {

                rectValue = self.cellFrames[i];

                if ([self p_isFrameOnScreen:[rectValue CGRectValue]] && !self.visibleCells[rectValue]) {
                    [self p_displayCellWithFrameValue:rectValue atIndex:i];
                }
            }
            return;
        }
    }
}

- (NSInteger)p_indexOfAnyCellOnScreen
{
    CGRect   frame;
    CGFloat  minY, maxY;
    CGFloat  visibleMinY = self.contentOffset.y;
    CGFloat  visibleMaxY = visibleMinY + CGRectGetHeight(self.bounds);

    NSInteger count = self.cellFrames.count;
    NSInteger low = 0, high = count - 1, mid = NSNotFound;

    // 二分查找找出任意一个在屏幕上的 cell.
    while (low <= high) {
        mid = (low + high) / 2;

        frame = [self.cellFrames[mid] CGRectValue];
        minY  = CGRectGetMinY(frame);
        maxY  = CGRectGetMaxY(frame);

        if (minY >= visibleMaxY) { // 在屏幕下方外.
            high = mid - 1;
        } else if (maxY <= visibleMinY) { // 在屏幕上方外.
            low = mid + 1;
        } else {
            break; // 在屏幕上.
        }
    }

    return mid;
}

- (void)p_displayCellWithFrameValue:(NSValue *)frameValue atIndex:(NSInteger)idx
{
    LXWaterfallFlowViewCell *cell = [self.dataSource waterfallFlowView:self cellAtIndex:idx];
    cell.frame = [frameValue CGRectValue];

    [self addSubview:cell];
    self.visibleCells[frameValue] = cell;
}

- (BOOL)p_isFrameOnScreen:(CGRect)frame
{
    CGFloat minY = CGRectGetMinY(frame);
    CGFloat maxY = CGRectGetMaxY(frame);

    CGFloat visibleMinY = self.contentOffset.y;
    CGFloat visibleMaxY = visibleMinY + CGRectGetHeight(self.bounds);

    return (minY < visibleMaxY) && (maxY > visibleMinY);
}

#pragma mark - 点击事件处理

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 拖动中或减速中直接退出.
    if (self.dragging) return;

    // 未实现代理方法直接退出.
    if (![self.delegate respondsToSelector:@selector(waterfallFlowView:didSelectCellAtIndex:)]) return;

    CGPoint touchPoint = [[touches anyObject] locationInView:self];

    // 遍历屏幕上的 cell, 找出点击位置处于哪个 cell 内.
    LXWaterfallFlowViewCell *resultCell;
    for (LXWaterfallFlowViewCell *cell in self.visibleCells.allValues) {
        if ( CGRectContainsPoint(cell.frame, touchPoint) ) {
            resultCell = cell;
            break;
        }
    }

    // 点的不是 cell 直接退出.
    if (!resultCell) return;

    [self.delegate waterfallFlowView:self
            didSelectCellAtIndex:[self p_indexOfCellForFrame:resultCell.frame]];
}

- (NSInteger)p_indexOfCellForFrame:(CGRect)frame
{
    return [self.cellFrames indexOfObject:[NSValue valueWithCGRect:frame]
                            inSortedRange:(NSRange){ 0, self.cellFrames.count }
                                  options:NSBinarySearchingFirstEqual
                          usingComparator:^NSComparisonResult(id obj1, id obj2) {

                              CGRect frame1 = [obj1 CGRectValue];
                              CGRect frame2 = [obj2 CGRectValue];

                              CGFloat minY1 = CGRectGetMinY(frame1);
                              CGFloat minY2 = CGRectGetMinY(frame2);
                              if (minY1 > minY2) return NSOrderedDescending;
                              if (minY1 < minY2) return NSOrderedAscending;

                              // minY 相等时,比较 minX.
                              CGFloat minX1 = CGRectGetMinX(frame1);
                              CGFloat minX2 = CGRectGetMinX(frame2);
                              if (round(minX1) == round(minX2)) return NSOrderedSame;
                              if (minX1 > minX2)                return NSOrderedDescending;
                              if (minX1 < minX2)                return NSOrderedAscending;

                              return NSOrderedSame; // 防止编译报错.
                          }];
}

@end