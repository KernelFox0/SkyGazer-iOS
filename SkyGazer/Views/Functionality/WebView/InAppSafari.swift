//
//  InAppSafari.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 17..
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
	let url: URL
	
	func makeUIViewController(context: Context) -> SFSafariViewController {
		SFSafariViewController(url: url)
	}
	
	func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

