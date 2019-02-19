//
//  BaseAPI.swift
//  Millcare
//
//  Created by Shithin PV on 08/02/18.
//  Copyright © 2018 Focaloid. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import KSToastView



class BaseApi: NSObject {
    
    typealias RequestCompletion = (_ error: APIResultStatus?, _ data: AnyObject?) -> Void
    var completionBlock: RequestCompletion!
    var requestMethod: HTTPMethod!
    var requestUrl: String!
    var requestObj: Mappable?
    var hadRetried = false
    var isObjectMapper = true
    let isDevelopment = false
    var showLoading = true
    var showErrorMessage = true
    
    func processResponse(response:  Any?) -> BaseApiResponse{
        assert(false, "This method must be overriden by the subclass")
        let response: BaseApiResponse! = nil
        return response
    }
    
    func setupBaseUrl() {
        if isDevelopment{
            requestUrl = ApiPaths.baseUrlDev+requestUrl
        }
        else{
            requestUrl = ApiPaths.baseUrlProd+requestUrl
        }
    }
    
    func processResponseMappable(response: Any?) -> AnyObject{
        let response: AnyObject! = nil
        return response
    }
    
    func getHeader() -> Dictionary<String, String>?{
        
        var headers: HTTPHeaders = [:]
        
       headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        if ACCESSTOKEN != ""{
            headers["user-token"] = ACCESSTOKEN
        }
        return headers
    }
    
    func getEncoding() -> ParameterEncoding{
        //Alamofire.ParameterEncoding =  JSONEncoding.default
        if requestMethod == .get {
            return URLEncoding.default
        }else if requestMethod == .post{
            return URLEncoding.default
        }
        
        return URLEncoding.default
    }
    
    
    func performApi(completion: @escaping RequestCompletion) -> Void{
        self.setupBaseUrl()
        self.completionBlock = completion
        
        let rechability = NetworkReachabilityManager()
        
        if rechability?.isReachable == false {
            self.showToast("No Network available!")
            self.completionBlock(APIResultStatus.networkIssue, nil)
            return
        }
        
        
        var params :[String:Any]? = [:]
        
        if requestObj != nil {
            params = (requestObj?.toJSON())!
        }
        else{
            params = nil
        }
       
        
        print("############### Api Call ##################")
        print("Req Url",requestUrl)
        print("Params", params)
        print("Req Method", requestMethod)
        print("Headers", getHeader())
        print("*******************************************")
        if showLoading{
            //E3ProgressHUD.shared.showClassicLoading()
        }
        
        
        request(requestUrl, method: requestMethod, parameters: (params == nil ? nil : params!), encoding: getEncoding(), headers: getHeader()).responseJSON { (response: DataResponse<Any>) in
            
            print("############### Api Call Response ##################")
            print("Result:", response.result.value as Any)
            print("Status code", response.response?.statusCode)
            print("*******************************************")
            if self.showLoading{
                //E3ProgressHUD.shared.dismiss()
            }
           
            
            if response.result.isSuccess  {
                guard let infoFromApiCall = response.result.value as? [String:Any] else{
                    return
                }
                // if error occured
                if let status = infoFromApiCall["status"] as? Int{
                    if status == 10 || status == 13{
                        if let errorMessage = infoFromApiCall["message"] as? String{
                            if self.showErrorMessage{
                                self.showToast(errorMessage)
                            }
                        }
                        if status == 10{
                            self.completionBlock(APIResultStatus.failure, nil)
                        }
                        else if status == 13{
                            let appDelegate = UIApplication.shared.delegate as? AppDelegate
                            //appDelegate?.logout()
                            self.cancelAPIRequests()
                            self.completionBlock(APIResultStatus.tokenIssue, nil)
                        }
                        return
                    }
                }
                
                //api call is sucess
                if self.isObjectMapper == false{
                    if response.data?.count != 0 {
                        let responseData = self.processResponseMappable(response: infoFromApiCall)
                        self.completionBlock(APIResultStatus.success, responseData as AnyObject)
                    }else{
                        self.showToast("Something went wrong!!")
                        self.completionBlock(APIResultStatus.failure, nil)
                    }
                    
                }else{
                        let responseData = self.processResponse(response: infoFromApiCall)
                        self.completionBlock(APIResultStatus.success, responseData as AnyObject)
                }
                
            }
            
        }
        
    }
    
