/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import Foundation
import ObjectMapper

public struct DriversQueue: Mappable {
    // MARK: Properties
    public var active: String!
    public var queued: [String]!
    public var cancelled: [String]!

    // MARK: ObjectMapper Initializers
    /// Map a JSON object to this class using ObjectMapper.
    ///
    /// - parameter map: A mapping from ObjectMapper.
    public init?(map: Map){
        
    }
    
    /// Map a JSON object to this class using ObjectMapper.
    ///
    /// - parameter map: A mapping from ObjectMapper.
    public mutating func mapping(map: Map) {
        active <- map["active"]
        queued <- map["queued"]
        cancelled <- map["cancelled"]
    }
}
