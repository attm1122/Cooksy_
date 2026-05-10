import XCTest
@testable import Cooksy

// MARK: - Source Model Tests
/// Comprehensive unit tests for the Source struct covering all initializers,
/// stored properties, computed properties, Codable encode/decode round-trips,
/// Hashable, Equatable, Sendable conformance, and edge cases.
final class SourceTests: XCTestCase {

    // MARK: - Factory Helpers

    private func makeSource(
        url: String = "https://youtube.com/watch?v=test123",
        platform: SourcePlatform = .youtube,
        creator: String = "Test Chef",
        title: String = "Amazing Pasta Recipe"
    ) -> Source {
        Source(
            url: url,
            platform: platform,
            creator: creator,
            title: title
        )
    }

    // MARK: - Initialization Tests

    func testInit_WithAllValues() {
        let source = makeSource()

        XCTAssertEqual(source.url, "https://youtube.com/watch?v=test123")
        XCTAssertEqual(source.platform, .youtube)
        XCTAssertEqual(source.creator, "Test Chef")
        XCTAssertEqual(source.title, "Amazing Pasta Recipe")
    }

    func testInit_YouTube() {
        let source = makeSource(
            url: "https://youtube.com/watch?v=abc123",
            platform: .youtube,
            creator: "Chef John",
            title: "How to Make Pizza"
        )

        XCTAssertEqual(source.platform, .youtube)
        XCTAssertEqual(source.url, "https://youtube.com/watch?v=abc123")
    }

    func testInit_TikTok() {
        let source = makeSource(
            url: "https://tiktok.com/@chefanna/video/456",
            platform: .tiktok,
            creator: "Chef Anna",
            title: "Quick Dinner Idea"
        )

        XCTAssertEqual(source.platform, .tiktok)
        XCTAssertEqual(source.creator, "Chef Anna")
    }

    func testInit_Instagram() {
        let source = makeSource(
            url: "https://instagram.com/reels/xyz789",
            platform: .instagram,
            creator: "Bake Master",
            title: "Chocolate Cake"
        )

        XCTAssertEqual(source.platform, .instagram)
        XCTAssertEqual(source.title, "Chocolate Cake")
    }

    func testInit_EmptyUrl() {
        let source = makeSource(url: "")

        XCTAssertEqual(source.url, "")
    }

    func testInit_EmptyCreator() {
        let source = makeSource(creator: "")

        XCTAssertEqual(source.creator, "")
    }

    func testInit_EmptyTitle() {
        let source = makeSource(title: "")

        XCTAssertEqual(source.title, "")
    }

    func testInit_UnicodeValues() {
        let source = makeSource(
            url: "https://youtube.com/watch?v=日本",
            platform: .youtube,
            creator: "田中シェフ",
            title: "最高の寿司"
        )

        XCTAssertEqual(source.creator, "田中シェフ")
        XCTAssertEqual(source.title, "最高の寿司")
    }

    func testInit_LongUrl() {
        let longUrl = "https://youtube.com/watch?v=" + String(repeating: "a", count: 500)
        let source = makeSource(url: longUrl)

        XCTAssertEqual(source.url, longUrl)
    }

    func testInit_MalformedUrl() {
        let source = makeSource(url: "not-a-valid-url")

        XCTAssertEqual(source.url, "not-a-valid-url")
    }

    func testInit_UrlWithSpecialCharacters() {
        let source = makeSource(url: "https://youtube.com/watch?v=abc&list=xyz&index=1")

        XCTAssertEqual(source.url, "https://youtube.com/watch?v=abc&list=xyz&index=1")
    }

    func testInit_UrlWithQueryParameters() {
        let source = makeSource(url: "https://youtube.com/watch?v=dQw4w9WgXcQ&t=42s")

        XCTAssertEqual(source.url, "https://youtube.com/watch?v=dQw4w9WgXcQ&t=42s")
    }

    // MARK: - Stored Property Tests

    func testUrl_IsStored() {
        let source = makeSource(url: "https://example.com/video")

        XCTAssertEqual(source.url, "https://example.com/video")
    }

