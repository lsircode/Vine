//
//  SDCursorView.m
//  SDPagesSelector
//
//  Created by 宋东昊 on 16/7/15.
//  Copyright © 2016年 songdh. All rights reserved.
//

#import "SDCursorView.h"
#import "SDSelectorCell.h"

static NSString *const cellIdentifier = @"selectorCell";

@interface SDCursorView ()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIScrollView *rootScrollView;

@property (nonatomic) CGFloat titleAddWidth;

@end

@implementation SDCursorView

-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        //设置颜色默认值
        _normalFont = _selectedFont = [UIFont systemFontOfSize:14];
        _normalColor = [UIColor blackColor];
        _selectedColor = [UIColor redColor];
        _currentIndex = 0;
        _lineEdgeInsets = UIEdgeInsetsMake(1, 0, 0, 0);
        _cursorEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        
        _titleAddWidth = 10;
        
    }
    return self;
}


#pragma mark - SETUP UI
-(UIScrollView*)rootScrollView
{
    if (!_rootScrollView) {
        _rootScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y + CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds), self.contentViewHeight)];
        _rootScrollView.backgroundColor = [UIColor clearColor];
        _rootScrollView.pagingEnabled = YES;
        _rootScrollView.delegate = self;
        _rootScrollView.alwaysBounceHorizontal = YES;
        _rootScrollView.showsVerticalScrollIndicator = NO;
        _rootScrollView.showsHorizontalScrollIndicator = NO;
        _rootScrollView.scrollsToTop = NO;
        _rootScrollView.bounces = YES;
    }
    return _rootScrollView;
}

-(UIView*)lineView
{
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = [UIColor purpleColor];
        [self.collectionView addSubview:_lineView];
    }
    return _lineView;
}

-(UICollectionView*)collectionView
{
    if (!_collectionView) {
        _layout = [[UICollectionViewFlowLayout alloc]init];
        _layout.minimumLineSpacing = 0;
        _layout.minimumInteritemSpacing = 0;
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        CGRect rect = CGRectMake(_cursorEdgeInsets.left, _cursorEdgeInsets.top, CGRectGetWidth(self.bounds)-_cursorEdgeInsets.left-_cursorEdgeInsets.right, CGRectGetHeight(self.bounds)-_cursorEdgeInsets.top-_cursorEdgeInsets.bottom);
        _collectionView = [[UICollectionView alloc]initWithFrame:rect collectionViewLayout:_layout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.scrollsToTop = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[SDSelectorCell class] forCellWithReuseIdentifier:cellIdentifier];
        [self addSubview:_collectionView];
        
    }
    return _collectionView;
}


-(void)reloadPages
{
    NSAssert(_titles.count == _controllers.count, @"titles' count is not equal to controllerNames' count");
    [self.collectionView reloadData];
    
    [self addChildViewController];
}

- (void)setTitles:(NSArray *)titles {
    [self setTitles:titles normalImages:nil selectedImages:nil];
}

-(void)setTitles:(NSArray *)titles normalImages:(NSArray *)normalImages selectedImages:(NSArray *)selectedImages
{
    _titles = titles;
    _normalImages = normalImages;
    _selectedImages = selectedImages;
    
    self.rootScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds)*self.titles.count, 100);
    
    /**
     *  适配title宽度
     */
    CGFloat allWidth = 0;
    for (int i = 0; i < _titles.count; i++) {
        NSString *title = _titles[i];
        CGSize size = [title sizeWithAttributes:@{NSFontAttributeName:self.selectedFont}];
        
        if (_normalImages.count > i) {
            UIImage *image = [UIImage imageNamed:_normalImages[i]];
            CGSize s = image.size;
            size.width += s.width + 6;
        }
        
        allWidth += size.width + _titleAddWidth;
    }
    CGFloat w = SCREEN_WIDTH - allWidth;
    if (w > 0) {
        _titleAddWidth += w / (CGFloat)_titles.count;
    }
    
}


/**
 *  将子viewController添加到scrollView上
 */
-(void)addChildViewController
{
    //viewController
    UIViewController *controller = _controllers[_currentIndex];
    
    CGFloat startX = CGRectGetWidth(self.rootScrollView.bounds)*_currentIndex;
    if (!controller.parentViewController) {
        [self.parentViewController addChildViewController:controller];
        CGRect rect = self.rootScrollView.bounds;
        rect.origin.x = startX;
        controller.view.frame = rect;
        [self.rootScrollView addSubview:controller.view];
        [controller didMoveToParentViewController:self.parentViewController];
    }

    [self.rootScrollView setContentOffset:CGPointMake(startX, 0) animated:NO];
    [self.parentViewController.view addSubview:_rootScrollView];
}

/**
 *  设置collectionView的偏移量，使得选中的项目居中
 *
 *  @param frame cellFrame
 */
-(void)setContentOffsetWithCellFrame:(CGRect)frame
{
    CGFloat width = CGRectGetWidth(self.collectionView.frame)/2;
    CGFloat offsetX = 0;
    
    if (CGRectGetMidX(frame) <= width) {
        
        offsetX = 0;
        
    }else if (CGRectGetMidX(frame) + width >= self.collectionView.contentSize.width) {
        
        offsetX = self.collectionView.contentSize.width - CGRectGetWidth(self.collectionView.frame);
        
    }else{
        offsetX = CGRectGetMidX(frame)-CGRectGetWidth(self.collectionView.frame)/2;
    }
    [self.collectionView setContentOffset:CGPointMake(offsetX, 0) animated:YES];
}
/**
 *  设置标识线的frame
 *
 *  @param frame cellFrame
 */
