//
//  UIPiPView.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 21/08/24.
//

import UIKit
import AVKit
import AVFoundation
import RealtimeKit
import RTKWebRTC

class SampleBufferVideoCallView: UIView {
    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }
    
    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }
}

class PipUserView : UIView {
    let videoDisplayView = SampleBufferVideoCallView()
    let profileAvatarView: RtkAvatarView = {
        let view = RtkAvatarView()
        view.setInitialName(font: UIFont.boldSystemFont(ofSize: 12))
        return view
    }()
    private var frameRenderer: RtkPipFrameRender?
    private let infoLable: RtkLabel
    private var participant: RtkMeetingParticipant?
    private var flipFrameHorizonatlly: Bool
    
    init(flipFrameHorizonatlly: Bool) {
        self.flipFrameHorizonatlly = flipFrameHorizonatlly
        infoLable = RtkUIUtility.createLabel()
        infoLable.font = UIFont.systemFont(ofSize: 12)
        infoLable.numberOfLines = 2
        super.init(frame: .zero)
        createSubView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createSubView() {
        self.addSubViews(profileAvatarView)
        self.addSubview(infoLable)
        self.addSubview(self.videoDisplayView)
        self.infoLable.set(.centerView(self), .leading(self,20,.greaterThanOrEqual))
        profileAvatarView.set(.width(30), .height(30),.centerView(self))
        self.videoDisplayView.set(.fillSuperView(self))
    }
    
    func clean() {
        self.participant?.removeParticipantUpdateListener(participantUpdateListener: self)
        removeFrameFetcher()
    }
    
    func setParticipant(participant: RtkMeetingParticipant?) {
        self.participant?.removeParticipantUpdateListener(participantUpdateListener: self)
        if let participant = participant {
            self.profileAvatarView.set(participant: participant)
            self.setFrameFetcher(participant: participant)
            self.videoDisplayView.isHidden = false
            participant.addParticipantUpdateListener(participantUpdateListener: self)
        }
        self.participant = participant
        updateVideoView()
    }
    
    private func setFrameFetcher(participant: RtkMeetingParticipant) {
        removeFrameFetcher()
        let frameRenderer = RtkPipFrameRender(size: CGSize(width: self.bounds.size.width*2.0, height: self.bounds.size.height*2.0), displayLayer: self.videoDisplayView.sampleBufferDisplayLayer, flipFrame: self.flipFrameHorizonatlly)
        //        participant.videoTrack?.addRenderer(renderer: frameRenderer)
        self.frameRenderer = frameRenderer
    }
    
    private func removeFrameFetcher() {
        if let frameRenderer = self.frameRenderer, let participant = self.participant {
            frameRenderer.clean()
            //            participant.videoTrack?.removeRenderer(renderer: frameRenderer)
        }
        self.frameRenderer = nil
    }
}

extension PipUserView : RtkParticipantUpdateListener {
    func onAudioUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        
    }
    
    func onPinned(participant: RtkMeetingParticipant) {
        
    }
    
    func onScreenShareUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        
    }
    
    func onUnpinned(participant: RtkMeetingParticipant) {
        
    }
    
    func onUpdate(participant: RtkMeetingParticipant) {
        
    }
    
    
    func onVideoUpdate(participant: RtkMeetingParticipant, isEnabled: Bool) {
        
        updateVideoView()
    }
    
    func updateVideoView() {
        if self.participant == nil {
            self.infoLable.isHidden = false
            self.profileAvatarView.isHidden = true
            self.videoDisplayView.isHidden = true
        }else {
            
            if self.participant?.videoEnabled == false {
                self.infoLable.isHidden = true
                self.profileAvatarView.isHidden = false
                self.videoDisplayView.isHidden = true
            }else {
                self.profileAvatarView.isHidden = true
                self.videoDisplayView.isHidden = false
            }
        }
    }
    
}


