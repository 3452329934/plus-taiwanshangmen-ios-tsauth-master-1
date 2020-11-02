//
//  TSSignInAppleManager.swift
//  ThinkSNSPlus
//
//  Created by IMAC on 2020/4/26.
//  Copyright © 2020 ZhiYiCX. All rights reserved.
//

import UIKit
import AuthenticationServices

class TSSignInAppleManager: NSObject {

    private static let shareManager = TSSignInAppleManager()
    /// 获取到了登录信息
    var didGetAuthInfoAction: ((_ uid: String, _ token: String)->Void)?

    class func share() -> TSSignInAppleManager {
        return shareManager
    }

    func startGetAuthorization() {
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        } else {
            // Fallback on earlier versions
        }
    }
}

extension TSSignInAppleManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow!
    }

    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:

                let userIdentifier = appleIDCredential.user
                guard let tokenData = appleIDCredential.identityToken, let tokenString = NSString(data: tokenData, encoding: String.Encoding.utf8.rawValue) else {
                    return
                }
                didGetAuthInfoAction?(userIdentifier, tokenString as String)
            default:
                break
        }
    }
}
