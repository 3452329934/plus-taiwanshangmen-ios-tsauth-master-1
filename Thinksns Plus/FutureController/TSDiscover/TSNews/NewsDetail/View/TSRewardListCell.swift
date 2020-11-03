//
//  TSRewardListCell.swift
//  ThinkSNS +
//
//  Created by GorCat on 2017/8/3.
//  Copyright © 2017年 ZhiYiCX. All rights reserved.
//

import UIKit

class TSRewardListCell: UITableViewCell {

    static let identifier = "TSRewardListCell"
    var rewardType: TSRewardType = .moment
    @IBOutlet weak var labelForTime: UILabel!
    @IBOutlet weak var labelForContent: UILabel!
    @IBOutlet weak var buttonForAvatar: AvatarView!

    func set(model: TSNewsRewardModel) {
        // 头像
        buttonForAvatar.avatarPlaceholderType = AvatarView.PlaceholderType(sexNumber: model.user.sex)
        let avatarInfo = AvatarInfo()
        avatarInfo.avatarURL = TSUtil.praseTSNetFileUrl(netFile: model.user.avatar)
        avatarInfo.verifiedIcon = model.user.verified?.icon ?? ""
        avatarInfo.verifiedType = model.user.verified?.type ?? ""
        avatarInfo.type = .normal(userId: model.userId)
        buttonForAvatar.avatarInfo = avatarInfo
        // 内容
        var contentString = NSMutableAttributedString()
        if model.user.name.isEmpty {
            model.user.name = "該用戶已被刪除"
        }
        switch self.rewardType {
        case .moment:
            contentString = NSMutableAttributedString(string: "\(model.user.name) 打賞了動態")
        case .news:
            contentString = NSMutableAttributedString(string: "\(model.user.name) 打賞了資訊")
        case .user:
            contentString = NSMutableAttributedString(string: "\(model.user.name) 打賞了用戶")
        case .answer:
            contentString = NSMutableAttributedString(string: "\(model.user.name) 打賞了回答")
        case .post:
            contentString = NSMutableAttributedString(string: "\(model.user.name) 打賞了貼文")
        }
        labelForContent.attributedText = TSCommonTool.string(contentString, addpendAtrrs: [[NSAttributedString.Key.foregroundColor: TSColor.main.content]], strings: [model.user.name])
        // 时间 // TODO: 替换时间
        labelForTime.text = TSDate().dateString(.normal, nsDate: model.createdDate)
    }

}
