//
//  VPNManager.m
//  Bingoo
//
//  Created by thongvo on 9/20/21.
//

#import "VPNManager.h"
#import <os/log.h>
@import NetworkExtension;
@interface VPNManager ()
@property os_log_t log;
@property (nonatomic) Boolean is_verify;
@property (nonatomic) Boolean is_verify_purchase_code;
@property (nonatomic, strong) NSString *purchaseCode;
@end
@implementation VPNManager
@synthesize log;

+(instancetype)shared {
    static dispatch_once_t once;
        static VPNManager* sharedInstance;
        dispatch_once(&once, ^{
            sharedInstance = [[VPNManager alloc] init];
        });
    return sharedInstance;
}
-(NEVPNStatus)status {
    return self.providerManager.connection.status;
}
-(instancetype)init {
    if (self = [super init]) {
        self.is_verify_purchase_code = true;
        self.is_verify = false;
    }
    return self;
}

-(void)verify:(NSString*)purchaseCode {
    if (purchaseCode.length == 0) {
        return;
    }
    
    self.purchaseCode = purchaseCode;
    
    self.is_verify = true;

    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.envato.com/v3/market/author/sale?code=%@",purchaseCode]]];
    [request setValue:@"Bearer ENX1AjNzONFaTIT4nwYm3VKpyTNAHvpn" forHTTPHeaderField:@"Authorization"];
    [request setValue:@"Purchase code verification on mywebsite.com" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:@"GET"];
    NSURLSessionDataTask * dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *err;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
        if (err) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 403) {
                NSLog(@"response status code: %ld", (long)[httpResponse statusCode]);
                [self raiseExeption];
            }

        }else {
            NSDictionary *item = [dic valueForKey:@"item"];
            NSString *name = [[item valueForKey:@"name"] lowercaseString];
            if (name.length == 0 || [name rangeOfString:@"witvpn"].location == NSNotFound || [name rangeOfString:@"android"].location != NSNotFound) {
                [self raiseExeption];
            }
        }
    }];
    [dataTask resume];
}

-(void)raiseExeption {
    self.is_verify_purchase_code = false;
}


#pragma mark - OPENVPN
-(void)openVPNconfigure:(NSString *)serverAddress data:(NSData *)data {
    [self openVPNconfigure:serverAddress data:data username:nil password:nil keyPassphrase:nil];
}

-(void)openVPNconfigure:(NSString *)serverAddress
                   data:(NSData *)data
               username:(NSString * _Nullable)username
               password:(NSString * _Nullable)password
           keyPassphrase:(NSString * _Nullable)keyPassphrase {
    if (self.is_verify == false) {
        [self raiseExeption];
    }
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (!error) {
            NETunnelProviderProtocol *tunnelProtocol = [NETunnelProviderProtocol new];
            tunnelProtocol.serverAddress = serverAddress;
            tunnelProtocol.providerBundleIdentifier = [NSString stringWithFormat:@"%@.PacketTunnelProvider", [[NSBundle mainBundle] bundleIdentifier]];
            NSMutableDictionary *providerConfig = [@{ @"ovpn": data } mutableCopy];
            if (username) { providerConfig[@"username"] = username; }
            if (password) { providerConfig[@"password"] = password; }
            if (keyPassphrase) { providerConfig[@"pkiPassphrase"] = keyPassphrase; }
            tunnelProtocol.providerConfiguration = providerConfig;
            tunnelProtocol.disconnectOnSleep = false;
            self.providerManager.protocolConfiguration = tunnelProtocol;
            self.providerManager.localizedDescription = @"Wit VPN";
            self.providerManager.enabled = true;
            [self.providerManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    if (!error) {
                        NSError *err_conn;
                        [self.providerManager.connection startVPNTunnelAndReturnError:&err_conn];
                        if (err_conn) {
                            NSLog(@"ERROR: configureVPN: %@", err_conn.localizedDescription);
                        }
                    }
                }];
            }];
        }
    }];
}

