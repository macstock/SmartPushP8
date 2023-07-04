//
//  JWTManager.swift
//  SmartPush
//
//  Created by js on 2023/7/3.
//  Copyright © 2023 www.skyfox.org. All rights reserved.
//

import Foundation

@objc public class JWTManager : NSObject {
    @objc public class func token(keyId:String, teamId:String, p8String:String) -> String{
        
        if keyId.isEmpty {
            return ""
        }
        
        if teamId.isEmpty {
            return ""
        }
        
        let jwt = JWT(keyID: keyId, teamID: teamId, issueDate: Date(), expireDuration: 60 * 60)
        var token : String = ""
        do {
            token = try jwt.sign(with: p8String)
        } catch {
            print("生成token 失败")
        }
          
        return token
    }
    
    @objc public class func isP8File(path:String) -> Bool {
        if path.isEmpty {
            return false
        }
        
        var isP8File = false
        let path = path.lowercased()
        isP8File = path.hasSuffix(".p8")
        return isP8File
    }
    
}
