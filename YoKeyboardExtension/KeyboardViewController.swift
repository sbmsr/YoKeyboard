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
        stackView.distribution = .fillProportionally
        stackView.spacing = 10  // Adjust spacing between keys
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for k in keys {
            let key = UIButton(type: .system)
            key.setTitle(k, for: .normal)
            key.titleLabel?.font = UIFont.systemFont(ofSize: 24) // Adjust the font size as needed
            
            // Add border to see the bounding box
            key.layer.borderWidth = 2
            key.layer.borderColor = UIColor.white.cgColor
            key.layer.cornerRadius = 5
            key.setTitleColor(UIColor.black, for: .normal)
            key.backgroundColor = UIColor.white  // this makes the button fully tappable
            
            key.addTarget(self, action: #selector(keyTapped(_:event:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(key)
        }
        
        view.addSubview(stackView)

        // Constraints to make the stack view fill the width of the keyboard
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10), // Left padding
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10), // Right padding
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 40) // Adjust the height of the keys
        ])
        
        keyboard = stackView
    }
    
    private let PIXEL_BOUNDARY: CGFloat = 20.0
    private let MIN_KEY_WIDTH: CGFloat = 20.0


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

            // Find the index of the tapped button in the stack view
            if let stackView = keyboard, let index = stackView.arrangedSubviews.firstIndex(of: sender) {
                
                // Adjust the width based on the tap position
                if abs(distanceFromCenter) > (sender.bounds.width/2 - PIXEL_BOUNDARY) {  // If tap is <PIXEL_BOUNDARY> pixels (or less) away from edge
                    let direction: CGFloat = distanceFromCenter > 0 ? 1 : -1  // Positive for right, negative for left
                    let changeAmount: CGFloat = 30 * direction  // Adjust the button width by 30 points

                    // Remove any existing width constraints on the tapped button
                    if let widthConstraint = sender.constraints.first(where: { $0.firstAttribute == .width }) {
                        sender.removeConstraint(widthConstraint)
                    }

                    // Adjust the width of the tapped button
                    sender.widthAnchor.constraint(equalToConstant: sender.frame.width + abs(changeAmount)).isActive = true
                    
                    // Adjust the width of the neighboring button if it exists
                    if direction > 0, index + 1 < stackView.arrangedSubviews.count {
                        let nextButton = stackView.arrangedSubviews[index + 1]
                        
                        // Calculate the new width of the next button
                        let newWidth = nextButton.frame.width - abs(changeAmount)
                        
                        // Only apply the width constraint if the new width is above the minimum
                        if newWidth >= MIN_KEY_WIDTH {
                            if let nextWidthConstraint = nextButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                nextButton.removeConstraint(nextWidthConstraint)
                            }
                            nextButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                        }
                        
                    } else if direction < 0, index - 1 >= 0 {
                        let previousButton = stackView.arrangedSubviews[index - 1]
                        
                        // Calculate the new width of the previous button
                        let newWidth = previousButton.frame.width - abs(changeAmount)
                        
                        // Only apply the width constraint if the new width is above the minimum
                        if newWidth >= MIN_KEY_WIDTH {
                            if let prevWidthConstraint = previousButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                previousButton.removeConstraint(prevWidthConstraint)
                            }
                            previousButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                        }
                    }
                    
                    // Ensure the layout updates
                    UIView.animate(withDuration: 0.1) {
                        self.view.layoutIfNeeded()  // Animate layout changes
                    }
                }
            }
        }
        
        // Insert the key's title into the text field
        textDocumentProxy.insertText(keyTitle)
    }
}
