//
//  KB_BaseViewController.m
//  Project
//
//  Created by hi  kobe on 2020/4/6.
//  Copyright © 2020 hiKobe@lsirCode. All rights reserved.
//

#import "KB_BaseViewController.h"
#import "SmallVideoPlayCell.h"
#import "SmallVideoModel.h"
#import "DDVideoPlayerManager.h"
#import "SDImageCache.h"
#import "CommentsPopView.h"
#import "KB_HomeVideoDetailModel.h"
#import "UMSocialWechatHandler.h"
#import "UIViewController+ZJScrollPageController.h"
#import "KB_NearVideoPlayCell.h"

static NSString * const NearVideoCellIdentifier = @"NearVideoCellIdentifier";
#define cellHeight SCREEN_HEIGHT - TabBarHeight

@interface KB_BaseViewController ()<UITableViewDataSource, UITableViewDelegate, ZFManagerPlayerDelegate, NearVideoPlayCellDlegate>
@property (nonatomic, strong) UIView *fatherView;
//这个是播放视频的管理器
@property (nonatomic, strong) DDVideoPlayerManager *videoPlayerManager;
//这个是预加载视频的管理器
@property (nonatomic, strong) DDVideoPlayerManager *preloadVideoPlayerManager;

@end

@implementation KB_BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self createUI];
    self.page = 1;
    [self.tableView.mj_header beginRefreshing];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.videoPlayerManager autoPause];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //[self.videoPlayerManager autoPlay];
}

- (void)zj_viewDidLoadForIndex:(NSInteger)index{

}

- (void)createUI {
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.pagingEnabled = YES;
    [self.view addSubview:self.tableView];
    self.tableView.scrollsToTop = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = SCREEN_HEIGHT - TabBarHeight;
    self.tableView.estimatedSectionFooterHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.backgroundColor = UIColorMakeWithHex(@"#222222");
    [self.tableView registerClass:[KB_NearVideoPlayCell class] forCellReuseIdentifier:NearVideoCellIdentifier];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(self.view).offset(0);
        make.height.offset(SCREEN_HEIGHT - TabBarHeight);
    }];
    @weakify(self)
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        @strongify(self)
        self.page = 1;
        self.tableView.mj_footer.hidden = YES;
        [self getDataList];
    }];
    self.tableView.mj_header.ignoredScrollViewContentInsetTop = 10;
    ((MJRefreshNormalHeader *)self.tableView.mj_header).lastUpdatedTimeLabel.hidden = YES;
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        @strongify(self)
        [self getDataList];
    }];
}

#pragma mrak - UITableViewDataSource & UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KB_NearVideoPlayCell *cell = [tableView dequeueReusableCellWithIdentifier:NearVideoCellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.videoModel = self.modelArray[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SCREEN_HEIGHT - TabBarHeight;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    DLog(@"快点播放下一个");
    NSInteger currentIndex = round(self.tableView.contentOffset.y / (SCREEN_HEIGHT - TabBarHeight));
    if(self.currentPlayIndex != currentIndex) {
        if(self.currentPlayIndex > currentIndex) {
            [self preLoadIndex:currentIndex-1];
        } else if(self.currentPlayIndex < currentIndex) {
            [self preLoadIndex:currentIndex+1];
        }
        self.currentPlayIndex = currentIndex;
        DLog(@"播放下一个");
        [self playIndex:self.currentPlayIndex];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat currentIndex = self.tableView.contentOffset.y / (SCREEN_HEIGHT - TabBarHeight);
    if(fabs(currentIndex - self.currentPlayIndex)>1) {
        [self.videoPlayerManager resetPlayer];
        [self.preloadVideoPlayerManager resetPlayer];
    }
}

- (void)playIndex:(NSInteger)currentIndex {
    DLog(@"播放下一个");
    KB_NearVideoPlayCell *currentCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
    
    NSString *artist = nil;
    NSString *title = nil;
    NSString *cover_url = nil;
    NSURL *videoURL = nil;
    NSURL *originVideoURL = nil;
    BOOL useDownAndPlay = NO;
    AVLayerVideoGravity videoGravity = AVLayerVideoGravityResizeAspect;
    
    
    KB_HomeVideoDetailModel *currentPlaySmallVideoModel = self.modelArray[currentIndex];
    
    artist = currentPlaySmallVideoModel.nickName;
    title = currentPlaySmallVideoModel.videoDesc;
    // 首帧图
    cover_url = [NSString stringWithFormat:@"%@%@",kAddressUrl,currentPlaySmallVideoModel.coverPath];
    // 视频地址
    videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAddressUrl,currentPlaySmallVideoModel.videoPath]];
    originVideoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAddressUrl,currentPlaySmallVideoModel.videoPath]];
    useDownAndPlay = YES;
    if((currentPlaySmallVideoModel.videoHeight / currentPlaySmallVideoModel.videoWidth) >= 1.4) {
        videoGravity = AVLayerVideoGravityResizeAspectFill;
    } else {
        videoGravity = AVLayerVideoGravityResizeAspect;
    }
    
    self.fatherView = currentCell.playerFatherView;
    self.videoPlayerManager.playerModel.videoGravity = videoGravity;
    self.videoPlayerManager.playerModel.fatherView       = self.fatherView;
    self.videoPlayerManager.playerModel.title            = title;
    self.videoPlayerManager.playerModel.artist = artist;
    self.videoPlayerManager.playerModel.placeholderImageURLString = cover_url;
    self.videoPlayerManager.playerModel.videoURL         = videoURL;
    self.videoPlayerManager.originVideoURL = originVideoURL;
    self.videoPlayerManager.playerModel.useDownAndPlay = YES;
    //如果设备存储空间不足200M,那么不要边下边播
    if([self deviceFreeMemorySize] < 200) {
        self.videoPlayerManager.playerModel.useDownAndPlay = NO;
    }
    [self.videoPlayerManager resetToPlayNewVideo];
}

