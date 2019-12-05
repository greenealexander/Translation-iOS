//
//  ChooseToInterpretScreen.swift
//  Japanese
//
//  Created by Alexander Greene on 11/18/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import SwiftUI
import SnapKit
import AVKit
import RealmSwift

extension StringProtocol {
	subscript(_ offset: Int) -> Element { self[index(startIndex, offsetBy: offset)] }
}

struct InterprettedTextView: UIViewControllerRepresentable {
	@EnvironmentObject var interpretTextStore: InterpretTextStore
	@EnvironmentObject var kanjiDetailStore: KanjiDetailStore

	func makeUIViewController(context: UIViewControllerRepresentableContext<InterprettedTextView>) -> UINavigationController {
		let controller = InterprettedTextController()
		controller.kanjiDetailStore = kanjiDetailStore
		controller.interpretTextStore = interpretTextStore
		return UINavigationController(rootViewController: controller)
	}

	func updateUIViewController(_ uiViewController: UINavigationController, context: UIViewControllerRepresentableContext<InterprettedTextView>) {

	}
}

enum TokenizationType: String {
	case word = "Word"
	case character = "Character"
}

typealias TokenTuple = (Character, Token, Bool)

class InterpretTextStore: ObservableObject {
	@Published var textToInterpret: String = "" {
		didSet {
			tokenize(text: textToInterpret)
		}
	}
	@Published var selectedToken: Token? {
		didSet {
			guard let token = selectedToken else {
				infoViewOffset = 0
				return
			}
			isLoading = true

			dataTask = GoogleTranslateAPI.shared.translateText(text: token.surface) { [weak self] text in
				guard let text = text else { return }
				self?.translation = text
				self?.isLoading = false
			}
		}
	}
	@Published var translation = ""
	@Published var isLoading = false
	@Published var isShowingKanjiInfo = false
	@Published var infoViewOffset: CGFloat = 0
	@Published var percentage: UInt = 0
	@Published var isProcessingImage = false

	var dataTask: URLSessionDataTask?
	let tokenizer = Tokenizer()

	var pairs = [TokenTuple]()

	func tokenize(text: String) {
		guard !textToInterpret.isEmpty else { return }

//		YahooJapanAPI.shared.getFuriganaFor(text: text)

		DispatchQueue(label: "background").async {
			autoreleasepool {
				let parsedText = self.tokenizer.parse(text)
				let pairs = self.fixParse(tokens: parsedText).compactMap { token -> [TokenTuple]? in
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

				DispatchQueue.main.async {
					self.pairs = pairs
					print("number of pairs: ", pairs.count)
					NotificationCenter.default.post(name: .pairsFinishedProcessing, object: nil)
				}
			}
		}

	}

	func clear() {
		translation = ""
		isLoading = false
		selectedToken = nil
		textToInterpret = ""
		isShowingKanjiInfo = false

		if dataTask?.state != .completed {
			dataTask?.cancel()
		}

		dataTask = nil
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

	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleKanjiInfoScreenDismissed), name: .kanjiInfoScreenDismissed, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handlePresentVideoPlayer), name: .presentVideoPlayerController, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleDismissVideoPlayer), name: .dismissVideoPlayerController, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleTextFromImage(_:)), name: .extractedTextFromImage, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageProcessedPercentage(_:)), name: .imageProcessedPercentage, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageProcessStarted), name: .imageProcessStarted, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc func handleImageProcessStarted() {
		DispatchQueue.main.async {
			self.isProcessingImage = true
		}
	}

	@objc func handleImageProcessedPercentage(_ notification: Notification) {
		guard let percentage = notification.object as? UInt else { return }
		self.percentage = percentage
		print(percentage)
	}

	@objc func handleTextFromImage(_ notification: Notification) {
		isProcessingImage = false
		percentage = 0
		guard let string = notification.object as? String else { return }
		textToInterpret = string
	}

	var isShowingVideo = false
	@objc func handlePresentVideoPlayer() {
		isShowingVideo = true
	}

	@objc func handleDismissVideoPlayer() {
		isShowingVideo = false
	}

	@objc func handleKanjiInfoScreenDismissed() {
		if !isShowingVideo {
			isShowingKanjiInfo = false
			print("info screen dismissed")
		}
	}
}

