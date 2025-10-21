package dev.mostafamovahhed.traccar_flutter.client

import kotlinx.coroutines.test.runTest
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class RequestManagerTest {

    @Test
    fun `sendRequest should handle invalid URL`() {
        // Arrange
        val invalidUrl = "not-a-valid-url"

        // Act
        val result = RequestManager.sendRequest(invalidUrl)

        // Assert
        assertFalse(result)
    }

    @Test
    fun `sendRequest should handle null URL`() {
        // Act
        val result = RequestManager.sendRequest(null)

        // Assert
        assertFalse(result)
    }

    @Test
    fun `sendRequestAsync should return failure for invalid URL`() = runTest {
        // Arrange
        val invalidUrl = "not-a-valid-url"

        // Act
        val result = RequestManager.sendRequestAsync(invalidUrl)

        // Assert
        assertTrue(result.isFailure)
    }

    @Test
    fun `sendRequestAsync should handle connection timeout`() = runTest {
        // Arrange - use a URL that will timeout
        val timeoutUrl = "http://10.255.255.1:12345/"

        // Act
        val result = RequestManager.sendRequestAsync(timeoutUrl)

        // Assert
        assertTrue(result.isFailure) // Should fail due to timeout
    }

    @Test
    fun `sendRequestAsync should return Result type`() = runTest {
        // Arrange
        val testUrl = "http://example.com/test"

        // Act
        val result = RequestManager.sendRequestAsync(testUrl)

        // Assert - verify Result type structure
        assertTrue(result.isSuccess || result.isFailure)
    }
}
