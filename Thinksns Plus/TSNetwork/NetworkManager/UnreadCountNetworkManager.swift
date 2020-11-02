//
//  UnreadCountNetworkManager.swift
//  ThinkSNS +
//
//  Created by lip on 2017/9/8.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//
//  未读数网络请求管理
// 现在由两个接口完成: unread-count获取具体的列表数据 counts获取未读数量

import UIKit

class UnreadCountNetworkManager {
    static let share = UnreadCountNetworkManager()

    var responseNotices: UserCounts?

    func unreadCount(complete: @escaping ((_: Bool) -> Void)) {
        if TSCurrentUserInfo.share.isLogin == false {
            complete(false)
            return
        }
        var request = UserNetworkRequest().counts
        request.urlPath = request.fullPathWith(replacers: [])
        RequestNetworkData.share.text(request: request) { [weak self] (result) in
            switch result {
            case .failure(_), .error(_):
                complete(false)
                break
            case .success(let response):
                if let model = response.model {
                    TSCurrentUserInfo.share.unreadCount.system = model.system.badge
                    TSCurrentUserInfo.share.unreadCount.like = model.like.badge
                    TSCurrentUserInfo.share.unreadCount.comments = model.comment.badge
                    TSCurrentUserInfo.share.unreadCount.follows = model.follow.badge
                    TSCurrentUserInfo.share.unreadCount.at = model.at.badge
                   // TSCurrentUserInfo.share.unreadCount.pending = model.follow.badge
                   // TSCurrentUserInfo.share.unreadCount.feedCommentPinned = 5
                   // TSCurrentUserInfo.share.unreadCount.atUsers = model.at.badge
                    

                    TSCurrentUserInfo.share.unreadCount.isHiddenNoticeBadge = TSCurrentUserInfo.share.unreadCount.onlyNoticeUnreadCount() <= 0
                    self?.unploadTabbarBadge()

                    // 这里直接解析处理 简化之前的逻辑
                    self?.responseNotices = response.model
                    self?.processNotice()

                    complete(true)
                }
            }
        }
    }

