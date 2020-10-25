import Foundation

public class AppleMusicAPI {
    public static let manager = AppleMusicAPI()
    
    private init() {}
    
    private var developerToken: String?
    private var userToken: String?
    private var storefront: String?
    
    public func initialize(developerToken: String, userToken: String, storefront: String) {
        self.developerToken = developerToken
        self.userToken = userToken
        self.storefront = storefront
    }
}
