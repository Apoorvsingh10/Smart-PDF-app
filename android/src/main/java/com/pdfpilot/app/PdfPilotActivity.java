package com.pdfpilot.app;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import org.qtproject.qt.android.bindings.QtActivity;

public class PdfPilotActivity extends QtActivity {
    private static final String TAG = "PdfPilotActivity";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "PdfPilotActivity created");

        // Initialize Firebase Auth helper with this activity
        FBAuth.initialize(this);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Log.d(TAG, "onActivityResult: requestCode=" + requestCode + ", resultCode=" + resultCode);

        // Forward to FBAuth to handle Google/Facebook sign-in results
        FBAuth.handleActivityResult(requestCode, resultCode, data);
    }
}
