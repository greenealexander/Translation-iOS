//
//  ContentView.swift
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
		case .particle:
			wordLabel.textColor = UIColor(named: "foreground")?.withAlphaComponent(0.5)
		default:
			wordLabel.textColor = UIColor(named: "foreground")
		}
	}

	override var isSelected: Bool {
		didSet {
			print(isSelected)

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

extension Character {
	var string: String {
		return "\(self)"
	}
}

class InterprettedTextController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

	weak var kanjiDetailStore: KanjiDetailStore?

	lazy var collectionView: UICollectionView = {
		let cv = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
		cv.delegate = self
		cv.dataSource = self
		cv.translatesAutoresizingMaskIntoConstraints = false
		cv.register(JapaneseWordCell.self, forCellWithReuseIdentifier: JapaneseWordCell.identifier)
		cv.backgroundColor = UIColor(named: "background")
		cv.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
		cv.alwaysBounceVertical = true
		return cv
	}()

	weak var interpretTextStore: InterpretTextStore?
	var selectedCellIndexPath: IndexPath?

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationController?.navigationBar.isHidden = true

		view.addSubview(collectionView)

		collectionView.snp.makeConstraints {
			$0.top.right.left.bottom.equalTo(view)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(handleKanjiSelected(_:)), name: .kanjiSelected, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .pairsFinishedProcessing, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc func refresh() {
		collectionView.reloadData()
	}

	@objc func handleKanjiSelected(_ notification: Notification) {
		guard
			let kanji = notification.object as? String,
			let store = kanjiDetailStore
		else { return }

		store.kanji = kanji
		navigationController?.pushViewController(UIHostingController(rootView: KanjiDetailView(kanji: kanji).environmentObject(store)), animated: true)
	}

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let store = interpretTextStore else { return 0 }

		return store.pairs.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JapaneseWordCell.identifier, for: indexPath) as? JapaneseWordCell,
			let store = interpretTextStore
		else { return UICollectionViewCell() }

		cell.configureCell(pair: store.pairs[indexPath.item])

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 0
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		guard let store = interpretTextStore else { return .init(width: 0, height: 0) }

		let tuple = store.pairs[indexPath.item]
		let text = tuple.0.string
		let width = text.width(withConstrainedHeight: 0, font: font)
		let height = text.height(withConstrainedWidth: 0, font: font)

		guard let partOfSpeech = PartsOfSpeech(rawValue: tuple.1.partOfSpeech ?? "") else { return .init(width: width, height: height) }

		return CGSize(
			width: tuple.2 && partOfSpeech != .special ? width + 8 : width,
			height: height
		)
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let store = interpretTextStore else { return }

		let token = store.pairs[indexPath.item].1
		let partOfSpeech = PartsOfSpeech.init(rawValue: token.partOfSpeech ?? "")

		if partOfSpeech == .special || partOfSpeech == .particle {
			return
		}
		
		store.selectedToken = token
		print(token.surface, partOfSpeech?.english ?? "")

		if let selectedCellIndexPath = selectedCellIndexPath {
			collectionView.deselectItem(at: selectedCellIndexPath, animated: true)
		}
		selectedCellIndexPath = indexPath
	}
}

extension String {
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
