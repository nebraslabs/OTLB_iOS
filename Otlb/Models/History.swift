/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import Foundation
import ObjectMapper

public struct History: Mappable {

  // MARK: Declaration for string constants to be used to decode and also serialize.
  private struct SerializationKeys {
    static let service = "service"
    static let status = "status"
    static let location = "location"
    static let destination = "destination"
    static let pickup = "pickup"
    static let distance = "distance"
    static let driver = "driver"
    static let rating = "rating"
    static let customer = "customer"
    static let timestamp = "timestamp"
  }

  // MARK: Properties
  public var service: String?
  public var status: String?
  public var location: HistoryLocation?
  public var destination: String?
  public var pickup: String?
  public var distance: String?
  public var driver: String?
  public var rating: String?
  public var customer: String?
  public var timestamp: Double?

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
    location <- map[SerializationKeys.location]
    destination <- map[SerializationKeys.destination]
    pickup <- map[SerializationKeys.pickup]
    distance <- map[SerializationKeys.distance]
    driver <- map[SerializationKeys.driver]
    rating <- map[SerializationKeys.rating]
    customer <- map[SerializationKeys.customer]
    timestamp <- map[SerializationKeys.timestamp]
  }

  /// Generates description of the object in the form of a NSDictionary.
  ///
  /// - returns: A Key value pair containing all valid values in the object.
  public func dictionaryRepresentation() -> [String: Any] {
    var dictionary: [String: Any] = [:]
    if let value = service { dictionary[SerializationKeys.service] = value }
    if let value = status { dictionary[SerializationKeys.status] = value }
    if let value = location { dictionary[SerializationKeys.location] = value.dictionaryRepresentation() }
    if let value = destination { dictionary[SerializationKeys.destination] = value }
    if let value = pickup { dictionary[SerializationKeys.pickup] = value }
    if let value = distance { dictionary[SerializationKeys.distance] = value }
    if let value = driver { dictionary[SerializationKeys.driver] = value }
    if let value = rating { dictionary[SerializationKeys.rating] = value }
    if let value = customer { dictionary[SerializationKeys.customer] = value }
    if let value = timestamp { dictionary[SerializationKeys.timestamp] = value }
    return dictionary
  }

}

public struct HistoryLocation: Mappable {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private struct SerializationKeys {
        static let to = "to"
        static let from = "from"
    }
    
    // MARK: Properties
    public var to: HistoryLatLng?
    public var from: HistoryLatLng?
    
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
        to <- map[SerializationKeys.to]
        from <- map[SerializationKeys.from]
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        if let value = to { dictionary[SerializationKeys.to] = value.dictionaryRepresentation() }
        if let value = from { dictionary[SerializationKeys.from] = value.dictionaryRepresentation() }
        return dictionary
    }
    
}

public struct HistoryLatLng: Mappable {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private struct SerializationKeys {
        static let lat = "lat"
        static let lng = "lng"
    }
    
    // MARK: Properties
    public var lat: Double?
    public var lng: Double?
    
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
        lat <- map[SerializationKeys.lat]
        lng <- map[SerializationKeys.lng]
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        if let value = lat { dictionary[SerializationKeys.lat] = value }
        if let value = lng { dictionary[SerializationKeys.lng] = value }
        return dictionary
    }
    
}