    func processNotice() {
        guard let notices = responseNotices else {
            return
        }
        if !notices.like.preview_users_names.isEmpty {
            var likeUsers = ""
            let count = notices.like.preview_users_names.count > 3 ? 3 : notices.like.preview_users_names.count
            for user in notices.like.preview_users_names[0..<count] {
                likeUsers = likeUsers + user + "、"
            }
            likeUsers.remove(at: likeUsers.index(before: likeUsers.endIndex))
            if notices.like.preview_users_names.count <= 1 {
                likeUsers += "赞了我"
            } else {
                likeUsers += "等人赞了我"
            }
            TSCurrentUserInfo.share.unreadCount.likedUsers = likeUsers
            TSCurrentUserInfo.share.unreadCount.likeUsersDate = notices.like.last_created_at
        } else {
                TSCurrentUserInfo.share.unreadCount.likedUsers = nil
                TSCurrentUserInfo.share.unreadCount.likeUsersDate = nil
        }

        if !notices.comment.preview_users_names.isEmpty {
            var commentsUser = ""
            let count = notices.comment.preview_users_names.count > 2 ? 2 : notices.comment.preview_users_names.count
            for user in notices.comment.preview_users_names[0..<count] {
                commentsUser = commentsUser + user + "、"
            }
            commentsUser = commentsUser.substring(to: commentsUser.index(before: commentsUser.endIndex))
            if notices.comment.preview_users_names.count <= 1 {
                commentsUser += "评论了我"
            } else {
                commentsUser += "等人评论了我"
            }
            TSCurrentUserInfo.share.unreadCount.commentsUsers = commentsUser
            TSCurrentUserInfo.share.unreadCount.commentsUsersDate = notices.comment.last_created_at
        } else {
            TSCurrentUserInfo.share.unreadCount.commentsUsers = nil
            TSCurrentUserInfo.share.unreadCount.commentsUsersDate = nil
        }

        if !notices.at.preview_users_names.isEmpty {
            var atUser = ""
            let count = notices.at.preview_users_names.count > 2 ? 2 : notices.at.preview_users_names.count
            for userName in notices.at.preview_users_names[0..<count] {
                atUser = atUser + userName + "、"
            }
            atUser = atUser.substring(to: atUser.index(before: atUser.endIndex))
            if notices.at.preview_users_names.count <= 1 {
                atUser += "@了我"
            } else {
                atUser += "等人@了我"
            }
            TSCurrentUserInfo.share.unreadCount.atUsers = atUser
            TSCurrentUserInfo.share.unreadCount.atUsersDate = notices.at.last_created_at
        } else {
            TSCurrentUserInfo.share.unreadCount.atUsers = ""
            TSCurrentUserInfo.share.unreadCount.atUsersDate = nil
        }
    

        // 解析系统消息
        if notices.system.first == nil {
            return
        }
        if let type = notices.system.first.data["type"] as? String {
            var content = ""
            if type == "reward" {
                if let sender = notices.system.first.data["sender"] as? [String:Any] {
                    if let name = sender["name"] {
                        content = "\(name)打赏了你"
                    }
                }
            } else if type == "reward:feeds" {
                if let sender = notices.system.first.data["sender"] as? [String:Any] {
                    if let name = sender["name"] {
                        content = "\(name)打赏了你的动态"
                    }
                }
            } else if type == "reward:news" {
                if let news = notices.system.first.data["news"] as? [String:Any] {
                    if let sender = notices.system.first.data["sender"] as? [String:Any] {
                        if let sendername = sender["name"], let newsname = news["title"], let amount = notices.system.first.data["amount"], let unit = notices.system.first.data["unit"] {
                            content = "你的资讯《\(newsname)》被\(sendername)打赏了\(amount)\(unit)"
                        }
                    }
                }
            } else if type == "user-certification" {
                if let state = notices.system.first.data["state"] as? String, let contentt = notices.system.first.data["contents"] as? String {
                    if state == "rejected" {
                        content = "你申请的身份认证已被驳回，驳回理由：\(contentt)"
                    } else {
                        content = "你申请的身份认证已通过"
                    }
                }
            } else if type == "qa:answer-adoption" {
                content = "你提交的问题回答被采纳"
            } else if type == "question:answer" {
                content = "你提交的问题回答被采纳"
            } else if type == "qa:reward" {
                if let sender = notices.system.first.data["sender"] as? [String:Any], let name = sender["name"] as? String {
                    content = "\(name)打赏了你的回答"
                }
            } else if type == "qa:invitation" {
                if let question = notices.system.first.data["question"] as? [String:Any] {
                    if let sender = notices.system.first.data["sender"] as? [String:Any] {
                        if let sendername = sender["name"], let questionname = question["subject"] {
                            content = "\(sendername)邀请你回答问题「\(questionname)」"
                        }
                    }
                }
            } else if type == "qa:question-topic:reject" {
                if let topic = notices.system.first.data["topic_application"] as? [String:Any], let name = topic["name"] {
                    content = "「\(name)」专题申请被拒绝"
                }
            } else if type == "qa:question-topic:passed" {
                if let topic = notices.system.first.data["topic_application"] as? [String:Any], let name = topic["name"] {
                    content = "「\(name)」专题申请被通过"
                }
            } else if type == "pinned:feed/comment" {
                if let comment = notices.system.first.data["comment"] as? [String:Any] {
                    if let name = comment["contents"] {
                        if let state = notices.system.first.data["state"] as? String {
                            if state == "rejected" {
                                content = "你的动态评论「\(name)」的置顶请求被拒绝"
                            } else {
                                content = "你的动态评论「\(name)」的置顶请求已通过"
                            }
                        }
                    }
                }
            } else if type == "pinned:news/comment" {
                if let comment = notices.system.first.data["comment"] as? [String:Any] {
                    if let news = notices.system.first.data["news"] as? [String:Any] {
                        if let commentname = comment["name"], let newsname = news["name"] {
                            if let state = notices.system.first.data["state"] as? String {
                                if state == "rejected" {
                                    content = "你的关于资讯《\(newsname)》评论「\(commentname)」的置顶请求被拒绝"
                                } else {
                                    content = "你的关于资讯《\(newsname)》评论「\(commentname)」的置顶请求已通过"
                                }
                            }
                        }
                    }
                }
            } else if type == "group:comment-pinned" {
                if let state = notices.system.first.data["state"] as? String {
                    if state == "rejected" {
                        content = "你的评论置顶请求被拒绝"
                    } else {
                        content = "你的评论置顶请求已通过"
                    }
                }
            } else if type == "group:post-pinned" {
                if let post = notices.system.first.data["post"] as? [String:Any] {
                    if let name = post["title"] {
                        if let state = notices.system.first.data["state"] as? String {
                            if state == "rejected" {
                                content = "你的帖子「\(name)」的置顶请求被拒绝"
                            } else {
                                content = "你的帖子「\(name)」的置顶请求已通过"
                            }
                        }
                    }
                }
            } else if type == "group:join" {
                if let group = notices.system.first.data["group"] as? [String:Any], let groupname = group["name"] {
                    if let state = notices.system.first.data["state"] as? String {
                        if state == "rejected" {
                            content = "你被拒绝加入「\(groupname)」圈子"
                        } else {
                            content = "你被同意加入「\(groupname)」圈子"
                        }
                    } else {
                        if let user = notices.system.first.data["user"] as? [String:Any], let username = user["name"] {
                            content = "\(username)申请加入「\(groupname)」圈子"
                        }
                    }
                }
            } else if type == "group:send-comment-pinned" {
                if let post = notices.system.first.data["post"] as? [String:Any] {
                    if let title = post["title"] {
                        if let sender = notices.system.first.data["sender"] as? [String:Any], let sendername = sender["name"] as? String {
                            content = "\(sendername)在你的帖子「\(title)」下申请评论置顶"
                        } else {
                            content = "用户在你的帖子「\(title)」下申请评论置顶"
                        }
                    }
                }
            } else if type == "group:post-reward" {
                if let sender = notices.system.first.data["sender"] as? [String:Any], let sendername = sender["name"] as? String {
                    if let post = notices.system.first.data["post"] as? [String:Any], let postname = post["title"] as? String {
                        content = "\(sendername)打赏了你的帖子「\(postname)」"
                    }
                }
            } else if type == "purchase" {
                if let sender = notices.system.first.data["sender"] as? [String:Any] {
                    if let name = sender["name"] {
                        content = "\(name)购买了你的动态"
                    }
                }
            } else if type == "user-cash" {
                if let state = notices.system.first.data["state"] as? String {
                    if state == "rejected" {
                        content = "申请的提现失败"
                    } else {
                        content = "申请的提现成功"
                    }
                }
            } else if type == "pinned:feeds" {
                if let state = notices.system.first.data["state"] as? String {
                    if state == "rejected" {
                        content = "你申请的动态置顶未通过"
                    } else if state == "admin" {
                        content = "你的动态被管理员设为置顶"
                    } else {
                        content = "你申请的动态置顶已通过"
                    }
                }
            } else if type == "user-currency:cash" {
                if let state = notices.system.first.data["state"] as? String {
                    if state == "rejected" {
                        if let contentt = notices.system.first.data["contents"] as? String {
                            content = "你申请的积分提现已被驳回，驳回理由：\(contentt)"
                        } else {
                            content = "你申请的积分提现已被驳回"
                        }
                    } else {
                        content = "你申请的积分提现已通过"
                    }
                }
            } else if type == "report" {
                content = "你举报的内容平台已处理"
                if let state = notices.system.first.data["state"] as? String, let contentt = notices.system.first.data["subject"] as? String {
                    if state == "rejected" {
                        content = "你举报的内容「\(contentt)」被驳回"
                    } else {
                        if let resourceData = notices.system.first.data["resource"] as? [String:Any], let typeS = resourceData["type"] as? String {
                            if typeS == "users" {
                                content = "你举报的用户「\(contentt)」平台已处理"
                            } else if typeS == "feed_topics"  ||  typeS == "types/models/feed-topics"  {
                                content = "你举报的动态话题「\(contentt)」平台已处理"
                            } else if typeS == "comments" {
                                content = "你举报的评论「\(contentt)」平台已处理"
                            } else if typeS == "questions" {
                                content = "你举报的问题「\(contentt)」平台已处理"
                            } else if typeS == "feeds" {
                                content = "你举报的动态「\(contentt)」平台已处理"
                            } else if typeS == "news" {
                                content = "你举报的资讯「\(contentt)」平台已处理"
                            } else if typeS == "answers" {
                                content = "你举报的回答「\(contentt)」平台已处理"
                            } else if typeS == "posts" || typeS == "group-posts" {
                                content = "你举报的帖子「\(contentt)」平台已处理"
                            } else if typeS == "groups" {
                                content = "你举报的圈子「\(contentt)」平台已处理"
                            }
                        }
                    }
                }
            } else if type == "qa:question-topic:accept" {
                if let topicData = notices.system.first.data["topic"] as? [String:Any], let name = topicData["name"] as? String {
                    content = "你申请创建的专题「\(name)」已通过"
                }
            } else if type == "group:transform" {
                content = "圈子转让给你"
                if let group = notices.system.first.data["group"] as? [String:Any], let groupname = group["name"], let user = notices.system.first.data["user"] as? [String:Any], let username = user["name"] {
                    content = "\(username)把「\(groupname)」圈子转让给你"
                }
            } else if type == "group:report_post" {
                if let sender = notices.system.first.data["sender"] as? [String:Any], let sendername = sender["name"] as? String, let post = notices.system.first.data["post"] as? [String:Any], let postname = post["title"] as? String, let group = notices.system.first.data["group"] as? [String:Any], let groupName = group["name"] as? String {
                    content = "\(sendername)举报了你的圈子「\(groupName)」下的帖子「\(postname)」"
                }
            } else if type == "group:report" {
                content = "你举报的圈子内容平台已处理"
                if let state = notices.system.first.data["state"] as? String, let contentt = notices.system.first.data["report"] as? String {
                    if state == "pass" || state == "passed" {
                        content = "你举报的圈子内容「\(contentt)」平台已处理"
                    } else {
                        content = "你举报的圈子内容「\(contentt)」被驳回"
                    }
                } else {
                    if let state = notices.system.first.data["state"] as? String {
                        if state == "pass" {
                            content = "你举报的圈子平台已处理"
                        } else {
                            content = "你举报的圈子被驳回"
                        }
                    }
                }
            } else if type == "group:menbers" {
                if let group = notices.system.first.data["group"] as? [String:Any], let groupName = group["name"] as? String, let message = notices.system.first.data["message"] as? String {
                    content = message
                }
            } else if type == "qa:question-excellent:accept" {
                content = "你的问题被管理员加精"
            } else if type == "qa:question-excellent:reject" {
                content = "你的问题申请加精被拒"
            } else if type == "group:pinned-admin" {
                if let message = notices.system.first.data["message"] as? String {
                    content = message
                } else {
                    content = "你的帖子已被管理员置顶"
                }
            } else if type == "group:report-comment" {
                /// x举报了你的圈子[xx]下的帖子[xxx]的评论[xxxx]
                if let sender = notices.system.first.data["sender"] as? [String:Any], let sendername = sender["name"] as? String, let post = notices.system.first.data["post"] as? [String:Any], let postname = post["title"] as? String, let group = notices.system.first.data["group"] as? [String:Any], let groupName = group["name"] as? String, let comment = notices.system.first.data["comment"] as? [String:Any], let contents = comment["contents"] as? String {
                    content = "\(sendername)举报了你的圈子「\(groupName)」下的帖子「\(postname)」的评论「\(contents)」"
                }
            } else if type == "group:report-post" {
                /// x举报了你的圈子[xx]下的帖子[xxx]
                if let sender = notices.system.first.data["sender"] as? [String:Any], let sendername = sender["name"] as? String, let post = notices.system.first.data["post"] as? [String:Any], let postname = post["title"] as? String, let group = notices.system.first.data["group"] as? [String:Any], let groupName = group["name"] as? String {
                    content = "\(sendername)举报了你的圈子「\(groupName)」下的帖子「\(postname)」"
                }
            } else if type == "group:audit" {
                if let message = notices.system.first.data["contents"] as? String {
                    content = message
                }
            } else if type == "news:reject" {
                if let message = notices.system.first.data["contents"] as? String {
                    content = message
                }
            }else if let comment = notices.system.first.data["contents"] as? String {
                content = comment
            }
            TSCurrentUserInfo.share.unreadCount.systemInfo = content
            TSCurrentUserInfo.share.unreadCount.systemTime = notices.system.first.created_at
        }
    }
    // MARK: - 新的未读的数量
    func unreadCountVer2(complete: @escaping (_ model: UserCounts) -> Void) {
        var request = UserNetworkRequest().counts
        request.urlPath = request.fullPathWith(replacers: [])
        RequestNetworkData.share.text(request: request) {(result) in
            switch result {
            case .success(let response):
                if let model = response.model {
//                    // 更新一下消息的红点
//                    TSCurrentUserInfo.share.unreadCount.system = model.system
//                    TSCurrentUserInfo.share.unreadCount.like = model.liked
//                    TSCurrentUserInfo.share.unreadCount.comments = model.commented
//                    TSCurrentUserInfo.share.unreadCount.pending = model.pinned
//                    // 更新单独的未审核数量
//                    TSCurrentUserInfo.share.unreadCount.newsCommentPinned = model.newsCommentPinned
//                    TSCurrentUserInfo.share.unreadCount.feedCommentPinned = model.feedCommentPinned
//                    TSCurrentUserInfo.share.unreadCount.groupJoinPinned = model.groupJoinPinned
//                    TSCurrentUserInfo.share.unreadCount.postPinned = model.postPinned
//                    TSCurrentUserInfo.share.unreadCount.postCommentPinned = model.postCommentPinned
//                    TSCurrentUserInfo.share.unreadCount.at = model.at
//                    TSCurrentUserInfo.share.unreadCount.mutual = model.mutual
//                    TSCurrentUserInfo.share.unreadCount.follows = model.following
                    TSCurrentUserInfo.share.unreadCount.isHiddenNoticeBadge = TSCurrentUserInfo.share.unreadCount.onlyNoticeUnreadCount() <= 0
                    self.unploadTabbarBadge()
                    complete(response.model!)
                }
            case .failure(_), .error(_):
                break
            }
        }
    }
    // MARK: - 更新tabbar的红点状态
    func unploadTabbarBadge() {
        // 更新tabbar红点状态
        if let currentTC = TSRootViewController.share.currentShowViewcontroller as? TSHomeTabBarController {
            let tabBar = currentTC.customTabBar
            let tsUnred = TSCurrentUserInfo.share.unreadCount
            // 消息
            if (tsUnred.system + tsUnred.like + tsUnred.comments + tsUnred.pending + tsUnred.imMessage + tsUnred.at) > 0 {
                tabBar.showBadge(.message)
            } else {
                tabBar.hiddenBadge(.message)
            }
            // 个人中心
            if (tsUnred.follows + tsUnred.mutual) > 0 {
                tabBar.showBadge(.myCenter)
            } else {
                tabBar.hiddenBadge(.myCenter)
            }
            JPUSHService.setBadge(tsUnred.allNoticeUnreadCount() + tsUnred.imMessage)
            // 更新桌面applicationIconBadgeNumber
            UIApplication.shared.applicationIconBadgeNumber = tsUnred.allNoticeUnreadCount() + tsUnred.imMessage
        }
    }
}
