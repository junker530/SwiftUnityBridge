//
//  UnityBridge.swift
//  Unity-iPhone
//
//  Created by Shota Sakoda on 2025/02/24.
//

import Foundation
import SwiftUI
import UIKit
import UnityFramework

// Unityから呼ばれるグローバル関数（SwiftUI画面を表示）
@_cdecl("showSwiftUIScreen")
@MainActor func showSwiftUIScreen() {
    let rootVC = UnityFramework.getInstance()?.appController()?.rootViewController
    let swiftUIController = UIHostingController(rootView: SettingsView())
    rootVC?.present(swiftUIController, animated: true, completion: nil)
}

// Unityからメッセージを受け取るグローバル関数
@_cdecl("sendMessageToSwift")
func sendMessageToSwift(_ message: UnsafePointer<CChar>) {
    let msg = String(cString: message)
    print("Unityから受け取ったメッセージ: \(msg)")
    // 必要ならここで何か処理を追記
}

// Unityと通信するためのクラス
@objc class UnityBridge: NSObject {
    // Unityに戻る＆メッセージ送信
    @MainActor @objc static func returnToUnity() {
        let rootVC = UnityFramework.getInstance()?.appController()?.rootViewController
        rootVC?.dismiss(animated: true) {
            UnityFramework.getInstance()?.sendMessageToGO(withName: "NativeBridge", functionName: "OnMessageFromSwift", message: "SwiftUIから戻ったよ！")
        }
    }
}

// SwiftUI画面
struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("Unityに戻る") {
                UnityBridge.returnToUnity()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}
