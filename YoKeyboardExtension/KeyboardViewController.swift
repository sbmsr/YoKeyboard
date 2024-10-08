import UIKit

class KeyboardViewController: UIInputViewController {
    private var keys = ["q", "w"]
    
    private var keyboard: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    private func setupKeyboard() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10  // Adjust spacing between keys
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for k in keys {
            let key = UIButton(type: .system)
            key.setTitle(k, for: .normal)
            key.titleLabel?.font = UIFont.systemFont(ofSize: 24) // Adjust the font size as needed
            
            // Add border to see the bounding box
            key.layer.borderWidth = 2
            key.layer.borderColor = UIColor.red.cgColor
            key.layer.cornerRadius = 5
            key.backgroundColor = UIColor.red  // this makes the button fully tappable
            
            key.addTarget(self, action: #selector(keyTapped(_:event:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(key)
        }
        
        view.addSubview(stackView)

        // Constraints to make the stack view fill the width of the keyboard
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10), // Left padding
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10), // Right padding
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 60) // Adjust the height of the keys
        ])
        
        keyboard = stackView
    }

    @objc private func keyTapped(_ sender: UIButton, event: UIEvent) {
        guard let keyTitle = sender.title(for: .normal) else { return }
        
        // Get the touch location within the button
        if let touch = event.allTouches?.first {
            let tapLocation = touch.location(in: sender)
            let buttonCenter = sender.bounds.midX  // Get the middle X of the button
            
            NSLog("Tapped key: \(keyTitle)")
            NSLog("Tap location (within button): \(tapLocation)")
            NSLog("Button center (x): \(buttonCenter)")
            
            let distanceFromCenter = tapLocation.x - buttonCenter
            
            // Move the button based on the tap position
            if abs(distanceFromCenter) > 20 {  // If tap is more than 20 pixels away from center
                let direction: CGFloat = distanceFromCenter > 0 ? 1 : -1  // Positive for right, negative for left
                let moveDistance: CGFloat = 20 * direction  // Move by 20 points
                
                // Make sure the button doesn't move off the screen or too far
                let newCenterX = max(sender.frame.origin.x + moveDistance, 0)
                let maxX = view.bounds.width - sender.frame.width
                sender.frame.origin.x = min(newCenterX, maxX)
            }
        }
        
        // Insert the key's title into the text field
        textDocumentProxy.insertText(keyTitle)
    }
}
