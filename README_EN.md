![LOGO](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/logo.png)

[![CocoaPods](https://img.shields.io/badge/pod-v0.2.4-28B9FE.svg)](http://cocoapods.org/pods/SwipeTableView)
![Platforms](https://img.shields.io/badge/platforms-iOS-orange.svg)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/Roylee-ML/SwipeTableView/blob/master/License)

This component support the UITableview scroll up and down, and both support switch between two list horizontally.At the same time it set a header and a segment bar at the top of list view, the usage is similar to the native UITableview tableHeaderView way.
****

# Overview

<img src="https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/screenshot1.gif" width = "290" height = "517" alt="OverView1" align=center />
<img src="https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/screenshot2.gif" width = "290" height = "517" alt="OverView1" align=center />
<img src="https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/screenshot3.gif" width = "290" height = "517" alt="OverView1" align=center />


# Quick start 

SwipeTableView is available on [CocoaPods](http://cocoapods.org).  Add the following to your Podfile:

```ruby
pod 'SwipeTableView'
```


# Catalog

1. [Principle](https://github.com/Roylee-ML/SwipeTableView/blob/master/README_EN.md#principle)
2. [Base Usage](https://github.com/Roylee-ML/SwipeTableView/blob/master/README_EN.md#how-to-use-it-just-like-uitableview)
3. [Pull To Refresh](https://github.com/Roylee-ML/SwipeTableView/blob/master/README_EN.md#how-to-support-pull-to-refersh)
4. [Hybrid Items](https://github.com/Roylee-ML/SwipeTableView/blob/master/README_EN.md#hybrid-uitableview--uicollectionview--uiscrollview)
5. [Example Code](https://github.com/Roylee-ML/SwipeTableView/blob/master/README_EN.md#example-code)
6. [Demo Info](https://github.com/Roylee-ML/SwipeTableView/blob/master/README_EN.md#detailed-usages-are-in-the-swipetableviewdemo-folder-provide-five-examples)


## Principle
>In order to be compatible with the pull to refresh, adopted two kinds of ways, but the basic structure is the same.
      
### Mode 1

![Mode 1](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/SwipeTableViewStruct1.png)
   
1. Use`UICollectionView`as a contentview for items，to enable scroll horizontally.

2. After supporting the horizontal scrolling, the most pivotal issue is the alignment of neighboring items after scroll horizontally.
>For the alignment of two itemViews after scroll, should compared to the contentOffsets of the two itemViews, and then set the contentOffset of the nest itemView same as the previous one. By this way, the offset of the itemView is aligned after scroll horizontally. 

3. Since the itemViews share a header and bar, so, the header and bar must be the subview of the root view, that is, the same as the CollectionView which is subview of `SwipeTableView`, and above the CollectionView.
>For support sticky of headr & bar, KVO observe the contentOffset of current itemView. And then change the Y frame of header and bar when the contentOffset of current itemView changed. 
 
4. Because he top header & bar are at the top, so the head of each itemView need make a blank space for header & bar display. In `Model 1`, the way is modify the top contentInsets of `UIScrollView` to set top blank space.

5. Due to the header is at the top of the layer, so if the current itemView should scroll follow with header when pan scroll the header, need to reset the contentOffset of current ItemView when header's frame changed. And the header must have a elasticity effect same as UIScrollview.
>Here, use the `UIKit Dynamic` physical animation engine to customize the `STHeaderView`, achieve the custom `UIScrollView` effect to solve the  problems above [`Reference`](http://holko.pl/2014/07/06/inertia-bouncing-rubber-banding-uikit-dynamics/).
 

### Mode 2

![Mode 2](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShots/SwipeTableViewStruct2.png)

1. In `Mode 2`, the basic structure sames as `Mode 1`, the only difference is that the top balnk of each itemView.
>By setting `tableHeaderView` of `UITabelView` to provide top space blank, CollectionView item should use custom `collectionHeaderView` of `STCollectionView` for set the blank. (Current mode does not support `UIScrollView`)



2. How to distinguish `Mode 1` from `Mode 2`?
>Under normal conditions, it is `Mode 1`; For `Mode 2`, set the macro `#define ST_PULLTOREFRESH_HEADER_HEIGHT xx` in the `SwipeTableView.h` or the PCH file.


## Basic Usage

### How to use it? Just like UITableView

**Conform protocol `SwipeTableViewDataSource` and implement the two methods below：**

```objc
- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView     
```
>Return a count of the itemViews.


   
```objc
- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view
```    
>Return a itemView at the index，the itemView must be kind of `UIScrollView`、`UITableView` or `UICollectionView`. It completed by reuse mechanism, so it is based the reusingView when create a itemView.


**The `swipeHeaderView` must be `STHeaderView` or subclass of `STHeaderView`**
 

### How to support pull to refersh?

>**There is two ways to support pull to refresh, one is custom pull to refresh by yourself(just custom part), another is set a macro simply and crudely**




**1. Support pull to refersh by one line code, juset set the macro below in `SwipeTableView.h` or the PCH file:**
 
```objc
#define ST_PULLTOREFRESH_HEADER_HEIGHT xx   
```

>The `xx` of macro above should be same as the height of your third pull to refresh component:      
`MJRefresh` is `MJRefreshHeaderHeight`, `SVPullToRefresh` is `SVPullToRefreshViewHeight` (Note: current mode is `Mode 2`)


Add a protocol of refresh, now you can set the top height of each itemView when began refresh, and set should supports pull to refresh for each item freely.
 
```objc
- (BOOL)swipeTableView:(SwipeTableView *)swipeTableView shouldPullToRefreshAtIndex:(NSInteger)index
```
 >Set the item should supports pull to refresh at the index. **Default is Yes When set macro `#define ST_PULLTOREFRESH_HEADER_HEIGHT xx`, otherwise is NO.**
 
 
```objc
- (CGFloat)swipeTableView:(SwipeTableView *)swipeTableView heightForRefreshHeaderAtIndex:(NSInteger)index
``` 
>Return a height of the itemView when began refresh, if not implement this method, the default height is `ST_PULLTOREFRESH_HEADER_HEIGHT` when you set the macro `#define ST_PULLTOREFRESH_HEADER_HEIGHT xx`.**If you didn't set the refresh macro, and want to support pull to refresh by custom the refresh, you must implement this method, and provide a height of the RefreshHeader(A height when the RefreshHeader show wholly), to notify `SwipeTableView` call the pull to refresh**


**2. If you want a better extension, as well as students who likes  research, you can try to modify or custom a refresh control to solve the problem of pull to refresh, while here provide some ideas:**

If the frame of refresh control is fixed (such as frame of refresh header), you can reset the frame of refresh header when init it, or reset the frame in the datasource of SwipeTableViewDataSource.
 
>Get the refresh header, and change Y of the frame, subtract both heights of `swipeHeaderView` and `swipeHeaderBar`(or override method `setFrame:` of RefreshHeader). So this way can solve the effect of top contentInsets of the itemVewi(othewise, the frefresh header will below the `swipeHeaderView`).

 
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

For some refreh control component, the frame of RefreshHeader will be set in mehtod `layoutSubviews`, so we should change the frame of RefreshHeader after execute `layouSubviews` of RefreshHeader, such as:
   
   
```objc
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    STRefreshHeader * header = self.header;
    CGFloat orginY = - (header.height + self.swipeTableView.swipeHeaderView.height + self.swipeTableView.swipeHeaderBar.height);
    if (header.y != orginY) {
        header.y = orginY;
    }
}
```


How to judge the frame of the RefreshHeader of refresh control is constant?
 
>One way is check out the source code of the refresh control; The other way is simple, just log the frame of RefreshHeader when scroll the itemView(most RefreshHeader height of third refresh control is constant).

 

### Hybrid (UItableView & UICollectionView & UIScrollView)

1. In basic mode `Model 1`, has the best extensibility, it supports `UITableView`、`UICollectionView`、`UIScrollView`.**If you set the property `shouldAdjustContentSize` YES to adjust the contentSize of itemView, you shuld only use `STCollectionView` its subcalss when your itemView is `UICollectionView` and its contentinfo is less**

>**`UICollectionView` can not set contentSize by property contentSize.**

2. In `Model 2`, **collectionView you used must be kind of `SwipeTableView`**, now, not support `UIScrollView`.


## **Example Code**：
### Init, set header and bar

```objc
self.swipeTableView = [[SwipeTableView alloc]initWithFrame:[UIScreen mainScreen].bounds];
_swipeTableView.delegate = self;
_swipeTableView.dataSource = self;
_swipeTableView.shouldAdjustContentSize = YES;
_swipeTableView.swipeHeaderView = self.tableViewHeader;
_swipeTableView.swipeHeaderBar = self.segmentBar;

```
   
### Conform the protocol：

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
    [tableVeiw refreshWithData:dataArray];
    ...
    return tableView;
}
```
   
### How to use `STCollectionView`:

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

**If `STCollectionViewFlowLayout` can not satisfy the layout of `UICollectionView`, you can custom a  `flowlayout` subcalss of `STCollectionViewFlowLayout`, And need to call call the parent class method and follow some rules when override methods, such as:**
   

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

### Detailed usages are in the SwipeTableViewDemo folder, provide five examples:

  - `SingleOneKindView`   
     The itemView is just one kind, it is `CustomTableView` (subclass of `UITableView`) in the demo

  - `HybridItemViews`     
     The itemViews which dataSource provided are hybird, they are `CustomTableView`  `CustomCollectionView`(subclass of `UICollectionView`) in the demo

  - <p><del>`AdjustContentSize`   
     Adjust the cotentOffszie to fit screen when the data is less than screen.</del></p>In release 0.2.3, delete this module in the demo, in module `SingleOneKindView` default is adjsut contentSize.

  - `DisabledBarScroll`         
     Disabel the segment scrolling when scroll the itemView, it is available when swipeHeaderView is nill.

  - `HiddenNavigationBar` 
     Hidden the nabigationbar. Have a back button, and support slide back.

  -  In the Demo, you can add or delete the header or bar.

  -  Tap the header can view the image in screen.
  
  -  Custom pull to refresh component `STRefreshHeader`, for reference only 

# License

SwipeTableView is available under the MIT license. See the LICENSE file for more info.

