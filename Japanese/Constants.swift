//
//  Constants.swift
//  Japanese
//
//  Created by Alexander Greene on 11/28/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import Foundation

class Constants {
	static let appTmpDirectory = NSTemporaryDirectory() + "japanese-iOS/"
	
	static let YAHOO_JAPAN_APP_ID = "dj00aiZpPTdyN2dHNnZBYWJDYyZzPWNvbnN1bWVyc2VjcmV0Jng9YTU-"
	static let YAHOO_JAPAN_API_ENDPOINT = "https://jlp.yahooapis.jp/FuriganaService/V1/furigana"

	static let NON_KANJI_CHARACTERS: [String:Bool] = {
		return [
		"あ","い","う","え","お",
		"た","ち","つ","て","と",
		"ら","り","る","れ","ろ",
		"は","ひ","ふ","へ","ほ",
		"さ","し","す","せ","そ",
		"な","に","ぬ","ね","の",
		"ま","み","む","め","も",
		"か","き","く","け","こ","ん","わ",
		"や","よ","ゆ","ゃ","ょ","ゅ","っ",
		"で","だ",

		"ア","イ","ウ","エ","オ",
		"タ","チ","ツ","テ","ト",
		"ラ","リ","ル","レ","ロ",
		"ハ","ヒ","フ","へ","ホ",
		"サ","シ","ス","セ","ソ",
		"ナ","ニ","ヌ","ネ","ノ",
		"マ","ミ","ム","メ","モ",
		"カ","キ","ク","ケ","コ","ん","ワ",
		"ッ","ヤ","ヨ","ユ","ャ","ョ","ュ"
		].reduce(into: [String:Bool]()) { (res, s) in
			res[s] = true
		}
	}()
}
