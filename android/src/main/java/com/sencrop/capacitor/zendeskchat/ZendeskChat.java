package com.sencrop.capacitor.zendeskchat;

import android.content.Context;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Locale;
import java.util.Map;

import com.getcapacitor.JSObject;

import com.zendesk.service.ErrorResponse;
import com.zendesk.service.ZendeskCallback;
import zendesk.core.AnonymousIdentity;
import zendesk.core.Zendesk;
import zendesk.support.Support;
import zendesk.support.guide.HelpCenterActivity;
import zendesk.support.request.RequestActivity;
import zendesk.support.requestlist.RequestListActivity;
import zendesk.support.SupportEngine;
import zendesk.classic.messaging.MessagingActivity;

@CapacitorPlugin(name = "ZendeskChat")
public class ZendeskChat extends Plugin {
    private String identityEmail = null;
    private boolean liveChatEnabled = true;
    @PluginMethod()
    public void initialize(PluginCall call) {
        String appId = call.getString("appId");
        String clientId = call.getString("clientId");
        String zendeskUrl = call.getString("zendeskUrl");

        if (appId == null || clientId == null || zendeskUrl == null) {
            call.reject("Missing appId, clientId or zendeskUrl");
            return;
        }

        Context context = getContext();
        Zendesk.INSTANCE.init(context, zendeskUrl, appId, clientId);
        Support.INSTANCE.init(Zendesk.INSTANCE);

        if (call.hasOption("theme")) {
            // Theme customization is handled in setTheme
            setTheme(call);
        }

        if (call.hasOption("locale")) {
            setLocale(call);
        }

        liveChatEnabled = Boolean.TRUE.equals(call.getBoolean("enableLiveChat", true));
        call.resolve();
    }

    @PluginMethod()
    public void setTheme(PluginCall call) {
        // For the Unified/Classic SDK on Android, theme customization is primarily done via XML styles.
        // Programmatic color adjustment is not directly supported by the Zendesk Support SDK activities.
        // We log this as a reminder that XML styles should be used for Android branding.
        String primaryColor = call.getString("primaryColor");
        if (primaryColor != null) {
            android.util.Log.w("ZendeskChat", "setTheme: Programmatic primaryColor customization is not supported on Android Unified SDK. Please use XML styles.");
        }
        call.resolve();
    }

    @PluginMethod()
    public void setLocale(PluginCall call) {
        String localeString = call.getString("locale");
        if (localeString != null) {
            Locale locale = Locale.forLanguageTag(localeString);
            Support.INSTANCE.setHelpCenterLocaleOverride(locale);
        }
        call.resolve();
    }

    @PluginMethod()
    public void setVisitorInfo(PluginCall call) {
        String name = call.getString("name");
        String email = call.getString("email");

        // Changing anonymous identity wipes all ticket history — skip if email unchanged.
        if (email != null && email.equals(identityEmail)) {
            call.resolve();
            return;
        }

        Zendesk.INSTANCE.setIdentity(new AnonymousIdentity.Builder()
                .withNameIdentifier(name)
                .withEmailIdentifier(email)
                .build());

        identityEmail = email;
        call.resolve();
    }

    @PluginMethod()
    public void open(PluginCall call) {
        MessagingActivity.builder()
            .withEngines(SupportEngine.engine())
            .show(getActivity());
        call.resolve();
    }

    @PluginMethod()
    public void openHelpCenter(PluginCall call) {
        HelpCenterActivity.builder()
                .show(getActivity());
        call.resolve();
    }

    @PluginMethod()
    public void openTicketList(PluginCall call) {
        RequestListActivity.builder()
                .show(getActivity());
        call.resolve();
    }

    @PluginMethod()
    public void createTicket(PluginCall call) {
        RequestActivity.builder()
                .show(getActivity());
        call.resolve();
    }

    @PluginMethod()
    public void handleNotification(PluginCall call) {
        JSObject data = call.getObject("data");
        if (data == null) {
            call.reject("Missing data");
            return;
        }

        // Convert JSObject to Map<String, String> for Zendesk SDK consumption.
        Map<String, String> pushData = new HashMap<>();
        Iterator<String> keys = data.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            try {
                String value = data.getString(key);
                if (value != null) {
                    pushData.put(key, value);
                }
            } catch (Exception e) {
                // skip non-string values
            }
        }

        // Classic Support SDK identifies its push notifications by the presence of
        // "zendesk_sdk_request_id" in the payload (docs: handle_push_notifications_wh).
        boolean isZendesk = pushData.containsKey("zendesk_sdk_request_id");
        if (isZendesk) {
            RequestListActivity.builder().show(getActivity());
        }

        JSObject result = new JSObject();
        result.put("isZendeskNotification", isZendesk);
        result.put("wasHandled", isZendesk);
        call.resolve(result);
    }

    @PluginMethod()
    public void getUnreadCount(PluginCall call) {
        if (Support.INSTANCE.provider() == null) {
            JSObject result = new JSObject();
            result.put("count", 0);
            call.resolve(result);
            return;
        }
        Support.INSTANCE.provider().requestProvider().getUpdatesForDevice(
            new ZendeskCallback<zendesk.support.RequestUpdates>() {
                @Override
                public void onSuccess(zendesk.support.RequestUpdates updates) {
                    JSObject result = new JSObject();
                    result.put("count", updates != null ? updates.totalUpdates() : 0);
                    call.resolve(result);
                }
                @Override
                public void onError(ErrorResponse errorResponse) {
                    JSObject result = new JSObject();
                    result.put("count", 0);
                    call.resolve(result);
                }
            }
        );
    }

    @PluginMethod()
    public void isLiveChatEnabled(PluginCall call) {
        JSObject result = new JSObject();
        result.put("enabled", liveChatEnabled);
        call.resolve(result);
    }

    @PluginMethod()
    public void registerPushToken(PluginCall call) {
        String token = call.getString("token");
        if (token == null) {
            call.reject("Missing token");
            return;
        }
        if (Zendesk.INSTANCE.provider() == null) {
            call.reject("Zendesk not initialized");
            return;
        }
        Zendesk.INSTANCE.provider().pushRegistrationProvider().registerWithDeviceIdentifier(
            token,
            new ZendeskCallback<String>() {
                @Override
                public void onSuccess(String result) {
                    call.resolve();
                }
                @Override
                public void onError(ErrorResponse errorResponse) {
                    android.util.Log.w("ZendeskChat", "registerPushToken failed: " + errorResponse.getReason());
                    call.resolve(); // best-effort, don't block the flow
                }
            }
        );
    }
}