-(void)resizeLineViewWihtCellFrame:(CGRect)frame animated:(BOOL)animated
{
    CGFloat height = 3.0f;
  
    CGRect rect = CGRectMake(CGRectGetMinX(frame)+_lineEdgeInsets.left,
                             CGRectGetHeight(self.collectionView.frame)-height-_lineEdgeInsets.bottom,
                             CGRectGetWidth(frame)-_lineEdgeInsets.left*2, height-_lineEdgeInsets.top);
    
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            
            self.lineView.frame = rect;
            //当设置了选中线条宽度
            if (CGSizeEqualToSize(_lineSize, CGSizeZero) == NO ) {

                self.lineView.bounds = CGRectMake(0, 0, _lineSize.width, _lineSize.height);
            }
            
        }];
    }else{
        self.lineView.frame = rect;
         //当设置了选中线条宽度
        if (CGSizeEqualToSize(_lineSize, CGSizeZero) == NO ) {
             self.lineView.bounds = CGRectMake(0, 0, _lineSize.width, _lineSize.height);
            
        }
    }
    
    

}
/**
 *  主动设置cursor选中item
 *
 *  @param index index
 */
-(void)selectItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentIndex inSection:0];
    [self.collectionView selectItemAtIndexPath:indexPath
                                      animated:YES
                                scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    [self selectItemAtIndexPath:indexPath animated:animated];

}
/**
 *  设置计算选中的item状态
 *
 *  @param indexPath indexPath
 */
-(void)selectItemAtIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated
{
    SDSelectorCell *cell = (SDSelectorCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell setItemSelected:YES];
    CGRect rect = cell.frame;
    if (!cell) {
        UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
        rect = attributes.frame;
    }
    
    [self setContentOffsetWithCellFrame:rect];
    [self resizeLineViewWihtCellFrame:rect animated:animated];
    
    [self addChildViewController];
}
/**
 *  主动设置使item变为不可选
 *
 *  @param index index
 */
-(void)deselectItemAtIndex:(NSInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    SDSelectorCell *cell = (SDSelectorCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell setItemSelected:NO];
}

- (void)setContentCanScroll:(BOOL)contentCanScroll {
    _contentCanScroll = contentCanScroll;
    [self.rootScrollView setScrollEnabled:contentCanScroll];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.rootScrollView isEqual:scrollView]) {
        CGFloat offsetX = scrollView.contentOffset.x;
        if (offsetX >= 0) {
            NSInteger index = offsetX / CGRectGetWidth(self.bounds);
            if (self.currentIndex != index) {
                //响应滑动切换
                if([self.delegate respondsToSelector:@selector(sliderChangeItemWithIndex:)]){
                    [self.delegate sliderChangeItemWithIndex:index];
                }
                [self deselectItemAtIndex:self.currentIndex];
                self.currentIndex = index;
                [self selectItemAtIndex:self.currentIndex animated:YES];
            }
        }
    }
}


#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.titles.count;
}
//
// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDSelectorCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSString *title = _titles[indexPath.item];
    cell.title = title;
    if (_normalImages.count > indexPath.item) {
        cell.normalImage = _normalImages[indexPath.item];
    }
    if (_selectedImages.count > indexPath.item) {
        cell.selectedImage = _selectedImages[indexPath.item];
    }
    cell.normalFont = self.normalFont;
    cell.selectedFont = self.selectedFont;
    cell.normalColor = self.normalColor;
    cell.selectedColor = self.selectedColor;
    
    [cell setItemSelected:(indexPath.item == _currentIndex)];
    
    if (collectionView.indexPathsForSelectedItems.count <= 0) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:_currentIndex inSection:0]
                                          animated:NO
                                    scrollPosition:UICollectionViewScrollPositionNone];
        
        [self resizeLineViewWihtCellFrame:cell.frame animated:NO];
    }
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldSelect = YES;
    
    if (_delegate && [_delegate respondsToSelector:@selector(shouldSelectItemWithIndex:)]) {
        shouldSelect = [_delegate shouldSelectItemWithIndex:indexPath.item];
    }
    
    if (shouldSelect) {
        if (_currentIndex == indexPath.item) {
            return;
        }

        [self deselectItemAtIndex:_currentIndex];
        
        self.currentIndex = indexPath.item;
        
        [self selectItemAtIndexPath:indexPath animated:YES];
    }
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = _titles[indexPath.item];
    CGSize size = [title sizeWithAttributes:@{NSFontAttributeName:self.selectedFont}];

    size = CGSizeMake(size.width + _titleAddWidth, CGRectGetHeight(self.bounds));
    if (_normalImages.count > indexPath.item) {
        UIImage *image = [UIImage imageNamed:_normalImages[indexPath.item]];
        CGSize s = image.size;
        size.width += s.width + 6;
    }
    return size;
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}


@end
