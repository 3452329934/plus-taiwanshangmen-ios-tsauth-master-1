//
//  NoticeReceiveInfoNetworkManager.swift
//  ThinkSNS +
//
//  Created by lip on 2017/9/14.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//
//  通知接收信息网络请求 (点赞/评论/待审核等)

import UIKit

class NoticeReceiveInfoNetworkManager {
    class func receiveLikeList(limit: Int = TSAppConfig.share.localInfo.limit, after: Int?, complete: @escaping ([ReceiveLikeModel]?, _ errorInfo: String?) -> Void) {
        var request = UserNetworkRequest().receiveLike
        request.urlPath = request.fullPathWith(replacers: [])
        var parameter: [String: Any] = ["limit": limit]
        if let after = after {
            parameter["page"] = after
        }
        parameter["type"] = "like"
        request.parameter = parameter

        var models: [ReceiveLikeModel]?
        var errorInfo: String?
        RequestNetworkData.share.text(request: request) { (networkResult) in
            switch networkResult {
            case .error(let error):
                if error == NetworkError.networkErrorFailing {
                    errorInfo = "提示信息_网络错误".localized
                } else {
                    errorInfo = "网络请求超时"
                }
            case .failure(let response):
                if let message = response.message {
                    errorInfo = message
                } else {
                    errorInfo = "提示信息_网络错误".localized
                }
            case .success(let response):
                /// 原始的评论类别数据
                guard let listData = response.model else {
                    complete([], nil)
                    return
                }
                // 失败的信息，只有有接口报错就把错误信息付值给他
                var comleteErrorInfo: String = ""
                var atMeFeeds: [TSReceiveCommentListModel] = []
                // 需要请求用户信息的全部ID
                var commentsUserIDs: [Int] = []
                // 请求的用户信息
                var commentsUserInfosDic: [Int : TSUserInfoModel] = [:]
                // 完善后的评论model ReceiveLikeModel(乱序)
                var completeModels: [ReceiveLikeModel] = []

                /// 解析评论Id
                var commentableIds: [Int] = []
                var atMeCommentIDs: [Int] = []

                // 动态
                var feedCommnetInfos: [TSCommentsSimpelModel] = []
                var feedCommnetFeedIDs: [Int] = []
                // 资讯
                var newsCommnetInfos: [TSCommentsSimpelModel] = []
                var newsCommnetInfoIDs: [Int] = []
                // 帖子
                var postCommentInfos: [TSCommentsSimpelModel] = []
                var postCommentPostIDs: [Int] = []
                // 问题
                var questionCommnetInfos: [TSCommentsSimpelModel] = []
                var questionCommnetQuestionIDs: [Int] = []
                // 回答
                var answerCommentInfos: [TSCommentsSimpelModel] = []
                var answerCommentAnswerIDs: [Int] = []

                for item in listData.receiveCommentList {
                    /// 原资源id
                    let commentSimple = TSCommentsSimpelModel()
                    commentSimple.userId = item.commentUserId
                    commentSimple.body = item.contents
                    commentSimple.type = item.sourceType
                    commentSimple.createDate = item.createDate
                    commentSimple.sourceID = item.sourceId
                    commentSimple.hasReplay = item.hasReplay
                    commentSimple.sortId = item.id

                    atMeCommentIDs.append(item.otherTypeSourceId)
                    if item.sourceType == "feeds" {
                        feedCommnetFeedIDs.append(item.sourceId)
                        feedCommnetInfos.append(commentSimple)
                    } else if item.sourceType == "news" {
                        newsCommnetInfoIDs.append(item.sourceId)
                        newsCommnetInfos.append(commentSimple)
                    } else if item.sourceType == "groups-post" {
                        postCommentPostIDs.append(item.sourceId)
                        postCommentInfos.append(commentSimple)
                    } else if item.sourceType == "questions" {
                        questionCommnetQuestionIDs.append(item.sourceId)
                        questionCommnetInfos.append(commentSimple)
                    } else if item.sourceType == "question-answers" {
                        answerCommentAnswerIDs.append(item.sourceId)
                        answerCommentInfos.append(commentSimple)
                    }
                    commentsUserIDs.append(item.commentUserId)
                }

                /// 请求评论数据
                let group = DispatchGroup()

                if feedCommnetFeedIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestFeedInfo(feedIDs: feedCommnetFeedIDs, complete: { (Infos, error) in
                        if error == nil {
                            var feedComments: [ReceiveLikeModel] = []
                            if let infos = Infos {
                                var didFindFeedInfo = false
                                for simpleCommentModel in feedCommnetInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveLikeModel(JSON: [:])
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .feed
                                            commentModel?.sortId = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.isVieo = false
                                            tempExten.content = info["feed_content"] as? String
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            if info["images"] != nil {
                                                let images = info["images"] as? Array<Dictionary<String, Any>>
                                                if (images?.count)! > 0 {
                                                    tempExten.coverId = images?[0]["file"] as? Int
                                                }
                                            }
                                            if let videoDic = info["video"] as? Dictionary<String, Any>, tempExten.coverId == nil {
                                                // 先判断是否是图片动态，然后尝试读取视频封面图
                                                tempExten.coverId = videoDic["cover_id"] as? Int
                                                tempExten.isVieo = true
                                            }
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            feedComments.append(commentModel!)
                                            didFindFeedInfo = true
                                            continue
                                        }
                                    }
                                    if didFindFeedInfo == false {
                                        ///动态已经被删除
                                        let commentModel = ReceiveLikeModel(JSON: [:])
                                        commentModel?.userId = simpleCommentModel.userId
                                        commentModel?.createDate = simpleCommentModel.createDate
                                        commentModel?.sourceType = .feed
                                        commentModel?.sortId = simpleCommentModel.sortId
                                        ///没有附属信息(原文内容极为已经删除)
                                        commentModel?.exten = nil
                                        feedComments.append(commentModel!)
                                    }
                                }
                            } else {
                                // 没有返回数据，说明对应的评论无效
                            }
                            if feedComments.isEmpty == false {
                                completeModels = completeModels + feedComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                // MARK: - 资讯评论
                if newsCommnetInfoIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestNewsInfo(IDs: newsCommnetInfoIDs, complete: { (Infos, error) in
                        if error == nil {
                            var newsComments: [ReceiveLikeModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in newsCommnetInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveLikeModel(JSON: [:])
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .news
                                            commentModel?.sortId = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.content = info["title"] as? String
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            if info["images"] != nil {
                                                let images = info["images"] as? Dictionary<String, Any>
                                                if images != nil {
                                                    tempExten.coverId = images?["id"] as? Int
                                                }
                                            }
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            newsComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if newsComments.isEmpty == false {
                                completeModels = completeModels + newsComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                // MARK: 帖子评论
                if postCommentPostIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestPostInfo(IDs: postCommentPostIDs, complete: { (Infos, error) in
                        if error == nil {
                            var postComments: [ReceiveLikeModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in postCommentInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveLikeModel(JSON: [:])
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .group
                                            commentModel?.sortId = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.content = info["title"] as? String
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            if info["images"] != nil {
                                                let images = info["images"] as? Array<Dictionary<String, Any>>
                                                if (images?.count)! > 0 {
                                                    tempExten.coverId = images?[0]["id"] as? Int
                                                }
                                            }
                                            tempExten.groupId = info["group_id"] as? Int
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            postComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if postComments.isEmpty == false {
                                completeModels = completeModels + postComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                // MARK: - 问题评论
                if questionCommnetQuestionIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestQuestionInfo(IDs: questionCommnetQuestionIDs, complete: { (Infos, error) in
                        if error == nil {
                            var questionComments: [ReceiveLikeModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in questionCommnetInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveLikeModel(JSON: [:])
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .question
                                            commentModel?.sortId = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            let question = info["question"] as? Dictionary<String, Any>
                                            let content = question!["subject"] as? String
                                            tempExten.content = content
                                            tempExten.coverId = content?.ts_getCustomMarkdownImageId().first
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            questionComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if questionComments.isEmpty == false {
                                completeModels = completeModels + questionComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                // MARK: - 回答评论
                if answerCommentAnswerIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestAnswerInfo(IDs: answerCommentAnswerIDs, complete: { (Infos, error) in
                        if error == nil {
                            var answerComments: [ReceiveLikeModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in answerCommentInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveLikeModel(JSON: [:])
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .answers
                                            commentModel?.sortId = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            let content = info["body"] as? String
                                            tempExten.coverId = content?.ts_getCustomMarkdownImageId().first
                                            tempExten.content = content?.ts_customMarkdownToNormal()
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            answerComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if answerComments.isEmpty == false {
                                completeModels = completeModels + answerComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                /// 所有都请求完毕
                group.notify(queue: .main) {
                    if commentsUserIDs.isEmpty {
                        complete([], nil)
                        return
                    }
                    /// 最后请求一遍用户信息，更新到model里边去
                    NoticeReceiveInfoNetworkManager.requestUserInfo(userIds: commentsUserIDs, complete: { (userInfos, error) in
                        if error != nil {
                            complete(nil, error)
                            return
                        }
                        if let userInfos = userInfos, userInfos.isEmpty == false {
                            // 把数组转换为字典
                            for userInfo in userInfos {
                                commentsUserInfosDic[userInfo.userIdentity] = userInfo
                            }
                        } else {
                            complete([], nil)
                            return
                        }

                        // 需要先判断一下是否有请求失败的，如果有一个失败了，就提示错误
                        if comleteErrorInfo.isEmpty == true {
                            var enAbleComments: [ReceiveLikeModel] = []
                            for commentModel in completeModels {
                                let userInfo = commentsUserInfosDic[commentModel.userId]
                                if userInfo != nil {
                                    commentModel.userInfo = userInfo
                                    enAbleComments.append(commentModel)
                                }
                            }
                            /// 恢复消息的排序
                            var commentsLists: [ReceiveLikeModel] = []
                            for item in listData.receiveCommentList {
                                for comment in enAbleComments {
                                    if comment.sortId == item.id {
                                        commentsLists.append(comment)
                                    }
                                }
                            }
                            complete(commentsLists, nil)
                        } else {
                            complete(nil, comleteErrorInfo)
                        }
                    })
                }
            }
        }
    }

    class func receiveCommentList(limit: Int = TSAppConfig.share.localInfo.limit, after: Int?, complete: @escaping ([ReceiveCommentModel]?, _ originModels: [TSReceiveCommentListModel]?, _ errorInfo: String?) -> Void) {
        var request = UserNetworkRequest().receiveComment
        request.urlPath = request.fullPathWith(replacers: [])
        var parameter: [String: Any] = ["limit": limit]
        if let after = after {
            parameter["page"] = after
        }
        parameter["type"] = "comment"
        request.parameter = parameter

        var models: [ReceiveCommentModel]?
        var errorInfo: String?
        RequestNetworkData.share.text(request: request) { (networkResult) in
            switch networkResult {
            case .error(let error):
                if error == NetworkError.networkErrorFailing {
                    errorInfo = "提示信息_网络错误".localized
                } else {
                    errorInfo = "网络请求超时"
                }
            case .failure(let response):
                if let message = response.message {
                    errorInfo = message
                } else {
                    errorInfo = "提示信息_网络错误".localized
                }
            case .success(let response):
                /// 原始的评论类别数据
                guard let listData = response.model else {
                    complete([], [], nil)
                    return
                }
                // 失败的信息，只有有接口报错就把错误信息付值给他
                var comleteErrorInfo: String = ""
                var atMeFeeds: [TSReceiveCommentListModel] = []
                // 需要请求用户信息的全部ID
                var commentsUserIDs: [Int] = []
                // 请求的用户信息
                var commentsUserInfosDic: [Int : TSUserInfoModel] = [:]
                // 完善后的评论model ReceiveCommentModel(乱序)
                var completeModels: [ReceiveCommentModel] = []

                /// 解析评论Id
                var commentableIds: [Int] = []
                var atMeCommentIDs: [Int] = []

                // 动态
                var feedCommnetInfos: [TSCommentsSimpelModel] = []
                var feedCommnetFeedIDs: [Int] = []
                // 资讯
                var newsCommnetInfos: [TSCommentsSimpelModel] = []
                var newsCommnetInfoIDs: [Int] = []
                // 帖子
                var postCommentInfos: [TSCommentsSimpelModel] = []
                var postCommentPostIDs: [Int] = []
                // 问题
                var questionCommnetInfos: [TSCommentsSimpelModel] = []
                var questionCommnetQuestionIDs: [Int] = []
                // 回答
                var answerCommentInfos: [TSCommentsSimpelModel] = []
                var answerCommentAnswerIDs: [Int] = []
                // 音乐专辑
                var musicCommentInfos: [TSCommentsSimpelModel] = []
                var musicCommentAnswerIDs: [Int] = []
                // 音乐详情
                var musicDetailCommentInfos: [TSCommentsSimpelModel] = []
                var musicDetailCommentAnswerIDs: [Int] = []

                for item in listData.receiveCommentList {
                    /// 原资源id
                    debugPrint("type =  \(item.otherTypeSourceType)")
                    let commentSimple = TSCommentsSimpelModel()
                    commentSimple.userId = item.commentUserId
                    commentSimple.body = item.contents
                    commentSimple.type = item.otherTypeSourceType
                    commentSimple.createDate = item.createDate
                    commentSimple.sourceID = item.otherTypeSourceId
                    commentSimple.hasReplay = item.hasReplay
                    commentSimple.sortId = item.id

                    atMeCommentIDs.append(item.otherTypeSourceId)
                    if item.otherTypeSourceType == "feeds" {
                        feedCommnetFeedIDs.append(item.otherTypeSourceId)
                        feedCommnetInfos.append(commentSimple)
                    } else if item.otherTypeSourceType == "news" {
                        newsCommnetInfoIDs.append(item.otherTypeSourceId)
                        newsCommnetInfos.append(commentSimple)
                        //group-posts
                    } else if item.otherTypeSourceType == "group-posts" {
                        postCommentPostIDs.append(item.otherTypeSourceId)
                        postCommentInfos.append(commentSimple)
                    } else if item.otherTypeSourceType == "questions" {
                        questionCommnetQuestionIDs.append(item.otherTypeSourceId)
                        questionCommnetInfos.append(commentSimple)
                    } else if item.otherTypeSourceType == "question-answers" {
                        answerCommentAnswerIDs.append(item.otherTypeSourceId)
                        answerCommentInfos.append(commentSimple)
                    } else if item.otherTypeSourceType ==  "music_specials" {
                        musicCommentAnswerIDs.append(item.otherTypeSourceId)
                        musicCommentInfos.append(commentSimple)
                    } else if item.otherTypeSourceType ==  "musics" {
                        musicDetailCommentAnswerIDs.append(item.otherTypeSourceId)
                        musicDetailCommentInfos.append(commentSimple)
                    }
                    commentsUserIDs.append(item.commentUserId)
                }
                let origalModels = listData.receiveCommentList

                let group = DispatchGroup()

                if feedCommnetFeedIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestFeedInfo(feedIDs: feedCommnetFeedIDs, complete: { (Infos, error) in
                        if error == nil {
                            var feedComments: [ReceiveCommentModel] = []
                            if let infos = Infos {
                                var didFindFeedInfo = false
                                for simpleCommentModel in feedCommnetInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveCommentModel(JSON: [:])
                                            commentModel?.id = simpleCommentModel.id
                                            commentModel?.content = simpleCommentModel.body
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.targetUserId = simpleCommentModel.targetUserID
                                            commentModel?.replyUserId = 0
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .feed
                                            commentModel?.hasReplay = simpleCommentModel.hasReplay
                                            commentModel?.sortID = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.isVieo = false
                                            tempExten.content = info["feed_content"] as? String
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            if info["images"] != nil {
                                                let images = info["images"] as? Array<Dictionary<String, Any>>
                                                if (images?.count)! > 0 {
                                                    tempExten.coverId = images?[0]["file"] as? Int
                                                }
                                            }
                                            if let videoDic = info["video"] as? Dictionary<String, Any>, tempExten.coverId == nil {
                                                // 先判断是否是图片动态，然后尝试读取视频封面图
                                                tempExten.coverId = videoDic["cover_id"] as? Int
                                                tempExten.isVieo = true
                                            }
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            feedComments.append(commentModel!)
                                            didFindFeedInfo = true
                                            continue
                                        }
                                    }
                                    if didFindFeedInfo == false {
                                        ///动态已经被删除
                                        let commentModel = ReceiveCommentModel(JSON: [:])
                                        commentModel?.id = simpleCommentModel.id
                                        commentModel?.content = simpleCommentModel.body
                                        commentModel?.userId = simpleCommentModel.userId
                                        commentModel?.targetUserId = simpleCommentModel.targetUserID
                                        commentModel?.replyUserId = 0
                                        commentModel?.createDate = simpleCommentModel.createDate
                                        commentModel?.sourceType = .feed
                                        commentModel?.hasReplay = simpleCommentModel.hasReplay
                                        commentModel?.sortID = simpleCommentModel.sortId
                                        ///没有附属信息(原文内容极为已经删除)
                                        commentModel?.exten = nil
                                        feedComments.append(commentModel!)
                                    }
                                }
                                /// 遍历一下动态类型的消息
                                /// 这是动态组装的一个评论model，没有回复内容，需要UI处理一下兼容
                                /// 所以UI上显示的评论的人实际上是动态的人信息
                                /// 评论的ID其实是没有的，所以也不要有快速回复的弹窗
                                for atMeModel in atMeFeeds {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == atMeModel.otherTypeSourceId {
                                            let commentModel = ReceiveCommentModel(JSON: [:])
                                            commentModel?.id = atMeModel.otherTypeSourceId
                                            commentModel?.isAtContent = true
                                            commentModel?.content = ""
                                            commentModel?.userId = (info["user_id"] as! NSNumber) as! Int
                                            //commentModel?.targetUserId = atMeModel.userId
                                            commentModel?.replyUserId = 0
                                            //commentModel?.createDate = atMeModel.createDate
                                            commentModel?.sourceType = .feed
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.targetId = atMeModel.otherTypeSourceId
                                            tempExten.isVieo = false
                                            tempExten.content = info["feed_content"] as? String
                                            if let images = info["images"] as? Array<Dictionary<String, Any>> {
                                                if images.count > 0 {
                                                    tempExten.coverId = images[0]["id"] as? Int
                                                }
                                            }
                                            if let video = info["video"] as? Dictionary<String, Any> {
                                                tempExten.coverId = video["cover_id"] as? Int
                                                tempExten.isVieo = true
                                            }
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,用户ID就是该动态的用户信息
                                            commentsUserIDs.append((commentModel?.userId)!)
                                            feedComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据，说明对应的评论无效
                            }
                            if feedComments.isEmpty == false {
                                completeModels = completeModels + feedComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                // MARK: - 资讯评论
                if newsCommnetInfoIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestNewsInfo(IDs: newsCommnetInfoIDs, complete: { (Infos, error) in
                        if error == nil {
                            var newsComments: [ReceiveCommentModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in newsCommnetInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveCommentModel(JSON: [:])
                                            commentModel?.id = simpleCommentModel.id
                                            commentModel?.content = simpleCommentModel.body
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.targetUserId = simpleCommentModel.targetUserID
                                            commentModel?.replyUserId = 0
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .news
                                            commentModel?.hasReplay = simpleCommentModel.hasReplay
                                            commentModel?.sortID = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.content = info["title"] as? String
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            if info["images"] != nil {
                                                let images = info["images"] as? Array<Dictionary<String, Any>>
                                                if images?.count ?? 0 > 0 {
                                                    tempExten.coverId = images?[0]["id"] as? Int
                                                }
                                            }
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            newsComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if newsComments.isEmpty == false {
                                completeModels = completeModels + newsComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                // MARK: 帖子评论
                if postCommentPostIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestPostInfo(IDs: postCommentPostIDs, complete: { (Infos, error) in
                        if error == nil {
                            var postComments: [ReceiveCommentModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in postCommentInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveCommentModel(JSON: [:])
                                            commentModel?.id = simpleCommentModel.id
                                            commentModel?.content = simpleCommentModel.body
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.targetUserId = simpleCommentModel.targetUserID
                                            commentModel?.replyUserId = 0
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .group
                                            commentModel?.hasReplay = simpleCommentModel.hasReplay
                                            commentModel?.sortID = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.content = info["title"] as? String
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            if info["images"] != nil {
                                                let images = info["images"] as? Array<Dictionary<String, Any>>
                                                if (images?.count)! > 0 {
                                                    tempExten.coverId = images?[0]["id"] as? Int
                                                }
                                            }
                                            tempExten.groupId = info["group_id"] as? Int
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            postComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if postComments.isEmpty == false {
                                completeModels = completeModels + postComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                // MARK: - 问题评论
                if questionCommnetQuestionIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestQuestionInfo(IDs: questionCommnetQuestionIDs, complete: { (Infos, error) in
                        if error == nil {
                            var questionComments: [ReceiveCommentModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in questionCommnetInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveCommentModel(JSON: [:])
                                            commentModel?.id = simpleCommentModel.id
                                            commentModel?.content = simpleCommentModel.body
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.targetUserId = simpleCommentModel.targetUserID
                                            commentModel?.replyUserId = 0
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .question
                                            commentModel?.hasReplay = simpleCommentModel.hasReplay
                                            commentModel?.sortID = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            let content = info["subject"] as? String
                                            tempExten.content = content
                                            tempExten.coverId = content?.ts_getCustomMarkdownImageId().first
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            questionComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if questionComments.isEmpty == false {
                                completeModels = completeModels + questionComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                // MARK: - 回答评论
                if answerCommentAnswerIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestAnswerInfo(IDs: answerCommentAnswerIDs, complete: { (Infos, error) in
                        if error == nil {
                            var answerComments: [ReceiveCommentModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in answerCommentInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveCommentModel(JSON: [:])
                                            commentModel?.id = simpleCommentModel.id
                                            commentModel?.content = simpleCommentModel.body
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.targetUserId = simpleCommentModel.targetUserID
                                            commentModel?.replyUserId = 0
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .answers
                                            commentModel?.hasReplay = simpleCommentModel.hasReplay
                                            commentModel?.sortID = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            let question = info["question"] as? Dictionary<String, Any>
                                            let content = question!["subject"] as? String
                                            tempExten.coverId = content?.ts_getCustomMarkdownImageId().first
                                            tempExten.content = content?.ts_customMarkdownToNormal()
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            answerComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if answerComments.isEmpty == false {
                                completeModels = completeModels + answerComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                //音乐评论
                if musicCommentAnswerIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestMusicInfo(IDs: musicCommentAnswerIDs, complete: { (Infos, error) in
                        if error == nil {
                            var newsComments: [ReceiveCommentModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in musicCommentInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveCommentModel(JSON: [:])
                                            commentModel?.id = simpleCommentModel.id
                                            commentModel?.content = simpleCommentModel.body
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.targetUserId = simpleCommentModel.targetUserID
                                            commentModel?.replyUserId = 0
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .musicAlbum
                                            commentModel?.hasReplay = simpleCommentModel.hasReplay
                                            commentModel?.sortID = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.content = info["title"] as? String
                                            tempExten.targetId = simpleCommentModel.sourceID

                                            if info["images"] != nil {
                                                let images = info["images"] as? Array<Dictionary<String, Any>>
                                                if images?.count ?? 0 > 0 {
                                                    tempExten.coverId = images?[0]["id"] as? Int
                                                }
                                            }
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            newsComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if newsComments.isEmpty == false {
                                completeModels = completeModels + newsComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }
                //音乐详情评论
                if musicDetailCommentAnswerIDs.isEmpty == false {
                    group.enter()
                    NoticeReceiveInfoNetworkManager.requestMusicDetailInfo(IDs: musicDetailCommentAnswerIDs, complete: { (Infos, error) in
                        if error == nil {
                            var newsComments: [ReceiveCommentModel] = []
                            if let infos = Infos {
                                for simpleCommentModel in musicDetailCommentInfos {
                                    for info in infos {
                                        if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                            let commentModel = ReceiveCommentModel(JSON: [:])
                                            commentModel?.id = simpleCommentModel.id
                                            commentModel?.content = simpleCommentModel.body
                                            commentModel?.userId = simpleCommentModel.userId
                                            commentModel?.targetUserId = simpleCommentModel.targetUserID
                                            commentModel?.replyUserId = 0
                                            commentModel?.createDate = simpleCommentModel.createDate
                                            commentModel?.sourceType = .song
                                            commentModel?.hasReplay = simpleCommentModel.hasReplay
                                            commentModel?.sortID = simpleCommentModel.sortId
                                            let tempExten = ReceiveExtenModel()
                                            tempExten.content = info["title"] as? String
                                            tempExten.targetId = simpleCommentModel.sourceID
                                            if info["images"] != nil {
                                                let images = info["images"] as? Array<Dictionary<String, Any>>
                                                if images?.count ?? 0 > 0 {
                                                    tempExten.coverId = images?[0]["id"] as? Int
                                                }
                                            }
                                            commentModel?.exten = tempExten
                                            // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                            newsComments.append(commentModel!)
                                            continue
                                        }
                                    }
                                }
                            } else {
                                // 没有返回数据
                            }
                            if newsComments.isEmpty == false {
                                completeModels = completeModels + newsComments
                            }
                        } else {
                            comleteErrorInfo = error!
                        }
                        group.leave()
                    })
                }

                /// 所有都请求完毕
                group.notify(queue: .main) {
                    if commentsUserIDs.isEmpty {
                        complete([], listData.receiveCommentList, nil)
                        return
                    }
                    /// 最后请求一遍用户信息，更新到model里边去
                    NoticeReceiveInfoNetworkManager.requestUserInfo(userIds: commentsUserIDs, complete: { (userInfos, error) in
                        if error != nil {
                            complete(nil, listData.receiveCommentList, error)
                            return
                        }
                        // 把数组转换为字典
                        if let userInfos = userInfos, userInfos.isEmpty == false {
                            // 把数组转换为字典
                            for userInfo in userInfos {
                                commentsUserInfosDic[userInfo.userIdentity] = userInfo
                            }
                        } else {
                            complete([], listData.receiveCommentList, nil)
                            return
                        }
                        // 需要先判断一下是否有请求失败的，如果有一个失败了，就提示错误
                        if comleteErrorInfo.isEmpty == true {
                            var enAbleComments: [ReceiveCommentModel] = []
                            for commentModel in completeModels {
                                let userInfo = commentsUserInfosDic[commentModel.userId]
                                if userInfo != nil {
                                    commentModel.user = userInfo
                                    enAbleComments.append(commentModel)
                                }
                            }
                            /// 恢复消息的排序
                            var commentsLists: [ReceiveCommentModel] = []
                            for item in origalModels {
                                for comment in enAbleComments {
                                    if comment.sortID == item.id {
                                        commentsLists.append(comment)
                                    }
                                }
                            }
                            complete(commentsLists, listData.receiveCommentList, nil)
                        } else {
                            complete(nil, listData.receiveCommentList, comleteErrorInfo)
                        }
                    })
                }
            }
        }
    }
    /*
     // 动态 feeds
     // 评论 comments
     // 资讯的评论 news
     // 圈子 groups（无at）
     // 帖子 groups-post
     // 问题的评论 questions
     // 回答的评论 question-answers
     // 话题 feed-topics
     */
    // MARK: - at我的
    class func receiveAtMeList(limit: Int = TSAppConfig.share.localInfo.limit, index: Int?, complete: @escaping ([ReceiveCommentModel]?, _ errorInfo: String?) -> Void) {
        NoticeReceiveInfoNetworkManager.requestAtMessageIDList(limit: limit, index: index) { (models, errorInfo) in
            /// 第一步：
            // 把messageIDModel分为动态和评论两大类
            if errorInfo == nil && models != nil {
                if (models?.count)! <= 0 {
                    complete([], "还没有人@了我")
                    return
                }
                // 用于最后还原整个列表数据
                let origalModels = models
                var atMeFeeds: [TSReceiveCommentListModel] = []
                var atMeComments: [TSReceiveCommentListModel] = []
                var atMeCommentIDs: [Int] = []
                // 需要请求用户信息的全部ID
                var commentsUserIDs: [Int] = []
                // 请求的用户信息
                var commentsUserInfosDic: [Int : TSUserInfoModel] = [:]
                // 完善后的评论model ReceiveCommentModel(乱序)
                var completeModels: [ReceiveCommentModel] = []
                // 失败的信息，只有有接口报错就把错误信息付值给他
                var comleteErrorInfo: String = ""
                for atmeModel in models! {
                    if atmeModel.sourceType == "feeds" {
                        atMeFeeds.append(atmeModel)
                    } else if atmeModel.sourceType == "comments" {
                        atMeComments.append(atmeModel)
                        /// 这个地方的resourceID才是评论的ID
                        /// 这个ID是消息的ID，用于排序的
                        atMeCommentIDs.append(atmeModel.sourceId)
                    }
                }
                /// 第二步：
                // 先通过评论id去拿评论的信息，然后通过评论信息进行分类，然后非类型去拿父级信息，如动态，资讯等
                NoticeReceiveInfoNetworkManager.requestCommentsInfo(commentIDs: atMeCommentIDs, complete: { (models, errorInfo) in
                    // 动态
                    var feedCommnetInfos: [TSCommentsSimpelModel] = []
                    var feedCommnetFeedIDs: [Int] = []
                    // 资讯
                    var newsCommnetInfos: [TSCommentsSimpelModel] = []
                    var newsCommnetInfoIDs: [Int] = []
                    // 帖子
                    var postCommentInfos: [TSCommentsSimpelModel] = []
                    var postCommentPostIDs: [Int] = []
                    // 问题
                    var questionCommnetInfos: [TSCommentsSimpelModel] = []
                    var questionCommnetQuestionIDs: [Int] = []
                    // 回答
                    var answerCommentInfos: [TSCommentsSimpelModel] = []
                    var answerCommentAnswerIDs: [Int] = []
                    // 音乐专辑
                    var musicCommentInfos: [TSCommentsSimpelModel] = []
                    var musicCommentAnswerIDs: [Int] = []
                    // 音乐详情
                    var musicDetailCommentInfos: [TSCommentsSimpelModel] = []
                    var musicDetailCommentAnswerIDs: [Int] = []
                    // 这里防止atMeCommentIDs为空时也会请求一堆数据回来
                    if atMeCommentIDs.count > 0 {
                        for model in models! {
                            for listModel in origalModels! {
                                if model.id == listModel.sourceId {
                                    model.sortId = listModel.id
                                }
                            }
                            if model.type == "feeds" {
                                feedCommnetInfos.append(model)
                                feedCommnetFeedIDs.append(model.sourceID)
                            } else if model.type == "news" {
                                newsCommnetInfos.append(model)
                                newsCommnetInfoIDs.append(model.sourceID)
                            } else if model.type == "groups-post" {
                                postCommentInfos.append(model)
                                postCommentPostIDs.append(model.sourceID)
                            } else if model.type == "questions" {
                                questionCommnetInfos.append(model)
                                questionCommnetQuestionIDs.append(model.sourceID)
                            } else if model.type == "question-answers" {
                                answerCommentInfos.append(model)
                                answerCommentAnswerIDs.append(model.sourceID)
                            } else if model.type ==  "music_specials" {
                                musicCommentAnswerIDs.append(model.sourceID)
                                musicCommentInfos.append(model)
                            } else if model.type ==  "musics" {
                                musicDetailCommentAnswerIDs.append(model.sourceID)
                                musicDetailCommentInfos.append(model)
                            }
                            commentsUserIDs.append(model.userId)
                        }
                    }

                    let group = DispatchGroup()
                    /// 单独请求
                    // 动态ID直接放到feedCommnetFeedIDs里边一起请求
                    for atMemodel in atMeFeeds {
                        feedCommnetFeedIDs.append(atMemodel.sourceId)
                    }

                    if feedCommnetFeedIDs.isEmpty == false {
                        group.enter()
                        NoticeReceiveInfoNetworkManager.requestFeedInfo(feedIDs: feedCommnetFeedIDs, complete: { (Infos, error) in
                            if error == nil {
                                var feedComments: [ReceiveCommentModel] = []
                                if let infos = Infos {
                                    for simpleCommentModel in feedCommnetInfos {
                                        for info in infos {
                                            if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                                let commentModel = ReceiveCommentModel(JSON: [:])
                                                commentModel?.id = simpleCommentModel.id
                                                commentModel?.content = simpleCommentModel.body
                                                commentModel?.userId = simpleCommentModel.userId
                                                commentModel?.targetUserId = simpleCommentModel.targetUserID
                                                commentModel?.replyUserId = 0
                                                commentModel?.createDate = simpleCommentModel.createDate
                                                commentModel?.sourceType = .feed
                                                commentModel?.sortID = simpleCommentModel.sortId
                                                let tempExten = ReceiveExtenModel()
                                                tempExten.isVieo = false
                                                tempExten.content = info["feed_content"] as? String
                                                tempExten.targetId = simpleCommentModel.sourceID
                                                if info["images"] != nil {
                                                    let images = info["images"] as? Array<Dictionary<String, Any>>
                                                    if (images?.count)! > 0 {
                                                        tempExten.coverId = images?[0]["file"] as? Int
                                                    }
                                                }
                                                if let videoDic = info["video"] as? Dictionary<String, Any>, tempExten.coverId == nil {
                                                    // 先判断是否是图片动态，然后尝试读取视频封面图
                                                    tempExten.coverId = videoDic["cover_id"] as? Int
                                                    tempExten.isVieo = true
                                                }
                                                commentModel?.exten = tempExten
                                                // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                                feedComments.append(commentModel!)
                                                continue
                                            }
                                        }
                                    }
                                    /// 遍历一下动态类型的消息
                                    /// 这是动态组装的一个评论model，没有回复内容，需要UI处理一下兼容
                                    /// 所以UI上显示的评论的人实际上是动态的人信息
                                    /// 评论的ID其实是没有的，所以也不要有快速回复的弹窗
                                    for atMeModel in atMeFeeds {
                                        for info in infos {
                                            if Int(info["id"] as! NSNumber) == atMeModel.sourceId {
                                                let commentModel = ReceiveCommentModel(JSON: [:])
                                                commentModel?.id = atMeModel.sourceId
                                                commentModel?.isAtContent = true
                                                commentModel?.content = atMeModel.contents
                                                commentModel?.userId = atMeModel.commentUserId
                                                commentModel?.replyUserId = 0
                                                commentModel?.createDate = atMeModel.createDate
                                                commentModel?.sourceType = .feed
                                                commentModel?.sortID = atMeModel.id
                                                let tempExten = ReceiveExtenModel()
                                                tempExten.targetId = atMeModel.sourceId
                                                tempExten.isVieo = false
                                                tempExten.content = info["feed_content"] as? String
                                                if let images = info["images"] as? Array<Dictionary<String, Any>> {
                                                    if images.count > 0 {
                                                        tempExten.coverId = images[0]["id"] as? Int
                                                    }
                                                }
                                                if let video = info["video"] as? Dictionary<String, Any> {
                                                    tempExten.coverId = video["cover_id"] as? Int
                                                    tempExten.isVieo = true
                                                }
                                                commentModel?.exten = tempExten
                                                // 发评论用户的信息最后再统一更新,用户ID就是该动态的用户信息
                                                commentsUserIDs.append((commentModel?.userId)!)
                                                feedComments.append(commentModel!)
                                                continue
                                            }
                                        }
                                    }
                                } else {
                                    // 没有返回数据，说明对应的评论无效
                                }
                                if feedComments.isEmpty == false {
                                    completeModels = completeModels + feedComments
                                }
                            } else {
                                comleteErrorInfo = error!
                            }
                            group.leave()
                        })
                    }
                    // MARK: - 资讯评论
                    if newsCommnetInfoIDs.isEmpty == false {
                        group.enter()
                        NoticeReceiveInfoNetworkManager.requestNewsInfo(IDs: newsCommnetInfoIDs, complete: { (Infos, error) in
                            if error == nil {
                                var newsComments: [ReceiveCommentModel] = []
                                if let infos = Infos {
                                    for simpleCommentModel in newsCommnetInfos {
                                        for info in infos {
                                            if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                                let commentModel = ReceiveCommentModel(JSON: [:])
                                                commentModel?.id = simpleCommentModel.id
                                                commentModel?.content = simpleCommentModel.body
                                                commentModel?.userId = simpleCommentModel.userId
                                                commentModel?.targetUserId = simpleCommentModel.targetUserID
                                                commentModel?.replyUserId = 0
                                                commentModel?.createDate = simpleCommentModel.createDate
                                                commentModel?.sourceType = .news
                                                commentModel?.sortID = simpleCommentModel.sortId
                                                let tempExten = ReceiveExtenModel()
                                                tempExten.content = info["title"] as? String
                                                tempExten.targetId = simpleCommentModel.sourceID
                                                if info["images"] != nil {
                                                    let images = info["images"] as? Array<Dictionary<String, Any>>
                                                    if images?.count ?? 0 > 0 {
                                                        tempExten.coverId = images?[0]["id"] as? Int
                                                    }
                                                }
                                                commentModel?.exten = tempExten
                                                // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                                newsComments.append(commentModel!)
                                                continue
                                            }
                                        }
                                    }
                                } else {
                                    // 没有返回数据
                                }
                                if newsComments.isEmpty == false {
                                    completeModels = completeModels + newsComments
                                }
                            } else {
                                comleteErrorInfo = error!
                            }
                            group.leave()
                        })
                    }
                    // MARK: 帖子评论
                    if postCommentPostIDs.isEmpty == false {
                        group.enter()
                        NoticeReceiveInfoNetworkManager.requestPostInfo(IDs: postCommentPostIDs, complete: { (Infos, error) in
                            if error == nil {
                                var postComments: [ReceiveCommentModel] = []
                                if let infos = Infos {
                                    for simpleCommentModel in postCommentInfos {
                                        for info in infos {
                                            if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                                let commentModel = ReceiveCommentModel(JSON: [:])
                                                commentModel?.id = simpleCommentModel.id
                                                commentModel?.content = simpleCommentModel.body
                                                commentModel?.userId = simpleCommentModel.userId
                                                commentModel?.targetUserId = simpleCommentModel.targetUserID
                                                commentModel?.replyUserId = 0
                                                commentModel?.createDate = simpleCommentModel.createDate
                                                commentModel?.sourceType = .group
                                                commentModel?.sortID = simpleCommentModel.sortId
                                                let tempExten = ReceiveExtenModel()
                                                tempExten.content = info["title"] as? String
                                                tempExten.targetId = simpleCommentModel.sourceID
                                                if info["images"] != nil {
                                                    let images = info["images"] as? Array<Dictionary<String, Any>>
                                                    if (images?.count)! > 0 {
                                                        tempExten.coverId = images?[0]["id"] as? Int
                                                    }
                                                }
                                                tempExten.groupId = info["group_id"] as? Int
                                                commentModel?.exten = tempExten
                                                // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                                postComments.append(commentModel!)
                                                continue
                                            }
                                        }
                                    }
                                } else {
                                    // 没有返回数据
                                }
                                if postComments.isEmpty == false {
                                    completeModels = completeModels + postComments
                                }
                            } else {
                                comleteErrorInfo = error!
                            }
                            group.leave()
                        })
                    }
                    // MARK: - 问题评论
                    if questionCommnetQuestionIDs.isEmpty == false {
                        group.enter()
                        NoticeReceiveInfoNetworkManager.requestQuestionInfo(IDs: questionCommnetQuestionIDs, complete: { (Infos, error) in
                            if error == nil {
                                var questionComments: [ReceiveCommentModel] = []
                                if let infos = Infos {
                                    for simpleCommentModel in questionCommnetInfos {
                                        for info in infos {
                                            if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                                let commentModel = ReceiveCommentModel(JSON: [:])
                                                commentModel?.id = simpleCommentModel.id
                                                commentModel?.content = simpleCommentModel.body
                                                commentModel?.userId = simpleCommentModel.userId
                                                commentModel?.targetUserId = simpleCommentModel.targetUserID
                                                commentModel?.replyUserId = 0
                                                commentModel?.createDate = simpleCommentModel.createDate
                                                commentModel?.sourceType = .question
                                                commentModel?.sortID = simpleCommentModel.sortId
                                                let tempExten = ReceiveExtenModel()
                                                tempExten.targetId = simpleCommentModel.sourceID
                                                let content = info["subject"] as? String
                                                tempExten.content = content
                                                tempExten.coverId = content?.ts_getCustomMarkdownImageId().first
                                                commentModel?.exten = tempExten
                                                // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                                questionComments.append(commentModel!)
                                                continue
                                            }
                                        }
                                    }
                                } else {
                                    // 没有返回数据
                                }
                                if questionComments.isEmpty == false {
                                    completeModels = completeModels + questionComments
                                }
                            } else {
                                comleteErrorInfo = error!
                            }
                            group.leave()
                        })
                    }
                    // MARK: - 回答评论
                    if answerCommentAnswerIDs.isEmpty == false {
                        group.enter()
                        NoticeReceiveInfoNetworkManager.requestAnswerInfo(IDs: answerCommentAnswerIDs, complete: { (Infos, error) in
                            if error == nil {
                                var answerComments: [ReceiveCommentModel] = []
                                if let infos = Infos {
                                    for simpleCommentModel in answerCommentInfos {
                                        for info in infos {
                                            if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                                let commentModel = ReceiveCommentModel(JSON: [:])
                                                commentModel?.id = simpleCommentModel.id
                                                commentModel?.content = simpleCommentModel.body
                                                commentModel?.userId = simpleCommentModel.userId
                                                commentModel?.targetUserId = simpleCommentModel.targetUserID
                                                commentModel?.replyUserId = 0
                                                commentModel?.createDate = simpleCommentModel.createDate
                                                commentModel?.sourceType = .answers
                                                commentModel?.sortID = simpleCommentModel.sortId
                                                let tempExten = ReceiveExtenModel()
                                                tempExten.targetId = simpleCommentModel.sourceID
                                                let question = info["question"] as? Dictionary<String, Any>
                                                let content = question!["subject"] as? String
                                                tempExten.coverId = content?.ts_getCustomMarkdownImageId().first
                                                tempExten.content = content?.ts_customMarkdownToNormal()
                                                commentModel?.exten = tempExten
                                                // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                                answerComments.append(commentModel!)
                                                continue
                                            }
                                        }
                                    }
                                } else {
                                    // 没有返回数据
                                }
                                if answerComments.isEmpty == false {
                                    completeModels = completeModels + answerComments
                                }
                            } else {
                                comleteErrorInfo = error!
                            }
                            group.leave()
                        })
                    }
                    // MARK: - 音乐专辑评论
                    if musicCommentAnswerIDs.isEmpty == false {
                        group.enter()
                        NoticeReceiveInfoNetworkManager.requestMusicInfo(IDs: musicCommentAnswerIDs, complete: { (Infos, error) in
                            if error == nil {
                                var answerComments: [ReceiveCommentModel] = []
                                if let infos = Infos {
                                    for simpleCommentModel in musicCommentInfos {
                                        for info in infos {
                                            if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                                let commentModel = ReceiveCommentModel(JSON: [:])
                                                commentModel?.id = simpleCommentModel.id
                                                commentModel?.content = simpleCommentModel.body
                                                commentModel?.userId = simpleCommentModel.userId
                                                commentModel?.targetUserId = simpleCommentModel.targetUserID
                                                commentModel?.replyUserId = 0
                                                commentModel?.createDate = simpleCommentModel.createDate
                                                commentModel?.sourceType = .musicAlbum
                                                commentModel?.sortID = simpleCommentModel.sortId
                                                let tempExten = ReceiveExtenModel()
                                                tempExten.content = info["title"] as? String
                                                tempExten.targetId = simpleCommentModel.sourceID
                                                commentModel?.exten = tempExten
                                                // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                                answerComments.append(commentModel!)
                                                continue
                                            }
                                        }
                                    }
                                } else {
                                    // 没有返回数据
                                }
                                if answerComments.isEmpty == false {
                                    completeModels = completeModels + answerComments
                                }
                            } else {
                                comleteErrorInfo = error!
                            }
                            group.leave()
                        })
                    }
                    // MARK: - 音乐详情评论
                    if musicDetailCommentAnswerIDs.isEmpty == false {
                        group.enter()
                        NoticeReceiveInfoNetworkManager.requestMusicDetailInfo(IDs: musicDetailCommentAnswerIDs, complete: { (Infos, error) in
                            if error == nil {
                                var answerComments: [ReceiveCommentModel] = []
                                if let infos = Infos {
                                    for simpleCommentModel in musicDetailCommentInfos {
                                        for info in infos {
                                            if Int(info["id"] as! NSNumber) == simpleCommentModel.sourceID {
                                                let commentModel = ReceiveCommentModel(JSON: [:])
                                                commentModel?.id = simpleCommentModel.id
                                                commentModel?.content = simpleCommentModel.body
                                                commentModel?.userId = simpleCommentModel.userId
                                                commentModel?.targetUserId = simpleCommentModel.targetUserID
                                                commentModel?.replyUserId = 0
                                                commentModel?.createDate = simpleCommentModel.createDate
                                                commentModel?.sourceType = .song
                                                commentModel?.sortID = simpleCommentModel.sortId
                                                let tempExten = ReceiveExtenModel()
                                                tempExten.targetId = simpleCommentModel.sourceID
                                                tempExten.content = info["title"] as? String
                                                commentModel?.exten = tempExten
                                                // 发评论用户的信息最后再统一更新,ID已经在最外层拆分评论分组的时候处理了
                                                answerComments.append(commentModel!)
                                                continue
                                            }
                                        }
                                    }
                                } else {
                                    // 没有返回数据
                                }
                                if answerComments.isEmpty == false {
                                    completeModels = completeModels + answerComments
                                }
                            } else {
                                comleteErrorInfo = error!
                            }
                            group.leave()
                        })
                    }
                    /// 所有都请求完毕
                    group.notify(queue: .main) {
                        if commentsUserIDs.isEmpty {
                            complete([], nil)
                            return
                        }
                        /// 最后请求一遍用户信息，更新到model里边去
                        NoticeReceiveInfoNetworkManager.requestUserInfo(userIds: commentsUserIDs, complete: { (userInfos, error) in
                            if error != nil {
                                complete(nil, error)
                                return
                            }
                            // 把数组转换为字典
                            if let userInfos = userInfos, userInfos.isEmpty == false {
                                // 把数组转换为字典
                                for userInfo in userInfos {
                                    commentsUserInfosDic[userInfo.userIdentity] = userInfo
                                }
                            } else {
                                complete([], nil)
                                return
                            }
                            // 需要先判断一下是否有请求失败的，如果有一个失败了，就提示错误
                            if comleteErrorInfo.isEmpty == true {
                                var enAbleComments: [ReceiveCommentModel] = []
                                for commentModel in completeModels {
                                    let userInfo = commentsUserInfosDic[commentModel.userId]
                                    if userInfo != nil {
                                        commentModel.user = userInfo
                                        enAbleComments.append(commentModel)
                                    }
                                }
                                /// 恢复消息的排序
                                var commentsLists: [ReceiveCommentModel] = []
                                for atModel in origalModels! {
                                    for enAbleComment in enAbleComments {
                                        if enAbleComment.sortID == atModel.id {
                                            commentsLists.append(enAbleComment)
                                        }
                                    }
                                }
                                complete(commentsLists, nil)
                            } else {
                                complete(nil, comleteErrorInfo)
                            }
                        })
                    }
                })
            }
        }
    }
    /// 获取消息ID列表
    fileprivate class func requestAtMessageIDList(limit: Int = TSAppConfig.share.localInfo.limit, index: Int?, complete: @escaping ([TSReceiveCommentListModel]?, _ errorInfo: String?) -> Void) {
        var requst = Request<TSReceiveSourceModel>(method: .get, path: TSURLPathV2.Message.atMeIDList.rawValue, replacers: [])
        requst.urlPath = requst.fullPathWith(replacers: [])

        var parameter: [String: Any] = ["limit": limit]
        if let index = index {
            parameter["page"] = index
        }
        parameter["type"] = "at"

        requst.parameter = parameter
        var models: [TSReceiveCommentListModel]?
        var errorInfo: String?
        RequestNetworkData.share.text(request: requst) { (networkResult) in
            switch networkResult {
            case .error(let error):
                if error == NetworkError.networkErrorFailing {
                    errorInfo = "提示信息_网络错误".localized
                } else {
                    errorInfo = "网络请求超时"
                }
            case .failure(let response):
                if let message = response.message {
                    errorInfo = message
                } else {
                    errorInfo = "提示信息_网络错误".localized
                }
            case .success(let response):
                models = response.model?.receiveCommentList
            }
            complete(models, errorInfo)
        }
    }
    /// 获取评论的信息
    fileprivate class func requestCommentsInfo(commentIDs: [Int], complete: @escaping ([TSCommentsSimpelModel]?, _ errorInfo: String?) -> Void) {
        var requst = Request<TSCommentsSimpelModel>(method: .get, path: "comments", replacers: [])
        requst.urlPath = requst.fullPathWith(replacers: [])

        var parameter: [String: Any] = [:]
        var commentIDStr = ""
        for commentID in commentIDs {
            commentIDStr = commentIDStr.isEmpty ? String(commentID) : commentIDStr + "," +  String(commentID)
        }
        parameter["id"] = commentIDStr
        requst.parameter = parameter
        var models: [TSCommentsSimpelModel]?
        var errorInfo: String?
        RequestNetworkData.share.text(request: requst) { (networkResult) in
            switch networkResult {
            case .error(let error):
                if error == NetworkError.networkErrorFailing {
                    errorInfo = "提示信息_网络错误".localized
                } else {
                    errorInfo = "网络请求超时"
                }
            case .failure(let response):
                if let message = response.message {
                    errorInfo = message
                } else {
                    errorInfo = "提示信息_网络错误".localized
                }
            case .success(let response):
                models = response.models
            }
            complete(models, errorInfo)
        }
    }
    /// 获取动态信息
    fileprivate class func requestFeedInfo(feedIDs: [Int], complete: @escaping ([[String: Any]]?, _ errorInfo: String?) -> Void) {
        let requestPath = TSURLPathV2.path.rawValue + "feeds"
        var parameter: [String: Any] = [:]
        var feedIdStr = ""
        for feedIs in feedIDs {
            feedIdStr = feedIdStr.isEmpty ? String(feedIs) : feedIdStr + "," +  String(feedIs)
        }
        parameter["id"] = feedIdStr
        try! RequestNetworkData.share.textRequest(method: .get, path: requestPath, parameter: parameter, complete: { (networkResponse, result) in
            // 请求失败
            guard result else {
                complete([], nil)
                return
            }
            // 服务器数据异常
            guard let datas = networkResponse as? [String: Any] else {
                complete([], nil)
                return
            }
            complete(datas["feeds"] as! [[String : Any]], nil)
        })
    }
    /// 帖子详情
    fileprivate class func requestPostInfo(IDs: [Int], complete: @escaping ([[String: Any]]?, _ errorInfo: String?) -> Void) {
        let requestPath = TSURLPathV2.path.rawValue + "group/simple-posts"
        var parameter: [String: Any] = [:]
        var idStr = ""
        for idInt in IDs {
            idStr = idStr.isEmpty ? String(idInt) : idStr + "," +  String(idInt)
        }
        parameter["id"] = idStr
        try! RequestNetworkData.share.textRequest(method: .get, path: requestPath, parameter: parameter, complete: { (networkResponse, result) in
            // 请求失败
            guard result else {
                complete([], nil)
                return
            }
            // 服务器数据异常
            guard let datas = networkResponse as? [[String : Any]] else {
                complete([], nil)
                return
            }
            complete(datas, nil)
        })
    }
    /// 资讯信息
    fileprivate class func requestNewsInfo(IDs: [Int], complete: @escaping ([[String: Any]]?, _ errorInfo: String?) -> Void) {
        let requestPath = TSURLPathV2.path.rawValue + "news"
        var parameter: [String: Any] = [:]
        var idStr = ""
        for idInt in IDs {
            idStr = idStr.isEmpty ? String(idInt) : idStr + "," +  String(idInt)
        }
        parameter["id"] = idStr
        try! RequestNetworkData.share.textRequest(method: .get, path: requestPath, parameter: parameter, complete: { (networkResponse, result) in
            // 请求失败
            guard result else {
                complete([], nil)
                return
            }
            // 服务器数据异常
            guard let datas = networkResponse as? [[String : Any]] else {
                complete([], nil)
                return
            }
            complete(datas, nil)
        })
    }
    /// 问题信息
    fileprivate class func requestQuestionInfo(IDs: [Int], complete: @escaping ([[String: Any]]?, _ errorInfo: String?) -> Void) {
        let requestPath = TSURLPathV2.path.rawValue + "questions"
        var parameter: [String: Any] = [:]
        var idStr = ""
        for idInt in IDs {
            idStr = idStr.isEmpty ? String(idInt) : idStr + "," +  String(idInt)
        }
        parameter["id"] = idStr
        try! RequestNetworkData.share.textRequest(method: .get, path: requestPath, parameter: parameter, complete: { (networkResponse, result) in
            // 请求失败
            guard result else {
                complete([], nil)
                return
            }
            // 服务器数据异常
            guard let datas = networkResponse as? [[String : Any]] else {
                complete([], nil)
                return
            }
            complete(datas, nil)
        })
    }
    /// 回答信息
    fileprivate class func requestAnswerInfo(IDs: [Int], complete: @escaping ([[String: Any]]?, _ errorInfo: String?) -> Void) {
        let requestPath = TSURLPathV2.path.rawValue + "qa/reposted-answers"
        var parameter: [String: Any] = [:]
        var idStr = ""
        for idInt in IDs {
            idStr = idStr.isEmpty ? String(idInt) : idStr + "," +  String(idInt)
        }
        parameter["id"] = idStr
        try! RequestNetworkData.share.textRequest(method: .get, path: requestPath, parameter: parameter, complete: { (networkResponse, result) in
            // 请求失败
            guard result else {
                complete([], nil)
                return
            }
            // 服务器数据异常
            guard let datas = networkResponse as? [[String : Any]] else {
                complete([], nil)
                return
            }
            complete(datas, nil)
        })
    }
    /// 音乐专辑信息
    fileprivate class func requestMusicInfo(IDs: [Int], complete: @escaping ([[String: Any]]?, _ errorInfo: String?) -> Void) {
        let requestPath = TSURLPathV2.path.rawValue + "music/specials"
        var parameter: [String: Any] = [:]
        var idStr = ""
        for idInt in IDs {
            idStr = idStr.isEmpty ? String(idInt) : idStr + "," +  String(idInt)
        }
        parameter["id"] = idStr
        try! RequestNetworkData.share.textRequest(method: .get, path: requestPath, parameter: parameter, complete: { (networkResponse, result) in
            // 请求失败
            guard result else {
                complete([], nil)
                return
            }
            // 服务器数据异常
            guard let datas = networkResponse as? [[String : Any]] else {
                complete([], nil)
                return
            }
            complete(datas, nil)
        })
    }
    /// 音乐详情信息
    fileprivate class func requestMusicDetailInfo(IDs: [Int], complete: @escaping ([[String: Any]]?, _ errorInfo: String?) -> Void) {
        let requestPath = TSURLPathV2.path.rawValue + "music/songs"
        var parameter: [String: Any] = [:]
        var idStr = ""
        for idInt in IDs {
            idStr = idStr.isEmpty ? String(idInt) : idStr + "," +  String(idInt)
        }
        parameter["id"] = idStr
        try! RequestNetworkData.share.textRequest(method: .get, path: requestPath, parameter: parameter, complete: { (networkResponse, result) in
            // 请求失败
            guard result else {
                complete([], nil)
                return
            }
            // 服务器数据异常
            guard let datas = networkResponse as? [[String : Any]] else {
                complete([], nil)
                return
            }
            complete(datas, nil)
        })
    }
    /// 请求用户信息
    fileprivate class func requestUserInfo(userIds: [Int], complete: @escaping ([TSUserInfoModel]?, _ errorInfo: String?) -> Void) {
        TSTaskQueueTool.getAndSave(userIds: userIds) { (users, msg, status) in
            guard let users = users else {
                complete(nil, msg)
                return
            }
            complete(users, nil)
        }
    }
    //        let requestPath = TSURLPathV2.path.rawValue + TSURLPathV2.Message.atMeIDList.rawValue
    //        var parameter: [String: Any] = ["limit": limit]
    //        if let after = after {
    //            parameter["after"] = after
    //        }
    //        try! RequestNetworkData.share.textRequest(method: .get, path: requestPath, parameter: parameter, complete: { (networkResponse, result) in
    //            // 请求失败
    //            guard result else {
    //                //let message = TSCommonNetworkManager.getNetworkSuccessMessage(with: networkResponse)
    //                complete(nil, nil)
    //                return
    //            }
    //            // 服务器数据异常
    //            guard let datas = networkResponse as? [[String: Any]] else {
    //                complete(nil, nil)
    //                return
    //            }
    //            /// 解析数据
    //        })
}
