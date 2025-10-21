package dev.mostafamovahhed.traccar_flutter.client

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import java.io.IOException
import java.net.SocketTimeoutException
import java.util.*

/**
 * Unit tests for TraccarError sealed class hierarchy.
 */
class TraccarErrorTest {

    @Test
    fun `network client error provides correct messages`() {
        val error = TraccarError.Network.ClientError(400, "Bad Request")

        assertTrue(error.toUserMessage().contains("400"))
        assertTrue(error.toDiagnosticMessage().contains("ClientError"))
    }

    @Test
    fun `network server error provides correct messages`() {
        val error = TraccarError.Network.ServerError(500, "Internal Server Error")

        assertTrue(error.toUserMessage().contains("500"))
        assertTrue(error.toDiagnosticMessage().contains("ServerError"))
    }

    @Test
    fun `network timeout provides user-friendly message`() {
        val error = TraccarError.Network.Timeout(15000)

        assertEquals("Request timed out. Please check your connection.", error.toUserMessage())
        assertTrue(error.toDiagnosticMessage().contains("15000"))
    }

    @Test
    fun `network connection failure provides correct messages`() {
        val error = TraccarError.Network.ConnectionFailed("No route to host")

        assertTrue(error.toUserMessage().contains("connection"))
        assertTrue(error.toDiagnosticMessage().contains("No route to host"))
    }

    @Test
    fun `database insert failure provides correct messages`() {
        val position = Position(0, "device", Date(), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 100.0, false, false)
        val error = TraccarError.Database.InsertFailed(position, Exception("Constraint violation"))

        assertTrue(error.toUserMessage().contains("save"))
        assertTrue(error.toDiagnosticMessage().contains("Constraint violation"))
    }

    @Test
    fun `location permission denied provides correct messages`() {
        val error = TraccarError.Location.PermissionDenied("ACCESS_FINE_LOCATION")

        assertTrue(error.toUserMessage().contains("ACCESS_FINE_LOCATION"))
        assertTrue(error.toDiagnosticMessage().contains("PermissionDenied"))
    }

    @Test
    fun `configuration invalid device id provides correct messages`() {
        val error = TraccarError.Configuration.InvalidDeviceId("")

        assertTrue(error.toUserMessage().contains("Invalid"))
        assertTrue(error.toDiagnosticMessage().contains("InvalidDeviceId"))
    }

    @Test
    fun `service start failure provides correct messages`() {
        val error = TraccarError.Service.StartFailed("Permission denied", null)

        assertTrue(error.toUserMessage().contains("start"))
        assertTrue(error.toDiagnosticMessage().contains("Permission denied"))
    }

    @Test
    fun `exception to TraccarError conversion for timeout`() {
        val exception = SocketTimeoutException("Read timed out")
        val error = exception.toTraccarError()

        assertTrue(error is TraccarError.Network.Timeout)
    }

    @Test
    fun `exception to TraccarError conversion for IOException`() {
        val exception = IOException("Network is unreachable")
        val error = exception.toTraccarError()

        assertTrue(error is TraccarError.Network.ConnectionFailed)
    }

    @Test
    fun `exception to TraccarError conversion for SecurityException`() {
        val exception = SecurityException("Location permission required")
        val error = exception.toTraccarError()

        assertTrue(error is TraccarError.Location.PermissionDenied)
    }

    @Test
    fun `all error types have non-empty user messages`() {
        val position = Position(0, "device", Date(), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 100.0, false, false)
        val errors = listOf<TraccarError>(
            TraccarError.Network.ClientError(404),
            TraccarError.Network.ServerError(500),
            TraccarError.Network.Timeout(15000),
            TraccarError.Network.ConnectionFailed("test"),
            TraccarError.Network.Unexpected(Exception()),
            TraccarError.Database.InsertFailed(position, Exception()),
            TraccarError.Database.QueryFailed("SELECT", Exception()),
            TraccarError.Database.DeleteFailed(1L, Exception()),
            TraccarError.Location.PermissionDenied("test"),
            TraccarError.Location.ServicesDisabled,
            TraccarError.Configuration.InvalidDeviceId(""),
            TraccarError.Configuration.NotInitialized,
            TraccarError.Service.StartFailed("test")
        )

        errors.forEach { error ->
            assertTrue(error.toUserMessage().isNotEmpty(), "User message empty for ${error.javaClass.simpleName}")
            assertTrue(error.toDiagnosticMessage().isNotEmpty(), "Diagnostic message empty for ${error.javaClass.simpleName}")
        }
    }
}
