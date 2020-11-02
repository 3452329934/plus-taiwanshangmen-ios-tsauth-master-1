//
//  ListCommentObject.swift
//  ThinkSNS +
//
//  Created by GorCat on 2017/11/13.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//
//  列表专用评论数据模型

import UIKit
import RealmSwift

class FeedListCommentObject: Object {

    // 动态 id
    @objc dynamic var feedId = 0
    /// 评论 id
    @objc dynamic var commentId = 0
    /// 评论者的用户 id
    @objc dynamic var userId = 0
    /// 评论者的用户名
    @objc dynamic var name = ""
    /// 被评论用户 id，为 nil 表示评论对象是动态
    let replyUserId = RealmOptional<Int>()
    /// 被评论用户名，为 nil 表示评论对象是动态
    @objc dynamic var replyName: String?
    /// 评论内容
    @objc dynamic var content = ""
    /// 是否显示置顶标签
    @objc dynamic var showTopIcon = false
    /// 发送状态
    @objc dynamic var sendStatus = 0

}
