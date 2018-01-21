/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import Foundation
import ObjectMapper

public struct Request: Mappable {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private struct SerializationKeys {
        static let service = "service"
        static let status = "status"
        static let destinationLat = "destinationLat"
        static let destination = "destination"
        static let customerRideId = "customerRideId"
        static let pickup = "pickup"
        static let destinationLng = "destinationLng"
        static let pickupLng = "pickupLng"
        static let pickupLat = "pickupLat"
        static let historyId = "historyId"
    }
    
    // MARK: Properties
    public var service: Int?
    public var status: String?
    public var destination: String?
    public var customerRideId: String?
    public var pickup: String?
    public var destinationLat: Double?
    public var destinationLng: Double?
    public var pickupLng: Double?
    public var pickupLat: Double?
    public var historyId: String?

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
        service <- map[SerializationKeys.service]
        status <- map[SerializationKeys.status]
        destinationLat <- map[SerializationKeys.destinationLat]
        destination <- map[SerializationKeys.destination]
        customerRideId <- map[SerializationKeys.customerRideId]
        pickup <- map[SerializationKeys.pickup]
        destinationLng <- map[SerializationKeys.destinationLng]
        pickupLng <- map[SerializationKeys.pickupLng]
        pickupLat <- map[SerializationKeys.pickupLat]
        historyId <- map[SerializationKeys.historyId]
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        if let value = service { dictionary[SerializationKeys.service] = value }
        if let value = status { dictionary[SerializationKeys.status] = value }
        if let value = destinationLat { dictionary[SerializationKeys.destinationLat] = value }
        if let value = destination { dictionary[SerializationKeys.destination] = value }
        if let value = customerRideId { dictionary[SerializationKeys.customerRideId] = value }
        if let value = pickup { dictionary[SerializationKeys.pickup] = value }
        if let value = destinationLng { dictionary[SerializationKeys.destinationLng] = value }
        if let value = pickupLng { dictionary[SerializationKeys.pickupLng] = value }
        if let value = pickupLat { dictionary[SerializationKeys.pickupLat] = value }
        if let value = historyId { dictionary[SerializationKeys.historyId] = value }
        return dictionary
    }
    
}