class ModalShowTracker: ObservableObject {
	@Published var interprettedTextScreenPresented = false
	@Published var takePhotoControllerPresented = false
	@Published var aboutPresented = false
	@Published var sheetPresented = false
	@Published var percentage: Int = 0

	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleExtractedText), name: .extractedTextFromImage, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc func handleExtractedText() {
		interprettedTextScreenPresented = true
		sheetPresented = true
		percentage = 0
	}
}

struct ChooseToInterpretView: View {
	@EnvironmentObject var interpretTextStore: InterpretTextStore
	@EnvironmentObject var kanjiDetailStore: KanjiDetailStore
	@EnvironmentObject var modalShowTracker: ModalShowTracker

	var body: some View {
		ZStack(alignment: .topLeading) {
			VStack {
				Button(action: {
					if let text = UIPasteboard.general.string {
						self.interpretTextStore.textToInterpret = text
						self.modalShowTracker.interprettedTextScreenPresented = true
						self.modalShowTracker.sheetPresented = true
					} else {
						self.interpretTextStore.textToInterpret = "私の家では、いつでもあなたを歓迎しますよ。見られる。これを食べてみたいです。クレジットカードは使えますか？あなたはいつでも大歓迎されることを忘れないでください。"
						self.modalShowTracker.interprettedTextScreenPresented = true
						self.modalShowTracker.sheetPresented = true
					}
				}) {
					VStack {
						Image(systemName: "paperclip")
							.resizable()
							.frame(width: 50, height: 50)
						Text("Paste from Clipboard")
					}
				}
				.foregroundColor(Color("accent"))
				.padding()

				Divider()

				Button(action: {
					switch AVCaptureDevice.authorizationStatus(for: .video) {
						case .authorized:
							self.modalShowTracker.takePhotoControllerPresented = true
							self.modalShowTracker.sheetPresented = true

						case .notDetermined:
							AVCaptureDevice.requestAccess(for: .video) { granted in
								if granted {
									DispatchQueue.main.async {
										self.modalShowTracker.takePhotoControllerPresented = true
										self.modalShowTracker.sheetPresented = true
									}
								}
							}

						case .denied: // The user has previously denied access.
							return

						case .restricted: // The user can't grant access due to restrictions.
							return

						@unknown default:
							return
					}
				}) {
					VStack {
						Image(systemName: "camera.viewfinder")
							.resizable()
							.frame(width: 50, height: 50)
						Text("Extract Text from Image")
					}
				}
				.foregroundColor(Color("accent"))
				.padding()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color("background"))
			.edgesIgnoringSafeArea(.all)
			.sheet(isPresented: $modalShowTracker.sheetPresented, onDismiss: onDismiss) {
				if self.modalShowTracker.interprettedTextScreenPresented {
					InteractWithTextScreen()
						.environmentObject(self.interpretTextStore)
						.environmentObject(self.kanjiDetailStore)
				} else if self.modalShowTracker.takePhotoControllerPresented {
					ExtractTextFromImageView()
						.edgesIgnoringSafeArea(.all)
						.environmentObject(self.interpretTextStore)
				} else if self.modalShowTracker.aboutPresented {
					AboutView()
						.edgesIgnoringSafeArea(.all)
				}
			}
			.blur(radius: interpretTextStore.isProcessingImage ? 3 : 0)

			VStack {
				ZStack {
					Text("Translation")
						.font(.largeTitle)
						.fontWeight(.bold)
						.foregroundColor(Color("foreground"))
						.frame(maxWidth: .infinity, alignment: .leading)
						.background(Color("background"))

					HStack {
						Spacer()

						Button(action: {
							self.modalShowTracker.aboutPresented = true
							self.modalShowTracker.sheetPresented = true
						}) {
							Text("About")
								.foregroundColor(Color("foreground"))
						}
					}
				}
				.padding(.horizontal)
				.padding(.top)
				.frame(maxWidth: .infinity)
				.background(Color("background"))
				.blur(radius: interpretTextStore.isProcessingImage ? 4 : 0)

				Divider()
			}

			VStack {
				Text("")
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color("background"))
			.edgesIgnoringSafeArea(.all)
			.opacity(interpretTextStore.isProcessingImage ? 0.4 : 0.0)
			.animation(.easeInOut)

			VStack(alignment: .center) {
				Spacer()

				Text("\(interpretTextStore.percentage)%")
					.foregroundColor(Color("accent"))
					.frame(maxWidth: .infinity, alignment: .center)

				ZStack(alignment: .leading) {
					Capsule()
						.frame(width: 250, height: 20)
						.foregroundColor(Color("accent").opacity(0.5))
					Capsule()
						.frame(width: 250 * (CGFloat(interpretTextStore.percentage) / 100), height: 20)
						.foregroundColor(Color("accent"))
				}
				.animation(.easeInOut)
				.frame(maxWidth: .infinity, alignment: .center)

				Spacer()
			}
			.opacity(interpretTextStore.isProcessingImage ? 1 : 0.0)
			.frame(alignment: .center)
		}
	}

