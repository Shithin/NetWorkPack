//
//  SampleRequest.swift
//  IvfEcho
//
//  Created by Shithin_Focaloid on 11/02/19.
//  Copyright © 2019 Hashinclude. All rights reserved.
//

import Foundation
import ObjectMapper

class SampleRequest: Mappable {
    
    var orderId: String?
    
    required init?(map: Map) {
        
    }
    
    init() {
    }
    
    func mapping(map: Map) {
        orderId       <- map["order_id"]
    }
}
