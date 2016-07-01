//
//  CustomTableView.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "CustomTableView.h"
#import "UIView+STFrame.h"
#define RGBColor(r,g,b)     [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

@interface CustomTableView ()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation CustomTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        self.separatorColor = RGBColor(175, 175, 175);
        [self registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
        self.tableFooterView = [UIView new];
        self.itemIndex = -1;
    }
    return self;
}

#pragma mark - UITableView M
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.backgroundColor = RGBColor(150, 215, 200);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSString * title = nil;
    if (_itemIndex >= 0) {
        title = [NSString stringWithFormat:@"[ ItemView_%ld ] ---- 第 %ld 行",_itemIndex,indexPath.row];
    }else {
        title = [NSString stringWithFormat:@"第 %ld 行",indexPath.row];
    }
    cell.textLabel.text = title;
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}

@end
