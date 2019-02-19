//
//  SampleApi.swift
//  IvfEcho
//
//  Created by Shithin_Focaloid on 11/02/19.
//  Copyright © 2019 Hashinclude. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class SampleApi: BaseApi {
    
    func get(request:SampleRequest,showActivity:Bool = true,completion: @escaping RequestCompletion){
        requestUrl = ApiPaths.sampleApi
        requestMethod = .post
        requestObj = request
        showLoading = showActivity
        super.performApi(completion: completion)
    }
    override func processResponse(response: Any?) -> BaseApiResponse {
        let responseDetails = Mapper<SampleResponse>().map(JSONObject: response)
        return responseDetails!
    }
}
