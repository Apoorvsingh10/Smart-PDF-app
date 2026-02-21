package io.smartpdf.app;

import android.app.Activity;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
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

public class FBAuth {
    private static final String TAG = "FBAuth";
    private static final int RC_SIGN_IN = 9001;

    private static Activity sActivity;
    private static FirebaseAuth sAuth;
    private static GoogleSignInClient sGoogleSignInClient;
    private static Handler sHandler = new Handler(Looper.getMainLooper());
    private static boolean sWaitingForSignIn = false;

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

        Log.d(TAG, "Starting Google Sign-In...");

        // First, try silent sign-in (for returning users)
        sGoogleSignInClient.silentSignIn()
            .addOnCompleteListener(sActivity, task -> {
                if (task.isSuccessful()) {
                    Log.d(TAG, "Silent sign-in successful");
                    GoogleSignInAccount account = task.getResult();
                    firebaseAuthWithGoogle(account.getIdToken());
                } else {
                    Log.d(TAG, "Silent sign-in failed, launching interactive sign-in");
                    launchInteractiveSignIn();
                }
            });
    }

    private static void launchInteractiveSignIn() {
        Intent signInIntent = sGoogleSignInClient.getSignInIntent();
        sWaitingForSignIn = true;
        sActivity.startActivityForResult(signInIntent, RC_SIGN_IN);

        // Start polling for result since Qt may intercept onActivityResult
        startPollingForSignIn();
    }

    private static void startPollingForSignIn() {
        sHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (!sWaitingForSignIn) return;

                GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(sActivity);
                if (account != null) {
                    Log.d(TAG, "Polling: Found signed-in account");
                    sWaitingForSignIn = false;
                    firebaseAuthWithGoogle(account.getIdToken());
                } else if (sWaitingForSignIn) {
                    // Continue polling
                    sHandler.postDelayed(this, 500);
                }
            }
        }, 1000);

        // Stop polling after 60 seconds (user cancelled or timeout)
        sHandler.postDelayed(() -> {
            if (sWaitingForSignIn) {
                sWaitingForSignIn = false;
                Log.d(TAG, "Sign-in polling timeout");
            }
        }, 60000);
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
        sWaitingForSignIn = false;

        Log.d(TAG, "User signed out");
    }

    // Called from Activity.onActivityResult if it works
    public static void handleActivityResult(int requestCode, int resultCode, Intent data) {
        Log.d(TAG, "handleActivityResult: requestCode=" + requestCode + ", resultCode=" + resultCode);
        if (requestCode == RC_SIGN_IN) {
            sWaitingForSignIn = false;
            Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
            try {
                GoogleSignInAccount account = task.getResult(ApiException.class);
                Log.d(TAG, "Google sign-in success from onActivityResult");
                firebaseAuthWithGoogle(account.getIdToken());
            } catch (ApiException e) {
                Log.e(TAG, "Google sign-in failed: " + e.getMessage() + " (Status Code: " + e.getStatusCode() + ")");
                onAuthError("Google sign-in failed: " + e.getMessage() + " (Status Code: " + e.getStatusCode() + ")");
            }
        }
    }

    private static void firebaseAuthWithGoogle(String idToken) {
        if (idToken == null) {
            Log.e(TAG, "ID token is null");
            onAuthError("Failed to get authentication token");
            return;
        }

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
