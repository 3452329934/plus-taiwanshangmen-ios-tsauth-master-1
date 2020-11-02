//
//  TSPostWebEditorController.swift
//  ThinkSNS +
//
//  Created by 小唐 on 27/01/2018.
//  Copyright © 2018 ZhiYiCX. All rights reserved.
//
//  帖子web编辑器
/**
 注：当前的同步至动态部分是取巧实现的，再工具栏的高度位置是没有计算动态的高度的，所以导致工具栏视图的不准确。
 需要进行优化，将同步至动态视图从工具栏中提取出来，作为页面的子视图进行控制与展示。
 需要注意的是，其可能动态隐藏与显示，且键盘关闭时仍展示再底部。
 之后作为优化部分，待完成。
 **/

import UIKit
import Kingfisher

typealias PostPublishController = TSPostWebEditorController

///  帖子web编辑器
class TSPostWebEditorController: TSWebEditorBaseVC {

    /// 展示类型
    enum ShowType: Int {
        /// 圈外发帖 - 需要自己去选择圈子
        case groupout = 0
        /// 圈内发帖
        case groupin
    }

    // MARK: - Internal Property
    /// 圈子id
    var groupId: Int?
    /// 圈子名 - 用于圈内发帖保存草稿再次编辑时变成圈外发帖
    var groupName: String?
    /// 是否可同步至动态
    var couldSyncMoment: Bool = false

    /// 保存草稿的回调
    var saveDraftAction: ((_ draftModel: TSPostDraftModel) -> Void)?

    // MARK: - Internal Function
    // MARK: - Private Property

    /// 展示类型，圈内发帖还是圈外发帖
    fileprivate let showType: ShowType

    /// 待编辑的帖子草稿
    fileprivate var editedDraft: TSPostDraftModel?

    /// 来自首页的 "+" 号中的发帖
    fileprivate var fromAdd: Bool = false

    /// 圈子选择控件，圈外才需要展示，圈内无需展示
    fileprivate let groupSelectControl = PostPublishGroupControl()
    fileprivate let groupSelectH: CGFloat = 50

    /// 标题输入框
    fileprivate weak var titleInputView: TSOriginalCenterOneInputView!
    /// 同步至动态的工具视图
    fileprivate let syncMomentView: TSEditorSyncMomentTopView = TSEditorSyncMomentTopView()

    /// 标题输入框的最小高度
    fileprivate let titleMinH: CGFloat = 50
    /// 标题长度最大值
    fileprivate let titleMaxLen: Int = 20

    // MARK: - Initialize Function

