import SwiftUI
import WebKit

// MARK: - VideoPlatformPlayer

/// A SwiftUI wrapper around WKWebView that embeds platform videos
/// (YouTube, TikTok, Instagram) with JavaScript bridge control.
///
/// Provides:
/// - Play/pause/seek via JS bridge
/// - Current time polling (30Hz)
/// - Playback state change notifications
/// - Platform-specific embed HTML with optimized player configurations
struct VideoPlatformPlayer: UIViewRepresentable {

    // MARK: - Input Bindings

    let videoUrl: String
    let platform: SourcePlatform
    @Binding var currentTime: TimeInterval
    @Binding var isPlaying: Bool
    @Binding var duration: TimeInterval
    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onReady: ((TimeInterval) -> Void)?
    var onStateChange: ((PlaybackState) -> Void)?

    // MARK: - Playback State

    enum PlaybackState: Int, Sendable {
        case unstarted = -1
        case ended = 0
        case playing = 1
        case paused = 2
        case buffering = 3
        case cued = 5
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Add script message handler for JS → Swift communication
        config.userContentController.add(context.coordinator, name: "videoBridge")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        // Load the appropriate embed HTML
        let html = embedHTML(for: videoUrl, platform: platform)
        webView.loadHTMLString(html, baseURL: nil)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Seek if the bound currentTime has changed significantly
        // (more than 0.5s difference from last known seek target)
        if abs(context.coordinator.lastSeekTarget - currentTime) > 0.5 {
            context.coordinator.lastSeekTarget = currentTime
            let js = "seekTo(\(currentTime));"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - JavaScript Commands

    /// Send a play command to the embedded video player.
    static func play(webView: WKWebView) {
        webView.evaluateJavaScript("playVideo();", completionHandler: nil)
    }

    /// Send a pause command to the embedded video player.
    static func pause(webView: WKWebView) {
        webView.evaluateJavaScript("pauseVideo();", completionHandler: nil)
    }

    /// Send a seek command to the embedded video player.
    static func seek(webView: WKWebView, to time: TimeInterval) {
        webView.evaluateJavaScript("seekTo(\(time));", completionHandler: nil)
    }

    // MARK: - Embed HTML Templates

    private func embedHTML(for url: String, platform: SourcePlatform) -> String {
        switch platform {
        case .youtube:
            return youtubeEmbedHTML(videoId: extractYouTubeID(from: url) ?? "")
        case .tiktok:
            return tiktokEmbedHTML(url: url)
        case .instagram:
            return instagramEmbedHTML(url: url)
        }
    }

    // MARK: - YouTube Embed

    private func youtubeEmbedHTML(videoId: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
                #player { width: 100%; height: 100%; position: absolute; top: 0; left: 0; }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script src="https://www.youtube.com/iframe_api"></script>
            <script>
                var player;
                var updateInterval;

                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        videoId: '\(videoId)',
                        playerVars: {
                            playsinline: 1,
                            rel: 0,
                            modestbranding: 1,
                            enablejsapi: 1,
                            autoplay: 0,
                            controls: 1,
                            origin: 'https://cooksy.app'
                        },
                        events: {
                            onReady: onPlayerReady,
                            onStateChange: onPlayerStateChange,
                            onError: onPlayerError
                        }
                    });
                }

                function onPlayerReady(event) {
                    try {
                        var dur = player.getDuration ? player.getDuration() : 0;
                        window.webkit.messageHandlers.videoBridge.postMessage({
                            type: 'ready',
                            duration: dur
                        });
                        startTimeUpdates();
                    } catch(e) {
                        console.error('Player ready error:', e);
                    }
                }

                function onPlayerStateChange(event) {
                    window.webkit.messageHandlers.videoBridge.postMessage({
                        type: 'stateChange',
                        state: event.data
                    });
                }

                function onPlayerError(event) {
                    window.webkit.messageHandlers.videoBridge.postMessage({
                        type: 'error',
                        errorCode: event.data
                    });
                }

                function startTimeUpdates() {
                    if (updateInterval) clearInterval(updateInterval);
                    updateInterval = setInterval(function() {
                        try {
                            if (player && player.getCurrentTime && player.getDuration) {
                                var time = player.getCurrentTime();
                                var dur = player.getDuration();
                                if (!isNaN(time) && !isNaN(dur)) {
                                    window.webkit.messageHandlers.videoBridge.postMessage({
                                        type: 'timeUpdate',
                                        currentTime: time,
                                        duration: dur
                                    });
                                }
                            }
                        } catch(e) {
                            console.error('Time update error:', e);
                        }
                    }, 33); // ~30Hz
                }

                function seekTo(time) {
                    try {
                        if (player && player.seekTo) {
                            player.seekTo(time, true);
                        }
                    } catch(e) {
                        console.error('Seek error:', e);
                    }
                }

                function playVideo() {
                    try {
                        if (player && player.playVideo) player.playVideo();
                    } catch(e) {
                        console.error('Play error:', e);
                    }
                }

                function pauseVideo() {
                    try {
                        if (player && player.pauseVideo) player.pauseVideo();
                    } catch(e) {
                        console.error('Pause error:', e);
                    }
                }

