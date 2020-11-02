//
//  OtherLoginView.swift
//  date
//
//  Created by Fiction on 2017/8/7.
//  Copyright © 2017年 段泽里. All rights reserved.
//
//  三方登录框UI

import UIKit
import MonkeyKing
import AuthenticationServices

class OtherLoginView: UIView {
    /// 标题
    let titleLabel: UILabel = UILabel()
    /// 左边线
    let leftSeparatorView = UIView()
    /// 右边线
    let rightSeparatorView = UIView()
    /// 按钮 - qq
    let qqItem: TSShareButton = TSShareButton(normalImage: #imageLiteral(resourceName: "IMG_login_qq.png"), title: "QQ")
    /// 按钮 - 微博
    let weiboItem: TSShareButton = TSShareButton(normalImage: #imageLiteral(resourceName: "IMG_login_weibo-.png"), title: "微博")
    /// 按钮 - 微信
    let weChatItem: TSShareButton = TSShareButton(normalImage: #imageLiteral(resourceName: "IMG_login_wechat.png"), title: "微信")
    // Apple登录
    let appleItem = UIView()

    /// 判断怎么布局需要的array
    var layoutArray: Array<UIControl> = []
    weak var pushVC: TSLoginVC!

    init(frame: CGRect, VC: TSLoginVC) {
        super.init(frame: frame)
        self.pushVC = VC
        setUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUI() {
        titleLabel.text = "社交账号登录"
        titleLabel.textColor = TSColor.normal.disabled
        titleLabel.font = UIFont.systemFont(ofSize: TSFont.UserName.comment.rawValue)
        leftSeparatorView.backgroundColor = TSColor.normal.disabled
        rightSeparatorView.backgroundColor = TSColor.normal.disabled

        qqItem.addTarget(self, action: #selector(loginForQQ), for: .touchUpInside)
        weiboItem.addTarget(self, action: #selector(loginForWeiBo), for: .touchUpInside)
        weChatItem.addTarget(self, action: #selector(loginForWeChat), for: .touchUpInside)

        self.addSubview(titleLabel)
        self.addSubview(leftSeparatorView)
        self.addSubview(rightSeparatorView)
        self.addSubview(qqItem)
        self.addSubview(weiboItem)
        self.addSubview(weChatItem)

        addSubview(appleItem)
        /// 标题
        let appleTitle = UILabel()
        appleItem.addSubview(appleTitle)
        appleTitle.text = "Apple"
        appleTitle.textColor = TSColor.normal.minor
        appleTitle.font = UIFont.systemFont(ofSize: TSFont.Button.toolbarTop.rawValue)
        appleTitle.textAlignment = .center
        appleTitle.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
        }
        layoutArray = []

        if ShareManager.thirdAccout(type: .qq).isAppInstalled {
            layoutArray.append(qqItem)
            qqItem.isHidden = false
        } else {
            qqItem.isHidden = true
        }

        if ShareManager.thirdAccout(type: .wechat).isAppInstalled {
            layoutArray.append(weChatItem)
            weChatItem.isHidden = false
        } else {
            weChatItem.isHidden = true
        }

        if ShareManager.thirdAccout(type: .weibo).isAppInstalled {
            layoutArray.append(weiboItem)
            weiboItem.isHidden = false
        } else {
            weiboItem.isHidden = true
        }

        /// iOS13才支持Apple登录
        if #available(iOS 13.0, *) {
            let appleSignBtn = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
            appleItem.addSubview(appleSignBtn)
            appleSignBtn.layer.cornerRadius = 20
            appleSignBtn.clipsToBounds = true
            appleSignBtn.addTarget(self, action: #selector(appleSignBtnClick), for: .touchUpInside)
            layoutArray.append(appleSignBtn)
        } else {
            /// 不支持Apple登录
        }

        /// 如果没有内容就隐藏自己
        if layoutArray.isEmpty {
            isHidden = true
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self)
            make.centerX.equalTo(self)
        }
        leftSeparatorView.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(self).offset(41.5)
            make.right.equalTo(titleLabel.snp.left).offset(-10)
            make.height.equalTo(0.5)
        }
        rightSeparatorView.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(titleLabel.snp.right).offset(10)
            make.right.equalTo(self).offset(-41.5)
            make.height.equalTo(0.5)
        }
        let itemWidth: CGFloat = 40
        let itemHeight: CGFloat = 62
        let itemSpace: CGFloat = (ScreenWidth - itemWidth * CGFloat(layoutArray.count)) / CGFloat(layoutArray.count + 1)

        for (index, item) in layoutArray.enumerated() {
            if #available(iOS 13.0, *) {
                if item.isKind(of: ASAuthorizationAppleIDButton.self) {
                    item.snp.makeConstraints { (make) in
                        make.left.top.equalToSuperview()
                        make.width.equalTo(itemWidth)
                        make.height.equalTo(itemWidth)
                    }
                    appleItem.snp.makeConstraints { (make) in
                        make.height.equalTo(itemHeight)
                        make.width.equalTo(itemWidth)
                        make.bottom.equalToSuperview()
                        make.left.equalToSuperview().offset(itemSpace * CGFloat(index + 1) + itemWidth * CGFloat(index))
                    }
                } else {
                    item.snp.makeConstraints { (make) in
                        make.height.equalTo(itemHeight)
                        make.width.equalTo(itemWidth)
                        make.bottom.equalToSuperview()
                        make.left.equalToSuperview().offset(itemSpace * CGFloat(index + 1) + itemWidth * CGFloat(index))
                    }
                }
            } else {
                item.snp.makeConstraints { (make) in
                    make.height.equalTo(itemHeight)
                    make.bottom.equalToSuperview()
                    make.width.equalTo(itemWidth)
                    make.left.equalToSuperview().offset(itemSpace * CGFloat(index + 1) + itemWidth * CGFloat(index))
                }
            }
        }
    }

    // MARK: - 按钮方法
    @objc func loginForQQ() {
        TSTripartiteAuthorizationManager().qqForAuthorization { (name, token, status) in
            guard status else {
                return
            }
            self.isSocialited(provider: .qq, token: token!, name: name!)
        }
    }

    @objc func loginForWeiBo() {
        TSTripartiteAuthorizationManager().weiboForAuthorization { (name, token, status) in
            guard status else {
                return
            }
            self.isSocialited(provider: .weibo, token: token!, name: name!)
        }
    }

    @objc func loginForWeChat() {
        TSTripartiteAuthorizationManager().weichatForAuthorization { (name, token, status) in
            guard status else {
                return
            }
            self.isSocialited(provider: .wechat, token: token!, name: name!)
        }
    }
    @objc func appleSignBtnClick() {
        if TSCurrentUserInfo.share.isLogin {
            TSCurrentUserInfo.share.logOut()
        }
        TSSignInAppleManager.share().startGetAuthorization()
        TSSignInAppleManager.share().didGetAuthInfoAction = { [unowned self] (uid, token) in
            /// 获取一个用户名称
            self.getRandomName { (aName) in
                self.isSocialited(provider: .apple, token: token, name: aName)
            }
        }
    }

    /// - 未绑定，走三方注册
    func pushOtherRegisteredVC(provider: ProviderType, asscesToken: String, name: String) -> Void {
        let vc = TSOtherRegisteredVC(socialite: TSSocialite(provider: provider, token: asscesToken, name: name, isLogin: self.pushVC.isHiddenDismissButton!))
        pushVC.navigationController?.pushViewController(vc, animated: true)
    }

    /// - 判断是否已经绑定
    func isSocialited(provider: ProviderType, token: String, name: String) {
        BindingNetworkManager().isSocialited(provider: provider, token: token) { (userToken, model, _, status) in
            guard status else {
                self.pushOtherRegisteredVC(provider: provider, asscesToken: token, name: name)
                return
            }
            BindingNetworkManager().saveUserInfo(token: userToken!, model: model!, isRegister: false)
            if self.pushVC.isHiddenDismissButton! == false { // 游客进入该页面登录成功
                NotificationCenter.default.post(name: NSNotification.Name.Visitor.login, object: nil)
                self.pushVC.dismiss(animated: true, completion: nil)
            } else {
                TSRootViewController.share.show(childViewController: .tabbar)
            }
        }
    }
    // MARK: - 隐式注册流程
    func getRandomName(complete: @escaping ((_ name: String) -> Void)) {
        var name = "用户"
        let characters = "0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z"
        let characterArr = characters.components(separatedBy: ",")
        var ranCodeString = ""
        for _ in 0 ..< 6 {
            let index = Int(arc4random_uniform(UInt32(characterArr.count)))
            ranCodeString.append(characterArr[index])
        }
        name.append(ranCodeString)
        let path = TSURLPathV2.path.rawValue + TSURLPathV2.User.users.rawValue + name
        try! RequestNetworkData.share.textRequest(method: .get, path: path, parameter: nil, complete: { (data, status) in
            /// 如果注册了 就返回用户信息，否者404
            if status == false {
                complete(name)
            } else {
                /// 重新再生成一个
                self.getRandomName(complete: { (aName) in
                    complete(aName)
                })
            }
        })
    }
}
