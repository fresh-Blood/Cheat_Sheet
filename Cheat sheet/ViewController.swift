import UIKit
import Vision
import AVKit

protocol UserView {
    
}

final class ViewController: UIViewController, UserView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    var captureSession = AVCaptureSession()
    var observationText = "" {
        didSet {
            if !observationText.isEmpty {
                counter += 1
                DispatchQueue.main.async { [weak self] in
                    if !(self?.loadingIndicator.isAnimating)! {
                        self?.loadingIndicator.startAnimating()
                    }
                }
            }
        }
    }
    var visionRequests = [VNRequest]()
    var counter = 0 {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard
                    let counter = self?.counter else { return }
                self?.scoreLabel.text = "\(counter*5) %"
            }
        }
    }
    
    private let scoreLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 1
        lbl.font = .systemFont(ofSize: 80, weight: .bold)
        lbl.backgroundColor = .clear
        lbl.textColor = .white.withAlphaComponent(0.5)
        lbl.textAlignment = .center
        return lbl
    }()
    
    private let visionTextRecognitionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest()
        request.preferBackgroundProcessing = true
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.usesCPUOnly = false
        return request
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView(style: .large)
        loading.hidesWhenStopped = true
        loading.tintColor = .white
        return loading
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemRed
        startCaptureSession(createObjectDetectionVisionRequest())
        view.addSubview(loadingIndicator)
        view.addSubview(scoreLabel)
    }
    
    private func endDetecting() {
        loadingIndicator.stopAnimating()
        captureSession.stopRunning()
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
    
    private func createObjectDetectionVisionRequest() -> VNRequest? {
        
        let visionTextRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard
                let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            self?.observationText = observations.compactMap({
                $0.topCandidates(1).first?.string
            }).joined(separator: " ")

            guard
                let unwrappedRequests = self?.visionRequests else { return }
            
            if unwrappedRequests.isEmpty {
                self?.visionRequests.append(request)
            } else {
                self?.visionRequests.removeAll()
                self?.visionRequests.append(request)
            }
            
            if self?.counter == 20 {
                self?.presentTextVC()
            }
            
        }
        return visionTextRecognitionRequest
    }
    
    func presentTextVC() {
        DispatchQueue.main.async { [weak self] in
            let textVC = TextViewController()
            self?.endDetecting()
            textVC.textToTranslate.text = self?.observationText
            self?.navigationController?.pushViewController(textVC, animated: true)
            self?.counter = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.counter = 0
            self?.captureSession.startRunning()
            self?.loadingIndicator.stopAnimating()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadingIndicator.center = view.center
        let inset: CGFloat = 50
        scoreLabel.frame = CGRect(x: view.safeAreaInsets.left + inset,
                                  y: view.bounds.height - inset*2 - view.safeAreaInsets.bottom,
                                  width: view.bounds.width - inset*2,
                                  height: inset*2)
    }
}

