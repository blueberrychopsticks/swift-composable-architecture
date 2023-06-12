import ComposableArchitecture
import SwiftUI


extension _ReducerPrinter {
  public static var expoReducerProxy: Self {
    Self { receivedAction, oldState, newState in
      print("ACTION_______")
      print(receivedAction)
//      print(oldState)
      print("NEW STATE")
      // EMIT THESE CHANGES OVER EXPO BRIDGE TO TypeScript Native Module (how do we serialize them)
      // Looks like CustomDump does some "mirror work which I think is reflection"?
      // Expore to hook
      // Look into automatic typing via Expo
      print(newState)
      guard let jsonEncodedNewState = try? JSONEncoder().encode(newState) else { return }
      
      print(jsonEncodedNewState)
      
//      var target = ""
//      target.write("received action:\n")
//      CustomDump.customDump(receivedAction, to: &target, indent: 2)
//      target.write("\n")
//      target.write(diff(oldState, newState).map { "\($0)\n" } ?? "  (No state changes)\n")
//      print(target)
    }
  }
}


@main
struct SpeechRecognitionApp: App {
  var body: some Scene {
    let store = Store(initialState: SpeechRecognition.State()) {
          SpeechRecognition()
        .signpost()
        ._printChanges(.expoReducerProxy)
        }
    
    WindowGroup {
      SpeechRecognitionView(
        store: store
      )
    }
  }
}

