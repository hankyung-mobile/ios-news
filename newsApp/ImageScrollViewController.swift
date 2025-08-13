import UIKit

class ImageScrollViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    var imageViewWidth:CGFloat = 0.0
    var imageViewHeight:CGFloat = 0.0
    
    var src:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let url: URL! = URL(string: self.src)
        let imageData = try! Data(contentsOf: url)
        
        imageView.image = UIImage(data: imageData)
        
        let imageWidth = imageView.contentClippingRect.width
        let imageHeight = imageView.contentClippingRect.height
        
        
        let vertical = (imageView.frame.height - imageHeight) / 2
        let horizontal = (imageView.frame.width - imageWidth) / 2

        for constraint in self.scrollView.constraints {

            if constraint.identifier == "imageViewTopConstraint" || constraint.identifier == "imageViewBottomConstraint" {
                constraint.constant = CGFloat(vertical)

            } else if constraint.identifier == "imageViewLeftConstraint" || constraint.identifier == "imageViewRightConstraint" {
                constraint.constant = CGFloat(horizontal)
            }
        }
        
        imageView.layoutIfNeeded()
        
        
//        scrollView.contentInset = UIEdgeInsets.zero
//        scrollView.sizeToFit()
//        scrollView.contentSize = imageView.frame.size
        
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
//        scrollView.contentInset = UIEdgeInsets.zero
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        let url: URL! = URL(string: self.src)
//        let imageData = try! Data(contentsOf: url)
//
//        imageView.image = UIImage(data: imageData)
//
//        let imageWidth = imageView.contentClippingRect.width
//        let imageHeight = imageView.contentClippingRect.height
//
//        let vertical = (imageViewHeight - imageHeight) / 2
//        let horizontal = (imageViewWidth - imageWidth) / 2


//        for constraint in self.scrollView.constraints {
//            if constraint.identifier == "imageViewTopConstraint" || constraint.identifier == "imageViewBottomConstraint" {
//                constraint.constant = CGFloat(vertical)
//
//            } else if constraint.identifier == "imageViewLeftConstraint" || constraint.identifier == "imageViewRightConstraint" {
//                constraint.constant = CGFloat(horizontal)
//            }
//        }
//        imageView.layoutIfNeeded()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        
        
//        for constraint in self.scrollView.constraints {
//            if constraint.identifier == "imageViewTopConstraint" || constraint.identifier == "imageViewBottomConstraint" {
//                constraint.constant = CGFloat(0.0)
//
//            } else if constraint.identifier == "imageViewLeftConstraint" || constraint.identifier == "imageViewRightConstraint" {
//                constraint.constant = CGFloat(0.0)
//            }
//        }
//        imageView.layoutIfNeeded()
//
//        scrollView.zoomScale = 1.0
//        imageView.image = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    @IBAction func closeView(_ sender: Any) {
         self.navigationController?.popViewController(animated: true)
    }

}
