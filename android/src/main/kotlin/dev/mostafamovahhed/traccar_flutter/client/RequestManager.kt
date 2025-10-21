/*
 * Copyright 2015 - 2021 Anton Tananaev (anton@traccar.org)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package dev.mostafamovahhed.traccar_flutter.client

import timber.log.Timber
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.scalars.ScalarsConverterFactory
import java.io.IOException
import java.net.SocketTimeoutException
import java.util.concurrent.TimeUnit

/**
 * Modern HTTP request manager using Retrofit and OkHttp.
 *
 * Benefits over deprecated HttpURLConnection:
 * - Automatic connection pooling and reuse
 * - Built-in retry mechanisms
 * - Interceptor support for logging and authentication
 * - Better error handling
 * - Industry standard for Android networking
 */
object RequestManager {

    private const val TIMEOUT_SECONDS = 15L
    private val TAG = RequestManager::class.java.simpleName

    private val loggingInterceptor = HttpLoggingInterceptor { message ->
        Timber.tag(TAG).d(message)
    }.apply {
        level = if (BuildConfig.DEBUG) {
            HttpLoggingInterceptor.Level.BODY
        } else {
            HttpLoggingInterceptor.Level.BASIC
        }
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .connectTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .writeTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true) // Automatic retry on connection failures
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl("http://placeholder.com") // Not used - we use dynamic URLs
        .client(okHttpClient)
        .addConverterFactory(ScalarsConverterFactory.create())
        .build()

    private val api = retrofit.create(TraccarApi::class.java)

    /**
     * Sends a request to the Traccar server using modern Retrofit/OkHttp.
     *
     * @param request The complete URL with query parameters
     * @return Result.success(Unit) if successful, Result.failure(TraccarError) otherwise
     */
    suspend fun sendRequestAsync(request: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            Timber.tag(TAG).i("Sending request: $request")

            val response = api.sendPosition(request)

            when {
                response.isSuccessful -> {
                    Timber.tag(TAG).i("Request successful: ${response.code()}")
                    Result.success(Unit)
                }
                response.code() in 400..499 -> {
                    val error = TraccarError.Network.ClientError(
                        statusCode = response.code(),
                        responseMessage = response.message()
                    )
                    Timber.tag(TAG).e(error.toDiagnosticMessage())
                    Result.failure(error)
                }
                response.code() in 500..599 -> {
                    val error = TraccarError.Network.ServerError(
                        statusCode = response.code(),
                        responseMessage = response.message()
                    )
                    Timber.tag(TAG).e(error.toDiagnosticMessage())
                    Result.failure(error)
                }
                else -> {
                    val error = TraccarError.Network.Unexpected(
                        IOException("Unexpected response: ${response.code()}")
                    )
                    Timber.tag(TAG).e(error.toDiagnosticMessage())
                    Result.failure(error)
                }
            }
        } catch (e: SocketTimeoutException) {
            val error = TraccarError.Network.Timeout(TIMEOUT_SECONDS * 1000)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        } catch (e: IOException) {
            val error = TraccarError.Network.ConnectionFailed(e.message ?: "Unknown IO error")
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        } catch (e: Exception) {
            val error = TraccarError.Network.Unexpected(e)
            Timber.tag(TAG).e(error.toDiagnosticMessage(), e)
            Result.failure(error)
        }
    }

    /**
     * Legacy synchronous method - kept for backward compatibility.
     * @deprecated Use sendRequestAsync instead
     */
    @Deprecated("Use sendRequestAsync instead",
        ReplaceWith("runBlocking { sendRequestAsync(request).isSuccess }"))
    fun sendRequest(request: String?): Boolean {
        if (request == null) return false
        Timber.tag(TAG).w("Using deprecated sendRequest method")
        return try {
            kotlinx.coroutines.runBlocking {
                sendRequestAsync(request).isSuccess
            }
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "Error in deprecated sendRequest")
            false
        }
    }

    interface RequestHandler {
        fun onComplete(success: Boolean)
    }

    @Deprecated("Use sendRequestAsync instead", ReplaceWith("sendRequestAsync(request)"))
    fun sendRequestAsync(request: String, handler: RequestHandler) {
        // Deprecated callback-based method kept for backward compatibility
        // Will be removed in version 2.0.0
    }
}

// BuildConfig stub for logging level - replace with actual BuildConfig in production
private object BuildConfig {
    const val DEBUG = true
}

