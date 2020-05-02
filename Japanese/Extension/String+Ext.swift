//
//  String+Ext.swift
//  Japanese
//
//  Created by Alexander Greene on 11/28/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit

extension String {
	func removeWhiteSpace() -> String {
		return self.components(separatedBy: .whitespacesAndNewlines)
		.filter { !$0.isEmpty }
		.joined(separator: "")
	}

	func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
			let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
			let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

			return ceil(boundingBox.height)
	}

	func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
			let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
			let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

			return ceil(boundingBox.width)
	}
}
