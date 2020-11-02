//
//  NewsObject.swift
//  ThinkSNS +
//
//  Created by lip on 2017/8/8.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//

import UIKit
import RealmSwift

///  资讯列表中的资讯数据库模型
class NewsObject: Object {
    /// 数据标识
    @objc dynamic var id: Int = 0
    /// 标题
    @objc dynamic var title: String = ""
    /// 副标题
    @objc dynamic var subject: String = ""
    /// 来源
    @objc dynamic var from: String = ""
    /// 作者
    @objc dynamic var author:	String = ""
    /// 发布者id
    @objc dynamic var authorId: Int = 0
    /// 点击量
    @objc dynamic var hits: Int = 0
    /// 当前用户是否已收藏
    @objc dynamic var isCollected: Bool = false
    /// 当前用户是否已点赞
    @objc dynamic var isLike: Bool = false
    /// 创建时间
    @objc dynamic var createdDate: NSDate = NSDate()
    /// 更新时间
    @objc dynamic var updatedDate: NSDate = NSDate()
    /// 所属分类信息
    @objc dynamic var categoryInfo: NewsCategoryObject!
    /// 封面图信息
    @objc dynamic var coverInfo: NewsImageObject?

    override static func primaryKey() -> String? {
        return "id"
    }
}

///  资讯列表中的置顶资讯数据库模型
class TopNewsObject: NewsObject {
}

class NewsCategoryObject: Object {
    /// 标识
    @objc dynamic var id: Int = 0
    /// 名称
    @objc dynamic var name: String = ""
    /// 所属分类排序
    @objc dynamic var rank: Int = 0

    override static func primaryKey() -> String? {
        return "id"
    }
}

class NewsImageObject: Object {
    /// 资讯封面附件id
    @objc dynamic var id: Int = 0
    /// 资讯封面尺寸
    @objc dynamic var size: String = ""

    override static func primaryKey() -> String? {
        return "id"
    }
}
