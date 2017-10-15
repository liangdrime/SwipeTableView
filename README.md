![LOGO](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/logo.png)

[![CocoaPods](https://img.shields.io/badge/pod-v0.2.4-28B9FE.svg)](http://cocoapods.org/pods/SwipeTableView)
![Platforms](https://img.shields.io/badge/platforms-iOS-orange.svg)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/Roylee-ML/SwipeTableView/blob/master/License)

功能类似半糖首页菜单与QQ音乐歌曲列表页面。即支持UITableview的上下滚动，同时也支持不同列表之间的滑动切换。同时可以设置顶部header view与列表切换功能bar，使用方式类似于原生UITableview的tableHeaderView的方式。 [`Engilish→`](https://github.com/Roylee-ML/SwipeTableView/blob/master/README_EN.md)
****

# 预览
<img src="https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/screenshot1.gif" width = "290" height = "517" alt="OverView1" align=center />
<img src="https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/screenshot2.gif" width = "290" height = "517" alt="OverView1" align=center />
<img src="https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/screenshot3.gif" width = "290" height = "517" alt="OverView1" align=center />


# 使用 Cocoapods 导入
SwipeTableView is available on [CocoaPods](http://cocoapods.org).  Add the following to your Podfile:

```ruby
pod 'SwipeTableView'
```


# 目录
1. [实现原理](https://github.com/Roylee-ML/SwipeTableView/blob/master/README.md#实现的原理)
2. [基本用法](https://github.com/Roylee-ML/SwipeTableView/blob/master/README.md#怎样使用使用方式类似uitableview)
3. [下拉刷新](https://github.com/Roylee-ML/SwipeTableView/blob/master/README.md#如何支持下拉刷新)
4. [混合模式](https://github.com/Roylee-ML/SwipeTableView/blob/master/README.md#混合模式uitableview--uicollectionview--uiscrollview)
5. [示例代码](https://github.com/Roylee-ML/SwipeTableView/blob/master/README.md#示例代码)
6. [Demo介绍](https://github.com/Roylee-ML/SwipeTableView/blob/master/README.md#使用的详细用法在swipetableviewdemo文件夹中提供了五种示例)



## 实现的原理
>为了兼容下拉刷新，采用了两种实现方式，但基本构造都是一样的

### Mode 1

![Mode 1](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/SwipeTableViewStruct1.png)

1. 使用 `UICollectionView` 作为 item 的载体，实现左右滑动的功能。

2. 在支持左右滑动之后，最关键的问题就是是滑动后相邻 item 的对齐问题。
>为实现前后 item 对齐，需要在 itemView 重用的时候，比较前后两个 itemView的 contentOffset，然后设置后一个 itemView 的 contentOffset 与前一个相同。这样就实现了左右滑动后前后 itemView 的 offset 是对齐的。 

3. 由于多个 item 共用一个 header 与 bar，header 与 bar 的处理在最新版本中采用新的方式处理：
>首先，在横滑的过程中 header 与bar 会作为根视图的子视图，即与 CollectionView 一样是 `SwipeTableView` 的子视图，并且在 CollectionView 的图层之上。
>
>其次，当`SwipeTableView`只是在当前 item 做上下滑动的时候，会将公共的 header 与 bar 放在当前 item 上，保证上下滑动的效果更流畅。

4. 顶部 header & bar 作为公共区域在图层的最顶部，每个 itemView 的顶部需要有一个留白来作为 header & bar 的显示空间。在 `Mode 1` 中，采用修改 `UIScrollView` 的 contentInsets 的 top 值来留出顶部留白。
 

### Mode 2

![Mode 2](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/SwipeTableViewStruct2.png)

1. 在 `Mode 2` 中，基本结构与 `Mode 1` 一样，唯一的不同在于每个 itemView 顶部留白的的方式。
>通过设置 `UITabelView` 的 `tableHeaderView` ，来提供顶部的占位留白，CollectionView 采用自定义 `STCollectionView` 的 `collectionHeaderView` 来实现占位留白。（目前不支持 `UIScrollView` ）


2. 如何设置区分 `Mode 1` 与 `Mode 2` 模式？
>正常条件下为 `Mode 2` 模式；修改 `SwipeTableView` 属性 `itemContentTopFromHeaderViewBottom` 为 `YES` 切换为 `Mode 1` 模式，如果想要有更灵活的定义效果（比如自定义 collectionView），建议采用 `Mode 1` 模式。



## 使用用法
### 怎样使用？使用方式类似 UITableView

**实现 `SwipeTableViewDataSource` 代理的两个方法：**

```objc
- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView     
```
>返回列表 item 的个数


```objc
- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view
```
>返回对应 index 下的 itemView，返回的视图类型需要是 `UIScrollView` 及其子类：`UITableView` 或者`UICollectionView`。这里采用重用机制，需要根据 reusingView 来创建单一的 itemView。


### 如何支持下拉刷新？

**1. 由于在垂直滚动 itemview 的时候，公共的 header 是放在当前的 itemview 上的，所以，下拉刷新的组件可以正常使用即可，但是需要注意在 `Mode 1` 与 `Mode 2` 模式的区别：**
>`Mode 1` 与 `Mode 2` 对于顶部 header 留白的处理不同，导致在 `Mode 1` 情况下，顶部的留白是当前 itemview 的 `contentInset`，可能有些下拉控件的位置会在公共 header 的底部。

**2. 当采用 `Mode 1` 模式的时候，下拉控件位置不准确的话，此时，可以尝试修改或者自定义下拉控件来解决下拉刷新的兼容问题，同时这里提供一些思路：**

如果下拉刷新控件的 frame 是固定的（比如 header 的 frame），这样可以在初始化下拉刷新的 header 或者在数据源的代理中重设下拉 header 的 frame。

>获取下拉刷新的 header，将 header 的 frame 的 y 值减去 `swipeHeaderView` 与 `swipeHeaderBar` 的高度和（或者重写 RefreshHeader 的 setFrame 方法），就可以消除 itemView contentInsets 顶部留白 top 值的影响（否则添加的下拉 header 是隐藏在底部的）。

```objc
- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view {
   ...
   STRefreshHeader * header = scrollView.header;
   header.y = - (header.height + (swipeHeaderView.height + swipeHeaderBar.height));
   ...
}
 

or


- (instancetype)initWithFrame:(CGRect)frame {
   ...
   STRefreshHeader * header = [STRefreshHeader headerWithRefreshingBlock:^(STRefreshHeader *header) {

}];
   header.y = - (header.height + (swipeHeaderView.height + swipeHeaderBar.height)); 
   scrollView.header = header;
   ...
}
```

对于一些下拉刷新控件，RefreshHeader 的 frame 设置可能会在 `layoutSubviews` 中，所以，对 RefreshHeader frame 的修改,需要等执行完 `layouSubviews` 之后，在 <u>*有效的方法*</u> 中操作，比如：


```objc
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    STRefreshHeader * header = self.header;
    CGFloat orginY = - (header.height + self.swipeTableView.swipeHeaderView.height + self.swipeTableView.swipeHeaderBar.height);
    if (header.y != orginY) {
        header.y = orginY;
    }
}
```


如何判断下拉刷新的控件的 frame 是不是固定不变的呢？

>一是可以研究源码查看 RefreshHeader 的 frame 是否固定不变；另一个简单的方式是，在 ScrollView 的滚动代理中 log RefreshHeader 的 frame（大部分的下拉控件的 frame 都是固定的）。


如果使用的下拉刷新控件的 frame 是变化的（个人感觉极少数），那么只能更深层的修改下拉刷新控件或者自定义下拉刷新。也可以更直接的采用第一种设置宏的方式支持下拉刷新。</br>


### 混合模式（UItableView & UICollectionView & UIScrollView）

1. 在 `Mode 1` 模式下，属于最基本的模式，可扩展性也是最强的，此时，支持 `UITableView`、`UICollectionView`、`UIScrollView`。**如果，同时设置 `shouldAdjustContentSize` 为 YES，实现自适应 contentSize，在 `UICollectionView` 内容不足的添加下，只能使用 `STCollectionView` 及其子类**

   >**`UICollectionView`不支持通过contentSize属性设置contentSize。**

2. 在 `Mode 2` 模式下，**`SwipeTableView`支持的 collectionView 必须是 `STCollectionView` 及其子类的实例**，目前，不支持 `UIScrollView`。


## **示例代码**：

### 初始化并设置 header 与 bar
```objc
self.swipeTableView = [[SwipeTableView alloc]initWithFrame:[UIScreen mainScreen].bounds];
_swipeTableView.delegate = self;
_swipeTableView.dataSource = self;
_swipeTableView.shouldAdjustContentSize = YES;
_swipeTableView.itemContentTopFromHeaderViewBottom = YES;  // the common header will use top of  contentinset
_swipeTableView.swipeHeaderAlwaysOnTop = NO; // if YES the max y position of header view will be the top of screen & if will be sticky.
_swipeTableView.swipeHeaderView = self.tableViewHeader;
_swipeTableView.swipeHeaderBar = self.segmentBar;
```

### 实现数据源代理：
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
    // 这里刷新每个 item 的数据
    [tableVeiw refreshWithData:dataArray];
    ...
    return tableView;
}
```

### `STCollectionView` 使用方法：
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

**如果 `STCollectionViewFlowLayout` 已经不能满足`UICollectionView` 的布局的话，用户自定义的 `flowlayout` 需要继承自 `STCollectionViewFlowLayout`，并在重写相应方法的时候需要调用父类方法，并需要遵循一定规则，如下：**


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


## Demo 介绍
### 使用的详细用法在 SwipeTableViewDemo 文件夹中，提供了五种示例：

  - `SingleOneKindView`   
     数据源提供的是单一类型的 itemView，这里默认提供的是  `CustomTableView` （`UITableView` 的子类），并且每一个 itemView 的数据行数有多有少，因此在滑动到数据少的 itemView 时，再次触碰界面，当前的 itemView 会有回弹的动作（由于 contentSize 小的缘故）。

  - `HybridItemViews`     
     数据源提供的 itemView 类型是混合的，即 `CustomTableView` 与 `CustomCollectionView` （`UICollectionView`的子类）。

  - <p><del>`AdjustContentSize`   
     自适应调整 cotentOffszie 属性，这里不同的 itemView 的数据行数有多有少，当滑动到数据较少的 itemView 时，再次触碰界面并不会导致当前 itemView 的回弹，这里当前数据少的 itemView 已经做了最小 contentSize 的设置。</del></p>在0.2.3版本中去除了 demo 中的这一模块，默认除了 `SingleOneKindView` 模式下全部是自适应 contentSize。

  - `DisabledBarScroll`         
     取消顶部控制条的跟随滚动，只有在 swipeHeaderView 是 nil 的条件下才能生效。这样可以实现一个类似网易新闻首页的滚动菜单列表的布局。

  - `HiddenNavigationBar` 
     隐藏导航。自定义了一个返回按钮（支持手势滑动返回）。

  - Demo支持添加移除header（定义的`UIImageView`）与bar（自定义的 `CutomSegmentControl` ）的功能。

  - 示例代码新增点击图片全屏查看。

  - Demo中提供简单的自定义下拉刷新控件`STRefreshHeader`，供参考

# License
SwipeTableView is available under the MIT license. See the LICENSE file for more info.

