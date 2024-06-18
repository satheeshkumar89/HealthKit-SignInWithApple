//
//  LoginView.swift
//  AppleSign
//
//  Created by APPLE on 05/06/24.
//

import SwiftUI
import AuthenticationServices
import UIKit

struct LoginView: View {
    @Environment(\.window) var window: UIWindow?
    @State private var userId: String?
    @State private var fullname: PersonNameComponents?
    @State private var email: String?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack() {
            SignInWithAppleButton(onRequest: configureSignInWithAppleRequest, onCompletion: handleSignInWithAppleCompletion)
                .frame(width: 280, height: 60)
            
            if let userIdentifier = userId {
                Text("User ID: \(userIdentifier)")
            }
            if let fullName = fullname {
                Text("Full Name: \(fullNameFormatter(fullName))")
            }
            if let email = email {
                Text("Email: \(email)")
            }
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            loadUserDetails()
        }
    }
    
    private func configureSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    private func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                userId = appleIDCredential.user
                fullname = appleIDCredential.fullName
                email = appleIDCredential.email
                saveUserDetails()
            }
        case .failure(let error):
            handleSignInWithAppleError(error)
        }
    }
    
    private func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
    }
    
    private func saveUserDetails() {
        UserDefaults.standard.set(userId, forKey: "UserId")
        if let fullname = fullname {
            UserDefaults.standard.set(PersonNameComponentsFormatter().string(from: fullname), forKey: "FullName")
        }
        UserDefaults.standard.set(email, forKey: "Email")
    }
    
    private func loadUserDetails() {
        userId = UserDefaults.standard.string(forKey: "UserId")
        if let fullNameString = UserDefaults.standard.string(forKey: "FullName") {
            fullname = PersonNameComponentsFormatter().personNameComponents(from: fullNameString)
        }
        email = UserDefaults.standard.string(forKey: "Email")
    }
    
    private func handleSignInWithAppleError(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain {
            switch nsError.code {
            case ASAuthorizationError.canceled.rawValue:
                errorMessage = "Sign in with Apple was canceled."
            case ASAuthorizationError.failed.rawValue:
                errorMessage = "Sign in with Apple failed."
            case ASAuthorizationError.invalidResponse.rawValue:
                errorMessage = "Sign in with Apple received an invalid response."
            case ASAuthorizationError.notHandled.rawValue:
                errorMessage = "Sign in with Apple not handled."
            case ASAuthorizationError.unknown.rawValue:
                errorMessage = "An unknown error occurred with Sign in with Apple."
            default:
                errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
        }
    }
    
    private func fullNameFormatter(_ fullName: PersonNameComponents) -> String {
        var nameString = ""
        if let givenName = fullName.givenName {
            nameString += givenName
        }
        if let familyName = fullName.familyName {
            nameString += " \(familyName)"
        }
        return nameString
    }
}

#Preview {
    LoginView()
}
