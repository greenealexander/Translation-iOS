//
//  KanjiInfoHeaderView.swift
//  Japanese
//
//  Created by Alexander Greene on 12/5/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SnapKit

class KanjiInfoHeaderView: UIView {
	var kanjiInfo: KanjiInfo? {
		didSet {
			guard let kanjiInfo = kanjiInfo else { return }
			kanjiLabel.text = kanjiInfo.kanji
			kunyomi.text = kanjiInfo.kunyomi
			meaning.text = kanjiInfo.meaning
			strokeCount.text = "(\(kanjiInfo.numStrokes))"
		}
	}

	private let kanjiLabel: UILabel = {
		let label = UILabel()
		label.adjustsFontForContentSizeCategory = true
		label.font = UIFont.systemFont(ofSize: 80, weight: UIFont.Weight.semibold)
		return label
	}()

	private let meaningLabel: UILabel = {
		let label = UILabel()
		label.adjustsFontForContentSizeCategory = true
		label.text = "Meaning"
		label.textColor = UIColor(named: "accent")
		return label
	}()

	private let meaning: UILabel = {
		let label = UILabel()
		label.adjustsFontForContentSizeCategory = true
		label.numberOfLines = 0
		return label
	}()

	private let kunyomiLabel: UILabel = {
		let label = UILabel()
		label.adjustsFontForContentSizeCategory = true
		label.text = "Kunyomi"
		label.textColor = UIColor(named: "accent")
		return label
	}()

	private let kunyomi: UILabel = {
		let label = UILabel()
		label.adjustsFontForContentSizeCategory = true
		label.numberOfLines = 0
		return label
	}()

	private let strokeCount: UILabel = {
		let label = UILabel()
		label.adjustsFontForContentSizeCategory = true
		label.textAlignment = .center
		return label
	}()

	override func layoutSubviews() {
		super.layoutSubviews()

		[kanjiLabel, meaningLabel, meaning, kunyomiLabel, kunyomi, strokeCount].forEach {
			$0.translatesAutoresizingMaskIntoConstraints = false
			addSubview($0)
		}

		kanjiLabel.snp.makeConstraints {
			$0.left.top.equalTo(self).offset(16)
			$0.width.equalTo(80)
		}

		meaningLabel.snp.makeConstraints {
			$0.left.equalTo(kanjiLabel.snp.right).offset(8)
			$0.top.equalTo(kanjiLabel)
			$0.right.equalTo(self).offset(-16)
		}

		meaning.snp.makeConstraints {
			$0.left.right.equalTo(meaningLabel)
			$0.top.equalTo(meaningLabel.snp.bottom).offset(8)
		}

		kunyomiLabel.snp.makeConstraints {
			$0.right.left.equalTo(meaningLabel)
			$0.top.equalTo(meaning.snp.bottom).offset(16)
		}

		kunyomi.snp.makeConstraints {
			$0.top.equalTo(kunyomiLabel.snp.bottom).offset(8)
			$0.left.right.equalTo(meaningLabel)
		}

		strokeCount.snp.makeConstraints {
			$0.top.equalTo(kanjiLabel.snp.bottom)
			$0.left.right.equalTo(kanjiLabel)
			$0.bottom.equalTo(self).offset(-16)
		}
	}
}
