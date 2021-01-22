//
//  ViewController.swift
//  CameraFrameExtractor
//
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    lazy var cameraPreview: UIView = {
        let view = UIView()
        return view
    }()
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    let context = CIContext()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.addSubview(cameraPreview)
        cameraPreview.frame = self.view.frame
        self.setUpAVCapture()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }
    // To add the layer of your preview
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.cameraPreview.layer.bounds
    }
    // To set the camera and its position to capture
    func setUpAVCapture() {
        session.sessionPreset = AVCaptureSession.Preset.high
        guard let device = AVCaptureDevice
            .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                     for: .video,
                     position: AVCaptureDevice.Position.front) else {
                        return
        }
        captureDevice = device
        beginSession()
    }
    // Function to setup the beginning of the capture session
    func beginSession(){
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }
            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames=true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
            
            if session.canAddOutput(self.videoDataOutput){
                session.addOutput(self.videoDataOutput)
            }
            videoDataOutput.connection(with: .video)?.isEnabled = true
            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            let rootLayer :CALayer = self.cameraPreview.layer
            rootLayer.masksToBounds=true
            rootLayer.addSublayer(self.previewLayer)
            session.startRunning()
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
    
    // Function to capture the frames again and again
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // do stuff here
        print("Got a frame \(Date()) ")
        DispatchQueue.main.async { [unowned self] in
            guard let uiImage = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
            print("\(uiImage.accessibilityFrame) -> frame")
        }
    }
    // Function to process the buffer and return UIImage to be used
    func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    // To stop the session 
    func stopCamera(){
        session.stopRunning()
    }
}