    func requestNew(completion: @escaping RequestCompletion) -> Void{
        
        self.setupBaseUrl()
        self.completionBlock = completion
        
        let rechability = NetworkReachabilityManager()
        
        if rechability?.isReachable == false {
            self.showToast("No Network available!")
            self.completionBlock(APIResultStatus.networkIssue, nil)
            return
        }
        
        
        var params :[String:Any] = [:]
        
        if requestObj != nil {
            params = (requestObj?.toJSON())!
        }
        var headers: HTTPHeaders = [:]
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["user-token"] = ACCESSTOKEN
        headers["Accept"] = "application/json"
        request(requestUrl, method: .post, parameters: params, encoding: URLEncoding.default, headers: headers).responseJSON {
            response in
            
        }
        
        
    }
    
    func showToast(_ message:String?){
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            KSToastView.ks_showToast(message ?? "")
        }
    }
    
    
    
    
    //To cancel All api calls
    func cancelAPIRequests(){
        defaultManager.session.getAllTasks{ (task) in
            task.forEach{$0.cancel()}
        }
    }
    
    //To cancel specific api calls. Should specify a part of url
    func cancelAPICallsContaining(string:String,completion:(()->Void)? = nil){
        
        defaultManager.session.getAllTasks
            { (task) in
                task.forEach{
                    if ($0.originalRequest?.url?.absoluteString.contains(string) == true){
                        $0.cancel()
                    }
                }
                DispatchQueue.main.async {
                    completion?()
                }
        }
    }
    
    func multipartRequest(imagesToBeUploded: [UIImage]?,imageParameter:String, imageWillBeAlwaysOne:Bool = false,completion: @escaping RequestCompletion) -> Void{
        
        self.setupBaseUrl()
        self.completionBlock = completion
        
        let rechability = NetworkReachabilityManager()
        
        if rechability?.isReachable == false {
            self.showToast("No Network available!")
            self.completionBlock(APIResultStatus.networkIssue, nil)
            return
        }
        
        if showLoading{
            //E3ProgressHUD.shared.showClassicLoading()
        }
        
        var params :[String:Any] = [:]
        
        if requestObj != nil {
            params = (requestObj?.toJSON())!
        }
        
        
        var headers : [String:String] = ["Content-Type" : "multipart/form-data"]

        headers["user-token"] = ACCESSTOKEN
        
        print("############### Api Call ##################")
        print("Req Url",requestUrl)
        print("Params", params)
        print("Req Method", requestMethod)
        print("Headers", headers)
        print("*******************************************")
        
        Alamofire.upload(multipartFormData:{ multipartFormData in
            if let image = imagesToBeUploded{
                if image.count == 1 && imageWillBeAlwaysOne{
                    if let currentImageData = image[0].jpegData(compressionQuality: 0.7){
                        multipartFormData.append(currentImageData, withName: imageParameter, fileName: "file.jpeg", mimeType: "image/jpeg")
                    }
                }else{
                    var index = 1
                    image.forEach({ (currentImage) in
                        if let currentImageData = currentImage.jpegData(compressionQuality: 0.7){
                            multipartFormData.append(currentImageData, withName: imageParameter+"\(index)", fileName: "file"+"\(index)"+".jpg", mimeType: "image/jpeg")
                            index += 1
                        }
                    })
                }
                
            }
            for (key, value) in params{
                if let value = value as? String{
                    multipartFormData.append((value.data(using: .utf8))!, withName: key)
                }
                
                
            }}, to: requestUrl, method: .post, headers: headers,
                encodingCompletion: { encodingResult in
                    
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON{
                            response in
                            if self.showLoading{
                                //E3ProgressHUD.shared.dismiss()
                            }
                            print("############### Api Call Response ##################")
                            print("Result:", response.result.value as Any)
                            print("Status code", response.response?.statusCode)
                            print("*******************************************")
                            switch response.result{
                            case .success(let JSON):
                                if let infoFromApiCall = JSON as? Dictionary<String, Any>{
                                    if self.isObjectMapper == false{
                                        if response.data?.count != 0 {
                                            let responseData = self.processResponseMappable(response: infoFromApiCall)
                                            self.completionBlock(APIResultStatus.success, responseData as AnyObject)
                                        }else{
                                            self.showToast("Something went wrong!!")
                                            self.completionBlock(APIResultStatus.failure, nil)
                                        }
                                        
                                    }else{
                                        let responseData = self.processResponse(response: infoFromApiCall)
                                        self.completionBlock(APIResultStatus.success, responseData as AnyObject)
                                    }
                                }
                            case .failure:
                                self.completionBlock(APIResultStatus.failure,nil)
                            }
                        }
                        upload .responseString(completionHandler:{ (result) in
                        })
                        
                    case .failure:
                        self.completionBlock(APIResultStatus.failure,nil)
                    }
        })
        
    }
    
    // parameter type Array
    func requestJsonArray(completion: @escaping RequestCompletion) -> Void{
        self.setupBaseUrl()
        self.completionBlock = completion
        let request = NSMutableURLRequest(url: URL(string: requestUrl)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        if userdefaultsModel.accessToken != ""{
//            request.setValue(userdefaultsModel.accessToken, forHTTPHeaderField: "sec_key")
//        }
        var params :[String:Any] = [:]
        
        if requestObj != nil {
            params = (requestObj?.toJSON())!
        }
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        request.timeoutInterval = 40
        let convertibleRequest = MLURLRequestConvertible()
        
        convertibleRequest.request = request as URLRequest
        
        Alamofire.request(convertibleRequest).responseJSON
            { response in
               
                switch response.result
                {
                case .success(let JSON):
                    
                        guard let infoFromApiCall = JSON as? [String:Any] else{
                            return
                        }
                        if let success = infoFromApiCall["success"] as? [String:Any]{
                            if  let status = success["success"] as? String,status == "False"{
                                self.showToast(success["message"] as? String)
                            }
                            if let message = success["message"] as? String, message == "Authentication Failed"{
                                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                                //appDelegate?.logout()
                            }
                        }
                        
                        if self.isObjectMapper == false{
                            if response.data?.count != 0 {
                                let responseData = self.processResponseMappable(response: infoFromApiCall)
                                self.completionBlock(APIResultStatus.success, responseData as AnyObject)
                            }else{
                                self.showToast("Something went wrong!!")
                                self.completionBlock(APIResultStatus.failure, nil)
                            }
                            
                        }else{
                            let responseData = self.processResponse(response: infoFromApiCall)
                            self.completionBlock(APIResultStatus.success, responseData as AnyObject)
                        }
                    
                case .failure(let error):
                    
                    self.showToast("Server not responding. Please try later")
                }
        }
    }
    
    let defaultManager: Alamofire.SessionManager = {
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            "" : .disableEvaluation
            //            BASE_URL_P: .disableEvaluation
        ]
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 120 // seconds
        configuration.timeoutIntervalForResource = 120
        
        return Alamofire.SessionManager(
            configuration: configuration,
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
    }()
    
        
    
    
}

class MLURLRequestConvertible : URLRequestConvertible{
    
    var request : URLRequest?
    func asURLRequest() throws -> URLRequest{
        
        return request!
    }
}

enum APIResultStatus{
    case success
    case failure
    case tokenIssue
    case networkIssue
}


