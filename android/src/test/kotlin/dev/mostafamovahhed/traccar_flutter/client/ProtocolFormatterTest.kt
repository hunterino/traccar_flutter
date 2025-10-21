package dev.mostafamovahhed.traccar_flutter.client

import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.sql.Date
import kotlin.test.assertTrue

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class ProtocolFormatterTest {

    @Test
    fun `formatRequest should include device ID`() {
        // Arrange
        val url = "https://demo.traccar.org"
        val position = createTestPosition("test-device-123")

        // Act
        val result = ProtocolFormatter.formatRequest(url, position)

        // Assert
        assertTrue(result.contains("id=test-device-123"))
    }

    @Test
    fun `formatRequest should include latitude and longitude`() {
        // Arrange
        val url = "https://demo.traccar.org"
        val position = createTestPosition().copy(
            latitude = 37.7749,
            longitude = -122.4194
        )

        // Act
        val result = ProtocolFormatter.formatRequest(url, position)

        // Assert
        assertTrue(result.contains("lat=37.7749"))
        assertTrue(result.contains("lon=-122.4194"))
    }

    @Test
    fun `formatRequest should include timestamp`() {
        // Arrange
        val url = "https://demo.traccar.org"
        val timestamp = 1234567890000L
        val position = createTestPosition().copy(
            time = Date(timestamp)
        )

        // Act
        val result = ProtocolFormatter.formatRequest(url, position)

        // Assert
        assertTrue(result.contains("timestamp=1234567890"))
    }

    @Test
    fun `formatRequest should include speed when available`() {
        // Arrange
        val url = "https://demo.traccar.org"
        val position = createTestPosition().copy(speed = 25.5)

        // Act
        val result = ProtocolFormatter.formatRequest(url, position)

        // Assert
        assertTrue(result.contains("speed="))
    }

    @Test
    fun `formatRequest should include battery level`() {
        // Arrange
        val url = "https://demo.traccar.org"
        val position = createTestPosition().copy(battery = 85.0)

        // Act
        val result = ProtocolFormatter.formatRequest(url, position)

        // Assert
        assertTrue(result.contains("batt=85.0"))
    }

    @Test
    fun `formatRequest should include charging status`() {
        // Arrange
        val url = "https://demo.traccar.org"
        val position = createTestPosition().copy(charging = true)

        // Act
        val result = ProtocolFormatter.formatRequest(url, position)

        // Assert
        assertTrue(result.contains("charge=true"))
    }

    @Test
    fun `formatRequest should start with base URL`() {
        // Arrange
        val url = "https://demo.traccar.org"
        val position = createTestPosition()

        // Act
        val result = ProtocolFormatter.formatRequest(url, position)

        // Assert
        assertTrue(result.startsWith(url))
    }

    private fun createTestPosition(deviceId: String = "test-device") = Position(
        id = 1,
        deviceId = deviceId,
        time = Date(System.currentTimeMillis()),
        latitude = 37.7749,
        longitude = -122.4194,
        altitude = 100.0,
        speed = 0.0,
        course = 0.0,
        accuracy = 10.0,
        battery = 85.0,
        charging = false,
        mock = false
    )
}
