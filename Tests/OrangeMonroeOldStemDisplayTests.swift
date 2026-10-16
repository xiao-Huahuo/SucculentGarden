import Foundation
import Testing

struct OrangeMonroeOldStemDisplayTests {
    @Test func orangeMonroeOldStemGrowsSingleHeadWhileOtherCrassulaceaeKeepTheirArt() {
        let species = SucculentSpecies.orangeMonroe
        #expect(species.assetName(stage: .oldStem) == species.assetName(stage: .prime))
        let prime = SucculentArtworkSize.centimeters(species: species, stage: .prime, isLeaf: false)
        let older = SucculentArtworkSize.centimeters(species: species, stage: .oldStem, isLeaf: false)
        #expect(older.width > prime.width && older.height > prime.height)
        #expect(species.purchasePrice(for: .oldStem) != species.purchasePrice(for: .prime))
        for other in SucculentSpecies.allCases where other.morphology == .crassulaceaeType && other != species {
            #expect(other.assetName(stage: .oldStem) != other.assetName(stage: .prime))
        }
    }
}
