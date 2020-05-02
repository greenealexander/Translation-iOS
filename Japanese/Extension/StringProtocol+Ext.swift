//
//  StringProtocol+Ext.swift
//  Japanese
//
//  Created by Alexander Greene on 12/6/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import Foundation

extension StringProtocol {
	subscript(_ offset: Int) -> Element { self[index(startIndex, offsetBy: offset)] }
}
