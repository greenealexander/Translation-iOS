//
//  String+Ext.swift
//  Japanese
//
//  Created by Alexander Greene on 11/28/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import Foundation

extension String {
	func removeWhiteSpace() -> String {
		return self.components(separatedBy: .whitespacesAndNewlines)
		.filter { !$0.isEmpty }
		.joined(separator: "")
	}
}
