//
//  ServersModel.swift
//  WitVPN
//
//  Created by thongvm on 16/01/2022.
//

import Foundation
class ServerModel: NSObject {
    var country: String = ""
    var countryCode: String = ""
    var ipAddress: String = ""
    var ovpn: String = ""
    var ovpnName: String = ""
    var premium: Bool = false
    var recommend: Bool = false
    var state: String = ""
    var status: Bool = false
    
    override init() {
        super.init()
    }
    
    func initWith(data: [String: Any]) {
        if let country = data["country"] as? String {
            self.country = country
        }
        
        if let countryCode = data["countryCode"] as? String {
            self.countryCode = countryCode
        }
        
        if let ipAddress = data["ipAddress"] as? String {
            self.ipAddress = ipAddress
        }
        
        if let ovpn = data["ovpn"] as? String {
            self.ovpn = ovpn
        }
        
        if let ovpnName = data["ovpnName"] as? String {
            self.ovpnName = ovpnName
        }
        
        if let state = data["state"] as? String {
            self.state = state
        }
        
        if let premium = data["premium"] as? Bool {
            self.premium = premium
        }
        
        if let recommend = data["recommend"] as? Bool {
            self.recommend = recommend
        }
        
        if let status = data["status"] as? Bool {
            self.status = status
        }
    }
    
    func dictionary() -> [String: Any] {
        return ["country": self.country,
                "countryCode": self.countryCode,
                "ipAddress": self.ipAddress,
                "ovpn": self.ovpn,
                "ovpnName": self.ovpnName,
                "state": self.state,
                "premium": self.premium,
                "recommend": self.recommend,
                "status": self.status]
    }
}
