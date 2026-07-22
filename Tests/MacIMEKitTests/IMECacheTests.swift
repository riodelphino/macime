import InputMethodKit
import XCTest

@testable import MacIMEKit

final class IMECacheTests: XCTestCase {
   private func inputSources() throws -> (TISInputSource, TISInputSource) {
      let sources = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
      let list = sources as! [TISInputSource]
      guard list.count >= 2 else {
         throw XCTSkip("requires two enabled input sources")
      }
      return (list[0], list[1])
   }

   func testSourcesLoadOnceUntilRefresh() throws {
      let (first, _) = try inputSources()
      var loadCount = 0
      let cache = InputSourceCache {
         loadCount += 1
         return [first]
      }

      XCTAssertEqual(cache.sources().first?.id, first.id)
      XCTAssertEqual(cache.sources().first?.id, first.id)
      XCTAssertEqual(loadCount, 1)

      XCTAssertEqual(cache.refresh().first?.id, first.id)
      XCTAssertEqual(loadCount, 2)
   }

   func testInitialSourceMissLoadsOnce() throws {
      let (first, second) = try inputSources()
      var loadCount = 0
      let cache = InputSourceCache {
         loadCount += 1
         return [first]
      }

      XCTAssertNil(cache.source(id: second.id))
      XCTAssertEqual(loadCount, 1)
   }

   func testCachedSourceMissRefreshesCache() throws {
      let (first, second) = try inputSources()
      var loadCount = 0
      let cache = InputSourceCache {
         loadCount += 1
         return loadCount == 1 ? [first] : [first, second]
      }

      XCTAssertEqual(cache.sources().first?.id, first.id)
      XCTAssertEqual(cache.source(id: second.id)?.id, second.id)
      XCTAssertEqual(loadCount, 2)
      XCTAssertEqual(cache.sources().count, 2)
   }

   func testSelectionFailureRefreshesCache() throws {
      let (first, _) = try inputSources()
      var loadCount = 0
      let cache = InputSourceCache {
         loadCount += 1
         return [first]
      }
      var selectionCount = 0

      let selected = try IME.select(id: first.id, sourceCache: cache) { _ in
         selectionCount += 1
         return selectionCount == 1 ? -1 : 0
      }

      XCTAssertEqual(selected.id, first.id)
      XCTAssertEqual(loadCount, 2)
      XCTAssertEqual(selectionCount, 2)
   }
}
