//
//  GetSingleOrderDetailsResponse.swift
//  IvfEcho
//
//  Created by Shithin_Focaloid on 11/02/19.
//  Copyright © 2019 Hashinclude. All rights reserved.
//

import Foundation
import ObjectMapper

class SampleResponse: BaseApiResponse {
    
    var id : Int?
    var createdAt : String?
    
    
    override func mapping(map: Map) {
            id <- map["id"]
        
        createdAt <- map["createdAt"]
    }
}
