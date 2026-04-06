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

        self.hostedView = UIView(frame: frame)
        self.vlcMediaPlayer = VLCMediaPlayer()
        self.mediaEventChannel = mediaEventChannel
        self.mediaEventChannelHandler = VLCPlayerEventStreamHandler()
        self.rendererEventChannel = rendererEventChannel
        self.rendererEventChannelHandler = VLCRendererEventStreamHandler()
        //
        self.mediaEventChannel.setStreamHandler(self.mediaEventChannelHandler)
        self.rendererEventChannel.setStreamHandler(self.rendererEventChannelHandler)
        self.vlcMediaPlayer.drawable = self.hostedView
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
        let drawable: UIView = self.vlcMediaPlayer.drawable as! UIView
        let size = drawable.frame.size
        UIGraphicsBeginImageContextWithOptions(size, _: false, _: 0.0)
        let rec = drawable.frame
        drawable.drawHierarchy(in: rec, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let byteArray = (image ?? UIImage()).pngData()
        //
        return byteArray?.base64EncodedString()
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
            tracks[index].selectedExclusively = true
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
            tracks[index].selectedExclusively = true
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
            tracks[index].selectedExclusively = true
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
            guard let url = URL(string: uri),
                  let m = VLCMedia(url: url)
            else {
                return
            }
            media = m
        }

        if !options.isEmpty {
            for option in options {
                media.addOption(option)
            }
        }

        switch HWAccellerationType(rawValue: hwAcc) {
        case .HW_ACCELERATION_DISABLED:
            media.addOption("--codec=avcodec")

        case .HW_ACCELERATION_DECODING:
            media.addOption("--codec=all")
            media.addOption(":no-mediacodec-dr")
            media.addOption(":no-omxil-dr")

        case .HW_ACCELERATION_FULL:
            media.addOption("--codec=all")

        case .HW_ACCELERATION_AUTOMATIC:
            break

        case .none:
            break
        }

        self.vlcMediaPlayer.media = media
        self.vlcMediaPlayer.play()
        if !autoPlay {
            self.vlcMediaPlayer.stop()
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

        guard let rendererEventSink = self.rendererEventSink else { return }
        rendererEventSink([
            "event": "attached",
            "id": item.name,
            "name": item.name,
        ])
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        if let index = renderItems.firstIndex(of: item) {
            self.renderItems.remove(at: index)
        }

        guard let rendererEventSink = self.rendererEventSink else { return }
        rendererEventSink([
            "event": "detached",
            "id": item.name,
            "name": item.name,
        ])
    }
}

class VLCPlayerEventStreamHandler: NSObject, FlutterStreamHandler, VLCMediaPlayerDelegate, VLCMediaDelegate {
    private var mediaEventSink: FlutterEventSink?

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.mediaEventSink = events
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        self.mediaEventSink = nil
        return nil
    }

    func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        guard let mediaEventSink = self.mediaEventSink else { return }

        // Note: in VLCKit 4.0 we no longer receive the player via notification,
        // so track counts are not available in state change callbacks.
        // They are reported in mediaPlayerTimeChanged instead.

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
            mediaEventSink([
                "event": "playing",
                "height": 0,
                "width": 0,
                "speed": 1,
                "duration": 0,
                "audioTracksCount": 0,
                "activeAudioTrack": 0,
                "spuTracksCount": 0,
                "activeSpuTrack": 0,
            ])

        case .buffering:
            mediaEventSink([
                "event": "timeChanged",
                "height": 0,
                "width": 0,
                "speed": 1,
                "duration": 0,
                "position": 0,
                "buffer": 100.0,
                "audioTracksCount": 0,
                "activeAudioTrack": 0,
                "spuTracksCount": 0,
                "activeSpuTrack": 0,
                "isPlaying": false,
            ])

        case .error:
            mediaEventSink([
                "event": "error",
            ])

        @unknown default:
            break
        }
    }

    func mediaPlayerStartedRecording(_ player: VLCMediaPlayer) {
        guard let mediaEventSink = self.mediaEventSink else { return }

        mediaEventSink([
            "event": "recording",
            "isRecording": true,
            "recordPath": "",
        ])
    }

    func mediaPlayer(_ player: VLCMediaPlayer, recordingStoppedAtURL url: URL?) {
        guard let mediaEventSink = self.mediaEventSink else { return }

        mediaEventSink([
            "event": "recording",
            "isRecording": false,
            "recordPath": url?.path ?? "",
        ])
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let mediaEventSink = self.mediaEventSink else { return }

        let player = aNotification.object as? VLCMediaPlayer
        //
        let height = player?.videoSize.height ?? 0
        let width = player?.videoSize.width ?? 0
        let speed = player?.rate ?? 1
        let duration = player?.media?.length.value ?? 0
        let audioTracksCount = Int32(player?.audioTracks.count ?? 0)
        let activeAudioTrack = player?.selectedAudioTrackIndex() ?? -1
        let spuTracksCount = Int32(player?.textTracks.count ?? 0)
        let activeSpuTrack = player?.selectedTextTrackIndex() ?? -1
        let buffering = 100.0
        let isPlaying = player?.isPlaying ?? false
        //
        if let position = player?.time.value {
            mediaEventSink([
                "event": "timeChanged",
                "height": height,
                "width": width,
                "speed": speed,
                "duration": duration,
                "position": position,
                "buffer": buffering,
                "audioTracksCount": audioTracksCount,
                "activeAudioTrack": activeAudioTrack,
                "spuTracksCount": spuTracksCount,
                "activeSpuTrack": activeSpuTrack,
                "isPlaying": isPlaying,
            ])
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
