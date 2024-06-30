import ComposableArchitecture
import Speech

extension SpeechClient: DependencyKey {
  static var liveValue: Self {
    let speech = Speech()
    NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
      .sink { notification in
        print(notification)
      }
    
    NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
      .sink { notification in
        print(notification)
      }
    return Self(
      finishTask: {
        await speech.finishTask()
      },
      requestAuthorization: {
        await withCheckedContinuation { continuation in
          SFSpeechRecognizer.requestAuthorization { status in
            continuation.resume(returning: status)
          }
        }
      },
      startTask: { request in
        let request = UncheckedSendable(request)
        return await speech.startTask(request: request)
      }
    )
  }
}

private actor Speech {
  var audioEngine: AVAudioEngine? = nil
  var recognitionTask: SFSpeechRecognitionTask? = nil
  var recognitionContinuation: AsyncThrowingStream<SpeechRecognitionResult, Error>.Continuation?

  func finishTask() {
    self.audioEngine?.stop()
    self.audioEngine?.inputNode.removeTap(onBus: 0)
    self.recognitionTask?.finish()
    self.recognitionContinuation?.finish()
  }
  
//  @objc func handleRouteChange(notification: Notification) async {
//      guard let userInfo = notification.userInfo,
//          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
//          let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
//              return
//      }
//      
//      // Switch over the route change reason.
//      switch reason {
//      case .newDeviceAvailable:
//          print("New Device Available")
//      case .oldDeviceUnavailable:
//          print("Old Device Unavailable")
//      // ... handle other cases
//      default: ()
//      }
//  }


  func startTask(
    request: UncheckedSendable<SFSpeechAudioBufferRecognitionRequest>
  ) -> AsyncThrowingStream<SpeechRecognitionResult, Error> {
    let request = request.wrappedValue
    

    return AsyncThrowingStream { continuation in
      self.recognitionContinuation = continuation
      let audioSession = AVAudioSession.sharedInstance()
      
      
      
      
      do {
        try! audioSession.setCategory(.record, options: [.mixWithOthers, .allowAirPlay, .allowBluetoothA2DP, .defaultToSpeaker ])

        try audioSession.setActive(true)
      } catch {
        continuation.finish(throwing: SpeechClient.Failure.couldntConfigureAudioSession)
        return
      }

      self.audioEngine = AVAudioEngine()
      let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
      self.recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
        switch (result, error) {
        case let (.some(result), _):
          continuation.yield(SpeechRecognitionResult(result))
        case (_, .some):
          continuation.finish(throwing: SpeechClient.Failure.taskError)
        case (.none, .none):
          fatalError("It should not be possible to have both a nil result and nil error.")
        }
      }

      continuation.onTermination = {
        [
          speechRecognizer = UncheckedSendable(speechRecognizer),
          audioEngine = UncheckedSendable(audioEngine),
          recognitionTask = UncheckedSendable(recognitionTask)
        ]
        _ in

        _ = speechRecognizer
        audioEngine.wrappedValue?.stop()
        audioEngine.wrappedValue?.inputNode.removeTap(onBus: 0)
        recognitionTask.wrappedValue?.finish()
      }
      
    

      self.audioEngine?.inputNode.installTap(
        onBus: 0,
        bufferSize: 1024,
        format: self.audioEngine?.inputNode.outputFormat(forBus: 0)
      ) { buffer, when in
        print(Date.now)
        request.append(buffer)
//        print(audioSession.isOtherAudioPlaying)
//        print(audioSession.availableModes)
//        print(audioSession.availableCategories)
      }

      self.audioEngine?.prepare()
      do {
        try self.audioEngine?.start()
      } catch {
        continuation.finish(throwing: SpeechClient.Failure.couldntStartAudioEngine)
        return
      }
    }
  }
}
