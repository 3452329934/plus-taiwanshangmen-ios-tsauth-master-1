//
//  TSAnswerListObject.swift
//  ThinkSNS +
//
//  Created by 小唐 on 25/08/2017.
//  Copyright © 2017 ZhiYiCX. All rights reserved.
//
//  答案列表的数据库模型

import Foundation
import RealmSwift

class TSAnswerListObject: Object {
    /// 回答唯一标识 ID 。
    @objc dynamic var id: Int = 0
    /// 回答所属问题标识 ID 。
    @objc dynamic var questionId: Int = 0
    /// 发布回答用户标识ID，如果 anonymity 为 1 则只为 0 。
    @objc dynamic var userId: Int = 0
    /// 回答的内容，markdown 。
    @objc dynamic var body: String = ""
    /// 回答的内容，纯文本字段，为nil表示兼容之前没该字段时的处理，
    @objc dynamic var body_text: String? = nil
    /// 是否是匿名回答 。
    @objc dynamic var isAnonymity: Bool = false
    /// 是否是采纳答案。
    @objc dynamic var isAdoption: Bool = false
    /// 是否该回答是被邀请的人的回答。
    @objc dynamic var isInvited: Bool = false
    /// 评论总数统计。
    @objc dynamic var commentsCount: Int = 0
    /// 回答打赏总额统计。
    @objc dynamic var rewardsAmount: Float = 0
    /// 打赏的人总数统计。
    @objc dynamic var rewardersCount: Int = 0
    /// 回答喜欢总数统计。
    @objc dynamic var likesCount: Int = 0
    /// 回答浏览量统计。
    @objc dynamic var viewsCount: Int = 0
    /// 回答创建时间。
    @objc dynamic var createDate: Date?
    /// 回答更新时间。
    @objc dynamic var updateDate: Date?
    /// 是否喜欢这个回答。
    var liked: Bool = false
    /// 是否已收藏这个回答。
    var collected: Bool = false
    /// 是否已打赏这个问题。
    var rewarded: Bool = false
    /// 回答的用户资料，参考「用户」文档，如果 anonymity 为 1 则不存在这个字段或者为 null 。
    @objc dynamic var user: TSUserInfoObject?

    /// 主键
    override static func primaryKey() -> String? {
        return "id"
    }
}
