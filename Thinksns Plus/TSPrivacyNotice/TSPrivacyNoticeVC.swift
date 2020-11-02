//
//  TSPrivacyNoticeVC.swift
//  ThinkSNSPlus
//
//  Created by IMAC on 2020/7/8.
//  Copyright © 2020 ZhiYiCX. All rights reserved.
//

import UIKit

class TSPrivacyNoticeVC: UIViewController {
    @IBOutlet weak var launchImageView: UIImageView!
    @IBOutlet weak var noticeBgView: UIView!
    @IBOutlet weak var aTitleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var privacyNoticeLabel: TYAttributedLabel!
    @IBOutlet weak var sureBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!

    var link0Range = NSRange(location: 0, length: 0)
    var link1Range = NSRange(location: 0, length: 0)
    var isSecondNotice = false

    var sureAciton: (()->Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        noticeBgView.backgroundColor = .white
        noticeBgView.layer.cornerRadius = 8
        noticeBgView.clipsToBounds = true
        aTitleLabel.textColor = TSColor.main.content
        let content = "欢迎来到\("APP_SIMPLE_NAME".localized)!\n1. 为更好的提供浏览推荐、发布信息、购买商品、交流沟通、注册认证等相关服务，我们会根据您使用服务的具体功能需要，收集必要的用户信息（可能涉及账户、交易、设备等相关信息）；\n 2. 未经您同意，我们不会从三方获取、共享或对外提供您的信息；\n 3. 您可以访问、更正、删除您的个人信息，我们也将提供注销、投诉方式。"
        let attrStr = NSMutableAttributedString(string: content)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6.0
        attrStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrStr.string.count))
        contentLabel.attributedText = attrStr

        privacyNoticeLabel.textColor = TSColor.main.content
        privacyNoticeLabel.text = "阅读完整版《用户协议》和《隐私政策》"
        link0Range = NSRange(location: 5, length: 6)
        link1Range = NSRange(location: 12, length: 6)
        privacyNoticeLabel.addLink(withLinkData: "1", linkColor: .blue, underLineStyle: CTUnderlineStyle(rawValue: 0), range: link0Range)
        privacyNoticeLabel.addLink(withLinkData: "2", linkColor: .blue, underLineStyle: CTUnderlineStyle(rawValue: 0), range: link1Range)
        privacyNoticeLabel.delegate = self
        privacyNoticeLabel.lineBreakMode = .byCharWrapping
        
        cancelBtn.backgroundColor = .white
        cancelBtn.layer.cornerRadius = 35 / 2
        cancelBtn.setTitleColor(TSColor.normal.minor, for: .normal)
        cancelBtn.setTitle("不同意", for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        cancelBtn.layer.borderColor = TSColor.normal.minor.cgColor
        cancelBtn.layer.borderWidth = 1
    
        sureBtn.backgroundColor = TSColor.main.theme
        sureBtn.layer.cornerRadius = 35 / 2
        sureBtn.setTitleColor(.white, for: .normal)
        sureBtn.setTitle("同意", for: .normal)
        sureBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
    }

    @IBAction func cancelBtnClick(_ sender: Any) {
        if !isSecondNotice {
            let content = "您的信息仅用于为您提供服务，\("APP_SIMPLE_NAME".localized)会坚决保障您的隐私信息安全。\n如果您仍不同意用户协议已经隐私政策，很遗憾我们将无法继续为您提供服务"
            let attrStr = NSMutableAttributedString(string: content)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6.0
            attrStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrStr.string.count))
            contentLabel.attributedText = attrStr

            cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            cancelBtn.setTitle("不同意，退出应用", for: .normal)

            isSecondNotice = true
        } else {
            exit(0)
        }
    }
    
    @IBAction func sureBtnClick(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: TSCurrentUserInfo.isAccessUserPrivacy)
        UserDefaults.standard.synchronize()
        sureAciton?()
    }
}

extension TSPrivacyNoticeVC: TYAttributedLabelDelegate {
    func attributedLabel(_ attributedLabel: TYAttributedLabel!, textStorageClicked textStorage: TYTextStorageProtocol!, at point: CGPoint) {
        // V2 版本网络请求
        RequestNetworkData.share.configRootURL(rootURL: TSAppConfig.share.rootServerAddress)
        if textStorage.range == link0Range {
            /// 用户协议
            TSUserNetworkingManager.getUserAgreement { (data, message, status) in
               if let data = data {
                   let markdownVC = TSMarkdownController(markdown: data)
                   markdownVC.title = "用户协议"
                   self.navigationController?.pushViewController(markdownVC, animated: true)
               } else {
                   TSIndicatorWindowTop.showDefaultTime(state: .faild, title: "网络错误")
               }
            }
        } else if textStorage.range == link1Range {
            /// 隐私政策
            TSUserNetworkingManager.getPrivacyAgreement { (data, message, status) in
               if let data = data {
                   let markdownVC = TSMarkdownController(markdown: data)
                   markdownVC.title = "隐私政策"
                   self.navigationController?.pushViewController(markdownVC, animated: true)
               } else {
                   TSIndicatorWindowTop.showDefaultTime(state: .faild, title: "网络错误")
               }
            }
        }
    }
}

