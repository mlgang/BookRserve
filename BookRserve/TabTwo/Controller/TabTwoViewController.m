//
//  TabTwoViewController.m
//  BookRserve
//
//  Created by jay on 2019/3/30.
//  Copyright © 2019 jay. All rights reserved.
//

#import "TabTwoViewController.h"
#import "buyBookCell.h"
#import "YYModel.h"
#import "MyBookList.h"
#import "NetWorkTool.h"
#import "MyInfoModel.h"
#import <MBProgressHUD.h>
#import "PublicTool.h"
#import "ZKVerifyAlertView.h"

@interface TabTwoViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong)UITableView *myTable;
@property (nonatomic,strong)NSMutableArray *infoArr;

@end

@implementation TabTwoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUI];
    [self setData];
}
- (void)setData{
    [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
    
    _infoArr = [NSMutableArray array];
    [NetWorkTool getBookListWithToken:[[NSUserDefaults standardUserDefaults] objectForKey:@"token"] completionBlock:^(NSDictionary * _Nonnull dic) {
        MyInfoModel *books = [MyInfoModel yy_modelWithDictionary:dic];
        for (MyBookList *book in books.books) {
            [self.infoArr addObject:book];
        }
        //主线程刷新数据
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.myTable reloadData];
            [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window]  animated:YES];
        });
    }];
}
- (void)configUI{
    self.view.backgroundColor = [UIColor whiteColor];
    _myTable = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _myTable.delegate = self;
    _myTable.dataSource = self;
    [self.view addSubview:_myTable];
    [_myTable registerClass:[buyBookCell class] forCellReuseIdentifier:@"twoCell"];
}
#pragma mark - table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _infoArr.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    buyBookCell *cell = [[buyBookCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"twoCell"];
    MyBookList *b = [_infoArr objectAtIndex:indexPath.row];
    cell.bookName.text = [NSString stringWithFormat:@"书名：%@",[b.title stringByRemovingPercentEncoding]];
    cell.authorLabel.text = [NSString stringWithFormat:@"作者：%@",[b.author stringByRemovingPercentEncoding]];
    cell.house.text = [NSString stringWithFormat:@"出版社：%@",[b.publishingHouse stringByRemovingPercentEncoding]];
    cell.oldDegree.text = [NSString stringWithFormat:@"折旧率：%@",[b.depreciationRate stringByRemovingPercentEncoding]];
    cell.Person.text = [NSString stringWithFormat:@"发布人：%@",[b.name stringByRemovingPercentEncoding]];
    cell.teleLabel.text = [NSString stringWithFormat:@"联系电话：%@",b.phone];;
    cell.timeLabel.text = b.time;
    cell.addressLabel.text = [NSString stringWithFormat:@"地址：%@",[b.address stringByRemovingPercentEncoding]];
    if ([b.status isEqualToString:@"0"]) {//可购
        [cell.dealBtn setTitle:@"拍下" forState:UIControlStateNormal];
        cell.dealBtn.backgroundColor = [PublicTool getColor];
        [cell.dealBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        cell.dealBtn.userInteractionEnabled = YES;
    }else if ([b.status isEqualToString:@"1"]){//已购
        [cell.dealBtn setTitle:@"已拍下" forState:UIControlStateNormal];
       cell.dealBtn.backgroundColor = [UIColor whiteColor];
        [cell.dealBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        cell.dealBtn.userInteractionEnabled = NO;
    }else{//我的发布
        [cell.dealBtn setTitle:@"我的发布" forState:UIControlStateNormal];
        cell.dealBtn.backgroundColor = [UIColor whiteColor];
        [cell.dealBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        cell.dealBtn.userInteractionEnabled = NO;
    }
   // __weak typeof(self) weakSelf = self;
    cell.buyBookBlock = ^{
        ZKVerifyAlertView *verifyView = [[ZKVerifyAlertView alloc] initWithMaximumVerifyNumber:3 results:^(ZKVerifyState state) {
            if (state == ZKVerifyStateSuccess) {
                //拍书
                        [NetWorkTool buyBookWithToken:[[NSUserDefaults standardUserDefaults] objectForKey:@"token"] UUID:b.UUID completionBlock:^(NSDictionary * _Nonnull dic) {
                            if ([[dic objectForKey:@"resault"] isEqualToString:@"true"]) {
                                // 拍下成功后，刷新
                                //刷新成功后，显示已拍下-----------
                                [PublicTool showHUDWithText:@"已拍下"];
                
                                [self.infoArr removeAllObjects];
                                [NetWorkTool getBookListWithToken:[[NSUserDefaults standardUserDefaults] objectForKey:@"token"] completionBlock:^(NSDictionary * _Nonnull dic) {
                                    MyInfoModel *books = [MyInfoModel yy_modelWithDictionary:dic];
                                    for (MyBookList *book in books.books) {
                                        [self.infoArr addObject:book];
                                    }
                                    //主线程刷新数据
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.myTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                                    });
                                }];
                            }
                        }];
            }
        }];
        [verifyView show];
 
    };
    return cell;
}


@end
