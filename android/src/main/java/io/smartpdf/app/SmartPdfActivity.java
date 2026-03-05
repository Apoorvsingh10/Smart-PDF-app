package io.smartpdf.app;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import org.qtproject.qt.android.bindings.QtActivity;

public class SmartPdfActivity extends QtActivity {
    private static final String TAG = "SmartPdfActivity";
    private static SmartPdfActivity s_instance;
    private static String s_pendingFileUri = null;
    private boolean m_qtReady = false;

    // Native method to notify Qt about incoming file
    public static native void onFileReceived(String fileUri);

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        s_instance = this;
        Log.d(TAG, "SmartPdfActivity created");

        // Initialize Firebase Auth
        try {
            FBAuth.initialize(this);
        } catch (Exception e) {
            Log.e(TAG, "FBAuth initialization failed: " + e.getMessage());
        }

        // Initialize Google Play Billing
        try {
            BillingHelper.getInstance(this);
            Log.d(TAG, "BillingHelper initialized");
        } catch (Exception e) {
            Log.e(TAG, "BillingHelper initialization failed: " + e.getMessage());
        }

        // Handle intent if app was opened with a PDF file
        handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        Log.d(TAG, "onNewIntent received");
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent == null) return;

        String action = intent.getAction();
        String type = intent.getType();

        Log.d(TAG, "handleIntent - action: " + action + ", type: " + type);

        if (Intent.ACTION_VIEW.equals(action) || Intent.ACTION_SEND.equals(action)) {
            Uri uri = null;

            if (Intent.ACTION_VIEW.equals(action)) {
                uri = intent.getData();
            } else if (Intent.ACTION_SEND.equals(action)) {
                uri = intent.getParcelableExtra(Intent.EXTRA_STREAM);
            }

            if (uri != null) {
                String uriString = uri.toString();
                Log.d(TAG, "Received file URI: " + uriString);

                // Grant read permission for content URIs
                if ("content".equals(uri.getScheme())) {
                    try {
                        grantUriPermission(getPackageName(), uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    } catch (Exception e) {
                        Log.w(TAG, "Could not grant URI permission: " + e.getMessage());
                    }

                    try {
                        getContentResolver().takePersistableUriPermission(uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    } catch (Exception e) {
                        Log.w(TAG, "Could not take persistable permission: " + e.getMessage());
                    }
                }

                // Store pending URI
                s_pendingFileUri = uriString;

                // Try to notify Qt if ready
                if (m_qtReady) {
                    notifyQt(uriString);
                }
            }
        }
    }

    private void notifyQt(String uriString) {
        try {
            onFileReceived(uriString);
            s_pendingFileUri = null;
            Log.d(TAG, "Successfully notified Qt about file: " + uriString);
        } catch (UnsatisfiedLinkError e) {
            Log.d(TAG, "Qt native library not loaded yet, file stored for later");
        } catch (Exception e) {
            Log.e(TAG, "Error notifying Qt: " + e.getMessage());
        }
    }

    // Called when Qt is fully loaded and ready
    public void setQtReady() {
        m_qtReady = true;
        Log.d(TAG, "Qt is ready");

        // Check if there's a pending file to send
        if (s_pendingFileUri != null) {
            notifyQt(s_pendingFileUri);
        }
    }

    // Called from Qt when it's ready to receive the pending file
    public static String getPendingFileUri() {
        String uri = s_pendingFileUri;
        Log.d(TAG, "getPendingFileUri returning: " + uri);
        return uri;
    }

    public static void clearPendingFileUri() {
        s_pendingFileUri = null;
    }

    public static SmartPdfActivity getInstance() {
        return s_instance;
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Log.d(TAG, "onActivityResult: requestCode=" + requestCode + ", resultCode=" + resultCode);

        try {
            FBAuth.handleActivityResult(requestCode, resultCode, data);
        } catch (Exception e) {
            Log.e(TAG, "Error handling activity result: " + e.getMessage());
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // Clean up billing
        BillingHelper helper = BillingHelper.getInstance();
        if (helper != null) {
            helper.destroy();
        }
    }
}
