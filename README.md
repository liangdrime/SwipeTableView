# SwipeTableView

# Overview
功能类似半糖首页菜单与QQ音乐歌曲列表页面。即支持UITableview的上下滚动，同时也支持不同列表之间的滑动切换。同时可以设置顶部header view与列表切换功能bar，使用方式类似于原生UITableview的tableHeaderView的方式。

![Demo OverView](https://github.com/Roylee-ML/SwipeTableView/blob/master/ScreenShot/wynews_screenshot.gif)

## Quick start 

SwipeTableView is available on [CocoaPods](http://cocoapods.org).  Add the following to your Podfile:

```ruby
pod 'SwipeTableView'
```

## Basic usage

* 使用方式类似UITableView，需要实现 `SwipeTableViewDataSource` 代理的两个方法：
  - 实现 `- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView` 返回列表item的个数

  - 实现 `- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view` 返回每个item对应的itemview，返回的视图类型需要时`UIScrollView`的子类：`UITableView`或者`UICollectionView`。这里采用重用机制，需要根据reusingView来创建单一的itemView。

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

* 使用的详细用法在SwipeTableViewDemo文件夹中，提供了四种示例：

  - `SingleOneKindView`   模式下数据源提供的是单一类型的itemView，这里默认提供的是 `CustomTableView` （`UITableView`的子类），并且每一个itemView的数据行数有多有少，因此在滑动到数据少的itemView时，再次触碰界面，当前的itemView会有回弹的动作（由于contentSize小的缘故）。

  - `HybridItemViews`     模式下数据源提供的itemView类型是混合的，即 `CustomTableView` 与 `CustomCollectionView` （`UICollectionView`的子类）。

  - `AdjustContentSize`   模式下自适应调整cotentOffszie属性，这里不同的itemView的数据行数有多有少，当滑动到数据较少的itemView时，再次触碰界面并不会导致当前itemView的回弹，这里当前数据少的itemView已经做了最小contentSize的设置。

  - `HiddenNavigationBar` 模式下隐藏导航。

  - Demo支持添加移除header（定义的`UIImageView`）与bar（自定义的 `CutomSegmentControl` ）的功能，同时自定义了一个返回按钮（支持手势滑动返回）。

## License

SwipeTableView is available under the MIT license. See the LICENSE file for more info.

