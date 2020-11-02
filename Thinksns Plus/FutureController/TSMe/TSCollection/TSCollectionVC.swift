//
//  TSCollectionVC.swift
//  ThinkSNS +
//
//  Created by GorCat on 17/4/14.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//
//  收藏

import UIKit
import ZFPlayer

class TSCollectionVC: TSViewController, UIScrollViewDelegate, ZFPlayerDelegate {
    /// 滚动视图
    let scrollView = UIScrollView(frame: CGRect(x: 0, y: 40, width: UIScreen.main.bounds.width, height: ScreenHeight - 40))
    /// 标签视图
    let titleView = UIView()
    /// 蓝色装饰线
    let blueLine = UIView(frame: CGRect(x: 15, y: 38, width: 37, height: 2))
    /// 灰色分割线
    let seperatorLine = UIView(frame: CGRect(x: 0, y: 39, width: UIScreen.main.bounds.width, height: 1))

    /// 标题按钮 tag
    let tagForTitleButtong = 200
    /// 标题数组
    let titleArray = ["动态", "资讯", "回答", "帖子"]
    /// 资讯页面
    var news: TSCollectionNewsVC!
    /// 动态收藏页
    let feeds = FeedCollectionController()
    /// 帖子收藏页
    let posts = PostsCollectionController()
    /// 回答收藏页
    let answer = TSAnswerCollectionController()
    // MARK: 播放相关
    var playerView: ZFPlayerView!
    var isPlaying = false
    /// 当前显示的视图
    var currentShowPage: FeedListActionView?
    /// 当前正在播放视频的视图
    var currentPlayingView: FeedListActionView?
    /// 当前正在播放视频的cell
    var currentPlayingCell: FeedListCell?
    /// 是否已经添加了播放器的播放状态监听，手动维护的一个属性
    private var didAddObserToPlayerViewPlayState = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        addNotice()
        feeds.table.feedListViewDelegate = self
        setPlayerView()
    }
    /// 添加相关收藏的通知
    fileprivate func addNotice() {
        NotificationCenter.default.addObserver(self, selector: #selector(collectionRefresh(noti:)), name: NSNotification.Name.Moment.momentDetailCollection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newRefresh(noti:)), name: NSNotification.Name.News.collection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(answerRefresh(noti:)), name: NSNotification.Name.Answers.collection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postRefresh(noti:)), name: NSNotification.Name.Posts.collection, object: nil)
        
    }
    /// 移除通知
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setPlayerView() {
        playerView = ZFPlayerView.shared()
        playerView.cellPlayerOnCenter = false
        playerView.stopPlayWhileCellNotVisable = true
        // 等比例填充，直到一个维度到达区域边界
        playerView.playerLayerGravity = ZFPlayerLayerGravity.resizeAspect
        playerView.forcePortrait = true
        playerView.hasPreviewView = false
        playerView.addObserver(self, forKeyPath: "state", options: [.new, .old], context: nil)
        didAddObserToPlayerViewPlayState = true
    }

    /// KVO监听属性
    ///
    /// - Parameters:
    ///   - keyPath: 被监听的属性名
    ///   - object:
    ///   - change:
    ///   - context:
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let playState = "\(self.playerView.value(forKey: keyPath!) ?? -1)"
        if self.playerView != nil && TSCurrentUserInfo.share.isAgreeUserCelluarWatchShortVideo == false && TSAppConfig.share.reachabilityStatus == .Cellular {
            if playState == "5" {
                self.perform(#selector(stopShortVideo), afterDelay: 0.000_01)
                let alert = TSAlertController(title: "提示", message: "您当前正在使用移动网络，继续播放将消耗流量", style: .actionsheet, sheetCancelTitle: "放弃")
                let action = TSAlertAction(title:"继续", style: .default, handler: { [weak self] (_) in
                    TSCurrentUserInfo.share.isAgreeUserCelluarWatchShortVideo = true
                    self?.playerView.play()
                })
                alert.addAction(action)
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: false, completion: nil)
            }
        }
    }

    @objc func stopShortVideo() {
        self.playerView.pause()
    }

    // MARK: - Custom user interface

    /// 设置视图
    func setUI() {
        title = "收藏"
        // scrollow 
        scrollView.contentSize = CGSize(width: scrollView.frame.width * CGFloat(titleArray.count), height: scrollView.frame.height)
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        // title view
        let topToolBgView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 40))
        topToolBgView.backgroundColor = UIColor.white
        let buttonWidth: CGFloat = 68
        titleView.frame = CGRect(x: (view.frame.width - buttonWidth * CGFloat(titleArray.count)) / 2, y: 0, width: buttonWidth * CGFloat(titleArray.count), height: 40)
        topToolBgView.addSubview(titleView)
        titleView.backgroundColor = UIColor.white
        for index in 0..<titleArray.count {
            let button = TSButton(type: .custom)
            button.tag = tagForTitleButtong + index
            button.addTarget(self, action: #selector(buttonTaped(_:)), for: .touchUpInside)
            button.titleLabel?.font = UIFont.systemFont(ofSize: TSFont.Button.keyboardRight.rawValue)
            button.setTitleColor(TSColor.normal.minor, for: .normal)
            button.setTitle(titleArray[index], for: .normal)
            button.frame = CGRect(x: CGFloat(index) * buttonWidth, y: 0, width: buttonWidth, height: 40)
            if index == 0 {
                button.setTitleColor(TSColor.inconspicuous.navHighlightTitle, for: .normal)
            }
            titleView.addSubview(button)
        }
        // blue line
        blueLine.backgroundColor = TSColor.main.theme
        // seperator line
        seperatorLine.backgroundColor = TSColor.inconspicuous.background

        titleView.addSubview(blueLine)
        view.addSubview(scrollView)
        view.addSubview(topToolBgView)
        view.addSubview(seperatorLine)

        // 设置初始显示页面为第一页
        setSelectedAt(0)

        // 设置子视图控制器
        let new = TSCollectionNewsVC(rootViewController: self)
        self.news = new
        add(childViewController: feeds, At: 0)
        add(childViewController: new, At: 1)
        add(childViewController: answer, At: 2)
        add(childViewController: posts, At: 3)
        add(childViewController: TSConllectionAlbumsVC(), At: 4)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.navigationController?.viewControllers.count == 1 && self.playerView != nil && self.isPlaying {
            self.isPlaying = false
            self.playerView.playerPushedOrPresented = false
        }
        NotificationCenter.default.addObserver(self, selector: #selector(didClickShortVideoShareBtn(_:)), name: NSNotification.Name(rawValue: "didClickShortVideoShareBtn"), object: nil)
        // 注册网络变化监听
        NotificationCenter.default.addObserver(self, selector: #selector(notiNetstatesChange(noti:)), name: Notification.Name.Reachability.Changed, object: nil)
        if self.playerView != nil, didAddObserToPlayerViewPlayState == false {
            playerView?.addObserver(self, forKeyPath: "state", options: [.new, .old], context: nil)
            didAddObserToPlayerViewPlayState = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.navigationController?.viewControllers.count == 2 && self.playerView != nil && self.playerView.isPauseByUser == false {
            self.isPlaying = true
            self.playerView.playerPushedOrPresented = true
        } else {
            self.playerView.resetPlayer()
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "didClickShortVideoShareBtn"), object: nil)
        // 移除网络变化监听
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Reachability.Changed, object: nil)
        if self.playerView != nil, didAddObserToPlayerViewPlayState == true {
            playerView?.removeObserver(self, forKeyPath: "state")
            didAddObserToPlayerViewPlayState = false
        }
    }
    // MARK: - Button click
    @objc func didClickShortVideoShareBtn(_ sender: Notification) {
        // 当分享内容为空时，显示默认内容
        guard let feedId = currentPlayingCell?.model.id["feedId"] else {
            return
        }
        guard currentPlayingCell?.model.sendStatus == .success else {
            return
        }
        var defaultContent = "默认分享内容".localized
        defaultContent.replaceAll(matching: "kAppName", with: TSAppSettingInfoModel().appDisplayName)
        let image = currentPlayingCell?.picturesView.pictures.first ?? UIImage(named: "IMG_icon")
        let description = currentPlayingCell?.model.content != "" ? currentPlayingCell?.model.content : defaultContent
        let shareView = ShareView()
        shareView.show(URLString: ShareURL.feed.rawValue + "\(feedId)", image: image, description: description, title: TSAppSettingInfoModel().appDisplayName + " " + "动态")
    }

    @objc func buttonTaped(_ sender: TSButton) {
        let index = sender.tag - tagForTitleButtong
        scrollView.setContentOffset(CGPoint(x: UIScreen.main.bounds.size.width * CGFloat(index), y: 0), animated: true)
    }

    // MARK: - Public

    /// 添加子视图控制器的方法
    ///
    /// - Parameters:
    ///   - childViewController: 子视图控制器
    ///   - index: 索引下标，从 0 开始，请与 titleArray 中的下标一一对应
    public func add(childViewController: Any, At index: Int) {
        let width = self.scrollView.frame.width
        let height = self.scrollView.frame.height
        if childViewController is UIViewController {
            let childVC = (childViewController as? UIViewController)!
            self.addChild(childVC)
            childVC.view.frame = CGRect(x: CGFloat(index) * width, y: 0, width: width, height: height - 64 - 40)
            self.scrollView.addSubview(childVC.view)
        }
    }

    /// 切换选中的分页
    ///
    /// - Parameter index: 分页下标
    public func setSelectedAt(_ index: Int) {
        scrollView.setContentOffset(CGPoint(x: scrollView.frame.width * CGFloat(index), y: 0), animated: false)
    }

    // MARK: - Private

    /// 更新 scrollow 的偏移位置
    private func update(childViewsAt index: Int) {
        let width = self.scrollView.frame.width
        // scroll view
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * width, y: 0), animated: true)
        updateButton(index)
    }

    var oldIndex = 0
    /// 刷新按钮
    private func updateButton(_ index: Int) {
        if oldIndex == index {
            return
        }
        let oldButton = (titleView.viewWithTag(tagForTitleButtong + oldIndex) as? TSButton)!
        oldButton.setTitleColor(TSColor.normal.minor, for: .normal)
        oldIndex = index

        let button = (titleView.viewWithTag(tagForTitleButtong + index) as? UIButton)!
        button.setTitleColor(TSColor.inconspicuous.navHighlightTitle, for: .normal)
    }
    /// 网络变化回调处理视频自动暂停
    @objc func notiNetstatesChange(noti: NSNotification) {
        if self.playerView != nil && TSCurrentUserInfo.share.isAgreeUserCelluarWatchShortVideo == false && TSAppConfig.share.reachabilityStatus == .Cellular && self.isPlaying {
            /// 只有在播放或者加载的时候亦或者是进度开始变化的时候才弹框
//            if self.playerView.state == ZFPlayerState.buffering || self.playerView.state == ZFPlayerState.playing || self.playerView.state == ZFPlayerState.started {
//                // 弹窗 然后继续播放
//                self.playerView.pause()
//                let alert = TSAlertController(title: "提示", message: "您当前正在使用移动网络，继续播放将消耗流量", style: .actionsheet, sheetCancelTitle: "放弃")
//                let action = TSAlertAction(title:"继续", style: .default, handler: { [weak self] (_) in
//                    self?.playerView.play()
//                    TSCurrentUserInfo.share.isAgreeUserCelluarWatchShortVideo = true
//                })
//                alert.addAction(action)
//                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: false, completion: nil)
//            }
        }
    }
    // MARK: - Delegate

    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var index = scrollView.contentOffset.x / scrollView.frame.width
        if index < 0 {
            index = CGFloat(0)
        }
        if Int(index) > titleArray.count {
            index = CGFloat(titleArray.count)
        }

        let i = round(index)
        updateButton(Int(i))
        blueLine.frame = CGRect(x: CGFloat(index) * titleView.frame.width / CGFloat(titleArray.count) + 15, y: blueLine.frame.origin.y, width: blueLine.frame.width, height: blueLine.frame.height)

        if i == 0 {
            self.playerView.play()
        } else {
            // 暂停播放
            self.playerView.pause()
        }
    }
}

