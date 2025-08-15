//
//  VPNManager.h
//  WitVPN
//
//  Created by thongvo on 9/20/21.
//

#import <Foundation/Foundation.h>
@import NetworkExtension;
NS_ASSUME_NONNULL_BEGIN

@interface VPNManager : NSObject

+(instancetype)shared;

/// MUST CALL IT IN APPDELEGATE
-(void)verify:(NSString*)purchaseCode;

@property(strong,nonatomic) NETunnelProviderManager *providerManager;
@property (nonatomic) NEVPNStatus status;

#pragma mark - OPENVPN
- (void) loadProviderManager:(void (^)(void))finishBlock;

- (void) openVPNconfigure:(NSString*)serverAddress data:(NSData*)data;

/// Configure and start OpenVPN with optional credentials for auth-user-pass and encrypted private key
- (void) openVPNconfigure:(NSString*)serverAddress
					 data:(NSData*)data
				 username:(NSString* _Nullable)username
				 password:(NSString* _Nullable)password
			 keyPassphrase:(NSString* _Nullable)keyPassphrase;
- (void) uninstallVPNConfigurationFromManagers;
- (void) startConnection:(void(^)(void))completion;
- (void) stopConnection:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
