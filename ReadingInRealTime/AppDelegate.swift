//
//  AppDelegate.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/15.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 화이트 테마 유지
        if #available(iOS 13.0, *){
            window?.overrideUserInterfaceStyle = .light
        }
        
        return true
    }
}