extension TSCollectionVC: FeedListActionViewDelegate {
    func playVideoWith(_ feedListView: FeedListActionView, indexPath: IndexPath) {
        let model = feedListView.datas[indexPath.row]
        var url = URL(string: model.videoURL)
        if let fileURL = model.localVideoFileURL {
            let filePath = TSUtil.getWholeFilePath(name: fileURL)
            url = URL(fileURLWithPath: filePath)
        }
        guard url != nil else {
            return
        }
        let playModel = ZFPlayerModel()
        playModel.videoURL = url
        playModel.indexPath = indexPath
        playModel.scrollView = feedListView
        playModel.fatherViewTag = 10_086
        var listCell: FeedListCell?
        if let cell = feedListView.cellForRow(at: indexPath) as? FeedListCell, let image = cell.picturesView.pictureViews.first?.picture {
            playModel.placeholderImage = image
            listCell = cell
            self.playerView.placeholderBlurImageView.image = image
        } else {
            self.playerView.placeholderBlurImageView.image = nil
        }
        let controlView = CustomPlayerControlView()
        self.playerView.playerControlView(CustomPlayerControlView(), playerModel: playModel)
        controlView.zf_playerPlayEndBlock = {
            listCell?.playIcon.isHidden = true
        }
        self.playerView.playerLayerGravity = ZFPlayerLayerGravity.resizeAspect
        self.playerView.hasDownload = true
        self.playerView.delegate = self
        self.playerView.autoPlayTheVideo()
        self.currentPlayingView = feedListView
        self.currentPlayingCell = feedListView.cellForRow(at: indexPath) as? FeedListCell
        if TSMusicPlayerHelper.sharePlayerHelper.player.status == .Playing {
            TSMusicPlayVC.shareMusicPlayVC.playOrStop("")
        }
    }

