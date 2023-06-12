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
    func encodeState(callback: @escaping (String) -> Void) -> some ReducerProtocol<State, Action> {
        Reduce { state, action in
            let effects = self.reduce(into: &state, action: action)
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(state.codableRepresentation)
                
                // Convert the data to a pretty-printed JSON string
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                   let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
                   let prettyPrintedString = String(data: prettyJsonData, encoding: .utf8) {
                    // Invoke the callback with the JSON-encoded state
                    callback(prettyPrintedString)
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
        let store = Store(
          initialState: SpeechRecognition.State()
        ) {
          SpeechRecognition().encodeState { json in
            print(json)
          }
        }
        
        WindowGroup {
            SpeechRecognitionView(
                store: store
            )
        }
    }
}


/*
 
 import ComposableArchitecture
 import SwiftUI
 import ExpoModulesCore

 public class StateChangeEmitter: Module {
   var store: Store<SpeechRecognition.State, SpeechRecognition.Action>? // Store instance

   public func definition() -> ModuleDefinition {
     Name("StateChangeEmitter")

     Events("onStateChange")

     OnStartObserving {
       // Instantiate the store when Expo starts observing
       self.store = Store(initialState: SpeechRecognition.State()) {
         SpeechRecognition().encodeState(callback: { jsonEncodedState in
           // This function is invoked with the JSON-encoded state whenever the state changes
           // Here, you can do something with the state, like sending it to Expo
           self.emitStateChange(state: jsonEncodedState)
         })
       }
     }
 
      // TODO how do we elegantly map the Actions from TCA -> Expo?
     struct FileReadOptions: Record {
       @Field
       var encoding: String = "utf8"

       @Field
       var position: Int = 0

       @Field
       var length: Int?
     }

     // Now this record can be used as an argument of the functions or the view prop setters.
     Function("readFile") { (path: String, options: FileReadOptions) -> String in
       // Read the file using given `options`
     }

     OnStopObserving {
       // Clean up when Expo stops observing
       self.store = nil
     }
   }
   
   func emitStateChange(state: String) {
     sendEvent("onStateChange", ["state": state])
   }
 }

 extension ReducerProtocol where State: CodableState {
     func encodeState() -> some ReducerProtocol<State, Action> {
         return Reduce { state, action in
             let effects = self.reduce(into: &state, action: action)
             return effects
         }
     }
 }

 
 
 
 
 
 
 
 
 
 
 */
