import UIKit

class ViewController: UIViewController {

    var uxn: UxnBridge = UxnBridge()

    override func viewDidLoad() {
        super.viewDidLoad()

        let rom = Bundle.main.path(forResource: "screen", ofType: "rom")!
        uxn.load(rom)
    }

}
