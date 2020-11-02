//
//  TSMomentListObject.swift
//  Thinksns Plus
//
//  Created by GorCat on 17/2/22.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//
//  动态列表 - 列表信息表

import UIKit
import RealmSwift

class TSMomentListObject: Object {
    /// 用户标识
    @objc dynamic var userIdentity: Int = -1
    /// 动态类型，1 为处于此类型，0 为不处于此类型
    @objc dynamic var hot = 0 ///< 热门
    @objc dynamic var now = 0 ///< 最新
    @objc dynamic var follow = 0 ///< 关注
    /// 发送状态，0 发送中，1 成功 2 失败 用于本地发布动态状态更新
    @objc dynamic var sendState: Int = -1
    @objc dynamic var sendStateReason: String = "发送失败"
    /// 本地之间戳，用于热门列表排序
    @objc dynamic var localCreate: Double = 0
    /// 是否置顶
    @objc dynamic var isTop = false
    /// 频道 id
    let channelsIdentity = RealmOptional<Int>()

    // MARK: 动态内容
    /// 动态标识
    /// 该标识使用本地表示，发布成功后会被替换为服务器给予标识
    @objc dynamic var feedIdentity = -1
    /// 主键 本地创建的数据等于初始化的本地 feedIdentity 服务器给的数据等于服务器的 feedIdentity
    @objc dynamic var primaryKey = -1
    /// 动态标题
    @objc dynamic var title = ""
    /// 动态内容
    @objc dynamic var content = ""
    /// 创建时间
    @objc dynamic var create: NSDate = NSDate()
    /// 来源，1:pc 2:h5 3:ios 4:android 5:其他
    @objc dynamic var from = -1
    /// 经度
    @objc dynamic var latitude: String? = nil
    /// 纬度
    @objc dynamic var longtitude: String? = nil
    /// GeoHash
    @objc dynamic var geohash: String?
    // 图片数组
    let pictures = List<TSImageObject>()
    // 动态评论（最新三条）
    let comments = List<TSMomentCommnetObject>()

    // MARK: 动态工具栏

    /// 点赞数
    @objc dynamic var digg = -1
    /// 浏览量
    @objc dynamic var view = -1
    /// 评论数
    @objc dynamic var commentCount = -1
    /// 当前用户是否有点赞，0 为否，1 为是
    @objc dynamic var isDigg = -1
    /// 当前用户是否有收藏，0 为否，1 为是
    @objc dynamic var isCollect = -1

    // MARK: v2 接口数据
    /// 动态收费信息
    /// 审核状态
    let status = RealmOptional<Int>()
    let mark = RealmOptional<Int>()
    @objc dynamic var paid: TSPaidFeedObject?
    /// 评论收费信息
    @objc dynamic var commentPaid: TSPaidFeedObject?
    // 发布时的文字收费价格 单位分 0 表示不收费
    @objc dynamic var textPrice = 0
    /// 点赞人
    let diggs = List<RealmInt>()
    /// 打赏
    @objc dynamic var reward: TSRewardObject?
    /// 视频本地地址
    /// 如果是存在视频地址的情况下,视频封面是当做单张图片来处理的
    @objc dynamic var shortVideoOutputUrl: String?
    // 视频播放地址
    @objc dynamic var videoURL: String?
    /// 话题信息
    let topics = List<TopicListObject>()
    /// 转发资源类型
    @objc dynamic var repostType: String? = nil
    /// 转发资源ID
    @objc dynamic var repostID: Int = 0
    /// 转发信息
    @objc dynamic var repostModel: TSRepostModel? = nil

    /// 设置索引
    override static func indexedProperties() -> [String] {
        return ["hot", "now", "follow"]
    }

    /// 设置主键
    override static func primaryKey() -> String? {
        return "primaryKey"
    }
}