    func testPlatform_IsStored() {
        let source = makeSource(platform: .tiktok)

        XCTAssertEqual(source.platform, .tiktok)
    }

    func testCreator_IsStored() {
        let source = makeSource(creator: "Gordon Ramsay")

        XCTAssertEqual(source.creator, "Gordon Ramsay")
    }

    func testTitle_IsStored() {
        let source = makeSource(title: "Beef Wellington")

        XCTAssertEqual(source.title, "Beef Wellington")
    }

    // MARK: - displayAttribution Computed Property Tests

    func testDisplayAttribution_YouTube() {
        let source = makeSource(platform: .youtube, creator: "Chef John")

        XCTAssertEqual(source.displayAttribution, "By Chef John on YouTube")
    }

    func testDisplayAttribution_TikTok() {
        let source = makeSource(platform: .tiktok, creator: "Chef Anna")

        XCTAssertEqual(source.displayAttribution, "By Chef Anna on TikTok")
    }

    func testDisplayAttribution_Instagram() {
        let source = makeSource(platform: .instagram, creator: "Bake Master")

        XCTAssertEqual(source.displayAttribution, "By Bake Master on Instagram")
    }

    func testDisplayAttribution_EmptyCreator() {
        let source = makeSource(creator: "", platform: .youtube)

        XCTAssertEqual(source.displayAttribution, "By  on YouTube")
    }

    func testDisplayAttribution_UnicodeCreator() {
        let source = makeSource(creator: "田中シェフ", platform: .youtube)

        XCTAssertEqual(source.displayAttribution, "By 田中シェフ on YouTube")
    }

    // MARK: - shortAttribution Computed Property Tests

    func testShortAttribution() {
        let source = makeSource(creator: "Chef John")

        XCTAssertEqual(source.shortAttribution, "Chef John")
    }

    func testShortAttribution_EmptyCreator() {
        let source = makeSource(creator: "")

        XCTAssertEqual(source.shortAttribution, "")
    }

    func testShortAttribution_UnicodeCreator() {
        let source = makeSource(creator: "🍳 Chef")

        XCTAssertEqual(source.shortAttribution, "🍳 Chef")
    }

    func testShortAttribution_VeryLongCreator() {
        let longCreator = String(repeating: "A", count: 500)
        let source = makeSource(creator: longCreator)

        XCTAssertEqual(source.shortAttribution, longCreator)
    }

    // MARK: - Codable Encode/Decode Tests

    func testCodable_RoundTrip() throws {
        let original = makeSource()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Source.self, from: data)

