//
//  LXWaterfallFlowView.m
//  LXWaterfallFlowView
//
//  Created by 从今以后 on 15/7/11.
//  Copyright (c) 2015年 从今以后. All rights reserved.
//

#import "LXWaterfallFlowView.h"
#import "LXWaterfallFlowViewCell.h"

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

/** 记录最新一次的 frame. */
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

    if (self.translatesAutoresizingMaskIntoConstraints) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}
#pragma clang diagnostic pop

#pragma mark - 刷新表格

- (void)reloadData
{
    [self p_clearData];

    [self p_calculateFrameOfCell];

    [self p_setContentSize];
}

- (void)p_clearData
{
    // 移除屏幕上的 cell, 加入重用池.不移除旋屏时会有个别重叠的情况.
    NSArray *visibleCells = self.visibleCells.allValues;
    [self.reusableCells addObjectsFromArray:visibleCells];
    [visibleCells makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // 清空 frame 数组和 cell 字典.
    [self.cellFrames removeAllObjects];
    [self.visibleCells removeAllObjects];
}

- (CGFloat)p_widthOfCell
{
    // 询问代理应该显示的列数,否则使用默认值.
    if ([self.dataSource respondsToSelector:@selector(numberOfColumnsInWaterfallFlowView:)]) {
        self.numberOfColumns = [self.delegate numberOfColumnsInWaterfallFlowView:self];
    }

    CGFloat totalOfMargin     = (self.numberOfColumns - 1) * self.columnSpacing;
    CGFloat totalOfValidWidth = self.bounds.size.width - self.sectionInset.left - self.sectionInset.right;

    return (totalOfValidWidth - totalOfMargin) / self.numberOfColumns;
}

- (CGFloat)p_maxYForShortestColumnInArrayOfColumnMaxY:(const CGFloat [])arrayOfColumnMaxY
                                              atIndex:(NSUInteger *)index
                                      withArrayLength:(NSUInteger)length
{
    *index = 0;
    for (NSUInteger i = 1; i < length; ++i) {
        if (arrayOfColumnMaxY[i] < arrayOfColumnMaxY[*index]) {
            *index = i;
        }
    }
    return arrayOfColumnMaxY[*index];
}

- (void)p_calculateFrameOfCell
{
    CGFloat   widthOfCell   = [self p_widthOfCell];
    NSInteger numberOfCells = [self.dataSource numberOfCellsInWaterfallFlowView:self];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wvla"
    // 记录每列 maxY 的数组.
    CGFloat arrayOfColumnMaxY[self.numberOfColumns];
    for (NSInteger i = 0; i < self.numberOfColumns; ++i) {
        arrayOfColumnMaxY[i] = self.sectionInset.top;
    }
#pragma clang diagnostic pop

    CGFloat scale  = [UIScreen mainScreen].scale;
    for (NSInteger index = 0; index < numberOfCells; ++index) {

        NSUInteger shortestColumn;
        CGFloat maxYForShortestColumn =
            [self p_maxYForShortestColumnInArrayOfColumnMaxY:arrayOfColumnMaxY
                                                     atIndex:&shortestColumn
                                             withArrayLength:self.numberOfColumns];

        CGFloat x = self.sectionInset.left + (widthOfCell + self.columnSpacing) * shortestColumn;
        CGFloat y = (index < self.numberOfColumns) ?
            maxYForShortestColumn : (maxYForShortestColumn + self.rowSpacing);

        CGFloat height = [self.delegate waterfallFlowView:self
                                   cellHeightForWidth:widthOfCell
                                              atIndex:index];
        CGRect  frame  = {
            LXPixelRound(x, scale),
            LXPixelRound(y, scale),
            LXPixelRound(widthOfCell, scale),
            LXPixelRound(height, scale)
        };

        [self.cellFrames addObject:[NSValue valueWithCGRect:frame]];

        arrayOfColumnMaxY[shortestColumn] = CGRectGetMaxY(frame);
    }
}

- (void)p_setContentSize
{
    NSUInteger count      = self.cellFrames.count;
    CGFloat    tempHeight = 0;
    CGFloat    maxHeight  = CGRectGetMaxY([self.cellFrames.lastObject CGRectValue]);

    for (NSUInteger i = count - self.numberOfColumns; i < count - 1; ++i) {
        tempHeight = CGRectGetMaxY([self.cellFrames[i] CGRectValue]);
        maxHeight  = (maxHeight < tempHeight) ? tempHeight : maxHeight;
    }

    self.contentSize = (CGSize){ 0, maxHeight + self.sectionInset.bottom };
}

#pragma mark - 从缓存池取 cell

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier
{
    LXWaterfallFlowViewCell *reusableCell;
    for (LXWaterfallFlowViewCell *cell in self.reusableCells) {
        if ([cell.reuseIdentifier isEqualToString:identifier]) {
            reusableCell = cell;
            [self.reusableCells removeObject:cell];
            break;
        }
    }
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

    if (!CGRectEqualToRect(self.frame, self.lastFrame)) {
        self.lastFrame = self.frame;
        [self reloadData];
    }

    [self p_reuseCell];
}

- (void)p_reuseCell
{
    [self p_recycleCell];

    NSInteger index = [self p_indexOfAnyCellOnScreen];
    [self p_traverseForwardFromIndex:index];
    [self p_traverseBackwardFromIndex:index - 1];
}

- (void)p_recycleCell
{
    for (UIView *cell in self.visibleCells.allValues) {
        if (![self p_isFrameOnScreen:cell.frame]) {
            [cell removeFromSuperview];
            [self.reusableCells addObject:cell];
            [self.visibleCells removeObjectForKey:[NSValue valueWithCGRect:cell.frame]];
        }
    }
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

    // 二分查找找出一个在屏幕上的 cell.
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