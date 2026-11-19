package com.raindrop.raindrop_client

import android.content.Context
import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.BlockstoreClient
import com.google.android.gms.auth.blockstore.DeleteBytesRequest
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The `raindrop/block_store` channel: one entry in Google's Block Store, the opt-in copy of the
 * person's identity that a new phone set up from their Google Account brings back. The Dart end is
 * `BlockStoreCloudBackup` in `core/storage/cloud_backup_store.dart`, and what the bytes are is
 * `IdentityBackup`'s business — here they are opaque.
 *
 * Nothing is written unless Block Store would encrypt it end to end (Android 9 or later, with a
 * screen lock): the entry holds the identity's root, and a copy Google could read would be no
 * backup at all.
 */
object BlockStoreChannel {

    private const val CHANNEL = "raindrop/block_store"
    private const val KEY = "com.raindrop.identity_backup"

    fun register(context: Context, messenger: BinaryMessenger) {
        val client = Blockstore.getClient(context)
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isEncrypted" -> client.isEndToEndEncryptionAvailable
                    .addOnSuccessListener { result.success(it) }
                    .addOnFailureListener { result.error("block_store", it.message, null) }

                "read" -> read(client, result)

                "write" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("block_store", "Nothing to store.", null)
                    } else {
                        write(client, bytes, result)
                    }
                }

                "delete" -> client
                    .deleteBytes(DeleteBytesRequest.Builder().setKeys(listOf(KEY)).build())
                    .addOnSuccessListener { result.success(null) }
                    .addOnFailureListener { result.error("block_store", it.message, null) }

                else -> result.notImplemented()
            }
        }
    }

    private fun read(client: BlockstoreClient, result: MethodChannel.Result) {
        client.retrieveBytes(RetrieveBytesRequest.Builder().setKeys(listOf(KEY)).build())
            .addOnSuccessListener { response -> result.success(response.blockstoreDataMap[KEY]?.bytes) }
            .addOnFailureListener { result.error("block_store", it.message, null) }
    }

    private fun write(client: BlockstoreClient, bytes: ByteArray, result: MethodChannel.Result) {
        client.isEndToEndEncryptionAvailable
            .addOnSuccessListener { encrypted ->
                if (!encrypted) {
                    result.error(
                        "not_encrypted",
                        "Set a screen lock first: without one, Google cannot encrypt the backup end to end.",
                        null,
                    )
                    return@addOnSuccessListener
                }
                val data = StoreBytesData.Builder()
                    .setKey(KEY)
                    .setBytes(bytes)
                    .setShouldBackupToCloud(true)
                    .build()
                client.storeBytes(data)
                    .addOnSuccessListener { result.success(null) }
                    .addOnFailureListener { result.error("block_store", it.message, null) }
            }
            .addOnFailureListener { result.error("block_store", it.message, null) }
    }
}
