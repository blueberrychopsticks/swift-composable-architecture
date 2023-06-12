import ComposableArchitecture
import SwiftUI


struct PartialState<T>: Encodable {
    let original: T
    let keyPaths: [PartialKeyPath<T>]
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        for keyPath in keyPaths {
            guard let keyPath = keyPath as? KeyPath<T, Encodable> else { continue }
            let value = original[keyPath: keyPath]
            try container.encode(value, forKey: CodingKeys(stringValue: NSExpression(forKeyPath: keyPath).keyPath)!)
        }
    }
    
    struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int? {
            return Int(stringValue)
        }
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init?(intValue: Int) {
            return nil
        }
    }
}

protocol CodableState {
    associatedtype CodableRepresentation: Encodable
    var codableRepresentation: CodableRepresentation { get }
}

extension ReducerProtocol where State: CodableState {
    func encodeState() -> some ReducerProtocol<State, Action> {
        Reduce { state, action in
            print("Received action: \(action)")
            let effects = self.reduce(into: &state, action: action)
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(state.codableRepresentation)
                
                // Convert the data to a pretty-printed JSON string
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                   let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
                   let prettyPrintedString = String(data: prettyJsonData, encoding: .utf8) {
                    print(prettyPrintedString)
                } else {
                    print("Failed to pretty print the JSON")
                }
            } catch {
                print("Failed to encode state")
            }
            return effects
        }
    }
}



@main
struct SpeechRecognitionApp: App {
    var body: some Scene {
        let store = Store(initialState: SpeechRecognition.State()) {
            SpeechRecognition().encodeState()
        }
        
        WindowGroup {
            SpeechRecognitionView(
                store: store
            )
        }
    }
}
