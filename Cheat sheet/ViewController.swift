import UIKit
import Vision
import AVKit

protocol UserView {
    
}

final class ViewController: UIViewController, UserView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    var objectDetectionLayer = CALayer()
    var visionRequests = [VNRequest]()
    
    private let label: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.backgroundColor = .systemBlue
        lbl.text = "Starting..."
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemRed
        startCaptureSession(createObjectDetectionVisionRequest())
        setupObjectDetectionLayer(previewLayer, previewLayer.frame.size)
        view.addSubview(label)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        
        previewLayer.videoGravity = .resizeAspectFill
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
    
    private func startCaptureSession(_ visionRequest: VNRequest?) {
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard
            let captureDevice = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: captureDevice)
        else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.bounds
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "queue"))
        captureSession.addOutput(dataOutput)
        captureSession.commitConfiguration()
        if visionRequest != nil {
            self.visionRequests = [visionRequest!]
        } else {
            self.visionRequests = []
        }
    }
    
    
    func createObjectDetectionVisionRequest() -> VNRequest? {
        
        let visionTextRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard
                let observations = request.results as? [VNRecognizedTextObservation] else { return }
                        
            let text = observations.compactMap({
                $0.topCandidates(1).first?.string
            }).joined(separator: ", ")
            
            guard
                let unwrappedRequests = self?.visionRequests else { return }
            
            if unwrappedRequests.isEmpty {
                self?.visionRequests.append(request)
            } else {
                self?.visionRequests.removeAll()
                self?.visionRequests.append(request)
            }
            
            DispatchQueue.main.async {
//                self?.processVisionRequestResults(observations)
                self?.drawBoundingBoxes(observations: observations)
                self?.label.text = text
            }
        }
        print(visionTextRecognitionRequest.recognitionLanguages)
        visionTextRecognitionRequest.preferBackgroundProcessing = true
        visionTextRecognitionRequest.usesLanguageCorrection = true
        return visionTextRecognitionRequest
    }
    
    private func drawBoundingBoxes(observations: [VNRecognizedTextObservation]) {
        
        let boundingRects: [CGRect] = observations.compactMap { observation in

            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else { return .zero }
            
            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            let boundingBox = boxObservation?.boundingBox ?? .zero
            
            // Convert the rectangle from normalized coordinates to image coordinates.
            return VNImageRectForNormalizedRect(boundingBox,
                                                Int(objectDetectionLayer.bounds.width),
                                                Int(objectDetectionLayer.bounds.height))
        }
    }
    
    private func processVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        self.objectDetectionLayer.sublayers = nil
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            let topLabelObservation = objectObservation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(
                objectObservation.boundingBox,
                Int(self.objectDetectionLayer.bounds.width), Int(self.objectDetectionLayer.bounds.height))
            
            let bbLayer = self.createBoundingBoxLayer(objectBounds, identifier: topLabelObservation.identifier, confidence: topLabelObservation.confidence)
            self.objectDetectionLayer.addSublayer(bbLayer)
        }
        CATransaction.commit()
    }
    
    private func setupObjectDetectionLayer(_ viewLayer: CALayer, _ videoFrameSize: CGSize) {
        self.objectDetectionLayer = CALayer()
        self.objectDetectionLayer.name = "ObjectDetectionLayer"
        self.objectDetectionLayer.bounds = CGRect(x: 0.0,
                                                  y: 0.0,
                                                  width: videoFrameSize.width,
                                                  height: videoFrameSize.height)
        self.objectDetectionLayer.position = CGPoint(x: viewLayer.bounds.midX, y: viewLayer.bounds.midY)
        
        viewLayer.addSublayer(self.objectDetectionLayer)
        
        let bounds = viewLayer.bounds
        
        let scale = fmax(bounds.size.width  / videoFrameSize.width, bounds.size.height / videoFrameSize.height)
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        self.objectDetectionLayer.setAffineTransform(CGAffineTransform(scaleX: scale, y: -scale))
        self.objectDetectionLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }
    
    private func createBoundingBoxLayer(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CALayer {
        let path = UIBezierPath(rect: bounds)
        
        let boxLayer = CAShapeLayer()
        boxLayer.path = path.cgPath
        boxLayer.strokeColor = UIColor.red.cgColor
        boxLayer.lineWidth = 2
        boxLayer.fillColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 0.0])
        
        boxLayer.bounds = bounds
        boxLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        boxLayer.name = "Detected Object Box"
        boxLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.5, 0.5, 0.2, 0.3])
        boxLayer.cornerRadius = 6
        
        let textLayer = CATextLayer()
        textLayer.name = "Detected Object Label"
        
        textLayer.string = String(format: "\(identifier)\n(%.2f)", confidence)
        textLayer.fontSize = CGFloat(16.0)
        
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.width - 10, height: bounds.size.height - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.alignmentMode = .center
        textLayer.foregroundColor =  UIColor.red.cgColor
        textLayer.contentsScale = 2.0
        
        textLayer.setAffineTransform(CGAffineTransform(scaleX: 1.0, y: -1.0))
        
        boxLayer.addSublayer(textLayer)
        return boxLayer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        label.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
}

