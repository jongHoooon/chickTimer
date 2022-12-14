//
//  TimerRouter.swift
//  HongikTimer
//
//  Created by JongHoon on 2022/11/20.
//

import Foundation
import Alamofire

enum TimerRouter: URLRequestConvertible {
  
  // MARK: - Property
  var baseURL: URL {
    return URL(string: APIClient.BASE_URL)!
  }
  
  // MARK: - Cases
  ///  홈 화면에서 목표 작성시 저장
  case saveGoal(_ request: SaveGoalRequest)
  
  case postTime(second: Int)
  case getTodayTime
  
  // MARK: - End Point
  
  var path: String {
    switch self {
    case .saveGoal:                return "members/goal/\(APIClient.getid())"
    case .postTime, .getTodayTime:
      return "timer/\(APIClient.getid())"
    }
  }
  
  // MARK: - Method
  
  var method: HTTPMethod {
    switch self {
    case .saveGoal:                   return .post
    case .postTime:
      return .post
    case .getTodayTime:
      return .get
    }
  }
  
  // MARK: - Parameters
  
  var parameters: Parameters? {
    var params = Parameters()
    switch self {
    case let .saveGoal(req):      return req.parametrs
    case let .postTime(second):
      params["time"] = second
    case .getTodayTime:
      return nil
    }
    return params
  }
  
  // MARK: - URL Request
  func asURLRequest() throws -> URLRequest {
    
    var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
    
    urlRequest.method = self.method
    urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("\(APIClient.getToekn())", forHTTPHeaderField: "X-AUTH")
    urlRequest.httpBody = try JSONEncoding.default.encode(urlRequest, with: parameters).httpBody
    
    print(APIClient.getToekn())
    print(APIClient.getid())
    
    return urlRequest
  }
}