	func onDismiss() {
		if self.modalShowTracker.takePhotoControllerPresented {
			self.modalShowTracker.takePhotoControllerPresented = false
			return
		}
		self.interpretTextStore.clear()
		NotificationCenter.default.post(name: .kanjiInfoScreenDismissed, object: nil)
		self.modalShowTracker.interprettedTextScreenPresented = false
		self.modalShowTracker.aboutPresented = false
	}
}

extension Notification.Name {
	static let kanjiSelected = Notification.Name("kanjiSelected")
	static let kanjiInfoScreenDismissed = Notification.Name("kanjiInfoScreenDismissed")
	static let refreshStrokeOrderImages = Notification.Name("refreshStrokeOrderImages")
	static let presentVideoPlayerController = Notification.Name("presentVideoPlayerController")
	static let dismissVideoPlayerController = Notification.Name("dismissVideoPlayerController")
	static let extractedTextFromImage = Notification.Name("extractedTextFromImage")
	static let imageProcessedPercentage = Notification.Name("imageProcessedPercentage")
	static let imageProcessStarted = Notification.Name("imageProcessStarted")
	static let pairsFinishedProcessing = Notification.Name("pairsFinishedProcessing")
}

struct InteractWithTextScreen: View {
	@EnvironmentObject var interpretTextStore: InterpretTextStore

	var body: some View {
		let shouldShowInfoView = interpretTextStore.selectedToken != nil && !interpretTextStore.isShowingKanjiInfo

		return ZStack(alignment: .bottom) {
			InterprettedTextView()
				.animation(.easeInOut)
				.navigationBarHidden(true)
				.blur(radius: shouldShowInfoView ? 2 : 0)

			Rectangle()
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.foregroundColor(Color("foreground"))
				.opacity(shouldShowInfoView ? 0.3 : 0)
				.edgesIgnoringSafeArea(.all)
				.animation(.easeInOut)
				.onTapGesture {
					self.interpretTextStore.selectedToken = nil
				}

			InfoView()
				.animation(.easeInOut)
				.offset(x: 0, y: shouldShowInfoView ? interpretTextStore.infoViewOffset : UIScreen.main.bounds.height)
				.gesture(
					DragGesture()
						.onChanged { gesture in
							let translation = gesture.translation.height

							if translation > 0 && translation < 200 {
								self.interpretTextStore.infoViewOffset = translation
							}
						}
						.onEnded { gesture in
							let translation = gesture.translation.height
							let predictedTranslation = gesture.predictedEndTranslation.height

							if translation >= 200 || predictedTranslation >= 200 {
								self.interpretTextStore.infoViewOffset = UIScreen.main.bounds.height
								self.interpretTextStore.selectedToken = nil
							} else {
								self.interpretTextStore.infoViewOffset = 0
							}
						}
					)
		}
		.edgesIgnoringSafeArea(.bottom)
		.onDisappear {
			if !self.interpretTextStore.isShowingVideo {
				self.interpretTextStore.clear()
			}
		}
	}
}

struct InfoView: View {
	@EnvironmentObject var interpretTextStore: InterpretTextStore

