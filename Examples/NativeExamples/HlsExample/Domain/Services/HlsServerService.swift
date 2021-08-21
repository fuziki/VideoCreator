//
//  HlsServerService.swift
//  HlsExample
//
//  Created by fuziki on 2021/08/13.
//

import Foundation
import Swifter

protocol HlsServerService: AnyObject {
    func onSegmentData(data: Data)
    var segmentDurationMicroSec: Int { get set }
}

class DefaultHlsServerService: HlsServerService {
    private let server = HttpServer()

    private var sequences: [(sequence: Int, data: Data)] = []
    private var initData: Data?

    private var sequence: Int = -1

    public var segmentDurationMicroSec: Int = 1_000_000

    init() {
        server["/hello"] = { (request: HttpRequest) -> HttpResponse in
            print("request: \(request.path)")
            let body = """
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
<head>
<title>VideoCreator</title>
</head>
<video id="video" width="240" height="360" autoplay muted></video>
<script>
  var video = document.getElementById('video');
  var videoSrc = 'hls.m3u8';
  if (Hls.isSupported()) {
    var hls = new Hls();
    hls.loadSource(videoSrc);
    hls.attachMedia(video);
  } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
    video.src = videoSrc;
  }
</script>
"""
            return .ok(.htmlBody(body))
        }
        server["/hls.m3u8"] = { [weak self] (request: HttpRequest) -> HttpResponse in
            let body: HttpResponseBody = .data(self!.m3u8.data(using: .utf8)!, contentType: "application/x-mpegURL")
            print("request hls: \(request.path), \(self!.sequences.first!.sequence) ~ \(self!.sequences.last!.sequence)")
            if self!.sequence < 5 { return .notFound }
            return .ok(body)
        }
        server["init.mp4"] = { [weak self] (request: HttpRequest) -> HttpResponse in
            let body: HttpResponseBody = .data(self!.initData!, contentType: "video/mp4")
            print("request path init.mp4: \(request.path)")
            return .ok(body)
        }
        server["/files/:path"] = { [weak self] (request: HttpRequest) -> HttpResponse in
            guard let data = self!.sequences.first(where: { request.path.hasPrefix("/files/sequence\($0.sequence)") })?.data else {
                print("request path: \(request.path) no data, \(self!.sequences.first!.sequence) ~ \(self!.sequences.last!.sequence)")
                return .notFound
            }
            let body: HttpResponseBody = .data(data, contentType: "video/iso.segment")
            print("request path: \(request.path)")
            return .ok(body)
        }
        // swiftlint:disable force_try
        try! server.start(8080, forceIPv4: true, priority: .default)
    }

    private var m3u8: String {
        let durationStr = String(format: "%1.5f", Double(segmentDurationMicroSec) / 1_000_000)
        let template = """
#EXTM3U
#EXT-X-TARGETDURATION:1
#EXT-X-VERSION:9
#EXT-X-MEDIA-SEQUENCE:\(sequence - 2)
#EXT-X-MAP:URI="init.mp4"
#EXTINF:\(durationStr),
files/sequence\(sequence - 2).m4s
#EXTINF:\(durationStr),
files/sequence\(sequence - 1).m4s
#EXTINF:\(durationStr),
files/sequence\(sequence).m4s
"""
        return template
    }

    public func onSegmentData(data: Data) {

        sequence += 1

        if sequence == 0 {
            initData = data
            return
        }

        sequences.append((sequence: sequence, data: data))

        if sequences.count > 5 {
            sequences.removeFirst()
        }
    }
}
