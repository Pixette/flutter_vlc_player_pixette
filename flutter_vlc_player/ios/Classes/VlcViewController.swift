import Flutter
import Foundation
import VLCKit
import UIKit

public class VLCViewController: NSObject, FlutterPlatformView {
    var hostedView: UIView
    var vlcMediaPlayer: VLCMediaPlayer
    var mediaEventChannel: FlutterEventChannel
    let mediaEventChannelHandler: VLCPlayerEventStreamHandler
    var rendererEventChannel: FlutterEventChannel
    let rendererEventChannelHandler: VLCRendererEventStreamHandler
    var rendererdiscoverers: [VLCRendererDiscoverer] = .init()

    public func view() -> UIView {
        return self.hostedView
    }

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
        let mediaEventChannel = FlutterEventChannel(
            name: "flutter_video_plugin/getVideoEvents_\(viewId)",
            binaryMessenger: messenger
        )
        let rendererEventChannel = FlutterEventChannel(
            name: "flutter_video_plugin/getRendererEvents_\(viewId)",
            binaryMessenger: messenger
        )

        // VLCKit 4.0 calls addSubview: on the drawable to add its rendering
        // view. Use a subclass that ensures the rendering view always fills
        // the parent when Flutter resizes the platform view.
        self.hostedView = VLCHostView(frame: frame)
        self.hostedView.backgroundColor = .black
        self.hostedView.isOpaque = true
        self.hostedView.clipsToBounds = true
        self.vlcMediaPlayer = VLCMediaPlayer()
        self.mediaEventChannel = mediaEventChannel
        self.mediaEventChannelHandler = VLCPlayerEventStreamHandler()
        self.rendererEventChannel = rendererEventChannel
        self.rendererEventChannelHandler = VLCRendererEventStreamHandler()
        //
        self.mediaEventChannel.setStreamHandler(self.mediaEventChannelHandler)
        self.rendererEventChannel.setStreamHandler(self.rendererEventChannelHandler)
        // Defer setting drawable until setMediaPlayerUrl, so the view has
        // been laid out by Flutter and has non-zero bounds for VLCKit 4.0's
        // rendering subview.
        self.mediaEventChannelHandler.mediaPlayer = self.vlcMediaPlayer
        self.vlcMediaPlayer.delegate = self.mediaEventChannelHandler
    }

    public func play() {
        self.vlcMediaPlayer.play()
    }

    public func pause() {
        self.vlcMediaPlayer.pause()
    }

    public func stop() {
        self.vlcMediaPlayer.stop()
    }

    public var isPlaying: Bool {
        self.vlcMediaPlayer.isPlaying
    }

    public var isSeekable: Bool {
        self.vlcMediaPlayer.isSeekable
    }

    public func setLooping(isLooping: Bool) {
        self.vlcMediaPlayer.media?.addOption(isLooping ? "--loop" : "--no-loop")
    }

    public func seek(position: Int64) {
        self.vlcMediaPlayer.time = VLCTime(number: position as NSNumber)
    }

    public var position: Int32 {
        self.vlcMediaPlayer.time.intValue
    }

    public var duration: Int32 {
        self.vlcMediaPlayer.media?.length.intValue ?? 0
    }

    public func setVolume(volume: Int64) {
        self.vlcMediaPlayer.audio?.volume = volume.int32
    }

    public var volume: Int32 {
        self.vlcMediaPlayer.audio?.volume ?? 100
    }

    public func setPlaybackSpeed(speed: Float) {
        self.vlcMediaPlayer.rate = speed
    }

    public var playbackSpeed: Float {
        self.vlcMediaPlayer.rate
    }

    public func takeSnapshot() -> String? {
        guard let drawable = self.vlcMediaPlayer.drawable as? UIView else { return nil }
        let renderer = UIGraphicsImageRenderer(size: drawable.frame.size)
        let image = renderer.image { _ in
            drawable.drawHierarchy(in: drawable.bounds, afterScreenUpdates: false)
        }
        return image.pngData()?.base64EncodedString()
    }

    public var spuTracksCount: Int32 {
        return Int32(self.vlcMediaPlayer.textTracks.count)
    }

    public var spuTracks: [Int: String] {
        self.vlcMediaPlayer.textTracksDictionary()
    }

    public func setSpuTrack(spuTrackNumber: Int32) {
        let tracks = self.vlcMediaPlayer.textTracks
        let index = Int(spuTrackNumber)
        if index == -1 {
            self.vlcMediaPlayer.deselectAllTextTracks()
        } else if index >= 0 && index < tracks.count {
            tracks[index].isSelectedExclusively = true
        }
    }

    public var spuTrack: Int32 {
        let tracks = self.vlcMediaPlayer.textTracks
        if let index = tracks.firstIndex(where: { $0.isSelected }) {
            return Int32(index)
        }
        return -1
    }

    public func setSpuDelay(delay: Int) {
        self.vlcMediaPlayer.currentVideoSubTitleDelay = delay
    }

    public var spuDelay: Int {
        self.vlcMediaPlayer.currentVideoSubTitleDelay
    }

    public func addSubtitleTrack(uri: String, isSelected: Bool) {
        guard
            let url = URL(string: uri)
        else {
            return
        }

        self.vlcMediaPlayer.addPlaybackSlave(
            url,
            type: VLCMediaPlaybackSlaveType.subtitle,
            enforce: isSelected
        )
    }

    public var audioTracksCount: Int32 {
        Int32(self.vlcMediaPlayer.audioTracks.count)
    }

    public var audioTracks: [Int: String] {
        self.vlcMediaPlayer.audioTracksDictionary()
    }

    public func setAudioTrack(audioTrackNumber: Int32) {
        let tracks = self.vlcMediaPlayer.audioTracks
        let index = Int(audioTrackNumber)
        if index == -1 {
            self.vlcMediaPlayer.deselectAllAudioTracks()
        } else if index >= 0 && index < tracks.count {
            tracks[index].isSelectedExclusively = true
        }
    }

    public var audioTrack: Int32 {
        let tracks = self.vlcMediaPlayer.audioTracks
        if let index = tracks.firstIndex(where: { $0.isSelected }) {
            return Int32(index)
        }
        return -1
    }

    public func setAudioDelay(delay: Int) {
        self.vlcMediaPlayer.currentAudioPlaybackDelay = delay
    }

    public var audioDelay: Int {
        self.vlcMediaPlayer.currentAudioPlaybackDelay
    }

    public func addAudioTrack(uri: String, isSelected: Bool) {
        guard let url = URL(string: uri)
        else {
            return
        }
        self.vlcMediaPlayer.addPlaybackSlave(
            url,
            type: VLCMediaPlaybackSlaveType.audio,
            enforce: isSelected
        )
    }

    public var videoTracksCount: Int32 {
        Int32(self.vlcMediaPlayer.videoTracks.count)
    }

    public var videoTracks: [Int: String] {
        self.vlcMediaPlayer.videoTracksDictionary()
    }

    public func setVideoTrack(videoTrackNumber: Int32) {
        let tracks = self.vlcMediaPlayer.videoTracks
        let index = Int(videoTrackNumber)
        if index == -1 {
            self.vlcMediaPlayer.deselectAllVideoTracks()
        } else if index >= 0 && index < tracks.count {
            tracks[index].isSelectedExclusively = true
        }
    }

    public var videoTrack: Int32 {
        let tracks = self.vlcMediaPlayer.videoTracks
        if let index = tracks.firstIndex(where: { $0.isSelected }) {
            return Int32(index)
        }
        return -1
    }

    public func setVideoScale(scale: Float) {
        self.vlcMediaPlayer.scaleFactor = scale
    }

    public var videoScale: Float {
        self.vlcMediaPlayer.scaleFactor
    }

    public func setVideoAspectRatio(aspectRatio: String) {
        self.vlcMediaPlayer.videoAspectRatio = aspectRatio
    }

    public var videoAspectRatio: String {
        self.vlcMediaPlayer.videoAspectRatio ?? "1"
    }

    public var availableRendererServices: [String] {
        self.vlcMediaPlayer.rendererServices()
    }

    public func startRendererScanning() {
        self.rendererdiscoverers.removeAll()
        self.rendererEventChannelHandler.renderItems.removeAll()
        let rendererServices = self.vlcMediaPlayer.rendererServices()
        for rendererService in rendererServices {
            guard let rendererDiscoverer
                = VLCRendererDiscoverer(name: rendererService)
            else {
                continue
            }
            rendererDiscoverer.delegate = self.rendererEventChannelHandler
            rendererDiscoverer.start()
            self.rendererdiscoverers.append(rendererDiscoverer)
        }
    }

    public func stopRendererScanning() {
        for rendererDiscoverer in self.rendererdiscoverers {
            rendererDiscoverer.stop()
            rendererDiscoverer.delegate = nil
        }
        self.rendererdiscoverers.removeAll()
        self.rendererEventChannelHandler.renderItems.removeAll()
        if self.vlcMediaPlayer.isPlaying {
            self.vlcMediaPlayer.pause()
        }
        self.vlcMediaPlayer.setRendererItem(nil)
    }

    public var rendererDevices: [String: String] {
        var rendererDevices: [String: String] = [:]
        let rendererItems = self.rendererEventChannelHandler.renderItems
        for (_, item) in rendererItems.enumerated() {
            rendererDevices[item.name] = item.name
        }
        return rendererDevices
    }

    public func cast(rendererDevice: String) {
        if self.vlcMediaPlayer.isPlaying {
            self.vlcMediaPlayer.pause()
        }
        let rendererItems = self.rendererEventChannelHandler.renderItems
        let rendererItem = rendererItems.first {
            $0.name.contains(rendererDevice)
        }
        self.vlcMediaPlayer.setRendererItem(rendererItem)
        self.vlcMediaPlayer.play()
    }

    public func startRecording(saveDirectory: String) -> Bool {
        self.vlcMediaPlayer.startRecording(atPath: saveDirectory)
        return true
    }

    public func stopRecording() -> Bool {
        self.vlcMediaPlayer.stopRecording()
        return true
    }

    public func dispose() {
        (self.hostedView as? VLCHostView)?.onFirstLayout = nil
        self.mediaEventChannel.setStreamHandler(nil)
        self.rendererEventChannel.setStreamHandler(nil)
        self.rendererdiscoverers.removeAll()
        self.rendererEventChannelHandler.renderItems.removeAll()
        self.vlcMediaPlayer.stop()
    }

    func setMediaPlayerUrl(uri: String, isAssetUrl: Bool, autoPlay: Bool, hwAcc: Int, options: [String]) {
        self.vlcMediaPlayer.stop()

        var media: VLCMedia
        if isAssetUrl {
            guard let path = Bundle.main.path(forResource: uri, ofType: nil),
                  let m = VLCMedia(path: path)
            else {
                return
            }
            media = m
        }
        else {
            guard let url = URL(string: uri) else {
                return
            }
            guard let m = VLCMedia(url: url) else {
                return
            }
            media = m
        }

        // VLCKit 4.0 strictly distinguishes global libvlc options ("--foo=bar")
        // from per-media options (":foo=bar"). VLCMedia.addOption() takes the
        // per-media form, so any "--" prefix is silently dropped. On VLCKit
        // 3.6.x this was lenient; on 4.0.0a18 it isn't, which means options
        // like --avcodec-hw=none never reached the decoder and VideoToolbox
        // re-engaged on streams that should have stayed software-decoded
        // (interlaced H.264 → "buffer deadlock prevented" → black frames
        // even though playback "progressed"). Normalize every option to the
        // ":"-prefixed form before handing it to VLCMedia.
        func normalizeOption(_ raw: String) -> String {
            var s = raw
            if s.hasPrefix("--") {
                s = String(s.dropFirst(2))
            }
            if !s.hasPrefix(":") {
                s = ":" + s
            }
            return s
        }

        if !options.isEmpty {
            for option in options {
                media.addOption(normalizeOption(option))
            }
        }

        switch HWAccellerationType(rawValue: hwAcc) {
        case .HW_ACCELERATION_DISABLED:
            media.addOption(":codec=avcodec")
            media.addOption(":avcodec-hw=none")

        case .HW_ACCELERATION_DECODING:
            media.addOption(":codec=all")
            media.addOption(":no-mediacodec-dr")
            media.addOption(":no-omxil-dr")

        case .HW_ACCELERATION_FULL:
            media.addOption(":codec=all")

        case .HW_ACCELERATION_AUTOMATIC, .none:
            break
        }

        // VLCKit 4.0 configures its rendering pipeline (Metal/OpenGL) using
        // the drawable's bounds at assignment time. Flutter platform views
        // often start at (0,0,0,0) and only get real bounds on the first
        // layout pass. If we assign the drawable now with zero bounds, the
        // rendering surface stays zero-size and the video is black forever.
        //
        // Solution: if bounds are zero, defer drawable + media + play until
        // VLCHostView.layoutSubviews fires with non-zero bounds.
        let startPlayback = { [weak self] in
            guard let self = self else { return }
            // Defensive: clear any pending deferred-layout callback so a second
            // setMediaPlayerUrl call can't re-arm and run this twice.
            (self.hostedView as? VLCHostView)?.onFirstLayout = nil
            if self.vlcMediaPlayer.drawable == nil {
                self.vlcMediaPlayer.drawable = self.hostedView
            }
            self.vlcMediaPlayer.media = media
            self.vlcMediaPlayer.play()
            if !autoPlay {
                self.vlcMediaPlayer.stop()
            }
        }

        if self.hostedView.bounds.size == .zero {
            (self.hostedView as? VLCHostView)?.onFirstLayout = startPlayback
        } else {
            startPlayback()
        }
    }
}