        XCTAssertEqual(decoded.url, original.url)
        XCTAssertEqual(decoded.platform, original.platform)
        XCTAssertEqual(decoded.creator, original.creator)
        XCTAssertEqual(decoded.title, original.title)
    }

    func testCodable_RoundTrip_YouTube() throws {
        let original = makeSource(
            url: "https://youtube.com/watch?v=abc123",
            platform: .youtube,
            creator: "Chef John",
            title: "Pizza Recipe"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Source.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testCodable_RoundTrip_TikTok() throws {
        let original = makeSource(
            url: "https://tiktok.com/@user/video/123",
            platform: .tiktok,
            creator: "TikTok Chef",
            title: "Quick Meal"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Source.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testCodable_RoundTrip_Instagram() throws {
        let original = makeSource(
            url: "https://instagram.com/reels/abc",
            platform: .instagram,
            creator: "Insta Chef",
            title: "Vegan Bowl"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Source.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testCodable_KeysAreCorrect() throws {
        let source = makeSource(
            url: "https://example.com",
            platform: .youtube,
            creator: "Test",
            title: "Title"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(source)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("\"creator\""))
        XCTAssertTrue(json.contains("\"platform\""))
        XCTAssertTrue(json.contains("\"title\""))
        XCTAssertTrue(json.contains("\"url\""))
    }

    func testCodable_PlatformIsEncodedAsString() throws {
        let source = makeSource(platform: .youtube)

        let encoder = JSONEncoder()
        let data = try encoder.encode(source)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("youtube"))
    }

    func testCodable_DecodeFromJSONString() throws {
        let jsonString = """
        {
            "url": "https://youtube.com/watch?v=test",
            "platform": "youtube",
            "creator": "Test Chef",
            "title": "Test Title"
        }
        """

        let decoder = JSONDecoder()
        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        let source = try decoder.decode(Source.self, from: data)

        XCTAssertEqual(source.url, "https://youtube.com/watch?v=test")
        XCTAssertEqual(source.platform, .youtube)
        XCTAssertEqual(source.creator, "Test Chef")
        XCTAssertEqual(source.title, "Test Title")
    }

    func testCodable_DecodeTikTokFromJSONString() throws {
        let jsonString = """
        {
            "url": "https://tiktok.com/@user/123",
            "platform": "tiktok",
            "creator": "TikTok User",
            "title": "Dance Recipe"
        }
        """

        let decoder = JSONDecoder()
        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        let source = try decoder.decode(Source.self, from: data)

        XCTAssertEqual(source.platform, .tiktok)
        XCTAssertEqual(source.creator, "TikTok User")
    }

    func testCodable_DecodeInvalidPlatform_Throws() {
        let jsonString = """
        {
            "url": "https://unknown.com",
            "platform": "nonexistent_platform",
            "creator": "Test",
            "title": "Test"
        }
        """

        let decoder = JSONDecoder()
        let data = jsonString.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(Source.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testCodable_EmptyStrings_RoundTrip() throws {
        let original = makeSource(url: "", creator: "", title: "")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Source.self, from: data)

        XCTAssertEqual(decoded.url, "")
        XCTAssertEqual(decoded.creator, "")
        XCTAssertEqual(decoded.title, "")
    }

    func testCodable_UnicodeValues_RoundTrip() throws {
        let original = makeSource(
            url: "https://日本語.jp",
            platform: .youtube,
            creator: "シェフ",
            title: "レシピ"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Source.self, from: data)

        XCTAssertEqual(decoded.creator, "シェフ")
        XCTAssertEqual(decoded.title, "レシピ")
    }

    // MARK: - Equatable Tests

    func testEquality_AllFieldsEqual() {
        let source1 = makeSource()
        let source2 = makeSource()

        // Sources are structs with value equality, but UUIDs in URLs differ
        // Actually, since they use the same default URL, they're equal
        XCTAssertEqual(source1.url, source2.url)
    }

    func testEquality_SameValues() {
        let source1 = makeSource(
            url: "https://same.com",
            platform: .youtube,
            creator: "Same",
            title: "Same"
        )
        let source2 = makeSource(
            url: "https://same.com",
            platform: .youtube,
            creator: "Same",
            title: "Same"
        )

        XCTAssertEqual(source1, source2)
    }

    func testEquality_DifferentUrl() {
        let source1 = makeSource(url: "https://a.com")
        let source2 = makeSource(url: "https://b.com")

        XCTAssertNotEqual(source1, source2)
    }

    func testEquality_DifferentPlatform() {
        let source1 = makeSource(platform: .youtube)
        let source2 = makeSource(platform: .tiktok)

        XCTAssertNotEqual(source1, source2)
    }

    func testEquality_DifferentCreator() {
        let source1 = makeSource(creator: "Chef A")
        let source2 = makeSource(creator: "Chef B")

        XCTAssertNotEqual(source1, source2)
    }

    func testEquality_DifferentTitle() {
        let source1 = makeSource(title: "Title A")
        let source2 = makeSource(title: "Title B")

        XCTAssertNotEqual(source1, source2)
    }

    // MARK: - Hashable Tests

    func testHashable_SameValues() {
        let source1 = makeSource(url: "https://same.com", creator: "Same", title: "Same")
        let source2 = makeSource(url: "https://same.com", creator: "Same", title: "Same")

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        source1.hash(into: &hasher1)
        source2.hash(into: &hasher2)

        XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testHashable_DifferentValues() {
        let source1 = makeSource(url: "https://a.com")
        let source2 = makeSource(url: "https://b.com")

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        source1.hash(into: &hasher1)
        source2.hash(into: &hasher2)

        XCTAssertNotEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testHashable_UsedInSet() {
        let source1 = makeSource(url: "https://a.com")
        let source2 = makeSource(url: "https://b.com")

        let set: Set<Source> = [source1, source2, source1]

        XCTAssertEqual(set.count, 2)
    }

    func testHashable_UsedInDictionary() {
        let source = makeSource(url: "https://test.com")

        let dict: [Source: Int] = [source: 42]

        XCTAssertEqual(dict[source], 42)
    }

    // MARK: - Sendable Conformance Tests

    func testSource_IsSendable() {
        // Compile-time check: Source conforms to Sendable
        let source = makeSource()

        // If this compiles, Sendable conformance is verified
        func takesSendable<T: Sendable>(_ value: T) {
            // no-op
        }
        takesSendable(source)

        // Runtime verification that properties are accessible
        XCTAssertEqual(source.platform, .youtube)
    }

    func testSource_CanBeUsedConcurrently() {
        let source = makeSource()
        let expectation = self.expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            DispatchQueue.global().async {
                _ = source.displayAttribution
                _ = source.shortAttribution
                _ = source.url
                _ = source.platform
                _ = source.creator
                _ = source.title
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Mutation Tests (Struct Copy-on-Write)

    func testMutation_CreatesNewValue() {
        var source1 = makeSource(creator: "Original")
        let source2 = source1
        source1.creator = "Modified"

        XCTAssertEqual(source1.creator, "Modified")
        XCTAssertEqual(source2.creator, "Original")
    }

    func testMutation_Url() {
        var source = makeSource(url: "https://old.com")
        source.url = "https://new.com"

        XCTAssertEqual(source.url, "https://new.com")
    }

    func testMutation_Platform() {
        var source = makeSource(platform: .youtube)
        source.platform = .tiktok

        XCTAssertEqual(source.platform, .tiktok)
    }

    func testMutation_Creator() {
        var source = makeSource(creator: "Old")
        source.creator = "New"

        XCTAssertEqual(source.creator, "New")
    }

    func testMutation_Title() {
        var source = makeSource(title: "Old Title")
        source.title = "New Title"

        XCTAssertEqual(source.title, "New Title")
    }

    // MARK: - Edge Case Tests

    func testDisplayAttribution_VeryLongCreator() {
        let longCreator = String(repeating: "A", count: 500)
        let source = makeSource(creator: longCreator, platform: .youtube)

        XCTAssertTrue(source.displayAttribution.hasPrefix("By \(longCreator) on YouTube"))
    }

    func testDisplayAttribution_SpecialCharactersInCreator() {
        let source = makeSource(creator: "Chef O'Brien-Smith Jr.", platform: .youtube)

        XCTAssertEqual(source.displayAttribution, "By Chef O'Brien-Smith Jr. on YouTube")
    }

    func testDisplayAttribution_EmojiInCreator() {
        let source = makeSource(creator: "🍕 Pizza King", platform: .tiktok)

        XCTAssertEqual(source.displayAttribution, "By 🍕 Pizza King on TikTok")
    }

    func testShortAttribution_AfterMutation() {
        var source = makeSource(creator: "Original")
        source.creator = "Updated"

        XCTAssertEqual(source.shortAttribution, "Updated")
    }

    func testUrl_WithPercentEncoding() {
        let source = makeSource(url: "https://youtube.com/watch?v=abc%20def")

        XCTAssertEqual(source.url, "https://youtube.com/watch?v=abc%20def")
    }

    func testUrl_WithoutScheme() {
        let source = makeSource(url: "youtube.com/watch")

        XCTAssertEqual(source.url, "youtube.com/watch")
    }

    func testCodable_AllPlatforms_RoundTrip() throws {
        for platform in [SourcePlatform.youtube, .tiktok, .instagram] {
            let source = makeSource(platform: platform)

            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let data = try encoder.encode(source)
            let decoded = try decoder.decode(Source.self, from: data)

            XCTAssertEqual(decoded.platform, platform)
        }
    }
}
