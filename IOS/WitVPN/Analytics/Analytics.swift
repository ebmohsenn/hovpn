//
//  Analytics.swift
//  StrongVPN
//
//  Created by Thong Vo on 16/01/2023.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

enum WitVPNVPNAnalyticsType: String {
    case screen                         = "screen_name"
    case tap                            = "tap"
    case connect                        = "connect_vpn"
    case disConnect                     = "disconnect_vpn"
    case signup                         = "signup"
    case login                          = "login"
    case loginAnonymous                 = "login_anonymous"
    case logout                         = "logout"
    case delete                         = "delete"
    case verifyOTP                      = "verify_otp"
    case restoreSubscription            = "restore_subscription"
    case restoreSuccessSubscription     = "restore_success_subscription"
    case restoreFailedSubscription      = "restore_failed_subscription"
    case purchaseSubscription           = "purchase_subscription"
    case reAuthen                       = "re_authen"
}

enum WitVPNVPNAnalyticsKey: String {
    case email                         = "email"
    case ipAddress                     = "ip_address"
}

public class WitVPNVPNAnalytics {
    
    static func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
        Crashlytics.crashlytics().setUserID(userId)
    }
    
    static func logScreen(params: [String: Any]?) {
        Analytics.logEvent(WitVPNVPNAnalyticsType.screen.rawValue, parameters: params)
    }
    
    static func logEvent(_ event: WitVPNVPNAnalyticsType, params: [String: Any]? = nil) {
        Analytics.logEvent(event.rawValue, parameters: params)
    }
}
