import UIKit

class KeyboardViewController: UIInputViewController {
    private var keys = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
        ["spacebar"]
    ]
    
    private var keyboard: UIStackView!
    private var morphButton: UIButton!
    private var isMorphModeEnabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
        setupMorphButton()
    }

    private func setupKeyboard() {
        let keyboardStackView = UIStackView()
        keyboardStackView.axis = .vertical
        keyboardStackView.alignment = .fill
        keyboardStackView.distribution = .fillEqually
        keyboardStackView.spacing = 4  // Adjust spacing between keys
        keyboardStackView.translatesAutoresizingMaskIntoConstraints = false

        for row in keys {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.alignment = .fill
            rowStackView.distribution = .fillProportionally
            rowStackView.spacing = 4  // Adjust spacing between keys
            rowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            for k in row {
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
                
                rowStackView.addArrangedSubview(key)
            }
            keyboardStackView.addArrangedSubview(rowStackView)
        }
        
        view.addSubview(keyboardStackView)

        // Constraints to make the keyboardStackView fill the view horizontally and position it vertically
        NSLayoutConstraint.activate([
            keyboardStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10), // Left padding
            keyboardStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10), // Right padding
            keyboardStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20.0),
            keyboardStackView.heightAnchor.constraint(equalToConstant: 180) // Adjust the total height of the keyboard
        ])
        
        keyboard = keyboardStackView
    }
    
    private func setupMorphButton() {
        morphButton = UIButton(type: .system)
        morphButton.setTitle("Enable Morph Mode", for: .normal)
        morphButton.addTarget(self, action: #selector(toggleMorphMode), for: .touchUpInside)
        morphButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(morphButton)
        
        NSLayoutConstraint.activate([
            morphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            morphButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func toggleMorphMode() {
        isMorphModeEnabled.toggle()

        let title = isMorphModeEnabled ? "Disable Morph Mode" : "Enable Morph Mode";
        morphButton.setTitle(title, for: .normal);
    }
    
    private let PIXEL_BOUNDARY: CGFloat = 8.0
    private let MIN_WIDTH: CGFloat = 20.0

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
            
            let rowStackView = keyboard.arrangedSubviews.first { row in
                guard let rowStackView = row as? UIStackView else { return false }
                return rowStackView.arrangedSubviews.contains { key in
                    guard let button = key as? UIButton else { return false }
                    return button.currentTitle == sender.currentTitle
                }
            }

            // Find the index of the tapped button in the stack view
            if isMorphModeEnabled, let stackView = rowStackView as? UIStackView, let index = stackView.arrangedSubviews.firstIndex(of: sender) {

                // Adjust the width based on the tap position
                if abs(distanceFromCenter) > (sender.bounds.width/2 - PIXEL_BOUNDARY) {  // If tap is <PIXEL_BOUNDARY> pixels (or less) away from edge
                    let direction: CGFloat = distanceFromCenter > 0 ? 1 : -1  // Positive for right, negative for left
                    let changeAmount: CGFloat = PIXEL_BOUNDARY * direction

                    var morphedNeighbor = false;
                    
                    // Adjust the width of the neighboring button if it exists
                    if direction > 0, index + 1 < stackView.arrangedSubviews.count {
                        let nextButton = stackView.arrangedSubviews[index + 1]
                        
                        // Calculate the new width of the next button
                        let newWidth = nextButton.frame.width - abs(changeAmount)
                        
                        // Only apply the width constraint if the new width is above the minimum
                        if newWidth >= MIN_WIDTH {
                             if let nextWidthConstraint = nextButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                 nextButton.removeConstraint(nextWidthConstraint)
                             }
                            nextButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                            morphedNeighbor = true;
                        }
                        
                    } else if direction < 0, index - 1 >= 0 {
                        let previousButton = stackView.arrangedSubviews[index - 1]
                        
                        // Calculate the new width of the previous button
                        let newWidth = previousButton.frame.width - abs(changeAmount)
                        
                        // Only apply the width constraint if the new width is above the minimum
                        if newWidth >= MIN_WIDTH {
                             if let prevWidthConstraint = previousButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                 previousButton.removeConstraint(prevWidthConstraint)
                             }
                            previousButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                            morphedNeighbor = true;
                        }
                    }

                    if (morphedNeighbor) {
                         // Remove any existing width constraints on the tapped button
                         if let widthConstraint = sender.constraints.first(where: { $0.firstAttribute == .width }) {
                             sender.removeConstraint(widthConstraint)
                         }
                        
                        // Adjust the width of the tapped button
                        sender.widthAnchor.constraint(equalToConstant: sender.frame.width + abs(changeAmount)).isActive = true
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