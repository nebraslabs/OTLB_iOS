/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import Foundation
import ObjectMapper
import EVReflection

public final class User: EVObject, Mappable {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private struct SerializationKeys {
        static let phone = "phone"
        static let name = "name"
        static let profileImageUrl = "profileImageUrl"
        static let serviceProvider = "serviceProvider"
    }
    
    // MARK: Properties
    public var phone: String?
    public var name: String?
    public var profileImageUrl: String?
    public var serviceProvider: Bool?

    // MARK: ObjectMapper Initializers
    /// Map a JSON object to this class using ObjectMapper.
    ///
    /// - parameter map: A mapping from ObjectMapper.
    public required init?(map: Map){
        
    }
    
    /// Map a JSON object to this class using ObjectMapper.
    ///
    /// - parameter map: A mapping from ObjectMapper.
    public func mapping(map: Map) {
        phone <- map[SerializationKeys.phone]
        name <- map[SerializationKeys.name]
        profileImageUrl <- map[SerializationKeys.profileImageUrl]
        serviceProvider <- map[SerializationKeys.serviceProvider]
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        if let value = phone { dictionary[SerializationKeys.phone] = value }
        if let value = name { dictionary[SerializationKeys.name] = value }
        if let value = profileImageUrl { dictionary[SerializationKeys.profileImageUrl] = value }
        if let value = serviceProvider { dictionary[SerializationKeys.serviceProvider] = value }
        return dictionary
    }
    
    // MARK: NSCoding Protocol
    required public init(coder aDecoder: NSCoder) {
        self.phone = aDecoder.decodeObject(forKey: SerializationKeys.phone) as? String
        self.name = aDecoder.decodeObject(forKey: SerializationKeys.name) as? String
        self.profileImageUrl = aDecoder.decodeObject(forKey: SerializationKeys.profileImageUrl) as? String
        self.serviceProvider = aDecoder.decodeObject(forKey: SerializationKeys.serviceProvider) as? Bool
    }
    
    required public init() {
        fatalError("init() has not been implemented")
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(phone, forKey: SerializationKeys.phone)
        aCoder.encode(name, forKey: SerializationKeys.name)
        aCoder.encode(profileImageUrl, forKey: SerializationKeys.profileImageUrl)
        aCoder.encode(serviceProvider, forKey: SerializationKeys.serviceProvider)
    }
    
}

