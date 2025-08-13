import UIKit

class ImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var pinchGestureRecognizer: UIPinchGestureRecognizer!
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var baseSizeView: UIView!
    
    var src:String = ""
    
    var maxCenterX: CGFloat = 0.0
    var minCenterX: CGFloat = 0.0
    var maxCenterY: CGFloat = 0.0
    var minCenterY: CGFloat = 0.0
    
    var imageWidth: CGFloat = 0.0
    var imageHeight: CGFloat = 0.0
    
    var imageCenterX: CGFloat = 0.0
    var imageCenterY: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {

    }
    
    override func viewDidLayoutSubviews() {
        let url: URL! = URL(string: self.src)
            
        do {
            let imageData = try Data(contentsOf: url)
            imageView.image = UIImage(data: imageData)
            
            imageWidth = imageView.contentClippingRect.width
            imageHeight = imageView.contentClippingRect.height
            
            let vertical = (imageView.frame.height - imageHeight) / 2
            let horizontal = (imageView.frame.width - imageWidth) / 2
            
            for constraint in self.view.constraints {
                if constraint.identifier == "imageViewConstraint" || constraint.identifier == "imageViewBottomConstraint" {
                    constraint.constant = CGFloat(vertical)
                } else if constraint.identifier == "imageViewLeftConstraint" || constraint.identifier == "imageViewRightConstraint" {
                    constraint.constant = CGFloat(horizontal)
                }
            }
            
            imageCenterX = imageView.center.x
            imageCenterY = imageView.center.y
        } catch {
            return
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    @IBAction func closeView(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: false)
    }
    
    @IBAction func pinchAction(_ sender: Any) {
        
        imageView.transform = imageView.transform.scaledBy(x: pinchGestureRecognizer.scale, y: pinchGestureRecognizer.scale)
        
        pinchGestureRecognizer.scale = 1.0
        
        if pinchGestureRecognizer.state == .ended {
            
            if imageView.transform.a < 1.0 {
                UIImageView.animate(withDuration: 0.3, animations: {
                    self.imageView.transform = CGAffineTransform.identity
                })
            } else if imageView.transform.a > 3.0 {
                UIImageView.animate(withDuration: 0.3, animations: {
                    self.imageView.transform = CGAffineTransform.identity.scaledBy(x: 3.0, y: 3.0)
                })
            }
            
            if imageWidth * imageView.transform.a > baseSizeView.frame.width {
                maxCenterX = imageWidth * imageView.transform.a / 2
                minCenterX = baseSizeView.frame.size.width - imageWidth * imageView.transform.a / 2
            } else {
                maxCenterX = imageCenterX
                minCenterX = imageCenterX
            }
            
            if imageHeight * imageView.transform.a > baseSizeView.frame.height {
                maxCenterY = imageHeight * imageView.transform.a  / 2
                minCenterY = baseSizeView.frame.size.height - imageHeight * imageView.transform.a / 2
            } else {
                maxCenterY = imageCenterY
                minCenterY = imageCenterY
            }

            if imageView.transform.a == 1 {
                imageView.center = CGPoint(x: imageCenterX , y: imageCenterY)
                return
            }
            
            if maxCenterX != minCenterX {
                if maxCenterX < imageView.center.x {
                    imageView.center.x = maxCenterX
                }
                if minCenterX > imageView.center.x {
                    imageView.center.x = minCenterX
                }
            } else {
                imageView.center.x = imageCenterX
            }
            
            if maxCenterY != minCenterY {
                if maxCenterY < imageView.center.y{
                    imageView.center.y = maxCenterY
                }
                if minCenterY > imageView.center.y {
                    imageView.center.y = minCenterY
                }
            } else {
                imageView.center.y = imageCenterY
            }


        }
    }
    
    @IBAction func panAction(_ sender: Any) {
        
        guard imageView.transform.a > 1 else {
            return
        }
        
        let transition = panGestureRecognizer.translation(in: imageView)
        var changedX = imageView.center.x + transition.x * imageView.transform.a
        var changedY = imageView.center.y + transition.y * imageView.transform.a
        
        
        if changedX > maxCenterX || changedX < minCenterX {
            changedX = imageView.center.x
        }
        if changedY > maxCenterY || changedY < minCenterY {
            changedY = imageView.center.y
        }
        
        imageView.center = CGPoint(x: changedX , y: changedY)

        panGestureRecognizer.setTranslation(CGPoint.zero, in: imageView)
        
    }
    
}
extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }
        
        let scale: CGFloat
        
        if bounds.width / image.size.width < bounds.height / image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }
        
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