    // 草稿方式加载
    init(draft: TSPostDraftModel) {
        // 草稿箱编辑时都采用圈外发帖样式，即使草稿中保存有发帖样式。
        self.showType = .groupout
        self.editedDraft = draft
        if nil != draft.isSyncMoment {
            self.couldSyncMoment = true
        }
        super.init(editType: .draft)
    }
    /// 通过传入圈子信息进行加载，根据groupdId是否有值判定是圈内还是圈外
    init(groupId: Int?, groupName: String?, couldSyncMoment: Bool = false) {
        self.showType = (nil != groupId) ? .groupin : .groupout
        self.groupId = groupId
        self.groupName = groupName
        if nil != groupId && (nil == groupName || groupName!.isEmpty) {
            // 圈内发帖必须传入圈子名字，因为这种情况下保存草稿再次编辑时变成圈外发帖
            assert(false, "圈内发帖请传入圈子名")
        }
        self.couldSyncMoment = couldSyncMoment
        super.init(editType: .normal)
    }
    /// 便利构造，主要是用于从首页的加号进入时调用
    convenience init(fromAdd: Bool) {
        self.init(groupId: nil, groupName: nil)
        self.fromAdd = fromAdd
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCircle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

// MARK: - UI加载
extension TSPostWebEditorController {

    /// 界面布局
    override func initialUI() {
        self.view.backgroundColor = UIColor.white
        // 1. navigation bar
        self.navigationItem.title = "发帖"
        let backItem = UIButton(type: .custom)
        backItem.addTarget(self, action: #selector(leftItemClick), for: .touchUpInside)
        self.setupNavigationTitleItem(backItem, title: "显示_导航栏_返回".localized)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backItem)
        let nextItem = UIButton(type: .custom)
        nextItem.addTarget(self, action: #selector(rightItemClick), for: .touchUpInside)
        nextItem.setTitleColor(UIColor.lightGray, for: .disabled)
        self.setupNavigationTitleItem(nextItem, title: "显示_发布".localized)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: nextItem)
        self.leftItem = backItem
        self.rightItem = nextItem
        // 2. selectGroupView
        if self.showType == .groupout {
            self.view.addSubview(self.groupSelectControl)
            groupSelectControl.addTarget(self, action: #selector(groupSelectControlClick), for: .touchUpInside)
            groupSelectControl.addLineWithSide(.inBottom, color: TSColor.inconspicuous.disabled, thickness: 0.5, margin1: 0, margin2: 0)
            groupSelectControl.snp.makeConstraints { (make) in
                make.height.equalTo(self.groupSelectH)
                make.leading.trailing.equalTo(self.view)
                make.top.equalTo(self.view).offset(0)
            }
        }
        // 3. titleInputView
        let lrMargin: Float = 15
        let font = UIFont.systemFont(ofSize: 15)
        let titleInputView = TSOriginalCenterOneInputView(viewWidth: ScreenWidth - CGFloat(lrMargin) * 2.0, font: font, maxLine: 2, showTextMinCount: 15, maxTextCount: self.titleMaxLen, lrMargin: CGFloat(5), tbMargin: (self.titleMinH - font.lineHeight) / 2.0)
        self.view.addSubview(titleInputView)
        titleInputView.placeHolder = "占位符_请输入资讯标题".localized
        titleInputView.delegate = self
        titleInputView.snp.makeConstraints { (make) in
            make.leading.equalTo(self.view).offset(lrMargin)
            make.trailing.equalTo(self.view).offset(-lrMargin)
            make.height.equalTo(titleMinH)
            if self.showType == .groupout {
                make.top.equalTo(self.groupSelectControl.snp.bottom)
            } else {
                make.top.equalTo(self.view)
            }
        }
        titleInputView.addLineWithSide(.inBottom, color: UIColor(hex: 0xdedede), thickness: 0.5, margin1: 0, margin2: 0)
        self.titleInputView = titleInputView
        // 4. editorView
        editorView = TSWebEidtor(userContentController: self)
        self.view.addSubview(editorView)
        editorView.navigationDelegate = self
        editorView.scrollView.delegate = self
        editorView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(0)
            make.top.equalTo(titleInputView.snp.bottom).offset(0)
        }
        // 5. toolbar - 该工具栏需要进行再度改造，以适应同步至动态
        let toolbar = TSEditorToolBar(showSetting: false)// 测试人员说帖子发布不需要设置按钮 (TSAppConfig.share.launchInfo?.anonymousStatus)!
        self.view.addSubview(toolbar)
        toolbar.delegate = self
        toolbar.inputEnable = false
        toolbar.topShowView = self.syncMomentView
        toolbar.topViewVisibility = self.couldSyncMoment
        toolbar.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(toolbar.currentHeight)
        }
        self.editorToolbar = toolbar
    }
}

// MARK: - 数据处理与加载
extension TSPostWebEditorController {

    override func initialDataSource() {
        super.initialDataSource()
    }

    override func loadDataNoMarkdown() {
        switch self.editType {
        case .draft:
            // 草稿 加载圈子名
            if let groupName = self.editedDraft?.groupName {
                self.groupName = groupName
                self.groupSelectControl.detail = groupName
            }
            if let groupID = self.editedDraft?.groupId {
                self.groupId = groupID
            }
            // 加载圈子标题
            if let title = self.editedDraft?.title {
                self.titleInputView.text = title
            }
        default:
            break
        }
    }

