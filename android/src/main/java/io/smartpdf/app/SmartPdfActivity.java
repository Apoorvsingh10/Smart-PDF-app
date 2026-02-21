package io.smartpdf.app;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import org.qtproject.qt.android.bindings.QtActivity;

public class SmartPdfActivity extends QtActivity {
    private static final String TAG = "SmartPdfActivity";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "SmartPdfActivity created");

        // Initialize Firebase Auth helper with this activity
        FBAuth.initialize(this);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Log.d(TAG, "onActivityResult: requestCode=" + requestCode + ", resultCode=" + resultCode);

        // Forward to FBAuth to handle Google sign-in results
        FBAuth.handleActivityResult(requestCode, resultCode, data);
    }
}
