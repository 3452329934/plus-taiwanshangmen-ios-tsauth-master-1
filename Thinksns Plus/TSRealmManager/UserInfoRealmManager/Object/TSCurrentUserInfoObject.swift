//
//  TSCurrentUserInfoObject.swift
//  ThinkSNS +
//
//  Created by 小唐 on 25/07/2017.
//  Copyright © 2017 ZhiYiCX. All rights reserved.
//
//  当前用户的数据库模型

import Foundation
import RealmSwift

class TSCurrentUserInfoObject: Object {
    /// 用户标识
    @objc dynamic var userIdentity = -1
    /// 用户名
    @objc dynamic var name = ""
    /// 邮箱
    @objc dynamic var email: String? = nil
    /// 电话
    @objc dynamic var phone: String? = nil
    /// 性别
    @objc dynamic var sex: Int = 0
    /// 简介
    @objc dynamic var bio: String? = nil
    /// 地址
    @objc dynamic var location: String? = nil
    /// 创建时间
    @objc dynamic var createDate: String = ""
    /// 更新时间
    @objc dynamic var updateDate: String = ""
    /// 头像
    @objc dynamic var avatar: TSNetFileObject?
    /// 背景
    @objc dynamic var bg: TSNetFileObject?
    /// Whether the user is following you.
    @objc dynamic var following: Bool = false
    /// Whether you are following this user.
    @objc dynamic var follower: Bool = false
    /// 好友数量
    @objc dynamic var friendsCount: Int = 0
    /// 验证信息
    @objc dynamic var verified: TSUserVerifiedObject?
    /// 附加信息
    @objc dynamic var extra: TSUserExtraObject?
    /// 钱包
    @objc dynamic var wallet: TSUserInfoWalletObject?

    /// 设置索引
    override static func indexedProperties() -> [String] {
        return ["userIdentity"]
    }

    /// 设置主键
    override static func primaryKey() -> String? {
        return "userIdentity"
    }
}
