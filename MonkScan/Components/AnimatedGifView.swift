import SwiftUI
import UIKit

struct AnimatedGifView: UIViewRepresentable {
    let name: String
    var size: CGSize = CGSize(width: 150, height: 150)
    
    func makeUIView(context: Context) -> UIView {
        // Container view to control size
        let containerView = UIView()
        let imageView = UIImageView()
        
        containerView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        guard let path = Bundle.main.path(forResource: name, ofType: "gif"),
              let data = NSData(contentsOfFile: path),
              let source = CGImageSourceCreateWithData(data, nil) else {
            if let image = UIImage(named: name) {
                imageView.image = image
            }
            return containerView
        }
        
        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)
                
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval {
                    totalDuration += delayTime
                }
            }
        }
        
        imageView.animationImages = images
        imageView.animationDuration = totalDuration
        imageView.animationRepeatCount = 0
        imageView.startAnimating()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        // Prevent expansion
        containerView.setContentHuggingPriority(.required, for: .horizontal)
        containerView.setContentHuggingPriority(.required, for: .vertical)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        return size
    }
}

