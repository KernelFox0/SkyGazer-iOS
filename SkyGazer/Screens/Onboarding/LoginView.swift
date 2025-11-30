//
//  LoginView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 30..
//

import SwiftUI

struct LoginView: View {
	@Binding var presentLoginContent: Bool
	@Binding var applicationLoadIsCompleted: Bool
	@Binding var loginPresented: Bool
	
	@State private var handle: String = ""
	@State private var password: String = ""
	@State private var customPds: Bool = false
	@State private var pds: String = ""
	@State private var invalidField: Bool = false
	@State private var errorHappened: Bool = false
	@State private var errorMessage: String = ""
	
	@Environment(PreferenceManager.self) private var preferenceManager
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \Account.handle, ascending: true)],
		animation: .default
	) private var accounts: FetchedResults<Account>
	@Environment(\.managedObjectContext) private var viewContext
	
	var body: some View {
		if accounts.isEmpty {
			addAccountView
		} else {
			accountListView
		}
	}
	
	var accountListView: some View {
		VStack {
			ForEach(accounts, id: \.id) { account in
				VStack {
					Text(account.handle ?? "Unknown Account")
						.font(.subheadline)
					if let pds = account.pds {
						Text("PDS: \(pds)")
					}
				}
				.padding()
				.onTapGesture {
					preferenceManager.lastLoggedInAccount = account.handle
					login()
				}
				.contextMenu {
					Button("Edit", systemImage: "pencil") {
						errorMessage = String(localized: "Sorry! That's not added yet :(")
						errorHappened = true
					}
					Button("Delete", systemImage: "trash", role: .destructive) {
						if let handle = account.handle {
							do {
								try AccountManager(accounts: accounts.map { $0 }, viewContext: viewContext).deleteAccount(handle: handle)
							} catch {
								errorMessage = error.localizedDescription
								errorHappened = true
							}
						}
					}
				}
			}
		}
	}
	
	var addAccountView: some View {
		VStack {
			Spacer()
			Text("Log in to Bluesky")
				.font(.title)
				.padding(.bottom, 15)
			GlassEffectContainer {
				HStack {
					Image(systemName: "at")
					TextField("Handle", text: $handle)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding()
				.glassEffect(.regular.interactive())
				HStack {
					Image(systemName: "key")
					SecureField("App password", text: $password)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding()
				.glassEffect(.regular.interactive())
				.padding(.bottom)
				Toggle("Custom hosting provider", isOn: $customPds)
				if customPds {
					HStack {
						Image(systemName: "server.rack")
						TextField("Server address", text: $pds)
							.keyboardType(.URL)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding()
					.glassEffect(.regular.interactive())
				}
			}
			.autocorrectionDisabled()
			.textInputAutocapitalization(.never)
			Spacer()
			Spacer()
			Button {
				guard !(handle.isEmpty || password.isEmpty || (customPds && pds.isEmpty)) else {
					HapticsManager.notification(type: .error)
					invalidField = true
					return
				}
				
				Task {
					do {
						try await UserManager.shared.addAccountLogin(handle: handle, password: password, pds: pds.isEmpty ? nil : pds, accounts: accounts.map { $0 }, viewContext: viewContext)
						preferenceManager.lastLoggedInAccount = handle
						login()
					} catch {
						if error is AccountAlreadyExistsError {
							errorMessage = String(localized: "Account is already added! Go to the account list and edit it there")
						} else if let error = error as? AppError {
							errorMessage = error.message
						} else {
							errorMessage = error.localizedDescription
						}
						errorHappened = true
					}
				}
			} label: {
				Text("Log in")
					.font(.title2)
					.padding(.horizontal)
			}
			.tint(preferenceManager.accentColor)
			.buttonStyle(.glassProminent)
			.padding()
		}
		.alert("Please fill out every field", isPresented: $invalidField, actions: {
			Text("OK")
		})
		.alert("Error", isPresented: $errorHappened, actions: {
			Text("OK")
		}, message: {
			Text(errorMessage)
		})
		.padding(.horizontal)
		.animation(.bouncy, value: customPds)
	}
	
	@MainActor
	private func login() {
		applicationLoadIsCompleted = false
		presentLoginContent = false
		loginPresented = false
	}
}
