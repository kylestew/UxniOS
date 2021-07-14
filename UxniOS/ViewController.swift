import UIKit

class ViewController: UIViewController {

    var uxn: UxnBridge = UxnBridge()

    override func viewDidLoad() {
        super.viewDidLoad()

        let rom = Bundle.main.path(forResource: "screen", ofType: "rom")!
        uxn.load(rom)
    }

    @IBOutlet weak var renderView: UIView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let imageRef = uxn.redraw() {
            let cgImage = imageRef.takeUnretainedValue()
            renderView.layer.contents = cgImage
        }
    }

}
