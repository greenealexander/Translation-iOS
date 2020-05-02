//
//  MakeInterpretationChoiceController.swift
//  Japanese
//
//  Created by Alexander Greene on 12/5/19.
//  Copyright © 2019 Alexander Greene. All rights reserved.
//

import UIKit
import AVKit
import VisionKit
import TesseractOCR
import SnapKit
import SwiftUI

class MakeInterpretationChoiceController: UIViewController {

	private let viewModel = MakeChoiceControllerViewModel()

	// MARK: - UIBarButtons

	private lazy var pasteBoardBtn: UIBarButtonItem = {
		let btn = UIBarButtonItem(
			image: UIImage(systemName: "paperclip"),
			style: .plain,
			target: self,
			action: #selector(handlePasteBoardBtnPressed)
		)
		btn.tintColor = UIColor(named: "accent")
		return btn
	}()

	private lazy var docImageBtn: UIBarButtonItem = {
		let btn = UIBarButtonItem(
			image: UIImage(systemName: "doc.text.viewfinder"),
			style: .plain,
			target: self,
			action: #selector(handleDocImageBtnPressed)
		)
		btn.tintColor = UIColor(named: "accent")
		return btn
	}()

	private lazy var clearBtn: UIBarButtonItem = {
		let btn = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(handleClearBtnPressed))
		btn.isEnabled = false
		btn.tintColor = UIColor(named: "accent")
		return btn
	}()

	private lazy var overlay: UIVisualEffectView = {
		let view = UIVisualEffectView()
		view.backgroundColor = UIColor.black
		view.effect = UIBlurEffect(style: .dark)
		view.layer.opacity = 0
		view.translatesAutoresizingMaskIntoConstraints = false
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismissOverlay)))
		return view
	}()

	private lazy var wordInfoView: WordInfoView = {
		let view = WordInfoView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.token = Token(surface: "日本語", partOfSpeech: PartsOfSpeech.noun.rawValue)
		view.didSelectKanjiDelegate = self
		return view
	}()

	private lazy var progressBarView: ProgressBarView = {
		let view = ProgressBarView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.layer.opacity = 0
		return view
	}()

	private var wordInfoViewTopConstraint: Constraint?
	private var wordInfoViewHeight: CGFloat?

	// MARK: - Child ViewControllers

	private let childController = InterprettedTextController()

	// MARK: - LifeCycle

	override func viewDidLoad() {
		super.viewDidLoad()

		let _ = viewModel.$pairs.receive(on: DispatchQueue.main)
			.assign(to: \.pairs, on: childController)

		let _ = viewModel.$textToInterpret.receive(on: DispatchQueue.main)
			.map { !$0.isEmpty }
			.assign(to: \.isEnabled, on: clearBtn)

		let _ = viewModel.$selectedToken.receive(on: DispatchQueue.main).sink { token in
			let tokenExists = !(token == nil)

			if tokenExists {
				self.wordInfoView.token = token
			}

			UIView.animate(withDuration: 0.2, animations: {
				self.overlay.layer.opacity = tokenExists ? 0.5 : 0
				self.wordInfoView.snp.updateConstraints { _ in
					self.wordInfoViewTopConstraint?.update(offset: tokenExists ? -(self.wordInfoViewHeight ?? 0) : 0)
				}
				self.view.layoutIfNeeded()
			}) { _ in

			}
		}

		let _ = viewModel.$isLoadingTranslation.receive(on: DispatchQueue.main).assign(to: \.isLoading, on: wordInfoView)
		let _ = viewModel.$translation.receive(on: DispatchQueue.main).assign(to: \.meaning, on: wordInfoView)
		let _ = viewModel.$isProcessingImage.receive(on: DispatchQueue.main).sink { isProcessing in
			UIView.animate(withDuration: 0.2, animations: {
				self.progressBarView.layer.opacity = isProcessing ? 1 : 0
				self.overlay.layer.opacity = isProcessing ? 0.5 : 0
			}) { _ in
				self.viewModel.imageProcessingPercentage = 0
			}
			self.overlay.isUserInteractionEnabled = !isProcessing
		}
		let _ = viewModel.$imageProcessingPercentage.receive(on: DispatchQueue.main).sink { progress in
			self.progressBarView.progress = progress
		}

		childController.didSelectWordDelegate = viewModel

		if let backgroundColor = UIColor(named: "background") {
			view.backgroundColor = backgroundColor
		}

		navigationItem.setLeftBarButton(clearBtn, animated: true)
		navigationItem.setRightBarButtonItems([docImageBtn, pasteBoardBtn], animated: true)

		view.addSubview(childController.view)
		childController.didMove(toParent: self)
		childController.view.snp.makeConstraints {
			$0.top.right.left.bottom.equalTo(self.view)
		}

		view.addSubview(overlay)
		overlay.snp.makeConstraints {
			$0.top.right.left.bottom.equalTo(view)
		}

		view.addSubview(wordInfoView)
		wordInfoView.snp.makeConstraints {
			self.wordInfoViewTopConstraint = $0.top.equalTo(view.snp.bottom).offset(0).constraint
			$0.right.left.equalTo(view)
		}

		view.addSubview(progressBarView)
		progressBarView.snp.makeConstraints {
			$0.centerX.centerY.equalTo(view)
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		wordInfoViewHeight = wordInfoView.bounds.height
	}

	// MARK: - Selector Handlers

	@objc func handleDismissOverlay() {
		UIView.animate(withDuration: 0.2, animations: {
			self.overlay.layer.opacity = 0
			self.wordInfoView.snp.updateConstraints { _ in
				self.wordInfoViewTopConstraint?.update(offset: 0)
			}
			self.view.layoutIfNeeded()
		}) { _ in

		}
	}

	@objc func handleClearBtnPressed() {
		viewModel.clear()
		UIPasteboard.general.string = ""
	}

	@objc func handlePasteBoardBtnPressed() {
		guard
			let text = UIPasteboard.general.string,
			!text.isEmpty
		else {
			viewModel.textToInterpret = "私の家では、いつでもあなたを歓迎しますよ。見られる。これを食べてみたいです。クレジットカードは使えますか？あなたはいつでも大歓迎されることを忘れないでください。"
			return
		}

		viewModel.textToInterpret = text
	}

	@objc func handleDocImageBtnPressed() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
			case .authorized:
				presentDocScanner()

			case .notDetermined:
				AVCaptureDevice.requestAccess(for: .video) { granted in
					if granted {
						DispatchQueue.main.async { [weak self] in
							self?.presentDocScanner()
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
	}

	private func presentDocScanner() {
		let controller = VNDocumentCameraViewController()
		controller.delegate = self
		present(controller, animated: true, completion: nil)
	}
}

// MARK: - MakeInterpretationChoiceController Extensions

extension MakeInterpretationChoiceController: VNDocumentCameraViewControllerDelegate, G8TesseractDelegate {
	func processImage(image: UIImage) -> String? {
		guard let tesseract = G8Tesseract(language: "jpn+eng") else {
			print("failed to create tesseract instance")
			return nil
		}

		tesseract.delegate = self
		tesseract.image = image.scaledImage(1000)?.preprocessedImage() ?? image
		tesseract.recognize()

		return tesseract.recognizedText
	}

	func progressImageRecognition(for tesseract: G8Tesseract) {
		DispatchQueue.main.async { [weak self] in
			self?.viewModel.imageProcessingPercentage = tesseract.progress
		}
	}

	func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
		controller.dismiss(animated: true) {
			DispatchQueue.global(qos: .userInitiated).async {
				DispatchQueue.main.async { [weak self] in
					self?.viewModel.isProcessingImage = true
				}

				var strings = [String]()
				for pageNumber in 0 ..< scan.pageCount {
					let image = scan.imageOfPage(at: pageNumber)
					strings.append(self.processImage(image: image) ?? "")
				}
				let string = strings.joined(separator: "\n\n")

				DispatchQueue.main.async { [weak self] in
					self?.viewModel.textToInterpret = string
				}
			}
		}
	}
}

extension MakeInterpretationChoiceController: DidSelectKanjiDelegate {
	func didSelect(kanji: String) {
		let controller = KanjiDetailViewController()
		controller.viewModel.kanji = kanji
		navigationController?.pushViewController(
			controller,
			animated: true
		)
	}
}
