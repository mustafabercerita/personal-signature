import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

let filter = CIFilter.morphologyMinimum()
print(filter.attributes)
