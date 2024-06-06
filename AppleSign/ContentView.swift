//
//  ContentView.swift
//  AppleSign
//
//  Created by APPLE on 05/06/24.
//
import SwiftUI

struct WindowKey: EnvironmentKey {
    static let defaultValue: UIWindow? = nil
}

extension EnvironmentValues {
    var window: UIWindow? {
        get { self[WindowKey.self] }
        set { self[WindowKey.self] = newValue }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            HStack {
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                        .font(.title3)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                NavigationLink(destination: HealthStoreDataView()) {
                    Text("Details")
                        .font(.title3)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
