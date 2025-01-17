//
//  SmallVideoPlayViewController.m
//  RingtoneDuoduo
//
//  Created by 唐天成 on 2019/1/5.
//  Copyright © 2019年 duoduo. All rights reserved.
//

#import "SmallVideoPlayViewController.h"
#import "KB_NearVideoPlayCell.h"
#import "DDVideoPlayerManager.h"
#import "SDImageCache.h"
#import "CommentsPopView.h"
#import "UMSocialWechatHandler.h"
#import "KB_KeyboardCustomVCViewController.h"

static NSString * const NearVideoCellIdentifier = @"NearVideoCellIdentifier";


@interface SmallVideoPlayViewController ()<UITableViewDataSource, UITableViewDelegate, ZFManagerPlayerDelegate, NearVideoPlayCellDlegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView      *bottomView;
@property (nonatomic, strong) QMUIButton  *commentButton;
@property (nonatomic, strong) QMUIButton   *commentBtn;
@property (nonatomic, strong) UIView *fatherView;
//这个是播放视频的管理器
@property (nonatomic, strong) DDVideoPlayerManager *videoPlayerManager;
//这个是预加载视频的管理器
@property (nonatomic, strong) DDVideoPlayerManager *preloadVideoPlayerManager;

// 是否正在加载中
@property (nonatomic, assign) BOOL isLoad;

@property (nonatomic, strong) KB_KeyboardCustomVCViewController *customVC;

@end

@implementation SmallVideoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.videoPlayerManager autoPause];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.videoPlayerManager autoPlay];
}

//设置导航栏背景色
- (UIImage *)navigationBarBackgroundImage{
   return [[UIImage alloc] init];
}

- (void)createUI {
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.pagingEnabled = YES;
    self.tableView.scrollsToTop = NO;
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = SCREEN_HEIGHT - TabBarHeight;
    self.tableView.estimatedSectionFooterHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.backgroundColor = [UIColor blackColor];
    [self.tableView registerClass:[KB_NearVideoPlayCell class] forCellReuseIdentifier:NearVideoCellIdentifier];

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.with.offset(0);
        make.height.offset(SCREEN_HEIGHT - TabBarHeight);
    }];
    if(@available(iOS 11.0, *)){
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;//UIScrollView也适用
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentPlayIndex inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self playIndex:self.currentPlayIndex];
        if(self.modelArray.count > (self.currentPlayIndex + 1)) {
            [self preLoadIndex:self.currentPlayIndex + 1];
        }
    });
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor  = UIColorMakeWithHex(@"#222222");
    [self.view addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.with.offset(0);
        make.height.offset(TabBarHeight);
    }];
    
    self.commentButton = [QMUIButton buttonWithType:UIButtonTypeCustom];
    [self.commentButton setTitle:@"说点什么..." forState:UIControlStateNormal];
    self.commentButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.commentButton.titleLabel.font = UIFontMake(15);
    [self.commentButton addTarget:self action:@selector(commentAction) forControlEvents:UIControlEventTouchUpInside];
    [self.commentButton setTitleColor:UIColorMakeWithHex(@"666666") forState:UIControlStateNormal];
    [self.view addSubview:self.commentButton];
    [self.commentButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.offset(SCREEN_WIDTH - 20);
        make.left.offset(10);
        make.top.mas_equalTo(self.tableView.mas_bottom).offset(10);
        make.height.offset(40);
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 默认不实现
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
    }else {
        if (self.currentPlayIndex + 1 == self.modelArray.count) {
            LQLog(@"没有了");
            if (!self.isLoad) {
                //self.page++;
                [self getDataList];
            }
        }
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

- (void)getDataList{
    if (self.isLoad) {
        return;
    }
    self.isLoad = YES;
    NSString *url = [NSString stringWithFormat:@"/video/showAll?page=%@&isSaveRecord=0&category=food",@(self.page)];
    [RequesetApi requestAPIWithParams:nil andRequestUrl:url completedBlock:^(ApiResponseModel *apiResponseModel, BOOL isSuccess) {
        self.isLoad = NO;
        if (isSuccess) {
            NSMutableArray *datas = [NSArray modelArrayWithClass:[KB_HomeVideoDetailModel class] json:apiResponseModel.data[@"rows"]].mutableCopy;
            if (datas.count == 0) {
                [SVProgressHUD showErrorWithStatus:@"暂无更多"];
            }
            if (self.page == 1) {
                [self.modelArray removeAllObjects];
                self.modelArray = datas;
            }else{
                [self.modelArray addObjectsFromArray:datas];
            }
            if (datas.count == 5) {
                //有下一页
                self.page++;
            }else{
                self.isLoad = YES;
            }
            [self.tableView reloadData];
        } else {
            [SVProgressHUD showErrorWithStatus:@"网络错误"];
        }
    }];
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
#pragma mark - Action
- (void) backToPreviousView:(id)sender;
{
    [self.videoPlayerManager resetPlayer];
    [self.preloadVideoPlayerManager resetPlayer];
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.customVC.view.superview) {
        return UIInterfaceOrientationMaskPortrait;
    } else {
        return self.supportedOrientationMask;
    }
}

- (void)commentAction{
    if (!self.customVC) {
        self.customVC = [[KB_KeyboardCustomVCViewController alloc] init];
    }
    if (!self.customVC.view.superview) {
        [self.customVC showInParentViewController:self.navigationController];
    } else {
        [self.customVC.textView resignFirstResponder];
    }
    @weakify(self)
    self.customVC.sendTextBlock = ^(NSString * text) {
        @strongify(self)
        if ([text isEqualToString:@""]) {
            [SVProgressHUD showErrorWithStatus:@"内容不能为空"];
            return;
        }
        [self onSendText:text];
    };
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

// 发表评论网络请求
- (void)onSendText:(NSString *)text{
    
    KB_HomeVideoDetailModel *model = self.modelArray[self.currentPlayIndex];
    NSString *requestUrl = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [RequesetApi requestAPIWithParams:nil andRequestUrl:[NSString stringWithFormat:@"/video/saveComments?comment=%@&videoId=%@&userId=%@",requestUrl,model.id,User_Center.id] completedBlock:^(ApiResponseModel *apiResponseModel, BOOL isSuccess) {
        if (isSuccess) {
        } else {
            [SVProgressHUD showErrorWithStatus:@"评论失败"];
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
@end
