//
//  AttributedBskyTextView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 21..
//

import SwiftUI
import ATProtoKit

struct AttributedBskyTextView: UIViewRepresentable {
	typealias Facet = AppBskyLexicon.RichText.Facet
	
	private var text: NSAttributedString
	let accentColor: UIColor
	
	let onLinkTap: ((URL) -> Void)?
	let onHandleTap: ((String) -> Void)?
	let onTagTap: ((String) -> Void)?
	
	private var font: UIFont.TextStyle
	
	init(
		_ text: String,
		facets: [Facet]?,
		accentColor: Color,
		font: UIFont.TextStyle = .body,
		onLinkTap: ((URL)->Void)? = nil,
		onHandleTap: ((String)->Void)? = nil,
		onTagTap: ((String)->Void)? = nil
	) {
		self.accentColor = UIColor(accentColor)
		self.onLinkTap = onLinkTap
		self.onHandleTap = onHandleTap
		self.onTagTap = onTagTap
		self.font = font
		
		self.text = NSAttributedString.fromBluesky(
			text: text,
			facets: facets,
			baseAttributes: [
				.font : UIFont.preferredFont(forTextStyle: font),
				.foregroundColor : UIColor.label,
			]
		)
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self, onLinkTap: onLinkTap, onHandleTap: onHandleTap, onTagTap: onTagTap)
	}
	
	func makeUIView(context: Context) -> UITextView {
		let textView = UITextView()
		
		textView.delegate = context.coordinator
		textView.isScrollEnabled = false
		textView.isEditable = false
		textView.isSelectable = false
		textView.isUserInteractionEnabled = true
		textView.backgroundColor = .clear
		textView.adjustsFontForContentSizeCategory = true
		textView.textContainer.lineBreakMode = .byWordWrapping
		textView.textContainer.lineFragmentPadding = 0
		textView.textContainerInset = .zero
		textView.dataDetectorTypes = []
		textView.linkTextAttributes = [
			.foregroundColor : accentColor
		]
		textView.allowsEditingTextAttributes = false
		
		return textView
	}
	
	func updateUIView(_ uiView: UITextView, context: Context) {
		uiView.attributedText = text
		uiView.linkTextAttributes = [
			.foregroundColor : accentColor
		]
		
		let mutable = NSMutableAttributedString(attributedString: uiView.attributedText)
		mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: uiView.attributedText.length)) { value, range, _ in
			mutable.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: font, compatibleWith: uiView.traitCollection), range: range)
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
		private var attributedText: AttributedBskyTextView
		let onLinkTap: ((URL) -> Void)?
		let onHandleTap: ((String) -> Void)?
		let onTagTap: ((String) -> Void)?
		
		init(
			_ attributedText: AttributedBskyTextView,
			onLinkTap: ((URL)->Void)? = nil,
			onHandleTap: ((String)->Void)? = nil,
			onTagTap: ((String)->Void)? = nil
		) {
			self.attributedText = attributedText
			self.onLinkTap = onLinkTap
			self.onHandleTap = onHandleTap
			self.onTagTap = onTagTap
			super.init()
		}
		
		func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
			return true
		}
		
		func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
			guard case .link(let url) = textItem.content else { return nil }
			
			return UIAction { [weak self] _ in
				guard let scheme = url.scheme,
					  scheme == "skygazer" else {
					if let onLinkTap = self?.onLinkTap {
						onLinkTap(url)
					}
					return
				}
				
				guard let host = url.host(percentEncoded: false) else { return }
				
				let urlComponent = url.absoluteString
					.replacingOccurrences(of: "\(scheme)://", with: "")
					.replacingOccurrences(of: "\(host)/", with: "")
				
				if host == "tag",
				   let onTagTap = self?.onTagTap {
					onTagTap(urlComponent)
				} else if host == "mention",
						  let onHandleTap = self?.onHandleTap {
					onHandleTap(urlComponent)
				}
			}
		}
		
		func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
			if case .link(let url) = textItem.content,
			   url.scheme == "skygazer" {
				return nil
			}
			
			return .init(menu: defaultMenu)
		}

		
		func textViewDidChange(_ textView: UITextView) {
			self.attributedText.text = textView.attributedText
		}
	}
}


fileprivate struct PreviewView: View {
	@State private var color: Color = .blue
	
	var body: some View {
		VStack(alignment: .leading) {
			ColorPicker("Test accent color", selection: $color)
			Text("Preview & Test:")
			ScrollView {
				AttributedBskyTextView(
					"This is a test :3\nhttps://example.com\n@handle.domain.tld\n#tag\n\nThis is to show the facet handler text view in operation",
					facets: [
						.init(index: .init(byteStart: 18, byteEnd: 37), features: [.link(.init(uri: "https://example.com"))]),
						.init(index: .init(byteStart: 38, byteEnd: 56), features: [.mention(.init(did: "did:plc:test"))]),
						.init(index: .init(byteStart: 57, byteEnd: 61), features: [.tag(.init(tag: "tag"))])
					],
					accentColor: color,
					font: .title1
				) { url in
					print("Link: \(url)")
				} onHandleTap: { handle in
					print("Handle: \(handle)")
				} onTagTap: { tag in
					print("Tag: \(tag)")
				}
			}
		}
		.font(.title)
		.padding()
	}
}

#Preview {
	PreviewView()
}