class VLCRendererEventStreamHandler: NSObject, FlutterStreamHandler, VLCRendererDiscovererDelegate {
    private var rendererEventSink: FlutterEventSink?
    var renderItems: [VLCRendererItem] = .init()

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.rendererEventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.rendererEventSink = nil
        return nil
    }

    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        self.renderItems.append(item)

        let name = item.name
        DispatchQueue.main.async { [weak self] in
            guard let rendererEventSink = self?.rendererEventSink else { return }
            rendererEventSink([
                "event": "attached",
                "id": name,
                "name": name,
            ])
        }
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        if let index = renderItems.firstIndex(of: item) {
            self.renderItems.remove(at: index)
        }

        let name = item.name
        DispatchQueue.main.async { [weak self] in
            guard let rendererEventSink = self?.rendererEventSink else { return }
            rendererEventSink([
                "event": "detached",
                "id": name,
                "name": name,
            ])
        }
    }
}

class VLCPlayerEventStreamHandler: NSObject, FlutterStreamHandler, VLCMediaPlayerDelegate, VLCMediaDelegate {
    private var mediaEventSink: FlutterEventSink?
    weak var mediaPlayer: VLCMediaPlayer?

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.mediaEventSink = events
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        self.mediaEventSink = nil
        return nil
    }

    /// Builds the common player status dictionary shared by playing, buffering, and timeChanged events.
    private func buildPlayerStatusDict(from player: VLCMediaPlayer?) -> [String: Any] {
        return [
            "height": player?.videoSize.height ?? 0,
            "width": player?.videoSize.width ?? 0,
            "speed": player?.rate ?? 1,
            "duration": player?.media?.length.value ?? 0,
            "audioTracksCount": Int32(player?.audioTracks.count ?? 0),
            "activeAudioTrack": player?.selectedAudioTrackIndex() ?? -1,
            "spuTracksCount": Int32(player?.textTracks.count ?? 0),
            "activeSpuTrack": player?.selectedTextTrackIndex() ?? -1,
        ]
    }

    func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        // VLCKit 4.0: delegate callbacks fire on VLC's internal thread.
        // Flutter platform channels require the main thread.
        DispatchQueue.main.async { [weak self] in
            guard let mediaEventSink = self?.mediaEventSink else { return }

            switch newState {
            case .opening:
                mediaEventSink([
                    "event": "opening",
                ])

            case .paused:
                mediaEventSink([
                    "event": "paused",
                ])

            case .stopped, .stopping:
                mediaEventSink([
                    "event": "stopped",
                ])

            case .playing:
                var dict = self?.buildPlayerStatusDict(from: self?.mediaPlayer) ?? [:]
                dict["event"] = "playing"
                mediaEventSink(dict)

            case .buffering:
                let player = self?.mediaPlayer
                var dict = self?.buildPlayerStatusDict(from: player) ?? [:]
                dict["event"] = "timeChanged"
                dict["position"] = 0
                dict["buffer"] = 100.0
                dict["isPlaying"] = player?.isPlaying ?? false
                mediaEventSink(dict)

            case .error:
                mediaEventSink([
                    "event": "error",
                ])

            @unknown default:
                break
            }
        }
    }

    func mediaPlayerStartedRecording(_ player: VLCMediaPlayer) {
        DispatchQueue.main.async { [weak self] in
            guard let mediaEventSink = self?.mediaEventSink else { return }

            mediaEventSink([
                "event": "recording",
                "isRecording": true,
                "recordPath": "",
            ])
        }
    }

    func mediaPlayer(_ player: VLCMediaPlayer, recordingStoppedAt url: URL?) {
        let path = url?.path ?? ""
        DispatchQueue.main.async { [weak self] in
            guard let mediaEventSink = self?.mediaEventSink else { return }

            mediaEventSink([
                "event": "recording",
                "isRecording": false,
                "recordPath": path,
            ])
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        // VLCKit 4.0: this callback fires on VLC's internal thread with
        // timer.lock held. Accessing player properties here causes a mutex
        // assertion (vlc_player_Lock requires timer.lock NOT held).
        // Dispatch to main thread for both property access and event sink.
        let player = aNotification.object as? VLCMediaPlayer
        DispatchQueue.main.async { [weak self] in
            guard let mediaEventSink = self?.mediaEventSink else { return }

            if let position = player?.time.value {
                var dict = self?.buildPlayerStatusDict(from: player) ?? [:]
                dict["event"] = "timeChanged"
                dict["position"] = position
                dict["buffer"] = 100.0
                dict["isPlaying"] = player?.isPlaying ?? false
                mediaEventSink(dict)
            }
        }
    }
}

