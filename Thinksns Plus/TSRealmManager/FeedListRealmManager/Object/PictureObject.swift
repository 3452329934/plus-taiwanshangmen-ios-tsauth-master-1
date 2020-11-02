//
//  PictureObject.swift
//  ThinkSNS +
//
//  Created by GorCat on 2017/11/13.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//

import UIKit
import RealmSwift

class PictureObject: Object {
    /// 图片网络链接
    @objc dynamic var url: String?
    /// 图片缓存地址
    @objc dynamic var cache: String?
    /// 图片原始的大小
    @objc dynamic var originalWidth: CGFloat = 0
    @objc dynamic var originalHeight: CGFloat = 0
    /// 加载图片时是否要清空旧的图片缓存
    @objc dynamic var shouldClearCache = false
    /// 是否需要显示长图标识
    @objc dynamic var shouldShowLongicon = false
    /// 图片类型
    @objc dynamic var mimeType: String = ""
    /// 厂商名称
    @objc dynamic var vendor: String = "local"
}

class PaidPictureObject: PictureObject {
    var paidInfo: PiadInfoObject?
}

class PiadInfoObject: Object {

    /// 当前用户是否已经付费
    @objc dynamic var isPaid = false
    /// 付费节点
    @objc dynamic var node = 0
    /// 付费金额
    @objc dynamic var price = 0.0
    // 付费方式
    @objc dynamic var payType = ""
}
