//
//  MakeChoiceControllerViewModel.swift
//  Japanese
//
//  Created by Alexander Greene on 12/5/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import Foundation

class MakeChoiceControllerViewModel: ObservableObject {
	let tokenizer = Tokenizer()
	@Published var pairs = [TokenTuple]()
	@Published var imageProcessingPercentage: UInt = 0
	@Published var isProcessingImage = false
	@Published var translation = " "
	@Published var isLoadingTranslation = false
	var dataTask: URLSessionDataTask?
	@Published var selectedToken: Token? = nil {
		didSet {
			guard
				let selectedToken = selectedToken,
				!selectedToken.surface.isEmpty
			else { return }

			dataTask = GoogleTranslateAPI.shared.translateText(text: selectedToken.surface) { translation in
				guard let translation = translation else { return }

				DispatchQueue.main.async { [weak self] in
					self?.translation = translation
					self?.isLoadingTranslation = false
				}
			}

			isLoadingTranslation = true
			dataTask?.resume()
		}
	}
	@Published var textToInterpret = "" {
		didSet {
			imageProcessingPercentage = 100
			isProcessingImage = false
			selectedToken = nil

			if !textToInterpret.isEmpty {
				tokenize(text: textToInterpret)
			} else {
				pairs.removeAll()
			}
		}
	}

	func cancelDataTask() {
		dataTask?.cancel()
		isLoadingTranslation = false
	}

	func clear() {
		textToInterpret = ""
		translation = " "
		selectedToken = nil
	}

	func tokenize(text: String) {
		guard !textToInterpret.isEmpty else { return }

		DispatchQueue(label: "background").async { [weak self] in
			autoreleasepool {
				guard let parsedText = self?.tokenizer.parse(text) else { return }
				let pairs = self?.fixParse(tokens: parsedText).compactMap { token -> [TokenTuple]? in
					let surface = token.surface
					var tuples = [TokenTuple]()

					for i in 0..<surface.count {
						let character = surface[i]
						let isLast = surface.count - 1 == i

						tuples.append((character, token, isLast))
					}

					return tuples
				}.reduce(into: [TokenTuple]()) { (res, arr) in
					arr.forEach { res.append($0) }
				}

				DispatchQueue.main.async { [weak self] in
					self?.pairs = pairs ?? []
					NotificationCenter.default.post(name: .pairsFinishedProcessing, object: nil)
				}
			}
		}
	}

	func fixParse(tokens: [Token]) -> [Token] {
		guard tokens.count > 1 else { return tokens }

		var wordTokens = [Token]()
		wordTokens.append(tokens[0])

		for i in 1..<tokens.count {
			let currentToken = tokens[i]
			let prevToken = wordTokens[wordTokens.count - 1]

			let currentValue = currentToken.partOfSpeech ?? ""
			let currentPartOfSpeech = PartsOfSpeech(rawValue: currentValue)

			let prevValue = prevToken.partOfSpeech ?? ""
			let prevPartOfSpeech = PartsOfSpeech(rawValue: prevValue)

			if currentPartOfSpeech == .auxiliaryVerb && prevPartOfSpeech == .verb
			|| currentPartOfSpeech == .verb && prevPartOfSpeech == .verb
			|| currentPartOfSpeech == .particle && prevPartOfSpeech == .particle
			|| (currentPartOfSpeech == .particle && prevPartOfSpeech == .verb && (currentToken.surface == "て" || currentToken.surface == "で")) {
				let token = Token(surface: "\(prevToken.surface)\(currentToken.surface)", partOfSpeech: prevValue)
				let _ = wordTokens.popLast()
				wordTokens.append(token)
				continue
			} else if prevPartOfSpeech == nil {
				let token = Token(surface: "\(prevToken.surface)\(currentToken.surface)", partOfSpeech: currentValue)
				let _ = wordTokens.popLast()
				wordTokens.append(token)
				continue
			}

			wordTokens.append(currentToken)
		}

		return wordTokens
	}
}

extension MakeChoiceControllerViewModel: DidSelectWordDelegate {
	func didSelect(token: Token) {
		self.selectedToken = token
	}
}
