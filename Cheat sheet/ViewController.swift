import UIKit
import Vision
import AVKit

protocol UserView {
    
}

final class ViewController: UIViewController, UserView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Vision -> AVF coordinate transform.
    var visionToAVFTransform = CGAffineTransform.identity
    
    var previewLayer: AVCaptureVideoPreviewLayer = {
       let layer = AVCaptureVideoPreviewLayer()
        return layer
    }()
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
    
    var boxes = [CGRect]() // Shows all recognized text lines {
    {
        didSet {
            self.show(boxGroups: [(color: UIColor.systemGreen.cgColor, boxes: boxes)])
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
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var visionTextRecognitionRequest: VNRecognizeTextRequest = {
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
        loading.color = .white
        return loading
    }()
    
    let recognizeButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Recognize!", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .heavy)
        btn.layer.cornerRadius = 8
        btn.backgroundColor = .random()
        btn.setTitleColor(.black, for: .normal)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setButtonGesturePolitics()
        configurateNavBar()
        view.backgroundColor = .random()
        startCaptureSession()
        view.addSubview(loadingIndicator)
        view.addSubview(scoreLabel)
        view.addSubview(recognizeButton)
        view.layer.addSublayer(previewLayer) // test
    }
    private func configurateNavBar() {
        navigationItem.title = "Focus on text,don't move ಠ_ಠ"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 25,
                                     weight: .bold),
            .foregroundColor: UIColor.white 
        ]
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
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
    
    private func startCaptureSession() {
        
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
        visionTextRecognitionRequest.regionOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: previewLayer.bounds)
        visionRequests.append(visionTextRecognitionRequest)
    }
    
    func presentTextVC() {
        DispatchQueue.main.async { [weak self] in
            let textVC = TextViewController()
            self?.endDetecting()
            textVC.textToTranslate.text = self?.observationText
            self?.navigationController?.pushViewController(textVC, animated: true)
            self?.counter = 0
            self?.visionRequests.removeAll()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.counter = 0
            self?.captureSession.startRunning()
            self?.loadingIndicator.stopAnimating()
            
            guard
                let sublayers = self?.previewLayer.sublayers else { return }
            
            for sublayer in sublayers where sublayer != sublayers[0] {
                sublayer.removeFromSuperlayer()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadingIndicator.center = view.center
        NSLayoutConstraint.activate([
            recognizeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recognizeButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            recognizeButton.widthAnchor.constraint(equalToConstant: 150),
            recognizeButton.heightAnchor.constraint(equalToConstant: 70),
            
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            scoreLabel.widthAnchor.constraint(equalToConstant: 150),
            scoreLabel.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
}

extension ViewController {
    // MARK: - Bounding box drawing
    
    // Draw a box on screen. Must be called from main queue.
    
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 1
        layer.borderColor = color
        layer.borderWidth = 1
        layer.frame = rect
        layer.fillColor = color 
        layer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)))

        previewLayer.insertSublayer(layer, at: 1)
        guard
            let sublayers = previewLayer.sublayers else { return }
        if sublayers.count > 2 {
            previewLayer.sublayers?.removeLast()
        }
    }
    
    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
    
    // Draws groups of colored boxes.
    func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.previewLayer
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                    self.draw(rect: rect, color: color)
                }
            }
        }
    }
}
