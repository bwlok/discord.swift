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
        
        var heartbeatInterval: TimeInterval = 0
        
        // Listen for messages from the server
        task.receive { result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                    
                    // Parse the JSON response
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let op = json["op"] as? Int {
                        
                        if op == 10, let d = json["d"] as? [String: Any], let interval = d["heartbeat_interval"] as? TimeInterval {
                            // Save the heartbeat interval
                            heartbeatInterval = interval / 1000 // Convert to seconds
                            
                            // Start sending heartbeats
                            DispatchQueue.global().async {
                                while true {
                                    sleep(UInt32(heartbeatInterval))
                                    task.sendPing { error in /* Handle error */ }
                                }
                            }
                        } else if op == 9 {
                            print("Invalid session, please check your token.")
                        }
                    }
                    
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    print("Unknown message")
                }
            }
        }
        
        // Delay before closing the socket
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            task.cancel(with: .normalClosure, reason: nil)
        }
    }
}
