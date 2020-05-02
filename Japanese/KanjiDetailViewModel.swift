//
//  KanjiDetailViewModel.swift
//  Japanese
//
//  Created by Alexander Greene on 12/5/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit

class KanjiDetailViewModel: ObservableObject {

	var kanji: String? {
		didSet {
			fetchKanjiInfo()
		}
	}
	@Published var kanjiInfo: KanjiInfo? = nil
	@Published var kanjiImages: [KanjiImage]? = nil
	@Published var isLoading = false

	private func fetchKanjiInfo() {
		guard let kanji = kanji else { return }
		
		KanjiAliveAPI.shared.getInfoFor(
			kanji: kanji,
			receivedKanjiInfo(kanjiInfo:),
			receivedImages(kanjiImages:)
		)
	}

	private func receivedKanjiInfo(kanjiInfo: KanjiInfo?) {
		print("received kanji info")
		DispatchQueue.main.async { [weak self] in
			self?.kanjiInfo = kanjiInfo
		}
	}

	private func receivedImages(kanjiImages: [KanjiImage]?) {
		print("received kanji images")
		DispatchQueue.main.async { [weak self] in
			self?.kanjiImages = kanjiImages
		}
	}
}
