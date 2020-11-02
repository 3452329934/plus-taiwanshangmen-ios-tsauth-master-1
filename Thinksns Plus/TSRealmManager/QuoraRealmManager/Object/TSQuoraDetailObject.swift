//
//  TSQuoraDetailObject.swift
//  ThinkSNS +
//
//  Created by 小唐 on 25/08/2017.
//  Copyright © 2017 ZhiYiCX. All rights reserved.
//
//  问答详情的数据库模型

import Foundation
import RealmSwift

typealias TSQuestionDetailObject = TSQuoraDetailObject
class TSQuoraDetailObject: Object {
    /// 问题唯一 ID 。
    @objc dynamic var id: Int = 0
    /// 发布的用户 ID，如果是 anonymity 是 1 则该字段为 0。
    @objc dynamic var userId: Int = 0
    /// 问题标题。
    @objc dynamic var title: String = ""
    /// 问题详情，markdown，如果没有详情为 null。
    @objc dynamic var body: String = ""
    /// 问题详情，纯文字版，可能为nil，用于兼容之前没有该字段时发布的问答
    @objc dynamic var body_text: String?
    /// 是否匿名，1 代表匿名发布，匿名后不会返回任何用户信息。
    @objc dynamic var isAnonymity: Bool = false
    /// 问题价值，悬赏金额，0 代表非悬赏。
    @objc dynamic var amount: Int = 0     // 0 表示非悬赏
    /// 围观总金额 - 该字段不一定存在，来自邀请答案中的
    var outlookAmount = RealmOptional<Int>()
    /// 是否自动入账。客户端无用，邀请回答后端判断逻辑使用。
    @objc dynamic var isAutomaticity: Bool = false
    /// 是否开启了围观。
    @objc dynamic var isLook: Bool = true
    /// 是否属于精选问题。
    @objc dynamic var isExcellent: Bool = false
    /// 问题评论总数统计。
    @objc dynamic var commentsCount: Int = 0
    /// 问题答案数量统计。
    @objc dynamic var answersCount: Int = 0
    /// 问题关注的人总数统计。
    @objc dynamic var watchersCount: Int = 0
    /// 喜欢问题的人总数统计。
    @objc dynamic var likesCount: Int = 0
    /// 问题查看数量统计。
    @objc dynamic var viewsCount: Int = 0
    /// 问题创建时间。
    @objc dynamic var createDate: Date = Date()
    /// 问题修改时间。
    @objc dynamic var updateDate: Date = Date()
    /// 用户是否关注这个问题。
    @objc dynamic var isWatched: Bool = false
    /// 问题状态，0 - 未解决，1 - 已解决， 2 - 问题关闭 。
    var status = RealmOptional<Int>()

//    /// 问题话题列表，参考「话题」文档。
//    @objc dynamic var topics: [Any]?
//    /// 问题邀请用户回答的答案列表，具体数据结构参考「回答」文档。
//    @objc dynamic var invitationAnswers: [Any]?
//    /// 问题采纳的答案列表，具体数据结构参考「回答」文档。
//    @objc dynamic var adoptionAnswers: [Any]?
//    /// 问题邀请回答的用户列表，参考「用户」文档。
//    @objc dynamic var invitations: [TSUserInfoObject]?
    /// 用户资料，如果是 anonymity 是 1 则该字段不存在。
    @objc dynamic var user: TSUserInfoObject?

    /// 主键
    override static func primaryKey() -> String? {
        return "id"
    }
}
