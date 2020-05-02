//
//  InterprettedTextController.swift
//  Japanese
//
//  Created by Alexander Greene on 12/6/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import SnapKit

class InterprettedTextController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

	private let layout = UICollectionViewFlowLayout()
	lazy var collectionView: UICollectionView = {
		let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
		cv.delegate = self
		cv.dataSource = self
		cv.translatesAutoresizingMaskIntoConstraints = false
		cv.register(JapaneseWordCell.self, forCellWithReuseIdentifier: JapaneseWordCell.identifier)
		cv.backgroundColor = UIColor(named: "background")
		cv.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
		cv.alwaysBounceVertical = true
		return cv
	}()

	var selectedCellIndexPath: IndexPath?
	var didSelectWordDelegate: DidSelectWordDelegate?

	var pairs = [TokenTuple]() {
		didSet {
			collectionView.reloadData()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationController?.navigationBar.isHidden = true

		view.addSubview(collectionView)

		collectionView.snp.makeConstraints {
			$0.top.bottom.equalTo(view)
			$0.right.left.equalTo(view.safeAreaLayoutGuide)
		}
	}

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pairs.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JapaneseWordCell.identifier, for: indexPath) as? JapaneseWordCell
		else { return UICollectionViewCell() }

		cell.configureCell(pair: pairs[indexPath.item])

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 0
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let tuple = pairs[indexPath.item]
		let text = tuple.0.string
		let width = text.width(withConstrainedHeight: 0, font: font)
		let height = text.height(withConstrainedWidth: 0, font: font)

		guard let partOfSpeech = PartsOfSpeech(rawValue: tuple.1.partOfSpeech ?? "")
		else { return .init(width: width, height: height) }

		return CGSize(
			width: tuple.2 && partOfSpeech != .special ? width + 8 : width,
			height: height
		)
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let token = pairs[indexPath.item].1
		let partOfSpeech = PartsOfSpeech.init(rawValue: token.partOfSpeech ?? "")

		if partOfSpeech == .special || partOfSpeech == .particle {
			return
		}

//		store.selectedToken = token
		print(token.surface, partOfSpeech?.english ?? "")

		if let selectedCellIndexPath = selectedCellIndexPath {
			collectionView.deselectItem(at: selectedCellIndexPath, animated: true)
		}
		selectedCellIndexPath = indexPath

		didSelectWordDelegate?.didSelect(token: token)
	}
}
