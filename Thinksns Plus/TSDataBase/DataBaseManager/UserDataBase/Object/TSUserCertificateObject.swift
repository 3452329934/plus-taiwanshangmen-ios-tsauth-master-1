//
//  TSUserCertificateObject.swift
//  ThinkSNS +
//
//  Created by GorCat on 2017/8/9.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//

import RealmSwift
import UIKit

class TSUserCertificateObject: Object {

    /// 主键
    @objc dynamic var id = 1
    /// 认证类型
    @objc dynamic var type = ""
    /// 认证状态: 0 - 待审核, 1 - 通过, 2 - 拒绝
    @objc dynamic var status = -1
    /// 姓名
    @objc dynamic var name = ""
    /// 电话
    @objc dynamic var phone = ""
    /// 数字
    @objc dynamic var number = ""
    /// 描述
    @objc dynamic var desc = ""
    /// 图片
    let files = List<TSImageObject>()
    /// 企业名称
    @objc dynamic var orgName = ""
    /// 企业地址
    @objc dynamic var orgAddress = ""

    /// 设置主键
    override static func primaryKey() -> String? {
        return "id"
    }
}
