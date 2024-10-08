import UIKit

class KeyboardViewController: UIInputViewController {

    private var yoButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupYoButton()
    }

    private func setupYoButton() {
        yoButton = UIButton(type: .system)
        yoButton.setTitle("Yo", for: .normal)
        yoButton.sizeToFit()
        yoButton.translatesAutoresizingMaskIntoConstraints = false
        yoButton.addTarget(self, action: #selector(yoButtonTapped), for: .touchUpInside)

        view.addSubview(yoButton)

        NSLayoutConstraint.activate([
            yoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            yoButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func yoButtonTapped() {
        textDocumentProxy.insertText("Yo")
    }
}
