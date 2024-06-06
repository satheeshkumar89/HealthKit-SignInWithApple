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
        VStack(){
            SignInWithAppleButton(onRequest: configureSignInWithAppleRequest, onCompletion: handleSignInWithAppleCompletion)
                .frame(width: 280, height: 60)
            
            if let userIdentifier = userId {
                Text("User ID: \(userId)")
            }
            if let fullName = fullname {
                Text("Full Name: \(fullName)")
            }
            if let email = email {
                Text("Email: \(email)")
            }
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
        }
        .onAppear{
            loadUserDetails()
        }
    }
    
    private func configureSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    private func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        print(result)
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                userId = appleIDCredential.user
                fullname = appleIDCredential.fullName
                email = appleIDCredential.email
                saveUserDetails()
            }
        case .failure(let error):
            // Handle error.
            handleSignInWithAppleError(error)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
    }
    
    //Save Local Data
    private func saveUserDetails(){
        UserDefaults.standard.set(userId, forKey: "UserId")
        UserDefaults.standard.set(fullname, forKey: "FullName")
        UserDefaults.standard.set(email, forKey: "Email")
    }
    
    //Get Local Data
    private func loadUserDetails(){
        userId = UserDefaults.standard.string(forKey: "UserID")
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
                print("Sign in with Apple was canceled.")
            case ASAuthorizationError.failed.rawValue:
                print("Sign in with Apple failed.")
            case ASAuthorizationError.invalidResponse.rawValue:
                print("Sign in with Apple received an invalid response.")
            case ASAuthorizationError.notHandled.rawValue:
                print("Sign in with Apple not handled.")
            case ASAuthorizationError.unknown.rawValue:
                print("Sign in with Apple unknown error occurred.")
            default:
                print("Sign in with Apple failed: \(error.localizedDescription)")
            }
        } else {
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    LoginView()
}
