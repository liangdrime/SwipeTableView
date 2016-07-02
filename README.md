# SwipeTableView

# Overview
功能类似半糖首页菜单与QQ音乐歌曲列表页面。即支持UITableview的上下滚动，同时也支持不同列表之间的滑动切换。同时可以设置顶部header view与列表切换功能bar，使用方式类似于原生UITableview的tableHeaderView的方式。

![Demo OverView1](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/screenshot1.gif)  
![Demo OverView2](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/screenshot2.gif)

## Quick start 

SwipeTableView is available on [CocoaPods](http://cocoapods.org).  Add the following to your Podfile:

```ruby
pod 'SwipeTableView'
```

## Introduction

  由于公司的项目要实现类似半塘首页的功能，既能上下滚动又能左右滑动切换。后想到的实现方式是：

  - 1.先设置一个contentView，这里采用UICollectionView，作为视图的内容载体。

  - 2.创建UIScrollView子类的itemView，作为UICollectionView的cell，这样便实现了左右滑动

  - 3.支持左右滑动之后，关键的问题是滑动后相邻item的对齐问题，这里采用在itemView生成重用的时候，比较前后两个itemView的contentOffset，然后设置后一个itemView的contentOffset与前一个相同。这样就实现了左右滑动后前后itemView的offset是对齐的。

  - 4.对于header与可以悬停的顶部bar的实现，是在contentView（即根容器视图）上添加控件。然后对当前的itemView的contentOffset进行KVO，这样在当前itemView的contentOffset发生变化时，去改变header与bar的Y坐标值，实现同步滚动与悬停效果。

  - 5.由于项目为了兼容UITableView与UICollectionView，同时保留UITableView设置tableHeaderView的特性，常用的下拉刷新控件将不兼容。<p><del>为了支持常用的下拉刷新控件，解决方案见 [`Issue #1`](https://github.com/Roylee-ML/SwipeTableView/issues/1)</del></p>在最新的`0.2`以上版本中，只需要定义一个宏即可支持常用的下拉刷新控件（注：此时UITableView本身的tableHeaderView属性不能使用）。

  - 6.通过用户反映的问题[`issue#2`](https://github.com/Roylee-ML/SwipeTableView/issues/2)，在`0.1`版本中滑动`swipeHeaderView`并不能触发当前页面的`scrollView`跟随滚动。在`0.2`版本中，采用`UIKit Dynamic`物理动画引擎实现自定义`UIScrollView`效果解决上述问题，[`参考文章`](http://philcai.com/2016/03/15/%E7%94%A8UIKit-Dynamics%E6%A8%A1%E4%BB%BFUIScrollView/) [`英文博客`](http://holko.pl/2014/07/06/inertia-bouncing-rubber-banding-uikit-dynamics/)。
  - 7.为了保证在混合模式下(即`UITableView`与`UICollectionView`并用)，设置了自适应`shouldAdjustContentSize`属性或者支持下拉刷新，用户使用的`UICollectionView`需要时`STCollectionView`及其子类的实例。

## Basic usage

** 使用方式类似UITableView，需要实现 `SwipeTableViewDataSource` 代理的两个方法：**
  - `- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView`      
    返回列表item的个数

  - `- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view`     
    返回每个item对应的itemView，返回的视图类型需要时`UIScrollView`的子类：`UITableView`或者`UICollectionView`。这里采用重用机制，需要根据reusingView来创建单一的itemView。

** `SwipeTableViewDelegate` 代理提供了`SwipeTableVeiw`相关的代理操作，可以自行根据需要实现相关代理。**

** 现在可以一行代码支持常用的下拉刷新控件了，只需要在项目的PCH文件中或者在`SwipeTableView`的.h文件中设置如下的宏即可：**
```objc
#define ST_PULLTOREFRESH_HEADER_HEIGHT xx      
上述宏中的`xx`要与您使用的第三方下拉刷新控件的refreshHeader高度相同：      
`MJRefresh` 为 `MJRefreshHeaderHeight`，`SVPullToRefresh` 为 `SVPullToRefreshViewHeight`（目前只测试了这两个）
```

** 混合 item 模式，并支持自适应 contentSize 或者下拉刷新，`UICollectionView`需要时`STCollectionView`及其子类的实例，并需要代理与数据源需要遵守`STCollectionViewDataSource` & `STCollectionViewDelegate`协议，实现相关协议方法。**

** 示例：**
   - 初始化并设置header与bar
```objc
self.swipeTableView = [[SwipeTableView alloc]initWithFrame:self.view.bounds];
_swipeTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
_swipeTableView.delegate = self;
_swipeTableView.dataSource = self;
_swipeTableView.shouldAdjustContentSize = _shouldFitItemsContentSize;
_swipeTableView.swipeHeaderView = self.tableViewHeader;
_swipeTableView.swipeHeaderBar = self.segmentBar;
```
   
   - 实现代理：
```objc
- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView {
    return 4;
}

- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view {
    UITableView * tableView = view;
    if (nil == tableView) {
        UITableView * tableView = [[UITableView alloc]initWithFrame:swipeView.bounds style:UITableViewStylePlain];
        tableView.backgroundColor = [UIColor whiteColor];
        ...
    }
    // 这里刷新每个item的数据
    [tableVeiw setData:dataArray];
    [tableView reloadData];
    ...
    return tableView;
}
```
   
   - `STCollectionView`使用方法：
```objc
MyCollectionView.h

@interface MyCollectionView : STCollectionView

@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, assign) BOOL isWaterFlow;

@end



MyCollectionView.m

- (instancetype)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        STCollectionViewFlowLayout * layout = self.st_collectionViewLayout;
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 5;
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
        self.stDelegate = self;
        self.stDataSource = self;
        [self registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"item"];
        [self registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
        [self registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    }
    return self;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView layout:(STCollectionViewFlowLayout *)layout numberOfColumnsInSection:(NSInteger)section {
    return _numberOfColumns;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(0, 100);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(kScreenWidth, 35);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(kScreenWidth, 35);
}

- (UICollectionReusableView *)stCollectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView * reusableView = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
        // custom UI......
    }else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
        // custom UI......
    }
    return reusableView;
}

- (NSInteger)numberOfSectionsInStCollectionView:(UICollectionView *)collectionView {
    return _numberOfSections;
} 

- (NSInteger)stCollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _numberOfItems;
}

- (UICollectionViewCell *)stCollectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"item" forIndexPath:indexPath];
    // do something .......
    return cell;
}

```

** 如果`STCollectionViewFlowLayout`已经不能满足`UICollectionView`的布局的话，用户自定义的`flowlayout`需要继承自`STCollectionViewFlowLayout`，并在重写相应方法的时候需要调用父类方法，并需要遵循一定规则，如下：**

```objc
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

```


## Demo Info

** 使用的详细用法在SwipeTableViewDemo文件夹中，提供了五种示例：**

  - `SingleOneKindView`   
     数据源提供的是单一类型的itemView，这里默认提供的是 `CustomTableView` （`UITableView`的子类），并且每一个itemView的数据行数有多有少，因此在滑动到数据少的itemView时，再次触碰界面，当前的itemView会有回弹的动作（由于contentSize小的缘故）。

  - `HybridItemViews`     
     数据源提供的itemView类型是混合的，即 `CustomTableView` 与 `CustomCollectionView` （`UICollectionView`的子类）。

  - <p><del>`AdjustContentSize`   
     自适应调整cotentOffszie属性，这里不同的itemView的数据行数有多有少，当滑动到数据较少的itemView时，再次触碰界面并不会导致当前itemView的回弹，这里当前数据少的itemView已经做了最小contentSize的设置。</del></p>在0.2.3版本中去除了 demo 中的这一模块，默认除了`SingleOneKindView`模式下全部是自适应 contentSize。

  - `DisabledBarScroll`         
     取消顶部控制条的跟随滚动，只有在swipeHeaderView是nil的条件下才能生效。这样可以实现一个类似网易新闻首页的滚动菜单列表的布局。

  - `HiddenNavigationBar` 
     隐藏导航。自定义了一个返回按钮（支持手势滑动返回）。

  -  Demo支持添加移除header（定义的`UIImageView`）与bar（自定义的 `CutomSegmentControl` ）的功能。

  -  示例代码新增点击图片全屏查看。

## License

SwipeTableView is available under the MIT license. See the LICENSE file for more info.

