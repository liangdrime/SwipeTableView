//
//  STCollectionView.h
//  SwipeTableView
//
//  Created by Roy lee on 16/6/29.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>


@class STCollectionView;
@class STCollectionViewFlowLayout;

/**
   `STCollectionView`数据源,代替`UICollectionViewDataSource`协议.使用注意如下:
 
   ①.`STCollectionView`及其子类最好不要使用系统的`UICollectionViewDataSource`协议方法,否则在 dataSource 不是 self 的情况下数据展示会不正常(内部的 dataSource 设置始终是 self).
   ②.DataDource 需要实现`stCollectionView:numberOfItemsInSection:`与`stCollectionView:cellForItemAtIndexPath:`方法提供数据,此时系统的数据源协议要用此协议方法替换.
 */
@protocol STCollectionViewDataSource <NSObject>

/**
 *  以下两个方法提供 collection view 所需数据.
 *  ①.返回对应 section 的 item 的个数.
 *  ②.返回对应 indexPath 的 cell.
 */
- (NSInteger)stCollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
- (UICollectionViewCell *)stCollectionView:(STCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

/**
 *  返回collection view section 的个数.
 */
- (NSInteger)numberOfSectionsInStCollectionView:(UICollectionView *)collectionView;

/**
 *  设置 collection view 在 indexPath 下的 SupplementaryElement,可以通过这个方法设置 header 跟 footer.
 *  请勿使用原有方法`collectionView:viewForSupplementaryElementOfKind:atIndexPath:`.
 */
- (UICollectionReusableView *)stCollectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

@end


@protocol STCollectionViewDelegate <UICollectionViewDelegate>
@end



/**
   SwipeTableView 混合模式下,如果当前的 item 是`UICollectionView`的话,而且在默认支持自适应 contenSize 的条件下,该 item 需要是`STCollectionView`的实例或其子类的实例.
 
   对于layout,现在十分方便，已经完成了普通 CollectionView 的布局还有瀑布流支持,只需要调取`st_collectionViewLayout`属性获得`STCollectionViewFlowLayout`的实例,简单设置列数等参数,在不设置`itemHeight`的添加下通过代理提供item的高就可以了.
 */
@interface STCollectionView : UICollectionView

/**
 *  设置 collection view 的数据源与代理,遵守`STCollectionViewDataSource` & `UICollectionViewDelegate`协议.
 */
@property (nonatomic, weak) id<STCollectionViewDataSource>stDataSource;
@property (nonatomic, weak) id<STCollectionViewDelegate>stDelegate;

/**
 *  用于设置 collection view 最小要求的 contentSize.
 */
@property (nonatomic, assign) CGSize minRequireContentSize;

/**
 *  collection view 的 header view,在`SwipeTableView`支持下拉刷新的模式下,用于顶部留白的占位.
 */
@property (nonatomic, readonly, strong) UIView * collectionHeadView;

/**
 *  继承自`UICollectionViewFlowLayout`的`STCollectionViewFlowLayout`,是当前 collection view 的 flowlayout.用户可以通过这个属性拿到 collection view 的 flowlayout, 设置一些参数进行简单布局.
 */
@property (nonatomic, readonly, strong) STCollectionViewFlowLayout * st_collectionViewLayout;


/**
 *  默认初始化方法,可以不用传入 layout 参数.
 */
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end




/**
   `STCollectionViewFlowLayout`数据源,可以实现`STCollectionView:layout:heightForItemAtIndexPath:`来动态设置 item 的高度.
 */
@protocol STCollectionViewFlowLayoutDelegate <UICollectionViewDelegateFlowLayout>

@required
/**
 *  返回 section 所在区的列数.
 */
- (NSInteger)collectionView:(UICollectionView *)collectionView
                     layout:(STCollectionViewFlowLayout *)layout
   numberOfColumnsInSection:(NSInteger)section;

@end

/**
   `STCollectionView`专用的 flowlayout,用户需要获取`STCollectionView`的`STCollectionViewFlowLayout`来设置参数进行布局.
 
   现功能可以支持普通 collection view 布局 & 瀑布流布局.
   用户自定义 flowlayout 需要继承自`STCollectionViewFlowLayout`,并且要在重写`prepareLayout`,`layoutAttributesForElementsInRect`与`collectionViewContentSize`方法的时候调用父类的方法.
   例如:
   - (void)prepareLayout {
      [super prepareLayout];
      // do something in sub class......
   }
 
   - (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
      NSArray * superAttrs = [super layoutAttributesForElementsInRect:rect];
      NSMutableArray * itemAttrs = [superAttrs mutableCopy];
 
      // filter subClassAttrs to rect
      NSArray * filteredSubClassAttrs = ........;
    
      [itemAttrs addObjectsFromArray:fittesSubClassAttrs];
 
      return itemAttrs;
   }
 
   - (CGSize)collectionViewContentSize {
      CGSize superSize = [super collectionViewContentSize];
      
      CGSize subClassSize = .......;
      subClassSize.height += superSize.height;
 
      // fit mincontentSize
      STCollectionView * collectionView = (STCollectionView *)self.collectionView;
      subClassSize.height = fmax(subClassSize.height, collectionView.minRequireContentSize.height);
 
      return subClassSize;
   }
 
 */
@interface STCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) CGFloat columnCount;
@property (nonatomic, assign) CGFloat minimumLineSpacing;
@property (nonatomic, assign) CGFloat minimumInteritemSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;
@property (nonatomic, assign) CGSize itemSize;

/**
 *  需要自定义 flowlayout 的时候,自定义的 flowlayout 需要继承自`STCollectionViewFlowLayout`,并且在布局 Attributes 的时候,第一个 Attributes 的 orgin.y 需要从`topOffsetOfFirstAttributes`开始,而不是0点的位置
 */
@property (nonatomic, readonly, assign) CGFloat topOffsetOfFirstAttributes;

@end










