import UIKit

protocol UserText {

}

final class TextViewController: UIViewController, UserText {
        
    let textToTranslate: UILabel = {
       let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.adjustsFontSizeToFitWidth = true
        lbl.backgroundColor = .systemGray6
        return lbl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPink
        view.addSubview(textToTranslate)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let inset: CGFloat = 20
        textToTranslate.frame = CGRect(x: view.safeAreaInsets.left + inset,
                                       y: view.safeAreaInsets.top,
                                       width: view.frame.width - inset*2,
                                       height: view.frame.height/2)
    }
}