class PipDisplayView: UIView {
    var localUserView = PipUserView(flipFrameHorizonatlly: true)
    var otherUserView = PipUserView(flipFrameHorizonatlly: false)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubView()
    }
    
    private func createSubView() {
        self.addSubview(localUserView)
        self.addSubview(otherUserView)
        localUserView.set(.leading(self),
                          .top(self),
                          .trailing(self),
                          .equateAttribute(.height, toView: self, toAttribute: .height, withRelation: .equal, multiplier: 0.5))
        otherUserView.set(.below(localUserView),
                          .leading(self),
                          .bottom(self),
                          .trailing(self))
    }
    
    func clean() {
        self.localUserView.clean()
        self.otherUserView.clean()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RtkPipController: NSObject {
    private var videoView: UIView
    private var pipController: AVPictureInPictureController?
    var isPlayBackPaused = true
    private(set) var localUser: RtkSelfParticipant
    var videoViewToDisplayOnPip = PipDisplayView()
    private(set) var otherUser: RtkRemoteParticipant?
    private let size: CGSize
    private let scaleFactorWidth = 0.25
    private let scaleFactorHeight = 0.20
    
    init?(renderingView: UIView, localUser: RtkSelfParticipant) {
        self.videoView = renderingView
        self.localUser = localUser
        let screenSize = UIScreen.main.bounds.size
        size = CGSize(width: screenSize.width*scaleFactorWidth, height: screenSize.height*scaleFactorHeight)
        super.init()
        
        if #available(iOS 15.0, *) {
            let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
            pipVideoCallViewController.preferredContentSize = size
            pipVideoCallViewController.view.addSubview(videoViewToDisplayOnPip)
            videoViewToDisplayOnPip.set(.fillSuperView(pipVideoCallViewController.view))
            videoViewToDisplayOnPip.backgroundColor = DesignLibrary.shared.color.background.shade1000
            let pipContentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: self.videoView,
                contentViewController: pipVideoCallViewController)
            pipController = AVPictureInPictureController(contentSource: pipContentSource)
            pipController?.delegate = self
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
            
        } else {
            // Fallback on earlier versions
            return nil
        }
    }
    
    func clean() {
        self.videoViewToDisplayOnPip.clean()
    }
    
    func setSecondaryUser(otherParticipant: RtkRemoteParticipant?) {
        self.otherUser = otherParticipant
        if pipController?.isPictureInPictureActive == true {
            self.videoViewToDisplayOnPip.otherUserView.setParticipant(participant: self.otherUser)
        }
    }
    
}

extension RtkPipController : AVPictureInPictureControllerDelegate {
    open func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        
    }
    
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[DYTE_PIP] Delegate PiP Did start.")
        self.videoViewToDisplayOnPip.localUserView.setParticipant(participant: self.localUser)
        self.videoViewToDisplayOnPip.otherUserView.setParticipant(participant: self.otherUser)
    }
    
    open func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("[DYTE_PIP] Delegate  PiP will stop shortly.")
        self.videoViewToDisplayOnPip.clean()
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[DYTE_PIP] Delegate  PiP DID stop shortly.")
    }
    
    open func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        let error = error as NSError
        print("[DYTE_PIP] Delegate Failed to start PiP with error: \(error.localizedDescription). \(error)")
    }
}

class RtkPipFrameRender : NSObject, RTKRTCVideoRenderer {
    
    var displayLayer : AVSampleBufferDisplayLayer
    let targetSize: CGSize
    let flipFrame: Bool
    
    init(size:CGSize, displayLayer: AVSampleBufferDisplayLayer, flipFrame: Bool = false) {
        self.displayLayer = displayLayer
        self.targetSize = size
        self.flipFrame = flipFrame
    }
    
    func setSize(_ size: CGSize) {
        
    }
    var shouldRenderFrame = true
    
    func clean() {
        shouldRenderFrame = false
    }
    private var pixelBufferPool: CVPixelBufferPool?
    private var frameProcessingQueue = DispatchQueue(label: "FrameProcessingQueue")
    private let synchronizationQueue = DispatchQueue(label: "com.yourapp.synchronizationQueue")
    
