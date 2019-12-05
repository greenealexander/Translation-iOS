//
//  YahooJapanAPI.swift
//  Japanese
//
//  Created by Alexander Greene on 12/1/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import Foundation

class YahooJapanAPI: NSObject, XMLParserDelegate {
	static let shared = YahooJapanAPI()
	var parser: XMLParser?

	private override init() {
		super.init()
	}

	func getFuriganaFor(text: String) {
		guard let escapedText = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return }
		let path = "\(Constants.YAHOO_JAPAN_API_ENDPOINT)?appid=\(Constants.YAHOO_JAPAN_APP_ID)&sentence=\(escapedText)"

		guard let url = URL(string: path) else { return }

		URLSession.shared.dataTask(with: url) { (data, res, err) in
			if let err = err {
				print("LOOK AT ME ERROR: \(err)")
				return
			}

			guard let data = data else { return }

			self.parser = XMLParser(data: data)
			self.parser?.delegate = self
			self.parser?.parse()
		}.resume()
	}

	enum YahooXMLElement: String {
		case WordList
		case Word
		case Surface
		case Furigana
		case Roman

		case SubWordList
		case SubWord
	}

	var currElement: YahooXMLElement = .WordList
	var wordList = [Word]()
	var subList: [Word]?
	var isInSubList = false
	var currSurface = "" {
		didSet {
			print(currSurface)
		}
	}
	var currFurigana = ""
	var subListSurface = ""
	var subListFurigana = ""

	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

		guard let el = YahooXMLElement(rawValue: elementName) else { return }

		self.currElement = el

		switch el {
		case .SubWordList:
			isInSubList = true
			subList = [Word]()
		default: ()
		}
	}

	func parser(_ parser: XMLParser, foundCharacters string: String) {
		guard string.contains("\n") == false else { return }
		switch self.currElement {
		case .Surface:
			if isInSubList {
				self.subListSurface = string
			} else {
				self.currSurface = string
			}
		case .Furigana:
			if isInSubList {
				self.subListFurigana = string
			} else {
				self.currFurigana = string
			}
		default: ()
		}
	}

	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		guard let el = YahooXMLElement(rawValue: elementName) else { return }

		switch el {
		case .Word:
			let word = Word(surface: currSurface, furigana: currFurigana, subList: subList)
			subList = nil
			currSurface = ""
			currFurigana = ""
			wordList.append(word)
		case .SubWord:
			let word = Word(surface: subListSurface, furigana: subListFurigana, subList: nil)
			subList?.append(word)
			subListSurface = ""
			subListFurigana = ""
		case .SubWordList:
			isInSubList = false
		default: ()
		}
	}

	func parserDidEndDocument(_ parser: XMLParser) {
//		wordList.forEach { print($0) }
	}
}

struct Word {
	let surface: String
	let furigana: String

	let subList: [Word]?
}
