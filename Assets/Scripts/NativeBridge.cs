using UnityEngine;
using UnityEngine.UI; // UIを使うために追加
#if UNITY_IOS
using System.Runtime.InteropServices;
#endif

public class NativeBridge : MonoBehaviour
{
    #if UNITY_IOS
    [DllImport("__Internal")]
    private static extern void showSwiftUIScreen();

    [DllImport("__Internal")]
    private static extern void sendMessageToSwift(string message);
    #endif

    // デバッグ用にText UIを追加（Inspectorでアサイン）
    public Text debugText;

    // SwiftUI画面を表示する関数（ボタンから呼ぶ用）
    public void OnShowSwiftUIClick()
    {
        #if UNITY_IOS
        showSwiftUIScreen();
        Debug.Log("SwiftUI画面を表示します！");
        if (debugText != null) debugText.text = "SwiftUIへ移動中...";
        #endif
    }

    // テストメッセージをSwiftに送る関数（ボタンから呼ぶ用）
    public void SendTestMessage()
    {
        #if UNITY_IOS
        sendMessageToSwift("Hello from Unity!");
        Debug.Log("Swiftにメッセージを送りました！");
        if (debugText != null) debugText.text = "メッセージ送信: Hello from Unity!";
        #endif
    }

    // Swiftからメッセージを受け取るコールバック
    public void OnMessageFromSwift(string message)
    {
        Debug.Log("Swiftから受け取ったメッセージ: " + message);
        if (debugText != null) debugText.text = "Swiftから受け取ったメッセージ\n" + message;
        // 必要ならここで追加処理（例: AR再開とか）
    }

    // シーンにボタンを手動で設定するための例（インスペクターで使う）
    void Start()
    {
        // 必要ならここで初期化処理
        if (debugText != null) debugText.text = "準備完了！";
    }
}