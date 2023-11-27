import Foundation

public struct SDK {
    public static func test(token: String) {
        // Create a websocket with a URL
        let task = URLSession.shared.webSocketTask(with: URL(string: "wss://gateway.discord.gg/?v=10&encoding=json")!)
        // Connect, handles handshake
        task.resume()
        
        // Identify payload
        let identifyPayload = [
            "op": 2,
            "d": [
                "token": token,
                "properties": [
                    "$os": "ios",
                    "$browser": "my_library",
                    "$device": "my_library"
                ],
                "compress": false,
                "large_threshold": 250
            ]
        ] as [String : Any]
        
        // Convert dictionary to JSON
        let jsonData = try! JSONSerialization.data(withJSONObject: identifyPayload)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Send identify payload to the server
        let identifyMessage = URLSessionWebSocketTask.Message.string(jsonString)
        task.send(identifyMessage) { error in /* Handle error */ }
        
        // Listen for messages from the server
        task.receive { result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    print("Unknown message")
                }
            }
        }
        task.sendPing { error in /* Handle error */ }
        
        // Delay before closing the socket
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            task.cancel(with: .normalClosure, reason: nil)
        }
    }
}
