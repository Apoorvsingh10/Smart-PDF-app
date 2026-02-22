package io.smartpdf.app;

import android.app.Activity;
import android.util.Log;

import com.razorpay.Checkout;
import com.razorpay.PaymentResultListener;

import org.json.JSONObject;

public class RazorpayHelper implements PaymentResultListener {
    private static final String TAG = "RazorpayHelper";

    private static Activity sActivity;
    private static String sCurrentOrderId;

    // Native methods to call back to C++
    public static native void onPaymentSuccess(String paymentId, String orderId);
    public static native void onPaymentFailed(String errorCode, String errorDesc);

    public static void startPayment(Activity activity, String key, int amountPaise,
                                     String orderId, String description, String email) {
        sActivity = activity;
        sCurrentOrderId = orderId;

        Log.d(TAG, "Starting payment - amount: " + amountPaise + " paise, orderId: " + orderId);

        activity.runOnUiThread(() -> {
            try {
                Checkout checkout = new Checkout();
                checkout.setKeyID(key);

                // Set logo (optional)
                // checkout.setImage(R.drawable.ic_launcher);

                JSONObject options = new JSONObject();
                options.put("name", "Smart PDF");
                options.put("description", description);
                options.put("currency", "INR");
                options.put("amount", amountPaise);
                options.put("order_id", orderId);

                // Prefill user details
                JSONObject prefill = new JSONObject();
                prefill.put("email", email);
                options.put("prefill", prefill);

                // Theme
                JSONObject theme = new JSONObject();
                theme.put("color", "#7C3AED"); // Primary color from Theme.qml
                options.put("theme", theme);

                // Notes for tracking
                JSONObject notes = new JSONObject();
                notes.put("app", "Smart PDF");
                notes.put("platform", "Android");
                options.put("notes", notes);

                Log.d(TAG, "Opening Razorpay checkout");
                checkout.open(activity, options);

            } catch (Exception e) {
                Log.e(TAG, "Error starting payment", e);
                onPaymentFailed("CHECKOUT_ERROR", e.getMessage());
            }
        });
    }

    @Override
    public void onPaymentSuccess(String paymentId) {
        Log.d(TAG, "Payment success: " + paymentId);
        onPaymentSuccess(paymentId, sCurrentOrderId);
    }

    @Override
    public void onPaymentError(int code, String description) {
        Log.e(TAG, "Payment error - code: " + code + ", desc: " + description);
        onPaymentFailed(String.valueOf(code), description != null ? description : "Payment failed");
    }

    // Initialize Razorpay (call from Activity.onCreate)
    public static void initialize(Activity activity) {
        Checkout.preload(activity.getApplicationContext());
        Log.d(TAG, "Razorpay preloaded");
    }
}