    func didClickVideoCell(_ feedListView: FeedListActionView, cellIndexPath: IndexPath, fatherViewTag: Int) {
        // 判断网络然后决定是否播放
        if TSAppConfig.share.reachabilityStatus == .WIFI {
            playVideoWith(feedListView, indexPath: cellIndexPath)
        } else if TSAppConfig.share.reachabilityStatus == .Cellular {
            guard TSCurrentUserInfo.share.isAgreeUserCelluarWatchShortVideo == false else {
                self.playVideoWith(feedListView, indexPath: cellIndexPath)
                return
            }
            // 弹窗 然后继续播放
            let alert = TSAlertController(title: "提示", message: "您当前正在使用移动网络，继续播放将消耗流量", style: .actionsheet, sheetCancelTitle: "放弃")
            let action = TSAlertAction(title:"继续", style: .default, handler: { [weak self] (_) in
                self?.playVideoWith(feedListView, indexPath: cellIndexPath)
                TSCurrentUserInfo.share.isAgreeUserCelluarWatchShortVideo = true
            })
            alert.addAction(action)
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: false, completion: nil)
        } else if TSAppConfig.share.reachabilityStatus == .NotReachable {
            // 弹窗 然后继续播放
            let alert = TSAlertController(title: "提示", message: "网络未连接，请检查网络", style: .actionsheet, sheetCancelTitle: "停止播放")
            let action = TSAlertAction(title:"继续播放", style: .default, handler: { [weak self] (_) in
                self?.playVideoWith(feedListView, indexPath: cellIndexPath)
                TSCurrentUserInfo.share.isAgreeUserCelluarWatchShortVideo = true
            })
            alert.addAction(action)
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: false, completion: nil)
        }
    }
    /// 当tableView 滑动停止后如果屏幕上出现了可以播放视频的cell
    func canPlayVideoCell(_ feedListView: FeedListActionView, indexPath: IndexPath) {
        // 屏蔽了自动播放
    }
    func zf_playerDownload(_ url: String!) {
        TSUtil.share().showDownloadVC(videoUrl: url)
    }
}

extension TSCollectionVC {
    /// 动态收藏刷新
    /// - Parameter noti: <#noti description#>
    @objc func collectionRefresh(noti: NSNotification) {
        feeds.table.mj_header.beginRefreshing()
    }
    /// 资讯收藏刷新
    /// - Parameter noti: <#noti description#>
    @objc func newRefresh(noti: NSNotification) {
        self.news.listTableView.mj_header.beginRefreshing()
    }
    
    /// 回答收藏刷新
    /// - Parameter noti: <#noti description#>
    @objc func answerRefresh(noti: NSNotification) {
        self.answer.tableView.mj_header.beginRefreshing()
    }
    
    ///  帖子收藏刷新
    /// - Parameter noti: <#noti description#>
    @objc func postRefresh(noti: NSNotification) {
        posts.table.mj_header.beginRefreshing()
    }

}