	var body: some View {
		let chars = Array(interpretTextStore.selectedToken?.surface ?? "")
			.compactMap { "\($0)" }.filter { !(nonKanjiCharacters["\($0)"] ?? false) }

		return VStack(alignment: .center) {
			Text(interpretTextStore.selectedToken?.surface ?? "")
				.font(.largeTitle)
				.fontWeight(.bold)

//			Text(PartsOfSpeech(rawValue: interpretTextStore.selectedToken?.partOfSpeech ?? "")?.english ?? "")

			if interpretTextStore.isLoading {
				ActivityIndicator(isAnimating: $interpretTextStore.isLoading, style: .large)
			} else {
				Text("Meaning")
					.font(.subheadline)
					.foregroundColor(Color("accent"))
					.padding(.top)
					.padding(.bottom, 4)
					.frame(maxWidth: .infinity, alignment: .leading)

				Text("\(interpretTextStore.translation)")
					.font(.headline)
					.frame(maxWidth: .infinity, alignment: .leading)

				Text("Kanji")
					.font(.subheadline)
					.foregroundColor(Color("accent"))
					.padding(.top)
					.padding(.bottom, 8)
					.frame(maxWidth: .infinity, alignment: .leading)
					.opacity(chars.isEmpty ? 0 : 1)

				HStack {
					ForEach(chars, id: \.self) { char in
						Button(action: {
							NotificationCenter.default.post(name: .kanjiSelected, object: char)
							self.interpretTextStore.isShowingKanjiInfo = true
						}) {
							Text(char)
								.font(.title)
								.foregroundColor(Color("foreground"))
//								.frame(maxWidth: .infinity, alignment: .leading)
						}
						.padding()
						.background(Color("background"))
						.cornerRadius(8)
						.shadow(color: Color("shadow"), radius: 8, x: 0, y: 8)
					}
				}.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
		.padding()
		.padding(.bottom, 32)
		.frame(maxWidth: .infinity, alignment: .center)
		.background(Color("background"))
		.cornerRadius(20)
	}
}

struct WordToken {
	let id: String
	let character: String
}

let nonKanjiCharacters = [
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

class GoogleTranslateAPI {
	static let shared = GoogleTranslateAPI()
	private let apiKey = "AIzaSyDp03g1VlxPOW4-nWrNMU-waIaMcTQIi_I"
	private let endpointUrl = "https://translation.googleapis.com/language/translate/v2"
	private var lookedUpWords = [String:String]()

	private init() {}

	func translateText(text: String, _ completed: ((String?)->())? = nil) -> URLSessionDataTask? {
		if let translatedText = lookedUpWords[text] {
			completed?(translatedText)
			return nil
		}

		guard let url = URL(string: "\(endpointUrl)?key=\(apiKey)") else { return nil }

		var req = URLRequest(url: url)
		req.httpMethod = "POST"
		req.addValue("application/json", forHTTPHeaderField: "Content-Type")
		let body: [String:String] = ["q":text, "source":"ja", "target":"en", "format": "text"]
		var data = body.keys.reduce("") {
			return "\($0)\("\"\($1)\":\"\(body[$1]!)\",")"
		}
		let _ = data.popLast()
		let dataString = "{\(data)}".utf8
		req.httpBody = Data(dataString)

		let task = URLSession.shared.dataTask(with: req) { [weak self] (data, res, err) in
			if let err = err {
				print(err)
				return
			}

			guard let data = data else { return }

			do {
				let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)

				guard
					let dict = json as? [String:Any],
					let data = dict["data"] as? [String:Any],
					let translations = data["translations"] as? [[String:String]],
					let translatedText = translations[0]["translatedText"]
				else { return }

				self?.lookedUpWords[text] = translatedText

				DispatchQueue.main.async {
					completed?(translatedText)
				}
			} catch let error {
				print(error)
				DispatchQueue.main.async {
					completed?(nil)
				}
			}
		}
		task.resume()
		return task
	}
}

extension Color {
	static let infoGreen = Color(UIColor(displayP3Red: 59/255, green: 127/255, blue: 81/255, alpha: 1))
}

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
