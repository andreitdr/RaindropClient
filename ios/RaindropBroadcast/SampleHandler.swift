import CoreImage
import CoreMedia
import Darwin
import ReplayKit

/// The screen of this iPhone or iPad, handed to Raindrop while it shares it
/// into a call.
///
/// iOS gives an app its own screen and nothing else. Everything outside the
/// app — the home screen, other apps — is only ever given to a *broadcast
/// extension*: this small separate process, started by the system when the
/// user taps Start Broadcast and stopped when they stop it. It is not part of
/// the call and knows nothing about it. All it does is pass each picture of
/// the screen to the app, which is the one that encodes it, encrypts it and
/// sends it. So nothing here ever touches the network, and no frame leaves
/// the device from this process.
///
/// **The hand-over** is the one flutter_webrtc already reads on the app's
/// side (`FlutterSocketConnectionFrameReader`): a Unix socket in the folder
/// the two share through their App Group, which the *app* opens when it
/// starts capturing, and down which each frame goes as a JPEG behind a few
/// HTTP-style headers. The format is that library's, not ours; this is only
/// the sending half of it, written to be read by it.
///
/// **Why frames are thrown away.** The system holds an extension to about
/// 50 MB of memory and ends it without notice above that. Frames arrive at up
/// to sixty a second, at the screen's full size. So a frame is only ever
/// worked on if the previous one is finished — never queued — and at most
/// thirty a second are taken, each scaled into the 1080p box before it is
/// compressed. Thirty and 1080p are the most a share is sent at from iOS
/// (`maximumShareFrameRate` in the app); a lower ceiling its sharer picks is
/// applied by the encoder in the app, which can change it mid-share without
/// anything here having to be told.
final class SampleHandler: RPBroadcastSampleHandler {
  // LiveKit's names for the three things the app and the extension say to
  // each other. They cross the process boundary as Darwin notifications,
  // which carry a name and nothing else.
  private static let started = "iOS_BroadcastStarted"
  private static let stopped = "iOS_BroadcastStopped"
  private static let stopRequested = "iOS_BroadcastRequestStop"

  /// The key both targets name their App Group under, and the socket's file
  /// name inside it: flutter_webrtc's, since it is the one listening.
  private static let appGroupKey = "RTCAppGroupIdentifier"
  private static let socketName = "rtc_SSFD"

  /// The most frames a second handed to the app, and the box each is fitted
  /// inside (turned for a portrait screen).
  private static let framesPerSecond = 30.0
  private static let longEdge: CGFloat = 1920
  private static let shortEdge: CGFloat = 1080

  /// How good the JPEG that crosses to the app is. High, because what is on a
  /// shared screen is mostly text and the video encoder will compress it
  /// again; not the maximum, which doubles the size for nothing visible.
  private static let jpegQuality = 0.85

  /// How long the app has to open its end. It does so once the server has
  /// agreed to the share, which is a round trip or two after the broadcast
  /// starts. A broadcast started from Control Centre with no call behind it
  /// never gets an answer, and ends itself after this long rather than
  /// recording a screen for nobody.
  private static let connectTimeout: TimeInterval = 20
  private static let connectRetry: TimeInterval = 0.1

  /// Everything that touches the socket happens here, one thing at a time.
  private let queue = DispatchQueue(label: "raindrop.broadcast.upload")
  private let imageContext = CIContext(options: nil)

  private var socket: Int32 = -1
  private var connectTimer: DispatchSourceTimer?
  private var finished = false

  /// Whether a frame is being compressed or written right now. Read from
  /// ReplayKit's thread and written from ours, hence the lock.
  private var busy = false
  private var lastTaken = CMTime.invalid
  private let lock = NSLock()

