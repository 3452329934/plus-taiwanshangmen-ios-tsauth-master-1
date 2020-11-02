//
//  TSUserInfoObject.swift
//  Thinksns Plus
//
//  Created by GorCat on 17/2/15.
//  Copyright © 2017年 LeonFa. All rights reserved.
//
//  用户信息列表

import UIKit
import RealmSwift
import SwiftyJSON

/// 用户验证的数据库模型
class TSUserVerifiedObject: Object {
    @objc dynamic var type: String = ""
    @objc dynamic var icon: String = ""
    /// 认证描述
    @objc dynamic var descrip: String = ""
}

// 网络文件数据库模型，用于用户头像、背景、圈子封面等可修复文件
// 附件信息可查看 https://slimkit.github.io/docs/api-v2-core-file-storage.html
class TSNetFileObject: Object {
    /*
     
     "vendor": "local",
     "url": "https://xxxxx",
     "mime": "image/png",
     "size": 8674535,
     "dimension": {
     "width": 240,
     "height": 240,
     }
     */
    // 厂商名称
    @objc dynamic var vendor: String = "local"
    // 文件请求地址，GET 方式
    @objc dynamic var url: String = ""
    // 文件 MIME
    @objc dynamic var mime: String = ""
    // 文件尺寸
    @objc dynamic var size: Int = 0
    // 文件宽
    @objc dynamic var width: Int = 0
    // 文件高
    @objc dynamic var height: Int = 0

}

/// 用户附加信息的数据库模型
class TSUserExtraObject: Object {
    @objc dynamic var userId: Int = 0
    @objc dynamic var likesCount: Int = 0
    @objc dynamic var commentsCount: Int = 0
    @objc dynamic var followersCount: Int = 0
    @objc dynamic var followingsCount: Int = 0
    @objc dynamic var feedsCount: Int = 0
    @objc dynamic var updateDate: String = ""
    /// 问题数
    @objc dynamic var qustionsCount = 0
    /// 回答数
    @objc dynamic var answersCount = 0

    /// 设置索引
    override static func indexedProperties() -> [String] {
        return ["userId"]
    }
    /// 设置主键
    override static func primaryKey() -> String? {
        return "userId"
    }
}

/// 用户信息的数据库模型
class TSUserInfoObject: Object {
    /// 用户标识
    @objc dynamic var userIdentity = -1
    /// 用户名
    @objc dynamic var name = ""
    /// 邮箱
    @objc dynamic var email: String? = nil
    /// 电话
    @objc dynamic var phone: String? = nil
    /// 电话2，后台在“/user/find-by-phone”接口中返回的电话信息的 key 为 mobi，通过聚众讨论，决定增加一个字段
    @objc dynamic var mobi: String? = nil
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
    /// 用户标签
    let tags = List<TSTagObject>()

    /// 设置索引
    override static func indexedProperties() -> [String] {
        return ["userIdentity"]
    }

    /// 设置主键
    override static func primaryKey() -> String? {
        return "userIdentity"
    }
}
