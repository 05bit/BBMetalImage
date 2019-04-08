//
//  BBMetalCamera.swift
//  BBMetalImage
//
//  Created by Kaibo Lu on 4/8/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import AVFoundation

public class BBMetalCamera: NSObject {
    public private(set) var consumers: [BBMetalImageConsumer]
    
    private var session: AVCaptureSession!
    private var camera: AVCaptureDevice!
    
    private var textureCache: CVMetalTextureCache!
    
    public init?(sessionPreset: AVCaptureSession.Preset = .high) {
        consumers = []
        
        super.init()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return nil }
        
        session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = sessionPreset
        
        if !session.canAddInput(videoDeviceInput) {
            session.commitConfiguration()
            return nil
        }
        
        session.addInput(videoDeviceInput)
        camera = videoDevice
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
        videoDataOutput.setSampleBufferDelegate(self, queue: nil)
        if !session.canAddOutput(videoDataOutput) {
            session.commitConfiguration()
            return nil
        }
        session.addOutput(videoDataOutput)
        
        session.commitConfiguration()
        
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, BBMetalDevice.sharedDevice, nil, &textureCache) != kCVReturnSuccess {
            return nil
        }
    }
    
    public func start() { session.startRunning() }
    
    public func stop() { session.stopRunning() }
}

extension BBMetalCamera: BBMetalImageSource {
    @discardableResult
    public func add<T: BBMetalImageConsumer>(consumer: T) -> T {
        consumers.append(consumer)
        consumer.add(source: self)
        return consumer
    }
    
    public func add(consumer: BBMetalImageConsumer, at index: Int) {
        consumers.insert(consumer, at: index)
        consumer.add(source: self)
    }
    
    public func remove(consumer: BBMetalImageConsumer) {
        if let index = consumers.firstIndex(where: { $0 === consumer }) {
            consumers.remove(at: index)
            consumer.remove(source: self)
        }
    }
}

extension BBMetalCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !consumers.isEmpty,
            let texture = texture(with: sampleBuffer) else { return }
        for consumer in consumers { consumer.newTextureAvailable(texture, from: self) }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print(#function)
    }
    
    private func texture(with sampleBuffer: CMSampleBuffer) -> MTLTexture? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        var cvMetalTextureOut: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               textureCache,
                                                               imageBuffer,
                                                               nil,
                                                               .rgba8Unorm,
                                                               width,
                                                               height,
                                                               0,
                                                               &cvMetalTextureOut)
        if result == kCVReturnSuccess,
            let cvMetalTexture = cvMetalTextureOut,
            let texture = CVMetalTextureGetTexture(cvMetalTexture) {
            return texture
        }
        CVMetalTextureCacheFlush(textureCache, 0)
        return nil
    }
}