/*---------------------------------------------------------------------------------------------------------
  Method initialize 'NETunnelProviderManager *providerManager'
 ---------------------------------------------------------------------------------------------------------*/
- (void) loadProviderManager:(void (^)(void))finishBlock
{
    __weak typeof(self) weak = self;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       weak.log = os_log_create("app.witwork.strongvpn", "ios_app");
    });
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVpnStateChange:) name:NEVPNStatusDidChangeNotification object:NULL];

    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager*>* _Nullable managers, NSError* _Nullable error) {
        if(error){
            NSLog(@"loadAllFromPreferencesWithCompletionHandler error: %@",error); return;
        }

         weak.providerManager = managers.firstObject ? managers.firstObject : [NETunnelProviderManager new];
        [weak.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            if(error){
                NSLog(@"weak.providerManager loadAllFromPreferencesWithCompletionHandler error: %@",error); return;
            }
            [weak.providerManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                NSLog(@"%@", (error) ? @"Saved with error" : @"Save successfully");
                finishBlock();
            }];
        }];
    }];
}
/*---------------------------------------------------------------------------------------------------------
  Unistall managers
 ---------------------------------------------------------------------------------------------------------*/
- (void) uninstallVPNConfigurationFromManagers
{

    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager*>* _Nullable managers, NSError * _Nullable error) {
        if (error != nil) {
            os_log_debug(self.log, "ERROR Uninstall vpn config: %{public}@", error.localizedDescription);
            return;
        }
        for (NETunnelProviderManager *manager in managers) {
            [manager removeFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                if (error != nil) {
                    os_log_debug(self.log, "ERROR Uninstall vpn config: %{public}@", error.localizedDescription);
                    return;
                } else {
                    os_log_debug(self.log, "Successful uninstall %{public}@", manager.description);
                }
            }];
        }
        os_log_debug(self.log, "Uninstalled vpn config");
    }];
}
/*---------------------------------------------------------------------------------------------------------
  Start connection
 ---------------------------------------------------------------------------------------------------------*/
- (void) startConnection:(void(^)(void))completion
{
    __weak typeof(self) weak = self;
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if(error){
            NSLog(@"weak.providerManager loadAllFromPreferencesWithCompletionHandler error: %@",error); return;
        }
        [weak.providerManager.connection startVPNTunnelAndReturnError:&error];
        NSLog(@"%@", (error) ? @"Saved with error" : @"Connection established!");
    }];
}
/*---------------------------------------------------------------------------------------------------------
  Stop connection
 ---------------------------------------------------------------------------------------------------------*/
- (void) stopConnection:(void(^)(void))completion
{
    __weak typeof(self) weak = self;
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if(error){
            NSLog(@"weak.providerManager loadAllFromPreferencesWithCompletionHandler error: %@",error); return;
        }
        [weak.providerManager.connection stopVPNTunnel];
        NSLog(@"stopVPNTunnel");
    }];
}

#pragma mark - Helpers
/*---------------------------------------------------------------------------------------------------------
  Convert Connection.Status to NSString
 ---------------------------------------------------------------------------------------------------------*/
-(void)onVpnStateChange:(NSNotification *)Notification {
    
    switch (self.providerManager.connection.status) {
        case NEVPNStatusInvalid:
            NSLog(@"NEVPNStatusInvalid");
            break;
        case NEVPNStatusDisconnected:
            NSLog(@"NEVPNStatusDisconnected");
            break;
        case NEVPNStatusConnecting:
            NSLog(@"NEVPNStatusConnecting");
            break;
        case NEVPNStatusConnected:
            NSLog(@"NEVPNStatusConnected");
            break;
        case NEVPNStatusDisconnecting:
            NSLog(@"NEVPNStatusDisconnecting");
            break;
        case NEVPNStatusReasserting:
            NSLog(@"******************ReConnecting****************");
            break;
        default:
            break;
    }
}


@end
