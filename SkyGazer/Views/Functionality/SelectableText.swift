//
//  SelectableText.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 16..
//

import SwiftUI

struct SelectableText: UIViewRepresentable {
	var text: NSAttributedString
	
	init(_ text: String) {
		self.text = NSAttributedString(string: text, attributes: [
			.font : UIFont.preferredFont(forTextStyle: .body),
			.foregroundColor : UIColor.label
		])
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	func makeUIView(context: Context) -> UITextView {
		let textView = UITextView()
		
		textView.delegate = context.coordinator
		textView.isScrollEnabled = false
		textView.isEditable = false
		textView.isSelectable = true
		textView.isUserInteractionEnabled = true
		textView.backgroundColor = .clear
		textView.textContainer.lineBreakMode = .byWordWrapping
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		
		return textView
	}
	
	func updateUIView(_ uiView: UITextView, context: Context) {
		uiView.attributedText = text
		
		let mutable = NSMutableAttributedString(attributedString: uiView.attributedText)
		mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: uiView.attributedText.length)) { value, range, _ in
			mutable.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body, compatibleWith: uiView.traitCollection), range: range)
		}
		uiView.attributedText = mutable
	}
	
	func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
		guard let width = proposal.width else { return nil }
		
		let textDimensions = uiView.attributedText.boundingRect(
			with: .init(
				width: width,
				height: .greatestFiniteMagnitude
			),
			options: [
				.usesLineFragmentOrigin,
				.usesFontLeading
			],
			context: nil
		)
		return .init(width: width, height: ceil(textDimensions.height))
	}
	
	final class Coordinator: NSObject, UITextViewDelegate {
		private var selectableText: SelectableText
		
		init(_ selectableText: SelectableText) {
			self.selectableText = selectableText
			super.init()
		}
		
		func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
			return true
		}
		
		func textViewDidChange(_ textView: UITextView) {
			self.selectableText.text = textView.attributedText
		}
	}
}

#Preview {
	SelectableText("This text should be selectable!\nGo ahead and test it :3")
		.padding()
}
