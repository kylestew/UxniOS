import UIKit

class ViewController: UIViewController {

    var uxn: UxnBridge = UxnBridge()

    override func viewDidLoad() {
        super.viewDidLoad()

        let file = "hello.rom"
        uxn.load(file)
    }

}
