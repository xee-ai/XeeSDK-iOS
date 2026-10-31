#if canImport(Testing)

@testable import Xee
import Testing

struct ComputedProfileIdTests {
    /// Python's `uuid.uuid5(UUID("3d6f4a5e-2b1c-4e8f-9a7d-58e2c1b0a9f4"), "ccpjmfxpm7")`: any tool can compute the same ID.
    @Test func theIdIsTheStandardUuidV5OfTheCustomerUserId() {
        #expect(XeeUserId.computedProfileId(for: "ccpjmfxpm7") == "3f810746-6219-57a9-b052-0f330cfb4b5e")
    }

    @Test func onlyAnIdComputedFromItsOwnCustomerUserIdIsComputed() {
        let id = XeeUserId.computedProfileId(for: "ccpjmfxpm7")
        #expect(XeeUserId(profileId: id, customerId: "ccpjmfxpm7").isComputed)
        #expect(!XeeUserId(profileId: id, customerId: "another").isComputed)
        #expect(!XeeUserId(profileId: "10f0a7e0-095f-424c-ab74-d2c13c1d1fd9", customerId: "ccpjmfxpm7").isComputed)
        #expect(!XeeUserId(profileId: id, customerId: nil).isComputed)
    }
}

#endif
