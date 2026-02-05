package com.pdfpilot.app;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;



import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.Task;

import com.google.firebase.auth.AuthCredential;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.GoogleAuthProvider;

import java.util.Arrays;

public class FBAuth {
    private static final String TAG = "FBAuth";
    private static final int RC_SIGN_IN = 9001;

    private static Activity sActivity;
    private static FirebaseAuth sAuth;
    private static GoogleSignInClient sGoogleSignInClient;


    // Native methods to call back to C++
    public static native void onAuthSuccess(String userId, String userName, String userEmail, String photoUrl);
    public static native void onAuthError(String errorMessage);

    public static void initialize(Activity activity) {
        sActivity = activity;
        sAuth = FirebaseAuth.getInstance();

        // Configure Google Sign-In
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestIdToken(activity.getString(R.string.default_web_client_id))
                .requestEmail()
                .build();

        sGoogleSignInClient = GoogleSignIn.getClient(activity, gso);



        Log.d(TAG, "FBAuth initialized");
    }

    public static void signInWithGoogle() {
        if (sActivity == null || sGoogleSignInClient == null) {
            onAuthError("Google Sign-In not initialized");
            return;
        }

        Intent signInIntent = sGoogleSignInClient.getSignInIntent();
        sActivity.startActivityForResult(signInIntent, RC_SIGN_IN);
    }



    public static void signInAnonymously() {
        if (sAuth == null) {
            onAuthError("Firebase Auth not initialized");
            return;
        }

        sAuth.signInAnonymously()
                .addOnCompleteListener(sActivity, task -> {
                    if (task.isSuccessful()) {
                        Log.d(TAG, "Anonymous sign-in success");
                        FirebaseUser user = sAuth.getCurrentUser();
                        if (user != null) {
                            onAuthSuccess(user.getUid(), "Guest User", "", "");
                        }
                    } else {
                        Log.e(TAG, "Anonymous sign-in failed", task.getException());
                        onAuthError("Guest sign-in failed: " +
                                (task.getException() != null ? task.getException().getMessage() : "Unknown error"));
                    }
                });
    }

    public static void signOut() {
        if (sAuth != null) {
            sAuth.signOut();
        }
        if (sGoogleSignInClient != null) {
            sGoogleSignInClient.signOut();
        }

        Log.d(TAG, "User signed out");
    }

    // Call this from Activity.onActivityResult
    public static void handleActivityResult(int requestCode, int resultCode, Intent data) {


        // Handle Google Sign-In result
        if (requestCode == RC_SIGN_IN) {
            Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
            try {
                GoogleSignInAccount account = task.getResult(ApiException.class);
                Log.d(TAG, "Google sign-in success, authenticating with Firebase");
                firebaseAuthWithGoogle(account.getIdToken());
            } catch (ApiException e) {
                Log.e(TAG, "Google sign-in failed", e);
                onAuthError("Google sign-in failed: " + e.getMessage() + " (Status Code: " + e.getStatusCode() + ")");
            }
        }
    }

    private static void firebaseAuthWithGoogle(String idToken) {
        AuthCredential credential = GoogleAuthProvider.getCredential(idToken, null);
        sAuth.signInWithCredential(credential)
                .addOnCompleteListener(sActivity, task -> {
                    if (task.isSuccessful()) {
                        Log.d(TAG, "Firebase auth with Google success");
                        FirebaseUser user = sAuth.getCurrentUser();
                        if (user != null) {
                            String photoUrl = user.getPhotoUrl() != null ? user.getPhotoUrl().toString() : "";
                            onAuthSuccess(user.getUid(),
                                    user.getDisplayName() != null ? user.getDisplayName() : "",
                                    user.getEmail() != null ? user.getEmail() : "",
                                    photoUrl);
                        }
                    } else {
                        Log.e(TAG, "Firebase auth with Google failed", task.getException());
                        onAuthError("Authentication failed: " +
                                (task.getException() != null ? task.getException().getMessage() : "Unknown error"));
                    }
                });
    }


}
