//
//  TSReceiveCommentListModel.swift
//  ThinkSNSPlus
//
//  Created by IMAC on 2019/3/15.
//  Copyright © 2019年 ZhiYiCX. All rights reserved.
//

import UIKit
import ObjectMapper

class TSReceiveCommentListModel: Mappable {
    /// 评论 ID
    var id: String!
    /// 评论时间
    var createDate: Date?
    var contents: String = ""
    /// 评论用户
    var commentUserId: Int = 0
    /// 所属资源类型(动态)
    var sourceType: String = ""
    var sourceId: Int = 0
    /// 其他类型的所属资源
    var otherTypeSourceType: String = ""
    var otherTypeSourceId: Int = 0
    var hasReplay = false

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        id <- map["id"]
        createDate <- (map["created_at"], TSDateTransfrom())
        contents <- map["data.contents"]
        commentUserId <- map["data.sender.id"]
        sourceType <- map["data.resource.type"]
        sourceId <- map["data.resource.id"]
        otherTypeSourceType <- map["data.commentable.type"]
        otherTypeSourceId <- map["data.commentable.id"]
        hasReplay <- map["data.hasReply"]
    }
}
