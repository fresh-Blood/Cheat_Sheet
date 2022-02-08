import UIKit
import Vision
import AVKit

protocol UserView {
    
}

final class ViewController: UIViewController, UserView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Vision -> AVF coordinate transform.
    var visionToAVFTransform = CGAffineTransform.identity
    var visionRequests = [VNRequest]()
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
    
    var boxes = [CGRect]() // Shows all recognized text lines
    {
        didSet {
            self.show(boxGroups: [(color: UIColor.systemGreen.cgColor, boxes: boxes)])
        }
    }

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
    
    var visionTextRecognitionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest()
        request.preferBackgroundProcessing = true
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.usesCPUOnly = false
        return request
    }()
    
    let loadingIndicator: UIActivityIndicatorView = {
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
        setView()
        setButtonGesturePolitics()
        configureNavBar()
        view.backgroundColor = .random()
        startCaptureSession()
        view.addSubview(loadingIndicator)
        view.addSubview(scoreLabel)
        view.addSubview(recognizeButton)
    }
    
    private func configureNavBar() {
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
    
    private func setView() {
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


