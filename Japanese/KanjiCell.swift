//
//  KanjiCell.swift
//  Japanese
//
//  Created by Alexander Greene on 12/5/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SnapKit

class KanjiCell: UICollectionViewCell {
	static let identifier = "KanjiCell"

	var kanji: String? {
		didSet {
			kanjiLabel.text = kanji
		}
	}

	private let kanjiLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.textColor = UIColor(named: "foreground")
		label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title2)
		label.textAlignment = .center
		label.adjustsFontForContentSizeCategory = true
		return label
	}()

	override func layoutSubviews() {
		super.layoutSubviews()

		backgroundColor = UIColor(named: "background")
		layer.cornerRadius = 8
		layer.shadowColor = UIColor(named: "accent")?.withAlphaComponent(0.3).cgColor
		layer.shadowOffset = .init(width: 0, height: 4)
		layer.shadowRadius = 4
		layer.shadowOpacity = 1

		addSubview(kanjiLabel)

		kanjiLabel.snp.makeConstraints {
			$0.top.left.equalTo(self).offset(8)
			$0.right.bottom.equalTo(self).offset(-8)
		}
	}
}
