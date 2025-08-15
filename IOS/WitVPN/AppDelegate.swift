//
//  AppDelegate.swift
//  WitVPN
//
//  Created by thongvm on 07/01/2022.
//

import UIKit
import FirebaseCore
import SwiftyStoreKit
import GoogleMobileAds
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        VPNManager.shared().verify("PUT_YOUR_PURCHASE_CODE")
        VPNManager.shared().loadProviderManager {}
        setupIAP()

        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        return true
    }
    
    func setupIAP() {
        StoreKit.shared.setupIAP()
    }
}

