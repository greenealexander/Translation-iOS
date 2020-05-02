//
//  AppTabBarController.swift
//  Japanese
//
//  Created by Alexander Greene on 12/5/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SwiftUI

class AppTabBarController: UITabBarController {

	enum Tabs: CaseIterable {
		case makeChoice
		case about

		var controller: UIViewController {
			switch self {
			case .makeChoice: return MakeInterpretationChoiceController()
			case .about: return UIHostingController(rootView: AboutView())
			}
		}

		var image: UIImage? {
			switch self {
			case .makeChoice: return UIImage(systemName: "doc.text.magnifyingglass")
			case .about: return UIImage(systemName: "info.circle")
			}
		}

		var label: String {
			switch self {
			case .makeChoice: return "Text"
			case .about: return "About"
			}
		}

		var title: String? {
			switch self {
			case .about: return "About"
			default: return nil
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tabBar.tintColor = UIColor(named: "accent")
		tabBar.isTranslucent = false

		viewControllers = Tabs.allCases.map { type -> UINavigationController in
			let controller = type.controller
			controller.navigationItem.title = type.title
			let navController = UINavigationController(rootViewController: controller)
			navController.tabBarItem.image = type.image
			navController.tabBarItem.imageInsets = UIEdgeInsets(top: 16, left: 0, bottom: -16, right: 0)
			navController.tabBarItem.title = type.label
			navController.navigationBar.isTranslucent = false
			navController.navigationBar.tintColor = UIColor(named: "foreground")
			return navController
		}

	}
}