  // MARK: - The broadcast

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    // The app is waiting for this before it tells the server anything.
    Self.post(Self.started)
    observeStopRequest()
    queue.async { self.connect(deadline: Date().addingTimeInterval(Self.connectTimeout)) }
  }

  override func broadcastFinished() {
    // However it ended — from the status bar, Control Centre, or us — the app
    // has to hear it: this is what ends the share on its side.
    Self.post(Self.stopped)
    CFNotificationCenterRemoveEveryObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      Unmanaged.passUnretained(self).toOpaque()
    )
    queue.sync {
      self.finished = true
      self.connectTimer?.cancel()
      self.connectTimer = nil
      self.closeSocket()
    }
  }

  override func processSampleBuffer(
    _ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType
  ) {
    // The picture only. The sound of the device is never sent: a whole screen
    // is shared without sound, on every platform.
    guard sampleBufferType == .video, take(sampleBuffer) else { return }

    queue.async {
      defer {
        self.lock.lock()
        self.busy = false
        self.lock.unlock()
      }
      self.send(sampleBuffer)
    }
  }

  /// Whether to work on this frame: not while the last one is still in hand,
  /// and not sooner after it than the frame rate allows.
  private func take(_ sampleBuffer: CMSampleBuffer) -> Bool {
    lock.lock()
    defer { lock.unlock() }

    if busy { return false }

    let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    if lastTaken.isValid, time.isValid {
      let since = CMTimeGetSeconds(CMTimeSubtract(time, lastTaken))
      // A little under the interval, so a steady sixty-a-second source gives
      // every other frame rather than every third.
      if since >= 0, since < (1 / Self.framesPerSecond) * 0.9 { return false }
    }

    lastTaken = time
    busy = true
    return true
  }

  // MARK: - Sending a frame

  private func send(_ sampleBuffer: CMSampleBuffer) {
    guard socket >= 0, let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    // Which way up the screen is. The picture always arrives as the device is
    // built; this is what turns it for whoever is watching.
    var orientation = CGImagePropertyOrientation.up.rawValue
    if let attached = CMGetAttachment(
      sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil
    ) as? NSNumber {
      orientation = attached.uint32Value
    }

    var image = CIImage(cvPixelBuffer: pixels)
    let size = image.extent.size
    let scale = min(
      1,
      Self.longEdge / max(size.width, size.height),
      Self.shortEdge / min(size.width, size.height)
    )
    if scale < 1 {
      image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    let width = Int(image.extent.width.rounded(.down))
    let height = Int(image.extent.height.rounded(.down))
    guard width > 0, height > 0 else { return }

    let quality = CIImageRepresentationOption(
      rawValue: kCGImageDestinationLossyCompressionQuality as String)
    guard
      let jpeg = imageContext.jpegRepresentation(
        of: image,
        colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
        options: [quality: Self.jpegQuality]
      )
    else { return }

    // A response, not a request, with no status line anybody reads: it is
    // only being used as a way to put named numbers in front of some bytes.
    let message = CFHTTPMessageCreateResponse(nil, 200, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(message, "Content-Length" as CFString, "\(jpeg.count)" as CFString)
    CFHTTPMessageSetHeaderFieldValue(message, "Buffer-Width" as CFString, "\(width)" as CFString)
    CFHTTPMessageSetHeaderFieldValue(message, "Buffer-Height" as CFString, "\(height)" as CFString)
    CFHTTPMessageSetHeaderFieldValue(
      message, "Buffer-Orientation" as CFString, "\(orientation)" as CFString)
    CFHTTPMessageSetBody(message, jpeg as CFData)

    guard let bytes = CFHTTPMessageCopySerializedMessage(message)?.takeRetainedValue() as Data?
    else { return }

    if !write(bytes) {
      // The app closed its end: the share is over, and so is the reason for
      // this broadcast.
      finish("Screen sharing has ended.")
    }
  }

  /// Writes all of [data], or says it could not. Blocking, which is the point:
  /// while this is writing, [take] turns the next frames away.
  private func write(_ data: Data) -> Bool {
    data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Bool in
      guard var next = buffer.baseAddress else { return true }
      var left = buffer.count
      while left > 0 {
        let wrote = Darwin.write(socket, next, left)
        if wrote > 0 {
          next += wrote
          left -= wrote
        } else if wrote < 0, errno == EINTR {
          continue
        } else {
          return false
        }
      }
      return true
    }
  }

  // MARK: - Reaching the app

  /// Tries the app's socket until it is there. The app opens it when it
  /// starts capturing, which is after this broadcast has started, so the
  /// first tries are expected to fail.
  private func connect(deadline: Date) {
    if finished { return }
    if open() { return }

    if Date() >= deadline {
      finish("Start sharing from a call in Raindrop.")
      return
    }

    let timer = DispatchSource.makeTimerSource(queue: queue)
    timer.schedule(deadline: .now() + Self.connectRetry)
    timer.setEventHandler { [weak self] in
      self?.connectTimer = nil
      self?.connect(deadline: deadline)
    }
    connectTimer = timer
    timer.resume()
  }

  private func open() -> Bool {
    guard
      let group = Bundle.main.object(forInfoDictionaryKey: Self.appGroupKey) as? String,
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: group)
    else { return false }

    let path = container.appendingPathComponent(Self.socketName).path

    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let capacity = MemoryLayout.size(ofValue: address.sun_path)
    guard path.utf8.count < capacity else { return false }
    withUnsafeMutablePointer(to: &address.sun_path) { pointer in
      pointer.withMemoryRebound(to: CChar.self, capacity: capacity) { destination in
        _ = path.withCString { strncpy(destination, $0, capacity - 1) }
      }
    }

    let descriptor = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
    guard descriptor >= 0 else { return false }

    // A write to an end the app has closed must come back as an error, not
    // arrive as a signal that ends this process mid-frame.
    var on: Int32 = 1
    setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))

    let connected = withUnsafePointer(to: &address) { pointer in
      pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        Darwin.connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
      }
    }
    guard connected == 0 else {
      close(descriptor)
      return false
    }

    socket = descriptor
    return true
  }

  private func closeSocket() {
    if socket >= 0 {
      close(socket)
      socket = -1
    }
  }

  /// Ends the broadcast from this side. iOS shows the user [reason] in an
  /// alert of its own, so it is written for them.
  private func finish(_ reason: String) {
    if finished { return }
    finished = true
    connectTimer?.cancel()
    connectTimer = nil
    closeSocket()
    // Said here as well as in broadcastFinished, which the system does not
    // call for a broadcast its own extension ended.
    Self.post(Self.stopped)
    finishBroadcastWithError(
      NSError(
        domain: "com.raindrop.broadcast", code: 0,
        userInfo: [NSLocalizedDescriptionKey: reason]
      ))
  }

  // MARK: - Words between the two processes

  private static func post(_ name: String) {
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(name as CFString), nil, nil, true
    )
  }

  /// Stopped from inside the app: its Stop sharing, or the call ending. The
  /// app cannot stop a broadcast, only ask.
  private func observeStopRequest() {
    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      Unmanaged.passUnretained(self).toOpaque(),
      { _, observer, _, _, _ in
        guard let observer else { return }
        let handler = Unmanaged<SampleHandler>.fromOpaque(observer).takeUnretainedValue()
        handler.queue.async { handler.finish("Screen sharing has ended.") }
      },
      Self.stopRequested as CFString, nil, .deliverImmediately
    )
  }
}