/// UIView subclass that ensures VLCKit 4.0's rendering subview always fills
/// the parent. VLCKit 4.0 calls addSubview: on the drawable to insert its
/// own video output view, but does not set autoresizing masks. When Flutter
/// resizes the platform view, the rendering subview would stay at its
/// initial (possibly zero) size, causing a black screen.
///
/// Also handles deferred drawable assignment: Flutter platform views often
/// start with zero bounds. VLCKit 4.0 configures its rendering pipeline
/// (Metal/OpenGL) using the drawable's bounds at assignment time. If those
/// bounds are zero, the pipeline renders to a zero-size surface and the
/// video stays black even after the view is resized. The fix is to defer
/// drawable assignment until the first layout pass with non-zero bounds.
class VLCHostView: UIView {
    /// Closure executed once when the view first gets non-zero bounds.
    /// Used to defer VLCMediaPlayer.drawable assignment + play().
    var onFirstLayout: (() -> Void)?

    /// Safety net: Flutter's compositor sets `frame` directly on platform views,
    /// which may not trigger `layoutSubviews`. Intercept frame changes to ensure
    /// the deferred callback fires when the view gets non-zero bounds.
    override var frame: CGRect {
        get { super.frame }
        set {
            super.frame = newValue
            if newValue.size != .zero, let setup = onFirstLayout {
                onFirstLayout = nil
                setup()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Execute deferred drawable setup once we have real bounds.
        if bounds.size != .zero, let setup = onFirstLayout {
            onFirstLayout = nil
            setup()
        }
        for subview in subviews {
            subview.frame = bounds
        }
    }
}

enum DataSourceType: Int {
    case ASSET = 0
    case NETWORK = 1
    case FILE = 2
}

enum HWAccellerationType: Int {
    case HW_ACCELERATION_AUTOMATIC = 0
    case HW_ACCELERATION_DISABLED = 1
    case HW_ACCELERATION_DECODING = 2
    case HW_ACCELERATION_FULL = 3
}

extension VLCMediaPlayer {
    func selectedAudioTrackIndex() -> Int32 {
        if let index = audioTracks.firstIndex(where: { $0.isSelected }) {
            return Int32(index)
        }
        return -1
    }

    func selectedTextTrackIndex() -> Int32 {
        if let index = textTracks.firstIndex(where: { $0.isSelected }) {
            return Int32(index)
        }
        return -1
    }

    func selectedVideoTrackIndex() -> Int32 {
        if let index = videoTracks.firstIndex(where: { $0.isSelected }) {
            return Int32(index)
        }
        return -1
    }

    func textTracksDictionary() -> [Int: String] {
        var result: [Int: String] = [:]
        for (index, track) in textTracks.enumerated() {
            result[index] = track.trackName
        }
        return result
    }

    func audioTracksDictionary() -> [Int: String] {
        var result: [Int: String] = [:]
        for (index, track) in audioTracks.enumerated() {
            result[index] = track.trackName
        }
        return result
    }

    func videoTracksDictionary() -> [Int: String] {
        var result: [Int: String] = [:]
        for (index, track) in videoTracks.enumerated() {
            result[index] = track.trackName
        }
        return result
    }

    func rendererServices() -> [String] {
        let renderers = VLCRendererDiscoverer.list()
        var services: [String] = []

        renderers?.forEach { VLCRendererDiscovererDescription in
            services.append(VLCRendererDiscovererDescription.name)
        }
        return services
    }
}
