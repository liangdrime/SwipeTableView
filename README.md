# SwipeTableView

# Overview
功能类似半糖首页菜单与QQ音乐歌曲列表页面。即支持UITableview的上下滚动，同时也支持不同列表之间的滑动切换。同时可以设置顶部header view与列表切换功能bar，使用方式类似于原生UITableview的tableHeaderView的方式。

![Demo OverView](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShot/screenshot.gif)

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

## Basic usage

* 使用方式类似UITableView，需要实现 `SwipeTableViewDataSource` 代理的两个方法：
  - `- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView`      
    返回列表item的个数

  - `- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view`     
    返回每个item对应的itemView，返回的视图类型需要时`UIScrollView`的子类：`UITableView`或者`UICollectionView`。这里采用重用机制，需要根据reusingView来创建单一的itemView。

* `SwipeTableViewDelegate` 代理提供了`SwipeTableVeiw`相关的代理操作，可以自行根据需要实现相关代理。

* 示例：
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

## Demo Info

* 使用的详细用法在SwipeTableViewDemo文件夹中，提供了五种示例：

  - `SingleOneKindView`   
     数据源提供的是单一类型的itemView，这里默认提供的是 `CustomTableView` （`UITableView`的子类），并且每一个itemView的数据行数有多有少，因此在滑动到数据少的itemView时，再次触碰界面，当前的itemView会有回弹的动作（由于contentSize小的缘故）。

  - `HybridItemViews`     
     数据源提供的itemView类型是混合的，即 `CustomTableView` 与 `CustomCollectionView` （`UICollectionView`的子类）。

  - `AdjustContentSize`   
     自适应调整cotentOffszie属性，这里不同的itemView的数据行数有多有少，当滑动到数据较少的itemView时，再次触碰界面并不会导致当前itemView的回弹，这里当前数据少的itemView已经做了最小contentSize的设置。

  - `DisabledBarScroll`         
     取消顶部控制条的跟随滚动，只有在swipeHeaderView是nil的条件下才能生效。这样可以实现一个类似网易新闻首页的滚动菜单列表的布局。

  - `HiddenNavigationBar` 
     隐藏导航。自定义了一个返回按钮（支持手势滑动返回）。

  -  Demo支持添加移除header（定义的`UIImageView`）与bar（自定义的 `CutomSegmentControl` ）的功能。

## License

SwipeTableView is available under the MIT license. See the LICENSE file for more info.