    override func loadDataForMarkdownContent() {
        switch self.editType {
        case .draft:
            // 草稿 加载markdown
            guard let markdown = self.editedDraft?.markdown else {
                return
            }
            super.loadDataWithMarkdown(markdown)
        default:
            break
        }
    }
    /// 显示保存草稿提示弹窗
    override func showSaveDraftDialogView() -> Void {
        let alertVC = TSAlertController(title: nil, message: nil, style: .actionsheet)
        alertVC.addAction(TSAlertAction(title: "选择_放弃编辑".localized, style: .default, handler: { (action) in
            // 如果是草稿箱的修改需要保留原草稿中的图片，只删除其他的图片
            self.getImageIds { (ids) in
                if var allImageIDs = ids {
                    if self.editedDraft != nil {
                        for (index, nowID) in allImageIDs.enumerated() {
                            for draftID in self.draftImageIDs {
                                if draftID == nowID {
                                    allImageIDs.remove(at: index)
                                }
                            }
                        }
                    }
                    self.removeImageCaches(fileIds: allImageIDs) // 移除缓存图片
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
        }))
        alertVC.addAction(TSAlertAction(title: "选择_保存至草稿箱".localized, style: .default, handler: { (action) in
            self.saveDraft()
            _ = self.navigationController?.popViewController(animated: true)
        }))
        self.present(alertVC, animated: false, completion: nil)
    }
}

extension TSPostWebEditorController {
    override func couldNext(complete: @escaping(_ result: Bool) -> Void) {
        var couldFlag: Bool = true
        var markdown, content: String?
        var imageIds: [Int]?

        var didGetMarkdown = false
        var didGetContent = false

        guard let groupId = self.groupId, let title = self.titleInputView?.text  else {
            complete(false)
            return
        }
        let getContentComplete = {
            guard didGetContent, didGetMarkdown else {
                return
            }
            guard let summary = content?.ts_customMarkdownToStandard().ts_standardMarkdownToClearString(), let getMarkdown = markdown else {
                complete(false)
                return
            }
            let isExistImage = getMarkdown.ts_customMarkdownIsContainImageCode()
            // summary 和imageIds不能同时为空
            let summaryJugle1: NSString = summary as NSString
            let summary1 = summaryJugle1.trimmingCharacters(in: .whitespaces)
            if title.isEmpty || getMarkdown.isEmpty || (summary1.isEmpty && !isExistImage) {
                couldFlag = false
            }
            complete(couldFlag)
        }

        self.didGetMarkdownAction = {[unowned self] (data) in
            markdown = data
            self.didGetMarkdownAction = nil
            didGetMarkdown = true
            getContentComplete()
        }
        self.didGetContentAction = {[unowned self] (data) in
            content = data
            self.didGetContentAction = nil
            didGetContent = true
            getContentComplete()
        }

        editorView.getContentMarkdown()
        editorView.getContentText()
    }


    override func nextProcess() {
        self.view.endEditing(true)
        var markdown, content: String?
        var imageIds: [Int]?

        var didGetMarkdown = false
        var didGetContent = false
        guard let groupId = self.groupId, let title = self.titleInputView?.text else {
            return
        }
        getImageIds { (ids) in
            imageIds = ids
            let complete = {
                guard didGetContent, didGetMarkdown else {
                    return
                }
                guard let getMarkdown = markdown, let summary = content?.ts_customMarkdownToClearString() else {
                   return
                }
                let syncMoment = self.syncMomentView.syncMoment
                self.publishPost(groupId, title: title, markdown: getMarkdown, summary: summary, imageIds:imageIds ?? [], syncMoment: syncMoment)
            }

            self.didGetMarkdownAction = {[unowned self] (data) in
                markdown = data
                self.didGetMarkdownAction = nil
                didGetMarkdown = true
                complete()
            }
            self.didGetContentAction = {[unowned self] (data) in
                content = data
                self.didGetContentAction = nil
                didGetContent = true
                complete()
            }

            self.editorView.getContentMarkdown()
            self.editorView.getContentText()
        }
    }

}

extension TSPostWebEditorController {
    override func couldSaveDraft(complete: @escaping(_ could: Bool) -> Void) {
        var markdown, content: String?
        var didGetMarkdown = false
        var didGetContent = false
        var couldFlag: Bool = true

        //var groupFlag: Bool = false
        var titleFlag: Bool = false
        var markdownFlag: Bool = false
        var summaryFlag: Bool = false
        var imageFlag: Bool = false

        if let title = self.titleInputView?.text, !title.isEmpty {
            titleFlag = true
        }

        let getContetntComplete = {
            guard didGetContent, didGetMarkdown else {
                return
            }
            guard let getMarkdown = markdown, !getMarkdown.isEmpty, let getContent = content, !getContent.isEmpty else {
               complete(false)
               return
            }
            markdownFlag = true
            summaryFlag = true
            imageFlag = getMarkdown.ts_customMarkdownIsContainImageCode()

            if !titleFlag, !markdownFlag, !summaryFlag, !imageFlag {
                couldFlag = false
            }
            complete(couldFlag)
        }
        self.didGetMarkdownAction = {[unowned self] (data) in
            markdown = data
            self.didGetMarkdownAction = nil
            didGetMarkdown = true
            getContetntComplete()
        }
        self.didGetContentAction = {[unowned self] (data) in
            content = data
            self.didGetContentAction = nil
            didGetContent = true
            getContetntComplete()
        }

        self.editorView.getContentMarkdown()
        self.editorView.getContentText()
    }

    override func saveDraft() {
        var markdown, content: String?
        var didGetMarkdown = false
        var didGetContent = false
        
        
        let title = self.titleInputView?.text

        let getContetntComplete = {
            guard didGetContent, didGetMarkdown else {
                return
            }
            guard let getMarkdown = markdown, let getContent = content else {
                return
            }
            
            // 使用构造方法优化
            var draft = TSPostDraftModel()
            if let draftModel = self.editedDraft {
                draft = draftModel
            }
            draft.showType = self.showType
            draft.groupId = self.groupId
            if self.showType == .groupout {
                draft.groupName = self.groupSelectControl.detail
            } else {
                draft.groupName = self.groupName
            }
            draft.title = title
            draft.markdown = getMarkdown
            draft.summary = getContent.ts_customMarkdownToNormal()

            if self.couldSyncMoment {
                draft.isSyncMoment = self.syncMomentView.syncMoment
            }
            // 草稿保存
            switch self.editType {
            case .normal:
                TSDatabaseManager().draft.addPostDraft(draft)
            case .draft:
                TSDatabaseManager().draft.updatePostDraft(draft)
            case .update:
                break
            }
            // 保存草稿的回调
            self.saveDraftAction?(draft)
        }

        self.didGetMarkdownAction = {[unowned self] (data) in
            markdown = data
            self.didGetMarkdownAction = nil
            didGetMarkdown = true
            getContetntComplete()
        }
        self.didGetContentAction = {[unowned self] (data) in
            content = data
            self.didGetContentAction = nil
            didGetContent = true
            getContetntComplete()
        }

        self.editorView.getContentMarkdown()
        self.editorView.getContentText()
        
    }
}

// MARK: - 事件响应
extension TSPostWebEditorController {
    /// 导航栏 取消按钮 点击响应
    @objc override func leftItemClick() {
        super.leftItemClick()
    }

    /// 选择圈子响应
    @objc fileprivate func groupSelectControlClick() -> Void {
        let groupSelectVC = PostableGroupSelectController(fromAdd: self.fromAdd)
        groupSelectVC.selectedGroupAction = { (selectedGroup) in
            self.groupSelectControl.detail = selectedGroup.name
            self.groupId = selectedGroup.id
            self.editorToolbar.topViewVisibility = selectedGroup.allowFeed
        }
        self.navigationController?.pushViewController(groupSelectVC, animated: true)
    }

}

// MARK: - 响应扩展
extension TSPostWebEditorController {
    /// 发布帖子
    fileprivate func publishPost(_ groupId: Int, title: String, markdown: String, summary: String, imageIds: [Int], syncMoment: Bool) -> Void {
        let loadingAlert = TSIndicatorWindowTop(state: .loading, title: "发布中")
        loadingAlert.show()
        GroupNetworkManager.publishPost(in: groupId, title: title, body: markdown, summary: summary, images: imageIds, syncFeed: syncMoment) { (postListModel, msg, status) in
            loadingAlert.dismiss()
            var alert: TSIndicatorWindowTop = TSIndicatorWindowTop(state: .success, title: msg)
            guard status, let postListModel = postListModel else {
                alert = TSIndicatorWindowTop(state: .faild, title: msg)
                alert.show(timeInterval: TSIndicatorWindowTop.defaultShowTimeInterval, complete: nil)
                return
            }
            alert.show(timeInterval: TSIndicatorWindowTop.defaultShowTimeInterval, complete: nil)
            // 发布成功，缓存图片移除
            self.getImageIds { (ids) in
                if let ids = ids {
                    self.removeImageCaches(fileIds: ids)
                }
            }
            let postDetailVC = PostDetailController(groupId: postListModel.groupId, postId: postListModel.id, fromGroup: false)
            /// 进入详情页
            /// 非一级页面发布，用现在的导航pop，否则用tabbar来处理
            if let vcs = self.navigationController?.viewControllers, vcs.count > 2 {
                /// 非一级页面
                self.navigationController?.popViewController(animated: false)
                // self.navigationController?.pushViewController(postDetailVC, animated: true)
                // 这里保存groupid id 推到原页面再推
                UserDefaults.standard.set(["groupid":postListModel.groupId,"id":postListModel.id], forKey: "TSPostWebEditorControllerPostInfo")
                UserDefaults.standard.synchronize()
            } else {
                /// 在一级页面发布
                self.navigationController?.popViewController(animated: false)
                if let currentTC = TSRootViewController.share.currentShowViewcontroller as? TSHomeTabBarController, let nav = currentTC.selectedViewController as? UINavigationController {
                    nav.pushViewController(postDetailVC, animated: true)
                }
            }
        }
    }
}

// MARK: - Nofication
extension TSPostWebEditorController {

}

/// MARK: - WebEditor相关的js回调，用于子类重写
extension TSPostWebEditorController {

    override func editorContentFocus() -> Void {
        super.editorContentFocus()

        UIView.animate(withDuration: 0.25, animations: {
            self.editorView.snp.updateConstraints({ (make) in
                let height: CGFloat = self.titleInputView.currentHeight + (self.showType == .groupout ? self.groupSelectH : 0)
                make.top.equalTo(self.titleInputView.snp.bottom).offset(-height)
            })
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    override func editorContentBlur() -> Void {
        super.editorContentBlur()

        UIView.animate(withDuration: 0.25, animations: {
            self.editorView.snp.updateConstraints({ (make) in
                make.top.equalTo(self.titleInputView.snp.bottom).offset(0)
            })
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

// MARK: - TSOriginalCenterOneInputViewProtocol
/// title输入框的回调
extension TSPostWebEditorController: TSOriginalCenterOneInputViewProtocol {

    func inputView(_ inputView: TSOriginalCenterOneInputView, didLoadedWith minHeight: CGFloat) {
        if minHeight > self.titleMinH {
            inputView.snp.updateConstraints({ (make) in
                make.height.equalTo(minHeight)
            })
        } else {
            inputView.snp.updateConstraints({ (make) in
                make.height.equalTo(self.titleMinH)
            })
        }
        self.view.layoutIfNeeded()
    }
    func inputView(_ inputView: TSOriginalCenterOneInputView, didTextValueChanged newText: String) {
    }
    func inputView(_ inputView: TSOriginalCenterOneInputView, didHeightChanged newHeight: CGFloat) {
        if newHeight > self.titleMinH {
            inputView.snp.updateConstraints({ (make) in
                make.height.equalTo(newHeight)
            })
        } else {
            inputView.snp.updateConstraints({ (make) in
                make.height.equalTo(self.titleMinH)
            })
        }
        self.view.layoutIfNeeded()
    }
}
