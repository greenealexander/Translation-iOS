//
//  AppDelegate.swift
//  Japanese
//
//  Created by Alexander Greene on 11/16/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		let navigationBarAppearace = UINavigationBar.appearance()
		let tabBarAppearance = UITabBar.appearance()

		let tintColor = UIColor(named: "accent")
		let barTintColor = UIColor(named: "background")

		navigationBarAppearace.tintColor = tintColor
		tabBarAppearance.tintColor = tintColor

		navigationBarAppearace.barTintColor = barTintColor
		tabBarAppearance.barTintColor = barTintColor

		// change navigation item title color
		if let foregroundColor = UIColor(named: "foreground") {
			navigationBarAppearace.titleTextAttributes = [NSAttributedString.Key.foregroundColor: foregroundColor]
		}

		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}

