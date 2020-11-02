//
//  GroupSearchHistoryObject.swift
//  ThinkSNS +
//
//  Created by GorCat on 2017/12/1.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//
//  圈子搜索记录 object

import UIKit
import RealmSwift

class GroupSearchHistoryObject: Object {
    enum SearchType: Int {
        /// 圈子搜索
        case group = 1
        /// 圈内搜索帖子
        case postInGroup = 2
        /// 圈外搜索帖子
        case postOutGroup = 3
    }

    /// 时间戳
    @objc dynamic var timeInterval: Int = 0
    /// 搜索内容
    @objc dynamic var content = ""
    /// 搜索类型
    @objc dynamic var typeId = 0
    /// 主键 content + type
    @objc dynamic var historyKey = ""
    /// 圈子ID
    @objc dynamic var groupID: Int = 0

    /// 设置主键
    override static func primaryKey() -> String? {
        return "historyKey"
    }
}
