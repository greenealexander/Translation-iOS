//
//  JapaneseWordCell.swift
//  Japanese
//
//  Created by Alexander Greene on 11/16/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import SwiftUI
import SnapKit

//let font = UIFont.systemFont(ofSize: 24)
let font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title2)

class JapaneseWordCell: UICollectionViewCell {
	static let identifier = "JapeneseWordCell"

	var token: Token?
	var pair: TokenTuple?

	func configureCell(pair: TokenTuple) {
		self.pair = pair
		wordLabel.text = self.pair?.0.string

		let partOfSpeech = PartsOfSpeech.init(rawValue: pair.1.partOfSpeech ?? "")

		switch partOfSpeech {
		case .particle, .special:
			wordLabel.textColor = UIColor(named: "foreground")?.withAlphaComponent(0.6)
		default:
			wordLabel.textColor = UIColor(named: "foreground")
		}
	}

	override var isSelected: Bool {
		didSet {
			if let text = token?.surface {
				underlineText(text: text, isSelected: isSelected)
				return
			}
		}
	}

	func underlineText(text: String, isSelected: Bool) {
		print("Text: ", text)
		let textRange = NSMakeRange(0, text.count)
		let attributedText = NSMutableAttributedString(string: text)

		if isSelected {
			attributedText.addAttribute(NSAttributedString.Key.underlineStyle , value: NSUnderlineStyle.single.rawValue, range: textRange)
		} else {
			attributedText.removeAttribute(NSAttributedString.Key.underlineStyle, range: textRange)
		}

		// Add other attributes if needed
		wordLabel.attributedText = attributedText
	}

	let wordLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = font
		label.adjustsFontSizeToFitWidth = true
		label.adjustsFontForContentSizeCategory = true
		return label
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)

		contentView.addSubview(wordLabel)
		wordLabel.snp.makeConstraints {
			$0.top.left.right.bottom.equalTo(contentView)
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


