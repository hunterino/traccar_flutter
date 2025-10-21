/*
 * Copyright 2025 - Modern implementation using Retrofit
 * Based on original Traccar code by Anton Tananaev (anton@traccar.org)
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

import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Url

/**
 * Retrofit API interface for Traccar location updates.
 *
 * Uses dynamic URLs since the Traccar protocol includes all data
 * in the URL query parameters.
 */
interface TraccarApi {

    /**
     * Sends a position update to the Traccar server.
     *
     * @param url The complete URL with query parameters containing position data
     * @return Response with empty body (server typically responds with 200 OK)
     */
    @GET
    suspend fun sendPosition(@Url url: String): Response<String>
}