- (CGFloat)deviceFreeMemorySize {
    /// 总大小
    float totalsize = 0.0;
    /// 剩余大小
    float freesize = 0.0;
    /// 是否登录
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary)
    {
        NSNumber *_free = [dictionary objectForKey:NSFileSystemFreeSize];
        freesize = [_free unsignedLongLongValue]*1.0/(1024);
        
        NSNumber *_total = [dictionary objectForKey:NSFileSystemSize];
        totalsize = [_total unsignedLongLongValue]*1.0/(1024);
    } else
    {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return freesize/1024.0;
}

//预加载
- (void)preLoadIndex:(NSInteger)index {
    [self.preloadVideoPlayerManager resetPlayer];
    if(self.modelArray.count <= index || [self deviceFreeMemorySize] < 200  || index<0) {
        return;
    }
    NSString *artist = nil;
    NSString *title = nil;
    NSString *cover_url = nil;
    NSURL *videoURL = nil;
    NSURL *originVideoURL = nil;
    BOOL useDownAndPlay = NO;
    
    KB_HomeVideoDetailModel *currentPlaySmallVideoModel = self.modelArray[index];
    
    artist = currentPlaySmallVideoModel.nickName;
    title = currentPlaySmallVideoModel.videoDesc;
    // 首帧图
    cover_url = [NSString stringWithFormat:@"%@%@",kAddressUrl,currentPlaySmallVideoModel.coverPath];
    // 视频地址
    videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAddressUrl,currentPlaySmallVideoModel.videoPath]];
    originVideoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAddressUrl,currentPlaySmallVideoModel.videoPath]];
    useDownAndPlay = YES;
    
    self.preloadVideoPlayerManager.playerModel.title            = title;
    self.preloadVideoPlayerManager.playerModel.artist = artist;
    self.preloadVideoPlayerManager.playerModel.placeholderImageURLString = cover_url;
    self.preloadVideoPlayerManager.playerModel.videoURL         = videoURL;
    self.preloadVideoPlayerManager.originVideoURL = originVideoURL;
    self.preloadVideoPlayerManager.playerModel.useDownAndPlay = YES;
    self.preloadVideoPlayerManager.playerModel.isAutoPlay = NO;
    [self.preloadVideoPlayerManager resetToPlayNewVideo];
}



#pragma mark - NearVideoPlayCellDlegate

//评论
- (void)handleCommentVidieoModel:(KB_HomeVideoDetailModel *)model{
    CommentsPopView *popView = [[CommentsPopView alloc] initWithSmallVideoModel:model];
    [popView showToView:self.view];
}

//关注
- (void)handleAddConcerWithVideoModel:(KB_HomeVideoDetailModel *)model{
    KB_HomeVideoDetailModel *videoModel = model;
    videoModel.isFoucs = YES;
    self.modelArray[self.currentPlayIndex] = videoModel;
}


//点赞
- (void)handleFavoriteVdieoModel:(KB_HomeVideoDetailModel *)model{
    KB_HomeVideoDetailModel *videoModel = model;
    videoModel.likeCounts += 1;
    videoModel.isLike = YES;
    self.modelArray[self.currentPlayIndex] = videoModel;
}
//取消点赞
- (void)handleDeleteFavoriteVdieoModel:(KB_HomeVideoDetailModel *)model{
    KB_HomeVideoDetailModel *videoModel = model;
    videoModel.likeCounts -= 1;
    videoModel.isLike = NO;
    self.modelArray[self.currentPlayIndex] = videoModel;
}
- (void)handleShareVideoModel:(KB_HomeVideoDetailModel *)smallVideoModel{
    QMUIMoreOperationController *moreOperationController = [[QMUIMoreOperationController alloc] init];
    moreOperationController.cancelButtonTitleColor = UIColorMakeWithHex(@"#999999");
    moreOperationController.items = @[
                                     // 第一行
                                     @[
                                         [QMUIMoreOperationItemView itemViewWithImage:UIImageMake(@"icon_moreOperation_shareMoment") title:@"分享到微信" handler:^(QMUIMoreOperationController * _Nonnull moreOperationController, QMUIMoreOperationItemView * _Nonnull itemView) {
                                             [self shareVedioToPlatformType:UMSocialPlatformType_WechatSession];
                                             [moreOperationController hideToBottom];
                                         }],
                                         [QMUIMoreOperationItemView itemViewWithImage:UIImageMake(@"icon_moreOperation_shareFriend") title:@"分享到朋友圈" handler:^(QMUIMoreOperationController * _Nonnull moreOperationController, QMUIMoreOperationItemView * _Nonnull itemView) {
                                             [self shareVedioToPlatformType:UMSocialPlatformType_WechatTimeLine];
                                             [moreOperationController hideToBottom];
                                         }
                                         ]
                                     ],
    ];
    [moreOperationController showFromBottom];
}

