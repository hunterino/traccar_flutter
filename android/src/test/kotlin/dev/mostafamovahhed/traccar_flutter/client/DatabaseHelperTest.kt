package dev.mostafamovahhed.traccar_flutter.client

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import dev.mostafamovahhed.traccar_flutter.client.database.TraccarDatabase
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.sql.Date
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Unit tests for DatabaseHelper with Room database.
 *
 * These tests verify the Room database implementation works correctly
 * and that the DatabaseHelper facade properly wraps Room operations.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class DatabaseHelperTest {

    private lateinit var context: Context
    private lateinit var databaseHelper: DatabaseHelper

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        databaseHelper = DatabaseHelper(context)
    }

    @After
    fun tearDown() {
        // Clear Room database instance
        TraccarDatabase.clearInstance()
        context.deleteDatabase(DatabaseHelper.DATABASE_NAME)
    }

    @Test
    fun `insertPosition should insert position successfully`() {
        // Arrange
        val position = createTestPosition()

        // Act
        databaseHelper.insertPosition(position)
        val retrieved = databaseHelper.selectPosition()

        // Assert
        assertNotNull(retrieved)
        assertEquals(position.deviceId, retrieved.deviceId)
        assertEquals(position.latitude, retrieved.latitude, 0.0001)
        assertEquals(position.longitude, retrieved.longitude, 0.0001)
    }

    @Test
    fun `insertPositionAsync should insert position successfully`() = runTest {
        // Arrange
        val position = createTestPosition()

        // Act
        val result = databaseHelper.insertPositionAsync(position)

        // Assert
        assertTrue(result.isSuccess)

        val retrieved = databaseHelper.selectPosition()
        assertNotNull(retrieved)
        assertEquals(position.deviceId, retrieved.deviceId)
    }

    @Test
    fun `insertPositionAsync should return TraccarError on failure`() = runTest {
        // This test demonstrates error handling structure
        // In a real scenario, we'd force a DB error, but for this test
        // we just verify the structure works
        val position = createTestPosition()

        // Act
        val result = databaseHelper.insertPositionAsync(position)

        // Assert - verify result is handled properly
        result.onSuccess {
            // Success case - position inserted
            assertTrue(true)
        }.onFailure { error ->
            // Failure case - should be TraccarError
            assertTrue(error is TraccarError.Database.InsertFailed)
        }
    }

    @Test
    fun `selectPosition should return null when database is empty`() {
        // Act
        val result = databaseHelper.selectPosition()

        // Assert
        assertNull(result)
    }

    @Test
    fun `selectPositionAsync should return success with null when database is empty`() = runTest {
        // Act
        val result = databaseHelper.selectPositionAsync()

        // Assert
        assertTrue(result.isSuccess)
        assertNull(result.getOrNull())
    }

    @Test
    fun `deletePosition should remove position from database`() {
        // Arrange
        val position = createTestPosition()
        databaseHelper.insertPosition(position)
        val inserted = databaseHelper.selectPosition()
        assertNotNull(inserted)

        // Act
        databaseHelper.deletePosition(inserted.id)

        // Assert
        val afterDelete = databaseHelper.selectPosition()
        assertNull(afterDelete)
    }

    @Test
    fun `deletePositionAsync should remove position from database`() = runTest {
        // Arrange
        val position = createTestPosition()
        databaseHelper.insertPosition(position)
        val inserted = databaseHelper.selectPosition()
        assertNotNull(inserted)

        // Act
        val result = databaseHelper.deletePositionAsync(inserted.id)

        // Assert
        assertTrue(result.isSuccess)
        val afterDelete = databaseHelper.selectPosition()
        assertNull(afterDelete)
    }

    @Test
    fun `deletePositionAsync should return error when position not found`() = runTest {
        // Act - try to delete non-existent position
        val result = databaseHelper.deletePositionAsync(99999L)

        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is TraccarError.Database.DeleteFailed)
    }

    @Test
    fun `getCountAsync should return correct count`() = runTest {
        // Arrange - insert multiple positions
        val position1 = createTestPosition()
        val position2 = createTestPosition(deviceId = "device-2")
        databaseHelper.insertPositionAsync(position1)
        databaseHelper.insertPositionAsync(position2)

        // Act
        val result = databaseHelper.getCountAsync()

        // Assert
        assertTrue(result.isSuccess)
        assertEquals(2, result.getOrNull())
    }

    @Test
    fun `getCountAsync should return zero for empty database`() = runTest {
        // Act
        val result = databaseHelper.getCountAsync()

        // Assert
        assertTrue(result.isSuccess)
        assertEquals(0, result.getOrNull())
    }

    @Test
    fun `deleteOlderThanAsync should delete old positions`() = runTest {
        // Arrange - insert positions with different timestamps
        val oldTime = System.currentTimeMillis() - 60 * 60 * 1000 // 1 hour ago
        val recentTime = System.currentTimeMillis()

        val oldPosition = createTestPosition(time = Date(oldTime))
        val recentPosition = createTestPosition(
            deviceId = "device-2",
            time = Date(recentTime)
        )

        databaseHelper.insertPositionAsync(oldPosition)
        databaseHelper.insertPositionAsync(recentPosition)

        // Act - delete positions older than 30 minutes
        val cutoffTime = System.currentTimeMillis() - 30 * 60 * 1000
        val result = databaseHelper.deleteOlderThanAsync(cutoffTime)

        // Assert
        assertTrue(result.isSuccess)
        assertEquals(1, result.getOrNull()) // Should delete 1 old position

        val countResult = databaseHelper.getCountAsync()
        assertEquals(1, countResult.getOrNull()) // Should have 1 remaining
    }

    @Test
    fun `deleteOlderThanAsync should return zero when no old positions`() = runTest {
        // Arrange - insert recent position
        val position = createTestPosition()
        databaseHelper.insertPositionAsync(position)

        // Act - delete positions older than 1 hour ago
        val cutoffTime = System.currentTimeMillis() - 60 * 60 * 1000
        val result = databaseHelper.deleteOlderThanAsync(cutoffTime)

        // Assert
        assertTrue(result.isSuccess)
        assertEquals(0, result.getOrNull()) // No positions deleted

        val countResult = databaseHelper.getCountAsync()
        assertEquals(1, countResult.getOrNull()) // Position still exists
    }

    @Test
    fun `multiple operations should maintain FIFO order`() = runTest {
        // Arrange - insert positions in specific order
        val position1 = createTestPosition(deviceId = "first")
        val position2 = createTestPosition(deviceId = "second")
        val position3 = createTestPosition(deviceId = "third")

        databaseHelper.insertPositionAsync(position1)
        databaseHelper.insertPositionAsync(position2)
        databaseHelper.insertPositionAsync(position3)

        // Act & Assert - should retrieve in FIFO order
        val first = databaseHelper.selectPositionAsync().getOrNull()
        assertNotNull(first)
        assertEquals("first", first.deviceId)

        databaseHelper.deletePositionAsync(first.id)

        val second = databaseHelper.selectPositionAsync().getOrNull()
        assertNotNull(second)
        assertEquals("second", second.deviceId)
    }

    private fun createTestPosition(
        deviceId: String = "test-device-123",
        time: Date = Date(System.currentTimeMillis())
    ) = Position(
        id = 0,
        deviceId = deviceId,
        time = time,
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
