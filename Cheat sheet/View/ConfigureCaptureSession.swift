import Foundation
import AVKit
import Vision


extension ViewController {
    
    func startCaptureSession() {
        
        captureSession.sessionPreset = .photo
        guard
            let captureDevice = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: captureDevice)
        else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: view.safeAreaInsets.left + 20,
                                    y: view.safeAreaInsets.top + 20,
                                    width: view.bounds.width - 40,
                                    height: view.bounds.height/2 - 150)

        previewLayer.cornerRadius = 8
        previewLayer.borderColor = UIColor.black.cgColor
        previewLayer.borderWidth = 2.0
        previewLayer.masksToBounds = true
        view.layer.addSublayer(previewLayer)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "queue"))
        captureSession.addOutput(dataOutput)
        captureSession.commitConfiguration()
    }
    
    func createObjectDetectionVisionRequest() {
        
        visionTextRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard
                let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            for observation in observations {
                DispatchQueue.main.async {
                    let box = observation.boundingBox
                    self?.boxes.append(box)
                }
            }
            
            self?.observationText = observations.compactMap({
                $0.topCandidates(1).first?.string
            }).joined(separator: " ")
            
            
            if self?.counter == 20 {
                self?.presentTextVC()
            }
        }
        // try to see the zone of interest adding a sublayer with this frame. The goal is to set it correctly and then make other part half black / the zone of interest clear
        visionTextRecognitionRequest.regionOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: previewLayer.bounds)
        visionRequests.append(visionTextRecognitionRequest)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        
        previewLayer.videoGravity = .resizeAspect // try to play with this if not - add sublayer ?
        let frameOrientation: CGImagePropertyOrientation = .right
        let imageRequesthandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                        orientation: frameOrientation,
                                                        options: [:])
        do {
            try imageRequesthandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    func endDetecting() {
        loadingIndicator.stopAnimating()
        captureSession.stopRunning()
    }
}
