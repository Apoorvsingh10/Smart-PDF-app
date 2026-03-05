package io.smartpdf.app;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.NonNull;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.ProductDetailsResponseListener;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesResponseListener;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class BillingHelper implements PurchasesUpdatedListener {
    private static final String TAG = "BillingHelper";

    // Product IDs - must match Google Play Console
    public static final String PRODUCT_MONTHLY = "smartpdf_monthly";
    public static final String PRODUCT_QUARTERLY = "smartpdf_quarterly";
    public static final String PRODUCT_LIFETIME = "smartpdf_lifetime";

    private static BillingHelper sInstance;
    private Activity mActivity;
    private BillingClient mBillingClient;
    private Map<String, ProductDetails> mProductDetailsMap = new HashMap<>();
    private boolean mIsConnected = false;
    private String mPendingPurchaseProductId = null;

    // Native callbacks to C++
    public static native void onBillingConnected();
    public static native void onBillingDisconnected();
    public static native void onProductDetailsLoaded(String productId, String price, String title);
    public static native void onPurchaseSuccess(String productId, String purchaseToken, String orderId);
    public static native void onPurchaseFailed(String errorCode, String errorMessage);
    public static native void onPurchasePending(String productId);

    private BillingHelper(Activity activity) {
        mActivity = activity;
        initializeBillingClient();
    }

    public static synchronized BillingHelper getInstance(Activity activity) {
        if (sInstance == null) {
            sInstance = new BillingHelper(activity);
        }
        return sInstance;
    }

    public static BillingHelper getInstance() {
        return sInstance;
    }

    private void initializeBillingClient() {
        mBillingClient = BillingClient.newBuilder(mActivity)
                .setListener(this)
                .enablePendingPurchases()
                .build();

        connectToPlayBilling();
    }

    public void connectToPlayBilling() {
        if (mBillingClient.isReady()) {
            Log.d(TAG, "BillingClient already connected");
            return;
        }

        Log.d(TAG, "Connecting to Google Play Billing...");

        mBillingClient.startConnection(new BillingClientStateListener() {
            @Override
            public void onBillingSetupFinished(@NonNull BillingResult billingResult) {
                if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    Log.d(TAG, "Google Play Billing connected successfully");
                    mIsConnected = true;

                    try {
                        onBillingConnected();
                    } catch (UnsatisfiedLinkError e) {
                        Log.w(TAG, "Native library not loaded yet");
                    }

                    // Query product details
                    queryProductDetails();

                    // Check for existing purchases
                    queryExistingPurchases();
                } else {
                    Log.e(TAG, "Billing setup failed: " + billingResult.getDebugMessage());
                    mIsConnected = false;
                }
            }

            @Override
            public void onBillingServiceDisconnected() {
                Log.w(TAG, "Google Play Billing disconnected");
                mIsConnected = false;

                try {
                    onBillingDisconnected();
                } catch (UnsatisfiedLinkError e) {
                    Log.w(TAG, "Native library not loaded");
                }

                // Retry connection
                connectToPlayBilling();
            }
        });
    }

    private void queryProductDetails() {
        // Query subscriptions
        List<QueryProductDetailsParams.Product> subscriptionProducts = new ArrayList<>();
        subscriptionProducts.add(
                QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(PRODUCT_MONTHLY)
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build()
        );
        subscriptionProducts.add(
                QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(PRODUCT_QUARTERLY)
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build()
        );

        QueryProductDetailsParams subscriptionParams = QueryProductDetailsParams.newBuilder()
                .setProductList(subscriptionProducts)
                .build();

        mBillingClient.queryProductDetailsAsync(subscriptionParams, new ProductDetailsResponseListener() {
            @Override
            public void onProductDetailsResponse(@NonNull BillingResult billingResult,
                                                  @NonNull List<ProductDetails> productDetailsList) {
                if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    for (ProductDetails details : productDetailsList) {
                        mProductDetailsMap.put(details.getProductId(), details);
                        Log.d(TAG, "Subscription loaded: " + details.getProductId());

                        // Get price from subscription offer
                        if (details.getSubscriptionOfferDetails() != null &&
                            !details.getSubscriptionOfferDetails().isEmpty()) {
                            String price = details.getSubscriptionOfferDetails().get(0)
                                    .getPricingPhases().getPricingPhaseList().get(0)
                                    .getFormattedPrice();
                            notifyProductDetails(details.getProductId(), price, details.getTitle());
                        }
                    }
                } else {
                    Log.e(TAG, "Failed to query subscriptions: " + billingResult.getDebugMessage());
                }
            }
        });

        // Query one-time purchase (lifetime)
        List<QueryProductDetailsParams.Product> inAppProducts = new ArrayList<>();
        inAppProducts.add(
                QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(PRODUCT_LIFETIME)
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build()
        );

        QueryProductDetailsParams inAppParams = QueryProductDetailsParams.newBuilder()
                .setProductList(inAppProducts)
                .build();

        mBillingClient.queryProductDetailsAsync(inAppParams, new ProductDetailsResponseListener() {
            @Override
            public void onProductDetailsResponse(@NonNull BillingResult billingResult,
                                                  @NonNull List<ProductDetails> productDetailsList) {
                if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    for (ProductDetails details : productDetailsList) {
                        mProductDetailsMap.put(details.getProductId(), details);
                        Log.d(TAG, "In-app product loaded: " + details.getProductId());

                        if (details.getOneTimePurchaseOfferDetails() != null) {
                            String price = details.getOneTimePurchaseOfferDetails().getFormattedPrice();
                            notifyProductDetails(details.getProductId(), price, details.getTitle());
                        }
                    }
                } else {
                    Log.e(TAG, "Failed to query in-app products: " + billingResult.getDebugMessage());
                }
            }
        });
    }

    private void notifyProductDetails(String productId, String price, String title) {
        try {
            onProductDetailsLoaded(productId, price, title);
        } catch (UnsatisfiedLinkError e) {
            Log.w(TAG, "Native library not loaded yet");
        }
    }

    private void queryExistingPurchases() {
        // Check subscriptions
        mBillingClient.queryPurchasesAsync(
                QueryPurchasesParams.newBuilder()
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build(),
                new PurchasesResponseListener() {
                    @Override
                    public void onQueryPurchasesResponse(@NonNull BillingResult billingResult,
                                                          @NonNull List<Purchase> purchases) {
                        if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                            for (Purchase purchase : purchases) {
                                handlePurchase(purchase);
                            }
                        }
                    }
                }
        );

        // Check in-app purchases
        mBillingClient.queryPurchasesAsync(
                QueryPurchasesParams.newBuilder()
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build(),
                new PurchasesResponseListener() {
                    @Override
                    public void onQueryPurchasesResponse(@NonNull BillingResult billingResult,
                                                          @NonNull List<Purchase> purchases) {
                        if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                            for (Purchase purchase : purchases) {
                                handlePurchase(purchase);
                            }
                        }
                    }
                }
        );
    }

    public static void launchPurchase(String productId) {
        if (sInstance == null) {
            Log.e(TAG, "BillingHelper not initialized");
            return;
        }
        sInstance.startPurchase(productId);
    }

    public void startPurchase(String productId) {
        if (!mIsConnected) {
            Log.e(TAG, "Billing not connected");
            onPurchaseFailed("NOT_CONNECTED", "Billing service not connected");
            return;
        }

        ProductDetails productDetails = mProductDetailsMap.get(productId);
        if (productDetails == null) {
            Log.e(TAG, "Product not found: " + productId);
            onPurchaseFailed("PRODUCT_NOT_FOUND", "Product not available");
            return;
        }

        mPendingPurchaseProductId = productId;

        mActivity.runOnUiThread(() -> {
            try {
                BillingFlowParams.ProductDetailsParams.Builder productParamsBuilder =
                        BillingFlowParams.ProductDetailsParams.newBuilder()
                                .setProductDetails(productDetails);

                // For subscriptions, we need to specify the offer token
                if (productDetails.getSubscriptionOfferDetails() != null &&
                    !productDetails.getSubscriptionOfferDetails().isEmpty()) {
                    productParamsBuilder.setOfferToken(
                            productDetails.getSubscriptionOfferDetails().get(0).getOfferToken()
                    );
                }

                List<BillingFlowParams.ProductDetailsParams> productDetailsParamsList = new ArrayList<>();
                productDetailsParamsList.add(productParamsBuilder.build());

                BillingFlowParams billingFlowParams = BillingFlowParams.newBuilder()
                        .setProductDetailsParamsList(productDetailsParamsList)
                        .build();

                BillingResult result = mBillingClient.launchBillingFlow(mActivity, billingFlowParams);

                if (result.getResponseCode() != BillingClient.BillingResponseCode.OK) {
                    Log.e(TAG, "Failed to launch billing flow: " + result.getDebugMessage());
                    onPurchaseFailed(String.valueOf(result.getResponseCode()), result.getDebugMessage());
                }
            } catch (Exception e) {
                Log.e(TAG, "Error launching purchase", e);
                onPurchaseFailed("LAUNCH_ERROR", e.getMessage());
            }
        });
    }

    @Override
    public void onPurchasesUpdated(@NonNull BillingResult billingResult,
                                    List<Purchase> purchases) {
        int responseCode = billingResult.getResponseCode();

        if (responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (Purchase purchase : purchases) {
                handlePurchase(purchase);
            }
        } else if (responseCode == BillingClient.BillingResponseCode.USER_CANCELED) {
            Log.d(TAG, "User cancelled the purchase");
            try {
                onPurchaseFailed("USER_CANCELED", "Purchase cancelled by user");
            } catch (UnsatisfiedLinkError e) {
                Log.w(TAG, "Native library not loaded");
            }
        } else {
            Log.e(TAG, "Purchase failed: " + billingResult.getDebugMessage());
            try {
                onPurchaseFailed(String.valueOf(responseCode), billingResult.getDebugMessage());
            } catch (UnsatisfiedLinkError e) {
                Log.w(TAG, "Native library not loaded");
            }
        }
    }

    private void handlePurchase(Purchase purchase) {
        int purchaseState = purchase.getPurchaseState();

        if (purchaseState == Purchase.PurchaseState.PURCHASED) {
            // Acknowledge the purchase if not already acknowledged
            if (!purchase.isAcknowledged()) {
                acknowledgePurchase(purchase);
            } else {
                // Already acknowledged, notify success
                notifyPurchaseSuccess(purchase);
            }
        } else if (purchaseState == Purchase.PurchaseState.PENDING) {
            Log.d(TAG, "Purchase is pending");
            try {
                String productId = purchase.getProducts().isEmpty() ? "" : purchase.getProducts().get(0);
                onPurchasePending(productId);
            } catch (UnsatisfiedLinkError e) {
                Log.w(TAG, "Native library not loaded");
            }
        }
    }

    private void acknowledgePurchase(Purchase purchase) {
        AcknowledgePurchaseParams params = AcknowledgePurchaseParams.newBuilder()
                .setPurchaseToken(purchase.getPurchaseToken())
                .build();

        mBillingClient.acknowledgePurchase(params, billingResult -> {
            if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                Log.d(TAG, "Purchase acknowledged");
                notifyPurchaseSuccess(purchase);
            } else {
                Log.e(TAG, "Failed to acknowledge purchase: " + billingResult.getDebugMessage());
            }
        });
    }

    private void notifyPurchaseSuccess(Purchase purchase) {
        String productId = purchase.getProducts().isEmpty() ? mPendingPurchaseProductId : purchase.getProducts().get(0);
        String purchaseToken = purchase.getPurchaseToken();
        String orderId = purchase.getOrderId();

        Log.d(TAG, "Purchase successful - productId: " + productId + ", orderId: " + orderId);

        try {
            onPurchaseSuccess(productId, purchaseToken, orderId != null ? orderId : "");
        } catch (UnsatisfiedLinkError e) {
            Log.w(TAG, "Native library not loaded");
        }
    }

    public boolean isConnected() {
        return mIsConnected;
    }

    public void destroy() {
        if (mBillingClient != null) {
            mBillingClient.endConnection();
            mBillingClient = null;
        }
        sInstance = null;
    }
}