                // Cleanup on page unload
                window.addEventListener('beforeunload', function() {
                    if (updateInterval) clearInterval(updateInterval);
                });
            </script>
        </body>
        </html>
        """
    }

    // MARK: - TikTok Embed

    private func tiktokEmbedHTML(url: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: #000; display: flex; align-items: center; justify-content: center; overflow: hidden; }
            </style>
        </head>
        <body>
            <blockquote class="tiktok-embed" cite="\(url)" data-video-id="" style="max-width: 100%; min-width: 280px;">
                <section></section>
            </blockquote>
            <script async src="https://www.tiktok.com/embed.js"></script>
            <script>
                // TikTok embed does not provide a JS API for playback control.
                // Poll for video element as fallback.
                var checkVideo = setInterval(function() {
                    var video = document.querySelector('video');
                    if (video) {
                        clearInterval(checkVideo);
                        video.style.width = '100%';
                        video.style.height = '100%';
                        video.style.objectFit = 'contain';

                        // Bridge current time
                        setInterval(function() {
                            window.webkit.messageHandlers.videoBridge.postMessage({
                                type: 'timeUpdate',
                                currentTime: video.currentTime,
                                duration: video.duration || 0
                            });
                        }, 33);
                    }
                }, 500);

                function seekTo(time) {
                    var video = document.querySelector('video');
                    if (video) video.currentTime = time;
                }

                function playVideo() {
                    var video = document.querySelector('video');
                    if (video) video.play();
                }

                function pauseVideo() {
                    var video = document.querySelector('video');
                    if (video) video.pause();
                }
            </script>
        </body>
        </html>
        """
    }

    // MARK: - Instagram Embed

    private func instagramEmbedHTML(url: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: #000; display: flex; align-items: center; justify-content: center; overflow: hidden; }
            </style>
        </head>
        <body>
            <blockquote class="instagram-media"
                data-instgrm-permalink="\(url)"
                data-instgrm-version="14"
                data-instgrm-captioned
                style="background:#FFF; border:0; border-radius:3px; box-shadow:0 0 1px 0 rgba(0,0,0,0.5),0 1px 10px 0 rgba(0,0,0,0.15); margin: 1px; max-width:540px; min-width:326px; padding:0; width:99.375%;">
            </blockquote>
            <script async src="//www.instagram.com/embed.js"></script>
            <script>
                // Instagram embed does not provide a JS API.
                // Poll for video element as fallback.
                var checkVideo = setInterval(function() {
                    var video = document.querySelector('video');
                    if (video) {
                        clearInterval(checkVideo);
                        video.style.width = '100%';
                        video.style.height = '100%';
                        video.style.objectFit = 'contain';

                        setInterval(function() {
                            window.webkit.messageHandlers.videoBridge.postMessage({
                                type: 'timeUpdate',
                                currentTime: video.currentTime,
                                duration: video.duration || 0
                            });
                        }, 33);
                    }
                }, 500);

                function seekTo(time) {
                    var video = document.querySelector('video');
                    if (video) video.currentTime = time;
                }

                function playVideo() {
                    var video = document.querySelector('video');
                    if (video) video.play();
                }

                function pauseVideo() {
                    var video = document.querySelector('video');
                    if (video) video.pause();
                }
            </script>
        </body>
        </html>
        """
    }

    // MARK: - URL Helpers

    private func extractYouTubeID(from url: String) -> String? {
        let patterns = [
            "(?<=v=)[^&#]+",
            "(?<=be/)[^&#]+",
            "(?<=embed/)[^&#]+",
            "(?<=/v/)[^&#]+",
            "(?<=/live/)[^&#]+"
        ]
        for pattern in patterns {
            if let range = url.range(of: pattern, options: .regularExpression) {
                return String(url[range])
            }
        }
        // Handle youtu.be short URLs
        if let url = URL(string: url), let pathComponent = url.pathComponents.dropFirst().first {
            return pathComponent
        }
        return nil
    }
}

// MARK: - Coordinator

extension VideoPlatformPlayer {
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: VideoPlatformPlayer
        var lastSeekTarget: TimeInterval = 0

        init(_ parent: VideoPlatformPlayer) {
            self.parent = parent
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }

            switch type {
            case "timeUpdate":
                if let time = body["currentTime"] as? Double {
                    // Only update if not currently being dragged/seeked
                    if abs(self.lastSeekTarget - time) > 0.3 {
                        parent.currentTime = time
                    }
                    parent.onTimeUpdate?(time)
                }
                if let dur = body["duration"] as? Double, dur > 0 {
                    parent.duration = dur
                }

            case "stateChange":
                let state = body["state"] as? Int ?? 0
                let playbackState = PlaybackState(rawValue: state) ?? .unstarted
                // YT states: -1=unstarted, 0=ended, 1=playing, 2=paused, 3=buffering, 5=cued
                parent.isPlaying = (state == PlaybackState.playing.rawValue || state == PlaybackState.buffering.rawValue)
                parent.onStateChange?(playbackState)

            case "ready":
                if let dur = body["duration"] as? Double {
                    parent.duration = dur
                    parent.onReady?(dur)
                }

            case "error":
                let errorCode = body["errorCode"] as? Int ?? 0
                logError("Video player error: code \(errorCode)")

            default:
                break
            }
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Page loaded — embed scripts may still be initializing
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            logError("Navigation failed: \(error.localizedDescription)")
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            logError("Provisional navigation failed: \(error.localizedDescription)")
        }

        // MARK: - Logging

        private func logError(_ message: String) {
            #if DEBUG
            print("[VideoPlatformPlayer] \(message)")
            #endif
        }
    }
}