    var isReady = true
    func renderFrame(_ frame: RTKRTCVideoFrame?) {
        guard let frame = frame else {
            print("[DYTE_PIP] Frame passed is nil")
            return
        }
        
        synchronizationQueue.async { [weak self] in
            guard let self = self else {return}
            if self.isReady {
                self.isReady = false
                self.frameProcessingQueue.async { [weak self] in
                    guard let self = self else {return}
                    if let sampleBuffer = self.handleRTCVideoFrame(frame) {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else {return}
                            if self.displayLayer.isReadyForMoreMediaData && shouldRenderFrame {
                                self.displayLayer.enqueue(sampleBuffer)
                            }
                        }
                    }
                    self.synchronizationQueue.async {
                        self.isReady = true
                    }
                }
            }
        }
    }
    
    // Helper function to convert RTCVideoFrame to CVPixelBuffer
    private func frameToPixelBuffer(frame: RTKRTCVideoFrame) -> CVPixelBuffer? {
        if let buffer = frame.buffer as? RTKRTCCVPixelBuffer {
            return buffer.pixelBuffer
        }else if let buffer = frame.buffer as? RTKRTCI420Buffer {
            return createPixelBuffer(from: buffer, targetSize: self.targetSize)
        }
        print("[DYTE_PIP] buffer should be of type RTKRTCCVPixelBuffer")
        return nil
        
    }
    
    private func handleRTCVideoFrame(_ frame: RTKRTCVideoFrame) -> CMSampleBuffer? {
        // Example: Convert frame to CVPixelBuffer for further processing
        if let pixelBuffer = frameToPixelBuffer(frame: frame) {
            // Use pixelBuffer as needed
            return createSampleBufferFromPixelBuffer(pixelBuffer: pixelBuffer)
        }
        print("[DYTE_PIP] pixel buffer cannot be created")
        return nil
    }
    
    var pixelBuffer: CVPixelBuffer?
    var pixelBufferKey: String?
    
    private func createPixelBuffer(from i420Buffer: RTKRTCI420Buffer, targetSize: CGSize) -> CVPixelBuffer? {
        // Calculate the scale factor based on the target size and the original buffer size
        let widthScaleFactor = targetSize.width / CGFloat(i420Buffer.width)
        let heightScaleFactor = targetSize.height / CGFloat(i420Buffer.height)
        
        // Choose the smaller scale factor to maintain aspect ratio
        let scaleFactor = min(widthScaleFactor, heightScaleFactor)
        
        // Calculate the new width and height based on the scale factor
        var width = Int(CGFloat(i420Buffer.width) * scaleFactor)
        var height = Int(CGFloat(i420Buffer.height) * scaleFactor)
        
        if width%2 != 0 {
            width += 1
        }
        if height%2 != 0 {
            height += 1
        }
        
        let tempKey = "\(width)_\(height)"
        if tempKey != pixelBufferKey {
            pixelBuffer = nil
            pixelBufferKey = tempKey
        }
        
        if pixelBuffer == nil {
            let attributes: [String: Any] = [
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]
            
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                attributes as CFDictionary,
                &pixelBuffer
            )
            // Create a CVPixelBuffer with the specified width, height, and pixel format type
            guard status == kCVReturnSuccess else {
                print("Failed to create CVPixelBuffer.")
                return nil
            }
        }
        
        
        guard let createdPixelBuffer = pixelBuffer else {
            print("Failed to load CVPixelBuffer.")
            return nil
        }
        
        // Lock the pixel buffer base address for writing
        CVPixelBufferLockBaseAddress(createdPixelBuffer, [])
        
        // Resize and copy the Y plane
        if let yBaseAddress = CVPixelBufferGetBaseAddressOfPlane(createdPixelBuffer, 0) {
            let yDestination = yBaseAddress.assumingMemoryBound(to: UInt8.self)
            let ySource = i420Buffer.dataY
            let yStride = CVPixelBufferGetBytesPerRowOfPlane(createdPixelBuffer, 0)
            
            for row in 0..<height {
                let origRow = Int(ceilf(Float(row) / Float(scaleFactor)))
                for col in 0..<width {
                    let origCol = Int(ceilf(Float(col) / Float(scaleFactor)))
                    if flipFrame {
                        let flippedCol = Int(i420Buffer.width) - 1 - origCol
                        yDestination[row * yStride + col] = ySource[origRow * Int(i420Buffer.strideY) + flippedCol]
                    }else {
                        yDestination[row * yStride + col] = ySource[origRow * Int(i420Buffer.strideY) + origCol]
                    }
                }
            }
        }
        
        // Resize and copy the UV plane (interleaved UV format)
        if let uvBaseAddress = CVPixelBufferGetBaseAddressOfPlane(createdPixelBuffer, 1) {
            let uvDestination = uvBaseAddress.assumingMemoryBound(to: UInt8.self)
            let uSource = i420Buffer.dataU
            let vSource = i420Buffer.dataV
            let uvStride = CVPixelBufferGetBytesPerRowOfPlane(createdPixelBuffer, 1)
            
            for row in 0..<height / 2 {
                let origRow = Int(ceilf(Float(row) / Float(scaleFactor)))
                
                for col in 0..<width / 2 {
                    let origCol = Int(ceilf(Float(col) / Float(scaleFactor)))
                    
                    let uvIndex = row * uvStride + col * 2
                    if flipFrame {
                        let flippedCol = Int(i420Buffer.width/2) - 1 - origCol
                        // Interleave U and V
                        uvDestination[uvIndex] = uSource[origRow * Int(i420Buffer.strideU) + flippedCol]
                        uvDestination[uvIndex + 1] = vSource[origRow * Int(i420Buffer.strideV) + flippedCol]
                    }else {
                        // Interleave U and V
                        uvDestination[uvIndex] = uSource[origRow * Int(i420Buffer.strideU) + origCol]
                        uvDestination[uvIndex + 1] = vSource[origRow * Int(i420Buffer.strideV) + origCol]
                    }
                }
            }
        }
        
        // Unlock the pixel buffer base address
        CVPixelBufferUnlockBaseAddress(createdPixelBuffer, [])
        
        return createdPixelBuffer
    }
    
    
    private func createSampleBufferFromPixelBuffer(pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil,
                                                     imageBuffer: pixelBuffer,
                                                     formatDescriptionOut: &formatDescription)
        
        guard let formatDescription = formatDescription else {
            print("[DYTE_PIP] not able to create format description")
            return nil
        }
        
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo()
        timingInfo.duration = CMTime.invalid
        timingInfo.decodeTimeStamp = CMTime.invalid
        timingInfo.presentationTimeStamp = CMTime(value: CMTimeValue(CACurrentMediaTime() * 1000), timescale: 1000)
        
        let status = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                        imageBuffer: pixelBuffer,
                                                        dataReady: true,
                                                        makeDataReadyCallback: nil,
                                                        refcon: nil,
                                                        formatDescription: formatDescription,
                                                        sampleTiming: &timingInfo,
                                                        sampleBufferOut: &sampleBuffer)
        if status != noErr {
            print("[DYTE_PIP] Failed to create CMSampleBuffer: \(status)")
            return nil
        }
        
        return sampleBuffer
    }
    
    deinit {
        print("[Rtk_PIP] Deinit frame fetcher")
    }
    
}
