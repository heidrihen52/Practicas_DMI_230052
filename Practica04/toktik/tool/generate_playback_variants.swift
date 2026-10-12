// Run from the Flutter project root. Only derived playback copies are replaced.
import Foundation
import AVFoundation
@main struct Convert {
 static func main() async throws {
  let base = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("assets/videos", isDirectory: true)
  let playback = base.appendingPathComponent("playback", isDirectory: true)
  try FileManager.default.createDirectory(at: playback, withIntermediateDirectories: true)
  let videos = try FileManager.default.contentsOfDirectory(at: base,
      includingPropertiesForKeys: nil).filter { $0.pathExtension.lowercased() == "mp4" }
      .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
  for original in videos {
   let n = original.deletingPathExtension().lastPathComponent
   let source = AVURLAsset(url: original)
   let output = playback.appendingPathComponent(original.lastPathComponent)
   guard let session = AVAssetExportSession(asset: source, presetName: AVAssetExportPreset1280x720) else { fatalError("No exporter \(n)") }
   let composition = AVMutableVideoComposition(propertiesOf: source)
   composition.sourceTrackIDForFrameTiming = kCMPersistentTrackID_Invalid
   composition.frameDuration = CMTime(value: 1, timescale: 30)
   session.videoComposition = composition
   session.shouldOptimizeForNetworkUse = true
   if FileManager.default.fileExists(atPath: output.path) {
    try FileManager.default.removeItem(at: output)
   }
   try await session.export(to: output, as: .mp4)
   let result = AVURLAsset(url: output)
   let originalAudio = try await source.loadTracks(withMediaType: .audio)
   let audio = try await result.loadTracks(withMediaType: .audio)
   guard audio.count == originalAudio.count else {fatalError("Changed audio \(n)")}
   let t = try await result.loadTracks(withMediaType: .video)[0]
   let size = try await t.load(.naturalSize)
   let tr = try await t.load(.preferredTransform)
   let dims = size.applying(tr)
   let fps = try await t.load(.nominalFrameRate)
   guard fps <= 30.1 else { fatalError("FPS above 30") }
   print("\(n).mp4 fps=\(fps) \(abs(dims.width))x\(abs(dims.height)) audio=\(audio.count)")
   fflush(stdout)
  }
 }
}
