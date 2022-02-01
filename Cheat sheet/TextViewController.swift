import UIKit
import NaturalLanguage

protocol UserText {
    
}

final class TextViewController: UIViewController, UserText {
    
    var languagesToChooseForPickerView: [String] = [NLLanguage.russian.rawValue]

    private let loadingIndicator: UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView(style: .large)
        loading.color = .white
        loading.hidesWhenStopped = true
        return loading
    }()
    
    private let placeholderLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.adjustsFontSizeToFitWidth = true
        lbl.backgroundColor = .clear
        lbl.textColor = .label
        lbl.font = .systemFont(ofSize: 30, weight: .bold)
        lbl.text = "Translate to:"
        return lbl
    }()
    
    let textToTranslate: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.adjustsFontSizeToFitWidth = true
        lbl.backgroundColor = .systemGray6
        lbl.textColor = .label
        lbl.font = .systemFont(ofSize: 50, weight: .bold)
        return lbl
    }()
    
    private let picker: UIPickerView = {
        let picker = UIPickerView()
        picker.backgroundColor = .systemGray6
        return picker
    }()
    
    let goButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Go!", for: .normal)
        btn.backgroundColor = .random()
        btn.setTitleColor(UIColor.label, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private func recognizeCheckAndCorrectLanguage() {
        let languageRecognizer = NLLanguageRecognizer()
        guard
            let labelText = textToTranslate.text else { return }
        if !labelText.isEmpty {
            languageRecognizer.processString(labelText)
            guard
                let dominantLanguage = languageRecognizer.dominantLanguage?.rawValue else { return }
            
            languageRecognizer.processString(labelText)
            
            let textChecker = UITextChecker()
            let nsString = NSString(string: labelText)
            let stringRange = NSRange(location: 0, length: nsString.length)
            var offset = 0
            
            repeat {
                let wordRange = textChecker.rangeOfMisspelledWord(in: labelText,
                                                                  range: stringRange,
                                                                  startingAt: offset,
                                                                  wrap: false,
                                                                  language: dominantLanguage)
                guard
                    wordRange.location != NSNotFound else {
                        break
                    }
                let wordWithError = nsString.substring(with: wordRange)
                guard
                    let quessRightWord = textChecker.guesses(forWordRange: wordRange, in: labelText, language: dominantLanguage)?.first else { return }
                offset = wordRange.upperBound
                textToTranslate.text = labelText.replacingOccurrences(of: wordWithError, with: quessRightWord)
            } while true
            DispatchQueue.main.async { [weak self] in
                self?.loadingIndicator.stopAnimating()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .random()
        view.addSubview(textToTranslate)
        self.title = "I recognized this (ಠ‿ಠ):"
        view.addSubview(loadingIndicator)
        view.addSubview(placeholderLabel)
        loadingIndicator.startAnimating()
        picker.delegate = self
        picker.dataSource = self
        view.addSubview(picker)
        view.addSubview(goButton)
        setGoButtonGesturePolitics()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recognizeCheckAndCorrectLanguage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let inset: CGFloat = 20
        textToTranslate.frame = CGRect(x: view.safeAreaInsets.left + inset,
                                       y: view.safeAreaInsets.top,
                                       width: view.frame.width - inset*2,
                                       height: view.frame.height/2)
        loadingIndicator.center = view.center
        placeholderLabel.frame = CGRect(x: view.safeAreaInsets.left + inset,
                                        y: view.safeAreaInsets.top + textToTranslate.frame.height + inset,
                                        width: view.frame.width/2 - inset,
                                        height: 50)
        picker.frame = CGRect(x: view.safeAreaInsets.left + inset + placeholderLabel.frame.width,
                              y: view.safeAreaInsets.top + textToTranslate.frame.height + inset,
                              width: view.frame.width/2 - inset,
                              height: 50)
        goButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        goButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        goButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        goButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        goButton.layer.cornerRadius = goButton.frame.height/2
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red:   .random(in: 0...1),
            green: .random(in: 0...1),
            blue:  .random(in: 0...1),
            alpha: 1.0
        )
    }
}

extension TextViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languagesToChooseForPickerView.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languagesToChooseForPickerView[row]
    }
}