- (void)shareVedioToPlatformType:(UMSocialPlatformType)platformType
{
    //获取要分享的视频内容
    KB_HomeVideoDetailModel *currentPlaySmallVideoModel = self.modelArray[self.currentPlayIndex];
    //创建分享消息对象
    UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];

    //创建视频内容对象
    UMShareVideoObject *shareObject = [UMShareVideoObject shareObjectWithTitle:@"OTunes" descr:currentPlaySmallVideoModel.videoDesc thumImage:[UIImage imageNamed:@"AppIcon"]];
    //设置视频网页播放地址
    shareObject.videoUrl = [NSString stringWithFormat:@"%@%@",kAddressUrl,currentPlaySmallVideoModel.videoPath];

    //分享消息对象设置分享内容对象
    messageObject.shareObject = shareObject;

    //调用分享接口
    [[UMSocialManager defaultManager] shareToPlatform:platformType messageObject:messageObject currentViewController:self completion:^(id data, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:@"分享失败"];
        }else{
            [SVProgressHUD showSuccessWithStatus:@"分享成功"];
        }
    }];
}
#pragma mark - LazyLoad

- (DDVideoPlayerManager *)videoPlayerManager {
    if(!_videoPlayerManager) {
        _videoPlayerManager = [[DDVideoPlayerManager alloc] init];
        _videoPlayerManager.managerDelegate = self;
    }
    return _videoPlayerManager;
}

- (DDVideoPlayerManager *)preloadVideoPlayerManager {
    if(!_preloadVideoPlayerManager) {
        DLog(@"%@",self);
        _preloadVideoPlayerManager = [[DDVideoPlayerManager alloc] init];
    }
    return _preloadVideoPlayerManager;
}

#pragma mark - dealloc
- (void)dealloc {
    [self.videoPlayerManager resetPlayer];
    [self.preloadVideoPlayerManager resetPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getDataList{
    if (self.page == 1) {
        [self showEmptyViewWithLoading];
    }
    NSString *url;
    if (self.homeType == HomeType_Recommend) {
        //推荐
        url = [NSString stringWithFormat:@"/video/showAll?page=%@&isSaveRecord=0&category=define",@(self.page)];
    } else {
        // 关注
        url = [NSString stringWithFormat:@"/video/showAll?page=%@&isSaveRecord=0&category=dress",@(self.page)];
    }
    [RequesetApi requestAPIWithParams:nil andRequestUrl:url completedBlock:^(ApiResponseModel *apiResponseModel, BOOL isSuccess) {
        [self hideEmptyView];
        if (isSuccess) {
            [self.tableView.mj_header endRefreshing];
            NSMutableArray *datas = [NSArray modelArrayWithClass:[KB_HomeVideoDetailModel class] json:apiResponseModel.data[@"rows"]].mutableCopy;
            if (self.page == 1) {
                [self.modelArray removeAllObjects];
                self.modelArray = datas;
            }else{
                [self.modelArray addObjectsFromArray:datas];
            }
            if (self.page == 1) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentPlayIndex inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self playIndex:self.currentPlayIndex];
                    if(self.modelArray.count > (self.currentPlayIndex + 1)) {
                        [self preLoadIndex:self.currentPlayIndex + 1];
                    }
                });
            }
            if (datas.count == 5) {
                //有下一页
                self.tableView.mj_footer.hidden = NO;
                [self.tableView.mj_footer endRefreshing];
                self.page++;
            }else{
                [self.tableView.mj_footer endRefreshing];
                // 通知已经全部加载完毕
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
                self.tableView.mj_footer.hidden = YES;
            }
            if (self.modelArray.count == 0) {
                [self showNoDataEmptyViewWithText:@"暂无数据" detailText:@""];
            }else{
                [self.tableView reloadData];
            }
            
        } else {
            self.tableView.mj_footer.hidden = YES;
            [self.tableView.mj_header endRefreshing];
            if (self.page == 1) {
                [self showEmptyViewWithImage:UIImageMake(@"404") text:@"" detailText:@"加载失败" buttonTitle:@"点击重试" buttonAction:@selector(getDataList)];
            }else{
                [SVProgressHUD showErrorWithStatus:@"网络错误"];
            }
        }
    }];
}
@end
