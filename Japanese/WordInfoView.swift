//
//  WordInfoView.swift
//  Japanese
//
//  Created by Alexander Greene on 12/5/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SnapKit

class WordInfoView: UIView {
	var token: Token? {
		didSet {
			wordLabel.text = token?.surface
			kanjiCharacters = token?.surface.compactMap {
				if !Constants.NON_KANJI_CHARACTERS.keys.contains($0.string) {
					return $0.string
				}
				return nil
			}
		}
	}

	var didSelectKanjiDelegate: DidSelectKanjiDelegate?

	var meaningTextBottomConstraint: Constraint?

	var kanjiCharacters: [String]? {
		didSet {
			collectionView.reloadData()
			kanjiLabel.layer.opacity = (kanjiCharacters?.isEmpty ?? false) ? 0 : 1
		}
	}

	var meaning: String = "" {
		didSet {
			meaningText.text = meaning
		}
	}

	var isLoading: Bool = false {
		didSet {
			if isLoading {
				activityIndicator.startAnimating()
			} else {
				activityIndicator.stopAnimating()
			}
		}
	}

	private let wordLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.textColor = UIColor(named: "foreground")
		label.textAlignment = .center
		label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1)
		label.adjustsFontForContentSizeCategory = true
		return label
	}()

	private let meaningLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.adjustsFontForContentSizeCategory = true
		label.textColor = UIColor(named: "accent")
		label.text = "Meaning"
		return label
	}()

	private let meaningText: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.adjustsFontForContentSizeCategory = true
		label.textColor = UIColor(named: "foreground")
		label.text = " "
		return label
	}()

	private let activityIndicator: UIActivityIndicatorView = {
		let view = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.hidesWhenStopped = true
		view.color = UIColor(named: "accent")
		return view
	}()

	private let kanjiLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.text = "Kanji"
		label.textColor = UIColor(named: "accent")
		label.adjustsFontForContentSizeCategory = true
		return label
	}()

	private lazy var collectionView: UICollectionView = {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
		cv.translatesAutoresizingMaskIntoConstraints = false
		cv.backgroundColor = UIColor(named: "background")
		cv.delegate = self
		cv.dataSource = self
		cv.register(KanjiCell.self, forCellWithReuseIdentifier: KanjiCell.identifier)
		cv.contentInset = .init(top: 0, left: 16, bottom: 0, right: 16)
		return cv
	}()

	override func layoutSubviews() {
		super.layoutSubviews()

		backgroundColor = UIColor(named: "background")

		roundCorners(corners: [.topLeft, .topRight], radius: 8)
		
		[wordLabel, meaningLabel, meaningText, activityIndicator, kanjiLabel, collectionView]
			.forEach { addSubview($0) }

		wordLabel.snp.makeConstraints {
			$0.top.left.equalTo(self).offset(16)
			$0.right.equalTo(self).offset(-16)
		}

		meaningLabel.snp.makeConstraints {
			$0.top.equalTo(wordLabel.snp.bottom).offset(16)
			$0.left.equalTo(self).offset(16)
		}

		activityIndicator.snp.makeConstraints {
			$0.left.equalTo(meaningLabel.snp.right).offset(16)
			$0.centerY.equalTo(meaningLabel)
		}

		meaningText.snp.makeConstraints {
			$0.top.equalTo(meaningLabel.snp.bottom).offset(8)
			$0.left.equalTo(self).offset(16)
		}

		kanjiLabel.snp.makeConstraints {
			$0.top.equalTo(meaningText.snp.bottom).offset(32)
			$0.left.equalTo(self).offset(16)
		}

		collectionView.snp.makeConstraints {
			$0.top.equalTo(kanjiLabel.snp.bottom).offset(4)
			$0.left.right.equalTo(self)
			$0.height.greaterThanOrEqualTo(60)
			$0.bottom.equalTo(self).offset(-16)
		}
	}
}

extension WordInfoView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return kanjiCharacters?.count ?? 1
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KanjiCell.identifier, for: indexPath) as? KanjiCell else {
			return UICollectionViewCell()
		}

		cell.kanji = kanjiCharacters?[indexPath.item]

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		guard let text = kanjiCharacters?[indexPath.item] else { return .init(width: 50, height: 50) }

		let font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title2)
		let width = text.width(withConstrainedHeight: 0, font: font) + 16
		let height = text.height(withConstrainedWidth: 0, font: font) + 16

		let dimension = max(width, height)

		return .init(width: dimension, height: dimension)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let kanji = kanjiCharacters?[indexPath.item] else { return }
		didSelectKanjiDelegate?.didSelect(kanji: kanji)
	}
}
