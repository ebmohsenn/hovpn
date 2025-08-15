//
//  wizBooster.swift
//  witBooster
//
//  Created by witworkapp on 11/4/20.
//

import Foundation

/// CONFIG
let k_subscription       = "Subscription"
var k_title_vpn: String = "VPN"
var k_title_premium: String = "PREMIUM"
var k_title_profile: String = "PROFILE"
var k_followId: String = "followId"
var k_user: String = "user"
var k_uuid: String = "uuid"

import DeviceKit
import GBDeviceInfo
import FirebaseFirestore
import UIKit
import FirebaseAuth
struct Define {
    let cl_navigation: UIColor = .init(named: "cl_navigation")!
    
    func font_bold(size: Int) -> UIFont {
        return .init(name: "WorkSans-Bold", size: CGFloat(size)) ?? UIFont.boldSystemFont(ofSize: CGFloat(size))
    }
    
    func font_medium(size: Int) -> UIFont {
        return .init(name: "WorkSans-Medium", size: CGFloat(size)) ?? UIFont.systemFont(ofSize: CGFloat(size))
    }
    
    func font_regular(size: Int) -> UIFont {
        return .init(name: "WorkSans-Regular", size: CGFloat(size)) ?? UIFont.systemFont(ofSize: CGFloat(size))
    }
    
    func font_thin(size: Int) -> UIFont {
        return .init(name: "WorkSans-Thin", size: CGFloat(size)) ?? UIFont.systemFont(ofSize: CGFloat(size))
    }
    
    struct itunes {
        static let secret_key                   =        "8d740f4cece34a0485e2066e87bc9c3a"
    }
    
    static let password_encrypt = "WitWorkApp2023@1234"
}

class WitWork: NSObject {
    static var shared: WitWork! = .init()
    
    let device = Device.current
    let gbDevice: GBDeviceInfo! =  GBDeviceInfo.deviceInfo()
    lazy var user: User? = Auth.auth().currentUser
    var serversData: [ServerModel] = []
    var uuid: String!
    var download: UInt64 = 0
    var upload: UInt64 = 0
    var adsBanner: String? = nil
    var adsShow: String? = nil
    
    override init() {
        super.init()
        guard let uuid = UserDefaults.standard.string(forKey: k_uuid) else{
            self.set(UIDevice.current.identifierForVendor?.uuidString ?? NSUUID().uuidString.lowercased())
            return
        }
        self.set(uuid)
    }
    func getDeviceInfo() -> [String: Any]{
        
        let battery = device.batteryLevel ?? 0
        let isGuidedAccessSessionActive: Int = device.isGuidedAccessSessionActive ? 1 : 0
        let screenBrightness = device.screenBrightness
        
        let model = self.gbDevice.modelString ?? ""
        let family = self.gbDevice.family.rawValue
        let physicalMemory = self.gbDevice.physicalMemory
        let rawSystemInfoString = self.gbDevice.rawSystemInfoString
        let pixelsPerInch = self.gbDevice.displayInfo.pixelsPerInch
        let display = self.gbDevice.displayInfo.display.rawValue

        return [
            "battery": battery,
            "isGuidedAccessSessionActive": isGuidedAccessSessionActive,
            "screenBrightness": screenBrightness,
            "model": model,
            "family": family,
            "physicalMemory": physicalMemory,
            "rawSystemInfoString": rawSystemInfoString ?? "",
            "pixelsPerInch": pixelsPerInch,
            "display": display,
            "uuid": WitWork.shared.uuid ?? NSUUID().uuidString.lowercased()
        ]
    }
    
    func logout() {
        self.download = 0
        self.upload = 0
        self.user = nil
        
        UserDefaults.standard.removeObject(forKey: k_user)
        UserDefaults.standard.synchronize()
    }
    
    func udpateTraffic(snapshot: DocumentSnapshot?) {
        guard let data = snapshot?.data(),
           let traffic = data["traffic"] as? [String: Any],
           let download = traffic["download"] as? UInt64,
           let upload = traffic["download"] as? UInt64  else { return }
        self.upload = upload
        self.download = download
    }
    
    func removeFollower() {
        UserDefaults.standard.removeObject(forKey: k_followId)
        UserDefaults.standard.synchronize()
    }
    
    func set(_ uuid: String) {
        self.uuid = uuid
        UserDefaults.standard.set(uuid, forKey: k_uuid)
        UserDefaults.standard.synchronize()
    }
    
    func getUUID() -> String {
        return self.uuid
    }
    
    func deleteAccount() {
        UserDefaults.standard.removeObject(forKey: k_subscription)
        UserDefaults.standard.synchronize()
    }
    
    //MARK: - Subscription
    func getSubscription() -> PaidSubscription? {
        guard let subscription = UserDefaults.standard.object(forKey: k_subscription) as? Data else{
            return nil
        }
        return PaidSubscription(data: subscription)
    }
    func set(subscription: PaidSubscription) {
        UserDefaults.standard.set(subscription.encode(), forKey: k_subscription)
        UserDefaults.standard.synchronize()
    }
}

public struct WP_Error: Error {
    let msg: String
    
    static func unknow() -> Error {
        return WP_Error(msg: "Unknow Error")
    }
}

extension WP_Error: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString(msg, comment: "")
    }
}
