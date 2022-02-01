import UIKit
import NaturalLanguage

protocol UserText {
    
}

final class TextViewController: UIViewController, UserText, UITextViewDelegate {
    
    let textToTranslate: UITextView = {
        let text = UITextView()
        text.backgroundColor = .systemGray6
        text.textColor = .label
        text.font = .systemFont(ofSize: 20, weight: .bold)
        text.translatesAutoresizingMaskIntoConstraints = false
        text.layer.cornerRadius = 8 
        return text
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
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .random()
        view.addSubview(textToTranslate)
        self.title = "I recognized this (ಠ‿ಠ):"
        textToTranslate.delegate = self
        setTextViewConstraints()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recognizeCheckAndCorrectLanguage()
    }
    
    private func setTextViewConstraints() {
        NSLayoutConstraint.activate([
            textToTranslate.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textToTranslate.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            textToTranslate.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            textToTranslate.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
        ])
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


